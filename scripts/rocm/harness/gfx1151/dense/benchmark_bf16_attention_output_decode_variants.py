#!/usr/bin/env python3
"""Matched real-weight A/B for gfx1151 BF16 attention-output raw kernels."""
from __future__ import annotations

import argparse
import ctypes
import json
import socket
import statistics
from pathlib import Path

import torch
from safetensors import safe_open


LAYERS_AND_SHARDS = (
    (3, 3), (7, 5), (11, 8), (15, 10), (19, 12),
    (23, 16), (27, 18), (31, 20), (35, 23), (39, 26),
)


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = fraction * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def load_weights(checkpoint: Path) -> list[torch.Tensor]:
    result = []
    for layer, shard in LAYERS_AND_SHARDS:
        path = checkpoint / f"model-{shard:05d}-of-00026.safetensors"
        key = f"model.language_model.layers.{layer}.self_attn.o_proj.weight"
        with safe_open(path, framework="pt", device="cpu") as handle:
            weight = handle.get_tensor(key).cuda().contiguous()
        if weight.dtype != torch.bfloat16 or tuple(weight.shape) != (2048, 4096):
            raise RuntimeError(f"unexpected layer {layer}: {weight.dtype} {weight.shape}")
        result.append(weight)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--baseline-hsaco", type=Path, required=True)
    parser.add_argument("--candidate-hsaco", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path,
                        default=Path("/root/models/qwen36-sgl-mxfp4"))
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--iterations", type=int, default=60)
    parser.add_argument("--graph-replays", type=int, default=60)
    parser.add_argument("--seed", type=int, default=20260731)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("this benchmark must run inside the Netra LXC")
    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":")[0]
    if arch != "gfx1151":
        raise SystemExit(f"expected gfx1151, got {arch}")

    library = ctypes.CDLL(str(args.library.resolve()))
    library.netra_bf16_attention_output_dual_load.argtypes = [
        ctypes.c_char_p, ctypes.c_char_p
    ]
    library.netra_bf16_attention_output_dual_load.restype = ctypes.c_int
    library.netra_bf16_attention_output_dual_launch.argtypes = [
        ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p,
        ctypes.c_void_p, ctypes.c_void_p,
    ]
    library.netra_bf16_attention_output_dual_launch.restype = ctypes.c_int
    status = library.netra_bf16_attention_output_dual_load(
        str(args.baseline_hsaco.resolve()).encode(),
        str(args.candidate_hsaco.resolve()).encode(),
    )
    if status != 0:
        raise RuntimeError(f"module load failed: HIP status {status}")

    weights = load_weights(args.checkpoint)
    torch.manual_seed(args.seed)
    activations = [
        torch.randn((1, 4096), dtype=torch.bfloat16, device="cuda")
        for _ in weights
    ]
    outputs = {
        name: [torch.empty((1, 2048), dtype=torch.bfloat16, device="cuda")
               for _ in weights]
        for name in ("baseline", "candidate")
    }

    def run(variant: int, name: str) -> None:
        stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
        for weight, activation, output in zip(weights, activations, outputs[name]):
            status = library.netra_bf16_attention_output_dual_launch(
                variant, weight.data_ptr(), activation.data_ptr(),
                output.data_ptr(), stream,
            )
            if status != 0:
                raise RuntimeError(f"{name} launch failed: HIP status {status}")

    run(0, "baseline")
    run(1, "candidate")
    torch.cuda.synchronize()
    correctness = []
    for (layer, _), weight, activation, old, new in zip(
        LAYERS_AND_SHARDS, weights, activations,
        outputs["baseline"], outputs["candidate"]
    ):
        reference = torch.mm(activation, weight.t())
        delta = (new.float() - reference.float()).abs()
        old_new = (new.float() - old.float()).abs()
        correctness.append({
            "layer": layer,
            "candidate_vs_rocblas_max_abs": float(delta.max()),
            "candidate_vs_rocblas_bf16_bit_mismatches": int(torch.count_nonzero(
                new.view(torch.int16) != reference.view(torch.int16)
            )),
            "candidate_vs_baseline_max_abs": float(old_new.max()),
            "candidate_vs_baseline_bf16_bit_mismatches": int(torch.count_nonzero(
                new.view(torch.int16) != old.view(torch.int16)
            )),
        })

    for _ in range(args.warmups):
        run(0, "baseline")
        run(1, "candidate")
    torch.cuda.synchronize()
    samples = {"baseline": [], "candidate": []}
    functions = {
        "baseline": lambda: run(0, "baseline"),
        "candidate": lambda: run(1, "candidate"),
    }
    for iteration in range(args.iterations):
        order = ("baseline", "candidate") if iteration % 2 == 0 else (
            "candidate", "baseline"
        )
        for name in order:
            begin = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            begin.record()
            functions[name]()
            end.record()
            end.synchronize()
            samples[name].append(begin.elapsed_time(end))

    graphs = {}
    graph_samples = {"baseline": [], "candidate": []}
    for name in ("baseline", "candidate"):
        functions[name]()
        torch.cuda.synchronize()
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            functions[name]()
        graphs[name] = graph
        graph.replay()
        torch.cuda.synchronize()
    for iteration in range(args.graph_replays):
        order = ("baseline", "candidate") if iteration % 2 == 0 else (
            "candidate", "baseline"
        )
        for name in order:
            begin = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            begin.record()
            graphs[name].replay()
            end.record()
            end.synchronize()
            graph_samples[name].append(begin.elapsed_time(end))

    timing = {
        name: {
            "samples_ms": values,
            "median_ms": statistics.median(values),
            "p90_ms": percentile(values, 0.9),
        }
        for name, values in samples.items()
    }
    graph_timing = {
        name: {
            "samples_ms": values,
            "median_ms": statistics.median(values),
            "p90_ms": percentile(values, 0.9),
        }
        for name, values in graph_samples.items()
    }
    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "estimated_values": False,
        "shape": {"m": 1, "n": 2048, "k": 4096, "layers": 10},
        "checkpoint": str(args.checkpoint),
        "method": "interleaved raw ASM A/B in one process with identical real weights",
        "correctness": correctness,
        "hip_event": timing,
        "graph_replay": graph_timing,
    }
    result["hip_event"]["speedup"] = (
        timing["baseline"]["median_ms"] / timing["candidate"]["median_ms"]
    )
    result["graph_replay"]["speedup"] = (
        graph_timing["baseline"]["median_ms"] /
        graph_timing["candidate"]["median_ms"]
    )
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
