#!/usr/bin/env python3
"""Validate the gfx950 T=8 direct-QKVZ convolution against SGLang Triton."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch
from safetensors import safe_open

from sglang.srt.layers.attention.mamba.causal_conv1d_triton import (
    causal_conv1d_update,
)


TOKENS = 8
QKV_DIM = 10240
QKVZ_DIM = 16384
WIDTH = 4
WEIGHT_KEY = "model.language_model.layers.0.linear_attn.conv1d.weight"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path, required=True)
    parser.add_argument("--batch", type=int, default=128)
    parser.add_argument("--iterations", type=int, default=200)
    parser.add_argument("--seed", type=int, default=20260820)
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
    }


def distribution(values: list[float]) -> dict[str, float | int]:
    ordered = sorted(values)
    return {
        "count": len(ordered),
        "mean_us": statistics.fmean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, (9 * len(ordered) + 9) // 10 - 1)],
        "maximum_us": ordered[-1],
    }


def load_weight(model_dir: Path) -> tuple[torch.Tensor, Path]:
    for shard in sorted(model_dir.glob("*.safetensors")):
        with safe_open(shard, framework="pt", device="cpu") as handle:
            if WEIGHT_KEY not in handle.keys():
                continue
            value = handle.get_tensor(WEIGHT_KEY)
            if tuple(value.shape) != (QKV_DIM, 1, WIDTH):
                raise ValueError(f"unexpected convolution weight: {value.shape}")
            return value.squeeze(1).contiguous(), shard
    raise KeyError(WEIGHT_KEY)


def time_graph(graph: torch.cuda.CUDAGraph, iterations: int) -> list[float]:
    for _ in range(10):
        graph.replay()
    torch.cuda.synchronize()
    values: list[float] = []
    for _ in range(iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        graph.replay()
        end.record()
        end.synchronize()
        values.append(float(start.elapsed_time(end) * 1000.0))
    return values


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if not 1 <= args.batch <= 256:
        raise ValueError("batch must be in [1,256]")
    device = torch.device("cuda", 0)
    architecture = str(torch.cuda.get_device_properties(device).gcnArchName)
    if not architecture.startswith("gfx950"):
        raise RuntimeError(f"requires gfx950, got {architecture}")

    torch.manual_seed(args.seed)
    rows = args.batch * TOKENS
    qkvz = torch.randn(
        rows, QKVZ_DIM, dtype=torch.bfloat16, device=device
    ).contiguous()
    initial_state = torch.randn(
        args.batch, QKV_DIM, WIDTH - 1, dtype=torch.bfloat16, device=device
    ).contiguous()
    weight_cpu, weight_shard = load_weight(args.model_dir)
    weight = weight_cpu.to(device)
    state_indices = torch.arange(args.batch, dtype=torch.int32, device=device)
    intermediate_indices = state_indices.clone()

    def baseline(state: torch.Tensor, window: torch.Tensor) -> torch.Tensor:
        qkv = qkvz[:, :QKV_DIM]
        qkv_by_sequence = qkv.view(args.batch, TOKENS, QKV_DIM).transpose(1, 2)
        processed = causal_conv1d_update(
            qkv_by_sequence,
            state,
            weight,
            bias=None,
            activation="silu",
            conv_state_indices=state_indices,
            intermediate_conv_window=window,
            intermediate_state_indices=intermediate_indices,
        )
        return processed.transpose(1, 2).reshape(rows, QKV_DIM)

    baseline_state = initial_state.clone()
    baseline_window = torch.empty(
        args.batch,
        TOKENS,
        QKV_DIM,
        WIDTH - 1,
        dtype=torch.bfloat16,
        device=device,
    )
    baseline_output = baseline(baseline_state, baseline_window)
    torch.cuda.synchronize()

    library = ctypes.CDLL(str(args.bridge))
    load = library.netra_gdn_qkvz_conv_t8_d10240_load
    load.argtypes = [ctypes.c_char_p]
    load.restype = ctypes.c_int
    launch = library.netra_gdn_qkvz_conv_t8_d10240_launch
    launch.argtypes = [ctypes.c_void_p] * 7 + [ctypes.c_uint32, ctypes.c_void_p]
    launch.restype = ctypes.c_int
    library.netra_qwen36_gdn_verify_m12_batched_last_error.restype = ctypes.c_char_p

    def check(status: int) -> None:
        if status:
            raw = library.netra_qwen36_gdn_verify_m12_batched_last_error()
            raise RuntimeError(raw.decode() if raw else f"status={status}")

    check(load(str(args.hsaco).encode()))
    raw_state = initial_state.clone()
    raw_window = torch.empty_like(baseline_window)
    raw_output = torch.empty_like(baseline_output)

    def raw_launch() -> None:
        stream = torch.cuda.current_stream(device)
        check(
            launch(
                pointer(qkvz),
                pointer(weight),
                pointer(raw_state),
                pointer(state_indices),
                pointer(raw_window),
                pointer(intermediate_indices),
                pointer(raw_output),
                args.batch,
                ctypes.c_void_p(stream.cuda_stream),
            )
        )

    raw_launch()
    torch.cuda.synchronize()
    eager_correctness = {
        "output": compare(raw_output, baseline_output),
        "state": compare(raw_state, baseline_state),
        "window": compare(raw_window, baseline_window),
    }

    baseline_graph_state = initial_state.clone()
    baseline_graph_window = torch.empty_like(baseline_window)
    baseline_graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(baseline_graph):
        baseline_graph_output = baseline(
            baseline_graph_state, baseline_graph_window
        )

    raw_state.copy_(initial_state)
    raw_graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(raw_graph):
        raw_launch()
    raw_state.copy_(initial_state)
    baseline_graph_state.copy_(initial_state)
    baseline_graph.replay()
    raw_graph.replay()
    torch.cuda.synchronize()
    graph_correctness = {
        "output": compare(raw_output, baseline_graph_output),
        "state": compare(raw_state, baseline_graph_state),
        "window": compare(raw_window, baseline_graph_window),
    }

    baseline_stats = distribution(time_graph(baseline_graph, args.iterations))
    raw_stats = distribution(time_graph(raw_graph, args.iterations))
    result = {
        "format": "netra-gdn-qkvz-conv-t8-synthetic-1",
        "architecture": architecture,
        "shape": {
            "batch": args.batch,
            "tokens": TOKENS,
            "qkvz_dim": QKVZ_DIM,
            "qkv_dim": QKV_DIM,
            "width": WIDTH,
        },
        "seed": args.seed,
        "weight_shard": str(weight_shard),
        "eager_correctness": eager_correctness,
        "graph_correctness": graph_correctness,
        "graph_hip_event": {
            "triton": baseline_stats,
            "assembly": raw_stats,
        },
        "graph_speedup": baseline_stats["median_us"] / raw_stats["median_us"],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    correctness = (*eager_correctness.values(), *graph_correctness.values())
    if not all(item["bit_exact"] for item in correctness):
        raise SystemExit("T=8 direct-QKVZ correctness failure")


if __name__ == "__main__":
    main()
