#!/usr/bin/env python3
"""Validate the raw gfx950 GDN M=16 path through the SGLang wrapper.

This intentionally calls SGLang's fused recurrent entry point rather than the
netra-kernel bridge directly.  The control call uses the deployed Triton path;
the candidate call must reach the raw-module bridge exactly once.  Inputs and
expected outputs are exported from a real Qwen3.6 dFlash verification pass.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import statistics
from pathlib import Path
from typing import Callable

import torch


BF16_ATOL = 0.03125
BF16_RTOL = 0.010
BF16_RELATIVE_FLOOR = BF16_ATOL
BF16_MINIMUM_COSINE = 0.9995

ENABLE_ENV = "SGLANG_NETRA_QWEN36_GFX950_GDN_VERIFY_M16"
BRIDGE_ENV = "SGLANG_NETRA_QWEN36_GFX950_GDN_VERIFY_M16_BRIDGE"
PRECOMPUTE_ENV = (
    "SGLANG_NETRA_QWEN36_GFX950_GDN_VERIFY_M16_PRECOMPUTE_HSACO"
)
CORE_ENV = "SGLANG_NETRA_QWEN36_GFX950_GDN_VERIFY_M16_CORE_HSACO"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--precompute-hsaco", type=Path, required=True)
    parser.add_argument("--core-hsaco", type=Path, required=True)
    parser.add_argument("--warmup", type=int, default=20)
    parser.add_argument("--iterations", type=int, default=200)
    return parser.parse_args()


def load_tensor(
    directory: Path,
    name: str,
    dtype: torch.dtype,
    shape: tuple[int, ...],
) -> torch.Tensor:
    elements = math.prod(shape)
    path = directory / name
    tensor = torch.from_file(
        str(path), shared=False, size=elements, dtype=dtype
    ).clone()
    if tensor.numel() != elements:
        raise RuntimeError(
            f"{path}: got {tensor.numel()} elements, expected {elements}"
        )
    return tensor.reshape(shape)


def sha256_tensor(tensor: torch.Tensor) -> str:
    raw = (
        tensor.detach()
        .contiguous()
        .cpu()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )
    return hashlib.sha256(raw).hexdigest()


def compare_bf16(actual: torch.Tensor, expected: torch.Tensor) -> dict:
    actual_cpu = actual.detach().contiguous().cpu()
    expected_cpu = expected.detach().contiguous().cpu()
    if actual_cpu.shape != expected_cpu.shape:
        raise RuntimeError(
            f"shape mismatch: {tuple(actual_cpu.shape)} != "
            f"{tuple(expected_cpu.shape)}"
        )
    actual_f32 = actual_cpu.float().reshape(-1)
    expected_f32 = expected_cpu.float().reshape(-1)
    delta = (actual_f32 - expected_f32).abs()
    relative_mask = ~(
        (actual_f32.abs() < BF16_RELATIVE_FLOOR)
        & (expected_f32.abs() < BF16_RELATIVE_FLOOR)
    )
    if bool(relative_mask.any()):
        relative = delta[relative_mask] / expected_f32[
            relative_mask
        ].abs().clamp_min(1.0e-20)
        max_relative = float(relative.max())
    else:
        max_relative = 0.0
    actual64 = actual_f32.double()
    expected64 = expected_f32.double()
    denominator = float(
        torch.sqrt((actual64.square().sum()) * (expected64.square().sum()))
    )
    if denominator == 0.0:
        cosine = 1.0 if torch.equal(actual_cpu, expected_cpu) else 0.0
    else:
        cosine = float((actual64 * expected64).sum()) / denominator
    max_abs = float(delta.max())
    result = {
        "elements": actual_cpu.numel(),
        "bit_exact": torch.equal(actual_cpu, expected_cpu),
        "mismatches": int((actual_cpu != expected_cpu).sum()),
        "max_abs": max_abs,
        "max_relative": max_relative,
        "mean_abs": float(delta.mean()),
        "rmse": float(torch.sqrt(delta.square().mean())),
        "cosine": cosine,
        "actual_sha256": sha256_tensor(actual_cpu),
        "expected_sha256": sha256_tensor(expected_cpu),
    }
    result["preregistered_pass"] = (
        bool(torch.isfinite(actual_f32).all())
        and bool(torch.isfinite(expected_f32).all())
        and max_abs <= BF16_ATOL
        and max_relative <= BF16_RTOL
        and cosine >= BF16_MINIMUM_COSINE
    )
    return result


def percentile(sorted_values: list[float], fraction: float) -> float:
    index = min(
        len(sorted_values) - 1,
        max(0, math.ceil(fraction * len(sorted_values)) - 1),
    )
    return sorted_values[index]


def measure(
    call: Callable[[], torch.Tensor], warmup: int, iterations: int
) -> dict:
    for _ in range(warmup):
        call()
    torch.cuda.synchronize()
    starts = [torch.cuda.Event(enable_timing=True) for _ in range(iterations)]
    stops = [torch.cuda.Event(enable_timing=True) for _ in range(iterations)]
    outputs = []
    for start, stop in zip(starts, stops):
        start.record()
        outputs.append(call())
        stop.record()
    stops[-1].synchronize()
    timings = sorted(
        start.elapsed_time(stop) * 1000.0
        for start, stop in zip(starts, stops)
    )
    del outputs
    return {
        "iterations": iterations,
        "minimum_us": timings[0],
        "median_us": statistics.median(timings),
        "mean_us": statistics.fmean(timings),
        "p90_us": percentile(timings, 0.90),
        "maximum_us": timings[-1],
        "timing": "HIP events around the complete SGLang wrapper call",
    }


def main() -> None:
    args = parse_args()
    if args.warmup < 1 or args.iterations < 1:
        raise ValueError("warmup and iterations must be positive")
    for path in (
        args.capture_dir,
        args.bridge,
        args.precompute_hsaco,
        args.core_hsaco,
    ):
        if not path.exists():
            raise FileNotFoundError(path)

    if not torch.cuda.is_available():
        raise RuntimeError("ROCm device is unavailable")
    device = torch.device("cuda", 0)
    properties = torch.cuda.get_device_properties(device)
    architecture = properties.gcnArchName
    if not architecture.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    capture = args.capture_dir
    cpu_inputs = {
        "A_log": load_tensor(capture, "A_log_f32.bin", torch.float32, (32,)),
        "a": load_tensor(capture, "a_bf16.bin", torch.bfloat16, (16, 32)),
        "dt_bias": load_tensor(
            capture, "dt_bias_bf16.bin", torch.bfloat16, (32,)
        ),
        "q": load_tensor(
            capture, "q_bf16.bin", torch.bfloat16, (1, 16, 16, 128)
        ),
        "k": load_tensor(
            capture, "k_bf16.bin", torch.bfloat16, (1, 16, 16, 128)
        ),
        "v": load_tensor(
            capture, "v_bf16.bin", torch.bfloat16, (1, 16, 32, 128)
        ),
        "b": load_tensor(capture, "b_bf16.bin", torch.bfloat16, (16, 32)),
        "initial": load_tensor(
            capture,
            "initial_ssm_bf16.bin",
            torch.bfloat16,
            (1, 32, 128, 128),
        ),
        "initial_indices": load_tensor(
            capture, "cache_indices_i32.bin", torch.int32, (1,)
        ),
        "intermediate_indices": load_tensor(
            capture,
            "intermediate_state_indices_i32.bin",
            torch.int32,
            (1,),
        ),
        "cu_seqlens": load_tensor(
            capture, "query_start_loc_i32.bin", torch.int32, (2,)
        ),
    }
    expected_output = load_tensor(
        capture,
        "expected_output_bf16.bin",
        torch.bfloat16,
        (1, 16, 32, 128),
    )
    expected_final = load_tensor(
        capture,
        "expected_final_ssm_bf16.bin",
        torch.bfloat16,
        (1, 32, 128, 128),
    )
    inputs = {name: tensor.to(device) for name, tensor in cpu_inputs.items()}

    initial_index = int(cpu_inputs["initial_indices"].item())
    intermediate_index = int(cpu_inputs["intermediate_indices"].item())
    if initial_index < 0 or intermediate_index < 0:
        raise RuntimeError("captured state indices must be nonnegative")
    initial_pool = torch.zeros(
        (initial_index + 1, 32, 128, 128),
        dtype=torch.bfloat16,
        device=device,
    )
    initial_pool[initial_index].copy_(inputs["initial"][0])

    def new_intermediate_pool() -> torch.Tensor:
        return torch.zeros(
            (intermediate_index + 1, 16, 32, 128, 128),
            dtype=torch.bfloat16,
            device=device,
        )

    from sglang.srt.layers.attention.fla.fused_sigmoid_gating_recurrent import (
        fused_sigmoid_gating_delta_rule_update,
    )

    def call(intermediate: torch.Tensor) -> torch.Tensor:
        return fused_sigmoid_gating_delta_rule_update(
            A_log=inputs["A_log"],
            a=inputs["a"],
            dt_bias=inputs["dt_bias"],
            softplus_beta=1.0,
            softplus_threshold=20.0,
            q=inputs["q"],
            k=inputs["k"],
            v=inputs["v"],
            b=inputs["b"],
            initial_state_source=initial_pool,
            initial_state_indices=inputs["initial_indices"],
            scale=128**-0.5,
            use_qk_l2norm_in_kernel=True,
            cu_seqlens=inputs["cu_seqlens"],
            disable_state_update=True,
            intermediate_states_buffer=intermediate,
            intermediate_state_indices=inputs["intermediate_indices"],
            cache_steps=16,
        )

    os.environ[ENABLE_ENV] = "0"
    control_intermediate = new_intermediate_pool()
    control_output = call(control_intermediate)
    torch.cuda.synchronize()
    control_final = control_intermediate[
        intermediate_index, 15
    ].unsqueeze(0)

    os.environ[BRIDGE_ENV] = str(args.bridge)
    os.environ[PRECOMPUTE_ENV] = str(args.precompute_hsaco)
    os.environ[CORE_ENV] = str(args.core_hsaco)
    os.environ[ENABLE_ENV] = "1"
    from sglang.srt.layers.attention.linear import (
        netra_gfx950_qwen36_gdn_verify as netra_module,
    )

    netra_module.maybe_load_netra_qwen36_gfx950_gdn_verify_m16()
    candidate_intermediate = new_intermediate_pool()
    if not netra_module.can_launch_netra_qwen36_gfx950_gdn_verify_m16(
        A_log=inputs["A_log"],
        a=inputs["a"],
        dt_bias=inputs["dt_bias"],
        q=inputs["q"],
        k=inputs["k"],
        v=inputs["v"],
        b=inputs["b"],
        initial_state=initial_pool,
        initial_state_indices=inputs["initial_indices"],
        intermediate_state=candidate_intermediate,
        intermediate_state_indices=inputs["intermediate_indices"],
    ):
        raise RuntimeError("the real captured shape failed the raw dispatch gate")

    launch_counter = [0]
    original_launch = netra_module._BRIDGE.launch

    def counted_launch(**kwargs) -> None:
        launch_counter[0] += 1
        original_launch(**kwargs)

    netra_module._BRIDGE.launch = counted_launch
    candidate_output = call(candidate_intermediate)
    torch.cuda.synchronize()
    if launch_counter[0] != 1:
        raise RuntimeError(
            f"candidate wrapper dispatched raw bridge {launch_counter[0]} times, "
            "expected exactly once"
        )
    candidate_final = candidate_intermediate[
        intermediate_index, 15
    ].unsqueeze(0)

    comparisons = {
        "control_output_vs_export": compare_bf16(
            control_output, expected_output
        ),
        "control_final_vs_export": compare_bf16(
            control_final, expected_final
        ),
        "candidate_output_vs_export": compare_bf16(
            candidate_output, expected_output
        ),
        "candidate_final_vs_export": compare_bf16(
            candidate_final, expected_final
        ),
        "candidate_output_vs_control": compare_bf16(
            candidate_output, control_output
        ),
        "candidate_final_vs_control": compare_bf16(
            candidate_final, control_final
        ),
    }
    if not all(item["preregistered_pass"] for item in comparisons.values()):
        raise RuntimeError(
            "one or more wrapper comparisons failed preregistered BF16 gates: "
            + json.dumps(comparisons, sort_keys=True)
        )

    os.environ[ENABLE_ENV] = "0"
    control_timing_intermediate = new_intermediate_pool()
    control_timing = measure(
        lambda: call(control_timing_intermediate),
        args.warmup,
        args.iterations,
    )
    os.environ[ENABLE_ENV] = "1"
    candidate_timing_intermediate = new_intermediate_pool()
    candidate_timing = measure(
        lambda: call(candidate_timing_intermediate),
        args.warmup,
        args.iterations,
    )

    graph_intermediate = new_intermediate_pool()
    warmup_stream = torch.cuda.Stream()
    with torch.cuda.stream(warmup_stream):
        graph_warmup_output = call(graph_intermediate)
    warmup_stream.synchronize()
    del graph_warmup_output
    launches_before_capture = launch_counter[0]
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        graph_output = call(graph_intermediate)
    launches_after_capture = launch_counter[0]
    if launches_after_capture != launches_before_capture + 1:
        raise RuntimeError("raw bridge was not invoked exactly once during capture")
    for _ in range(20):
        graph.replay()
    torch.cuda.synchronize()
    if launch_counter[0] != launches_after_capture:
        raise RuntimeError("graph replay unexpectedly returned to Python dispatch")
    graph_final = graph_intermediate[intermediate_index, 15].unsqueeze(0)
    graph_output_comparison = compare_bf16(graph_output, candidate_output)
    graph_final_comparison = compare_bf16(graph_final, candidate_final)
    if not graph_output_comparison["bit_exact"]:
        raise RuntimeError("graph output is not bit-exact with eager candidate")
    if not graph_final_comparison["bit_exact"]:
        raise RuntimeError("graph final state is not bit-exact with eager candidate")

    result = {
        "measurement_status": "measured",
        "accelerator": properties.name,
        "architecture": architecture,
        "torch": torch.__version__,
        "hip": torch.version.hip,
        "weight_quantization": "FP8 E4M3 128x128 blocks",
        "operation": "Qwen3.6 dFlash GDN M=16 SGLang wrapper dispatch",
        "shape": {
            "batch": 1,
            "tokens": 16,
            "q_heads": 16,
            "kv_heads": 32,
            "k": 128,
            "v": 128,
        },
        "state_indices": {
            "initial": initial_index,
            "intermediate": intermediate_index,
        },
        "raw_bridge_dispatches_observed": launch_counter[0],
        "comparisons": comparisons,
        "control_timing": control_timing,
        "candidate_timing": candidate_timing,
        "candidate_over_control_speedup": (
            control_timing["median_us"] / candidate_timing["median_us"]
        ),
        "graph": {
            "replays": 20,
            "python_dispatches_during_replay": 0,
            "output_vs_eager": graph_output_comparison,
            "final_state_vs_eager": graph_final_comparison,
        },
        "tolerances": {
            "bf16_atol": BF16_ATOL,
            "bf16_rtol": BF16_RTOL,
            "relative_floor": BF16_RELATIVE_FLOOR,
            "minimum_cosine": BF16_MINIMUM_COSINE,
            "source": "preregistered before raw candidate inspection",
        },
    }
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
