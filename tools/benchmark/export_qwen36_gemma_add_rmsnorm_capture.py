#!/usr/bin/env python3
"""Export one real Qwen Gemma add+RMSNorm state capture for raw kernels."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch

PREFIX = "gdn_stage.layer.0.gemma_add_rmsnorm_m1_n2048."
EXPECTED = {
    "input": ((1, 2048), torch.bfloat16),
    "residual": ((1, 2048), torch.bfloat16),
    "weight": ((2048,), torch.bfloat16),
    "output": ((1, 2048), torch.bfloat16),
    "residual_out": ((1, 2048), torch.bfloat16),
}
EPSILON = 1.0e-6


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    return parser.parse_args()


def raw_bytes(tensor: torch.Tensor) -> bytes:
    return (
        tensor.detach()
        .cpu()
        .contiguous()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )


def sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(raw_bytes(tensor)).hexdigest()


def main() -> None:
    args = parse_args()
    if args.output_dir.exists():
        raise FileExistsError(f"refusing to overwrite {args.output_dir}")
    payload = torch.load(args.state_pass, map_location="cpu", weights_only=False)
    tensors: dict[str, torch.Tensor] = {}
    for name, (shape, dtype) in EXPECTED.items():
        key = PREFIX + name
        tensor = payload.get(key)
        if not isinstance(tensor, torch.Tensor):
            raise KeyError(f"missing tensor: {key}")
        if tuple(tensor.shape) != shape or tensor.dtype != dtype:
            raise ValueError(
                f"{key}: got shape={tuple(tensor.shape)} dtype={tensor.dtype}"
            )
        tensors[name] = tensor.contiguous()

    summed_f32 = tensors["input"].float() + tensors["residual"].float()
    reference_residual = summed_f32.to(torch.bfloat16)
    inverse_rms = torch.rsqrt(
        summed_f32.square().mean(dim=-1, keepdim=True) + EPSILON
    )
    reference_output_f32 = summed_f32 * inverse_rms * tensors["weight"].float()
    reference_output = reference_output_f32.to(torch.bfloat16)

    residual_mismatches = int(
        torch.ne(reference_residual, tensors["residual_out"]).sum().item()
    )
    output_mismatches = int(
        torch.ne(reference_output, tensors["output"]).sum().item()
    )
    if residual_mismatches or output_mismatches:
        raise ValueError(
            "structural oracle mismatch: "
            f"residual={residual_mismatches}, output={output_mismatches}"
        )

    args.output_dir.mkdir(parents=True)
    for name, tensor in tensors.items():
        (args.output_dir / f"{name}_bf16.bin").write_bytes(raw_bytes(tensor))
    (args.output_dir / "reference_output_f32.bin").write_bytes(
        raw_bytes(reference_output_f32)
    )
    manifest = {
        "source_state_pass": str(args.state_pass),
        "shape": {"m": 1, "n": 2048},
        "epsilon": EPSILON,
        "semantics": (
            "sum=input.float()+residual.float(); residual_out=bf16(sum); "
            "output=bf16(sum*rsqrt(mean(sum^2)+epsilon)*weight.float())"
        ),
        "structural_oracle": {
            "residual_bf16_mismatches": residual_mismatches,
            "output_bf16_mismatches": output_mismatches,
        },
        "tensors": {
            name: {
                "shape": list(tensor.shape),
                "dtype": str(tensor.dtype),
                "sha256": sha256(tensor),
            }
            for name, tensor in tensors.items()
        },
        "reference_output_f32_sha256": sha256(reference_output_f32),
    }
    (args.output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
