#!/usr/bin/env python3
"""Validate and HIP-event time the exact Qwen3.6 M8192 causal convolution."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch

from sglang.srt.layers.attention.mamba.causal_conv1d_triton import (
    causal_conv1d_fn,
)


TOKENS = 8192
DIM = 8192
WIDTH = 4


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=50)
    parser.add_argument("--seed", type=int, default=950)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def distribution(samples: list[float]) -> dict[str, float | int]:
    ordered = sorted(samples)
    return {
        "count": len(ordered),
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, (9 * len(ordered) + 9) // 10 - 1)],
        "maximum_us": ordered[-1],
    }


def comparison(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    actual_f32 = actual.float()
    expected_f32 = expected.float()
    delta = (actual_f32 - expected_f32).abs()
    dot = torch.sum(actual_f32 * expected_f32, dtype=torch.float64)
    norm = torch.linalg.vector_norm(actual_f32.double())
    norm *= torch.linalg.vector_norm(expected_f32.double())
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
        "cosine": float((dot / norm).item()),
        "nan_count": int(torch.isnan(actual).sum().item()),
    }


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if args.iterations <= 0:
        raise ValueError("iterations must be positive")

    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    torch.manual_seed(args.seed)
    # Production storage is token-major. The operator consumes its transposed
    # (D,T) view with strides (1,D).
    token_major = torch.randn(
        (TOKENS, DIM), device=device, dtype=torch.bfloat16
    ).mul_(0.125)
    x = token_major.transpose(0, 1)
    weight = torch.randn(
        (DIM, WIDTH), device=device, dtype=torch.bfloat16
    ).mul_(0.02)
    initial_state = torch.randn(
        (4, DIM, WIDTH - 1), device=device, dtype=torch.bfloat16
    ).mul_(0.125)
    query_start = torch.tensor([0, TOKENS], device=device, dtype=torch.int32)
    cache_indices = torch.tensor([3], device=device, dtype=torch.int32)

    bridge = ctypes.CDLL(
        str(args.build_dir / "libqwen36_gdn_causal_conv_m8192_bridge.so")
    )
    bridge.netra_qwen36_gdn_causal_conv_m8192_load.argtypes = [ctypes.c_char_p]
    bridge.netra_qwen36_gdn_causal_conv_m8192_load.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_causal_conv_m8192_launch.argtypes = [ctypes.c_void_p] * 7
    bridge.netra_qwen36_gdn_causal_conv_m8192_launch.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_causal_conv_m8192_last_error.restype = ctypes.c_char_p

    hsaco = args.build_dir / "qwen36_gdn_causal_conv_m8192_bm32_gfx950.hsaco"
    status = bridge.netra_qwen36_gdn_causal_conv_m8192_load(str(hsaco).encode())
    if status:
        raise RuntimeError(
            bridge.netra_qwen36_gdn_causal_conv_m8192_last_error().decode()
        )
    stream = ctypes.c_void_p(torch.cuda.current_stream(device).cuda_stream)

    def raw(
        state: torch.Tensor,
        output: torch.Tensor,
        has_initial: torch.Tensor,
    ) -> None:
        status = bridge.netra_qwen36_gdn_causal_conv_m8192_launch(
            pointer(x),
            pointer(weight),
            pointer(state),
            pointer(cache_indices),
            pointer(has_initial),
            pointer(output),
            stream,
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_causal_conv_m8192_last_error().decode()
            )

    correctness: dict[str, object] = {}
    for has_initial in (False, True):
        has_initial_tensor = torch.tensor(
            [has_initial], device=device, dtype=torch.bool
        )
        reference_state = initial_state.clone()
        reference = causal_conv1d_fn(
            x,
            weight,
            None,
            reference_state,
            query_start,
            [TOKENS],
            cache_indices,
            has_initial_tensor,
            "silu",
            validate_data=True,
        )
        raw_state = initial_state.clone()
        raw_output = torch.empty_like(x)
        raw_output.fill_(float("nan"))
        raw(raw_state, raw_output, has_initial_tensor)
        torch.cuda.synchronize(device)
        correctness[str(has_initial).lower()] = {
            "output": comparison(raw_output, reference),
            "state": comparison(raw_state, reference_state),
        }

    timing_has_initial = torch.tensor([False], device=device, dtype=torch.bool)
    triton_state = initial_state.clone()
    raw_state = initial_state.clone()
    raw_output = torch.empty_like(x)

    def invoke_triton() -> None:
        causal_conv1d_fn(
            x,
            weight,
            None,
            triton_state,
            query_start,
            [TOKENS],
            cache_indices,
            timing_has_initial,
            "silu",
        )

    def invoke_raw() -> None:
        raw(raw_state, raw_output, timing_has_initial)

    for _ in range(5):
        invoke_triton()
        invoke_raw()
    torch.cuda.synchronize(device)

    triton_samples: list[float] = []
    raw_samples: list[float] = []
    for invoke, samples in (
        (invoke_triton, triton_samples),
        (invoke_raw, raw_samples),
    ):
        for _ in range(args.iterations):
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            invoke()
            end.record()
            end.synchronize()
            samples.append(float(start.elapsed_time(end) * 1000.0))

    false_output = correctness["false"]["output"]
    true_output = correctness["true"]["output"]
    false_state = correctness["false"]["state"]
    true_state = correctness["true"]["state"]
    gate = bool(
        false_output["nan_count"] == 0
        and true_output["nan_count"] == 0
        and false_output["max_abs"] <= 0.0078125
        and true_output["max_abs"] <= 0.0078125
        and false_output["cosine"] >= 0.99999
        and true_output["cosine"] >= 0.99999
        and false_state["bit_exact"]
        and true_state["bit_exact"]
    )
    result = {
        "schema_version": 1,
        "measurement_status": "measured",
        "target": architecture,
        "shape": {
            "batch": 1,
            "tokens": TOKENS,
            "dim": DIM,
            "width": WIDTH,
            "dtype": "bfloat16",
            "activation": "silu",
            "input_strides": list(x.stride()),
        },
        "correctness": correctness,
        "correctness_gate": {
            "max_abs": 0.0078125,
            "minimum_cosine": 0.99999,
            "state_bit_exact": True,
            "pass": gate,
        },
        "timing": {
            "method": "HIP events",
            "triton": distribution(triton_samples),
            "raw_gfx950": distribution(raw_samples),
            "speedup": statistics.median(triton_samples)
            / statistics.median(raw_samples),
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
