#!/usr/bin/env python3
"""Real-checkpoint gate for raw gfx950 Qwen GDN K0 accepted-prefix replay."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch

from sglang.srt.layers.attention.fla.fused_sigmoid_gating_recurrent import (
    fused_sigmoid_gating_delta_rule_update,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-pass", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--batch", type=int, default=64)
    parser.add_argument("--waves", type=int, nargs="+", default=(1, 4, 8))
    parser.add_argument("--hip-graph", action="store_true")
    parser.add_argument("--precomputed", action="store_true")
    parser.add_argument(
        "--index-mode",
        choices=("same", "spare", "shifted", "reverse"),
        default="same",
    )
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(actual: torch.Tensor, expected: torch.Tensor) -> dict[str, object]:
    delta = (actual.float() - expected.float()).abs()
    return {
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
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


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)
    if args.iterations <= 0:
        raise ValueError("--iterations must be positive")
    if not args.waves or any(waves not in (1, 4, 8) for waves in args.waves):
        raise ValueError("--waves entries must be 1, 4, or 8")
    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    payload = torch.load(args.state_pass, map_location="cpu", weights_only=False)
    metadata = payload["metadata"]
    captured_batch = int(metadata["batch_size"])
    captured_tokens = int(metadata["input_token_count"])
    if captured_batch != 64 or captured_tokens != captured_batch * 12:
        raise ValueError(f"expected B64/M12 capture, got {metadata}")
    batch = args.batch
    if not 1 <= batch <= captured_batch:
        raise ValueError(f"--batch must be in [1,{captured_batch}]")
    total_tokens = batch * 12
    prefix = "gdn_stage.layer.0.backend"

    def gpu(key: str) -> torch.Tensor:
        value = payload[key]
        if not isinstance(value, torch.Tensor):
            raise TypeError(key)
        return value.contiguous().to(device=device)

    def token_gpu(key: str) -> torch.Tensor:
        value = gpu(key)
        if value.ndim == 4 and value.shape[1] == captured_tokens:
            return value[:, :total_tokens].contiguous()
        if value.ndim >= 1 and value.shape[0] == captured_tokens:
            return value[:total_tokens].contiguous()
        raise ValueError(f"unexpected packed-token tensor for {key}: {value.shape}")

    A_log = gpu(f"{prefix}.verify_A_log")
    a = token_gpu(f"{prefix}.verify_a")
    dt_bias = gpu(f"{prefix}.verify_dt_bias")
    k = token_gpu(f"{prefix}.verify_k")
    v = token_gpu(f"{prefix}.verify_v")
    b = token_gpu(f"{prefix}.verify_b")
    initial = gpu(f"{prefix}.initial_ssm")
    del payload

    output_indices = torch.arange(batch, dtype=torch.int32, device=device)
    if args.index_mode == "spare":
        initial = torch.cat((initial, initial[:1].clone()), dim=0)
        initial_indices = output_indices
        output_indices = output_indices.clone()
        output_indices[-1] = initial.shape[0] - 1
    elif args.index_mode == "shifted":
        initial_indices = output_indices.roll(1)
    elif args.index_mode == "reverse":
        initial_indices = output_indices.flip(0).contiguous()
    else:
        initial_indices = output_indices
    patterns = {
        "zero": torch.zeros(batch, dtype=torch.int32, device=device),
        "one": torch.ones(batch, dtype=torch.int32, device=device),
        "ramp": (torch.arange(batch, dtype=torch.int32, device=device) % 12) + 1,
        "twelve": torch.full((batch,), 12, dtype=torch.int32, device=device),
    }

    bridge = ctypes.CDLL(
        str(args.build_dir / "libqwen36_gdn_state_replay_m12_bridge.so")
    )
    bridge.netra_qwen36_gdn_state_replay_m12_load.argtypes = [ctypes.c_char_p] * 4
    bridge.netra_qwen36_gdn_state_replay_m12_load.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_state_replay_m12_launch.argtypes = (
        [ctypes.c_void_p] * 14
        + [ctypes.c_uint32] * 7
        + [ctypes.c_void_p]
    )
    bridge.netra_qwen36_gdn_state_replay_m12_launch.restype = ctypes.c_int
    bridge.netra_qwen36_gdn_state_replay_m12_launch_precomputed.argtypes = (
        [ctypes.c_void_p] * 8
        + [ctypes.c_uint32] * 4
        + [ctypes.c_void_p]
    )
    bridge.netra_qwen36_gdn_state_replay_m12_launch_precomputed.restype = (
        ctypes.c_int
    )
    bridge.netra_qwen36_gdn_state_replay_m12_last_error.restype = ctypes.c_char_p

    stem = "qwen36_gdn_state_replay_m12"
    status = bridge.netra_qwen36_gdn_state_replay_m12_load(
        str(
            args.build_dir
            / "qwen36_gdn_verify_m12_batched_precompute_gfx950.hsaco"
        ).encode(),
        str(args.build_dir / f"{stem}_waves1_gfx950.hsaco").encode(),
        str(args.build_dir / f"{stem}_waves4_gfx950.hsaco").encode(),
        str(args.build_dir / f"{stem}_waves8_gfx950.hsaco").encode(),
    )
    if status:
        raise RuntimeError(
            bridge.netra_qwen36_gdn_state_replay_m12_last_error().decode()
        )

    q_dummy = torch.empty_like(k, dtype=torch.float32)
    k_normalized = torch.empty_like(k, dtype=torch.float32)
    decay = torch.empty((total_tokens, 32), dtype=torch.float32, device=device)
    beta = torch.empty_like(decay)

    def run_triton(states: torch.Tensor, lengths: torch.Tensor) -> None:
        fused_sigmoid_gating_delta_rule_update(
            A_log=A_log,
            a=a,
            dt_bias=dt_bias,
            q=k,
            k=k,
            v=v,
            b=b,
            initial_state_source=states,
            initial_state_indices=initial_indices,
            output_state_indices=output_indices,
            use_qk_l2norm_in_kernel=True,
            softplus_beta=1.0,
            softplus_threshold=20.0,
            disable_output_calculation=True,
            input_sequence_lengths=lengths,
            input_token_start=0,
            input_token_stride=12,
        )

    def run_raw(states: torch.Tensor, lengths: torch.Tensor, waves: int) -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_state_replay_m12_launch(
            pointer(A_log),
            pointer(a),
            pointer(dt_bias),
            pointer(k),
            pointer(v),
            pointer(b),
            pointer(states),
            pointer(initial_indices),
            pointer(output_indices),
            pointer(lengths),
            pointer(q_dummy),
            pointer(k_normalized),
            pointer(decay),
            pointer(beta),
            k.stride(1),
            v.stride(1),
            a.stride(-2),
            b.stride(-2),
            batch,
            waves,
            states.shape[0],
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_state_replay_m12_last_error().decode()
            )

    def run_precomputed(
        states: torch.Tensor, lengths: torch.Tensor, waves: int
    ) -> None:
        stream = torch.cuda.current_stream(device)
        status = bridge.netra_qwen36_gdn_state_replay_m12_launch_precomputed(
            pointer(k_normalized),
            pointer(v),
            pointer(decay),
            pointer(beta),
            pointer(states),
            pointer(initial_indices),
            pointer(output_indices),
            pointer(lengths),
            v.stride(1),
            batch,
            waves,
            states.shape[0],
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(
                bridge.netra_qwen36_gdn_state_replay_m12_last_error().decode()
            )

    run_selected = run_precomputed if args.precomputed else run_raw
    if args.precomputed:
        # Populate the exact target-verification workspaces once, outside all
        # correctness comparisons and timing intervals.
        run_raw(initial.clone(), patterns["zero"], args.waves[0])
        torch.cuda.synchronize(device)

    results: dict[str, object] = {}
    exact = True
    for pattern_name, lengths in patterns.items():
        expected = initial.clone()
        run_triton(expected, lengths)
        torch.cuda.synchronize(device)
        triton_timing_state = initial.clone()
        for _ in range(5):
            triton_timing_state.copy_(initial)
            run_triton(triton_timing_state, lengths)
        torch.cuda.synchronize(device)
        triton_elapsed: list[float] = []
        for _ in range(args.iterations):
            triton_timing_state.copy_(initial)
            start = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            start.record()
            run_triton(triton_timing_state, lengths)
            end.record()
            end.synchronize()
            triton_elapsed.append(float(start.elapsed_time(end) * 1000.0))
        pattern_result: dict[str, object] = {
            "triton": {"timing": distribution(triton_elapsed)}
        }
        for waves in args.waves:
            actual = initial.clone()
            run_selected(actual, lengths, waves)
            torch.cuda.synchronize(device)
            correctness = compare(actual, expected)
            exact = exact and bool(correctness["bit_exact"])
            graph_correctness = None
            if args.hip_graph:
                graph = torch.cuda.CUDAGraph()
                graph_state = initial.clone()
                with torch.cuda.graph(graph):
                    run_selected(graph_state, lengths, waves)
                graph_state.copy_(initial)
                graph.replay()
                torch.cuda.synchronize(device)
                graph_correctness = compare(graph_state, expected)
                exact = exact and bool(graph_correctness["bit_exact"])

            timing_state = initial.clone()
            for _ in range(5):
                timing_state.copy_(initial)
                run_selected(timing_state, lengths, waves)
            torch.cuda.synchronize(device)
            elapsed: list[float] = []
            for _ in range(args.iterations):
                timing_state.copy_(initial)
                start = torch.cuda.Event(enable_timing=True)
                end = torch.cuda.Event(enable_timing=True)
                start.record()
                run_selected(timing_state, lengths, waves)
                end.record()
                end.synchronize()
                elapsed.append(float(start.elapsed_time(end) * 1000.0))
            pattern_result[f"waves{waves}"] = {
                "correctness": correctness,
                "graph_correctness": graph_correctness,
                "timing": distribution(elapsed),
            }
        results[pattern_name] = pattern_result

    output = {
        "accelerator": "AMD Instinct MI350X",
        "architecture": architecture,
        "model": "Qwen3.6-35B-A3B-FP8",
        "weight_quantization": "FP8 E4M3 128x128 blocks (unchanged)",
        "shape": {"batch": batch, "tokens": 12, "H": 16, "HV": 32, "K": 128, "V": 128},
        "state_pass": str(args.state_pass),
        "reuse_target_verify_precompute": args.precomputed,
        "index_mode": args.index_mode,
        "bit_exact": exact,
        "patterns": results,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n")
    print(json.dumps(output, indent=2, sort_keys=True))
    if not exact:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
