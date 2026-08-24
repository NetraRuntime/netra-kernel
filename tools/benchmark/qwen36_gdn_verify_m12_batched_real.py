#!/usr/bin/env python3
"""Real-checkpoint gate for the raw gfx950 batched Qwen GDN M=12 pipeline."""

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
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument(
        "--k0-no-intermediate",
        action="store_true",
        help=(
            "Validate the K0 target-verify ABI: no intermediate snapshots and "
            "FP32 live recurrence across all 12 positions."
        ),
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
    delta = (actual.float() - expected.float()).abs()
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
    }


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def main() -> None:
    args = parse_args()
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

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=False)
    metadata = payload["metadata"]
    if str(metadata["forward_mode"]) != "ForwardMode.TARGET_VERIFY":
        raise ValueError(metadata)
    batch = int(metadata["batch_size"])
    total_tokens = int(metadata["input_token_count"])
    if batch != 64 or total_tokens != 768 or total_tokens // batch != 12:
        raise ValueError(f"expected exact B64/M12 capture, got {metadata}")

    prefix = "gdn_stage.layer.0"
    backend = f"{prefix}.backend"

    def gpu(key: str) -> torch.Tensor:
        value = payload[key]
        if not isinstance(value, torch.Tensor):
            raise TypeError(key)
        return value.contiguous().to(device=device)

    A_log = gpu(f"{backend}.verify_A_log")
    a = gpu(f"{backend}.verify_a")
    dt_bias = gpu(f"{backend}.verify_dt_bias")
    q = gpu(f"{backend}.verify_q")
    k = gpu(f"{backend}.verify_k")
    v = gpu(f"{backend}.verify_v")
    b = gpu(f"{backend}.verify_b")
    initial = gpu(f"{backend}.initial_ssm")
    cu_seqlens = gpu(f"{backend}.query_start_loc")
    captured_intermediate_indices = gpu(
        f"{backend}.verify_intermediate_state_indices"
    )
    indices = torch.arange(batch, dtype=torch.int32, device=device)
    if not torch.equal(captured_intermediate_indices, indices):
        raise ValueError("capture does not use dense intermediate-state indices")
    expected_output = gpu(f"{prefix}.core_attn")
    expected_final = gpu(f"{backend}.final_ssm")
    expected_intermediate = gpu("gdn.layer.0.intermediate_ssm")
    del payload

    value_heads, width = 32, 128
    triton_output = torch.empty((1, *v.shape), dtype=torch.bfloat16, device=device)
    triton_intermediate = torch.empty_like(expected_intermediate)

    def run_triton() -> torch.Tensor:
        intermediate_buffer = (
            None if args.k0_no_intermediate else triton_intermediate
        )
        intermediate_indices = None if args.k0_no_intermediate else indices
        fused_sigmoid_gating_delta_rule_update_kernel[
            (1, 4, batch * value_heads)
        ](
            A_log=A_log, a=a, dt_bias=dt_bias,
            softplus_beta=1.0, softplus_threshold=20.0,
            q=q, k=k, v=v, b=b, o=triton_output,
            h0_source=initial, h0_indices=indices, h0_output_indices=indices,
            cu_seqlens=cu_seqlens,
            intermediate_states_buffer=intermediate_buffer,
            intermediate_state_indices=intermediate_indices,
            cache_steps=0 if args.k0_no_intermediate else 12,
            retrieve_parent_token_ptr=None, input_token_indices=None,
            input_sequence_indices=None, input_sequence_lengths=None,
            input_token_start=0, input_token_stride=0,
            stride_retrieve_parent_token_seq=0,
            stride_retrieve_parent_token_token=0,
            scale=width**-0.5, T=total_tokens,
            stride_a=a.stride(-2), stride_q=q.stride(1),
            stride_k=k.stride(1), stride_v=v.stride(1), stride_b=b.stride(-2),
            NP2_T=1024, B=1, H=16, HV=value_heads, K=width, V=width,
            BK=width, BV=32, USE_INITIAL_STATE=True,
            USE_QK_L2NORM_IN_KERNEL=True, IS_VARLEN=True, IS_KDA=False,
            DISABLE_STATE_UPDATE=True, DISABLE_OUTPUT_CALCULATION=False,
            CACHE_INTERMEDIATE_STATES=not args.k0_no_intermediate,
            HAS_EAGLE_TREE_CUSTOM_ATTN_MASK=False,
            HAS_INPUT_TOKEN_INDICES=False, HAS_INPUT_SEQUENCE_INDICES=False,
            HAS_INPUT_SEQUENCE_LENGTHS=False, USE_APPROX_RSQRT=False,
            num_warps=1, num_stages=3,
        )
        return triton_output.squeeze(0)

    bridge = ctypes.CDLL(
        str(args.build_dir / "libqwen36_gdn_verify_m12_batched_bridge.so")
    )
    bridge.netra_qwen36_gdn_verify_m12_batched_load.argtypes = [
        ctypes.c_char_p, ctypes.c_char_p
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
        [ctypes.c_void_p] * 16 + [ctypes.c_uint32] * 6 + [ctypes.c_void_p]
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

    raw_output = torch.empty_like(expected_output)
    raw_intermediate = torch.empty_like(expected_intermediate)
    q_normalized = torch.empty_like(q, dtype=torch.float32)
    k_normalized = torch.empty_like(k, dtype=torch.float32)
    decay = torch.empty((total_tokens, value_heads), dtype=torch.float32, device=device)
    beta = torch.empty_like(decay)

    def run_raw() -> torch.Tensor:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_verify_m12_batched_launch(
            pointer(raw_output), pointer(A_log), pointer(a), pointer(dt_bias),
            pointer(q), pointer(k), pointer(v), pointer(b), pointer(initial),
            pointer(indices), pointer(raw_intermediate), pointer(indices),
            pointer(q_normalized), pointer(k_normalized), pointer(decay), pointer(beta),
            q.stride(1), k.stride(1), v.stride(1), a.stride(-2), b.stride(-2),
            batch, ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_verify_m12_batched_last_error().decode()
            )
        return raw_output

    triton_actual = run_triton()
    raw_actual = run_raw()
    torch.cuda.synchronize(device)
    if args.k0_no_intermediate:
        correctness = {
            "raw_output_vs_triton_k0": compare(raw_actual, triton_actual),
            # Retain this comparison only to make any semantic difference from
            # the older full-cache capture explicit.  It is not the K0 oracle.
            "triton_k0_output_vs_full_cache_capture": compare(
                triton_actual, expected_output
            ),
        }
        exact = correctness["raw_output_vs_triton_k0"]["bit_exact"]
    else:
        correctness = {
            "triton_output_vs_capture": compare(triton_actual, expected_output),
            "triton_intermediate_vs_capture": compare(
                triton_intermediate, expected_intermediate
            ),
            "raw_output_vs_capture": compare(raw_actual, expected_output),
            "raw_intermediate_vs_capture": compare(
                raw_intermediate, expected_intermediate
            ),
            "raw_final_vs_capture": compare(
                raw_intermediate[:, -1], expected_final
            ),
        }
        exact = all(value["bit_exact"] for value in correctness.values())

    for _ in range(5):
        run_triton(); run_raw()
    torch.cuda.synchronize(device)
    timings: dict[str, dict[str, float | int]] = {}
    for name, function in (("triton", run_triton), ("raw", run_raw)):
        elapsed: list[float] = []
        for _ in range(args.iterations):
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record(); function(); end.record(); end.synchronize()
            elapsed.append(float(start.elapsed_time(end) * 1000.0))
        timings[name] = distribution(elapsed)

    result = {
        "accelerator": "AMD Instinct MI350X",
        "architecture": architecture,
        "model": "Qwen3.6-35B-A3B-FP8",
        "weight_quantization": "FP8 E4M3 128x128 blocks (unchanged)",
        "state_pass": str(args.state_pass),
        "shape": {"batch": batch, "tokens_per_sequence": 12, "total_tokens": total_tokens},
        "k0_no_intermediate": args.k0_no_intermediate,
        "wavegroup_variants": wavegroup_variants,
        "correctness": correctness,
        "bit_exact": exact,
        "timing": timings,
        "median_speedup": timings["triton"]["median_us"] / timings["raw"]["median_us"],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    if not exact:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
