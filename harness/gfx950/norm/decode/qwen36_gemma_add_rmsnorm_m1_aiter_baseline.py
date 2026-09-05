#!/usr/bin/env python3
"""Time deployed AITER Gemma add+RMSNorm on retained Qwen operands."""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from pathlib import Path

import torch
from aiter import rmsnorm2d_fwd_with_add


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=500)
    parser.add_argument("--warmup", type=int, default=20)
    return parser.parse_args()


def load_bf16(path: Path, shape: tuple[int, ...]) -> torch.Tensor:
    payload = bytearray(path.read_bytes())
    return (
        torch.frombuffer(payload, dtype=torch.uint8)
        .clone()
        .view(torch.bfloat16)
        .reshape(shape)
        .cuda()
    )


def tensor_sha256(tensor: torch.Tensor) -> str:
    payload = (
        tensor.detach()
        .contiguous()
        .cpu()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )
    return hashlib.sha256(payload).hexdigest()


def main() -> None:
    args = parse_args()
    props = torch.cuda.get_device_properties(0)
    if not props.gcnArchName.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {props.gcnArchName}")
    capture = args.capture_dir
    inp = load_bf16(capture / "input_bf16.bin", (1, 2048))
    residual = load_bf16(capture / "residual_bf16.bin", (1, 2048))
    weight = load_bf16(capture / "weight_bf16.bin", (2048,))
    deployed_output = load_bf16(capture / "output_bf16.bin", (1, 2048))
    deployed_residual = load_bf16(
        capture / "residual_out_bf16.bin", (1, 2048)
    )
    output = torch.empty_like(inp)
    residual_out = torch.empty_like(inp)

    def launch() -> None:
        rmsnorm2d_fwd_with_add(
            output, inp, residual, residual_out, weight, 1.0e-6
        )

    for _ in range(args.warmup):
        launch()
    torch.cuda.synchronize()
    durations_us: list[float] = []
    output_hashes: list[str] = []
    residual_hashes: list[str] = []
    for _ in range(args.iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        launch()
        end.record()
        end.synchronize()
        durations_us.append(float(start.elapsed_time(end)) * 1000.0)
        output_hashes.append(tensor_sha256(output))
        residual_hashes.append(tensor_sha256(residual_out))

    result = {
        "architecture": props.gcnArchName,
        "shape": {"m": 1, "n": 2048},
        "iterations": args.iterations,
        "output_bf16_mismatches": int(
            torch.ne(output, deployed_output).sum().item()
        ),
        "residual_bf16_mismatches": int(
            torch.ne(residual_out, deployed_residual).sum().item()
        ),
        "unique_output_hashes": len(set(output_hashes)),
        "unique_residual_hashes": len(set(residual_hashes)),
        "duration_us": {
            "minimum": min(durations_us),
            "median": statistics.median(durations_us),
            "p90": sorted(durations_us)[
                min(len(durations_us) - 1, int(0.9 * len(durations_us)))
            ],
            "maximum": max(durations_us),
            "mean": statistics.fmean(durations_us),
        },
    }
    if args.output.exists():
        raise FileExistsError(f"refusing to overwrite {args.output}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
