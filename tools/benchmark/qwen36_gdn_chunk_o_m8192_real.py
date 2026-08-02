#!/usr/bin/env python3
"""Exact real-checkpoint gate for the experimental gfx950 GDN chunk-o kernel."""

from __future__ import annotations

import argparse
import ctypes
import json
import math
import statistics
from pathlib import Path

import torch


ATOL = 0.03125
RTOL = 0.010
COSINE_MIN = 0.9995


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--layer-pass", type=Path, required=True)
    parser.add_argument("--h-pass", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path)
    parser.add_argument("--kernel-name", default="qwen36_gdn_chunk_o_m8192_bv64_gfx950")
    parser.add_argument("--triton-fixed-shape", action="store_true")
    parser.add_argument("--triton-bk", type=int, default=128)
    parser.add_argument("--triton-bv", type=int, default=64)
    parser.add_argument("--triton-warps", type=int, default=4)
    parser.add_argument("--triton-stages", type=int, default=2)
    parser.add_argument("--test-sglang-wrapper", action="store_true")
    parser.add_argument("--iterations", type=int, default=50)
    parser.add_argument("--graph-iterations", type=int, default=100)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def distribution(values: list[float]) -> dict[str, float | int]:
    ordered = sorted(values)
    return {
        "count": len(ordered),
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, math.ceil(0.9 * len(ordered)) - 1)],
        "minimum_us": ordered[0],
        "maximum_us": ordered[-1],
    }


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    a = actual.float()
    e = expected.float()
    delta = (a - e).abs()
    denominator = e.abs().clamp_min(1e-6)
    relative = delta / denominator
    significant = torch.maximum(a.abs(), e.abs()) >= ATOL
    relative_fail = significant & (relative > RTOL)
    finite = bool(torch.isfinite(a).all().item())
    cosine = float(torch.nn.functional.cosine_similarity(a.flatten(), e.flatten(), dim=0))
    maximum = int(delta.argmax().item())
    return {
        "finite": finite,
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "max_relative_significant": float(relative[significant].max().item()),
        "mean_abs": float(delta.mean().item()),
        "rmse": float(torch.sqrt(torch.mean((a - e) ** 2)).item()),
        "cosine": cosine,
        "worst_flat_index": maximum,
        "absolute_fail_count": int((delta > ATOL).sum().item()),
        "relative_fail_count": int(relative_fail.sum().item()),
        "pass": bool(
            finite
            and float(delta.max().item()) <= ATOL
            and not bool(relative_fail.any().item())
            and cosine >= COSINE_MIN
        ),
    }


