#!/usr/bin/env python3
"""Validate and time raw gfx950 Qwen3.6 verification argmax at live shapes."""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import statistics
from pathlib import Path
from typing import Callable

import torch


COLS = 248320
CHUNKS = 128


def tensor_hash(tensor: torch.Tensor) -> str:
    return hashlib.sha256(
        tensor.contiguous().view(torch.uint8).cpu().numpy().tobytes()
    ).hexdigest()


def timing(operation: Callable[[], torch.Tensor], repeats: int) -> dict[str, float]:
    for _ in range(20):
        operation()
    torch.cuda.synchronize()
    samples: list[float] = []
    for _ in range(repeats):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        operation()
        end.record()
        end.synchronize()
        samples.append(begin.elapsed_time(end) * 1000.0)
    samples.sort()
    return {
        "minimum_us": samples[0],
        "median_us": statistics.median(samples),
        "p90_us": samples[int(0.9 * (len(samples) - 1))],
        "maximum_us": samples[-1],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--rows", type=int, default=768)
    parser.add_argument("--repeats", type=int, default=200)
    args = parser.parse_args()
    if args.rows < 1 or args.rows > 4096:
        raise ValueError("rows must be in [1, 4096]")

    properties = torch.cuda.get_device_properties(0)
    if "gfx950" not in properties.gcnArchName:
        raise RuntimeError(f"gfx950 required; got {properties.gcnArchName}")

    torch.manual_seed(20260804)
    logits = torch.randn(
        (args.rows, COLS), device="cuda", dtype=torch.float32
    ).contiguous()
    # Preserve the edge cases used by the accepted fixed-row harness.
    if args.rows >= 1:
        logits[0, 3] = 1000.0
        logits[0, 200000] = 1000.0
    if args.rows >= 2:
        logits[1].fill_(-0.0)
        logits[1, 1] = 0.0
    if args.rows >= 3:
        logits[2, 17] = float("inf")
        logits[2, 100000] = float("inf")
    if args.rows >= 4:
        logits[3, 12345] = float("nan")
        logits[3, 12000] = float("nan")

    output = torch.empty((args.rows,), device="cuda", dtype=torch.int64)
    partials = torch.empty(
        (args.rows, CHUNKS, 2), device="cuda", dtype=torch.int32
    )
    bridge = args.build_dir / "libqwen36_argmax_f32_bridge.so"
    hsaco = args.build_dir / "qwen36_argmax_f32_gfx950.hsaco"
    library = ctypes.CDLL(str(bridge.resolve()))
    library.netra_qwen36_argmax_f32_load.argtypes = [ctypes.c_char_p]
    library.netra_qwen36_argmax_f32_load.restype = ctypes.c_int
    library.netra_qwen36_argmax_f32_launch.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_uint32,
        ctypes.c_void_p,
    ]
    library.netra_qwen36_argmax_f32_launch.restype = ctypes.c_int
    library.netra_qwen36_argmax_f32_last_error.restype = ctypes.c_char_p
    status = library.netra_qwen36_argmax_f32_load(str(hsaco.resolve()).encode())
    if status:
        raise RuntimeError(library.netra_qwen36_argmax_f32_last_error().decode())

    def raw() -> torch.Tensor:
        stream = torch.cuda.current_stream()
        status = library.netra_qwen36_argmax_f32_launch(
            output.data_ptr(),
            partials.data_ptr(),
            logits.data_ptr(),
            args.rows,
            stream.cuda_stream,
        )
        if status:
            raise RuntimeError(
                library.netra_qwen36_argmax_f32_last_error().decode()
            )
        return output

    def control() -> torch.Tensor:
        return torch.argmax(logits, dim=-1)

    reference = control()
    actual = raw().clone()
    torch.cuda.synchronize()
    mismatch_count = int((actual != reference).sum().item())

    graph = torch.cuda.CUDAGraph()
    raw()
    torch.cuda.synchronize()
    with torch.cuda.graph(graph):
        raw()
    graph.replay()
    graph_actual = output.clone()
    torch.cuda.synchronize()
    graph_exact = bool(torch.equal(graph_actual, reference))

    result = {
        "contract": {
            "target": properties.gcnArchName,
            "wavefront_size": 64,
            "rows": args.rows,
            "cols": COLS,
            "chunks": CHUNKS,
            "dtype": str(logits.dtype),
        },
        "correctness": {
            "mismatches": mismatch_count,
            "graph_exact": graph_exact,
            "raw_sha256": tensor_hash(actual),
            "control_sha256": tensor_hash(reference),
        },
        "hip_event_timing": {
            "raw": timing(raw, args.repeats),
            "torch_argmax": timing(control, args.repeats),
            "repeats": args.repeats,
        },
        "pass": mismatch_count == 0 and graph_exact,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    if not result["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
