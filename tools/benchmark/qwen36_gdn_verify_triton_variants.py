#!/usr/bin/env python3
"""Benchmark the exact Qwen GDN M=16 verifier Triton ABI on gfx950."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import time
from pathlib import Path

import torch

from sglang.srt.layers.attention.fla.fused_sigmoid_gating_recurrent import (
    fused_sigmoid_gating_delta_rule_update_kernel,
)

GDN_ONE_STEP_ATOL = 0.03125
GDN_ONE_STEP_RTOL = 0.010
GDN_ONE_STEP_MIN_COSINE = 0.9995


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=200)
    parser.add_argument("--correctness-iterations", type=int, default=10)
    parser.add_argument("--num-warps", type=int, default=1)
    parser.add_argument("--num-stages", type=int, default=3)
    parser.add_argument("--block-v", type=int, default=32)
    parser.add_argument(
        "--normalization",
        choices=("div", "rsqrt"),
        default="div",
    )
    parser.add_argument(
        "--correctness-policy",
        choices=("exact", "preregistered"),
        default="exact",
        help=(
            "exact requires bit-identical output/state; preregistered permits "
            "deterministic results satisfying the campaign's predeclared "
            "one-step GDN BF16 tensor bounds"
        ),
    )
    return parser.parse_args()


def read_tensor(
    root: Path,
    name: str,
    shape: tuple[int, ...],
    dtype: torch.dtype,
    device: torch.device,
) -> torch.Tensor:
    data = (root / f"{name}.bin").read_bytes()
    element_size = torch.empty((), dtype=dtype).element_size()
    expected_bytes = math.prod(shape) * element_size
    if len(data) != expected_bytes:
        raise ValueError(
            f"{name}: got {len(data)} bytes, expected {expected_bytes}"
        )
    source = torch.frombuffer(bytearray(data), dtype=dtype).reshape(shape)
    return source.clone().to(device=device)


def sha256(tensor: torch.Tensor) -> str:
    data = (
        tensor.detach()
        .cpu()
        .contiguous()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    )
    return hashlib.sha256(data).hexdigest()


def compare(
    actual: torch.Tensor, expected: torch.Tensor
) -> dict[str, float | int | bool | str]:
    actual_cpu = actual.detach().cpu().contiguous()
    expected_cpu = expected.detach().cpu().contiguous()
    exact = torch.equal(actual_cpu, expected_cpu)
    mismatch_count = int((actual_cpu != expected_cpu).sum().item())
    actual_f32 = actual_cpu.float()
    expected_f32 = expected_cpu.float()
    delta = (actual_f32 - expected_f32).abs()
    finite = torch.isfinite(actual_f32) & torch.isfinite(expected_f32)
    relative_applicable = ~(
        (actual_f32.abs() < GDN_ONE_STEP_ATOL)
        & (expected_f32.abs() < GDN_ONE_STEP_ATOL)
    )
    relative = delta / expected_f32.abs().clamp_min(1e-6)
    applicable_relative = relative[relative_applicable]
    max_relative = (
        float(applicable_relative.max().item())
        if applicable_relative.numel()
        else 0.0
    )
    worst_flat_index = int(delta.flatten().argmax().item())
    denominator = (
        torch.linalg.vector_norm(actual_f32)
        * torch.linalg.vector_norm(expected_f32)
    )
    if denominator.item() == 0.0:
        cosine = 1.0 if exact else 0.0
    else:
        cosine = float(
            torch.dot(actual_f32.flatten(), expected_f32.flatten()).item()
            / denominator.item()
        )
    preregistered_pass = bool(
        finite.all().item()
        and float(delta.max().item()) <= GDN_ONE_STEP_ATOL
        and max_relative <= GDN_ONE_STEP_RTOL
        and cosine >= GDN_ONE_STEP_MIN_COSINE
    )
    return {
        "bit_exact": exact,
        "preregistered_pass": preregistered_pass,
        "mismatch_count": mismatch_count,
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "max_relative": max_relative,
        "mean_abs": float(delta.mean().item()),
        "rmse": float(torch.sqrt(torch.mean(delta * delta)).item()),
        "cosine": cosine,
        "actual_nonfinite_count": int((~torch.isfinite(actual_f32)).sum().item()),
        "expected_nonfinite_count": int(
            (~torch.isfinite(expected_f32)).sum().item()
        ),
        "worst_flat_index": worst_flat_index,
        "actual_sha256": sha256(actual_cpu),
        "expected_sha256": sha256(expected_cpu),
    }


def distribution(values: list[float]) -> dict[str, float | int]:
    ordered = sorted(values)
    p90_index = min(len(ordered) - 1, math.ceil(0.9 * len(ordered)) - 1)
    return {
        "count": len(ordered),
        "total_us": sum(ordered),
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[p90_index],
        "maximum_us": ordered[-1],
        "minimum_us": ordered[0],
    }


def main() -> None:
    args = parse_args()
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")
    if args.correctness_iterations <= 0:
        raise ValueError("--correctness-iterations must be positive")
    if args.num_warps not in {1, 2, 4, 8}:
        raise ValueError("--num-warps must be one of 1,2,4,8")
    if args.num_stages <= 0:
        raise ValueError("--num-stages must be positive")
    if args.block_v not in {8, 16, 32, 64, 128}:
        raise ValueError("--block-v must be one of 8,16,32,64,128")
    if args.output.exists():
        raise FileExistsError(f"refusing to overwrite {args.output}")
    manifest = json.loads(
        (args.capture_dir / "manifest.json").read_text(encoding="utf-8")
    )
    if manifest.get("architecture") != "gfx950":
        raise ValueError("capture is not labeled gfx950")

    if not torch.cuda.is_available():
        raise RuntimeError("ROCm torch device is unavailable")
    device = torch.device("cuda", 0)
    properties = torch.cuda.get_device_properties(device)
    architecture = getattr(properties, "gcnArchName", "")
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    q = read_tensor(
        args.capture_dir, "q_bf16", (1, 16, 16, 128), torch.bfloat16, device
    )
    k = read_tensor(
        args.capture_dir, "k_bf16", (1, 16, 16, 128), torch.bfloat16, device
    )
    v = read_tensor(
        args.capture_dir, "v_bf16", (1, 16, 32, 128), torch.bfloat16, device
    )
    a = read_tensor(
        args.capture_dir, "a_bf16", (16, 32), torch.bfloat16, device
    )
    b = read_tensor(
        args.capture_dir, "b_bf16", (16, 32), torch.bfloat16, device
    )
    A_log = read_tensor(
        args.capture_dir, "A_log_f32", (32,), torch.float32, device
    )
    dt_bias = read_tensor(
        args.capture_dir, "dt_bias_bf16", (32,), torch.bfloat16, device
    )
    initial_ssm = read_tensor(
        args.capture_dir,
        "initial_ssm_bf16",
        (1, 32, 128, 128),
        torch.bfloat16,
        device,
    )
    captured_cache_indices = read_tensor(
        args.capture_dir, "cache_indices_i32", (1,), torch.int32, device
    )
    # The capture exports the selected one-entry state tensor, while the live
    # request still names its original pool slot. Rebase that slot to entry zero
    # for the isolated one-entry replay. Passing the live pool index here would
    # address beyond ``initial_ssm``.
    cache_indices = torch.zeros_like(captured_cache_indices)
    query_start_loc = read_tensor(
        args.capture_dir,
        "query_start_loc_i32",
        (2,),
        torch.int32,
        device,
    )
    intermediate_indices = read_tensor(
        args.capture_dir,
        "intermediate_state_indices_i32",
        (1,),
        torch.int32,
        device,
    )
    expected_output = read_tensor(
        args.capture_dir,
        "expected_output_bf16",
        (1, 16, 32, 128),
        torch.bfloat16,
        device,
    )
    expected_final = read_tensor(
        args.capture_dir,
        "expected_final_ssm_bf16",
        (1, 32, 128, 128),
        torch.bfloat16,
        device,
    )

    output = torch.empty((1, 1, 16, 32, 128), dtype=torch.bfloat16, device=device)
    intermediate = torch.empty(
        (1, 16, 32, 128, 128), dtype=torch.bfloat16, device=device
    )
    def launch() -> None:
        grid = (1, 128 // args.block_v, 32)
        fused_sigmoid_gating_delta_rule_update_kernel[grid](
            A_log=A_log,
            a=a,
            dt_bias=dt_bias,
            softplus_beta=1.0,
            softplus_threshold=20.0,
            q=q,
            k=k,
            v=v,
            b=b,
            o=output,
            h0_source=initial_ssm,
            h0_indices=cache_indices,
            h0_output_indices=cache_indices,
            cu_seqlens=query_start_loc,
            intermediate_states_buffer=intermediate,
            intermediate_state_indices=intermediate_indices,
            cache_steps=16,
            retrieve_parent_token_ptr=None,
            input_token_indices=None,
            input_sequence_indices=None,
            input_sequence_lengths=None,
            input_token_start=0,
            input_token_stride=0,
            stride_retrieve_parent_token_seq=0,
            stride_retrieve_parent_token_token=0,
            scale=128**-0.5,
            T=16,
            stride_a=a.stride(-2),
            stride_q=q.stride(1),
            stride_k=k.stride(1),
            stride_v=v.stride(1),
            stride_b=b.stride(-2),
            NP2_T=16,
            B=1,
            H=16,
            HV=32,
            K=128,
            V=128,
            BK=128,
            BV=args.block_v,
            USE_INITIAL_STATE=True,
            USE_QK_L2NORM_IN_KERNEL=True,
            IS_VARLEN=True,
            IS_KDA=False,
            DISABLE_STATE_UPDATE=True,
            DISABLE_OUTPUT_CALCULATION=False,
            CACHE_INTERMEDIATE_STATES=True,
            HAS_EAGLE_TREE_CUSTOM_ATTN_MASK=False,
            HAS_INPUT_TOKEN_INDICES=False,
            HAS_INPUT_SEQUENCE_INDICES=False,
            HAS_INPUT_SEQUENCE_LENGTHS=False,
            USE_APPROX_RSQRT=args.normalization == "rsqrt",
            num_warps=args.num_warps,
            num_stages=args.num_stages,
        )

    compile_start = time.perf_counter_ns()
    launch()
    torch.cuda.synchronize()
    compile_end = time.perf_counter_ns()
    for _ in range(10):
        launch()
    torch.cuda.synchronize()

    first_output_hash = ""
    first_final_hash = ""
    nondeterministic_iterations = 0
    for index in range(args.correctness_iterations):
        launch()
        torch.cuda.synchronize()
        if index == 0:
            first_output_hash = sha256(output.squeeze(0))
            first_final_hash = sha256(intermediate[0, 15])
        elif (
            sha256(output.squeeze(0)) != first_output_hash
            or sha256(intermediate[0, 15]) != first_final_hash
        ):
            nondeterministic_iterations += 1

    output_comparison = compare(output.squeeze(0), expected_output)
    state_comparison = compare(intermediate[0, 15].unsqueeze(0), expected_final)
    required_comparison_key = (
        "bit_exact"
        if args.correctness_policy == "exact"
        else "preregistered_pass"
    )
    correctness_pass = bool(
        not nondeterministic_iterations
        and output_comparison[required_comparison_key]
        and state_comparison[required_comparison_key]
    )
    correctness_policy = {
        "name": args.correctness_policy,
        "required_comparison_key": required_comparison_key,
        "determinism_required": True,
        "preregistered_gdn_one_step_bf16": {
            "atol": GDN_ONE_STEP_ATOL,
            "rtol": GDN_ONE_STEP_RTOL,
            "minimum_cosine": GDN_ONE_STEP_MIN_COSINE,
            "relative_denominator_floor": 1e-6,
            "relative_bound_ignored_when_both_magnitudes_below_atol": True,
        },
    }
    if not correctness_pass:
        result = {
            "measurement_status": "correctness_failed_before_timing",
            "timing": "not run",
            "accelerator": "AMD Instinct MI350X",
            "architecture": str(architecture),
            "capture_manifest": str(args.capture_dir / "manifest.json"),
            "captured_state_pool_indices": captured_cache_indices.cpu().tolist(),
            "isolated_state_buffer_indices": cache_indices.cpu().tolist(),
            "kernel": "fused_sigmoid_gating_delta_rule_update_kernel",
            "config": {
                "grid": [1, 128 // args.block_v, 32],
                "block_v": args.block_v,
                "num_warps": args.num_warps,
                "num_stages": args.num_stages,
                "normalization": args.normalization,
            },
            "compile_and_first_launch_seconds": (compile_end - compile_start) / 1e9,
            "correctness_iterations": args.correctness_iterations,
            "nondeterministic_iterations": nondeterministic_iterations,
            "correctness_policy": correctness_policy,
            "output_comparison": output_comparison,
            "final_state_comparison": state_comparison,
        }
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(json.dumps(result, indent=2, sort_keys=True))
        raise SystemExit(1)

    event_pairs = [
        (
            torch.cuda.Event(enable_timing=True),
            torch.cuda.Event(enable_timing=True),
        )
        for _ in range(args.iterations)
    ]
    for start, stop in event_pairs:
        start.record()
        launch()
        stop.record()
    event_pairs[-1][1].synchronize()
    timings = [
        float(start.elapsed_time(stop)) * 1000.0
        for start, stop in event_pairs
    ]

    result = {
        "measurement_status": "measured",
        "timing": "HIP events",
        "accelerator": "AMD Instinct MI350X",
        "architecture": str(architecture),
        "capture_manifest": str(args.capture_dir / "manifest.json"),
        "captured_state_pool_indices": captured_cache_indices.cpu().tolist(),
        "isolated_state_buffer_indices": cache_indices.cpu().tolist(),
        "kernel": "fused_sigmoid_gating_delta_rule_update_kernel",
        "config": {
            "grid": [1, 128 // args.block_v, 32],
            "block_v": args.block_v,
            "num_warps": args.num_warps,
            "num_stages": args.num_stages,
            "normalization": args.normalization,
        },
        "compile_and_first_launch_seconds": (compile_end - compile_start) / 1e9,
        "correctness_iterations": args.correctness_iterations,
        "iterations": args.iterations,
        "nondeterministic_iterations": nondeterministic_iterations,
        "correctness_policy": correctness_policy,
        "duration": distribution(timings),
        "samples_us": timings,
        "output_comparison": output_comparison,
        "final_state_comparison": state_comparison,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2, sort_keys=True))
if __name__ == "__main__":
    main()
