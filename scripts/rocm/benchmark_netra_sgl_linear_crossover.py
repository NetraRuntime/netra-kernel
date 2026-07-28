#!/usr/bin/env python3
"""Measure the raw gfx1151 dense MXFP4 decode/prefill crossover."""

import ctypes
import json
from pathlib import Path

import torch
from safetensors import safe_open


MODEL = Path("/root/models/qwen36-mxfp4")
LIB = "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so"
KEY = "model.language_model.layers.0.linear_attn.in_proj_qkv.weight"


def ptr(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def load_tensor(key: str) -> torch.Tensor:
    index = json.loads((MODEL / "model.safetensors.index.json").read_text())
    with safe_open(MODEL / index["weight_map"][key], framework="pt") as f:
        return f.get_tensor(key)


def elapsed_us(fn, warmup: int = 20, repeats: int = 100) -> float:
    for _ in range(warmup):
        fn()
    torch.cuda.synchronize()
    start = torch.cuda.Event(enable_timing=True)
    stop = torch.cuda.Event(enable_timing=True)
    start.record()
    for _ in range(repeats):
        fn()
    stop.record()
    stop.synchronize()
    return start.elapsed_time(stop) * 1000.0 / repeats


def main() -> None:
    packed_cpu = load_tensor(KEY + "_packed")
    scales_cpu = load_tensor(KEY + "_scale")
    packed = packed_cpu.t().contiguous().cuda()
    scales = scales_cpu.t().contiguous().cuda()
    n, packed_k = packed_cpu.shape
    k = packed_k * 2

    lib = ctypes.CDLL(LIB)
    lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
    lib.netra_mxfp4_sgl_linear.argtypes = (
        [ctypes.c_void_p] * 4
        + [ctypes.c_uint] * 3
        + [ctypes.c_void_p]
    )
    lib.netra_mxfp4_sgl_linear.restype = ctypes.c_int
    lib.netra_mxfp4_sgl_linear_prefill.argtypes = (
        [ctypes.c_void_p] * 4
        + [ctypes.c_uint] * 3
        + [ctypes.c_void_p]
    )
    lib.netra_mxfp4_sgl_linear_prefill.restype = ctypes.c_int
    if lib.netra_mxfp4_sgl_init():
        raise RuntimeError("Netra raw-ASM runtime init failed")

    stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
    rows = [2, 4, 8, 12, 25, 36, 64, 65, 128, 210]
    results = []
    for m in rows:
        x = torch.randn((m, k), dtype=torch.bfloat16, device="cuda")
        decode_y = torch.empty((m, n), dtype=torch.bfloat16, device="cuda")
        groups = (m + 63) // 64
        grouped_x = torch.zeros(
            (groups, 64, k), dtype=torch.bfloat16, device="cuda"
        )
        grouped_x.view(-1, k)[:m].copy_(x)
        prefill_y = torch.empty(
            (groups, 64, n), dtype=torch.float32, device="cuda"
        )

        def decode() -> None:
            status = lib.netra_mxfp4_sgl_linear(
                ptr(packed), ptr(scales), ptr(x), ptr(decode_y), m, n, k, stream
            )
            if status:
                raise RuntimeError(f"decode launch failed: {status}")

        def prefill() -> None:
            status = lib.netra_mxfp4_sgl_linear_prefill(
                ptr(packed),
                ptr(scales),
                ptr(grouped_x),
                ptr(prefill_y),
                groups,
                n,
                k,
                stream,
            )
            if status:
                raise RuntimeError(f"prefill launch failed: {status}")

        decode_us = elapsed_us(decode)
        prefill_us = elapsed_us(prefill)
        results.append(
            {
                "m": m,
                "decode_row_loop_us": decode_us,
                "prefill_m64_us": prefill_us,
                "speedup": decode_us / prefill_us,
            }
        )
    print(
        json.dumps(
            {
                "device": torch.cuda.get_device_properties(0).gcnArchName,
                "shape_nk": [n, k],
                "timing": "HIP events; cache-resident crossover diagnostic",
                "results": results,
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
