#!/usr/bin/env python3
"""Compare production Triton and raw GDN-H execution at packed N up to 512."""

from __future__ import annotations

import argparse
import json
import os
import statistics
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--sequence-counts", type=int, nargs="+", default=[1, 64, 98, 128, 256, 512]
    )
    parser.add_argument("--iterations", type=int, default=5)
    parser.add_argument("--seed", type=int, default=20260809)
    return parser.parse_args()


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    delta = (actual.float() - expected.float()).abs()
    mismatch = actual != expected
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int(mismatch.sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
    }


def distribution(values: list[float]) -> dict[str, float]:
    return {
        "mean_us": statistics.mean(values),
        "median_us": statistics.median(values),
        "minimum_us": min(values),
        "maximum_us": max(values),
    }


def lengths_for(total: int, count: int) -> list[int]:
    quotient, remainder = divmod(total, count)
    if quotient == 0:
        raise ValueError(f"sequence count {count} exceeds total tokens {total}")
    return [quotient + (index < remainder) for index in range(count)]


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")

    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    os.environ[
        "SGLANG_NETRA_QWEN36_GFX950_GDN_H_M8192_BV16_BRIDGE"
    ] = str(args.bridge)
    os.environ[
        "SGLANG_NETRA_QWEN36_GFX950_GDN_H_M8192_BV16_HSACO"
    ] = str(args.hsaco)

    from sglang.srt.layers.attention.fla.chunk_delta_h import (
        chunk_gated_delta_rule_fwd_h,
    )
    from sglang.srt.layers.attention.linear.netra_gfx950_qwen36_gdn_h_m8192 import (
        maybe_load_netra_qwen36_gfx950_gdn_h_m8192_bv16,
    )

    total_tokens = 8192
    generator = torch.Generator(device=device).manual_seed(args.seed)
    k = (torch.randn((1, total_tokens, 16, 128), device=device, generator=generator) * 0.01).to(torch.bfloat16)
    u = (torch.randn((1, total_tokens, 32, 128), device=device, generator=generator) * 0.01).to(torch.bfloat16)
    w = (torch.randn((1, total_tokens, 32, 128), device=device, generator=generator) * 0.01).to(torch.bfloat16)
    g = -(torch.rand((1, total_tokens, 32), device=device, generator=generator) * 0.01).float()

    results: list[dict[str, object]] = []
    for sequence_count in args.sequence_counts:
        lengths = lengths_for(total_tokens, sequence_count)
        cu_cpu = torch.tensor([0] + lengths, dtype=torch.int32).cumsum(
            0, dtype=torch.int32
        )
        cu = cu_cpu.to(device=device)
        indices = torch.arange(sequence_count, dtype=torch.int32, device=device)
        initial = (torch.randn((sequence_count, 32, 128, 128), device=device, generator=generator) * 0.01).to(torch.bfloat16)

        os.environ["SGLANG_NETRA_QWEN36_GFX950_GDN_H_M8192_BV16"] = "0"
        reference_state = initial.clone()
        reference_h, reference_v = chunk_gated_delta_rule_fwd_h(
            k=k,
            w=w,
            u=u,
            g=g,
            initial_state=reference_state,
            initial_state_indices=indices,
            cu_seqlens=cu,
        )
        torch.cuda.synchronize(device)

        os.environ["SGLANG_NETRA_QWEN36_GFX950_GDN_H_M8192_BV16"] = "1"
        maybe_load_netra_qwen36_gfx950_gdn_h_m8192_bv16()

        elapsed: list[float] = []
        raw_h = raw_v = raw_state = None
        for _ in range(args.iterations):
            raw_state = initial.clone()
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            raw_h, raw_v = chunk_gated_delta_rule_fwd_h(
                k=k,
                w=w,
                u=u,
                g=g,
                initial_state=raw_state,
                initial_state_indices=indices,
                cu_seqlens=cu,
            )
            end.record()
            end.synchronize()
            elapsed.append(float(start.elapsed_time(end) * 1000.0))
        assert raw_h is not None and raw_v is not None and raw_state is not None

        correctness = {
            "h": compare(raw_h, reference_h),
            "v_new": compare(raw_v, reference_v),
            "final_state": compare(raw_state, reference_state),
        }
        bit_exact = all(bool(item["bit_exact"]) for item in correctness.values())
        results.append(
            {
                "sequence_count": sequence_count,
                "length_min": min(lengths),
                "length_max": max(lengths),
                "chunk_count": int(sum((length + 63) // 64 for length in lengths)),
                "grid": [8, 32 * sequence_count, 1],
                "correctness": correctness,
                "bit_exact": bit_exact,
                "raw_timing": distribution(elapsed),
            }
        )
        del reference_h, reference_v, reference_state, raw_h, raw_v, raw_state, initial
        torch.cuda.empty_cache()

    payload = {
        "schema_version": 1,
        "architecture": str(architecture),
        "seed": args.seed,
        "total_tokens": total_tokens,
        "results": results,
        "all_bit_exact": all(bool(item["bit_exact"]) for item in results),
        "peak_allocated_bytes": torch.cuda.max_memory_allocated(device),
        "peak_reserved_bytes": torch.cuda.max_memory_reserved(device),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    if not payload["all_bit_exact"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
