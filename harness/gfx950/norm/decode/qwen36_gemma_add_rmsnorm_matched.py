#!/usr/bin/env python3
"""Alternate deployed AITER and raw gfx950 Gemma add+RMSNorm in one process."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch
from aiter import rmsnorm2d_fwd_with_add


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=2000)
    parser.add_argument("--warmup", type=int, default=100)
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


def duration_summary(values: list[float]) -> dict[str, float]:
    ordered = sorted(values)
    return {
        "minimum": min(values),
        "median": statistics.median(values),
        "mean": statistics.fmean(values),
        "p90": ordered[min(len(ordered) - 1, int(0.9 * len(ordered)))],
        "maximum": max(values),
    }


class Bridge:
    def __init__(self, library_path: Path, hsaco_path: Path) -> None:
        self.library = ctypes.CDLL(str(library_path))
        self.library.netra_qwen36_gemma_add_rmsnorm_load.argtypes = [
            ctypes.c_char_p
        ]
        self.library.netra_qwen36_gemma_add_rmsnorm_load.restype = ctypes.c_int
        self.library.netra_qwen36_gemma_add_rmsnorm_launch.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_double,
            ctypes.c_void_p,
        ]
        self.library.netra_qwen36_gemma_add_rmsnorm_launch.restype = ctypes.c_int
        self.library.netra_qwen36_gemma_add_rmsnorm_last_error.restype = (
            ctypes.c_char_p
        )
        self.check(
            self.library.netra_qwen36_gemma_add_rmsnorm_load(
                str(hsaco_path).encode()
            )
        )

    def check(self, status: int) -> None:
        if status == 0:
            return
        detail = self.library.netra_qwen36_gemma_add_rmsnorm_last_error()
        raise RuntimeError(detail.decode() if detail else f"status={status}")

    def launch(
        self,
        output: torch.Tensor,
        inp: torch.Tensor,
        residual: torch.Tensor,
        residual_out: torch.Tensor,
        weight: torch.Tensor,
    ) -> None:
        stream = torch.cuda.current_stream(inp.device)
        self.check(
            self.library.netra_qwen36_gemma_add_rmsnorm_launch(
                ctypes.c_void_p(output.data_ptr()),
                ctypes.c_void_p(inp.data_ptr()),
                ctypes.c_void_p(residual.data_ptr()),
                ctypes.c_void_p(residual_out.data_ptr()),
                ctypes.c_void_p(weight.data_ptr()),
                ctypes.c_double(1.0e-6),
                ctypes.c_void_p(stream.cuda_stream),
            )
        )


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(f"refusing to overwrite {args.output}")
    props = torch.cuda.get_device_properties(0)
    if not props.gcnArchName.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {props.gcnArchName}")
    inp = load_bf16(args.capture_dir / "input_bf16.bin", (1, 2048))
    residual = load_bf16(args.capture_dir / "residual_bf16.bin", (1, 2048))
    weight = load_bf16(args.capture_dir / "weight_bf16.bin", (2048,))
    deployed_output = load_bf16(
        args.capture_dir / "output_bf16.bin", (1, 2048)
    )
    deployed_residual = load_bf16(
        args.capture_dir / "residual_out_bf16.bin", (1, 2048)
    )
    aiter_output = torch.empty_like(inp)
    aiter_residual = torch.empty_like(inp)
    raw_output = torch.empty_like(inp)
    raw_residual = torch.empty_like(inp)
    bridge = Bridge(args.bridge, args.hsaco)

    def aiter_launch() -> None:
        rmsnorm2d_fwd_with_add(
            aiter_output,
            inp,
            residual,
            aiter_residual,
            weight,
            1.0e-6,
        )

    def raw_launch() -> None:
        bridge.launch(raw_output, inp, residual, raw_residual, weight)

    for index in range(args.warmup):
        (aiter_launch if index % 2 == 0 else raw_launch)()
    torch.cuda.synchronize()

    durations = {"aiter": [], "raw": []}
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)

    def time_one(name: str, launch: object) -> None:
        start.record()
        launch()
        end.record()
        end.synchronize()
        durations[name].append(float(start.elapsed_time(end)) * 1000.0)

    for index in range(args.iterations):
        order = (
            (("aiter", aiter_launch), ("raw", raw_launch))
            if index % 2 == 0
            else (("raw", raw_launch), ("aiter", aiter_launch))
        )
        for name, launch in order:
            time_one(name, launch)

    result = {
        "architecture": props.gcnArchName,
        "shape": {"m": 1, "n": 2048},
        "iterations_per_implementation": args.iterations,
        "duration_us": {
            name: duration_summary(values) for name, values in durations.items()
        },
        "raw_over_aiter_median": (
            statistics.median(durations["raw"])
            / statistics.median(durations["aiter"])
        ),
        "raw_output_bf16_mismatches": int(
            torch.ne(raw_output, deployed_output).sum().item()
        ),
        "raw_residual_bf16_mismatches": int(
            torch.ne(raw_residual, deployed_residual).sum().item()
        ),
        "aiter_output_bf16_mismatches": int(
            torch.ne(aiter_output, deployed_output).sum().item()
        ),
        "aiter_residual_bf16_mismatches": int(
            torch.ne(aiter_residual, deployed_residual).sum().item()
        ),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
