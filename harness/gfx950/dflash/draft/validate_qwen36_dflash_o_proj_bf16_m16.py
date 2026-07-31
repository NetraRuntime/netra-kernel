#!/usr/bin/env python3
"""Validate and time the raw gfx950 Qwen3.6 dFlash M16 output projection.

Contract:
  input:  BF16 [16, 4096]
  weight: BF16 [2048, 4096] (PyTorch Linear layout)
  output: BF16 [16, 2048]

The correctness oracle is SGLang's fixed-order batch-invariant BF16 matmul.
All timings use HIP events through torch.cuda.Event.  The optional AITER
comparison is reported as a deployed baseline, not as a correctness oracle,
because its observed reduction order is not repeatable for this shape.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import statistics
from pathlib import Path
from typing import Callable

import torch

from sglang.srt.batch_invariant_ops.batch_invariant_ops import mm_batch_invariant


M = 16
K = 4096
N = 2048


def tensor_hash(tensor: torch.Tensor) -> str:
    raw = tensor.contiguous().view(torch.uint8).cpu().numpy().tobytes()
    return hashlib.sha256(raw).hexdigest()


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def distribution(values: list[float]) -> dict[str, float]:
    ordered = sorted(values)

    def percentile(fraction: float) -> float:
        index = min(len(ordered) - 1, int(fraction * len(ordered)))
        return ordered[index]

    return {
        "minimum_us": ordered[0],
        "median_us": statistics.median(ordered),
        "p90_us": percentile(0.90),
        "maximum_us": ordered[-1],
        "mean_us": statistics.fmean(ordered),
    }


def time_gpu(
    operation: Callable[[], torch.Tensor | None],
    *,
    warmup: int,
    samples: int,
    launches_per_sample: int,
) -> dict[str, float]:
    for _ in range(warmup):
        operation()
    torch.cuda.synchronize()

    durations_us: list[float] = []
    for _ in range(samples):
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        start.record()
        for _ in range(launches_per_sample):
            operation()
        stop.record()
        stop.synchronize()
        durations_us.append(
            1000.0 * start.elapsed_time(stop) / launches_per_sample
        )
    return distribution(durations_us)


def mismatch_metrics(
    actual: torch.Tensor, expected: torch.Tensor
) -> dict[str, float | int | str]:
    actual_f32 = actual.float()
    expected_f32 = expected.float()
    absolute = (actual_f32 - expected_f32).abs()
    denominator = expected_f32.abs().clamp_min(torch.finfo(torch.float32).tiny)
    relative = absolute / denominator
    return {
        "elements": actual.numel(),
        "bf16_mismatches": int(
            (actual.view(torch.uint16) != expected.view(torch.uint16)).sum()
        ),
        "max_abs_error": float(absolute.max()),
        "mean_abs_error": float(absolute.mean()),
        "max_relative_error": float(relative.max()),
        "actual_sha256": tensor_hash(actual),
        "expected_sha256": tensor_hash(expected),
    }


def repeatability(
    operation: Callable[[], torch.Tensor],
    *,
    iterations: int,
) -> dict[str, int | str]:
    reference = operation().clone()
    torch.cuda.synchronize()
    reference_hash = tensor_hash(reference)
    differing_iterations = 0
    maximum_mismatches = 0
    for _ in range(iterations):
        candidate = operation()
        torch.cuda.synchronize()
        mismatches = int(
            (candidate.view(torch.uint16) != reference.view(torch.uint16)).sum()
        )
        differing_iterations += int(mismatches != 0)
        maximum_mismatches = max(maximum_mismatches, mismatches)
    return {
        "iterations": iterations,
        "differing_iterations": differing_iterations,
        "maximum_bf16_mismatches": maximum_mismatches,
        "reference_sha256": reference_hash,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--warmup", type=int, default=20)
    parser.add_argument("--samples", type=int, default=100)
    parser.add_argument("--launches-per-sample", type=int, default=10)
    parser.add_argument("--repeatability-iterations", type=int, default=100)
    parser.add_argument("--include-aiter", action="store_true")
    args = parser.parse_args()

    if min(
        args.warmup,
        args.samples,
        args.launches_per_sample,
        args.repeatability_iterations,
    ) <= 0:
        raise ValueError("all iteration counts must be positive")

    properties = torch.cuda.get_device_properties(0)
    target = properties.gcnArchName
    if "gfx950" not in target:
        raise RuntimeError(
            f"raw dFlash output projection requires gfx950; got {target}"
        )

    torch.manual_seed(20260731)
    input_ = (
        torch.randn((M, K), device="cuda", dtype=torch.float32)
        .mul_(0.25)
        .to(torch.bfloat16)
    )
    weight = (
        torch.randn((N, K), device="cuda", dtype=torch.float32)
        .mul_(0.25)
        .to(torch.bfloat16)
    )
    output = torch.empty((M, N), device="cuda", dtype=torch.bfloat16)

    bridge_path = (
        args.build_dir / "libqwen36_dflash_o_proj_bf16_bridge.so"
    ).resolve()
    hsaco_path = (
        args.build_dir / "qwen36_dflash_o_proj_bf16_m16_gfx950.hsaco"
    ).resolve()
    library = ctypes.CDLL(str(bridge_path))
    library.netra_qwen36_dflash_o_proj_bf16_load.argtypes = [ctypes.c_char_p]
    library.netra_qwen36_dflash_o_proj_bf16_load.restype = ctypes.c_int
    library.netra_qwen36_dflash_o_proj_bf16_launch.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
    ]
    library.netra_qwen36_dflash_o_proj_bf16_launch.restype = ctypes.c_int
    library.netra_qwen36_dflash_o_proj_bf16_last_error.restype = ctypes.c_char_p

    rc = library.netra_qwen36_dflash_o_proj_bf16_load(
        str(hsaco_path).encode()
    )
    if rc:
        raise RuntimeError(
            library.netra_qwen36_dflash_o_proj_bf16_last_error().decode()
        )
    stream = torch.cuda.current_stream()

    def raw() -> torch.Tensor:
        rc = library.netra_qwen36_dflash_o_proj_bf16_launch(
            output.data_ptr(),
            input_.data_ptr(),
            weight.data_ptr(),
            stream.cuda_stream,
        )
        if rc:
            raise RuntimeError(
                library.netra_qwen36_dflash_o_proj_bf16_last_error().decode()
            )
        return output

    def oracle() -> torch.Tensor:
        return mm_batch_invariant(input_, weight.t())

    expected = oracle()
    actual = raw().clone()
    torch.cuda.synchronize()
    correctness = mismatch_metrics(actual, expected)
    raw_repeatability = repeatability(
        lambda: raw().clone(),
        iterations=args.repeatability_iterations,
    )
    oracle_repeatability = repeatability(
        oracle,
        iterations=args.repeatability_iterations,
    )
    raw_timing = time_gpu(
        raw,
        warmup=args.warmup,
        samples=args.samples,
        launches_per_sample=args.launches_per_sample,
    )
    oracle_timing = time_gpu(
        oracle,
        warmup=args.warmup,
        samples=args.samples,
        launches_per_sample=args.launches_per_sample,
    )

    result: dict[str, object] = {
        "contract": {
            "target": target,
            "wavefront_size": properties.warp_size,
            "m": M,
            "n": N,
            "k": K,
            "input_dtype": str(input_.dtype),
            "weight_dtype": str(weight.dtype),
            "output_dtype": str(output.dtype),
            "weight_layout": "[N,K], PyTorch Linear",
        },
        "candidate": "raw gfx950 wave64 fixed-order 16x16x32 BF16 MFMA",
        "oracle": "SGLang mm_batch_invariant(input, weight.T)",
        "artifacts": {
            "hsaco": str(hsaco_path),
            "hsaco_sha256": file_hash(hsaco_path),
            "bridge": str(bridge_path),
            "bridge_sha256": file_hash(bridge_path),
        },
        "correctness": correctness,
        "repeatability": {
            "raw": raw_repeatability,
            "oracle": oracle_repeatability,
        },
        "hip_event_timing": {
            "raw": raw_timing,
            "deterministic_oracle": oracle_timing,
            "raw_speedup_over_oracle": (
                oracle_timing["median_us"] / raw_timing["median_us"]
            ),
            "warmup": args.warmup,
            "samples": args.samples,
            "launches_per_sample": args.launches_per_sample,
        },
    }

    if args.include_aiter:
        try:
            from aiter.tuned_gemm import tgemm

            def aiter() -> torch.Tensor:
                return tgemm.mm(input_, weight, otype=input_.dtype)

            aiter_output = aiter()
            torch.cuda.synchronize()
            result["aiter_baseline"] = {
                "correctness_vs_deterministic_oracle": mismatch_metrics(
                    aiter_output, expected
                ),
                "repeatability": repeatability(
                    aiter,
                    iterations=args.repeatability_iterations,
                ),
                "hip_event_timing": time_gpu(
                    aiter,
                    warmup=args.warmup,
                    samples=args.samples,
                    launches_per_sample=args.launches_per_sample,
                ),
            }
        except Exception as error:
            result["aiter_baseline"] = {
                "available": False,
                "error": f"{type(error).__name__}: {error}",
            }

    passed = (
        correctness["bf16_mismatches"] == 0
        and raw_repeatability["differing_iterations"] == 0
        and oracle_repeatability["differing_iterations"] == 0
    )
    result["pass"] = passed
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
