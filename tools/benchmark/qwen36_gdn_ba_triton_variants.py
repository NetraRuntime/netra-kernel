#!/usr/bin/env python3
"""Arithmetic probes for the Qwen GDN BA M16 BF16 projection.

These Triton kernels are comparison oracles only. Any promoted compute kernel
must be reimplemented as raw gfx950 AMDGCN under kernels/gfx950/.
"""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

import torch
import triton
import triton.language as tl


@triton.jit
def _gdn_ba_kernel(
    hidden,
    weight,
    output,
    BLOCK_M: tl.constexpr,
    BLOCK_N: tl.constexpr,
    BLOCK_K: tl.constexpr,
    NUM_K_TILES: tl.constexpr,
):
    pid_m = tl.program_id(0)
    pid_n = tl.program_id(1)
    offsets_m = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)
    offsets_n = pid_n * BLOCK_N + tl.arange(0, BLOCK_N)
    accumulator = tl.zeros((BLOCK_M, BLOCK_N), tl.float32)
    for k_tile in range(NUM_K_TILES):
        offsets_k = k_tile * BLOCK_K + tl.arange(0, BLOCK_K)
        a = tl.load(
            hidden + offsets_m[:, None] * 2048 + offsets_k[None, :],
            mask=offsets_m[:, None] < 16,
            other=0.0,
        )
        b = tl.load(
            weight + offsets_n[None, :] * 2048 + offsets_k[:, None],
            mask=offsets_n[None, :] < 64,
            other=0.0,
        )
        accumulator = tl.dot(a, b, accumulator)
    tl.store(
        output + offsets_m[:, None] * 64 + offsets_n[None, :],
        accumulator.to(tl.bfloat16),
        mask=(offsets_m[:, None] < 16) & (offsets_n[None, :] < 64),
    )


VARIANTS = (
    (16, 16, 16, 1),
    (16, 16, 32, 1),
    (16, 16, 64, 1),
    (16, 32, 16, 1),
    (16, 32, 32, 2),
    (16, 32, 64, 2),
    (16, 64, 16, 2),
    (16, 64, 32, 4),
    (16, 64, 64, 4),
    (32, 32, 64, 4),
    (64, 64, 64, 4),
    (128, 128, 64, 8),
)


def _read_bf16(path: Path, shape: tuple[int, ...]) -> torch.Tensor:
    raw = bytearray(path.read_bytes())
    expected_bytes = torch.tensor(shape).prod().item() * 2
    if len(raw) != expected_bytes:
        raise ValueError(
            f"{path}: expected {expected_bytes} bytes, got {len(raw)}"
        )
    return (
        torch.frombuffer(raw, dtype=torch.uint16)
        .view(torch.bfloat16)
        .reshape(shape)
        .clone()
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("capture_dir", type=Path)
    parser.add_argument("--iterations", type=int, default=200)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.iterations <= 0:
        parser.error("--iterations must be positive")

    properties = torch.cuda.get_device_properties(0)
    architecture = getattr(properties, "gcnArchName", "")
    if not architecture.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    hidden = _read_bf16(
        args.capture_dir / "hidden_bf16.bin", (16, 2048)
    ).cuda()
    weight = _read_bf16(
        args.capture_dir / "ba_weight_bf16.bin", (64, 2048)
    ).cuda()
    expected = _read_bf16(
        args.capture_dir / "expected_ba_bf16.bin", (16, 64)
    ).cuda()
    results = []
    for block_m, block_n, block_k, num_warps in VARIANTS:
        output = torch.empty_like(expected)
        grid = (
            triton.cdiv(16, block_m),
            triton.cdiv(64, block_n),
        )

        def launch() -> None:
            _gdn_ba_kernel[grid](
                hidden,
                weight,
                output,
                BLOCK_M=block_m,
                BLOCK_N=block_n,
                BLOCK_K=block_k,
                NUM_K_TILES=2048 // block_k,
                num_warps=num_warps,
                num_stages=2,
            )

        for _ in range(20):
            launch()
        torch.cuda.synchronize()
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        timings_us = []
        for _ in range(args.iterations):
            start.record()
            launch()
            stop.record()
            stop.synchronize()
            timings_us.append(start.elapsed_time(stop) * 1000.0)

        actual_fp32 = output.float()
        expected_fp32 = expected.float()
        difference = (actual_fp32 - expected_fp32).abs()
        result = {
            "block_m": block_m,
            "block_n": block_n,
            "block_k": block_k,
            "num_warps": num_warps,
            "grid": list(grid),
            "exact": torch.equal(output, expected),
            "element_mismatches": torch.count_nonzero(
                output != expected
            ).item(),
            "max_absolute": difference.max().item(),
            "cosine": torch.nn.functional.cosine_similarity(
                actual_fp32.reshape(1, -1),
                expected_fp32.reshape(1, -1),
            )[0].item(),
            "minimum_us": min(timings_us),
            "median_us": statistics.median(timings_us),
            "maximum_us": max(timings_us),
        }
        results.append(result)
        print(json.dumps(result, sort_keys=True), flush=True)

    payload = {
        "architecture": architecture,
        "capture_dir": str(args.capture_dir),
        "iterations": args.iterations,
        "status": "compiler_arithmetic_probe_only",
        "variants": results,
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n"
        )


if __name__ == "__main__":
    main()
