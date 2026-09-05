#!/usr/bin/env python3
"""Validate and time fused QKVZ/BA split + M=12 Qwen3.6 GDN convolution."""

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
BATCH = 64
TOKENS_PER_SEQUENCE = 12
DIM = 8192
Z_DIM = 4096
BA_DIM = 64
WIDTH = 4
WEIGHT_KEY = f"model.language_model.layers.{LAYER}.linear_attn.conv1d.weight"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    delta = (actual.float() - expected.float()).abs()
    mismatches = actual != expected
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int(mismatches.sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
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


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def load_weight(model_dir: Path) -> tuple[torch.Tensor, Path]:
    for shard in sorted(model_dir.glob("*.safetensors")):
        with safe_open(shard, framework="pt", device="cpu") as handle:
            if WEIGHT_KEY in handle.keys():
                weight = handle.get_tensor(WEIGHT_KEY)
                if tuple(weight.shape) != (DIM, 1, WIDTH):
                    raise ValueError(f"unexpected convolution weight shape: {weight.shape}")
                return weight.squeeze(1).contiguous(), shard
    raise KeyError(f"{WEIGHT_KEY} not found below {model_dir}")


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

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=False)
    metadata = payload["metadata"]
    if int(metadata["batch_size"]) != BATCH:
        raise ValueError(f"expected B{BATCH} capture, got {metadata}")
    if int(metadata["input_token_count"]) != BATCH * TOKENS_PER_SEQUENCE:
        raise ValueError(f"expected M={TOKENS_PER_SEQUENCE} capture, got {metadata}")

    stage = f"gdn_stage.layer.{LAYER}"
    backend = f"{stage}.backend"
    cpu_tensors = {
        "qkvz": payload[f"{stage}.in_proj_qkvz"],
        "ba": payload[f"{stage}.in_proj_ba"],
        "mixed_qkv": payload[f"{stage}.mixed_qkv"],
        "z": payload[f"{stage}.z"],
        "b": payload[f"{stage}.b"],
        "a": payload[f"{stage}.a"],
        "initial_state": payload[f"{backend}.initial_conv"],
        "conv_output": payload[f"{backend}.post_conv_mixed_qkv"],
        "state": payload[f"gdn.layer.{LAYER}.conv.0"],
        "window": payload[f"gdn.layer.{LAYER}.intermediate_conv_window.0"],
    }
    expected_shapes = {
        "qkvz": (BATCH * TOKENS_PER_SEQUENCE, DIM + Z_DIM),
        "ba": (BATCH * TOKENS_PER_SEQUENCE, BA_DIM),
        "mixed_qkv": (BATCH * TOKENS_PER_SEQUENCE, DIM),
        "z": (BATCH * TOKENS_PER_SEQUENCE, 32, 128),
        "b": (BATCH * TOKENS_PER_SEQUENCE, 32),
        "a": (BATCH * TOKENS_PER_SEQUENCE, 32),
        "initial_state": (BATCH, DIM, WIDTH - 1),
        "conv_output": (BATCH * TOKENS_PER_SEQUENCE, DIM),
        "state": (BATCH, DIM, WIDTH - 1),
        "window": (BATCH, TOKENS_PER_SEQUENCE, DIM, WIDTH - 1),
    }
    for name, tensor in cpu_tensors.items():
        if tuple(tensor.shape) != expected_shapes[name]:
            raise ValueError(f"unexpected {name} shape: {tensor.shape}")
        if tensor.dtype != torch.bfloat16:
            raise TypeError(f"unexpected {name} dtype: {tensor.dtype}")

    weight_cpu, weight_shard = load_weight(args.model_dir)
    gpu = {name: tensor.contiguous().to(device) for name, tensor in cpu_tensors.items()}
    weight = weight_cpu.to(device)
    del payload, cpu_tensors

    state_indices = torch.arange(BATCH, dtype=torch.int32, device=device)
    intermediate_indices = torch.arange(BATCH, dtype=torch.int32, device=device)

    def invoke_triton(state: torch.Tensor, window: torch.Tensor):
        mixed_qkv, z, b, a = fused_qkvzba_split_reshape_cat_contiguous(
            gpu["qkvz"], gpu["ba"], 16, 32, 128, 128
        )
        x = mixed_qkv.view(BATCH, TOKENS_PER_SEQUENCE, DIM).transpose(1, 2)
        conv = causal_conv1d_update(
            x,
            state,
            weight,
            bias=None,
            activation="silu",
            conv_state_indices=state_indices,
            intermediate_conv_window=window,
            intermediate_state_indices=intermediate_indices,
        )
        return (
            mixed_qkv,
            z,
            b,
            a,
            conv.transpose(1, 2).reshape(BATCH * TOKENS_PER_SEQUENCE, DIM),
        )

    triton_state = gpu["initial_state"].clone()
    triton_window = torch.empty_like(gpu["window"])
    triton_outputs = invoke_triton(triton_state, triton_window)
    torch.cuda.synchronize(device)
    expected_names = ("mixed_qkv", "z", "b", "a", "conv_output")
    triton_correctness = {
        name: compare(actual, gpu[name])
        for name, actual in zip(expected_names, triton_outputs)
    }
    triton_correctness.update(
        {
            "final_state": compare(triton_state, gpu["state"]),
            "intermediate_window": compare(triton_window, gpu["window"]),
        }
    )

    for _ in range(5):
        triton_state.copy_(gpu["initial_state"])
        triton_outputs = invoke_triton(triton_state, triton_window)
    torch.cuda.synchronize(device)
    triton_timings_us: list[float] = []
    for _ in range(args.iterations):
        triton_state.copy_(gpu["initial_state"])
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        triton_outputs = invoke_triton(triton_state, triton_window)
        end.record()
        end.synchronize()
        triton_timings_us.append(float(start.elapsed_time(end) * 1000.0))

    raw_result: dict[str, object] | None = None
    if args.build_dir is not None:
        bridge = ctypes.CDLL(str(args.build_dir / "libqwen36_gdn_split_conv_m12_bridge.so"))
        bridge.netra_qwen36_gdn_split_conv_m12_load.argtypes = [ctypes.c_char_p]
        bridge.netra_qwen36_gdn_split_conv_m12_load.restype = ctypes.c_int
        bridge.netra_qwen36_gdn_split_conv_m12_launch.argtypes = (
            [ctypes.c_void_p] * 11 + [ctypes.c_uint32, ctypes.c_void_p]
        )
        bridge.netra_qwen36_gdn_split_conv_m12_launch.restype = ctypes.c_int
        bridge.netra_qwen36_gdn_split_conv_m12_last_error.restype = ctypes.c_char_p
        hsaco = args.build_dir / "qwen36_gdn_split_conv_m12_gfx950.hsaco"
        status = bridge.netra_qwen36_gdn_split_conv_m12_load(str(hsaco).encode())
        if status:
            raise RuntimeError(bridge.netra_qwen36_gdn_split_conv_m12_last_error().decode())

        raw_state = gpu["initial_state"].clone()
        raw_window = torch.empty_like(gpu["window"])
        raw_output = torch.empty_like(gpu["conv_output"])
        raw_z = torch.empty_like(gpu["z"])
        raw_b = torch.empty_like(gpu["b"])
        raw_a = torch.empty_like(gpu["a"])

        def invoke_raw() -> None:
            stream = torch.cuda.current_stream(device)
            status = bridge.netra_qwen36_gdn_split_conv_m12_launch(
                pointer(gpu["qkvz"]),
                pointer(gpu["ba"]),
                pointer(weight),
                pointer(raw_state),
                pointer(state_indices),
                pointer(raw_window),
                pointer(intermediate_indices),
                pointer(raw_output),
                pointer(raw_z),
                pointer(raw_b),
                pointer(raw_a),
                BATCH,
                ctypes.c_void_p(stream.cuda_stream),
            )
            if status:
                raise RuntimeError(
                    bridge.netra_qwen36_gdn_split_conv_m12_last_error().decode()
                )

        invoke_raw()
        torch.cuda.synchronize(device)
        raw_correctness = {
            "z": compare(raw_z, gpu["z"]),
            "b": compare(raw_b, gpu["b"]),
            "a": compare(raw_a, gpu["a"]),
            "conv_output": compare(raw_output, gpu["conv_output"]),
            "final_state": compare(raw_state, gpu["state"]),
            "intermediate_window": compare(raw_window, gpu["window"]),
        }

        for _ in range(5):
            raw_state.copy_(gpu["initial_state"])
            invoke_raw()
        torch.cuda.synchronize(device)
        raw_timings_us: list[float] = []
        for _ in range(args.iterations):
            raw_state.copy_(gpu["initial_state"])
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            invoke_raw()
            end.record()
            end.synchronize()
            raw_timings_us.append(float(start.elapsed_time(end) * 1000.0))
        raw_result = {
            "hsaco": str(hsaco),
            "correctness": raw_correctness,
            "hip_event": distribution(raw_timings_us),
        }

    triton_distribution = distribution(triton_timings_us)
    result = {
        "architecture": str(architecture),
        "state_pass": str(args.state_pass),
        "weight_shard": str(weight_shard),
        "weight_key": WEIGHT_KEY,
        "shape": {
            "batch": BATCH,
            "tokens_per_sequence": TOKENS_PER_SEQUENCE,
            "qkvz_dim": DIM + Z_DIM,
            "ba_dim": BA_DIM,
            "convolution_dim": DIM,
            "z_dim": Z_DIM,
            "width": WIDTH,
        },
        "dtype": "torch.bfloat16",
        "triton": {
            "correctness": triton_correctness,
            "hip_event": triton_distribution,
        },
        "raw_gfx950": raw_result,
    }
    if raw_result is not None:
        result["speedup_median"] = (
            triton_distribution["median_us"] / raw_result["hip_event"]["median_us"]
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))

    if not all(entry["bit_exact"] for entry in triton_correctness.values()):
        raise SystemExit("captured Triton reconstruction was not bit exact")
    if raw_result is not None and not all(
        entry["bit_exact"] for entry in raw_result["correctness"].values()
    ):
        raise SystemExit("raw gfx950 fused split-convolution was not bit exact")


if __name__ == "__main__":
    main()
