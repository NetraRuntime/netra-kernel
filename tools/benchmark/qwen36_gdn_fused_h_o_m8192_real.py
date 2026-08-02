#!/usr/bin/env python3
"""Real-checkpoint A/B for raw fused GDN h+o versus shipped h + Triton o."""

from __future__ import annotations

import argparse
import ctypes
import json
import math
import statistics
from pathlib import Path

import torch


def args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--layer-pass", type=Path, required=True)
    parser.add_argument("--h-pass", type=Path, required=True)
    parser.add_argument("--fused-build-dir", type=Path, required=True)
    parser.add_argument("--h-build-dir", type=Path, required=True)
    parser.add_argument("--iterations", type=int, default=30)
    parser.add_argument("--num-chunks", type=int, default=128)
    parser.add_argument(
        "--diagnostic-v-new",
        action="store_true",
        help="Compare the fused output buffer with the captured recurrent v_new tensor.",
    )
    parser.add_argument(
        "--diagnostic-weighted-v-new",
        action="store_true",
        help="Compare the output buffer with exp(g_last-g)*v_new.",
    )
    parser.add_argument(
        "--diagnostic-qh",
        action="store_true",
        help="Compare the output buffer with scale*exp(g)*Q@initial_state^T.",
    )
    parser.add_argument(
        "--diagnostic-k-lds",
        action="store_true",
        help="Compare the output buffer with grouped K reloaded from fused-kernel LDS.",
    )
    parser.add_argument(
        "--diagnostic-gated-qk",
        action="store_true",
        help="Compare output with the first chunk's causal gated QK matrix.",
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--diagnostic-tensors",
        type=Path,
        help="Optional CPU tensor dump for rejected raw-kernel diagnosis.",
    )
    return parser.parse_args()


