#!/usr/bin/env python3
"""Compare two fixed-shape raw gfx1151 BF16 QKV kernels with HIP events."""
from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import socket
import statistics
from pathlib import Path

import torch
from safetensors import safe_open


LAYERS_AND_SHARDS = (
    (3, 3),
    (7, 5),
    (11, 8),
    (15, 10),
    (19, 12),
    (23, 16),
    (27, 18),
    (31, 20),
    (35, 23),
    (39, 26),
)


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = fraction * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def tensor_sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(tensor.cpu().view(torch.uint8).numpy().tobytes()).hexdigest()


class RawQkv:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.library = ctypes.CDLL(str(library))
        self.library.netra_bf16_qkv_load.argtypes = [ctypes.c_char_p]
        self.library.netra_bf16_qkv_load.restype = ctypes.c_int
        self.library.netra_bf16_qkv_launch.argtypes = [ctypes.c_void_p] * 4
        self.library.netra_bf16_qkv_launch.restype = ctypes.c_int
        status = self.library.netra_bf16_qkv_load(str(hsaco).encode())
        if status:
            raise RuntimeError(f"module load failed for {hsaco}: HIP status {status}")

    def __call__(
        self,
        weight: torch.Tensor,
        activation: torch.Tensor,
        output: torch.Tensor,
    ) -> None:
        stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
        status = self.library.netra_bf16_qkv_launch(
            ctypes.c_void_p(weight.data_ptr()),
            ctypes.c_void_p(activation.data_ptr()),
            ctypes.c_void_p(output.data_ptr()),
            stream,
        )
        if status:
            raise RuntimeError(f"raw QKV launch failed: HIP status {status}")


def load_real_weights(checkpoint: Path) -> list[torch.Tensor]:
    weights = []
    for layer, shard in LAYERS_AND_SHARDS:
        path = checkpoint / f"model-{shard:05d}-of-00026.safetensors"
        prefix = f"model.language_model.layers.{layer}.self_attn."
        with safe_open(path, framework="pt", device="cpu") as handle:
            weight = torch.cat(
                [
                    handle.get_tensor(prefix + projection + ".weight")
                    for projection in ("q_proj", "k_proj", "v_proj")
                ],
                dim=0,
            ).cuda()
        if weight.dtype != torch.bfloat16 or tuple(weight.shape) != (9216, 2048):
            raise RuntimeError(f"unexpected layer {layer} QKV weight {weight.shape}")
        weights.append(weight.contiguous())
    return weights


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline-library", required=True, type=Path)
    parser.add_argument("--baseline-hsaco", required=True, type=Path)
    parser.add_argument("--candidate-library", required=True, type=Path)
    parser.add_argument("--candidate-hsaco", required=True, type=Path)
    parser.add_argument(
        "--checkpoint",
        type=Path,
        default=Path("/root/models/qwen36-sgl-mxfp4"),
    )
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--iterations", type=int, default=31)
    parser.add_argument("--graph-replays", type=int, default=31)
    parser.add_argument("--seed", type=int, default=20260731)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if socket.gethostname() != "Netra":
        raise SystemExit("this comparison must run inside the Netra LXC")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":")[0]
    if arch != "gfx1151":
        raise SystemExit(f"expected gfx1151, got {arch}")
    if min(args.warmups, args.iterations, args.graph_replays) < 1:
        raise SystemExit("warmups and iterations must be positive")

    baseline = RawQkv(args.baseline_library, args.baseline_hsaco)
    candidate = RawQkv(args.candidate_library, args.candidate_hsaco)
    weights = load_real_weights(args.checkpoint)
    torch.manual_seed(args.seed)
    activations = [
        torch.randn((1, 2048), dtype=torch.bfloat16, device="cuda")
        for _ in weights
    ]
    baseline_outputs = [
        torch.empty((1, 9216), dtype=torch.bfloat16, device="cuda")
        for _ in weights
    ]
    candidate_outputs = [
        torch.empty((1, 9216), dtype=torch.bfloat16, device="cuda")
        for _ in weights
    ]

    def baseline_pass() -> None:
        for weight, activation, output in zip(
            weights, activations, baseline_outputs
        ):
            baseline(weight, activation, output)

    def candidate_pass() -> None:
        for weight, activation, output in zip(
            weights, activations, candidate_outputs
        ):
            candidate(weight, activation, output)

    baseline_pass()
    candidate_pass()
    torch.cuda.synchronize()
    correctness = []
    for (layer, _), old, new in zip(
        LAYERS_AND_SHARDS, baseline_outputs, candidate_outputs
    ):
        delta = (old.float() - new.float()).abs()
        correctness.append(
            {
                "layer": layer,
                "bit_mismatches": int(
                    torch.count_nonzero(
                        old.view(torch.int16) != new.view(torch.int16)
                    )
                ),
                "max_abs": float(delta.max()),
                "baseline_sha256": tensor_sha256(old),
                "candidate_sha256": tensor_sha256(new),
            }
        )

    for _ in range(args.warmups):
        baseline_pass()
        candidate_pass()
    torch.cuda.synchronize()

    functions = {"baseline": baseline_pass, "candidate": candidate_pass}
    samples = {"baseline": [], "candidate": []}
    for iteration in range(args.iterations):
        order = (
            ("baseline", "candidate")
            if iteration % 2 == 0
            else ("candidate", "baseline")
        )
        for variant in order:
            begin = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            begin.record()
            functions[variant]()
            end.record()
            end.synchronize()
            samples[variant].append(begin.elapsed_time(end))

    candidate_pass()
    torch.cuda.synchronize()
    eager_hashes = [tensor_sha256(output) for output in candidate_outputs]
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        candidate_pass()
    graph.replay()
    torch.cuda.synchronize()
    graph_hashes = [tensor_sha256(output) for output in candidate_outputs]
    graph_samples = []
    for _ in range(args.graph_replays):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        graph.replay()
        end.record()
        end.synchronize()
        graph_samples.append(begin.elapsed_time(end))

    timing = {
        name: {
            "samples_ms": values,
            "median_ms": statistics.median(values),
            "p90_ms": percentile(values, 0.9),
        }
        for name, values in samples.items()
    }
    result = {
        "target": "gfx1151",
        "measurement_status": "measured_hip_events",
        "estimated_values": False,
        "checkpoint": str(args.checkpoint),
        "shape": {"m": 1, "n": 9216, "k": 2048, "layers": 10},
        "sample_order": "alternating_ab_ba",
        "correctness": {
            "layers": correctness,
            "total_bit_mismatches": sum(
                row["bit_mismatches"] for row in correctness
            ),
            "max_abs": max(row["max_abs"] for row in correctness),
        },
        "timing": timing,
        "median_speedup": (
            timing["baseline"]["median_ms"] / timing["candidate"]["median_ms"]
        ),
        "graph": {
            "eager_candidate_hashes": eager_hashes,
            "replay_hashes": graph_hashes,
            "eager_replay_bit_exact": eager_hashes == graph_hashes,
            "samples_ms": graph_samples,
            "median_ms": statistics.median(graph_samples),
            "p90_ms": percentile(graph_samples, 0.9),
        },
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
