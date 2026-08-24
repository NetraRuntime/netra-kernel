from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from dataclasses import asdict, is_dataclass
from enum import Enum
from pathlib import Path
from typing import Any


class DType(str, Enum):
    FP8_E4M3 = "fp8_e4m3"
    BF16 = "bf16"
    FP32 = "fp32"
    INT32 = "int32"


class Epilogue(str, Enum):
    IDENTITY = "identity"
    BIAS = "bias"
    SILU = "silu"
    GELU = "gelu"
    GATED_SILU = "gated_silu"


class Maturity(str, Enum):
    EXPERIMENT = "experiment"
    VERIFIED = "verified"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


def _primitive(value: Any) -> Any:
    if isinstance(value, Enum):
        return value.value
    if isinstance(value, Path):
        return value.as_posix()
    if is_dataclass(value):
        return {k: _primitive(v) for k, v in asdict(value).items()}
    if isinstance(value, Mapping):
        return {str(k): _primitive(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_primitive(v) for v in value]
    return value


def canonical_json(value: Any) -> str:
    return json.dumps(
        _primitive(value), sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ) + "\n"


def stable_hash(value: Any) -> str:
    return hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(canonical_json(value), encoding="utf-8")
