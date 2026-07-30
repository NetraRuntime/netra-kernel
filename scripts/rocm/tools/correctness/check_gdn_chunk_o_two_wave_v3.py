#!/usr/bin/env python3
"""Repeated eager/graph gate for the two-wave-v3 raw gfx1151 GDN chunk-o."""

from __future__ import annotations

import argparse
import ctypes
import json
import socket
import statistics
from pathlib import Path

import torch

from sglang.kernels.ops.attention.fla.chunk_o import chunk_fwd_kernel_o
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices


def measure(operation, samples: int) -> list[float]:
    for _ in range(3):
        operation()
    torch.cuda.synchronize()
    values = []
    for _ in range(samples):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        operation()
        end.record()
        end.synchronize()
        values.append(begin.elapsed_time(end))
    return values


def error(output: torch.Tensor, reference: torch.Tensor) -> dict[str, object]:
    finite = bool(torch.isfinite(output).all().item())
    difference = (output.float() - reference.float()).abs()
    sanitized = difference.nan_to_num(
        nan=float("inf"), posinf=float("inf"), neginf=float("inf")
    )
    flat_index = int(sanitized.argmax().item())
    shape = output.shape
    index = []
    for extent in reversed(shape):
        index.append(flat_index % extent)
        flat_index //= extent
    return {
        "finite": finite,
        "max_abs_error": float(sanitized.max().item()),
        "mean_abs_error": float(sanitized.mean().item()),
        "worst_index": list(reversed(index)),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--eager-repeats", type=int, default=30)
    parser.add_argument("--graph-repeats", type=int, default=30)
    parser.add_argument("--samples", type=int, default=11)
    parser.add_argument("--seed", type=int, default=2907)
    parser.add_argument("--tolerance", type=float, default=3.814697265625e-6)
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--library",
        type=Path,
        default=Path("build/experiments/gdn-chunk-o-two-wave-v3/libgdn_chunk_o_two_wave_v3.so"),
    )
    parser.add_argument(
        "--hsaco",
        type=Path,
        default=Path("build/experiments/gdn-chunk-o-two-wave-v3/gdn_chunk_o_bv32_two_wave_v3_gfx1151.hsaco"),
    )
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("refusing to run outside the Netra LXC")


    candidate_lib = ctypes.CDLL(str(args.library))
    candidate_lib.netra_gdn_chunk_o_two_wave_v3_init.argtypes = [ctypes.c_char_p]
    candidate_lib.netra_gdn_chunk_o_two_wave_v3_init.restype = ctypes.c_int
    candidate_lib.netra_gdn_chunk_o_two_wave_v3.argtypes = (
        [ctypes.c_void_p] * 8
        + [ctypes.c_float, ctypes.c_uint, ctypes.c_void_p]
    )
    candidate_lib.netra_gdn_chunk_o_two_wave_v3.restype = ctypes.c_int
    status = candidate_lib.netra_gdn_chunk_o_two_wave_v3_init(
        str(args.hsaco).encode()
    )
    if status:
        raise RuntimeError(f"two-wave-v3 module initialization failed with {status}")
    torch.manual_seed(args.seed)
    q = (torch.randn((1, 8192, 16, 128), device="cuda") * 0.01).bfloat16()
    k = (torch.randn_like(q.float()) * 0.01).bfloat16()
    v = (torch.randn((1, 8192, 32, 128), device="cuda") * 0.01).bfloat16()
    h = (
        torch.randn((1, 128, 32, 128, 128), device="cuda") * 0.01
    ).bfloat16()
    g = (-torch.rand((1, 8192, 32), device="cuda") * 0.002).cumsum(1)
    cu_seqlens = torch.tensor([0, 8192], device="cuda", dtype=torch.int32)
    chunk_indices = prepare_chunk_indices(cu_seqlens, 64)
    scale = 128**-0.5
    reference = torch.empty_like(v)
    output = torch.empty_like(v)

    def triton_reference() -> None:
        chunk_fwd_kernel_o[(4, 128, 32)](
            q,
            k,
            v,
            h,
            g,
            reference,
            cu_seqlens,
            chunk_indices,
            scale,
            T=8192,
            H=32,
            Hg=16,
            K=128,
            V=128,
            BT=64,
            BK=64,
            BV=32,
            USE_G=True,
            IS_VARLEN=True,
            num_warps=8,
            num_stages=2,
        )

    def raw() -> None:
        pointers = [
            ctypes.c_void_p(tensor.data_ptr())
            for tensor in (q, k, v, h, g, output, cu_seqlens, chunk_indices)
        ]
        status = candidate_lib.netra_gdn_chunk_o_two_wave_v3(
            *pointers,
            ctypes.c_float(scale),
            8192,
            ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
        )
        if status:
            raise RuntimeError(f"two-wave-v3 launch failed with status {status}")

    triton_reference()
    torch.cuda.synchronize()

    eager_errors = []
    for _ in range(args.eager_repeats):
        output.fill_(float("nan"))
        raw()
        torch.cuda.synchronize()
        eager_errors.append(error(output, reference))

    correctness_graph = torch.cuda.CUDAGraph()
    output.fill_(float("nan"))
    raw()
    torch.cuda.synchronize()
    with torch.cuda.graph(correctness_graph):
        output.fill_(float("nan"))
        raw()
    graph_errors = []
    for _ in range(args.graph_repeats):
        correctness_graph.replay()
        torch.cuda.synchronize()
        graph_errors.append(error(output, reference))

    timing_graph = torch.cuda.CUDAGraph()
    raw()
    torch.cuda.synchronize()
    with torch.cuda.graph(timing_graph):
        raw()
    raw_ms = measure(raw, args.samples)
    graph_ms = measure(timing_graph.replay, args.samples)
    triton_ms = measure(triton_reference, args.samples)

    def failed(item: dict[str, object]) -> bool:
        return (not item["finite"]) or item["max_abs_error"] > args.tolerance

    all_errors = eager_errors + graph_errors
    eager_failure_details = [
        {"repeat": repeat, **item}
        for repeat, item in enumerate(eager_errors)
        if failed(item)
    ]
    graph_failure_details = [
        {"repeat": repeat, **item}
        for repeat, item in enumerate(graph_errors)
        if failed(item)
    ]
    failures = len(eager_failure_details) + len(graph_failure_details)
    result = {
        "target": "gfx1151",
        "candidate": "raw_gdn_chunk_o_bv32_two_wave_v3_gfx1151",
        "candidate_hsaco": str(args.hsaco),
        "candidate_library": str(args.library),
        "measurement_status": "measured",
        "shape": "B1_T8192_H32_Hg16_K128_V128_BT64",
        "eager_repeats": args.eager_repeats,
        "graph_repeats": args.graph_repeats,
        "correctness_failures": failures,
        "eager_correctness_failures": len(eager_failure_details),
        "graph_correctness_failures": len(graph_failure_details),
        "eager_failure_details": eager_failure_details,
        "graph_failure_details": graph_failure_details,
        "finite_all": all(item["finite"] for item in all_errors),
        "max_abs_error": max(item["max_abs_error"] for item in all_errors),
        "max_mean_abs_error": max(item["mean_abs_error"] for item in all_errors),
        "tolerance": args.tolerance,
        "raw_median_hip_event_ms": statistics.median(raw_ms),
        "graph_replay_median_hip_event_ms": statistics.median(graph_ms),
        "triton_median_hip_event_ms": statistics.median(triton_ms),
        "raw_speedup_vs_tuned_triton": statistics.median(triton_ms)
        / statistics.median(raw_ms),
        "samples": args.samples,
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
