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
    result = {
        "family": "qwen3.6" if "qwen" in model_type else "gemma",
        "architecture": (root.get("architectures") or [None])[0],
        "model_type": model_type,
        "hidden_size": config.get("hidden_size"),
        "intermediate_size": config.get("intermediate_size") or config.get("moe_intermediate_size"),
        "num_hidden_layers": config.get("num_hidden_layers"),
        "num_attention_heads": config.get("num_attention_heads"),
        "num_key_value_heads": config.get("num_key_value_heads"),
        "head_dim": config.get("head_dim"),
        "linear_num_key_heads": config.get("linear_num_key_heads"),
        "linear_key_head_dim": config.get("linear_key_head_dim"),
        "linear_num_value_heads": config.get("linear_num_value_heads"),
        "linear_value_head_dim": config.get("linear_value_head_dim"),
        "linear_conv_kernel_dim": config.get("linear_conv_kernel_dim"),
        "layer_types": config.get("layer_types"),
        "full_attention_interval": config.get("full_attention_interval"),
        "attention_output_gate": config.get("attn_output_gate"),
        "vocab_size": config.get("vocab_size"),
        "mtp_layers": config.get("mtp_num_hidden_layers"),
        "max_position_embeddings": config.get("max_position_embeddings"),
        "quantization_config": root.get("quantization_config", config.get("quantization_config")),
    }
    return {name: value for name, value in result.items() if value is not None}
