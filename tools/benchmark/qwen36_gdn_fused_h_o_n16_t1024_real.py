#!/usr/bin/env python3
"""Real-checkpoint gate for packed gfx950 T1024 fused GDN kernels."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--layer-pass", type=Path, required=True)
    parser.add_argument("--h-pass", type=Path, required=True)
    parser.add_argument("--fused-build-dir", type=Path, required=True)
    parser.add_argument(
        "--fused-kernel",
        default="qwen36_gdn_fused_h_o_n16_t1024_bv128_gfx950",
    )
    parser.add_argument("--h-build-dir", type=Path, required=True)
    parser.add_argument("--server-python", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=20)
    parser.add_argument("--sequence-count", type=int, default=16)
    parser.add_argument("--reverse-state-indices", action="store_true")
    parser.add_argument(
        "--state-pool-size",
        type=int,
        default=0,
        help="Allocated recurrent-state rows; 0 uses sequence-count.",
    )
    parser.add_argument(
        "--state-index-offset",
        type=int,
        default=0,
        help="First recurrent-state row used by the packed batch.",
    )
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def comparison(
    actual: torch.Tensor,
    expected: torch.Tensor,
    *,
    atol: float,
    rtol: float,
    cosine_min: float,
) -> dict[str, object]:
    a, e = actual.float(), expected.float()
    delta = (a - e).abs()
    relative = delta / e.abs().clamp_min(1e-6)
    significant = torch.maximum(a.abs(), e.abs()) >= atol
    relative_fail = significant & (relative > rtol)
    combined_fail = delta > (atol + rtol * e.abs())
    cosine = float(torch.nn.functional.cosine_similarity(a.flatten(), e.flatten(), dim=0))
    finite = bool(torch.isfinite(a).all().item())
    return {
        "finite": finite,
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
        "cosine": cosine,
        "relative_fail_count": int(relative_fail.sum().item()),
        "combined_atol_rtol_fail_count": int(combined_fail.sum().item()),
        "pass": bool(
            finite
            and not bool(combined_fail.any().item())
            and cosine >= cosine_min
        ),
    }


def median_us(call, reset, iterations: int) -> float:
    for _ in range(5):
        reset()
        call()
    torch.cuda.synchronize()
    values = []
    for _ in range(iterations):
        reset()
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        call()
        end.record()
        end.synchronize()
        values.append(float(start.elapsed_time(end) * 1000.0))
    return statistics.median(values)


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")

    import sys

    sys.path.insert(0, str(args.server_python))
    from sglang.jit_kernel.triton.gdn_l2norm import l2norm_gather
    from sglang.srt.layers.attention.fla.chunk_o import chunk_fwd_kernel_o
    from sglang.srt.layers.attention.fla.index import (
        prepare_chunk_indices,
        prepare_chunk_offsets,
    )

    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    sequence_count, length, chunk_size = args.sequence_count, 1024, 64
    if sequence_count < 1 or sequence_count > 64:
        raise ValueError("--sequence-count must be in [1, 64]")
    state_pool_size = args.state_pool_size or sequence_count
    if state_pool_size < sequence_count:
        raise ValueError("--state-pool-size must cover every sequence")
    if args.state_index_offset < 0:
        raise ValueError("--state-index-offset must be nonnegative")
    if args.state_index_offset + sequence_count > state_pool_size:
        raise ValueError("selected state rows exceed --state-pool-size")
    layer = torch.load(args.layer_pass, map_location="cpu", weights_only=True)
    hp = torch.load(args.h_pass, map_location="cpu", weights_only=True)

    def assemble(source: torch.Tensor) -> torch.Tensor:
        pieces = [
            source[:, (i % 8) * length : ((i % 8) + 1) * length]
            for i in range(sequence_count)
        ]
        return torch.cat(pieces, dim=1).contiguous().to(device)

    q = l2norm_gather(assemble(layer["q"]), use_rsqrt=False)
    k = assemble(hp["k_normalized"])
    u = assemble(hp["u"])
    w = assemble(hp["w"])
    g = assemble(hp["g_cumsum"])
    initial = hp["initial_state"].repeat(state_pool_size, 1, 1, 1).to(device)
    initial_indices = torch.arange(
        args.state_index_offset,
        args.state_index_offset + sequence_count,
        dtype=torch.int32,
        device=device,
    )
    if args.reverse_state_indices:
        initial_indices = initial_indices.flip(0).contiguous()
    cu = torch.arange(
        0,
        (sequence_count + 1) * length,
        length,
        dtype=torch.int32,
        device=device,
    )
    chunk_indices = prepare_chunk_indices(cu, chunk_size)
    chunk_offsets = prepare_chunk_offsets(cu, chunk_size)
    total_tokens = sequence_count * length
    total_chunks = total_tokens // chunk_size
    del layer, hp

    h = torch.empty(
        (1, total_chunks, 32, 128, 128), dtype=torch.bfloat16, device=device
    )
    v_new = torch.empty_like(u)
    # Guard one full state row on each side. The raw kernel receives only the
    # interior view, so an off-by-one pool index changes a guard deterministically
    # instead of depending on allocator adjacency.
    state_guard_value = 0.337890625
    initial_backing = torch.full(
        (state_pool_size + 2, 32, 128, 128),
        state_guard_value,
        dtype=torch.bfloat16,
        device=device,
    )
    initial_backing[1:-1].copy_(initial)
    baseline_state_backing = initial_backing.clone()
    baseline_state = baseline_state_backing[1:-1]
    fused_state_backing = initial_backing.clone()
    fused_state = fused_state_backing[1:-1]

    # Guard an entire token on each side of output for the same reason.
    output_guard_value = -0.6171875
    baseline_output_backing = torch.full(
        (1, total_tokens + 2, 32, 128),
        output_guard_value,
        dtype=torch.bfloat16,
        device=device,
    )
    baseline_output = baseline_output_backing[:, 1:-1]
    fused_output_backing = baseline_output_backing.clone()
    fused_output = fused_output_backing[:, 1:-1]
    scale = 128.0**-0.5

    hlib = ctypes.CDLL(str(args.h_build_dir / "libqwen36_gdn_h_m8192_bv16_bridge.so"))
    hlib.netra_qwen36_gdn_h_m8192_bv16_load.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    hlib.netra_qwen36_gdn_h_m8192_bv16_load.restype = ctypes.c_int
    hlib.netra_qwen36_gdn_h_m8192_bv16_launch.argtypes = [
        *([ctypes.c_void_p] * 10), ctypes.c_uint32, ctypes.c_uint32, ctypes.c_void_p
    ]
    hlib.netra_qwen36_gdn_h_m8192_bv16_launch.restype = ctypes.c_int
    hlib.netra_qwen36_gdn_h_m8192_bv16_last_error.restype = ctypes.c_char_p
    status = hlib.netra_qwen36_gdn_h_m8192_bv16_load(
        str(args.h_build_dir / "qwen36_gdn_h_m8192_bv16_gfx950.hsaco").encode(),
        b"qwen36_gdn_h_m8192_bv16_gfx950",
    )
    if status:
        raise RuntimeError(hlib.netra_qwen36_gdn_h_m8192_bv16_last_error().decode())

    flib = ctypes.CDLL(str(args.fused_build_dir / "libqwen36_gdn_fused_h_o_m8192_bridge.so"))
    flib.netra_qwen36_gdn_fused_h_o_m8192_load.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    flib.netra_qwen36_gdn_fused_h_o_m8192_load.restype = ctypes.c_int
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024.argtypes = [
        *([ctypes.c_void_p] * 9), ctypes.c_float, ctypes.c_uint32,
        ctypes.c_uint32, ctypes.c_void_p
    ]
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024.restype = ctypes.c_int
    flib.netra_qwen36_gdn_fused_h_o_m8192_last_error.restype = ctypes.c_char_p
    kernel = args.fused_kernel
    status = flib.netra_qwen36_gdn_fused_h_o_m8192_load(
        str(args.fused_build_dir / f"{kernel}.hsaco").encode(), kernel.encode()
    )
    if status:
        raise RuntimeError(flib.netra_qwen36_gdn_fused_h_o_m8192_last_error().decode())

    def run_h() -> None:
        stream = torch.cuda.current_stream(device)
        status = hlib.netra_qwen36_gdn_h_m8192_bv16_launch(
            pointer(k), pointer(u), pointer(w), pointer(v_new), pointer(g), pointer(h),
            pointer(baseline_state), pointer(initial_indices), pointer(cu),
            pointer(chunk_offsets), ctypes.c_uint32(total_tokens),
            ctypes.c_uint32(sequence_count), ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(hlib.netra_qwen36_gdn_h_m8192_bv16_last_error().decode())

    def run_o() -> None:
        chunk_fwd_kernel_o[(2, total_chunks, 32)](
            q, k, v_new, h, g, baseline_output, cu, chunk_indices, scale,
            T=total_tokens, H=32, Hg=16, K=128, V=128, BT=64, BK=128, BV=64,
            USE_G=True, IS_VARLEN=True, num_warps=4, num_stages=2,
        )

    def run_baseline() -> None:
        run_h()
        run_o()

    def run_fused() -> None:
        stream = torch.cuda.current_stream(device)
        status = flib.netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024(
            pointer(q), pointer(k), pointer(u), pointer(w), pointer(g),
            pointer(fused_state), pointer(fused_output), pointer(initial_indices), pointer(cu),
            ctypes.c_float(scale), ctypes.c_uint32(sequence_count),
            ctypes.c_uint32(state_pool_size),
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(flib.netra_qwen36_gdn_fused_h_o_m8192_last_error().decode())

    baseline_state.copy_(initial)
    fused_state.copy_(initial)
    run_baseline()
    run_fused()
    torch.cuda.synchronize()
    correctness = {
        "output": comparison(
            fused_output, baseline_output, atol=0.03125, rtol=0.01,
            cosine_min=0.9995,
        ),
        "final_state": comparison(
            fused_state, baseline_state, atol=0.125, rtol=0.02,
            cosine_min=0.999,
        ),
        "final_state_vs_reversed_slots": comparison(
            fused_state,
            baseline_state.flip(0),
            atol=0.125,
            rtol=0.02,
            cosine_min=0.999,
        ),
        "output_by_sequence": [
            comparison(
                fused_output[:, index * length : (index + 1) * length],
                baseline_output[:, index * length : (index + 1) * length],
                atol=0.03125,
                rtol=0.01,
                cosine_min=0.9995,
            )
            for index in range(sequence_count)
        ],
        "state_by_sequence": [
            comparison(
                fused_state[int(initial_indices[index].item())],
                baseline_state[int(initial_indices[index].item())],
                atol=0.125,
                rtol=0.02, cosine_min=0.999,
            )
            for index in range(sequence_count)
        ],
        "guards": {
            "state_prefix_unchanged": bool(
                torch.equal(fused_state_backing[0], initial_backing[0])
            ),
            "state_suffix_unchanged": bool(
                torch.equal(fused_state_backing[-1], initial_backing[-1])
            ),
            "output_prefix_unchanged": bool(
                torch.equal(
                    fused_output_backing[:, 0], baseline_output_backing[:, 0]
                )
            ),
            "output_suffix_unchanged": bool(
                torch.equal(
                    fused_output_backing[:, -1], baseline_output_backing[:, -1]
                )
            ),
        },
    }
    baseline_us = median_us(run_baseline, lambda: baseline_state.copy_(initial), args.iterations)
    fused_us = median_us(run_fused, lambda: fused_state.copy_(initial), args.iterations)
    block_v = 128 if "_bv128_" in kernel else (64 if "_bv64_" in kernel else 32)
    report = {
        "target": architecture,
        "shape": {"N": sequence_count, "tokens_per_sequence": 1024, "T": total_tokens,
                  "H": 32, "Hg": 16, "K": 128, "V": 128, "BT": 64,
                  "BV": block_v,
                  "state_pool_size": state_pool_size,
                  "state_index_offset": args.state_index_offset},
        "kernel": kernel,
        "grid": [
            1 if "_bv128_" in kernel else (2 if "_bv64_" in kernel else 4),
            sequence_count * 32,
            1,
        ],
        "block": [256, 1, 1],
        "lds_bytes": (
            73728 if "_bv128_" in kernel else (40960 if "_bv64_" in kernel else 24576)
        ),
        "correctness": correctness,
        "baseline_h_plus_o_median_us": baseline_us,
        "fused_median_us": fused_us,
        "speedup": baseline_us / fused_us,
        "accepted_isolated": bool(
            correctness["output"]["pass"]
            and correctness["final_state"]["pass"]
            and all(correctness["guards"].values())
            and fused_us < baseline_us
        ),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    if not report["accepted_isolated"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
