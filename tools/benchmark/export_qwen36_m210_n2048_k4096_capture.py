#!/usr/bin/env python3
"""Export exact Qwen3.6 M210/N2048/K4096 block-FP8 operands."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch

from aiter.ops.gemm_op_a8w8 import (
    gemm_a8w8_blockscale_bpreshuffle_cktile,
)


BLOCK = 128
M = 210
N = 2048
K = 4096
PREFIX = "gdn_stage.layer.0.dense_m210_n2048_k4096."


def raw_bytes(tensor: torch.Tensor) -> bytes:
    return (
        tensor.detach()
        .contiguous()
        .cpu()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def unshuffle_weight(weight: torch.Tensor) -> torch.Tensor:
    return (
        weight.view(N // 16, K // 32, 2, 16, 16)
        .permute(0, 3, 1, 2, 4)
        .contiguous()
        .view(N, K)
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    if torch.version.hip is None:
        raise RuntimeError("ROCm is required")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":", 1)[0]
    if arch != "gfx950":
        raise RuntimeError(f"Expected gfx950, got {arch}")

    payload = torch.load(args.capture, map_location="cpu", weights_only=False)
    tensors = {
        "input_bf16": payload[f"{PREFIX}input_bf16"],
        "q_input": payload[f"{PREFIX}q_input"],
        "x_scale": payload[f"{PREFIX}x_scale"],
        "weight": payload[f"{PREFIX}weight"],
        "weight_scale": payload[f"{PREFIX}weight_scale"],
        "deployed_output_bf16": payload[f"{PREFIX}output_bf16"],
    }
    expected = {
        "input_bf16": ((M, K), torch.bfloat16),
        "q_input": ((M, K), torch.float8_e4m3fn),
        "x_scale": ((M, K // BLOCK), torch.float32),
        "weight": ((N, K), torch.float8_e4m3fn),
        "weight_scale": ((N // BLOCK, K // BLOCK), torch.float32),
        "deployed_output_bf16": ((M, N), torch.bfloat16),
    }
    for name, tensor in tensors.items():
        shape, dtype = expected[name]
        if tuple(tensor.shape) != shape or tensor.dtype != dtype:
            raise ValueError(
                f"{name}: expected {shape} {dtype}, got "
                f"{tuple(tensor.shape)} {tensor.dtype}"
            )

    q_input = tensors["q_input"].cuda()
    x_scale = tensors["x_scale"].cuda()
    weight = tensors["weight"].cuda()
    weight_scale = tensors["weight_scale"].cuda()
    cktile_output = torch.empty(
        (M, N), dtype=torch.bfloat16, device=q_input.device
    )
    gemm_a8w8_blockscale_bpreshuffle_cktile(
        q_input,
        weight,
        x_scale,
        weight_scale,
        cktile_output,
    )
    logical_x_scale = (
        x_scale.view(K // BLOCK, M).transpose(0, 1).contiguous()
    )
    q_dequant = q_input.float() * logical_x_scale.repeat_interleave(
        BLOCK, dim=1
    )
    logical_weight = unshuffle_weight(weight)
    weight_dequant = logical_weight.float() * (
        weight_scale.float()
        .repeat_interleave(BLOCK, dim=0)
        .repeat_interleave(BLOCK, dim=1)
    )
    reference_output_f32 = torch.mm(q_dequant, weight_dequant.t())
    torch.cuda.synchronize()
    tensors["cktile_output_bf16"] = cktile_output
    tensors["reference_output_f32"] = reference_output_f32
    tensors["reference_output_bf16"] = reference_output_f32.to(torch.bfloat16)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schema_version": 1,
        "architecture": arch,
        "rocm": torch.version.hip,
        "quantization": (
            "FP8 E4M3, 128x128 weights, per-row 1x128 activations"
        ),
        "shape": {"m": M, "n": N, "k": K},
        "source_capture": str(args.capture),
        "source_capture_sha256": sha256_bytes(args.capture.read_bytes()),
        "tensors": {},
    }
    for name, tensor in tensors.items():
        output = raw_bytes(tensor)
        filename = f"{name}.bin"
        (args.output_dir / filename).write_bytes(output)
        manifest["tensors"][name] = {
            "filename": filename,
            "shape": list(tensor.shape),
            "dtype": str(tensor.dtype),
            "bytes": len(output),
            "sha256": sha256_bytes(output),
        }
    (args.output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
