#!/usr/bin/env python3
"""Dispatch the deployed exact M8192 Triton GDN recurrence for profiling."""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

import torch


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=12)
    parser.add_argument("--bv", type=int, default=32)
    parser.add_argument("--num-stages", type=int, default=2)
    args = parser.parse_args()

    import triton
    from sglang.srt.layers.attention.fla.chunk_delta_h import (
        chunk_gated_delta_rule_fwd_h,
        chunk_gated_delta_rule_fwd_kernel_h_blockdim64,
    )

    chunk_gated_delta_rule_fwd_kernel_h_blockdim64.configs = [
        triton.Config(
            {"BV": args.bv},
            num_warps=4,
            num_stages=args.num_stages,
        )
    ]

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=True)
    device = torch.device("cuda", 0)

    def gpu(name: str) -> torch.Tensor:
        return payload[name].contiguous().to(device=device)

    k = gpu("k_normalized")
    w = gpu("w")
    u = gpu("u")
    g = gpu("g_cumsum")
    state_seed = gpu("initial_state")
    state = state_seed.clone()
    state_indices = gpu("initial_state_indices")
    cu_seqlens = gpu("cu_seqlens")
    chunk_indices = gpu("chunk_indices")
    expected_h = gpu("h")
    expected_v_new = gpu("v_new")
    expected_state = gpu("final_state")
    del payload

    comparisons: dict[str, dict[str, float | int | bool]] = {}
    elapsed_us: list[float] = []
    for iteration in range(args.iterations):
        state.copy_(state_seed)
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        h, v_new = chunk_gated_delta_rule_fwd_h(
            k=k,
            w=w,
            u=u,
            g=g,
            initial_state=state,
            initial_state_indices=state_indices,
            cu_seqlens=cu_seqlens,
            chunk_indices=chunk_indices,
        )
        end.record()
        end.synchronize()
        elapsed_us.append(float(start.elapsed_time(end) * 1000.0))
        if iteration == 0:
            for name, actual, expected in (
                ("h", h, expected_h),
                ("v_new", v_new, expected_v_new),
                ("final_state", state, expected_state),
            ):
                delta = (actual.float() - expected.float()).abs()
                comparisons[name] = {
                    "bit_exact": bool(torch.equal(actual, expected)),
                    "mismatch_count": int((actual != expected).sum().item()),
                    "max_abs": float(delta.max().item()),
                    "mean_abs": float(delta.mean().item()),
                    "cosine": float(
                        torch.nn.functional.cosine_similarity(
                            actual.float().flatten(),
                            expected.float().flatten(),
                            dim=0,
                        ).item()
                    ),
                }
    torch.cuda.synchronize(device)
    timed = elapsed_us[1:] if len(elapsed_us) > 1 else elapsed_us
    print(
        json.dumps(
            {
                "BV": args.bv,
                "num_stages": args.num_stages,
                "bit_exact": all(
                    bool(comparison["bit_exact"])
                    for comparison in comparisons.values()
                ),
                "comparisons": comparisons,
                "iterations": len(timed),
                "median_us": statistics.median(timed),
                "minimum_us": min(timed),
                "maximum_us": max(timed),
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
