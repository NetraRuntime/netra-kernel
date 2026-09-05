#!/usr/bin/env python3
"""Measure a split normalization/gating + recurrent-core GDN design oracle.

This Triton implementation is not a claimed gfx950 compute replacement.  It
tests the ABI and arithmetic decomposition intended for hand-written AMDGCN:
compute Q/K normalization and scalar gates once, then reuse them across all
eight V tiles for each verification head.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import time
from pathlib import Path

import torch
import triton
import triton.language as tl

from qwen36_gdn_verify_triton_variants import compare, read_tensor


@triton.jit
def precompute_qk_and_gates_kernel(
    A_log,
    a,
    dt_bias,
    q,
    k,
    b,
    q_normalized,
    k_normalized,
    decay,
    beta,
    H: tl.constexpr,
    HV: tl.constexpr,
    K: tl.constexpr,
    USE_APPROX_RSQRT: tl.constexpr,
):
    i_t = tl.program_id(0)
    i_h = tl.program_id(1)
    o_k = tl.arange(0, K)
    q_offset = (i_t * H + i_h) * K + o_k
    b_q = tl.load(q + q_offset).to(tl.float32)
    b_k = tl.load(k + q_offset).to(tl.float32)
    q_norm_squared = tl.sum(b_q * b_q) + 1e-6
    k_norm_squared = tl.sum(b_k * b_k) + 1e-6
    if USE_APPROX_RSQRT:
        b_q *= tl.rsqrt(q_norm_squared)
        b_k *= tl.rsqrt(k_norm_squared)
    else:
        b_q = b_q / tl.sqrt(q_norm_squared)
        b_k = b_k / tl.sqrt(k_norm_squared)
    tl.store(q_normalized + q_offset, b_q * (K**-0.5))
    tl.store(k_normalized + q_offset, b_k)

    for hv_offset in tl.static_range(0, 2):
        i_hv = i_h * 2 + hv_offset
        gate_offset = i_t * HV + i_hv
        b_a = tl.load(a + gate_offset).to(tl.float32)
        b_dt_bias = tl.load(dt_bias + i_hv).to(tl.float32)
        b_A_log = tl.load(A_log + i_hv)
        x = b_a + b_dt_bias
        softplus_x = tl.where(
            x <= 20.0,
            tl.log(1.0 + tl.exp(x)),
            x,
        )
        b_g = -tl.exp(b_A_log) * softplus_x
        b_b = tl.load(b + gate_offset).to(tl.float32)
        tl.store(decay + gate_offset, tl.exp(b_g))
        tl.store(beta + gate_offset, 1.0 / (1.0 + tl.exp(-b_b)))


@triton.jit
def precomputed_recurrent_core_kernel(
    q_normalized,
    k_normalized,
    v,
    decay,
    beta,
    output,
    initial_ssm,
    intermediate,
    H: tl.constexpr,
    HV: tl.constexpr,
    K: tl.constexpr,
    V: tl.constexpr,
    T: tl.constexpr,
    BV: tl.constexpr,
):
    i_v = tl.program_id(1)
    i_hv = tl.program_id(2)
    i_h = i_hv // (HV // H)
    o_k = tl.arange(0, K)
    o_v = i_v * BV + tl.arange(0, BV)
    mask_v = o_v < V
    state_offset = (
        i_hv * K * V
        + o_v[None, :] * K
        + o_k[:, None]
    )
    b_h = tl.load(
        initial_ssm + state_offset,
        mask=mask_v[None, :],
        other=0,
    ).to(tl.float32)

    for i_t in tl.static_range(0, T):
        qk_offset = (i_t * H + i_h) * K + o_k
        v_offset = (i_t * HV + i_hv) * V + o_v
        gate_offset = i_t * HV + i_hv
        b_q = tl.load(q_normalized + qk_offset)
        b_k = tl.load(k_normalized + qk_offset)
        b_v = tl.load(v + v_offset, mask=mask_v, other=0).to(tl.float32)
        b_decay = tl.load(decay + gate_offset)
        b_beta = tl.load(beta + gate_offset)

        b_h *= b_decay
        b_v -= tl.sum(b_h * b_k[:, None], 0)
        b_v *= b_beta
        b_h += b_k[:, None] * b_v[None, :]
        b_o = tl.sum(b_h * b_q[:, None], 0)
        tl.store(
            output + v_offset,
            b_o.to(output.dtype.element_ty),
            mask=mask_v,
        )
        intermediate_offset = (
            (i_t * HV + i_hv) * V * K
            + o_v[None, :] * K
            + o_k[:, None]
        )
        tl.store(
            intermediate + intermediate_offset,
            b_h.to(intermediate.dtype.element_ty),
            mask=mask_v[None, :],
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=500)
    parser.add_argument("--correctness-iterations", type=int, default=20)
    parser.add_argument("--block-v", type=int, default=16)
    parser.add_argument(
        "--precompute-num-warps",
        type=int,
        choices=(1, 2, 4, 8),
        default=1,
    )
    parser.add_argument("--core-num-warps", type=int, default=1)
    parser.add_argument(
        "--precompute-normalization",
        choices=("div", "rsqrt"),
        default="div",
    )
    parser.add_argument(
        "--export-precomputed-dir",
        type=Path,
        help="Export the four FP32 split-core inputs after validation",
    )
    return parser.parse_args()


def sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(
        tensor.detach()
        .cpu()
        .contiguous()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    ).hexdigest()


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


def measure(
    iterations: int,
    launch,
) -> tuple[dict[str, float | int], list[float]]:
    pairs = [
        (
            torch.cuda.Event(enable_timing=True),
            torch.cuda.Event(enable_timing=True),
        )
        for _ in range(iterations)
    ]
    for start, stop in pairs:
        start.record()
        launch()
        stop.record()
    pairs[-1][1].synchronize()
    samples = [
        float(start.elapsed_time(stop)) * 1000.0 for start, stop in pairs
    ]
    return distribution(samples), samples


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(f"refusing to overwrite {args.output}")
    if args.iterations <= 0 or args.correctness_iterations <= 0:
        raise ValueError("iteration counts must be positive")
    if args.block_v not in {8, 16, 32}:
        raise ValueError("--block-v must be one of 8,16,32")
    if args.core_num_warps not in {1, 2, 4, 8}:
        raise ValueError("--core-num-warps must be one of 1,2,4,8")

    manifest = json.loads(
        (args.capture_dir / "manifest.json").read_text(encoding="utf-8")
    )
    if manifest.get("architecture") != "gfx950":
        raise ValueError("capture is not labeled gfx950")
    if not torch.cuda.is_available():
        raise RuntimeError("ROCm torch device is unavailable")
    device = torch.device("cuda", 0)
    architecture = str(
        getattr(torch.cuda.get_device_properties(device), "gcnArchName", "")
    )
    if not architecture.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    q = read_tensor(
        args.capture_dir, "q_bf16", (1, 16, 16, 128), torch.bfloat16, device
    ).squeeze(0)
    k = read_tensor(
        args.capture_dir, "k_bf16", (1, 16, 16, 128), torch.bfloat16, device
    ).squeeze(0)
    v = read_tensor(
        args.capture_dir, "v_bf16", (1, 16, 32, 128), torch.bfloat16, device
    ).squeeze(0)
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
    ).squeeze(0)
    expected_output = read_tensor(
        args.capture_dir,
        "expected_output_bf16",
        (1, 16, 32, 128),
        torch.bfloat16,
        device,
    ).squeeze(0)
    expected_final = read_tensor(
        args.capture_dir,
        "expected_final_ssm_bf16",
        (1, 32, 128, 128),
        torch.bfloat16,
        device,
    ).squeeze(0)

    q_normalized = torch.empty_like(q, dtype=torch.float32)
    k_normalized = torch.empty_like(k, dtype=torch.float32)
    decay = torch.empty((16, 32), dtype=torch.float32, device=device)
    beta = torch.empty((16, 32), dtype=torch.float32, device=device)
    output = torch.empty((16, 32, 128), dtype=torch.bfloat16, device=device)
    intermediate = torch.empty(
        (16, 32, 128, 128), dtype=torch.bfloat16, device=device
    )

    def launch_precompute() -> None:
        precompute_qk_and_gates_kernel[(16, 16)](
            A_log,
            a,
            dt_bias,
            q,
            k,
            b,
            q_normalized,
            k_normalized,
            decay,
            beta,
            H=16,
            HV=32,
            K=128,
            USE_APPROX_RSQRT=args.precompute_normalization == "rsqrt",
            num_warps=args.precompute_num_warps,
            num_stages=2,
        )

    def launch_core() -> None:
        precomputed_recurrent_core_kernel[(1, 128 // args.block_v, 32)](
            q_normalized,
            k_normalized,
            v,
            decay,
            beta,
            output,
            initial_ssm,
            intermediate,
            H=16,
            HV=32,
            K=128,
            V=128,
            T=16,
            BV=args.block_v,
            num_warps=args.core_num_warps,
            num_stages=2,
        )

    def launch_combined() -> None:
        launch_precompute()
        launch_core()

    compile_start = time.perf_counter_ns()
    launch_combined()
    torch.cuda.synchronize()
    compile_end = time.perf_counter_ns()
    for _ in range(20):
        launch_combined()
    torch.cuda.synchronize()

    first_output_hash = ""
    first_final_hash = ""
    nondeterministic_iterations = 0
    for index in range(args.correctness_iterations):
        launch_combined()
        torch.cuda.synchronize()
        output_hash = sha256(output)
        final_hash = sha256(intermediate[15])
        if index == 0:
            first_output_hash = output_hash
            first_final_hash = final_hash
        elif output_hash != first_output_hash or final_hash != first_final_hash:
            nondeterministic_iterations += 1

    output_comparison = compare(output, expected_output)
    state_comparison = compare(intermediate[15], expected_final)
    correctness_pass = bool(
        not nondeterministic_iterations
        and output_comparison["preregistered_pass"]
        and state_comparison["preregistered_pass"]
    )
    result: dict[str, object] = {
        "measurement_status": (
            "measured" if correctness_pass else "correctness_failed_before_timing"
        ),
        "accelerator": "AMD Instinct MI350X",
        "architecture": architecture,
        "implementation": "Triton split design oracle; not final compute",
        "capture_manifest": str(args.capture_dir / "manifest.json"),
        "config": {
            "precompute_grid": [16, 16],
            "core_grid": [1, 128 // args.block_v, 32],
            "block_v": args.block_v,
            "precompute_num_warps": args.precompute_num_warps,
            "core_num_warps": args.core_num_warps,
            "precompute_normalization": args.precompute_normalization,
        },
        "compile_and_first_launch_seconds": (compile_end - compile_start) / 1e9,
        "correctness_iterations": args.correctness_iterations,
        "nondeterministic_iterations": nondeterministic_iterations,
        "output_comparison": output_comparison,
        "final_state_comparison": state_comparison,
    }
    if correctness_pass:
        precompute_duration, precompute_samples = measure(
            args.iterations, launch_precompute
        )
        core_duration, core_samples = measure(args.iterations, launch_core)
        combined_duration, combined_samples = measure(
            args.iterations, launch_combined
        )
        result.update(
            {
                "timing": "HIP events; continuously queued by phase",
                "iterations": args.iterations,
                "precompute_duration": precompute_duration,
                "core_duration": core_duration,
                "combined_duration": combined_duration,
                "precompute_samples_us": precompute_samples,
                "core_samples_us": core_samples,
                "combined_samples_us": combined_samples,
            }
        )
        if args.export_precomputed_dir is not None:
            if args.export_precomputed_dir.exists():
                raise FileExistsError(
                    "refusing to overwrite "
                    f"{args.export_precomputed_dir}"
                )
            args.export_precomputed_dir.mkdir(parents=True)
            exports = {
                "q_normalized_f32": q_normalized,
                "k_normalized_f32": k_normalized,
                "decay_f32": decay,
                "beta_f32": beta,
                "oracle_output_bf16": output,
                "oracle_intermediate_bf16": intermediate,
            }
            export_manifest: dict[str, object] = {
                "architecture": architecture,
                "source_capture_manifest": str(
                    args.capture_dir / "manifest.json"
                ),
                "implementation": (
                    "Triton split design oracle; inputs for raw AMDGCN "
                    "core development only"
                ),
                "precompute_normalization": args.precompute_normalization,
                "files": {},
            }
            for name, tensor in exports.items():
                host = tensor.detach().cpu().contiguous()
                path = args.export_precomputed_dir / f"{name}.bin"
                path.write_bytes(host.view(torch.uint8).numpy().tobytes())
                export_manifest["files"][path.name] = {
                    "shape": list(host.shape),
                    "dtype": str(host.dtype),
                    "bytes": path.stat().st_size,
                    "sha256": sha256(host),
                }
            (args.export_precomputed_dir / "manifest.json").write_text(
                json.dumps(export_manifest, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            result["precomputed_export_manifest"] = str(
                args.export_precomputed_dir / "manifest.json"
            )
    else:
        result["timing"] = "not run"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2, sort_keys=True))
    if not correctness_pass:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
