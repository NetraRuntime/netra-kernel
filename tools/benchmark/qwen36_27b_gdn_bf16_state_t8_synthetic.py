#!/usr/bin/env python3
"""Correctness, graph, and latency gate for the exact BF16-state T8 GDN path."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path
from typing import Callable

import torch

from sglang.srt.layers.attention.fla.fused_sigmoid_gating_recurrent import (
    fused_sigmoid_gating_delta_rule_update,
)


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    actual_flat = actual.reshape(-1)
    expected_flat = expected.reshape(-1)
    mismatches = actual_flat != expected_flat
    delta = (actual_flat.float() - expected_flat.float()).abs()
    mismatch_indices = torch.nonzero(mismatches, as_tuple=False).reshape(-1)[:16]
    result: dict[str, object] = {
        "bit_exact": bool(torch.equal(actual_flat, expected_flat)),
        "mismatch_count": int(mismatches.sum().item()),
        "elements": actual_flat.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
        "first_mismatch_flat_indices": mismatch_indices.tolist(),
        "first_mismatch_actual": actual_flat[mismatch_indices].float().tolist(),
        "first_mismatch_expected": expected_flat[mismatch_indices].float().tolist(),
    }
    if actual.dtype == torch.bfloat16 and mismatch_indices.numel():
        ulp = (
            actual_flat.view(torch.int16).int()
            - expected_flat.view(torch.int16).int()
        ).abs()
        result["max_ulp_bf16"] = int(ulp.max().item())
    return result


def median_us(function: Callable[[], None], iterations: int) -> float:
    for _ in range(3):
        function()
    torch.cuda.synchronize()
    samples = []
    for _ in range(iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        function()
        end.record()
        end.synchronize()
        samples.append(float(start.elapsed_time(end) * 1000.0))
    return statistics.median(samples)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument(
        "--batch", type=int, choices=(1, 32, 128, 192, 256), required=True
    )
    parser.add_argument("--iterations", type=int, default=50)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    device = torch.device("cuda", 0)
    properties = torch.cuda.get_device_properties(device)
    if not str(properties.gcnArchName).startswith("gfx950"):
        raise RuntimeError(f"this gate requires gfx950, got {properties.gcnArchName}")

    torch.manual_seed(20260820 + args.batch)
    batch = args.batch
    tokens = 8
    total_tokens = batch * tokens
    key_heads = 16
    value_heads = 48
    width = 128
    state_capacity = batch

    def bf16(*shape: int, scale: float = 1.0) -> torch.Tensor:
        return (torch.randn(shape, device=device) * scale).to(torch.bfloat16)

    A_log = (torch.randn(value_heads, device=device) * 0.5 - 1.0).float()
    a = bf16(total_tokens, value_heads, scale=0.8)
    dt_bias = bf16(value_heads, scale=0.3)
    b = bf16(total_tokens, value_heads, scale=0.9)
    q = bf16(total_tokens, key_heads * width)
    k = bf16(total_tokens, key_heads * width)
    v_storage = bf16(total_tokens, 8192)
    v = v_storage[:, : value_heads * width]
    state_master = bf16(
        state_capacity, value_heads, width, width, scale=0.05
    )
    state_indices = torch.arange(batch, device=device, dtype=torch.int32)
    accept_lengths = torch.randint(
        0, tokens + 1, (batch,), device=device, dtype=torch.int32
    )
    accept_lengths[0] = 0
    if batch > 1:
        accept_lengths[1] = tokens
    if batch > 2:
        accept_lengths[2] = 1
    cu_seqlens = torch.arange(
        0,
        (batch + 1) * tokens,
        tokens,
        device=device,
        dtype=torch.int32,
    )

    q_normalized = torch.empty(
        total_tokens, key_heads, width, device=device, dtype=torch.float32
    )
    k_normalized = torch.empty_like(q_normalized)
    decay = torch.empty(
        total_tokens, value_heads, device=device, dtype=torch.float32
    )
    beta = torch.empty_like(decay)
    output = torch.empty(
        1, total_tokens, value_heads, width, device=device, dtype=torch.bfloat16
    )
    graph_output = torch.empty_like(output)
    dummy_intermediate = torch.empty(1, device=device, dtype=torch.bfloat16)
    replay_state = state_master.clone()
    graph_replay_state = state_master.clone()

    bridge_path = args.build_dir / "libqwen36_27b_gdn_verify_m12_batched_bridge.so"
    bridge = ctypes.CDLL(str(bridge_path))
    bridge.netra_qwen36_gdn_verify_m12_batched_last_error.restype = ctypes.c_char_p

    def check(status: int, operation: str) -> None:
        if status:
            raw = bridge.netra_qwen36_gdn_verify_m12_batched_last_error()
            message = raw.decode() if raw else "unknown bridge error"
            raise RuntimeError(f"{operation}: {message}")

    check(
        bridge.netra_qwen36_gdn_verify_m12_batched_set_block_tokens(
            ctypes.c_uint32(tokens)
        ),
        "set block tokens",
    )
    check(
        bridge.netra_qwen36_gdn_verify_m12_batched_load(
            str(args.build_dir / "t8-bf16/precompute-gates.hsaco").encode(),
            str(args.build_dir / "t8-bf16/core.hsaco").encode(),
        ),
        "load core",
    )
    check(
        bridge.netra_qwen36_gdn_verify_m12_batched_load_state_replay(
            str(args.build_dir / "t8-bf16/replay.hsaco").encode()
        ),
        "load replay",
    )
    def current_stream() -> ctypes.c_void_p:
        """Resolve the caller-owned stream, including PyTorch's capture stream."""
        return ctypes.c_void_p(torch.cuda.current_stream(device).cuda_stream)

    def launch_precompute() -> None:
        check(
            bridge.netra_qwen36_gdn_verify_m12_batched_launch_precompute(
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
                ctypes.c_uint32(key_heads * width),
                ctypes.c_uint32(key_heads * width),
                ctypes.c_uint32(value_heads),
                ctypes.c_uint32(value_heads),
                ctypes.c_uint32(batch),
                current_stream(),
            ),
            "precompute",
        )

    def launch_core(destination: torch.Tensor = output) -> None:
        check(
            bridge.netra_qwen36_gdn_verify_m12_batched_launch_precomputed(
                pointer(q_normalized),
                pointer(k_normalized),
                pointer(v),
                pointer(decay),
                pointer(beta),
                pointer(destination),
                pointer(state_master),
                pointer(dummy_intermediate),
                pointer(state_indices),
                pointer(state_indices),
                ctypes.c_uint32(v_storage.stride(0)),
                ctypes.c_uint32(batch),
                ctypes.c_uint32(state_capacity),
                current_stream(),
            ),
            "core",
        )

    def launch_replay(destination: torch.Tensor = replay_state) -> None:
        check(
            bridge.netra_qwen36_gdn_verify_m12_batched_launch_state_replay(
                pointer(k_normalized),
                pointer(v),
                pointer(decay),
                pointer(beta),
                pointer(destination),
                pointer(accept_lengths),
                pointer(state_indices),
                pointer(state_indices),
                ctypes.c_uint32(v_storage.stride(0)),
                ctypes.c_uint32(batch),
                ctypes.c_uint32(state_capacity),
                current_stream(),
            ),
            "replay",
        )

    launch_precompute()
    launch_core()
    launch_replay()
    torch.cuda.synchronize(device)

    q_view = q.view(1, total_tokens, key_heads, width)
    k_view = k.view(1, total_tokens, key_heads, width)
    v_view = v.reshape(1, total_tokens, value_heads, width)

    reference_output = fused_sigmoid_gating_delta_rule_update(
        A_log=A_log,
        dt_bias=dt_bias,
        q=q_view,
        k=k_view,
        v=v_view,
        a=a,
        b=b,
        initial_state_source=state_master,
        initial_state_indices=state_indices,
        cu_seqlens=cu_seqlens,
        use_qk_l2norm_in_kernel=True,
        softplus_beta=1.0,
        softplus_threshold=20.0,
        disable_state_update=True,
    )
    reference_replay_state = state_master.clone()
    fused_sigmoid_gating_delta_rule_update(
        A_log=A_log,
        dt_bias=dt_bias,
        q=k_view,
        k=k_view,
        v=v_view,
        a=a,
        b=b,
        initial_state_source=reference_replay_state,
        initial_state_indices=state_indices,
        output_state_indices=state_indices,
        cu_seqlens=cu_seqlens,
        use_qk_l2norm_in_kernel=True,
        softplus_beta=1.0,
        softplus_threshold=20.0,
        disable_output_calculation=True,
        input_sequence_lengths=accept_lengths,
        input_token_start=0,
        input_token_stride=tokens,
    )
    torch.cuda.synchronize(device)

    eager_core = compare(output, reference_output)
    eager_replay = compare(replay_state, reference_replay_state)

    launch_core(graph_output)
    graph_replay_state.copy_(state_master)
    torch.cuda.synchronize(device)
    core_graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(core_graph):
        launch_core(graph_output)
    replay_graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(replay_graph):
        launch_replay(graph_replay_state)
    graph_output.zero_()
    graph_replay_state.copy_(state_master)
    core_graph.replay()
    replay_graph.replay()
    torch.cuda.synchronize(device)
    graph_core = compare(graph_output, reference_output)
    graph_replay = compare(graph_replay_state, reference_replay_state)

    timings = {
        "precompute_median_us": median_us(launch_precompute, args.iterations),
        "core_median_us": median_us(launch_core, args.iterations),
    }
    replay_state.copy_(state_master)
    timings["replay_median_us"] = median_us(launch_replay, args.iterations)

    result = {
        "format": "netra-qwen36-27b-gdn-bf16-state-t8-synthetic-1",
        "target": "gfx950",
        "tokens": tokens,
        "batch": batch,
        "state_dtype": "bfloat16",
        "eager": {"core": eager_core, "replay": eager_replay},
        "graph": {"core": graph_core, "replay": graph_replay},
        "timing": timings,
    }
    encoded = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded)
    print(encoded, end="")
    if not all(
        check_result["bit_exact"]
        for mode in (result["eager"], result["graph"])
        for check_result in mode.values()
    ):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
