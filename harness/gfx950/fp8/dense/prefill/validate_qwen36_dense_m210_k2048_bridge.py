#!/usr/bin/env python3
"""Validate the gfx950 dense M=210 K=2048 bridge on captured operands."""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import statistics
from pathlib import Path

import torch


M = 210
K = 2048


def tensor_from_bytes(
    path: Path, dtype: torch.dtype, shape: tuple[int, ...]
) -> torch.Tensor:
    payload = bytearray(path.read_bytes())
    tensor = torch.frombuffer(payload, dtype=torch.uint8).clone().view(dtype)
    return tensor.reshape(shape)


def sha256(tensor: torch.Tensor) -> str:
    return hashlib.sha256(
        tensor.detach()
        .contiguous()
        .cpu()
        .view(torch.uint8)
        .numpy()
        .tobytes()
    ).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path, required=True)
    parser.add_argument("--capture", type=Path, required=True)
    parser.add_argument("--n", type=int, choices=(9216, 12288), required=True)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--graph-replays", type=int, default=20)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    arch = torch.cuda.get_device_properties(0).gcnArchName.split(":", 1)[0]
    if arch != "gfx950":
        raise RuntimeError(f"Expected gfx950, got {arch}")
    n = args.n
    q_input = tensor_from_bytes(
        args.capture / "q_input.bin", torch.float8_e4m3fn, (M, K)
    ).cuda()
    x_scale = tensor_from_bytes(
        args.capture / "x_scale.bin", torch.float32, (M, K // 128)
    ).cuda()
    weight = tensor_from_bytes(
        args.capture / "weight.bin", torch.float8_e4m3fn, (n, K)
    ).cuda()
    weight_scale = tensor_from_bytes(
        args.capture / "weight_scale.bin",
        torch.float32,
        (n // 128, K // 128),
    ).cuda()
    expected = tensor_from_bytes(
        args.capture / "cktile_output_bf16.bin",
        torch.bfloat16,
        (M, n),
    ).cuda()
    output = torch.empty_like(expected)

    library = ctypes.CDLL(str(args.bridge))
    library.netra_qwen36_dense_m210_k2048_load.argtypes = [ctypes.c_char_p]
    library.netra_qwen36_dense_m210_k2048_load.restype = ctypes.c_int
    library.netra_qwen36_dense_m210_k2048_launch.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_uint,
        ctypes.c_void_p,
    ]
    library.netra_qwen36_dense_m210_k2048_launch.restype = ctypes.c_int
    library.netra_qwen36_dense_m210_k2048_last_error.argtypes = []
    library.netra_qwen36_dense_m210_k2048_last_error.restype = ctypes.c_char_p

    def check(status: int) -> None:
        if status == 0:
            return
        error = library.netra_qwen36_dense_m210_k2048_last_error()
        raise RuntimeError(error.decode() if error else f"status={status}")

    check(
        library.netra_qwen36_dense_m210_k2048_load(
            str(args.hsaco).encode()
        )
    )

    def launch() -> None:
        check(
            library.netra_qwen36_dense_m210_k2048_launch(
                ctypes.c_void_p(q_input.data_ptr()),
                ctypes.c_void_p(x_scale.data_ptr()),
                ctypes.c_void_p(weight.data_ptr()),
                ctypes.c_void_p(weight_scale.data_ptr()),
                ctypes.c_void_p(output.data_ptr()),
                n,
                ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
            )
        )

    for _ in range(10):
        launch()
    torch.cuda.synchronize()
    durations: list[float] = []
    hashes: list[str] = []
    for _ in range(args.iterations):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        launch()
        end.record()
        end.synchronize()
        durations.append(start.elapsed_time(end) * 1000.0)
        hashes.append(sha256(output))

    eager = output.detach().clone()
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        launch()
    graph_hashes: list[str] = []
    for _ in range(args.graph_replays):
        graph.replay()
        torch.cuda.synchronize()
        graph_hashes.append(sha256(output))

    delta = (output.float() - expected.float()).abs()
    report = {
        "schema_version": 1,
        "architecture": arch,
        "rocm": torch.version.hip,
        "shape": {"m": M, "n": n, "k": K},
        "quantization": "FP8 E4M3, 128x128 weights, per-row 1x128 activations",
        "iterations": args.iterations,
        "unique_eager_hashes": len(set(hashes)),
        "unique_graph_hashes": len(set(graph_hashes)),
        "graph_replays": args.graph_replays,
        "graph_matches_eager": bool(torch.equal(output, eager)),
        "cktile_bf16_mismatches": int(torch.ne(output, expected).sum().item()),
        "maximum_abs_error_cktile": float(delta.max().item()),
        "output_sha256": sha256(output),
        "expected_sha256": sha256(expected),
        "duration_us": {
            "minimum": min(durations),
            "median": statistics.median(durations),
            "maximum": max(durations),
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, indent=2, sort_keys=True))
    if (
        report["unique_eager_hashes"] != 1
        or report["unique_graph_hashes"] != 1
        or not report["graph_matches_eager"]
        or report["cktile_bf16_mismatches"] != 0
    ):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
