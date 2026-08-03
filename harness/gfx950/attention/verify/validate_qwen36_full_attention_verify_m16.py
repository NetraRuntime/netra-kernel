#!/usr/bin/env python3
"""Bitwise validation of the raw gfx950 M16 attention path.

The oracle is sixteen calls to the exact deployed SGLang decode-attention
implementation.  The candidate uses the same arithmetic in two raw AMDGCN
launch grids, with per-query sequence lengths and shared KV indices.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import math
from pathlib import Path

import torch

from sglang.srt.layers.attention.triton_ops.decode_attention import (
    decode_attention_fwd,
)


def tensor_hash(tensor: torch.Tensor) -> str:
    raw = tensor.contiguous().view(torch.uint8).cpu().numpy().tobytes()
    return hashlib.sha256(raw).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--prefix-length", type=int, default=257)
    parser.add_argument("--num-splits", type=int, default=4)
    parser.add_argument("--max-splits", type=int, default=129)
    parser.add_argument(
        "--raw-abi",
        choices=("sequence-lengths", "indptr"),
        default="sequence-lengths",
    )
    parser.add_argument("--warmup-iterations", type=int, default=10)
    parser.add_argument("--timed-iterations", type=int, default=100)
    args = parser.parse_args()

    torch.manual_seed(20260731)
    device = torch.device("cuda")
    verify_tokens = 16
    q_heads = 16
    kv_heads = 2
    head_dim = 256
    max_splits = args.max_splits
    max_length = args.prefix_length + verify_tokens

    query = (
        torch.randn(
            (verify_tokens, q_heads, head_dim),
            device=device,
            dtype=torch.float32,
        )
        .mul_(0.25)
        .to(torch.bfloat16)
    )
    key = (
        torch.randn(
            (max_length, kv_heads, head_dim),
            device=device,
            dtype=torch.float32,
        )
        .mul_(0.25)
        .to(torch.float8_e4m3fn)
    )
    value = (
        torch.randn(
            (max_length, kv_heads, head_dim),
            device=device,
            dtype=torch.float32,
        )
        .mul_(0.25)
        .to(torch.float8_e4m3fn)
    )
    kv_indices = torch.arange(max_length, device=device, dtype=torch.int64)
    sequence_lengths = torch.arange(
        args.prefix_length + 1,
        max_length + 1,
        device=device,
        dtype=torch.int32,
    )
    num_splits = torch.full(
        (verify_tokens,), args.num_splits, device=device, dtype=torch.int32
    )
    if args.raw_abi == "indptr":
        raw_lengths = [args.prefix_length + step + 1 for step in range(verify_tokens)]
        raw_indptr = [0]
        for length in raw_lengths:
            raw_indptr.append(raw_indptr[-1] + length)
        raw_length_argument = torch.tensor(
            raw_indptr, device=device, dtype=torch.int32
        )
        raw_kv_indices = torch.cat(
            [
                torch.arange(length, device=device, dtype=torch.int64)
                for length in raw_lengths
            ]
        )
    else:
        raw_length_argument = sequence_lengths
        raw_kv_indices = kv_indices

    oracle = torch.empty_like(query)
    oracle_mid = torch.empty(
        (1, q_heads, max_splits, head_dim),
        device=device,
        dtype=torch.float32,
    )
    oracle_lse = torch.empty(
        (1, q_heads, max_splits), device=device, dtype=torch.float32
    )
    oracle_mid_all = torch.empty(
        (verify_tokens, q_heads, max_splits, head_dim),
        device=device,
        dtype=torch.float32,
    )
    oracle_lse_all = torch.empty(
        (verify_tokens, q_heads, max_splits),
        device=device,
        dtype=torch.float32,
    )
    for step in range(verify_tokens):
        length = args.prefix_length + step + 1
        indptr = torch.tensor([0, length], device=device, dtype=torch.int32)
        decode_attention_fwd(
            query[step : step + 1],
            key,
            value,
            oracle[step : step + 1],
            indptr,
            kv_indices,
            oracle_mid,
            oracle_lse,
            num_splits[step : step + 1],
            max_splits,
            1.0 / math.sqrt(head_dim),
            1.0,
            1.0,
            logit_cap=0.0,
            sinks=None,
            xai_temperature_len=-1,
            has_mla=False,
            use_pdl=False,
        )
        oracle_mid_all[step].copy_(oracle_mid[0])
        oracle_lse_all[step].copy_(oracle_lse[0])

    oracle_indptrs = [
        torch.tensor(
            [0, args.prefix_length + step + 1],
            device=device,
            dtype=torch.int32,
        )
        for step in range(verify_tokens)
    ]

    def launch_oracle() -> None:
        for step in range(verify_tokens):
            decode_attention_fwd(
                query[step : step + 1],
                key,
                value,
                oracle[step : step + 1],
                oracle_indptrs[step],
                kv_indices,
                oracle_mid,
                oracle_lse,
                num_splits[step : step + 1],
                max_splits,
                1.0 / math.sqrt(head_dim),
                1.0,
                1.0,
                logit_cap=0.0,
                sinks=None,
                xai_temperature_len=-1,
                has_mla=False,
                use_pdl=False,
            )

    candidate = torch.empty_like(query)
    candidate_mid = torch.empty(
        (verify_tokens, q_heads, max_splits, head_dim),
        device=device,
        dtype=torch.float32,
    )
    candidate_lse = torch.empty(
        (verify_tokens, q_heads, max_splits),
        device=device,
        dtype=torch.float32,
    )

    library = ctypes.CDLL(
        str(args.build_dir / "libqwen36_full_attention_verify_m16_bridge.so")
    )
    library.netra_qwen36_full_attention_verify_m16_load.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
    ]
    library.netra_qwen36_full_attention_verify_m16_load.restype = ctypes.c_int
    library.netra_qwen36_full_attention_verify_m16_launch.argtypes = [
        *([ctypes.c_void_p] * 9),
        ctypes.c_float,
        ctypes.c_float,
        *([ctypes.c_uint32] * 11),
        ctypes.c_void_p,
    ]
    library.netra_qwen36_full_attention_verify_m16_launch.restype = ctypes.c_int
    library.netra_qwen36_full_attention_verify_m16_last_error.restype = (
        ctypes.c_char_p
    )

    stage1 = args.build_dir / "qwen36_full_attention_verify_m16_stage1_gfx950.hsaco"
    stage2 = args.build_dir / "qwen36_full_attention_verify_m16_stage2_gfx950.hsaco"
    rc = library.netra_qwen36_full_attention_verify_m16_load(
        str(stage1).encode(), str(stage2).encode()
    )
    if rc:
        raise RuntimeError(
            library.netra_qwen36_full_attention_verify_m16_last_error().decode()
        )

    stream = torch.cuda.current_stream()
    launch_args = (
        candidate.data_ptr(),
        query.data_ptr(),
        key.data_ptr(),
        value.data_ptr(),
        raw_length_argument.data_ptr(),
        raw_kv_indices.data_ptr(),
        num_splits.data_ptr(),
        candidate_mid.data_ptr(),
        candidate_lse.data_ptr(),
        1.0 / math.sqrt(head_dim),
        1.0,
        query.stride(0),
        query.stride(1),
        key.stride(0),
        key.stride(1),
        value.stride(0),
        value.stride(1),
        candidate_mid.stride(0),
        candidate_mid.stride(1),
        candidate_mid.stride(2),
        candidate.stride(0),
        candidate.stride(1),
        stream.cuda_stream,
    )
    rc = library.netra_qwen36_full_attention_verify_m16_launch(*launch_args)
    if rc:
        raise RuntimeError(
            library.netra_qwen36_full_attention_verify_m16_last_error().decode()
        )
    torch.cuda.synchronize()

    for _ in range(args.warmup_iterations):
        launch_oracle()
    torch.cuda.synchronize()
    oracle_start = torch.cuda.Event(enable_timing=True)
    oracle_end = torch.cuda.Event(enable_timing=True)
    oracle_start.record()
    for _ in range(args.timed_iterations):
        launch_oracle()
    oracle_end.record()
    oracle_end.synchronize()
    oracle_ms = oracle_start.elapsed_time(oracle_end) / args.timed_iterations

    for _ in range(args.warmup_iterations):
        rc = library.netra_qwen36_full_attention_verify_m16_launch(*launch_args)
        if rc:
            raise RuntimeError(
                library.netra_qwen36_full_attention_verify_m16_last_error().decode()
            )
    torch.cuda.synchronize()
    candidate_start = torch.cuda.Event(enable_timing=True)
    candidate_end = torch.cuda.Event(enable_timing=True)
    candidate_start.record()
    for _ in range(args.timed_iterations):
        rc = library.netra_qwen36_full_attention_verify_m16_launch(*launch_args)
        if rc:
            raise RuntimeError(
                library.netra_qwen36_full_attention_verify_m16_last_error().decode()
            )
    candidate_end.record()
    candidate_end.synchronize()
    candidate_ms = candidate_start.elapsed_time(candidate_end) / args.timed_iterations

    oracle_f32 = oracle.float()
    candidate_f32 = candidate.float()
    abs_error = (oracle_f32 - candidate_f32).abs()
    valid_splits_per_token = []
    oracle_mid_parts = []
    candidate_mid_parts = []
    oracle_lse_parts = []
    candidate_lse_parts = []
    for step in range(verify_tokens):
        length = args.prefix_length + step + 1
        split_span = (
            ((length + args.num_splits - 1) // args.num_splits + 31) // 32
        ) * 32
        valid_splits = min(
            args.num_splits, (length + split_span - 1) // split_span
        )
        valid_splits_per_token.append(valid_splits)
        oracle_mid_parts.append(
            oracle_mid_all[step, :, :valid_splits].reshape(-1)
        )
        candidate_mid_parts.append(
            candidate_mid[step, :, :valid_splits].reshape(-1)
        )
        oracle_lse_parts.append(
            oracle_lse_all[step, :, :valid_splits].reshape(-1)
        )
        candidate_lse_parts.append(
            candidate_lse[step, :, :valid_splits].reshape(-1)
        )
    oracle_mid_valid = torch.cat(oracle_mid_parts)
    candidate_mid_valid = torch.cat(candidate_mid_parts)
    oracle_lse_valid = torch.cat(oracle_lse_parts)
    candidate_lse_valid = torch.cat(candidate_lse_parts)
    mid_abs_error = (oracle_mid_valid - candidate_mid_valid).abs()
    lse_abs_error = (oracle_lse_valid - candidate_lse_valid).abs()
    mismatches = int((oracle.view(torch.uint16) != candidate.view(torch.uint16)).sum())
    per_token_mismatches = [
        int(
            (
                oracle[step].view(torch.uint16)
                != candidate[step].view(torch.uint16)
            ).sum()
        )
        for step in range(verify_tokens)
    ]
    result = {
        "contract": {
            "target": torch.cuda.get_device_properties(0).gcnArchName,
            "verify_tokens": verify_tokens,
            "q_heads": q_heads,
            "kv_heads": kv_heads,
            "head_dim": head_dim,
            "kv_dtype": str(key.dtype),
            "prefix_length": args.prefix_length,
            "num_kv_splits": args.num_splits,
            "max_kv_splits": max_splits,
            "raw_abi": args.raw_abi,
            "valid_splits_per_token": valid_splits_per_token,
        },
        "oracle": "16 sequential deployed SGLang decode_attention_fwd calls",
        "candidate": "raw gfx950 stage1+stage2 shared-index M16 launches",
        "timing": {
            "method": "HIP events on the current stream",
            "warmup_iterations": args.warmup_iterations,
            "timed_iterations": args.timed_iterations,
            "oracle_ms": oracle_ms,
            "candidate_ms": candidate_ms,
            "speedup": oracle_ms / candidate_ms,
        },
        "elements": oracle.numel(),
        "mismatches": mismatches,
        "per_token_mismatches": per_token_mismatches,
        "max_abs_error": float(abs_error.max()),
        "mean_abs_error": float(abs_error.mean()),
        "stage1_mid_max_abs_error": float(
            torch.nan_to_num(mid_abs_error, nan=0.0).max()
        ),
        "stage1_mid_mismatches": int(
            (
                oracle_mid_valid.contiguous().view(torch.uint32)
                != candidate_mid_valid.contiguous().view(torch.uint32)
            ).sum()
        ),
        "stage1_lse_max_abs_error": float(
            torch.nan_to_num(lse_abs_error, nan=0.0).max()
        ),
        "stage1_lse_mismatches": int(
            (
                oracle_lse_valid.contiguous().view(torch.uint32)
                != candidate_lse_valid.contiguous().view(torch.uint32)
            ).sum()
        ),
        "candidate_mid_nonzero": int(torch.count_nonzero(candidate_mid_valid)),
        "candidate_lse_nonzero": int(torch.count_nonzero(candidate_lse_valid)),
        "candidate_output_nonzero": int(torch.count_nonzero(candidate)),
        "candidate_mid_first_values": candidate_mid_valid.flatten()[:8].tolist(),
        "candidate_lse_first_values": candidate_lse_valid.flatten()[:8].tolist(),
        "oracle_first_values": oracle_f32.flatten()[:8].tolist(),
        "candidate_first_values": candidate_f32.flatten()[:8].tolist(),
        "oracle_sha256": tensor_hash(oracle),
        "candidate_sha256": tensor_hash(candidate),
        "pass": mismatches == 0,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    if not result["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
