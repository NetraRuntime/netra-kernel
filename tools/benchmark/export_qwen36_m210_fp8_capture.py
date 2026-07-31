#!/usr/bin/env python3
"""Export exact Qwen3.6 M=210 block-FP8 operands for raw gfx950 validation."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import torch

import aiter
from aiter import get_hip_quant
from aiter.ops.gemm_op_a8w8 import (
    gemm_a8w8_blockscale_bpreshuffle_cktile,
)


BLOCK = 128
M = 210
PROJECTIONS = {
    "gdn_qkvz": {
        "layer_id": 0,
        "input_stage": "input",
        "output_stage": "in_proj_qkvz",
        "n": 12288,
        "k": 2048,
    },
    "attn_qkv": {
        "layer_id": 3,
        "input_stage": "attention.input",
        "output_stage": "attention.qkv_proj",
        "n": 9216,
        "k": 2048,
    },
}


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


def unshuffle_weight(weight: torch.Tensor, n: int, k: int) -> torch.Tensor:
    return (
        weight.view(n // 16, k // 32, 2, 16, 16)
        .permute(0, 3, 1, 2, 4)
        .contiguous()
        .view(n, k)
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, required=True)
    parser.add_argument("--projection", choices=tuple(PROJECTIONS), required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    if torch.version.hip is None:
        raise RuntimeError("ROCm is required")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":", 1)[0]
    if arch != "gfx950":
        raise RuntimeError(f"Expected gfx950, got {arch}")

    projection = PROJECTIONS[args.projection]
    n = int(projection["n"])
    k = int(projection["k"])
    payload = torch.load(args.capture, map_location="cpu", weights_only=False)
    prefix = f"gdn_stage.layer.{projection['layer_id']}."
    input_bf16 = payload[f"{prefix}{projection['input_stage']}"]
    weight = payload[f"{prefix}{projection['output_stage']}.weight"]
    weight_scale = payload[
        f"{prefix}{projection['output_stage']}.weight_scale"
    ]
    deployed_output = payload[f"{prefix}{projection['output_stage']}"]

    expected = {
        "input_bf16": (input_bf16, (M, k), torch.bfloat16),
        "weight": (weight, (n, k), torch.float8_e4m3fn),
        "weight_scale": (
            weight_scale,
            (n // BLOCK, k // BLOCK),
            torch.float32,
        ),
        "deployed_output": (
            deployed_output,
            (M, n),
            torch.bfloat16,
        ),
    }
    for name, (tensor, shape, dtype) in expected.items():
        if tuple(tensor.shape) != shape or tensor.dtype != dtype:
            raise ValueError(
                f"{name}: expected {shape} {dtype}, got "
                f"{tuple(tensor.shape)} {tensor.dtype}"
            )

    quant = get_hip_quant(aiter.QuantType.per_1x128)
    input_gpu = input_bf16.cuda()
    weight_gpu = weight.cuda()
    weight_scale_gpu = weight_scale.cuda()
    q_input, x_scale = quant(
        input_gpu,
        quant_dtype=aiter.dtypes.fp8,
        transpose_scale=True,
    )
    cktile_output = torch.empty(
        (M, n), dtype=torch.bfloat16, device=input_gpu.device
    )
    gemm_a8w8_blockscale_bpreshuffle_cktile(
        q_input,
        weight_gpu,
        x_scale,
        weight_scale_gpu,
        cktile_output,
    )

    logical_x_scale = (
        x_scale.view(k // BLOCK, M).transpose(0, 1).contiguous()
    )
    q_dequant = q_input.float() * logical_x_scale.float().repeat_interleave(
        BLOCK, dim=1
    )
    logical_weight = unshuffle_weight(weight_gpu, n, k)
    weight_dequant = logical_weight.float() * (
        weight_scale_gpu.float()
        .repeat_interleave(BLOCK, dim=0)
        .repeat_interleave(BLOCK, dim=1)
    )
    reference_output_f32 = torch.mm(q_dequant, weight_dequant.t())
    torch.cuda.synchronize()

    tensors = {
        "input_bf16": input_bf16,
        "q_input": q_input,
        "x_scale": x_scale,
        "weight": weight_gpu,
        "weight_scale": weight_scale_gpu,
        "deployed_output_bf16": deployed_output,
        "cktile_output_bf16": cktile_output,
        "reference_output_f32": reference_output_f32,
        "reference_output_bf16": reference_output_f32.to(torch.bfloat16),
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schema_version": 1,
        "architecture": arch,
        "rocm": torch.version.hip,
        "quantization": "FP8 E4M3, 128x128 weights, per-row 1x128 activations",
        "projection": args.projection,
        "shape": {"m": M, "n": n, "k": k},
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
