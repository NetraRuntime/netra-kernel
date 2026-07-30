#!/usr/bin/env python3
"""Bit-exact and shared-output HIP-event comparison for gfx1151 attention."""
from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def load(library: Path, hsaco: Path):
    handle = ctypes.CDLL(str(library.resolve()))
    init = handle.netra_extend_attention_wmma_init
    init.argtypes = [ctypes.c_char_p]
    init.restype = ctypes.c_int
    status = init(str(hsaco.resolve()).encode())
    if status:
        raise RuntimeError(f"failed to load {hsaco}: HIP status {status}")
    launch = handle.netra_extend_attention_wmma
    launch.argtypes = [ctypes.c_void_p] * 8 + [
        ctypes.c_uint32,
        ctypes.c_float,
        ctypes.c_void_p,
    ]
    launch.restype = ctypes.c_int
    return handle, launch


def samples(call, warmup: int, repetitions: int) -> list[float]:
    for _ in range(warmup):
        call()
    torch.cuda.synchronize()
    values = []
    for _ in range(repetitions):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        call()
        end.record()
        end.synchronize()
        values.append(start.elapsed_time(end))
    return values


def paired_samples(call_a, call_b, warmup: int, repetitions: int):
    for i in range(warmup):
        if i % 2:
            call_b()
            call_a()
        else:
            call_a()
            call_b()
    torch.cuda.synchronize()
    values_a = []
    values_b = []
    for i in range(repetitions):
        ordered = ((call_a, values_a), (call_b, values_b))
        if i % 2:
            ordered = tuple(reversed(ordered))
        for call, values in ordered:
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            call()
            end.record()
            end.synchronize()
            values.append(start.elapsed_time(end))
    return values_a, values_b


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline-library", type=Path, required=True)
    parser.add_argument("--baseline-hsaco", type=Path, required=True)
    parser.add_argument("--candidate-library", type=Path, required=True)
    parser.add_argument("--candidate-hsaco", type=Path, required=True)
    parser.add_argument("--candidate-label", default="candidate")
    parser.add_argument("--tokens", type=int, default=8192)
    parser.add_argument("--prefix", type=int, nargs="+", default=[0, 8192, 16384, 24576])
    parser.add_argument("--warmup", type=int, default=3)
    parser.add_argument("--repetitions", type=int, default=11)
    parser.add_argument("--interleaved", action="store_true")
    parser.add_argument("--seed", type=int, default=20260729)
    parser.add_argument("--scale", type=float, default=0.02)
    parser.add_argument("--page-size", type=int, default=1)
    parser.add_argument("--shuffle-pages", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.tokens % 64:
        raise SystemExit("raw specialization requires tokens divisible by 64")
    if args.page_size < 1 or 64 % args.page_size:
        raise SystemExit("page size must be a positive divisor of the N64 tile")
    if any(prefix % args.page_size for prefix in args.prefix):
        raise SystemExit("all prefixes must be page aligned")

    baseline_handle, baseline = load(args.baseline_library, args.baseline_hsaco)
    candidate_handle, candidate = load(args.candidate_library, args.candidate_hsaco)
    assert baseline_handle and candidate_handle
    stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
    rows = []
    for prefix in args.prefix:
        torch.manual_seed(args.seed)
        shape = (args.tokens, 16, 256)
        kv_shape = (args.tokens, 2, 256)
        q = (torch.randn(shape, device="cuda", dtype=torch.bfloat16) * args.scale).contiguous()
        k = (torch.randn(kv_shape, device="cuda", dtype=torch.bfloat16) * args.scale).contiguous()
        v = (torch.randn(kv_shape, device="cuda", dtype=torch.bfloat16) * args.scale).contiguous()
        cache_shape = (max(prefix, 1), 2, 256)
        k_buffer = (torch.randn(cache_shape, device="cuda", dtype=torch.bfloat16) * args.scale).contiguous()
        v_buffer = (torch.randn(cache_shape, device="cuda", dtype=torch.bfloat16) * args.scale).contiguous()
        if args.shuffle_pages and prefix:
            page_count = prefix // args.page_size
            page_ids = torch.randperm(page_count, device="cuda", dtype=torch.int64)
            page_offsets = torch.arange(
                args.page_size, device="cuda", dtype=torch.int64
            )
            indices = (
                page_ids[:, None] * args.page_size + page_offsets[None, :]
            ).reshape(-1)
        else:
            indices = torch.arange(prefix, device="cuda", dtype=torch.int64)
        indptr = torch.tensor([0, prefix], device="cuda", dtype=torch.int32)
        baseline_output = torch.empty_like(q)
        candidate_output = torch.empty_like(q)
        # Both timed variants write the same physical allocation; separate large
        # allocations are not a fair comparison on this unified-memory APU.
        timed_output = torch.empty_like(q)

        def call(function, output) -> None:
            status = function(
                pointer(q), pointer(k), pointer(v), pointer(output),
                pointer(k_buffer), pointer(v_buffer), pointer(indices), pointer(indptr),
                args.tokens, 0.0625, stream,
            )
            if status:
                raise RuntimeError(f"raw launch failed: HIP status {status}")

        call(baseline, baseline_output)
        call(candidate, candidate_output)
        torch.cuda.synchronize()
        delta = (baseline_output.float() - candidate_output.float()).abs()
        baseline_call = lambda: call(baseline, timed_output)
        candidate_call = lambda: call(candidate, timed_output)
        if args.interleaved:
            baseline_ms, candidate_ms = paired_samples(
                baseline_call, candidate_call, args.warmup, args.repetitions
            )
        else:
            baseline_ms = samples(baseline_call, args.warmup, args.repetitions)
            candidate_ms = samples(candidate_call, args.warmup, args.repetitions)
        baseline_median = statistics.median(baseline_ms)
        candidate_median = statistics.median(candidate_ms)
        row = {
            "prefix_tokens": prefix,
            "timing_output_shared_between_variants": True,
            "bit_equal": bool(torch.equal(baseline_output, candidate_output)),
            "max_abs": delta.max().item(),
            "mean_abs": delta.mean().item(),
            "baseline_median_ms": baseline_median,
            "candidate_median_ms": candidate_median,
            "speedup": baseline_median / candidate_median,
            "baseline_samples_ms": baseline_ms,
            "candidate_samples_ms": candidate_ms,
        }
        rows.append(row)
        print(json.dumps(row), flush=True)

    result = {
        "target": "gfx1151",
        "timing_output_shared_between_variants": True,
        "measurement_status": "measured_hip_events",
        "estimated_values": False,
        "tokens": args.tokens,
        "candidate_label": args.candidate_label,
        "page_size": args.page_size,
        "page_order": "deterministically_shuffled" if args.shuffle_pages else "sequential",
        "indices_contiguous_within_each_page": True,
        "sample_order": "alternating_ab_ba" if args.interleaved else "sequential_a_then_b",
        "rows": rows,
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
