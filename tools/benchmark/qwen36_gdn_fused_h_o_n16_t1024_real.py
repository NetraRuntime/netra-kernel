#!/usr/bin/env python3
"""Real-checkpoint gate for the gfx950 N16/T1024 fused GDN experiment."""

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
        default="qwen36_gdn_fused_h_o_n16_t1024_bv32_gfx950",
    )
    parser.add_argument("--h-build-dir", type=Path, required=True)
    parser.add_argument("--server-python", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=20)
    parser.add_argument("--sequence-count", type=int, default=16)
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
        "pass": bool(
            finite
            and float(delta.max().item()) <= atol
            and not bool(relative_fail.any().item())
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
    if sequence_count < 1 or sequence_count > 16:
        raise ValueError("--sequence-count must be in [1, 16]")
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
    initial = hp["initial_state"].repeat(sequence_count, 1, 1, 1).to(device)
    initial_indices = torch.arange(sequence_count, dtype=torch.int32, device=device)
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
    baseline_state = initial.clone()
    baseline_output = torch.empty(
        (1, total_tokens, 32, 128), dtype=torch.bfloat16, device=device
    )
    fused_state = initial.clone()
    fused_output = torch.empty_like(baseline_output)
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
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch_varlen.argtypes = [
        *([ctypes.c_void_p] * 7), ctypes.c_float, ctypes.c_uint32,
        ctypes.c_uint32, ctypes.c_void_p
    ]
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch_varlen.restype = ctypes.c_int
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
        status = flib.netra_qwen36_gdn_fused_h_o_m8192_launch_varlen(
            pointer(q), pointer(k), pointer(u), pointer(w), pointer(g),
            pointer(fused_state), pointer(fused_output), ctypes.c_float(scale),
            ctypes.c_uint32(length // chunk_size), ctypes.c_uint32(sequence_count),
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
                fused_state[index], baseline_state[index], atol=0.125,
                rtol=0.02, cosine_min=0.999,
            )
            for index in range(sequence_count)
        ],
    }
    baseline_us = median_us(run_baseline, lambda: baseline_state.copy_(initial), args.iterations)
    fused_us = median_us(run_fused, lambda: fused_state.copy_(initial), args.iterations)
    report = {
        "target": architecture,
        "shape": {"N": sequence_count, "tokens_per_sequence": 1024, "T": total_tokens,
                  "H": 32, "Hg": 16, "K": 128, "V": 128, "BT": 64, "BV": 32},
        "kernel": kernel,
        "grid": [2 if "_bv64_" in kernel else 4, sequence_count * 32, 1],
        "block": [256, 1, 1],
        "lds_bytes": 40960 if "_bv64_" in kernel else 24576,
        "correctness": correctness,
        "baseline_h_plus_o_median_us": baseline_us,
        "fused_median_us": fused_us,
        "speedup": baseline_us / fused_us,
        "accepted_isolated": bool(
            correctness["output"]["pass"]
            and correctness["final_state"]["pass"]
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
