#!/usr/bin/env python3
"""Compare two raw gfx1151 extend-attention kernels with an FP64 oracle."""
from __future__ import annotations

import argparse
import ctypes
import json
from pathlib import Path

import torch


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def load(library: Path, hsaco: Path):
    handle = ctypes.CDLL(str(library.resolve()))
    init = handle.netra_extend_attention_wmma_init
    init.argtypes = [ctypes.c_char_p]
    init.restype = ctypes.c_int
    status = init(str(hsaco.resolve()).encode())
    if status:
        raise RuntimeError(f"failed to load {hsaco}: HIP status {status}")
    launch = handle.netra_extend_attention_wmma
    launch.argtypes = [ctypes.c_void_p] * 8 + [
        ctypes.c_uint32,
        ctypes.c_float,
        ctypes.c_void_p,
    ]
    launch.restype = ctypes.c_int
    return handle, launch


def fp64_reference(
    q: torch.Tensor,
    k_extend: torch.Tensor,
    v_extend: torch.Tensor,
    k_cache: torch.Tensor,
    v_cache: torch.Tensor,
    prefix: int,
    scale: float,
) -> torch.Tensor:
    tokens = q.shape[0]
    q_cpu = q.cpu().double()
    k_extend_cpu = k_extend.cpu().double()
    v_extend_cpu = v_extend.cpu().double()
    k_cache_cpu = k_cache.cpu().double()
    v_cache_cpu = v_cache.cpu().double()
    reference = torch.empty((tokens, 16, 256), dtype=torch.float64)
    positions = torch.arange(prefix + tokens)
    causal = positions[None, :] <= (prefix + torch.arange(tokens))[:, None]
    for query_head in range(16):
        kv_head = query_head // 8
        keys = torch.cat(
            (k_cache_cpu[:prefix, kv_head], k_extend_cpu[:, kv_head]), dim=0
        )
        values = torch.cat(
            (v_cache_cpu[:prefix, kv_head], v_extend_cpu[:, kv_head]), dim=0
        )
        scores = q_cpu[:, query_head] @ keys.T * scale
        probabilities = torch.softmax(
            scores.masked_fill(~causal, float("-inf")), dim=-1
        )
        reference[:, query_head] = probabilities @ values
    return reference


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline-library", type=Path, required=True)
    parser.add_argument("--baseline-hsaco", type=Path, required=True)
    parser.add_argument("--candidate-library", type=Path, required=True)
    parser.add_argument("--candidate-hsaco", type=Path, required=True)
    parser.add_argument("--candidate-label", default="candidate")
    parser.add_argument("--tokens", type=int, default=256)
    parser.add_argument("--prefix", type=int, default=128)
    parser.add_argument("--amplitude", type=float, nargs="+", default=[0.02, 1.0, 2.0])
    parser.add_argument("--scale", type=float, default=0.0625)
    parser.add_argument("--seed", type=int, default=20260730)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.tokens <= 0 or args.tokens > 512 or args.tokens % 64:
        raise SystemExit("tokens must be a multiple of 64 and at most 512")
    if args.prefix < 0 or args.prefix > 512:
        raise SystemExit("prefix must be between zero and 512")

    baseline_handle, baseline = load(args.baseline_library, args.baseline_hsaco)
    candidate_handle, candidate = load(args.candidate_library, args.candidate_hsaco)
    assert baseline_handle and candidate_handle
    stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
    rows = []
    for amplitude in args.amplitude:
        torch.manual_seed(args.seed + args.tokens + args.prefix)
        q = (torch.randn((args.tokens, 16, 256), device="cuda") * amplitude).to(
            torch.bfloat16
        ).contiguous()
        k_extend = (
            torch.randn((args.tokens, 2, 256), device="cuda") * amplitude
        ).to(torch.bfloat16).contiguous()
        v_extend = torch.randn(
            (args.tokens, 2, 256), device="cuda", dtype=torch.bfloat16
        ).contiguous()
        cache_tokens = max(args.prefix, 1)
        k_cache = (
            torch.randn((cache_tokens, 2, 256), device="cuda") * amplitude
        ).to(torch.bfloat16).contiguous()
        v_cache = torch.randn(
            (cache_tokens, 2, 256), device="cuda", dtype=torch.bfloat16
        ).contiguous()
        indices = torch.arange(args.prefix, device="cuda", dtype=torch.int64)
        indptr = torch.tensor([0, args.prefix], device="cuda", dtype=torch.int32)
        outputs = []
        for function in (baseline, candidate):
            output = torch.empty_like(q)
            status = function(
                pointer(q),
                pointer(k_extend),
                pointer(v_extend),
                pointer(output),
                pointer(k_cache),
                pointer(v_cache),
                pointer(indices),
                pointer(indptr),
                args.tokens,
                args.scale,
                stream,
            )
            if status:
                raise RuntimeError(f"raw launch failed: HIP status {status}")
            outputs.append(output)
        torch.cuda.synchronize()
        reference = fp64_reference(
            q, k_extend, v_extend, k_cache, v_cache, args.prefix, args.scale
        )
        row = {
            "amplitude": amplitude,
            "output_bit_equal": bool(torch.equal(outputs[0], outputs[1])),
        }
        for label, output in zip(("baseline", args.candidate_label), outputs):
            delta = (output.cpu().double() - reference).abs()
            row[label] = {
                "max_abs": delta.max().item(),
                "mean_abs": delta.mean().item(),
                "rmse": delta.square().mean().sqrt().item(),
            }
        rows.append(row)
        print(json.dumps(row), flush=True)

    result = {
        "target": "gfx1151",
        "measurement_status": "measured_kernel_outputs_with_fp64_cpu_reference",
        "estimated_values": False,
        "tokens": args.tokens,
        "prefix_tokens": args.prefix,
        "Hq": 16,
        "Hkv": 2,
        "head_dim": 256,
        "dtype": "BF16 inputs and outputs",
        "reference_dtype": "FP64",
        "scale": args.scale,
        "candidate_label": args.candidate_label,
        "rows": rows,
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
