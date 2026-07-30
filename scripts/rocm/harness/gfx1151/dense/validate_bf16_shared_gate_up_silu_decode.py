#!/usr/bin/env python3
"""Validate and HIP-event time the fixed gfx1151 BF16 shared gate+up+SiLU decode kernel."""
from __future__ import annotations

import argparse
import hashlib
import json
import socket
import statistics
import sys
from pathlib import Path

import torch
import torch.nn.functional as F
from safetensors import safe_open


REPO_ROOT = Path(__file__).resolve().parents[5]
SGLANG_ROOT = Path("/root/work/sglang-main/python")
sys.path.insert(0, str(SGLANG_ROOT))
sys.path.insert(0, str(REPO_ROOT / "scripts/rocm/integrations/sglang"))

from netra_gfx1151_sglang import netra_bf16_shared_gate_up_silu_with_output  # noqa: E402
from sglang.srt.layers.activation import silu_and_mul  # noqa: E402


LAYERS = tuple(range(40))


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = fraction * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def tensor_sha256(tensor: torch.Tensor) -> str:
    payload = tensor.cpu().view(torch.uint8).numpy().tobytes()
    return hashlib.sha256(payload).hexdigest()


def load_real_weights(checkpoint: Path) -> list[torch.Tensor]:
    index = json.loads((checkpoint / "model.safetensors.index.json").read_text())
    weight_map = index["weight_map"]
    weights = []
    for layer in LAYERS:
        prefix = f"model.language_model.layers.{layer}.mlp.shared_expert."
        names = [prefix + "gate_proj.weight", prefix + "up_proj.weight"]
        shard = weight_map[names[0]]
        if weight_map[names[1]] != shard:
            raise RuntimeError(f"layer {layer} gate/up span multiple shards")
        with safe_open(checkpoint / shard, framework="pt", device="cpu") as handle:
            weight = torch.cat([handle.get_tensor(name) for name in names], dim=0)
        weight = weight.cuda().contiguous()
        if weight.dtype != torch.bfloat16 or tuple(weight.shape) != (1024, 2048):
            raise RuntimeError(
                f"unexpected layer {layer} shared gate/up: {weight.dtype} {weight.shape}"
            )
        weights.append(weight)
    return weights


