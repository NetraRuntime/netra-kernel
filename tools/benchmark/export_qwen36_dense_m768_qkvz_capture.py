#!/usr/bin/env python3
"""Build an exact M=768 QKVZ fixture from retained Qwen3.6 operands."""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from pathlib import Path

import torch

from aiter.ops.gemm_op_a8w8 import (
    gemm_a8w8_blockscale_bpreshuffle_cktile,
)

M, N, K, BLOCK = 768, 12288, 2048, 128


def load(path: Path, dtype: torch.dtype, shape: tuple[int, ...]) -> torch.Tensor:
    payload = bytearray(path.read_bytes())
    return torch.frombuffer(payload, dtype=torch.uint8).clone().view(dtype).reshape(shape)


def raw(tensor: torch.Tensor) -> bytes:
    return tensor.detach().contiguous().cpu().view(torch.uint8).numpy().tobytes()


def sha(payload: bytes) -> str:
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
    parser.add_argument("--hidden-export", type=Path, required=True)
    parser.add_argument("--weight-capture", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=200)
    args = parser.parse_args()

    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":", 1)[0]
    if arch != "gfx950":
        raise RuntimeError(f"Expected gfx950, got {arch}")

    q_input = load(
        args.hidden_export / "hidden_fp8.bin",
        torch.float8_e4m3fn,
        (M, K),
    )
    logical_scale = load(
        args.hidden_export / "hidden_scale_f32.bin",
        torch.float32,
        (M, K // BLOCK),
    )
    weight = load(
        args.weight_capture / "weight.bin",
        torch.float8_e4m3fn,
        (N, K),
    )
    weight_scale = load(
        args.weight_capture / "weight_scale.bin",
        torch.float32,
        (N // BLOCK, K // BLOCK),
    )

    q_gpu = q_input.cuda()
    # AITER transpose_scale=True stores [K/128,M] while retaining a logical
    # [M,K/128] tensor shape. Recreate that exact byte layout from the retained
    # row-major MoE hidden-state scale capture.
    x_scale = logical_scale.t().contiguous().view(M, K // BLOCK).cuda()
    w_gpu = weight.cuda()
    ws_gpu = weight_scale.cuda()
    output = torch.empty((M, N), dtype=torch.bfloat16, device="cuda")

    def launch() -> None:
        gemm_a8w8_blockscale_bpreshuffle_cktile(
            q_gpu, w_gpu, x_scale, ws_gpu, output
        )

    for _ in range(10):
        launch()
    torch.cuda.synchronize()
    samples: list[float] = []
    hashes: list[str] = []
    for _ in range(args.iterations):
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        start.record()
        launch()
        stop.record()
        stop.synchronize()
        samples.append(start.elapsed_time(stop) * 1000.0)
        hashes.append(sha(raw(output)))

    q_dequant = q_gpu.float().reshape(M, K // BLOCK, BLOCK)
    q_dequant.mul_(logical_scale.cuda()[:, :, None])
    logical_weight = unshuffle_weight(w_gpu).float().reshape(
        N // BLOCK, BLOCK, K // BLOCK, BLOCK
    )
    logical_weight.mul_(ws_gpu[:, None, :, None])
    reference = torch.mm(
        q_dequant.reshape(M, K),
        logical_weight.reshape(N, K).t(),
    )
    torch.cuda.synchronize()

    tensors = {
        "q_input": q_gpu,
        "x_scale": x_scale,
        "weight": w_gpu,
        "weight_scale": ws_gpu,
        "cktile_output_bf16": output,
        "reference_output_f32": reference,
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schema_version": 1,
        "architecture": arch,
        "rocm": torch.version.hip,
        "quantization": "FP8 E4M3, 128x128 weights, per-row 1x128 activations",
        "shape": {"m": M, "n": N, "k": K},
        "source_hidden_export": str(args.hidden_export),
        "source_weight_capture": str(args.weight_capture),
        "cktile": {
            "iterations": args.iterations,
            "unique_output_hashes": len(set(hashes)),
            "minimum_us": min(samples),
            "median_us": statistics.median(samples),
            "p90_us": sorted(samples)[int(0.9 * (len(samples) - 1))],
            "maximum_us": max(samples),
        },
        "tensors": {},
    }
    for name, tensor in tensors.items():
        payload = raw(tensor)
        filename = f"{name}.bin"
        (args.output_dir / filename).write_bytes(payload)
        manifest["tensors"][name] = {
            "filename": filename,
            "shape": list(tensor.shape),
            "dtype": str(tensor.dtype),
            "bytes": len(payload),
            "sha256": sha(payload),
        }
    (args.output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))
    if len(set(hashes)) != 1:
        raise SystemExit("CKTile output was nondeterministic")


if __name__ == "__main__":
    main()

