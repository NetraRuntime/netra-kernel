#!/usr/bin/env python3
"""Graph capture/replay gate for raw gfx1151 extend attention."""
from __future__ import annotations

import argparse
import ctypes
import json
import socket
import statistics
import time
from pathlib import Path

import torch


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tokens", type=int, default=8192)
    parser.add_argument("--replay-prefix", type=int, default=8192)
    parser.add_argument("--samples", type=int, default=11)
    parser.add_argument("--seed", type=int, default=20260730)
    parser.add_argument("--library", type=Path, default=Path("build/sglang/libextend_attention_wmma.so"))
    parser.add_argument("--hsaco", type=Path, default=Path("build/sglang/extend_attention_wmma_n64_gfx1151.hsaco"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if socket.gethostname() != "Netra":
        raise SystemExit("refusing to run outside the Netra LXC")
    if args.tokens <= 0 or args.tokens % 64 or args.replay_prefix < 0:
        raise SystemExit("tokens must be a positive multiple of 64 and prefix nonnegative")

    lib = ctypes.CDLL(str(args.library.resolve()))
    lib.netra_extend_attention_wmma_init.argtypes = [ctypes.c_char_p]
    lib.netra_extend_attention_wmma_init.restype = ctypes.c_int
    launch = lib.netra_extend_attention_wmma
    launch.argtypes = [ctypes.c_void_p] * 8 + [ctypes.c_uint32, ctypes.c_float, ctypes.c_void_p]
    launch.restype = ctypes.c_int
    status = lib.netra_extend_attention_wmma_init(str(args.hsaco.resolve()).encode())
    if status:
        raise RuntimeError(f"hipModuleLoad/GetFunction failed: {status}")

    torch.manual_seed(args.seed)
    q = (torch.randn((args.tokens, 16, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
    k = (torch.randn((args.tokens, 2, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
    v = (torch.randn_like(k) * 0.02).contiguous()
    rows = max(args.replay_prefix, 1)
    k_buffer = (torch.randn((rows, 2, 256), device="cuda", dtype=torch.bfloat16) * 0.02).contiguous()
    v_buffer = (torch.randn_like(k_buffer) * 0.02).contiguous()
    indices = torch.arange(args.replay_prefix, device="cuda", dtype=torch.int64)
    indptr = torch.tensor([0, 0], device="cuda", dtype=torch.int32)
    eager0 = torch.empty_like(q)
    eager_prefix = torch.empty_like(q)
    graph_output = torch.empty_like(q)

    def call(output: torch.Tensor) -> None:
        stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
        result = launch(
            q.data_ptr(), k.data_ptr(), v.data_ptr(), output.data_ptr(),
            k_buffer.data_ptr(), v_buffer.data_ptr(), indices.data_ptr(),
            indptr.data_ptr(), args.tokens, 0.0625, stream,
        )
        if result:
            raise RuntimeError(f"raw launch failed: {result}")

    pointers_before = [tensor.data_ptr() for tensor in (q, k, v, k_buffer, v_buffer, indices, indptr, graph_output)]
    call(eager0)
    torch.cuda.synchronize()
    allocated_before = torch.cuda.memory_allocated()
    reserved_before = torch.cuda.memory_reserved()
    graph = torch.cuda.CUDAGraph()
    capture_start = time.perf_counter_ns()
    with torch.cuda.graph(graph):
        call(graph_output)
    torch.cuda.synchronize()
    capture_host_ms = (time.perf_counter_ns() - capture_start) / 1e6
    allocated_after = torch.cuda.memory_allocated()
    reserved_after = torch.cuda.memory_reserved()
    graph.replay()
    torch.cuda.synchronize()
    equal_zero = torch.equal(eager0, graph_output)

    indptr[1].fill_(args.replay_prefix)
    call(eager_prefix)
    torch.cuda.synchronize()
    graph.replay()
    torch.cuda.synchronize()
    equal_prefix = torch.equal(eager_prefix, graph_output)
    pointers_after = [tensor.data_ptr() for tensor in (q, k, v, k_buffer, v_buffer, indices, indptr, graph_output)]

    for _ in range(3):
        graph.replay()
    torch.cuda.synchronize()
    samples = []
    for _ in range(args.samples):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        graph.replay()
        end.record()
        end.synchronize()
        samples.append(begin.elapsed_time(end))

    report = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "estimated_values": False,
        "tokens": args.tokens,
        "capture_prefix_tokens": 0,
        "replay_prefix_tokens": args.replay_prefix,
        "stable_device_pointers": pointers_before == pointers_after,
        "eager_equal_replay_prefix0": bool(equal_zero),
        "eager_equal_replay_prefix": bool(equal_prefix),
        "graph_capture_host_ms": capture_host_ms,
        "graph_memory_allocated_delta_bytes": allocated_after - allocated_before,
        "graph_memory_reserved_delta_bytes": reserved_after - reserved_before,
        "graph_replay_hip_event_ms": samples,
        "graph_replay_median_hip_event_ms": statistics.median(samples),
    }
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
