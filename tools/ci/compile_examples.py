#!/usr/bin/env python3
"""Compile deterministic CPU-only example engines into ignored build storage."""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "compiler"))

from netra_compiler.engine import compile_engine, semantic_file_hashes  # noqa: E402
from netra_compiler.validation import validate_engine_directory  # noqa: E402


def compile_one(model: Path, profile: str, output: Path) -> dict[str, object]:
    compile_engine(model, "gfx950", profile, output, library_root=ROOT)
    result = validate_engine_directory(output, library_root=ROOT)
    if not result["valid"]:
        raise RuntimeError(f"static validation failed for {model}")
    return result


def main() -> int:
    build_root = ROOT / "build"
    build_root.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="ci-examples-", dir=build_root) as directory:
        root = Path(directory)
        qwen_model = ROOT / "manifests/gfx950/models/qwen36-moe-m1-golden.json"
        first = root / "qwen-first"
        second = root / "qwen-second"
        qwen = compile_one(qwen_model, "decode_m1", first)
        compile_one(qwen_model, "decode_m1", second)
        if semantic_file_hashes(first) != semantic_file_hashes(second):
            raise RuntimeError("repeated Qwen compilation is not deterministic")
        if qwen["kernel_operations"] != 3 or qwen["fallback_operations"] != 8:
            raise RuntimeError(
                "Qwen current-best inventory changed: expected three accepted "
                "engine kernels and eight explicit server fallback boundaries"
            )
        gemma = compile_one(
            ROOT / "tests/compiler/fixtures/gemma-dense-synthetic.json",
            "decode_m1",
            root / "gemma",
        )
        llama = compile_one(
            ROOT / "tests/compiler/fixtures/llama-moe-gate-up-exact.json",
            "decode_m1",
            root / "llama",
        )
        print(
            json.dumps(
                {
                    "format": "netra-example-compilation-1",
                    "qwen_deterministic": True,
                    "qwen": qwen,
                    "gemma": gemma,
                    "llama": llama,
                },
                sort_keys=True,
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
