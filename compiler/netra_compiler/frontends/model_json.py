from __future__ import annotations

import json
from pathlib import Path
from types import MappingProxyType
from typing import Any

from ..errors import ValidationError
from ..ir import Graph
from ..library import KernelLibrary
from ..schema_validation import validate_json_schema
from .gemma import gemma_graph
from .qwen import qwen_graph


_MODEL_FRONTENDS = MappingProxyType({
    "qwen3.6": qwen_graph,
    "gemma": gemma_graph,
})


def load_model(
    path: Path, *, library: KernelLibrary | None = None
) -> tuple[Graph, dict[str, Any]]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot read model manifest {path}: {exc}") from exc
    if data.get("format") != "netra-model-1":
        raise ValidationError("model manifest format must be netra-model-1")
    resolved_library = library or KernelLibrary.discover(anchors=(path,))
    schema_path = resolved_library.schema("netra-model.schema.json")
    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot read model schema {schema_path}: {exc}") from exc
    validate_json_schema(data, schema, label=str(path))
    family = data.get("family")
    # An explicit canonical graph is model-family agnostic. This is the zero-
    # Python-extension path for a new architecture whose operations already map
    # to Netra IR and kernel contracts.
    if "graph" in data:
        return Graph.from_dict(data["graph"]), data
    frontend = _MODEL_FRONTENDS.get(str(family))
    if frontend is not None:
        return frontend(data), data
    raise ValidationError(f"unsupported model family: {family!r}")
