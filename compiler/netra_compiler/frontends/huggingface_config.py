from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from ..errors import ValidationError


def read_recognized_config(path: Path) -> dict[str, Any]:
    """Interpret recognized config.json fields without importing Transformers."""
    try:
        root = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot read Hugging Face config: {exc}") from exc
    config = root.get("text_config", root)
    model_type = str(config.get("model_type", root.get("model_type", ""))).lower()
    if "qwen" not in model_type and "gemma" not in model_type:
        raise ValidationError(f"unrecognized Hugging Face model_type: {model_type!r}")
    return {
        "family": "qwen3.6" if "qwen" in model_type else "gemma",
        "hidden_size": config.get("hidden_size"),
        "intermediate_size": config.get("intermediate_size") or config.get("moe_intermediate_size"),
        "num_hidden_layers": config.get("num_hidden_layers"),
        "tensor_parallel": 1,
        "quantization_config": root.get("quantization_config", config.get("quantization_config")),
    }
