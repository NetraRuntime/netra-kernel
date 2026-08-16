#!/usr/bin/env python3
"""Convert a captured AITER-shuffled Qwen FP8 expert tensor to row-major.

The reference tensors in the corrected capture are already computed from the
logical [expert, N, K] weights. This tool changes only the resident weight
binary and its manifest entry, allowing the row-major raw gfx950 code objects
to be validated against exactly the same real-checkpoint oracle.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import shutil

import numpy as np


WEIGHT_TENSORS = ("selected_w1_fp8", "selected_w2_fp8")


def inverse_aiter_shuffle(raw: bytes, shape: list[int]) -> bytes:
    experts, n, k = shape
    if n % 16 or k % 32:
        raise ValueError(f"AITER (16,16) inverse requires N%16=K%32=0: {shape}")
    physical = np.frombuffer(raw, dtype=np.uint8)
    if physical.size != experts * n * k:
        raise ValueError(f"weight byte count does not match shape {shape}")
    logical = (
        physical.reshape(experts, n // 16, k // 32, 2, 16, 16)
        .transpose(0, 1, 4, 2, 3, 5)
        .copy()
        .reshape(experts, n, k)
    )
    return logical.tobytes()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=pathlib.Path)
    parser.add_argument("output_dir", type=pathlib.Path)
    args = parser.parse_args()

    source = args.input_dir.resolve()
    output = args.output_dir.resolve()
    if output.exists():
        raise SystemExit(f"refusing to overwrite output directory: {output}")
    manifest_path = source / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    selected = [name for name in WEIGHT_TENSORS if name in manifest["tensors"]]
    if len(selected) != 1:
        raise SystemExit(f"expected exactly one captured weight tensor, got {selected}")

    shutil.copytree(source, output)
    tensor_name = selected[0]
    tensor = manifest["tensors"][tensor_name]
    weight_path = output / tensor["file"]
    rowmajor = inverse_aiter_shuffle(weight_path.read_bytes(), tensor["shape"])
    weight_path.write_bytes(rowmajor)
    tensor["bytes"] = len(rowmajor)
    tensor["sha256"] = hashlib.sha256(rowmajor).hexdigest()
    manifest["weight_layout"] = {
        "oracle": "logical [expert,n,k]",
        "resident": "logical contiguous row-major [expert,n,k]",
        "source": "inverse of AITER shuffle_weight layout=(16,16)",
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
