#!/usr/bin/env python3
"""Correctness and HIP-event oracle for raw gfx1151 extend attention."""
from __future__ import annotations

import argparse
import ctypes
import importlib
import json
import statistics
from pathlib import Path

import torch


def event_samples(call, warmup: int, repetitions: int) -> list[float]:
    for _ in range(warmup):
        call()
    torch.cuda.synchronize()
    rows = []
    for _ in range(repetitions):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        call()
        end.record()
        end.synchronize()
        rows.append(start.elapsed_time(end))
    return rows


def fp32_reference(q, k, v, k_buffer, v_buffer, prefix: int) -> torch.Tensor:
    tokens = q.shape[0]
    output = torch.empty_like(q, dtype=torch.float32)
    mask = torch.arange(prefix + tokens, device=q.device)[None, :] <= (
        prefix + torch.arange(tokens, device=q.device)[:, None]
    )
    for head in range(16):
        kv_head = head // 8
        keys = torch.cat((k_buffer[:prefix, kv_head], k[:, kv_head])).float()
        values = torch.cat((v_buffer[:prefix, kv_head], v[:, kv_head])).float()
        scores = q[:, head].float() @ keys.T
        scores = scores.mul_(0.0625).masked_fill_(~mask, -float("inf"))
        output[:, head] = torch.softmax(scores, dim=-1) @ values
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tokens", type=int, default=64)
    parser.add_argument("--prefix", type=int, nargs="+", default=[0, 64])
    parser.add_argument("--warmup", type=int, default=2)
    parser.add_argument("--repetitions", type=int, default=5)
    parser.add_argument("--graph-repetitions", type=int, default=10)
    parser.add_argument("--library", type=Path, default=Path("build/sglang/libextend_attention_wmma.so"))
    parser.add_argument("--hsaco", type=Path, default=Path("build/sglang/extend_attention_wmma_n64_gfx1151.hsaco"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.tokens % 64:
        raise SystemExit("raw specialization requires tokens divisible by 64")

    lib = ctypes.CDLL(str(args.library.resolve()))
    lib.netra_extend_attention_wmma_init.argtypes = [ctypes.c_char_p]
    lib.netra_extend_attention_wmma_init.restype = ctypes.c_int
    launch = lib.netra_extend_attention_wmma
    launch.argtypes = [ctypes.c_void_p] * 8 + [ctypes.c_uint32, ctypes.c_float, ctypes.c_void_p]
    launch.restype = ctypes.c_int
    status = lib.netra_extend_attention_wmma_init(str(args.hsaco.resolve()).encode())
    if status:
        raise RuntimeError(f"hipModuleLoad/GetFunction failed: {status}")

    triton_attention = importlib.import_module("sglang.kernels.ops.attention.extend_attention")
    torch.manual_seed(20260729)
    rows = []
    for prefix in args.prefix:
        q = (torch.randn((args.tokens, 16, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
        k = (torch.randn((args.tokens, 2, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
        v = (torch.randn((args.tokens, 2, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
        k_buffer = (torch.randn((max(prefix, 1), 2, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
        v_buffer = (torch.randn_like(k_buffer) * 0.02).contiguous()
        indices = torch.arange(prefix, device="cuda", dtype=torch.int64)
        raw = torch.empty_like(q)
        triton = torch.empty_like(q)
        qo_indptr = torch.tensor([0, args.tokens], device="cuda", dtype=torch.int64)
        kv_indptr = torch.tensor([0, prefix], device="cuda", dtype=torch.int32)

        def raw_call() -> None:
            result = launch(q.data_ptr(), k.data_ptr(), v.data_ptr(), raw.data_ptr(),
                            k_buffer.data_ptr(), v_buffer.data_ptr(), indices.data_ptr(),
                            kv_indptr.data_ptr(), args.tokens, 0.0625,
                            torch.cuda.current_stream().cuda_stream)
            if result:
                raise RuntimeError(f"raw launch failed: {result}")

        def triton_call() -> None:
            triton_attention.extend_attention_fwd(
                q, k, v, triton, k_buffer, v_buffer, qo_indptr, kv_indptr,
                indices, None, True, None, args.tokens, 1.0, 1.0, 0.0625
            )

        raw_samples = event_samples(raw_call, args.warmup, args.repetitions)
        triton_samples = event_samples(triton_call, args.warmup, args.repetitions)
        eager_raw = raw.clone()
        graph = torch.cuda.CUDAGraph()
        raw_call()
        torch.cuda.synchronize()
        with torch.cuda.graph(graph):
            raw_call()
        graph.replay()
        torch.cuda.synchronize()
        graph_samples = event_samples(graph.replay, args.warmup, args.graph_repetitions)
        graph_raw = raw.clone()
        reference = fp32_reference(q, k, v, k_buffer, v_buffer, prefix)
        raw_delta = raw.float() - reference
        triton_delta = triton.float() - reference
        row = {
            "target": "gfx1151",
            "measurement_status": "measured_hip_events",
            "tokens": args.tokens,
            "prefix_tokens": prefix,
            "raw_hip_event_ms": raw_samples,
            "raw_median_ms": statistics.median(raw_samples),
            "triton_hip_event_ms": triton_samples,
            "triton_median_ms": statistics.median(triton_samples),
            "graph_replay_hip_event_ms": graph_samples,
            "graph_replay_median_ms": statistics.median(graph_samples),
            "raw_max_abs_vs_fp32": raw_delta.abs().max().item(),
            "raw_normalized_l2_vs_fp32": raw_delta.norm().item() / reference.norm().item(),
            "triton_max_abs_vs_fp32": triton_delta.abs().max().item(),
            "triton_normalized_l2_vs_fp32": triton_delta.norm().item() / reference.norm().item(),
            "raw_max_abs_vs_triton": (raw.float() - triton.float()).abs().max().item(),
            "graph_raw_max_abs_vs_eager": (graph_raw.float() - eager_raw.float()).abs().max().item(),
        }
        row["speedup_vs_triton"] = row["triton_median_ms"] / row["raw_median_ms"]
        rows.append(row)
        print(json.dumps(row, indent=2))

    result = {"target": "gfx1151", "measurement_status": "measured", "rows": rows, "estimated_values": False}
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
