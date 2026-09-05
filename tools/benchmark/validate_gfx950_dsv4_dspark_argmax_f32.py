#!/usr/bin/env python3
"""Validate and time the raw gfx950 DeepSeek-V4 verification argmax."""

from __future__ import annotations

import argparse
import ctypes
import json
import math
from pathlib import Path

import torch


COLS = 129280
PADDED_COLS = 131072
CHUNKS = 16
TIMING_ROW_SHAPES = (64, 128, 256, 384)


class Bridge:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.library = ctypes.CDLL(str(library))
        self.library.netra_dsv4_dspark_argmax_f32_load.argtypes = [ctypes.c_char_p]
        self.library.netra_dsv4_dspark_argmax_f32_load.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_argmax_f32_launch.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_uint32,
            ctypes.c_void_p,
        ]
        self.library.netra_dsv4_dspark_argmax_f32_launch.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_argmax_bf16_base_bias_launch_v1.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_uint32,
            ctypes.c_uint32,
            ctypes.c_uint32,
            ctypes.c_uint32,
            ctypes.c_void_p,
        ]
        self.library.netra_dsv4_dspark_argmax_bf16_base_bias_launch_v1.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_argmax_f32_last_error.argtypes = []
        self.library.netra_dsv4_dspark_argmax_f32_last_error.restype = ctypes.c_char_p
        self.check(
            self.library.netra_dsv4_dspark_argmax_f32_load(str(hsaco).encode()),
            "load",
        )

    def check(self, status: int, operation: str) -> None:
        if status == 0:
            return
        raw = self.library.netra_dsv4_dspark_argmax_f32_last_error()
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
            self.library.netra_dsv4_dspark_argmax_f32_launch(
                ctypes.c_void_p(output.data_ptr()),
                ctypes.c_void_p(partials.data_ptr()),
                ctypes.c_void_p(logits.data_ptr()),
                ctypes.c_uint32(logits.shape[0]),
                ctypes.c_void_p(stream.cuda_stream),
            ),
            "launch",
        )

    def launch_two_input(
        self,
        output: torch.Tensor,
        partials: torch.Tensor,
        base: torch.Tensor,
        bias: torch.Tensor,
    ) -> None:
        self.check(
            self.two_input_status(output, partials, base, bias),
            "launch_two_input",
        )

    def two_input_status(
        self,
        output: torch.Tensor,
        partials: torch.Tensor,
        base: torch.Tensor,
        bias: torch.Tensor,
        *,
        valid_width: int = COLS,
        padded_width: int | None = None,
        base_row_stride: int | None = None,
        rows: int | None = None,
        base_pointer: int | None = None,
    ) -> int:
        stream = torch.cuda.current_stream(base.device)
        return int(
            self.library.netra_dsv4_dspark_argmax_bf16_base_bias_launch_v1(
                ctypes.c_void_p(output.data_ptr()),
                ctypes.c_void_p(partials.data_ptr()),
                ctypes.c_void_p(
                    base.data_ptr() if base_pointer is None else base_pointer
                ),
                ctypes.c_void_p(bias.data_ptr()),
                ctypes.c_uint32(valid_width),
                ctypes.c_uint32(
                    base.shape[1] if padded_width is None else padded_width
                ),
                ctypes.c_uint32(
                    base.stride(0)
                    if base_row_stride is None
                    else base_row_stride
                ),
                ctypes.c_uint32(base.shape[0] if rows is None else rows),
                ctypes.c_void_p(stream.cuda_stream),
            )
        )

    def error_text(self) -> str:
        raw = self.library.netra_dsv4_dspark_argmax_f32_last_error()
        return raw.decode() if raw else ""


