#!/usr/bin/env python3
"""Validate the segmented T1024 affine decomposition for Qwen3.6 GDN M8192.

This is an algorithm oracle for the successor raw gfx950 implementation.  It
runs the accepted raw H plus Triton O path for one real T8192 sequence, runs
the existing raw fused T1024 kernel on eight zero-state segments, then applies
the exact inter-segment affine-state and output correction in PyTorch.
"""

from __future__ import annotations

import argparse
import ctypes
import json
from pathlib import Path

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--layer-pass", type=Path, required=True)
    parser.add_argument("--h-pass", type=Path, required=True)
    parser.add_argument("--fused-build-dir", type=Path, required=True)
    parser.add_argument("--h-build-dir", type=Path, required=True)
    parser.add_argument("--server-python", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def compare(
    actual: torch.Tensor,
    expected: torch.Tensor,
    *,
    atol: float,
    rtol: float,
    cosine_min: float,
) -> dict[str, object]:
    a = actual.float()
    e = expected.float()
    delta = (a - e).abs()
    tolerance = atol + rtol * e.abs()
    cosine = float(
        torch.nn.functional.cosine_similarity(a.flatten(), e.flatten(), dim=0)
    )
    finite = bool(torch.isfinite(a).all().item())
    return {
        "finite": finite,
        "bit_exact": bool(torch.equal(actual, expected)),
        "mismatch_count": int((actual != expected).sum().item()),
        "element_count": actual.numel(),
        "max_abs": float(delta.max().item()),
        "mean_abs": float(delta.mean().item()),
        "cosine": cosine,
        "combined_atol_rtol_fail_count": int((delta > tolerance).sum().item()),
        "pass": bool(
            finite and not bool((delta > tolerance).any().item())
            and cosine >= cosine_min
        ),
    }


def main() -> None:
    args = parse_args()
    if args.output.exists():
        raise FileExistsError(args.output)

    import sys

    sys.path.insert(0, str(args.server_python))
    from sglang.jit_kernel.triton.gdn_l2norm import l2norm_gather
    from sglang.srt.layers.attention.fla.chunk_o import chunk_fwd_kernel_o
    from sglang.srt.layers.attention.fla.index import (
        prepare_chunk_indices,
        prepare_chunk_offsets,
    )

    device = torch.device("cuda", 0)
    architecture = torch.cuda.get_device_properties(device).gcnArchName
    if not str(architecture).startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {architecture}")

    layer = torch.load(args.layer_pass, map_location="cpu", weights_only=True)
    hp = torch.load(args.h_pass, map_location="cpu", weights_only=True)

    q = l2norm_gather(layer["q"].contiguous().to(device), use_rsqrt=False)
    k = hp["k_normalized"].contiguous().to(device)
    u = hp["u"].contiguous().to(device)
    w = hp["w"].contiguous().to(device)
    g = hp["g_cumsum"].contiguous().to(device)
    initial = hp["initial_state"].contiguous().to(device)
    captured_output = layer["output"].contiguous().to(device)
    captured_final_state = layer["final_state"].contiguous().to(device)
    del layer, hp

    total_tokens = 8192
    segment_length = 1024
    segment_count = total_tokens // segment_length
    heads = 32
    query_heads = 16
    key_dim = value_dim = 128
    chunk_size = 64
    chunks = total_tokens // chunk_size
    scale = key_dim**-0.5

    cu_full = torch.tensor([0, total_tokens], dtype=torch.int32, device=device)
    full_indices = torch.zeros(1, dtype=torch.int32, device=device)
    chunk_indices = prepare_chunk_indices(cu_full, chunk_size)
    chunk_offsets = prepare_chunk_offsets(cu_full, chunk_size)

    h = torch.empty(
        (1, chunks, heads, key_dim, value_dim),
        dtype=torch.bfloat16,
        device=device,
    )
    v_new = torch.empty_like(u)
    baseline_state = initial.clone()
    baseline_output = torch.empty(
        (1, total_tokens, heads, value_dim),
        dtype=torch.bfloat16,
        device=device,
    )

    hlib = ctypes.CDLL(
        str(args.h_build_dir / "libqwen36_gdn_h_m8192_bv16_bridge.so")
    )
    hlib.netra_qwen36_gdn_h_m8192_bv16_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    hlib.netra_qwen36_gdn_h_m8192_bv16_load.restype = ctypes.c_int
    hlib.netra_qwen36_gdn_h_m8192_bv16_launch.argtypes = [
        *([ctypes.c_void_p] * 10),
        ctypes.c_uint32,
        ctypes.c_void_p,
    ]
    hlib.netra_qwen36_gdn_h_m8192_bv16_launch.restype = ctypes.c_int
    hlib.netra_qwen36_gdn_h_m8192_bv16_last_error.restype = ctypes.c_char_p
    status = hlib.netra_qwen36_gdn_h_m8192_bv16_load(
        str(args.h_build_dir / "qwen36_gdn_h_m8192_bv16_gfx950.hsaco").encode(),
        b"qwen36_gdn_h_m8192_bv16_gfx950",
    )
    if status:
        raise RuntimeError(
            hlib.netra_qwen36_gdn_h_m8192_bv16_last_error().decode()
        )

    stream = torch.cuda.current_stream(device)
    status = hlib.netra_qwen36_gdn_h_m8192_bv16_launch(
        pointer(k),
        pointer(u),
        pointer(w),
        pointer(v_new),
        pointer(g),
        pointer(h),
        pointer(baseline_state),
        pointer(full_indices),
        pointer(cu_full),
        pointer(chunk_offsets),
        ctypes.c_uint32(1),
        ctypes.c_void_p(stream.cuda_stream),
    )
    if status:
        raise RuntimeError(
            hlib.netra_qwen36_gdn_h_m8192_bv16_last_error().decode()
        )
    chunk_fwd_kernel_o[(2, chunks, heads)](
        q,
        k,
        v_new,
        h,
        g,
        baseline_output,
        cu_full,
        chunk_indices,
        scale,
        T=total_tokens,
        H=heads,
        Hg=query_heads,
        K=key_dim,
        V=value_dim,
        BT=chunk_size,
        BK=key_dim,
        BV=64,
        USE_G=True,
        IS_VARLEN=True,
        num_warps=4,
        num_stages=2,
    )

    fused_kernel = "qwen36_gdn_fused_h_o_n16_t1024_bv128_gfx950"
    flib = ctypes.CDLL(
        str(args.fused_build_dir / "libqwen36_gdn_fused_h_o_m8192_bridge.so")
    )
    flib.netra_qwen36_gdn_fused_h_o_m8192_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    flib.netra_qwen36_gdn_fused_h_o_m8192_load.restype = ctypes.c_int
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024.argtypes = [
        *([ctypes.c_void_p] * 9),
        ctypes.c_float,
        ctypes.c_uint32,
        ctypes.c_uint32,
        ctypes.c_void_p,
    ]
    flib.netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024.restype = ctypes.c_int
    flib.netra_qwen36_gdn_fused_h_o_m8192_last_error.restype = ctypes.c_char_p
    status = flib.netra_qwen36_gdn_fused_h_o_m8192_load(
        str(args.fused_build_dir / f"{fused_kernel}.hsaco").encode(),
        fused_kernel.encode(),
    )
    if status:
        raise RuntimeError(
            flib.netra_qwen36_gdn_fused_h_o_m8192_last_error().decode()
        )

    segment_cu = torch.arange(
        0,
        total_tokens + 1,
        segment_length,
        dtype=torch.int32,
        device=device,
    )
    segment_indices = torch.arange(
        segment_count, dtype=torch.int32, device=device
    )
    local_states = torch.zeros(
        (segment_count, heads, key_dim, value_dim),
        dtype=torch.bfloat16,
        device=device,
    )
    local_output = torch.empty_like(baseline_output)
    status = flib.netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024(
        pointer(q),
        pointer(k),
        pointer(u),
        pointer(w),
        pointer(g),
        pointer(local_states),
        pointer(local_output),
        pointer(segment_indices),
        pointer(segment_cu),
        ctypes.c_float(scale),
        ctypes.c_uint32(segment_count),
        ctypes.c_uint32(segment_count),
        ctypes.c_void_p(stream.cuda_stream),
    )
    if status:
        raise RuntimeError(
            flib.netra_qwen36_gdn_fused_h_o_m8192_last_error().decode()
        )
    torch.cuda.synchronize()

    # Each segment is an affine state transition:
    #   S_(j+1) = exp(sum_c g[j,c,last]) * S_j + B_j
    # where B_j is the final zero-initial-state result emitted by the fused
    # T1024 kernel.  Round each boundary to BF16 because it is the production
    # state ABI consumed by the next segment.
    g_segments = g.view(segment_count, segment_length, heads)
    chunk_last_log_decay = g_segments[:, chunk_size - 1 :: chunk_size, :]
    log_a = chunk_last_log_decay.sum(dim=1)
    prefix_states = torch.empty_like(local_states)
    current = initial[0]
    for segment in range(segment_count):
        prefix_states[segment].copy_(current)
        current = (
            torch.exp(log_a[segment])[:, None, None] * current.float()
            + local_states[segment].float()
        ).to(torch.bfloat16)
    segmented_final_state = current.unsqueeze(0)

    # The local T1024 output already includes all contributions produced inside
    # the segment.  Add only the propagated segment-start state.  For a token in
    # chunk c, the external state is scaled by all completed chunk decays and
    # the token's within-chunk cumulative decay.
    q32 = q[0].view(
        segment_count, segment_length, query_heads, key_dim
    ).repeat_interleave(2, dim=2)
    corrected_segments = []
    correction_segments = []
    for segment in range(segment_count):
        exclusive_chunk_prefix = torch.cat(
            [
                torch.zeros(
                    (1, heads), dtype=torch.float32, device=device
                ),
                chunk_last_log_decay[segment, :-1].cumsum(dim=0),
            ],
            dim=0,
        )
        token_log_decay = (
            g_segments[segment]
            + exclusive_chunk_prefix.repeat_interleave(chunk_size, dim=0)
        )
        correction = torch.einsum(
            "thk,hkv->thv",
            q32[segment].float(),
            prefix_states[segment].float(),
        )
        correction.mul_(
            torch.exp(token_log_decay)[:, :, None] * float(scale)
        )
        correction_segments.append(correction)
        local = local_output[
            0,
            segment * segment_length : (segment + 1) * segment_length,
        ]
        corrected_segments.append((local.float() + correction).to(torch.bfloat16))
    correction_output = torch.cat(correction_segments, dim=0).unsqueeze(0)
    segmented_output = torch.cat(corrected_segments, dim=0).unsqueeze(0)
    torch.cuda.synchronize()

    output_by_segment = []
    for segment in range(segment_count):
        sl = slice(segment * segment_length, (segment + 1) * segment_length)
        output_by_segment.append(
            compare(
                segmented_output[:, sl],
                baseline_output[:, sl],
                atol=0.03125,
                rtol=0.01,
                cosine_min=0.9995,
            )
        )

    report = {
        "schema_version": 1,
        "target": architecture,
        "shape": {
            "sequences": 1,
            "tokens": total_tokens,
            "segments": segment_count,
            "segment_tokens": segment_length,
            "heads": heads,
            "query_heads": query_heads,
            "key_dim": key_dim,
            "value_dim": value_dim,
            "chunk_tokens": chunk_size,
        },
        "decomposition": {
            "state_boundary_dtype": "bfloat16",
            "prefix_math": "float32",
            "correction_math": "float32 oracle",
            "local_kernel": fused_kernel,
        },
        "correctness": {
            "baseline_vs_capture_output": compare(
                baseline_output,
                captured_output,
                atol=0.03125,
                rtol=0.01,
                cosine_min=0.9995,
            ),
            "baseline_vs_capture_final_state": compare(
                baseline_state,
                captured_final_state,
                atol=0.125,
                rtol=0.02,
                cosine_min=0.999,
            ),
            "segmented_output_vs_baseline": compare(
                segmented_output,
                baseline_output,
                atol=0.03125,
                rtol=0.01,
                cosine_min=0.9995,
            ),
            "segmented_final_state_vs_baseline": compare(
                segmented_final_state,
                baseline_state,
                atol=0.125,
                rtol=0.02,
                cosine_min=0.999,
            ),
            "output_by_segment": output_by_segment,
            "local_output_vs_baseline": compare(
                local_output,
                baseline_output,
                atol=0.03125,
                rtol=0.01,
                cosine_min=0.9995,
            ),
            "correction_finite": bool(
                torch.isfinite(correction_output).all().item()
            ),
        },
    }
    report["algorithm_gate"] = bool(
        report["correctness"]["baseline_vs_capture_output"]["pass"]
        and report["correctness"]["baseline_vs_capture_final_state"]["pass"]
        and report["correctness"]["segmented_output_vs_baseline"]["pass"]
        and report["correctness"]["segmented_final_state_vs_baseline"]["pass"]
        and all(item["pass"] for item in output_by_segment)
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()

