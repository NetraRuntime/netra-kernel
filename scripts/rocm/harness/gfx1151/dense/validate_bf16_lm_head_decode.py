#!/usr/bin/env python3
"""Validate and HIP-event time the fixed gfx1151 BF16 LM-head kernel."""
from __future__ import annotations

import argparse
import hashlib
import json
import socket
import statistics
import sys
from pathlib import Path

import torch
from safetensors import safe_open


REPO_ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(REPO_ROOT / "scripts/rocm/integrations/sglang"))

from netra_gfx1151_sglang import apply_bf16_lm_head  # noqa: E402


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = fraction * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def event_samples(function, warmups: int, iterations: int) -> list[float]:
    for _ in range(warmups):
        function()
    torch.cuda.synchronize()
    samples = []
    for _ in range(iterations):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        output = function()
        end.record()
        end.synchronize()
        samples.append(begin.elapsed_time(end))
        del output
    return samples


def tensor_sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(tensor.cpu().view(torch.uint8).numpy().tobytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--checkpoint-shard",
        type=Path,
        default=Path(
            "/root/models/qwen36-sgl-mxfp4/model-00026-of-00026.safetensors"
        ),
    )
    parser.add_argument("--trials", type=int, default=10)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--iterations", type=int, default=30)
    parser.add_argument("--graph-replays", type=int, default=5)
    parser.add_argument("--seed", type=int, default=20260731)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("this validation must run inside the Netra LXC")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":")[0]
    if arch != "gfx1151":
        raise SystemExit(f"expected gfx1151, got {arch}")
    if min(args.trials, args.iterations, args.graph_replays) < 1:
        raise SystemExit("trials, iterations, and graph replays must be positive")

    with safe_open(args.checkpoint_shard, framework="pt", device="cpu") as handle:
        weight = handle.get_tensor("lm_head.weight").cuda().contiguous()
    if weight.dtype != torch.bfloat16 or tuple(weight.shape) != (248320, 2048):
        raise RuntimeError(f"unexpected LM-head tensor: {weight.dtype} {weight.shape}")

    correctness = []
    max_abs = 0.0
    max_bit_mismatches = 0
    for trial in range(args.trials):
        torch.manual_seed(args.seed + trial)
        activation = torch.randn(
            (1, 2048), device="cuda", dtype=torch.bfloat16
        ).contiguous()
        baseline = torch.mm(activation, weight.t())
        candidate = apply_bf16_lm_head(weight, activation)
        torch.cuda.synchronize()
        delta = (candidate.float() - baseline.float()).abs()
        mismatches = int(
            torch.count_nonzero(
                candidate.view(torch.int16) != baseline.view(torch.int16)
            )
        )
        row_max = float(delta.max())
        max_abs = max(max_abs, row_max)
        max_bit_mismatches = max(max_bit_mismatches, mismatches)
        correctness.append(
            {
                "trial": trial,
                "max_abs": row_max,
                "mean_abs": float(delta.mean()),
                "bf16_bit_mismatches": mismatches,
                "argmax_equal": bool(candidate.argmax() == baseline.argmax()),
                "candidate_sha256": tensor_sha256(candidate),
            }
        )

    torch.manual_seed(args.seed + 1000)
    timing_activation = torch.randn(
        (1, 2048), device="cuda", dtype=torch.bfloat16
    ).contiguous()
    baseline_ms = event_samples(
        lambda: torch.mm(timing_activation, weight.t()),
        args.warmups,
        args.iterations,
    )
    candidate_ms = event_samples(
        lambda: apply_bf16_lm_head(weight, timing_activation),
        args.warmups,
        args.iterations,
    )

    static_activation = timing_activation.clone()
    apply_bf16_lm_head(weight, static_activation)
    torch.cuda.synchronize()
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        graph_output = apply_bf16_lm_head(weight, static_activation)
    graph_rows = []
    for replay in range(args.graph_replays):
        torch.manual_seed(args.seed + 2000 + replay)
        static_activation.copy_(torch.randn_like(static_activation))
        graph.replay()
        torch.cuda.synchronize()
        reference = torch.mm(static_activation, weight.t())
        torch.cuda.synchronize()
        delta = (graph_output.float() - reference.float()).abs()
        graph_rows.append(
            {
                "replay": replay,
                "max_abs": float(delta.max()),
                "argmax_equal": bool(graph_output.argmax() == reference.argmax()),
            }
        )

    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "estimated_values": False,
        "checkpoint_shard": str(args.checkpoint_shard),
        "shape": {"m": 1, "n": 248320, "k": 2048},
        "dtype": "BF16",
        "reference": "PyTorch rocBLAS BF16 GEMM with FP32 accumulation",
        "correctness": {
            "trials": correctness,
            "max_abs": max_abs,
            "max_bf16_bit_mismatches": max_bit_mismatches,
            "all_argmax_equal": all(row["argmax_equal"] for row in correctness),
        },
        "hip_event_ms": {
            "baseline": {
                "samples": baseline_ms,
                "median": statistics.median(baseline_ms),
                "p90": percentile(baseline_ms, 0.9),
            },
            "candidate": {
                "samples": candidate_ms,
                "median": statistics.median(candidate_ms),
                "p90": percentile(candidate_ms, 0.9),
            },
        },
        "graph_replay": graph_rows,
    }
    result["hip_event_ms"]["median_speedup"] = (
        result["hip_event_ms"]["baseline"]["median"]
        / result["hip_event_ms"]["candidate"]["median"]
    )
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