def ptr(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(
    actual: torch.Tensor,
    expected: torch.Tensor,
    *,
    atol: float,
    rtol: float,
    cosine_min: float,
) -> dict[str, object]:
    a, e = actual.float(), expected.float()
    delta = (a - e).abs()
    max_flat_index = int(torch.nan_to_num(delta, nan=float("inf")).argmax().item())
    relative = delta / e.abs().clamp_min(1e-6)
    significant = torch.maximum(a.abs(), e.abs()) >= atol
    relative_fail = significant & (relative > rtol)
    cosine = float(torch.nn.functional.cosine_similarity(a.flatten(), e.flatten(), dim=0))
    finite = bool(torch.isfinite(a).all().item())
    return {
        "finite": finite,
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "max_abs_flat_index": max_flat_index,
        "actual_at_max_abs": float(a.flatten()[max_flat_index].item()),
        "expected_at_max_abs": float(e.flatten()[max_flat_index].item()),
        "max_relative_significant": (
            float(relative[significant].max().item()) if significant.any() else 0.0
        ),
        "mean_abs": float(delta.mean().item()),
        "rmse": float(torch.sqrt(torch.mean((a - e) ** 2)).item()),
        "cosine": cosine,
        "absolute_fail_count": int((delta > atol).sum().item()),
        "relative_fail_count": int(relative_fail.sum().item()),
        "pass": bool(
            finite
            and float(delta.max().item()) <= atol
            and not bool(relative_fail.any().item())
            and cosine >= cosine_min
        ),
    }


def distribution(values: list[float]) -> dict[str, float | int]:
    ordered = sorted(values)
    return {
        "count": len(ordered),
        "mean_us": statistics.mean(ordered),
        "median_us": statistics.median(ordered),
        "p90_us": ordered[min(len(ordered) - 1, math.ceil(0.9 * len(ordered)) - 1)],
        "minimum_us": ordered[0],
        "maximum_us": ordered[-1],
    }


def timed(call, reset, iterations: int, device: torch.device) -> dict[str, float | int]:
    for _ in range(5):
        reset()
        call()
    torch.cuda.synchronize(device)
    elapsed: list[float] = []
    for _ in range(iterations):
        reset()
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        call()
        end.record()
        end.synchronize()
        elapsed.append(float(start.elapsed_time(end) * 1000.0))
    return distribution(elapsed)


def main() -> None:
    a = args()
    if a.output.exists():
        raise FileExistsError(a.output)
    if a.iterations <= 0:
        raise ValueError("--iterations must be positive")
    device = torch.device("cuda", 0)
    arch = torch.cuda.get_device_properties(device).gcnArchName
    if not str(arch).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {arch}")

    from sglang.jit_kernel.triton.gdn_l2norm import l2norm_gather
    from sglang.srt.layers.attention.fla.chunk_o import chunk_fwd_kernel_o

    layer = torch.load(a.layer_pass, map_location="cpu", weights_only=True)
    hp = torch.load(a.h_pass, map_location="cpu", weights_only=True)
    q = l2norm_gather(layer["q"].contiguous().to(device), use_rsqrt=False)
    k = hp["k_normalized"].contiguous().to(device)
    u = hp["u"].contiguous().to(device)
    w = hp["w"].contiguous().to(device)
    g = hp["g_cumsum"].contiguous().to(device)
    initial = hp["initial_state"].contiguous().to(device)
    expected_output = layer["output"].contiguous().to(device)
    if sum(
        (
            a.diagnostic_v_new,
            a.diagnostic_weighted_v_new,
            a.diagnostic_qh,
            a.diagnostic_k_lds,
            a.diagnostic_gated_qk,
        )
    ) > 1:
        raise ValueError("select at most one fused-output diagnostic")
    if a.diagnostic_gated_qk:
        q_heads = q[:, :64].repeat_interleave(2, dim=2)
        k_heads = k[:, :64].repeat_interleave(2, dim=2)
        qk = torch.einsum("bthk,bshk->bths", q_heads.float(), k_heads.float())
        first_g = g[:, :64]
        qk *= torch.exp(
            first_g[:, :, :, None] - first_g.permute(0, 2, 1)[:, None, :, :]
        )
        causal = torch.arange(64, device=device)
        qk = qk.masked_fill(causal[None, :, None, None] < causal[None, None, None, :], 0)
        expected_fused_output = torch.empty_like(expected_output)
        expected_fused_output[:, :64] = qk.bfloat16().repeat(1, 1, 1, 2)
    elif a.diagnostic_k_lds:
        expected_fused_output = hp["k_normalized"].repeat_interleave(2, dim=2).to(device)
    elif a.diagnostic_qh:
        q_heads = q.repeat_interleave(2, dim=2)
        expected_fused_output = (
            torch.einsum(
                "bthk,bhvk->bthv", q_heads.float(), initial.float()
            )
            * torch.exp(g[:, :, :, None])
            * (128.0**-0.5)
        ).bfloat16()
    elif a.diagnostic_weighted_v_new:
        v_new_cpu = hp["v_new"].float()
        g_cpu = hp["g_cumsum"].float()
        g_last_cpu = g_cpu.reshape(1, 128, 64, 32)[:, :, -1, :]
        expected_fused_output = (
            v_new_cpu.reshape(1, 128, 64, 32, 128)
            * torch.exp(g_last_cpu[:, :, None, :, None] - g_cpu.reshape(1, 128, 64, 32, 1))
        ).reshape_as(v_new_cpu).bfloat16().contiguous().to(device)
    else:
        expected_fused_output = (
            hp["v_new"] if a.diagnostic_v_new else layer["output"]
        ).contiguous().to(device)
    expected_state = (
        hp["final_state"]
        if a.num_chunks == 128
        else hp["h"][:, a.num_chunks]
    ).contiguous().to(device)
    first_chunk_v_new = hp["v_new"][:, :64].contiguous().to(device)
    initial_indices = hp["initial_state_indices"].contiguous().to(device)
    cu = hp["cu_seqlens"].contiguous().to(device)
    chunk_indices = hp["chunk_indices"].contiguous().to(device)
    chunk_offsets = chunk_indices.view(torch.int64)
    del layer, hp

    baseline_h = torch.empty((1, 128, 32, 128, 128), dtype=torch.bfloat16, device=device)
    baseline_v = torch.empty_like(u)
    baseline_state = initial.clone()
    baseline_output = torch.empty_like(expected_output)
    fused_state = initial.clone()
    fused_output = torch.empty_like(expected_output)
    scale = 128.0**-0.5

    hlib = ctypes.CDLL(str(a.h_build_dir / "libqwen36_gdn_h_m8192_bv16_bridge.so"))
    hlib.netra_qwen36_gdn_h_m8192_bv16_load.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    hlib.netra_qwen36_gdn_h_m8192_bv16_load.restype = ctypes.c_int
    hlib.netra_qwen36_gdn_h_m8192_bv16_launch.argtypes = [
        *([ctypes.c_void_p] * 10), ctypes.c_void_p
    ]
    hlib.netra_qwen36_gdn_h_m8192_bv16_launch.restype = ctypes.c_int
    hlib.netra_qwen36_gdn_h_m8192_bv16_last_error.restype = ctypes.c_char_p
    status = hlib.netra_qwen36_gdn_h_m8192_bv16_load(
        str(a.h_build_dir / "qwen36_gdn_h_m8192_bv16_gfx950.hsaco").encode(),
        b"qwen36_gdn_h_m8192_bv16_gfx950",
    )
    if status:
        raise RuntimeError(hlib.netra_qwen36_gdn_h_m8192_bv16_last_error().decode())

    flib = ctypes.CDLL(str(a.fused_build_dir / "libqwen36_gdn_fused_h_o_m8192_bridge.so"))
    flib.netra_qwen36_gdn_fused_h_o_m8192_load.argtypes = [
        ctypes.c_char_p, ctypes.c_char_p
    ]
    flib.netra_qwen36_gdn_fused_h_o_m8192_load.restype = ctypes.c_int
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch.argtypes = [
        *([ctypes.c_void_p] * 7), ctypes.c_float, ctypes.c_uint32,
        ctypes.c_void_p
    ]
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch.restype = ctypes.c_int
    flib.netra_qwen36_gdn_fused_h_o_m8192_last_error.restype = ctypes.c_char_p
    status = flib.netra_qwen36_gdn_fused_h_o_m8192_load(
        str(a.fused_build_dir / "qwen36_gdn_fused_h_o_m8192_bv16_gfx950.hsaco").encode(),
        b"qwen36_gdn_fused_h_o_m8192_bv16_gfx950",
    )
    if status:
        raise RuntimeError(flib.netra_qwen36_gdn_fused_h_o_m8192_last_error().decode())

    def run_h() -> None:
        stream = torch.cuda.current_stream(device)
        status = hlib.netra_qwen36_gdn_h_m8192_bv16_launch(
            ptr(k), ptr(u), ptr(w), ptr(baseline_v), ptr(g), ptr(baseline_h),
            ptr(baseline_state), ptr(initial_indices), ptr(cu), ptr(chunk_offsets),
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(hlib.netra_qwen36_gdn_h_m8192_bv16_last_error().decode())

    def run_o() -> None:
        chunk_fwd_kernel_o[(2, 128, 32)](
            q, k, baseline_v, baseline_h, g, baseline_output, cu, chunk_indices,
            scale, T=8192, H=32, Hg=16, K=128, V=128, BT=64, BK=128, BV=64,
            USE_G=True, IS_VARLEN=True, num_warps=4, num_stages=2,
        )

    def run_baseline() -> None:
        run_h()
        run_o()

    def run_fused() -> None:
        stream = torch.cuda.current_stream(device)
        status = flib.netra_qwen36_gdn_fused_h_o_m8192_launch(
            ptr(q), ptr(k), ptr(u), ptr(w), ptr(g), ptr(fused_state),
            ptr(fused_output), ctypes.c_float(scale), ctypes.c_uint32(a.num_chunks),
            ctypes.c_void_p(stream.cuda_stream),
        )
        if status:
            raise RuntimeError(flib.netra_qwen36_gdn_fused_h_o_m8192_last_error().decode())

    baseline_state.copy_(initial)
    fused_state.copy_(initial)
    if (
        a.diagnostic_v_new
        or a.diagnostic_weighted_v_new
        or a.diagnostic_qh
        or a.diagnostic_k_lds
        or a.diagnostic_gated_qk
    ):
        fused_output.fill_(float("nan"))
    run_baseline()
    run_fused()
    torch.cuda.synchronize(device)
    correctness = {
        "baseline_output": compare(
            baseline_output, expected_output, atol=0.03125, rtol=0.01, cosine_min=0.9995
        ),
        "baseline_state": compare(
            baseline_state, expected_state, atol=0.125, rtol=0.02, cosine_min=0.999
        ),
        "fused_output": compare(
            fused_output[:, : a.num_chunks * 64],
            expected_fused_output[:, : a.num_chunks * 64],
            atol=0.03125, rtol=0.01, cosine_min=0.9995
        ),
        "fused_state": compare(
            fused_state, expected_state, atol=0.125, rtol=0.02, cosine_min=0.999
        ),
        "fused_state_transposed": compare(
            fused_state.transpose(-1, -2),
            expected_state,
            atol=0.125,
            rtol=0.02,
            cosine_min=0.999,
        ),
    }
    state_k_head_match = []
    if a.num_chunks == 1:
        first_g = g[:, :64]
        first_g_last = first_g[:, -1]
        weighted = (
            first_chunk_v_new.float()
            * torch.exp(first_g_last[:, None, :, None] - first_g[:, :, :, None])
        ).bfloat16()
        grouped_k = k[:, :64].repeat_interleave(2, dim=2)
        decayed = initial.float() * torch.exp(first_g_last[:, :, None, None])

        def state_after(token_slice: slice) -> torch.Tensor:
            update = torch.einsum(
                "bthv,bthk->bhvk",
                weighted[:, token_slice].float(),
                grouped_k[:, token_slice].float(),
            )
            return (decayed + update).bfloat16()

        correctness["torch_state_full64"] = compare(
            state_after(slice(None)),
            expected_state,
            atol=0.125,
            rtol=0.02,
            cosine_min=0.999,
        )
        correctness["fused_vs_torch_first32"] = compare(
            fused_state,
            state_after(slice(0, 32)),
            atol=0.125,
            rtol=0.02,
            cosine_min=0.999,
        )
        correctness["fused_vs_torch_last32"] = compare(
            fused_state,
            state_after(slice(32, 64)),
            atol=0.125,
            rtol=0.02,
            cosine_min=0.999,
        )
        for value_head in range(32):
            actual_update = fused_state[0, value_head].float() - decayed[0, value_head]
            candidate_cosines = []
            for key_head in range(16):
                candidate_update = torch.einsum(
                    "tv,tk->vk",
                    weighted[0, :, value_head].float(),
                    k[0, :64, key_head].float(),
                )
                candidate_cosines.append(
                    float(
                        torch.nn.functional.cosine_similarity(
                            actual_update.flatten(), candidate_update.flatten(), dim=0
                        ).item()
                    )
                )
            best_key_head = max(range(16), key=lambda idx: candidate_cosines[idx])
            state_k_head_match.append(
                {
                    "value_head": value_head,
                    "expected_key_head": value_head // 2,
                    "best_key_head": best_key_head,
                    "expected_cosine": candidate_cosines[value_head // 2],
                    "best_cosine": candidate_cosines[best_key_head],
                }
            )
    timing = {
        "shipped_raw_h": timed(
            run_h, lambda: baseline_state.copy_(initial), a.iterations, device
        ),
        "triton_o": timed(
            run_o, lambda: None, a.iterations, device
        ),
        "shipped_raw_h_plus_triton_o": timed(
            run_baseline, lambda: baseline_state.copy_(initial), a.iterations, device
        ),
        "fused_raw_h_o": timed(
            run_fused, lambda: fused_state.copy_(initial), a.iterations, device
        ),
    }
    baseline_median = float(timing["shipped_raw_h_plus_triton_o"]["median_us"])
    fused_median = float(timing["fused_raw_h_o"]["median_us"])
    accepted = bool(
        correctness["baseline_output"]["pass"]
        and correctness["baseline_state"]["pass"]
        and correctness["fused_output"]["pass"]
        and correctness["fused_state"]["pass"]
        and a.num_chunks == 128
        and fused_median < baseline_median
    )
    result = {
        "target": str(arch),
        "shape": {"B": 1, "T": 8192, "H": 32, "Hg": 16, "K": 128, "V": 128, "BT": 64, "BV": 16},
        "diagnostic_v_new": bool(a.diagnostic_v_new),
        "diagnostic_weighted_v_new": bool(a.diagnostic_weighted_v_new),
        "diagnostic_qh": bool(a.diagnostic_qh),
        "diagnostic_k_lds": bool(a.diagnostic_k_lds),
        "diagnostic_gated_qk": bool(a.diagnostic_gated_qk),
        "grid": [8, 32, 1],
        "block": [256, 1, 1],
        "lds_bytes": 18432,
        "diagnostic_num_chunks": a.num_chunks,
        "correctness": correctness,
        "timing": timing,
        "median_speedup": baseline_median / fused_median,
        "accepted_isolated": accepted,
        "diagnostics": {
            "state_k_head_match": state_k_head_match,
            "fused_output_head_cosine": [
                float(
                    torch.nn.functional.cosine_similarity(
                        fused_output[:, : a.num_chunks * 64, head].float().flatten(),
                        expected_fused_output[:, : a.num_chunks * 64, head].float().flatten(),
                        dim=0,
                    ).item()
                )
                for head in range(32)
            ],
            "fused_state_head_cosine": [
                float(
                    torch.nn.functional.cosine_similarity(
                        fused_state[:, head].float().flatten(),
                        expected_state[:, head].float().flatten(),
                        dim=0,
                    ).item()
                )
                for head in range(32)
            ],
        },
    }
    a.output.parent.mkdir(parents=True, exist_ok=True)
    a.output.write_text(json.dumps(result, indent=2) + "\n")
    if a.diagnostic_tensors is not None:
        a.diagnostic_tensors.parent.mkdir(parents=True, exist_ok=True)
        torch.save(
            {
                "fused_output": fused_output[:, : a.num_chunks * 64].cpu(),
                "expected_output": expected_fused_output[:, : a.num_chunks * 64].cpu(),
                "fused_state": fused_state.cpu(),
                "expected_state": expected_state.cpu(),
                "initial_state": initial.cpu(),
                "k_first_chunk": k[:, :64].cpu(),
                "weighted_v_new_first_chunk": (
                    weighted.cpu() if a.num_chunks == 1 else None
                ),
            },
            a.diagnostic_tensors,
        )
    print(json.dumps(result, indent=2))
    if not accepted:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
