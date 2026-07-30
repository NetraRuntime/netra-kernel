#!/usr/bin/env python3
"""Exact raw-vs-raw recompute W/U gate for Netra gfx1151."""
import argparse
import ctypes
import json
import socket
import statistics
from pathlib import Path

import torch
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices
from sglang.kernels.ops.attention.fla.wy_fast import recompute_w_u_fwd_kernel


def ptr(tensor):
    return ctypes.c_void_p(tensor.data_ptr())


def measure(operation, samples):
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--launcher-so", type=Path, required=True)
    parser.add_argument("--baseline-hsaco", type=Path, required=True)
    parser.add_argument("--candidate-hsaco", type=Path, required=True)
    parser.add_argument(
        "--candidate-symbol",
        default="recompute_w_u_reuse_a_ordered_breuse_gfx1151",
    )
    parser.add_argument("--samples", type=int, default=11)
    parser.add_argument("--seed", type=int, default=3008)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("refusing to run outside Netra")

    lib = ctypes.CDLL(str(args.launcher_so))
    lib.netra_recompute_w_u_dual_init.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    lib.netra_recompute_w_u_dual_init.restype = ctypes.c_int
    lib.netra_recompute_w_u_dual_launch.argtypes = (
        [ctypes.c_int] + [ctypes.c_void_p] * 9
        + [ctypes.c_uint, ctypes.c_void_p]
    )
    lib.netra_recompute_w_u_dual_launch.restype = ctypes.c_int
    status = lib.netra_recompute_w_u_dual_init(
        str(args.baseline_hsaco).encode(),
        str(args.candidate_hsaco).encode(),
        args.candidate_symbol.encode(),
    )
    if status:
        raise RuntimeError(f"dual init HIP status {status}")

    torch.manual_seed(args.seed)
    k = (torch.randn((1, 8192, 16, 128), device="cuda") * 0.02).bfloat16()
    v = (torch.randn((1, 8192, 32, 128), device="cuda") * 0.02).bfloat16()
    beta = torch.sigmoid(torch.randn((1, 8192, 32), device="cuda"))
    A = (torch.randn((1, 8192, 32, 64), device="cuda") * 0.01).bfloat16()
    g = (-torch.rand((1, 8192, 32), device="cuda") * 0.002).cumsum(1)
    cu = torch.tensor([0, 8192], device="cuda", dtype=torch.int32)
    ci = prepare_chunk_indices(cu, 64)
    ref_w = torch.empty((1, 8192, 32, 128), device="cuda", dtype=torch.bfloat16)
    ref_u = torch.empty_like(v)
    base_w = torch.empty_like(ref_w)
    base_u = torch.empty_like(ref_u)
    cand_w = torch.empty_like(ref_w)
    cand_u = torch.empty_like(ref_u)
    # Use identical output addresses for both timed kernels. Separate allocations
    # can differ by several percent on this memory-bound APU kernel.
    timed_w = torch.empty_like(ref_w)
    timed_u = torch.empty_like(ref_u)

    def raw(which, out_w, out_u):
        status = lib.netra_recompute_w_u_dual_launch(
            which, ptr(k), ptr(v), ptr(beta), ptr(out_w), ptr(out_u), ptr(A),
            ptr(g), ptr(cu), ptr(ci), 8192,
            ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
        )
        if status:
            raise RuntimeError(f"launch HIP status {status}")

    def oracle():
        recompute_w_u_fwd_kernel[(128, 32)](
            k=k, v=v, beta=beta, w=ref_w, u=ref_u, A=A, g=g,
            cu_seqlens=cu, chunk_indices=ci, T=8192, H=32, Hg=16,
            K=128, V=128, BT=64, BK=64, BV=64, IS_VARLEN=True,
            num_warps=2, num_stages=1,
        )

    baseline = lambda: raw(0, base_w, base_u)
    candidate = lambda: raw(1, cand_w, cand_u)
    timed_baseline = lambda: raw(0, timed_w, timed_u)
    timed_candidate = lambda: raw(1, timed_w, timed_u)
    candidate()
    torch.cuda.synchronize()
    eager_w = cand_w.clone()
    eager_u = cand_u.clone()
    candidate()
    torch.cuda.synchronize()
    repeat_equal = torch.equal(cand_w, eager_w) and torch.equal(cand_u, eager_u)
    oracle()
    baseline()
    torch.cuda.synchronize()

    base_w_diff = (base_w.float() - ref_w.float()).abs()
    base_u_diff = (base_u.float() - ref_u.float()).abs()
    cand_w_diff = (cand_w.float() - ref_w.float()).abs()
    cand_u_diff = (cand_u.float() - ref_u.float()).abs()
    raw_equal = torch.equal(base_w, cand_w) and torch.equal(base_u, cand_u)

    baseline_times = []
    candidate_times = []
    for index in range(args.samples):
        first, second = (
            (timed_baseline, timed_candidate)
            if index % 2 == 0
            else (timed_candidate, timed_baseline)
        )
        first_ms = measure(first, 1)[0]
        second_ms = measure(second, 1)[0]
        if index % 2 == 0:
            baseline_times.append(first_ms)
            candidate_times.append(second_ms)
        else:
            candidate_times.append(first_ms)
            baseline_times.append(second_ms)

    graph = torch.cuda.CUDAGraph()
    candidate()
    torch.cuda.synchronize()
    eager_w.copy_(cand_w)
    eager_u.copy_(cand_u)
    with torch.cuda.graph(graph):
        candidate()
    graph.replay()
    torch.cuda.synchronize()
    graph_equal = torch.equal(cand_w, eager_w) and torch.equal(cand_u, eager_u)
    graph_times = measure(graph.replay, args.samples)

    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "shape": "B1_T8192_H32_Hg16_K128_V128_BT64",
        "timing_outputs_shared_between_variants": True,
        "baseline_median_hip_event_ms": statistics.median(baseline_times),
        "candidate_median_hip_event_ms": statistics.median(candidate_times),
        "speedup": statistics.median(baseline_times) / statistics.median(candidate_times),
        "baseline_samples_ms": baseline_times,
        "candidate_samples_ms": candidate_times,
        "raw_bit_equal": raw_equal,
        "candidate_repeat_bit_equal": repeat_equal,
        "baseline_w_max_abs_vs_triton": base_w_diff.max().item(),
        "baseline_u_max_abs_vs_triton": base_u_diff.max().item(),
        "candidate_w_max_abs_vs_triton": cand_w_diff.max().item(),
        "candidate_u_max_abs_vs_triton": cand_u_diff.max().item(),
        "finite": torch.isfinite(cand_w).all().item() and torch.isfinite(cand_u).all().item(),
        "graph_bit_equal_to_eager": graph_equal,
        "graph_replay_median_ms": statistics.median(graph_times),
        "graph_samples_ms": graph_times,
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    print(rendered, end="")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)


if __name__ == "__main__":
    main()
