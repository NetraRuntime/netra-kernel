#!/usr/bin/env python3
"""HIP-event benchmark for gfx1151 Qwen3.6 extend-attention tile oracles."""
from __future__ import annotations

import argparse
import importlib
import json
import statistics
from pathlib import Path

import torch


def parse_tile(value: str) -> tuple[int, int, int]:
    try:
        block_m, block_n, warps = (int(part) for part in value.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError("tile must be BLOCK_M,BLOCK_N,WARPS") from exc
    return block_m, block_n, warps


def measure(call, warmup: int, repetitions: int) -> list[float]:
    for _ in range(warmup):
        call()
    torch.cuda.synchronize()
    samples = []
    for _ in range(repetitions):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        call()
        end.record()
        end.synchronize()
        samples.append(start.elapsed_time(end))
    return samples


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tokens", type=int, default=8192)
    parser.add_argument("--prefix", type=int, nargs="+", default=[0, 8192, 16384, 24576])
    parser.add_argument("--tile", type=parse_tile, action="append")
    parser.add_argument("--warmup", type=int, default=2)
    parser.add_argument("--repetitions", type=int, default=5)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    tiles = args.tile or [(64, 64, 4), (32, 64, 4), (32, 32, 4), (16, 64, 4)]

    torch.manual_seed(20260729)
    device = torch.device("cuda")
    dtype = torch.bfloat16
    heads_q, heads_kv, head_dim = 16, 2, 256
    module = importlib.import_module("sglang.kernels.ops.attention.extend_attention")
    original_blocks = module._get_block_sizes_for_extend_attention
    rows = []

    for prefix in args.prefix:
        q = torch.randn((args.tokens, heads_q, head_dim), device=device, dtype=dtype) * 0.02
        k = torch.randn((args.tokens, heads_kv, head_dim), device=device, dtype=dtype) * 0.02
        v = torch.randn((args.tokens, heads_kv, head_dim), device=device, dtype=dtype) * 0.02
        k_buffer = torch.randn((max(prefix, 1), heads_kv, head_dim), device=device, dtype=dtype) * 0.02
        v_buffer = torch.randn_like(k_buffer) * 0.02
        qo_indptr = torch.tensor([0, args.tokens], device=device, dtype=torch.int64)
        kv_indptr = torch.tensor([0, prefix], device=device, dtype=torch.int32)
        kv_indices = torch.arange(prefix, device=device, dtype=torch.int64)
        reference = None

        for block_m, block_n, warps in tiles:
            module._get_block_sizes_for_extend_attention = lambda lq, lv, bm=block_m, bn=block_n, nw=warps: (
                256, 0, 256, bm, bn, nw
            )
            output = torch.empty_like(q)

            def call() -> None:
                module.extend_attention_fwd(
                    q, k, v, output, k_buffer, v_buffer,
                    qo_indptr, kv_indptr, kv_indices, None, True, None,
                    args.tokens, 1.0, 1.0,
                )

            samples = measure(call, args.warmup, args.repetitions)
            if reference is None:
                reference = output.clone()
                max_abs = 0.0
                normalized_l2 = 0.0
            else:
                delta = output.float() - reference.float()
                max_abs = delta.abs().max().item()
                normalized_l2 = delta.norm().item() / max(reference.float().norm().item(), 1e-12)
            rows.append({
                "prefix_tokens": prefix,
                "extend_tokens": args.tokens,
                "tile": [block_m, block_n, warps],
                "hip_event_ms": samples,
                "median_hip_event_ms": statistics.median(samples),
                "max_abs_vs_64x64": max_abs,
                "normalized_l2_vs_64x64": normalized_l2,
            })
        del q, k, v, k_buffer, v_buffer, reference

    module._get_block_sizes_for_extend_attention = original_blocks
    result = {
        "target": "gfx1151",
        "measurement_status": "measured_hip_events",
        "shape": {"heads_q": heads_q, "heads_kv": heads_kv, "head_dim": head_dim},
        "rows": rows,
        "estimated_values": False,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
