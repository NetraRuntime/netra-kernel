#!/usr/bin/env python3

"""Correctness, HIP-event, and graph replay check for raw gfx1151 GDN."""

from __future__ import annotations

import argparse
import json
import socket
import statistics
from pathlib import Path

import torch

from sglang.kernels.ops.attention.fla.chunk_o import chunk_fwd_kernel_o
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices
from sglang.srt.layers.quantization.netra_gfx1151 import (
    netra_gdn_chunk_o_with_output,
)


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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--samples", type=int, default=10)
    parser.add_argument("--seed", type=int, default=2907)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("refusing to run outside the Netra LXC")

    torch.manual_seed(args.seed)
    q = (torch.randn((1, 8192, 16, 128), device="cuda") * 0.01).bfloat16()
    k = (torch.randn((1, 8192, 16, 128), device="cuda") * 0.01).bfloat16()
    v = (torch.randn((1, 8192, 32, 128), device="cuda") * 0.01).bfloat16()
    h = (torch.randn((1, 128, 32, 128, 128), device="cuda") * 0.01).bfloat16()
    g = (-torch.rand((1, 8192, 32), device="cuda") * 0.002).cumsum(1)
    cu_seqlens = torch.tensor([0, 8192], device="cuda", dtype=torch.int32)
    chunk_indices = prepare_chunk_indices(cu_seqlens, 64)
    scale = 128**-0.5
    reference = torch.empty_like(v)
    output = torch.empty_like(v)

    def triton_reference() -> None:
        chunk_fwd_kernel_o[(4, 128, 32)](
            q, k, v, h, g, reference, cu_seqlens, chunk_indices, scale,
            T=8192, H=32, Hg=16, K=128, V=128, BT=64, BK=64, BV=32,
            USE_G=True, IS_VARLEN=True, num_warps=8, num_stages=2,
        )

    def raw() -> None:
        netra_gdn_chunk_o_with_output(
            q, k, v, h, g, output, cu_seqlens, chunk_indices, scale, 8192
        )

    triton_reference()
    raw()
    torch.cuda.synchronize()
    difference = (output.float() - reference.float()).abs()
    raw_ms = measure(raw, args.samples)
    triton_ms = measure(triton_reference, args.samples)

    graph = torch.cuda.CUDAGraph()
    raw()
    torch.cuda.synchronize()
    with torch.cuda.graph(graph):
        raw()
    graph.replay()
    torch.cuda.synchronize()
    graph_difference = (output.float() - reference.float()).abs()
    graph_ms = measure(graph.replay, args.samples)

    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "shape": "B1_T8192_H32_Hg16_K128_V128_BT64",
        "max_abs_error": difference.max().item(),
        "mean_abs_error": difference.mean().item(),
        "finite": torch.isfinite(output).all().item(),
        "raw_median_hip_event_ms": statistics.median(raw_ms),
        "triton_median_hip_event_ms": statistics.median(triton_ms),
        "raw_speedup_vs_tuned_triton": statistics.median(triton_ms) / statistics.median(raw_ms),
        "graph_replay_median_hip_event_ms": statistics.median(graph_ms),
        "graph_max_abs_error_vs_reference": graph_difference.max().item(),
        "samples": args.samples,
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
