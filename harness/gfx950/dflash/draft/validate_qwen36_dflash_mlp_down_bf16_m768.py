#!/usr/bin/env python3
"""Validate/time raw gfx950 Qwen3.6 dFlash M768 MLP down projection."""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import statistics
from pathlib import Path
from typing import Callable

import torch
from safetensors import safe_open

M = 768
K = 6144
N = 2048
WEIGHT_KEY = "layers.0.mlp.down_proj.weight"


def sha256_tensor(tensor: torch.Tensor) -> str:
    return hashlib.sha256(
        tensor.contiguous().view(torch.uint8).cpu().numpy().tobytes()
    ).hexdigest()


def timing(operation: Callable[[], torch.Tensor], repeats: int) -> dict[str, float]:
    for _ in range(20):
        operation()
    torch.cuda.synchronize()
    values: list[float] = []
    for _ in range(repeats):
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        start.record()
        operation()
        stop.record()
        stop.synchronize()
        values.append(start.elapsed_time(stop) * 1000.0)
    values.sort()
    return {
        "minimum_us": values[0],
        "median_us": statistics.median(values),
        "p90_us": values[int(0.9 * (len(values) - 1))],
        "maximum_us": values[-1],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repeats", type=int, default=200)
    args = parser.parse_args()

    properties = torch.cuda.get_device_properties(0)
    if "gfx950" not in properties.gcnArchName:
        raise RuntimeError(f"gfx950 required; got {properties.gcnArchName}")
    with safe_open(args.checkpoint, framework="pt", device="cpu") as file:
        weight = file.get_tensor(WEIGHT_KEY).cuda()
    if tuple(weight.shape) != (N, K) or weight.dtype != torch.bfloat16:
        raise RuntimeError(f"unexpected weight: {weight.shape} {weight.dtype}")
    torch.manual_seed(20260804)
    input_ = (
        torch.randn((M, K), device="cuda", dtype=torch.float32)
        .mul_(0.25)
        .to(torch.bfloat16)
    )
    output = torch.empty((M, N), device="cuda", dtype=torch.bfloat16)

    bridge = args.build_dir / "libqwen36_dflash_mlp_down_bf16_m768_bridge.so"
    hsaco = (
        args.build_dir
        / "qwen36_dflash_mlp_down_bf16_m768_m64n64_global_gfx950.hsaco"
    )
    library = ctypes.CDLL(str(bridge.resolve()))
    library.netra_qwen36_dflash_mlp_down_bf16_m768_load.argtypes = [ctypes.c_char_p]
    library.netra_qwen36_dflash_mlp_down_bf16_m768_load.restype = ctypes.c_int
    library.netra_qwen36_dflash_mlp_down_bf16_m768_launch.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
    ]
    library.netra_qwen36_dflash_mlp_down_bf16_m768_launch.restype = ctypes.c_int
    library.netra_qwen36_dflash_mlp_down_bf16_m768_last_error.restype = ctypes.c_char_p
    rc = library.netra_qwen36_dflash_mlp_down_bf16_m768_load(
        str(hsaco.resolve()).encode()
    )
    if rc:
        raise RuntimeError(
            library.netra_qwen36_dflash_mlp_down_bf16_m768_last_error().decode()
        )
    def raw() -> torch.Tensor:
        stream = torch.cuda.current_stream()
        rc = library.netra_qwen36_dflash_mlp_down_bf16_m768_launch(
            output.data_ptr(), input_.data_ptr(), weight.data_ptr(), stream.cuda_stream
        )
        if rc:
            raise RuntimeError(
                library.netra_qwen36_dflash_mlp_down_bf16_m768_last_error().decode()
            )
        return output

    def baseline() -> torch.Tensor:
        return torch.nn.functional.linear(input_, weight)

    expected = baseline()
    actual = raw().clone()
    torch.cuda.synchronize()
    different = actual.view(torch.uint16) != expected.view(torch.uint16)
    absolute = (actual.float() - expected.float()).abs()

    graph_output = torch.empty_like(output)
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        capture_stream = torch.cuda.current_stream()
        rc = library.netra_qwen36_dflash_mlp_down_bf16_m768_launch(
            graph_output.data_ptr(),
            input_.data_ptr(),
            weight.data_ptr(),
            capture_stream.cuda_stream,
        )
        if rc:
            raise RuntimeError(
                library.netra_qwen36_dflash_mlp_down_bf16_m768_last_error().decode()
            )
    graph.replay()
    torch.cuda.synchronize()

    result = {
        "contract": {
            "target": properties.gcnArchName,
            "wavefront_size": properties.warp_size,
            "m": M,
            "n": N,
            "k": K,
            "weight_key": WEIGHT_KEY,
            "weight_dtype": str(weight.dtype),
        },
        "correctness": {
            "elements": actual.numel(),
            "bf16_mismatches": int(different.sum()),
            "max_abs_error": float(absolute.max()),
            "mean_abs_error": float(absolute.mean()),
            "raw_sha256": sha256_tensor(actual),
            "baseline_sha256": sha256_tensor(expected),
            "graph_exact": bool(torch.equal(graph_output, actual)),
        },
        "hip_event_timing": {
            "raw": timing(raw, args.repeats),
            "torch_linear": timing(baseline, args.repeats),
            "repeats": args.repeats,
        },
    }
    result["pass"] = (
        result["correctness"]["bf16_mismatches"] == 0
        and result["correctness"]["graph_exact"]
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    if not result["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
