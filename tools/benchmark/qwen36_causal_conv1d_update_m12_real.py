#!/usr/bin/env python3
"""Reconstruct Qwen3.6 layer-0 M=12 target-verification causal convolution.

This is the real-checkpoint correctness and timing oracle for the gfx950 raw
assembly implementation.  It deliberately preserves the production tensor
layout, including the non-contiguous ``(batch, dim, token)`` input view and the
full speculative intermediate convolution window.
"""

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


LAYER = 0
BATCH = 64
TOKENS_PER_SEQUENCE = 12
DIM = 8192
WIDTH = 4
WEIGHT_KEY = f"model.language_model.layers.{LAYER}.linear_attn.conv1d.weight"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--state-slot-offset", type=int, default=0)
    parser.add_argument("--intermediate-slot-offset", type=int, default=0)
    parser.add_argument("--valid-batch", type=int, default=BATCH)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    actual_f32 = actual.float()
    expected_f32 = expected.float()
    delta = (actual_f32 - expected_f32).abs()
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
    if args.state_slot_offset < 0 or args.intermediate_slot_offset < 0:
        raise ValueError("slot offsets must be nonnegative")
    if not 1 <= args.valid_batch <= BATCH:
        raise ValueError(f"valid batch must be in [1,{BATCH}]")

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

    prefix = f"gdn_stage.layer.{LAYER}.backend"
    mixed_qkv_cpu = payload[f"gdn_stage.layer.{LAYER}.mixed_qkv"]
    initial_state_cpu = payload[f"{prefix}.initial_conv"]
    expected_output_cpu = payload[f"{prefix}.post_conv_mixed_qkv"]
    expected_state_cpu = payload[f"gdn.layer.{LAYER}.conv.0"]
    expected_window_cpu = payload[
        f"gdn.layer.{LAYER}.intermediate_conv_window.0"
    ]

    expected_shapes = {
        "mixed_qkv": (BATCH * TOKENS_PER_SEQUENCE, DIM),
        "initial_state": (BATCH, DIM, WIDTH - 1),
        "output": (BATCH * TOKENS_PER_SEQUENCE, DIM),
        "state": (BATCH, DIM, WIDTH - 1),
        "window": (BATCH, TOKENS_PER_SEQUENCE, DIM, WIDTH - 1),
    }
    tensors = {
        "mixed_qkv": mixed_qkv_cpu,
        "initial_state": initial_state_cpu,
        "output": expected_output_cpu,
        "state": expected_state_cpu,
        "window": expected_window_cpu,
    }
    for name, tensor in tensors.items():
        if tuple(tensor.shape) != expected_shapes[name]:
            raise ValueError(f"unexpected {name} shape: {tensor.shape}")
        if tensor.dtype != torch.bfloat16:
            raise TypeError(f"unexpected {name} dtype: {tensor.dtype}")

    weight_cpu, weight_shard = load_weight(args.model_dir)
    mixed_qkv = mixed_qkv_cpu.contiguous().to(device)
    # Production ABI: token-major storage viewed as (B, D, M), so feature is
    # contiguous and the token stride is DIM.
    x = mixed_qkv.view(BATCH, TOKENS_PER_SEQUENCE, DIM).transpose(1, 2)
    # The live Mamba cache is contiguous (cache, D, win), matching the capture.
    initial_state = initial_state_cpu.contiguous().to(device)
    expected_output = expected_output_cpu.contiguous().to(device)
    expected_state = expected_state_cpu.contiguous().to(device)
    expected_window = expected_window_cpu.contiguous().to(device)
    weight = weight_cpu.to(device)
    del payload

    state_indices = torch.arange(BATCH, dtype=torch.int32, device=device)
    intermediate_indices = torch.arange(BATCH, dtype=torch.int32, device=device)

    def invoke(state: torch.Tensor, window: torch.Tensor) -> torch.Tensor:
        output = causal_conv1d_update(
            x,
            state,
            weight,
            bias=None,
            activation="silu",
            conv_state_indices=state_indices,
            intermediate_conv_window=window,
            intermediate_state_indices=intermediate_indices,
        )
        return output.transpose(1, 2).reshape(BATCH * TOKENS_PER_SEQUENCE, DIM)

    actual_state = initial_state.clone()
    actual_window = torch.empty_like(expected_window)
    actual_output = invoke(actual_state, actual_window)
    torch.cuda.synchronize(device)

    correctness = {
        "output": compare(actual_output, expected_output),
        "final_state": compare(actual_state, expected_state),
        "intermediate_window": compare(actual_window, expected_window),
    }

    timing_state = initial_state.clone()
    timing_window = torch.empty_like(expected_window)
    for _ in range(5):
        timing_state.copy_(initial_state)
        invoke(timing_state, timing_window)
    torch.cuda.synchronize(device)

    timings_us: list[float] = []
    for _ in range(args.iterations):
        timing_state.copy_(initial_state)
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        invoke(timing_state, timing_window)
        end.record()
        end.synchronize()
        timings_us.append(float(start.elapsed_time(end) * 1000.0))

    raw_result: dict[str, object] | None = None
    if args.build_dir is not None:
        bridge = ctypes.CDLL(
            str(args.build_dir / "libqwen36_gdn_causal_conv_m12_bridge.so")
        )
        bridge.netra_qwen36_gdn_causal_conv_m12_load.argtypes = [ctypes.c_char_p]
        bridge.netra_qwen36_gdn_causal_conv_m12_load.restype = ctypes.c_int
        bridge.netra_qwen36_gdn_causal_conv_m12_launch.argtypes = (
            [ctypes.c_void_p] * 7 + [ctypes.c_uint32, ctypes.c_void_p]
        )
        bridge.netra_qwen36_gdn_causal_conv_m12_launch.restype = ctypes.c_int
        bridge.netra_qwen36_gdn_causal_conv_m12_last_error.restype = ctypes.c_char_p
        hsaco = args.build_dir / "qwen36_gdn_causal_conv_m12_gfx950.hsaco"
        status = bridge.netra_qwen36_gdn_causal_conv_m12_load(str(hsaco).encode())
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_causal_conv_m12_last_error().decode()
            )

        valid_batch = args.valid_batch
        raw_state_pool = torch.empty(
            (args.state_slot_offset + valid_batch, DIM, WIDTH - 1),
            dtype=torch.bfloat16,
            device=device,
        )
        raw_state = raw_state_pool[
            args.state_slot_offset : args.state_slot_offset + valid_batch
        ]
        raw_state.copy_(initial_state[:valid_batch])
        raw_window_pool = torch.empty(
            (
                args.intermediate_slot_offset + valid_batch,
                TOKENS_PER_SEQUENCE,
                DIM,
                WIDTH - 1,
            ),
            dtype=torch.bfloat16,
            device=device,
        )
        raw_window = raw_window_pool[
            args.intermediate_slot_offset : args.intermediate_slot_offset
            + valid_batch
        ]
        raw_output_view = torch.empty_like(x)
        raw_output_view.zero_()
        raw_state_indices = torch.full(
            (BATCH,), -1, dtype=torch.int32, device=device
        )
        raw_intermediate_indices = torch.full(
            (BATCH,), -1, dtype=torch.int32, device=device
        )
        raw_state_indices[:valid_batch] = torch.arange(
            args.state_slot_offset,
            args.state_slot_offset + valid_batch,
            dtype=torch.int32,
            device=device,
        )
        raw_intermediate_indices[:valid_batch] = torch.arange(
            args.intermediate_slot_offset,
            args.intermediate_slot_offset + valid_batch,
            dtype=torch.int32,
            device=device,
        )

        def invoke_raw() -> None:
            stream = torch.cuda.current_stream(device)
            status = bridge.netra_qwen36_gdn_causal_conv_m12_launch(
                pointer(x),
                pointer(weight),
                pointer(raw_state_pool),
                pointer(raw_state_indices),
                pointer(raw_window_pool),
                pointer(raw_intermediate_indices),
                pointer(raw_output_view),
                BATCH,
                ctypes.c_void_p(stream.cuda_stream),
            )
            if status:
                raise RuntimeError(
                    bridge.netra_qwen36_gdn_causal_conv_m12_last_error().decode()
                )

        invoke_raw()
        torch.cuda.synchronize(device)
        raw_output = raw_output_view.transpose(1, 2).reshape(
            BATCH * TOKENS_PER_SEQUENCE, DIM
        )
        raw_correctness = {
            "output": compare(
                raw_output[: valid_batch * TOKENS_PER_SEQUENCE],
                expected_output[: valid_batch * TOKENS_PER_SEQUENCE],
            ),
            "final_state": compare(raw_state, expected_state[:valid_batch]),
            "intermediate_window": compare(
                raw_window, expected_window[:valid_batch]
            ),
            "padded_output_unchanged": bool(
                torch.count_nonzero(raw_output_view[valid_batch:]).item() == 0
            ),
        }

        for _ in range(5):
            raw_state.copy_(initial_state[:valid_batch])
            invoke_raw()
        torch.cuda.synchronize(device)
        raw_timings_us: list[float] = []
        for _ in range(args.iterations):
            raw_state.copy_(initial_state[:valid_batch])
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            invoke_raw()
            end.record()
            end.synchronize()
            raw_timings_us.append(float(start.elapsed_time(end) * 1000.0))
        raw_result = {
            "hsaco": str(hsaco),
            "state_slot_offset": args.state_slot_offset,
            "intermediate_slot_offset": args.intermediate_slot_offset,
            "valid_batch": valid_batch,
            "correctness": raw_correctness,
            "hip_event": distribution(raw_timings_us),
        }

    result = {
        "architecture": str(architecture),
        "state_pass": str(args.state_pass),
        "weight_shard": str(weight_shard),
        "weight_key": WEIGHT_KEY,
        "shape": {
            "batch": BATCH,
            "tokens_per_sequence": TOKENS_PER_SEQUENCE,
            "dim": DIM,
            "width": WIDTH,
            "x_shape": list(x.shape),
            "x_stride": list(x.stride()),
            "state_shape": list(actual_state.shape),
            "state_stride": list(actual_state.stride()),
            "window_shape": list(actual_window.shape),
            "window_stride": list(actual_window.stride()),
        },
        "dtype": str(x.dtype),
        "correctness": correctness,
        "triton_hip_event": distribution(timings_us),
        "raw_gfx950": raw_result,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))

    if not all(entry["bit_exact"] for entry in correctness.values()):
        raise SystemExit("captured Triton reconstruction was not bit exact")
    if raw_result is not None:
        raw_correctness = raw_result["correctness"]
        if not all(
            raw_correctness[name]["bit_exact"]
            for name in ("output", "final_state", "intermediate_window")
        ) or not raw_correctness["padded_output_unchanged"]:
            raise SystemExit("raw gfx950 convolution was not bit exact")


if __name__ == "__main__":
    main()
