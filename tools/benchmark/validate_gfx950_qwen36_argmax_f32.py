#!/usr/bin/env python3
"""Validate and time the raw gfx950 Qwen3.6 verification argmax."""

from __future__ import annotations

import argparse
import ctypes
import json
import math
from pathlib import Path

import torch


COLS = 248320
CHUNKS = 128


class Bridge:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.library = ctypes.CDLL(str(library))
        self.library.netra_qwen36_argmax_f32_load.argtypes = [ctypes.c_char_p]
        self.library.netra_qwen36_argmax_f32_load.restype = ctypes.c_int
        self.library.netra_qwen36_argmax_f32_launch.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_uint32,
            ctypes.c_void_p,
        ]
        self.library.netra_qwen36_argmax_f32_launch.restype = ctypes.c_int
        self.library.netra_qwen36_argmax_f32_last_error.argtypes = []
        self.library.netra_qwen36_argmax_f32_last_error.restype = ctypes.c_char_p
        self.check(
            self.library.netra_qwen36_argmax_f32_load(str(hsaco).encode()),
            "load",
        )

    def check(self, status: int, operation: str) -> None:
        if status == 0:
            return
        raw = self.library.netra_qwen36_argmax_f32_last_error()
        detail = raw.decode() if raw else f"status={status}"
        raise RuntimeError(f"{operation}: {detail}")

    def launch(
        self,
        output: torch.Tensor,
        partials: torch.Tensor,
        logits: torch.Tensor,
    ) -> None:
        stream = torch.cuda.current_stream(logits.device)
        self.check(
            self.library.netra_qwen36_argmax_f32_launch(
                ctypes.c_void_p(output.data_ptr()),
                ctypes.c_void_p(partials.data_ptr()),
                ctypes.c_void_p(logits.data_ptr()),
                ctypes.c_uint32(logits.shape[0]),
                ctypes.c_void_p(stream.cuda_stream),
            ),
            "launch",
        )


def special_cases(device: torch.device) -> list[tuple[str, torch.Tensor]]:
    cases: list[tuple[str, torch.Tensor]] = []

    ties = torch.full((16, COLS), -100.0, dtype=torch.float32, device=device)
    ties[:, 3] = 10.0
    ties[:, 200000] = 10.0
    cases.append(("ties_across_chunks", ties))

    zeros = torch.full((16, COLS), -0.0, dtype=torch.float32, device=device)
    zeros[:, 1::4096] = 0.0
    cases.append(("signed_zero", zeros))

    infinities = torch.full(
        (16, COLS), -math.inf, dtype=torch.float32, device=device
    )
    infinities[:, 17] = math.inf
    infinities[:, 100000] = math.inf
    cases.append(("infinities", infinities))

    nans = torch.randn((16, COLS), dtype=torch.float32, device=device)
    nans[:, 12345] = math.nan
    nans[:, 12000] = math.nan
    cases.append(("first_nan", nans))

    subnormal = torch.zeros((16, COLS), dtype=torch.float32, device=device)
    subnormal[:, 991] = torch.finfo(torch.float32).tiny / 2
    subnormal[:, 992] = torch.finfo(torch.float32).tiny
    cases.append(("subnormal", subnormal))
    return cases


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", required=True, type=Path)
    parser.add_argument("--hsaco", required=True, type=Path)
    parser.add_argument("--random-seeds", type=int, default=64)
    parser.add_argument("--iterations", type=int, default=1000)
    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise SystemExit("HIP device is unavailable")
    target = torch.cuda.get_device_properties(0).gcnArchName
    if "gfx950" not in target:
        raise SystemExit(f"requires gfx950, got {target}")
    device = torch.device("cuda:0")
    bridge = Bridge(args.bridge.resolve(), args.hsaco.resolve())

    case_results: list[dict[str, object]] = []
    inputs: list[tuple[str, torch.Tensor]] = special_cases(device)
    for rows in (1, 16, 32):
        for seed in range(args.random_seeds):
            generator = torch.Generator(device=device).manual_seed(
                2026073000 + rows * 1000 + seed
            )
            inputs.append(
                (
                    f"normal_rows{rows}_seed{seed}",
                    torch.randn(
                        (rows, COLS),
                        dtype=torch.float32,
                        device=device,
                        generator=generator,
                    ),
                )
            )

    for name, logits in inputs:
        rows = logits.shape[0]
        output = torch.empty((rows,), dtype=torch.int64, device=device)
        partials = torch.empty(
            (rows, CHUNKS, 2), dtype=torch.int32, device=device
        )
        reference = torch.argmax(logits, dim=-1)
        bridge.launch(output, partials, logits)
        torch.cuda.synchronize()
        mismatch = torch.nonzero(output != reference).flatten().cpu().tolist()
        case_results.append(
            {
                "name": name,
                "rows": rows,
                "mismatch_count": len(mismatch),
                "mismatch_rows": mismatch,
                "pass": not mismatch,
            }
        )
        del logits, output, partials, reference

    timing_logits = torch.randn(
        (16, COLS), dtype=torch.float32, device=device
    )
    raw_output = torch.empty((16,), dtype=torch.int64, device=device)
    torch_output = torch.empty_like(raw_output)
    partials = torch.empty(
        (16, CHUNKS, 2), dtype=torch.int32, device=device
    )
    for _ in range(20):
        bridge.launch(raw_output, partials, timing_logits)
        torch.argmax(timing_logits, dim=-1, out=torch_output)
    torch.cuda.synchronize()

    def elapsed_us(fn, iterations: int) -> float:
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        for _ in range(iterations):
            fn()
        end.record()
        end.synchronize()
        return begin.elapsed_time(end) * 1000.0 / iterations

    raw_mean_us = elapsed_us(
        lambda: bridge.launch(raw_output, partials, timing_logits),
        args.iterations,
    )
    torch_mean_us = elapsed_us(
        lambda: torch.argmax(timing_logits, dim=-1, out=torch_output),
        args.iterations,
    )
    torch.cuda.synchronize()
    timing_exact = torch.equal(raw_output, torch_output)
    passed = timing_exact and all(bool(result["pass"]) for result in case_results)
    result = {
        "target": target,
        "dtype": "torch.float32",
        "cols": COLS,
        "chunks": CHUNKS,
        "case_count": len(case_results),
        "random_seeds_per_row_shape": args.random_seeds,
        "row_shapes": [1, 16, 32],
        "failed_case_count": sum(
            not bool(case["pass"]) for case in case_results
        ),
        "timing_exact": timing_exact,
        "iterations": args.iterations,
        "raw_mean_us": raw_mean_us,
        "torch_mean_us": torch_mean_us,
        "speedup": torch_mean_us / raw_mean_us,
        "pass": passed,
        "cases": case_results,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
