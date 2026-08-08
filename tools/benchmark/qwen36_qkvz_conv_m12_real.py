#!/usr/bin/env python3
"""Validate graph replay for the gfx950 Qwen3.6 fused split+M12 convolution."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch
from safetensors import safe_open

from sglang.jit_kernel.triton.gdn_fused_proj import (
    fused_qkvzba_split_reshape_cat_contiguous,
)
from sglang.srt.layers.attention.mamba.causal_conv1d_triton import (
    causal_conv1d_update,
)


LAYER = 0
CAPTURE_BATCH = 64
TOKENS = 12
QKV_DIM = 8192
QKVZ_DIM = 12288
BA_DIM = 64
WIDTH = 4
WEIGHT_KEY = f"model.language_model.layers.{LAYER}.linear_attn.conv1d.weight"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=200)
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
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, (9 * len(ordered) + 9) // 10 - 1)],
        "maximum_us": ordered[-1],
    }


def load_weight(model_dir: Path) -> tuple[torch.Tensor, Path]:
    for shard in sorted(model_dir.glob("*.safetensors")):
        with safe_open(shard, framework="pt", device="cpu") as handle:
            if WEIGHT_KEY in handle.keys():
                value = handle.get_tensor(WEIGHT_KEY)
                if tuple(value.shape) != (QKV_DIM, 1, WIDTH):
                    raise ValueError(f"unexpected convolution weight: {value.shape}")
                return value.squeeze(1).contiguous(), shard
    raise KeyError(WEIGHT_KEY)


def time_graph(graph: torch.cuda.CUDAGraph, iterations: int) -> list[float]:
    for _ in range(10):
        graph.replay()
    torch.cuda.synchronize()
    result: list[float] = []
    for _ in range(iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        graph.replay()
        end.record()
        end.synchronize()
        result.append(float(start.elapsed_time(end) * 1000.0))
    return result


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"requires gfx950, got {architecture}")

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=False)
    prefix = f"gdn_stage.layer.{LAYER}.backend"
    qkv_cpu = payload[f"gdn_stage.layer.{LAYER}.mixed_qkv"]
    initial_state_cpu = payload[f"{prefix}.initial_conv"]
    expected_qkv_cpu = payload[f"{prefix}.post_conv_mixed_qkv"]
    expected_state_cpu = payload[f"gdn.layer.{LAYER}.conv.0"]
    expected_window_cpu = payload[
        f"gdn.layer.{LAYER}.intermediate_conv_window.0"
    ]
    if tuple(qkv_cpu.shape) != (CAPTURE_BATCH * TOKENS, QKV_DIM):
        raise ValueError(f"unexpected QKV capture: {qkv_cpu.shape}")

    weight_cpu, weight_shard = load_weight(args.model_dir)
    qkv = qkv_cpu.contiguous().to(device)
    initial_state = initial_state_cpu.contiguous().to(device)
    expected_qkv = expected_qkv_cpu.contiguous().to(device)
    expected_state = expected_state_cpu.contiguous().to(device)
    expected_window = expected_window_cpu.contiguous().to(device)
    weight = weight_cpu.to(device)
    del payload

    rows = CAPTURE_BATCH * TOKENS
    qkvz = torch.empty((rows, QKVZ_DIM), dtype=torch.bfloat16, device=device)
    qkvz[:, :QKV_DIM].copy_(qkv)
    z_seed = ((torch.arange(rows * 4096, device=device) % 997) - 498).float()
    qkvz[:, QKV_DIM:].copy_((z_seed / 257.0).to(torch.bfloat16).view(rows, 4096))
    ba_seed = ((torch.arange(rows * BA_DIM, device=device) % 127) - 63).float()
    ba = (ba_seed / 97.0).to(torch.bfloat16).view(rows, BA_DIM).contiguous()
    expected_z = qkvz[:, QKV_DIM:].reshape(rows, 32, 128).contiguous()
    expected_b = ba[:, :32].contiguous()
    expected_a = ba[:, 32:].contiguous()

    state_indices = torch.arange(CAPTURE_BATCH, dtype=torch.int32, device=device)
    intermediate_indices = state_indices.clone()

    def baseline(state: torch.Tensor, window: torch.Tensor):
        split_qkv, z, b, a = fused_qkvzba_split_reshape_cat_contiguous(
            qkvz, ba, 16, 32, 128, 128
        )
        x = split_qkv.view(CAPTURE_BATCH, TOKENS, QKV_DIM).transpose(1, 2)
        processed = causal_conv1d_update(
            x,
            state,
            weight,
            bias=None,
            activation="silu",
            conv_state_indices=state_indices,
            intermediate_conv_window=window,
            intermediate_state_indices=intermediate_indices,
        )
        return processed.transpose(1, 2).reshape(rows, QKV_DIM), z, b, a

    baseline_state = initial_state.clone()
    baseline_window = torch.empty_like(expected_window)
    baseline_qkv, baseline_z, baseline_b, baseline_a = baseline(
        baseline_state, baseline_window
    )
    torch.cuda.synchronize()

    library = ctypes.CDLL(
        str(args.build_dir / "libqwen36_gdn_qkvz_conv_m12_bridge.so")
    )
    library.netra_qwen36_gdn_qkvz_conv_m12_load.argtypes = [ctypes.c_char_p]
    library.netra_qwen36_gdn_qkvz_conv_m12_load.restype = ctypes.c_int
    library.netra_qwen36_gdn_qkvz_conv_m12_launch.argtypes = (
        [ctypes.c_void_p] * 7 + [ctypes.c_uint32, ctypes.c_void_p]
    )
    library.netra_qwen36_gdn_qkvz_conv_m12_launch.restype = ctypes.c_int
    library.netra_qwen36_gdn_qkvz_conv_m12_last_error.restype = ctypes.c_char_p
    hsaco = args.build_dir / "qwen36_gdn_qkvz_conv_m12_gfx950.hsaco"
    status = library.netra_qwen36_gdn_qkvz_conv_m12_load(str(hsaco).encode())
    if status:
        raise RuntimeError(
            library.netra_qwen36_gdn_qkvz_conv_m12_last_error().decode()
        )

    raw_state = initial_state.clone()
    raw_window = torch.empty_like(expected_window)
    raw_qkv = torch.empty((rows, QKV_DIM), dtype=torch.bfloat16, device=device)
    def raw_launch() -> None:
        stream = torch.cuda.current_stream(device)
        status = library.netra_qwen36_gdn_qkvz_conv_m12_launch(
            pointer(qkvz), pointer(weight), pointer(raw_state),
            pointer(state_indices), pointer(raw_window), pointer(intermediate_indices),
            pointer(raw_qkv), CAPTURE_BATCH, ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                library.netra_qwen36_gdn_qkvz_conv_m12_last_error().decode()
            )

    raw_launch()
    torch.cuda.synchronize()
    correctness = {
        "baseline_qkv": compare(baseline_qkv, expected_qkv),
        "baseline_z": compare(baseline_z, expected_z),
        "baseline_b": compare(baseline_b, expected_b),
        "baseline_a": compare(baseline_a, expected_a),
        "raw_qkv": compare(raw_qkv, expected_qkv),
        "qkvz_z_view": compare(qkvz[:, QKV_DIM:].reshape(rows, 32, 128), expected_z),
        "ba_b_view": compare(ba[:, :32], expected_b),
        "ba_a_view": compare(ba[:, 32:], expected_a),
        "raw_state": compare(raw_state, expected_state),
        "raw_window": compare(raw_window, expected_window),
    }

    baseline_graph_state = initial_state.clone()
    baseline_graph_window = torch.empty_like(expected_window)
    baseline_graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(baseline_graph):
        baseline_graph_outputs = baseline(baseline_graph_state, baseline_graph_window)

    raw_state.copy_(initial_state)
    raw_graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(raw_graph):
        raw_launch()
    raw_state.copy_(initial_state)
    raw_graph.replay()
    torch.cuda.synchronize()
    graph_correctness = {
        "raw_qkv": compare(raw_qkv, expected_qkv),
        "qkvz_z_view": compare(qkvz[:, QKV_DIM:].reshape(rows, 32, 128), expected_z),
        "ba_b_view": compare(ba[:, :32], expected_b),
        "ba_a_view": compare(ba[:, 32:], expected_a),
    }
    _ = baseline_graph_outputs

    baseline_timings = time_graph(baseline_graph, args.iterations)
    raw_timings = time_graph(raw_graph, args.iterations)
    baseline_stats = distribution(baseline_timings)
    raw_stats = distribution(raw_timings)
    result = {
        "architecture": str(architecture),
        "state_pass": str(args.state_pass),
        "weight_shard": str(weight_shard),
        "shape": {"batch": CAPTURE_BATCH, "tokens": TOKENS, "qkvz": QKVZ_DIM},
        "correctness": correctness,
        "graph_correctness": graph_correctness,
        "graph_hip_event": {"triton_split_plus_conv": baseline_stats, "raw_fused": raw_stats},
        "graph_speedup": baseline_stats["median_us"] / raw_stats["median_us"],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    if not all(entry["bit_exact"] for entry in correctness.values()):
        raise SystemExit("eager correctness failure")
    if not all(entry["bit_exact"] for entry in graph_correctness.values()):
        raise SystemExit("graph correctness failure")


if __name__ == "__main__":
    main()