def time_call(call, iterations: int, device: torch.device) -> dict[str, float | int]:
    for _ in range(10):
        call()
    torch.cuda.synchronize(device)
    values: list[float] = []
    for _ in range(iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        call()
        end.record()
        end.synchronize()
        values.append(float(start.elapsed_time(end) * 1000.0))
    return distribution(values)


def capture_graph(call, device: torch.device):
    call()
    torch.cuda.synchronize(device)
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        call()
    torch.cuda.synchronize(device)
    return graph.replay


def main() -> None:
    args = parse_args()
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")
    if args.output.exists():
        raise FileExistsError(args.output)
    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    from sglang.srt.layers.attention.fla.chunk_o import chunk_fwd_kernel_o
    from sglang.jit_kernel.triton.gdn_l2norm import l2norm_gather

    layer = torch.load(args.layer_pass, map_location="cpu", weights_only=True)
    h_pass = torch.load(args.h_pass, map_location="cpu", weights_only=True)

    q = l2norm_gather(layer["q"].contiguous().to(device), use_rsqrt=False)
    k_from_layer = l2norm_gather(
        layer["k"].contiguous().to(device), use_rsqrt=False
    )
    k = h_pass["k_normalized"].contiguous().to(device)
    if not torch.equal(k_from_layer, k):
        raise RuntimeError("layer-pass normalization does not reproduce captured k_normalized")
    v = h_pass["v_new"].contiguous().to(device)
    h = h_pass["h"].contiguous().to(device)
    g = h_pass["g_cumsum"].contiguous().to(device)
    cu_seqlens = h_pass["cu_seqlens"].contiguous().to(device)
    chunk_indices = h_pass["chunk_indices"].contiguous().to(device)
    expected = layer["output"].contiguous().to(device)
    del layer, h_pass, k_from_layer

    triton_output = torch.empty_like(expected)
    raw_output = torch.empty_like(expected)
    scale = 128.0**-0.5

    def run_triton() -> None:
        chunk_fwd_kernel_o[((128 + args.triton_bv - 1) // args.triton_bv, 128, 32)](
            q,
            k,
            v,
            h,
            g,
            triton_output,
            None if args.triton_fixed_shape else cu_seqlens,
            None if args.triton_fixed_shape else chunk_indices,
            scale,
            T=8192,
            H=32,
            Hg=16,
            K=128,
            V=128,
            BT=64,
            BK=args.triton_bk,
            BV=args.triton_bv,
            USE_G=True,
            IS_VARLEN=not args.triton_fixed_shape,
            num_warps=args.triton_warps,
            num_stages=args.triton_stages,
        )

    bridge_path = args.build_dir / "libqwen36_gdn_chunk_o_m8192_bridge.so"
    hsaco_path = args.hsaco or (
        args.build_dir / "qwen36_gdn_chunk_o_m8192_bv64_gfx950.hsaco"
    )
    bridge = ctypes.CDLL(str(bridge_path))
    bridge.netra_qwen36_gdn_chunk_o_m8192_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    bridge.netra_qwen36_gdn_chunk_o_m8192_load.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_chunk_o_m8192_launch.argtypes = [
        *([ctypes.c_void_p] * 8),
        ctypes.c_float,
        ctypes.c_void_p,
    ]
    bridge.netra_qwen36_gdn_chunk_o_m8192_launch.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_chunk_o_m8192_last_error.restype = ctypes.c_char_p
    status = bridge.netra_qwen36_gdn_chunk_o_m8192_load(
        str(hsaco_path).encode(), args.kernel_name.encode()
    )
    if status:
        raise RuntimeError(bridge.netra_qwen36_gdn_chunk_o_m8192_last_error().decode())

    def run_raw() -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_chunk_o_m8192_launch(
            pointer(q),
            pointer(k),
            pointer(v),
            pointer(h),
            pointer(g),
            pointer(raw_output),
            pointer(cu_seqlens),
            pointer(chunk_indices),
            ctypes.c_float(scale),
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_chunk_o_m8192_last_error().decode()
            )

    run_triton()
    run_raw()
    wrapper_output = None
    if args.test_sglang_wrapper:
        from sglang.srt.layers.attention.fla.chunk_o import chunk_fwd_o
        from sglang.srt.layers.attention.linear.netra_gfx950_qwen36_gdn_chunk_o_m8192 import (
            maybe_load,
        )

        maybe_load()
        wrapper_output = chunk_fwd_o(
            q=q,
            k=k,
            v=v,
            h=h,
            g=g,
            scale=scale,
            cu_seqlens=cu_seqlens,
            chunk_size=64,
        )
    torch.cuda.synchronize(device)
    correctness = {
        "triton_vs_capture": compare(triton_output, expected),
        "raw_vs_triton": compare(raw_output, triton_output),
        "raw_vs_capture": compare(raw_output, expected),
    }
    if wrapper_output is not None:
        correctness["sglang_wrapper_vs_capture"] = compare(wrapper_output, expected)
    timing = {
        "deployed_triton": time_call(run_triton, args.iterations, device),
        "raw_gfx950": time_call(run_raw, args.iterations, device),
    }
    triton_replay = capture_graph(run_triton, device)
    raw_replay = capture_graph(run_raw, device)
    timing["deployed_triton_graph_replay"] = time_call(
        triton_replay, args.graph_iterations, device
    )
    timing["raw_gfx950_graph_replay"] = time_call(
        raw_replay, args.graph_iterations, device
    )
    raw_median = float(timing["raw_gfx950"]["median_us"])
    triton_median = float(timing["deployed_triton"]["median_us"])
    raw_bv = 128 if "_bv128_" in args.kernel_name else 64
    result = {
        "target": str(architecture),
        "shape": {
            "B": 1,
            "T": 8192,
            "H": 32,
            "Hg": 16,
            "K": 128,
            "V": 128,
            "BT": 64,
            "BK": args.triton_bk,
            "BV": raw_bv,
        },
        "triton_oracle": {
            "fixed_shape": args.triton_fixed_shape,
            "BK": args.triton_bk,
            "BV": args.triton_bv,
            "num_warps": args.triton_warps,
            "num_stages": args.triton_stages,
        },
        "grid": [1 if raw_bv == 128 else 2, 128, 32],
        "block": [256, 1, 1],
        "lds_bytes": 32768 if raw_bv == 128 else 16384,
        "tolerances_preregistered": {
            "atol": ATOL,
            "rtol": RTOL,
            "cosine_min": COSINE_MIN,
        },
        "correctness": correctness,
        "timing": timing,
        "median_speedup": triton_median / raw_median,
        "accepted_isolated": bool(
            correctness["triton_vs_capture"]["pass"]
            and correctness["raw_vs_triton"]["pass"]
            and raw_median < triton_median
        ),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    if not result["accepted_isolated"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