def baseline_output(activation: torch.Tensor, weight: torch.Tensor) -> torch.Tensor:
    gate_up = torch.mm(activation, weight.t())
    output = torch.empty((1, 512), device=activation.device, dtype=torch.bfloat16)
    silu_and_mul(gate_up, output)
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--checkpoint",
        type=Path,
        default=Path("/root/models/qwen36-sgl-mxfp4"),
    )
    parser.add_argument("--warmups", type=int, default=3)
    parser.add_argument("--iterations", type=int, default=30)
    parser.add_argument("--graph-replays", type=int, default=30)
    parser.add_argument("--seed", type=int, default=20260731)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("this validation must run inside the Netra LXC")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":")[0]
    if arch != "gfx1151":
        raise SystemExit(f"expected gfx1151, got {arch}")
    if min(args.warmups, args.iterations, args.graph_replays) < 1:
        raise SystemExit("warmups, iterations, and graph replays must be positive")

    weights = load_real_weights(args.checkpoint)
    torch.manual_seed(args.seed)
    activations = [
        torch.randn((1, 2048), device="cuda", dtype=torch.bfloat16)
        for _ in weights
    ]
    outputs = [
        torch.empty((1, 512), device="cuda", dtype=torch.bfloat16)
        for _ in weights
    ]

    correctness = []
    for index, (layer, weight, activation, output) in enumerate(
        zip(LAYERS, weights, activations, outputs)
    ):
        reference = baseline_output(activation, weight)
        netra_bf16_shared_gate_up_silu_with_output(weight, activation, output)
        torch.cuda.synchronize()
        delta = (output.float() - reference.float()).abs()
        correctness.append(
            {
                "layer": layer,
                "max_abs": float(delta.max()),
                "mean_abs": float(delta.mean()),
                "bf16_bit_mismatches": int(
                    torch.count_nonzero(
                        output.view(torch.int16) != reference.view(torch.int16)
                    )
                ),
                "candidate_sha256": tensor_sha256(output),
                "index": index,
            }
        )

    fp64 = []
    for index in (0, 20, 39):
        layer = LAYERS[index]
        gate_up_fp64 = torch.mm(
            activations[index].double(), weights[index].double().t()
        )
        reference = (
            F.silu(gate_up_fp64[:, :512]) * gate_up_fp64[:, 512:]
        )
        rocblas = baseline_output(activations[index], weights[index])
        netra_bf16_shared_gate_up_silu_with_output(
            weights[index], activations[index], outputs[index]
        )
        torch.cuda.synchronize()
        baseline_error = (rocblas.double() - reference).abs()
        candidate_error = (outputs[index].double() - reference).abs()
        fp64.append(
            {
                "layer": layer,
                "baseline_max_abs": float(baseline_error.max()),
                "candidate_max_abs": float(candidate_error.max()),
                "baseline_mean_abs": float(baseline_error.mean()),
                "candidate_mean_abs": float(candidate_error.mean()),
                "candidate_closer_elements": int(
                    torch.count_nonzero(candidate_error < baseline_error)
                ),
                "baseline_closer_elements": int(
                    torch.count_nonzero(baseline_error < candidate_error)
                ),
            }
        )
        del gate_up_fp64, reference, rocblas, baseline_error, candidate_error

    def baseline_pass() -> None:
        temporary = [
            baseline_output(activation, weight)
            for activation, weight in zip(activations, weights)
        ]
        del temporary

    def candidate_pass() -> None:
        for weight, activation, output in zip(weights, activations, outputs):
            netra_bf16_shared_gate_up_silu_with_output(weight, activation, output)

    for _ in range(args.warmups):
        baseline_pass()
        candidate_pass()
    torch.cuda.synchronize()

    event_samples = {"baseline": [], "candidate": []}
    functions = {"baseline": baseline_pass, "candidate": candidate_pass}
    for iteration in range(args.iterations):
        order = ("baseline", "candidate") if iteration % 2 == 0 else (
            "candidate",
            "baseline",
        )
        for variant in order:
            begin = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            begin.record()
            functions[variant]()
            end.record()
            end.synchronize()
            event_samples[variant].append(begin.elapsed_time(end))

    candidate_pass()
    torch.cuda.synchronize()
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        candidate_pass()
    graph.replay()
    torch.cuda.synchronize()
    graph_correctness = []
    for layer, weight, activation, output in zip(
        LAYERS, weights, activations, outputs
    ):
        reference = baseline_output(activation, weight)
        torch.cuda.synchronize()
        delta = (output.float() - reference.float()).abs()
        graph_correctness.append(
            {"layer": layer, "max_abs": float(delta.max())}
        )

    graph_ms = []
    for _ in range(args.graph_replays):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        graph.replay()
        end.record()
        end.synchronize()
        graph_ms.append(begin.elapsed_time(end))

    timing = {}
    for variant, samples in event_samples.items():
        timing[variant] = {
            "samples": samples,
            "median": statistics.median(samples),
            "p90": percentile(samples, 0.9),
        }
    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "estimated_values": False,
        "checkpoint": str(args.checkpoint),
        "shape": {"m": 1, "n": 1024, "k": 2048, "layers": 40},
        "dtype": "BF16",
        "weight_working_set_bytes": 40 * 1024 * 2048 * 2,
        "reference": "PyTorch rocBLAS BF16 GEMM plus sgl-kernel SiLU-and-mul",
        "correctness": {
            "layers": correctness,
            "max_abs": max(row["max_abs"] for row in correctness),
            "max_bf16_bit_mismatches": max(
                row["bf16_bit_mismatches"] for row in correctness
            ),
            "fp64_spot_check": fp64,
        },
        "hip_event_ms_per_forty_layer_pass": timing,
        "graph": {
            "correctness": graph_correctness,
            "replay_samples_ms": graph_ms,
            "replay_median_ms": statistics.median(graph_ms),
            "replay_p90_ms": percentile(graph_ms, 0.9),
        },
    }
    result["hip_event_ms_per_forty_layer_pass"]["median_speedup"] = (
        timing["baseline"]["median"] / timing["candidate"]["median"]
    )
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