def special_cases(device: torch.device) -> list[tuple[str, torch.Tensor]]:
    cases: list[tuple[str, torch.Tensor]] = []

    ties = torch.full((16, COLS), -100.0, dtype=torch.float32, device=device)
    ties[:, 3] = 10.0
    ties[:, 120000] = 10.0
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
    parser.add_argument("--random-seeds", type=int, default=16)
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
    for rows in (1, 6, 64, 384):
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

    two_input_results = []
    for rows in (1, 3, 7, 64, 384):
        generator = torch.Generator(device=device).manual_seed(424242 + rows)
        base_storage = None
        if rows == 7:
            base_storage = torch.randn(
                (rows, 5, PADDED_COLS),
                dtype=torch.bfloat16,
                device=device,
                generator=generator,
            )
            base = base_storage[:, 2, :]
        elif rows == 3:
            base = torch.randn(
                (rows, COLS),
                dtype=torch.bfloat16,
                device=device,
                generator=generator,
            )
        else:
            base = torch.randn(
                (rows, PADDED_COLS),
                dtype=torch.bfloat16,
                device=device,
                generator=generator,
            )
        bias = torch.randn(
            (rows, COLS),
            dtype=torch.bfloat16,
            device=device,
            generator=generator,
        )
        # Padding contains tempting maxima and must never participate.
        base[:, COLS:] = torch.inf
        # Exact ties, signed zero, infinity, and NaN ordering across chunks.
        base[:, 3] = 4
        bias[:, 3] = 5
        base[:, 120000] = 4
        bias[:, 120000] = 5
        if rows >= 3:
            base[1, 17] = torch.inf
            base[1, 100000] = torch.inf
            base[2, 12000] = torch.nan
            base[2, 12345] = torch.nan
        if rows >= 64:
            base[3, :COLS] = -100
            bias[3, :] = 0
            base[3, 0] = 10
            base[3, COLS - 1] = 10
            base[4, :COLS] = -100
            bias[4, :] = 0
            base[4, 8079] = 10
            base[4, 8080] = 10
            base[5, :COLS] = -torch.inf
            bias[5, :] = 0
            bias[5, COLS // 2] = torch.inf
        reference_logits = base[:, :COLS].float() + bias.float()
        reference = torch.argmax(reference_logits, dim=-1)
        output = torch.empty((rows,), dtype=torch.int64, device=device)
        partials = torch.empty((rows, CHUNKS, 2), dtype=torch.int32, device=device)
        repeat_count = 100 if rows == 7 else 1
        if rows == 3:
            nondefault_stream = torch.cuda.Stream(device=device)
            with torch.cuda.stream(nondefault_stream):
                bridge.launch_two_input(output, partials, base, bias)
            nondefault_stream.synchronize()
        else:
            for _ in range(repeat_count):
                bridge.launch_two_input(output, partials, base, bias)
        graph_replay = rows == 64
        if graph_replay:
            torch.cuda.synchronize()
            graph = torch.cuda.CUDAGraph()
            with torch.cuda.graph(graph):
                bridge.launch_two_input(output, partials, base, bias)
            graph.replay()
        torch.cuda.synchronize()
        mismatch = torch.nonzero(output != reference).flatten().cpu().tolist()
        two_input_results.append(
            {
                "rows": rows,
                "base_row_stride": base.stride(0),
                "nondefault_stream": rows == 3,
                "repeat_count": repeat_count,
                "graph_replay": graph_replay,
                "mismatch_count": len(mismatch),
                "mismatch_rows": mismatch,
                "pass": not mismatch,
            }
        )

    invalid_base = torch.zeros((1, COLS), dtype=torch.bfloat16, device=device)
    invalid_bias = torch.zeros((1, COLS), dtype=torch.bfloat16, device=device)
    invalid_output = torch.empty((1,), dtype=torch.int64, device=device)
    invalid_partials = torch.empty((1, CHUNKS, 2), dtype=torch.int32, device=device)
    invalid_specs = (
        ("valid_width", {"valid_width": COLS - 1}),
        ("padded_width", {"padded_width": COLS + 1}),
        ("base_row_stride", {"base_row_stride": COLS - 1}),
        ("unaligned_row_stride", {"base_row_stride": COLS + 1}),
        ("row_address_overflow", {"base_row_stride": 0xFFFFFFFC, "rows": 2}),
        ("rows_zero", {"rows": 0}),
        ("null_base", {"base_pointer": 0}),
        ("unaligned_base", {"base_pointer": invalid_base.data_ptr() + 2}),
    )
    invalid_results = []
    for name, overrides in invalid_specs:
        status = bridge.two_input_status(
            invalid_output,
            invalid_partials,
            invalid_base,
            invalid_bias,
            **overrides,
        )
        invalid_results.append(
            {
                "name": name,
                "status": status,
                "error": bridge.error_text(),
                "pass": status != 0,
            }
        )

    def elapsed_us(fn, iterations: int) -> float:
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        for _ in range(iterations):
            fn()
        end.record()
        end.synchronize()
        return begin.elapsed_time(end) * 1000.0 / iterations

    timings = []
    timing_exact = True
    for timing_rows in TIMING_ROW_SHAPES:
        timing_logits = torch.randn(
            (timing_rows, COLS), dtype=torch.float32, device=device
        )
        raw_output = torch.empty(
            (timing_rows,), dtype=torch.int64, device=device
        )
        torch_output = torch.empty_like(raw_output)
        partials = torch.empty(
            (timing_rows, CHUNKS, 2), dtype=torch.int32, device=device
        )
        for _ in range(20):
            bridge.launch(raw_output, partials, timing_logits)
            torch.argmax(timing_logits, dim=-1, out=torch_output)
        torch.cuda.synchronize()
        raw_mean_us = elapsed_us(
            lambda: bridge.launch(raw_output, partials, timing_logits),
            args.iterations,
        )
        torch_mean_us = elapsed_us(
            lambda: torch.argmax(timing_logits, dim=-1, out=torch_output),
            args.iterations,
        )
        torch.cuda.synchronize()
        exact = torch.equal(raw_output, torch_output)
        timing_exact &= exact
        timings.append(
            {
                "rows": timing_rows,
                "raw_mean_us": raw_mean_us,
                "torch_mean_us": torch_mean_us,
                "speedup": torch_mean_us / raw_mean_us,
                "exact": exact,
            }
        )
    passed = (
        timing_exact
        and all(bool(result["pass"]) for result in case_results)
        and all(bool(result["pass"]) for result in two_input_results)
        and all(bool(result["pass"]) for result in invalid_results)
    )
    result = {
        "target": target,
        "dtype": "torch.float32",
        "cols": COLS,
        "chunks": CHUNKS,
        "timing_row_shapes": list(TIMING_ROW_SHAPES),
        "case_count": len(case_results),
        "random_seeds_per_row_shape": args.random_seeds,
        "row_shapes": [1, 6, 64, 384],
        "failed_case_count": sum(
            not bool(case["pass"]) for case in case_results
        ),
        "timing_exact": timing_exact,
        "iterations": args.iterations,
        "timings": timings,
        "pass": passed,
        "cases": case_results,
        "two_input_cases": two_input_results,
        "invalid_abi_cases": invalid_results,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
