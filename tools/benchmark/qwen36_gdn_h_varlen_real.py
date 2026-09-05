#!/usr/bin/env python3
"""Real-checkpoint varlen correctness/timing gate for the gfx950 GDN h kernel."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--variant", choices=("bv16", "bv32"), default="bv16")
    parser.add_argument("--server-python", type=Path, required=True)
    parser.add_argument("--sequence-counts", default="1,4,5,6,8,15,16")
    parser.add_argument("--tokens-per-sequence", type=int, default=1024)
    parser.add_argument("--iterations", type=int, default=20)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    delta = (actual.float() - expected.float()).abs()
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
    }


def median_us(run, iterations: int) -> float:
    for _ in range(5):
        run()
    torch.cuda.synchronize()
    values = []
    for _ in range(iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        run()
        end.record()
        end.synchronize()
        values.append(start.elapsed_time(end) * 1000.0)
    return statistics.median(values)


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")
    counts = [int(value) for value in args.sequence_counts.split(",")]
    if not counts or any(value < 1 or value > 16 for value in counts):
        raise ValueError("sequence counts must be in [1, 16]")
    length = args.tokens_per_sequence
    if length <= 0 or length > 32768:
        raise ValueError("tokens per sequence must be in [1, 32768]")

    import sys

    sys.path.insert(0, str(args.server_python))
    from sglang.srt.layers.attention.fla.chunk_delta_h import (
        chunk_gated_delta_rule_fwd_h,
    )
    from sglang.srt.layers.attention.fla.index import prepare_chunk_offsets

    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=True)
    names = ("k_normalized", "u", "w", "g_cumsum", "initial_state")
    if any(not isinstance(payload.get(name), torch.Tensor) for name in names):
        raise ValueError("state pass is missing required real-checkpoint tensors")

    variants = {
        "bv16": {
            "library": "libqwen36_gdn_h_m8192_bv16_bridge.so",
            "hsaco": "qwen36_gdn_h_m8192_bv16_gfx950.hsaco",
            "kernel": "qwen36_gdn_h_m8192_bv16_gfx950",
            "prefix": "netra_qwen36_gdn_h_m8192_bv16",
            "grid_x": 8,
        },
        "bv32": {
            "library": "libqwen36_gdn_h_varlen_bv32_bridge.so",
            "hsaco": "qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.hsaco",
            "kernel": "qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950",
            "prefix": "netra_qwen36_gdn_h_varlen_bv32",
            "grid_x": 4,
        },
    }
    variant = variants[args.variant]
    bridge = ctypes.CDLL(str(args.build_dir / variant["library"]))
    load = getattr(bridge, f'{variant["prefix"]}_load')
    launch = getattr(bridge, f'{variant["prefix"]}_launch')
    last_error = getattr(bridge, f'{variant["prefix"]}_last_error')
    load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    load.restype = ctypes.c_int
    launch.argtypes = [
        *([ctypes.c_void_p] * 10),
        ctypes.c_uint32,
        ctypes.c_uint32,
        ctypes.c_void_p,
    ]
    launch.restype = ctypes.c_int
    last_error.restype = ctypes.c_char_p
    status = load(
        str(args.build_dir / variant["hsaco"]).encode(),
        variant["kernel"].encode(),
    )
    if status:
        raise RuntimeError(last_error().decode())

    results = []
    for count in counts:
        starts = [(index * length) % 8192 for index in range(count)]

        def assemble(name: str) -> torch.Tensor:
            source = payload[name]
            tiled = torch.cat(
                [source] * ((length + 8191) // 8192 + 1), dim=1
            )
            pieces = [tiled[:, start : start + length] for start in starts]
            return torch.cat(pieces, dim=1).contiguous().to(device)

        k = assemble("k_normalized")
        u = assemble("u")
        w = assemble("w")
        g = assemble("g_cumsum")
        initial = payload["initial_state"].repeat(count, 1, 1, 1).to(device)
        initial_indices = torch.arange(count, dtype=torch.int32, device=device)
        cu_seqlens = torch.arange(
            0,
            (count + 1) * length,
            length,
            dtype=torch.int32,
            device=device,
        )
        chunk_offsets = prepare_chunk_offsets(cu_seqlens, 64)
        total_tokens = count * length

        oracle_state = initial.clone()

        def run_oracle():
            return chunk_gated_delta_rule_fwd_h(
                k=k,
                w=w,
                u=u,
                g=g,
                initial_state=oracle_state,
                initial_state_indices=initial_indices,
                cu_seqlens=cu_seqlens,
            )

        oracle_h, oracle_v = run_oracle()
        torch.cuda.synchronize(device)
        oracle_state_result = oracle_state.clone()

        raw_h = torch.empty_like(oracle_h)
        raw_v = torch.empty_like(oracle_v)
        raw_state = initial.clone()

        def run_raw() -> None:
            raw_state.copy_(initial)
            stream = torch.cuda.current_stream(device)
            status = launch(
                pointer(k),
                pointer(u),
                pointer(w),
                pointer(raw_v),
                pointer(g),
                pointer(raw_h),
                pointer(raw_state),
                pointer(initial_indices),
                pointer(cu_seqlens),
                pointer(chunk_offsets),
                ctypes.c_uint32(total_tokens),
                ctypes.c_uint32(count),
                ctypes.c_void_p(stream.cuda_stream),
            )
            if status:
                raise RuntimeError(last_error().decode())

        run_raw()
        torch.cuda.synchronize(device)
        correctness = {
            "h": compare(raw_h, oracle_h),
            "v_new": compare(raw_v, oracle_v),
            "final_state": compare(raw_state, oracle_state_result),
        }
        bit_exact = all(value["bit_exact"] for value in correctness.values())

        def timed_oracle() -> None:
            oracle_state.copy_(initial)
            run_oracle()

        raw_us = median_us(run_raw, args.iterations)
        oracle_us = median_us(timed_oracle, args.iterations)
        results.append(
            {
                "sequences": count,
                "tokens_per_sequence": length,
                "total_tokens": total_tokens,
                "grid": [variant["grid_x"], count * 32, 1],
                "correctness": correctness,
                "bit_exact": bit_exact,
                "raw_median_us": raw_us,
                "triton_median_us": oracle_us,
                "raw_speedup": oracle_us / raw_us,
            }
        )
        del k, u, w, g, initial, oracle_h, oracle_v, raw_h, raw_v
        torch.cuda.empty_cache()

    report = {
        "target": architecture,
        "source": str(args.state_pass),
        "kernel": variant["kernel"],
        "variant": args.variant,
        "results": results,
        "all_bit_exact": all(result["bit_exact"] for result in results),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
