#!/usr/bin/env python3
"""Correctness and latency gate for the experimental Qwen3.6-27B GDN kernel."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch

from sglang.srt.layers.attention.fla.fused_sigmoid_gating_recurrent import (
    fused_sigmoid_gating_delta_rule_update_kernel,
)
from sglang.srt.layers.attention.linear.netra_gfx950_qwen36_gdn_verify_m12_batched import (
    _gdn_hv48_gate_precompute_kernel,
)
import triton


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    delta = (actual.float() - expected.float()).abs()
    mismatch_indices = torch.nonzero(
        actual.reshape(-1) != expected.reshape(-1), as_tuple=False
    ).reshape(-1)[:16]
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "elements": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
        "first_mismatch_flat_indices": mismatch_indices.tolist(),
        "first_mismatch_actual": actual.reshape(-1)[mismatch_indices].float().tolist(),
        "first_mismatch_expected": expected.reshape(-1)[
            mismatch_indices
        ].float().tolist(),
    }


def stats(tensor: torch.Tensor) -> dict[str, float | int]:
    value = tensor.float()
    finite = torch.isfinite(value)
    return {
        "finite": int(finite.sum().item()),
        "elements": value.numel(),
        "minimum": float(value[finite].min().item()) if finite.any() else float("nan"),
        "maximum": float(value[finite].max().item()) if finite.any() else float("nan"),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--batch", type=int, choices=(1, 128), required=True)
    parser.add_argument("--iterations", type=int, default=20)
    parser.add_argument("--precompute-name", default="precompute.hsaco")
    parser.add_argument("--core-name", default="core.hsaco")
    args = parser.parse_args()

    device = torch.device("cuda", 0)
    if not str(torch.cuda.get_device_properties(device).gcnArchName).startswith(
        "gfx950"
    ):
        raise RuntimeError("this gate requires gfx950")

    torch.manual_seed(20260818 + args.batch)
    batch = args.batch
    steps = 12
    total_tokens = batch * steps
    heads = 16
    value_heads = 48
    width = 128

    def bf16(*shape: int, scale: float = 1.0) -> torch.Tensor:
        return (torch.randn(shape, device=device) * scale).to(torch.bfloat16)

    A_log = (torch.randn(value_heads, device=device) * 0.5 - 3.0).float()
    a = bf16(total_tokens, value_heads, scale=0.5)
    dt_bias = bf16(value_heads, scale=0.5)
    q = bf16(1, total_tokens, heads, width, scale=0.1)
    k = bf16(1, total_tokens, heads, width, scale=0.1)
    v = bf16(1, total_tokens, value_heads, width, scale=0.1)
    b = bf16(total_tokens, value_heads, scale=0.5)
    initial = torch.randn(
        (batch, value_heads, width, width), device=device
    ).float() * 0.01
    indices = torch.arange(batch, dtype=torch.int32, device=device)
    cu_seqlens = torch.arange(
        0, total_tokens + 1, steps, dtype=torch.int32, device=device
    )

    triton_output = torch.empty_like(v)

    def run_triton() -> None:
        fused_sigmoid_gating_delta_rule_update_kernel[
            (1, 4, batch * value_heads)
        ](
            A_log=A_log,
            a=a,
            dt_bias=dt_bias,
            softplus_beta=1.0,
            softplus_threshold=20.0,
            q=q,
            k=k,
            v=v,
            b=b,
            o=triton_output,
            h0_source=initial,
            h0_indices=indices,
            h0_output_indices=indices,
            cu_seqlens=cu_seqlens,
            intermediate_states_buffer=None,
            intermediate_state_indices=None,
            cache_steps=0,
            retrieve_parent_token_ptr=None,
            input_token_indices=None,
            input_sequence_indices=None,
            input_sequence_lengths=None,
            input_token_start=0,
            input_token_stride=0,
            stride_retrieve_parent_token_seq=0,
            stride_retrieve_parent_token_token=0,
            scale=width**-0.5,
            T=total_tokens,
            stride_a=a.stride(-2),
            stride_q=q.stride(1),
            stride_k=k.stride(1),
            stride_v=v.stride(1),
            stride_b=b.stride(-2),
            NP2_T=2048,
            B=1,
            H=heads,
            HV=value_heads,
            K=width,
            V=width,
            BK=width,
            BV=32,
            USE_INITIAL_STATE=True,
            USE_QK_L2NORM_IN_KERNEL=True,
            IS_VARLEN=True,
            IS_KDA=False,
            DISABLE_STATE_UPDATE=True,
            DISABLE_OUTPUT_CALCULATION=False,
            CACHE_INTERMEDIATE_STATES=False,
            HAS_EAGLE_TREE_CUSTOM_ATTN_MASK=False,
            HAS_INPUT_TOKEN_INDICES=False,
            HAS_INPUT_SEQUENCE_INDICES=False,
            HAS_INPUT_SEQUENCE_LENGTHS=False,
            USE_APPROX_RSQRT=False,
            num_warps=1,
            num_stages=3,
        )

    bridge = ctypes.CDLL(
        str(args.build_dir / "libqwen36_27b_gdn_verify_m12_batched_bridge.so")
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    bridge.netra_qwen36_gdn_verify_m12_batched_load.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_verify_m12_batched_launch.argtypes = (
        [ctypes.c_void_p] * 16
        + [ctypes.c_uint32] * 7
        + [ctypes.c_void_p]
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_launch.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_verify_m12_batched_launch_precomputed.argtypes = (
        [ctypes.c_void_p] * 10
        + [ctypes.c_uint32] * 3
        + [ctypes.c_void_p]
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_launch_precomputed.restype = (
        ctypes.c_int
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_launch_precompute.argtypes = (
        [ctypes.c_void_p] * 10
        + [ctypes.c_uint32] * 5
        + [ctypes.c_void_p]
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_launch_precompute.restype = (
        ctypes.c_int
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_last_error.restype = ctypes.c_char_p
    status = bridge.netra_qwen36_gdn_verify_m12_batched_load(
        str(args.build_dir / args.precompute_name).encode(),
        str(args.build_dir / args.core_name).encode(),
    )
    if status:
        raise RuntimeError(
            bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
        )

    raw_output = torch.empty_like(v)
    dummy_intermediate = torch.empty(1, dtype=torch.bfloat16, device=device)
    q_normalized = torch.empty_like(q, dtype=torch.float32)
    k_normalized = torch.empty_like(k, dtype=torch.float32)
    decay = torch.empty(
        (total_tokens, value_heads), dtype=torch.float32, device=device
    )
    beta = torch.empty_like(decay)

    def run_raw() -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_verify_m12_batched_launch(
            pointer(raw_output),
            pointer(A_log),
            pointer(a),
            pointer(dt_bias),
            pointer(q),
            pointer(k),
            pointer(v),
            pointer(b),
            pointer(initial),
            pointer(indices),
            pointer(dummy_intermediate),
            pointer(indices),
            pointer(q_normalized),
            pointer(k_normalized),
            pointer(decay),
            pointer(beta),
            q.stride(1),
            k.stride(1),
            v.stride(1),
            a.stride(-2),
            b.stride(-2),
            batch,
            initial.shape[0],
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
            )

    run_triton()
    run_raw()
    torch.cuda.synchronize(device)
    raw_correctness = compare(raw_output, triton_output)
    q_reference = (
        q.float()
        / torch.sqrt(torch.sum(q.float() * q.float(), dim=-1, keepdim=True) + 1e-6)
        * (width**-0.5)
    )
    k_reference = k.float() / torch.sqrt(
        torch.sum(k.float() * k.float(), dim=-1, keepdim=True) + 1e-6
    )
    gate_x = a.float() + dt_bias.float()
    decay_reference = torch.exp(
        -torch.exp(A_log.float()) * torch.nn.functional.softplus(gate_x)
    )
    beta_reference = torch.sigmoid(b.float())
    precomputed_output = torch.empty_like(v)

    def run_precomputed() -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_verify_m12_batched_launch_precomputed(
            pointer(q_reference),
            pointer(k_reference),
            pointer(v),
            pointer(decay_reference),
            pointer(beta_reference),
            pointer(precomputed_output),
            pointer(initial),
            pointer(dummy_intermediate),
            pointer(indices),
            pointer(indices),
            v.stride(1),
            batch,
            initial.shape[0],
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
            )

    run_precomputed()
    torch.cuda.synchronize(device)
    hybrid_output = torch.empty_like(v)

    def run_hybrid() -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_verify_m12_batched_launch_precompute(
            pointer(A_log),
            pointer(a),
            pointer(dt_bias),
            pointer(q),
            pointer(k),
            pointer(b),
            pointer(q_normalized),
            pointer(k_normalized),
            pointer(decay),
            pointer(beta),
            q.stride(1),
            k.stride(1),
            a.stride(-2),
            b.stride(-2),
            batch,
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
            )
        total_elements = total_tokens * value_heads
        _gdn_hv48_gate_precompute_kernel[
            (triton.cdiv(total_elements, 256),)
        ](
            A_log,
            a,
            dt_bias,
            b,
            decay,
            beta,
            total_elements=total_elements,
            BLOCK=256,
            num_warps=4,
        )
        status = bridge.netra_qwen36_gdn_verify_m12_batched_launch_precomputed(
            pointer(q_normalized),
            pointer(k_normalized),
            pointer(v),
            pointer(decay),
            pointer(beta),
            pointer(hybrid_output),
            pointer(initial),
            pointer(dummy_intermediate),
            pointer(indices),
            pointer(indices),
            v.stride(1),
            batch,
            initial.shape[0],
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
            )

    run_hybrid()
    torch.cuda.synchronize(device)
    correctness = compare(hybrid_output, triton_output)
    stages = {
        "q_normalized": compare(q_normalized, q_reference),
        "k_normalized": compare(k_normalized, k_reference),
        "decay": compare(decay, decay_reference),
        "beta": compare(beta, beta_reference),
        "raw_output_stats": stats(raw_output),
        "triton_output_stats": stats(triton_output),
        "precomputed_output_vs_triton": compare(
            precomputed_output, triton_output
        ),
        "precomputed_output_stats": stats(precomputed_output),
        "hybrid_output_vs_triton": compare(hybrid_output, triton_output),
        "hybrid_output_stats": stats(hybrid_output),
        "decay_first_six": decay[0, :6].tolist(),
        "decay_reference_first_six": decay_reference[0, :6].tolist(),
        "beta_first_six": beta[0, :6].tolist(),
        "beta_reference_first_six": beta_reference[0, :6].tolist(),
        "A_log_first_six": A_log[:6].tolist(),
        "a_first_six": a[0, :6].float().tolist(),
        "dt_bias_first_six": dt_bias[:6].float().tolist(),
        "b_first_six": b[0, :6].float().tolist(),
    }

    timings: dict[str, float] = {}
    for name, function in (
        ("triton", run_triton),
        ("hybrid", run_hybrid),
        ("raw_assembly", run_raw),
    ):
        for _ in range(3):
            function()
        torch.cuda.synchronize(device)
        elapsed = []
        for _ in range(args.iterations):
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            function()
            end.record()
            end.synchronize()
            elapsed.append(float(start.elapsed_time(end) * 1000.0))
        timings[f"{name}_median_us"] = statistics.median(elapsed)

    result = {
        "batch": batch,
        "correctness": correctness,
        "raw_assembly_correctness": raw_correctness,
        "stages": stages,
        "timing": timings,
        "median_speedup": timings["triton_median_us"]
        / timings["hybrid_median_us"],
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    if not correctness["bit_exact"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
