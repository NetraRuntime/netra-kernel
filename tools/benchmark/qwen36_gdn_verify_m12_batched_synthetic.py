#!/usr/bin/env python3
"""Exact synthetic gate for the raw gfx950 batched Qwen GDN M=12 pipeline."""

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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--batch-size", type=int, default=63)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--triton-block-v", type=int, choices=(16, 32), default=32)
    parser.add_argument("--hip-graph", action="store_true")
    parser.add_argument("--k0-no-intermediate", action="store_true")
    parser.add_argument(
        "--packed-projection-layout",
        action="store_true",
        help="Use the real SGLang graph Q/K/V views with token stride 8192",
    )
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def distribution(values: list[float]) -> dict[str, float | int]:
    ordered = sorted(values)
    return {
        "count": len(ordered),
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, (9 * len(ordered) + 9) // 10 - 1)],
        "maximum_us": ordered[-1],
    }


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    actual_cpu = actual.detach().cpu()
    expected_cpu = expected.detach().cpu()
    delta = (actual_cpu.float() - expected_cpu.float()).abs()
    return {
        "bit_exact": bool(torch.equal(actual_cpu, expected_cpu)),
        "mismatch_count": int((actual_cpu != expected_cpu).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
    }


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def main() -> None:
    args = parse_args()
    if args.batch_size <= 0:
        raise ValueError("--batch-size must be positive")
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")
    if args.output.exists():
        raise FileExistsError(args.output)
    if not torch.cuda.is_available():
        raise RuntimeError("ROCm device unavailable")
    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    torch.manual_seed(20260801)
    batch, tokens, q_heads, value_heads, width = (
        args.batch_size,
        12,
        16,
        32,
        128,
    )
    rand = lambda *shape, scale=1.0: (
        torch.randn(*shape, dtype=torch.float32, device=device) * scale
    ).to(torch.bfloat16)
    if args.packed_projection_layout:
        packed_qkv = rand(
            1, batch * tokens, q_heads + q_heads + value_heads, width,
            scale=0.25,
        )
        q = packed_qkv[:, :, :q_heads]
        k = packed_qkv[:, :, q_heads : 2 * q_heads]
        v = packed_qkv[:, :, 2 * q_heads :].mul_(0.5)
    else:
        q = rand(batch, tokens, q_heads, width, scale=0.25)
        k = rand(batch, tokens, q_heads, width, scale=0.25)
        v = rand(batch, tokens, value_heads, width, scale=0.125)
    a = rand(batch * tokens, value_heads, scale=0.5)
    b = rand(batch * tokens, value_heads, scale=0.5)
    A_log = (-2.0 + torch.randn(value_heads, device=device) * 0.125).float()
    dt_bias = rand(value_heads, scale=0.25)
    initial = rand(batch, value_heads, width, width, scale=0.015625)
    indices = torch.arange(batch, dtype=torch.int32, device=device)
    cu_seqlens = torch.arange(
        0, (batch + 1) * tokens, tokens, dtype=torch.int32, device=device
    )
    intermediate_indices = indices.clone()
    triton_intermediate = torch.empty(
        batch, tokens, value_heads, width, width,
        dtype=torch.bfloat16,
        device=device,
    )
    raw_intermediate = torch.empty_like(triton_intermediate)
    triton_output = torch.empty(
        (1, *v.shape), dtype=torch.bfloat16, device=device
    )

    def run_triton() -> torch.Tensor:
        grid = (1, width // args.triton_block_v, batch * value_heads)
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
            o=triton_output,
            h0_source=initial,
            h0_indices=indices,
            h0_output_indices=indices,
            cu_seqlens=cu_seqlens,
            intermediate_states_buffer=(
                None if args.k0_no_intermediate else triton_intermediate
            ),
            intermediate_state_indices=(
                None if args.k0_no_intermediate else intermediate_indices
            ),
            cache_steps=0 if args.k0_no_intermediate else tokens,
            retrieve_parent_token_ptr=None,
            input_token_indices=None,
            input_sequence_indices=None,
            input_sequence_lengths=None,
            input_token_start=0,
            input_token_stride=0,
            stride_retrieve_parent_token_seq=0,
            stride_retrieve_parent_token_token=0,
            scale=width**-0.5,
            T=tokens,
            stride_a=a.stride(-2),
            stride_q=q.stride(1),
            stride_k=k.stride(1),
            stride_v=v.stride(1),
            stride_b=b.stride(-2),
            NP2_T=16,
            B=batch,
            H=q_heads,
            HV=value_heads,
            K=width,
            V=width,
            BK=width,
            BV=args.triton_block_v,
            USE_INITIAL_STATE=True,
            USE_QK_L2NORM_IN_KERNEL=True,
            IS_VARLEN=True,
            IS_KDA=False,
            DISABLE_STATE_UPDATE=True,
            DISABLE_OUTPUT_CALCULATION=False,
            CACHE_INTERMEDIATE_STATES=not args.k0_no_intermediate,
            HAS_EAGLE_TREE_CUSTOM_ATTN_MASK=False,
            HAS_INPUT_TOKEN_INDICES=False,
            HAS_INPUT_SEQUENCE_INDICES=False,
            HAS_INPUT_SEQUENCE_LENGTHS=False,
            USE_APPROX_RSQRT=False,
            num_warps=1,
            num_stages=3,
        )
        return triton_output.squeeze(0)

    bridge = ctypes.CDLL(
        str(args.build_dir / "libqwen36_gdn_verify_m12_batched_bridge.so")
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    bridge.netra_qwen36_gdn_verify_m12_batched_load.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_verify_m12_batched_load_wavegroup_variants.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    bridge.netra_qwen36_gdn_verify_m12_batched_load_wavegroup_variants.restype = (
        ctypes.c_int
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_launch.argtypes = (
        [ctypes.c_void_p] * 16
        + [ctypes.c_uint32] * 7
        + [ctypes.c_void_p]
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_launch.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_verify_m12_batched_last_error.restype = ctypes.c_char_p

    precompute_path = args.build_dir / "qwen36_gdn_verify_m12_batched_precompute_gfx950.hsaco"
    core_path = args.build_dir / "qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950.hsaco"
    core_waves4_path = args.build_dir / "qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950_waves4.hsaco"
    core_waves8_path = args.build_dir / "qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950_waves8.hsaco"
    wavegroup_variants = core_waves4_path.is_file() and core_waves8_path.is_file()
    if wavegroup_variants:
        status = bridge.netra_qwen36_gdn_verify_m12_batched_load_wavegroup_variants(
            str(precompute_path).encode(),
            str(core_path).encode(),
            str(core_waves4_path).encode(),
            str(core_waves8_path).encode(),
        )
    else:
        status = bridge.netra_qwen36_gdn_verify_m12_batched_load(
            str(precompute_path).encode(), str(core_path).encode()
        )
    if status:
        raise RuntimeError(bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode())

    raw_output = torch.empty(tuple(v.shape), dtype=torch.bfloat16, device=device)
    q_normalized = torch.empty(tuple(q.shape), dtype=torch.float32, device=device)
    k_normalized = torch.empty_like(q_normalized)
    decay = torch.empty(batch, tokens, value_heads, dtype=torch.float32, device=device)
    beta = torch.empty_like(decay)

    def run_raw() -> torch.Tensor:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_verify_m12_batched_launch(
            pointer(raw_output), pointer(A_log), pointer(a), pointer(dt_bias),
            pointer(q), pointer(k), pointer(v), pointer(b), pointer(initial),
            pointer(indices), pointer(raw_intermediate),
            pointer(intermediate_indices), pointer(q_normalized),
            pointer(k_normalized), pointer(decay), pointer(beta),
            q.stride(1), k.stride(1), v.stride(1), a.stride(-2), b.stride(-2),
            batch, initial.shape[0], ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
            )
        return raw_output

    expected = run_triton()
    actual = run_raw()
    torch.cuda.synchronize(device)
    output_comparison = compare(actual, expected)
    state_comparison = (
        None
        if args.k0_no_intermediate
        else compare(raw_intermediate, triton_intermediate)
    )
    graph_comparison = None
    if args.hip_graph:
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            run_raw()
        graph.replay()
        torch.cuda.synchronize(device)
        graph_comparison = {"output": compare(raw_output, expected)}
        if not args.k0_no_intermediate:
            graph_comparison["intermediate_state"] = compare(
                raw_intermediate, triton_intermediate
            )

    for _ in range(5):
        run_triton()
        run_raw()
    torch.cuda.synchronize(device)

    timings: dict[str, dict[str, float | int]] = {}
    for name, function in (("triton", run_triton), ("raw", run_raw)):
        elapsed: list[float] = []
        for _ in range(args.iterations):
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            function()
            end.record()
            end.synchronize()
            elapsed.append(float(start.elapsed_time(end) * 1000.0))
        timings[name] = distribution(elapsed)

    result = {
        "accelerator": "AMD Instinct MI350X",
        "architecture": architecture,
        "shape": {
            "batch": batch,
            "tokens": tokens,
            "q_heads": q_heads,
            "value_heads": value_heads,
            "k": width,
            "v": width,
            "triton_block_v": args.triton_block_v,
        },
        "weight_quantization": "Qwen FP8 E4M3 128x128 blocks (unchanged)",
        "synthetic_input": True,
        "packed_projection_layout": args.packed_projection_layout,
        "k0_no_intermediate": args.k0_no_intermediate,
        "wavegroup_variants": wavegroup_variants,
        "output": output_comparison,
        "intermediate_state": state_comparison,
        "hip_graph": graph_comparison,
        "timing": timings,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    graph_exact = graph_comparison is None or all(
        value["bit_exact"] for value in graph_comparison.values()
    )
    if (
        not output_comparison["bit_exact"]
        or (state_comparison is not None and not state_comparison["bit_exact"])
        or not graph_exact
    ):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
