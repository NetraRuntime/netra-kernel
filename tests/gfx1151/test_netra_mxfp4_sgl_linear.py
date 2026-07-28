#!/usr/bin/env python3
"""Validate the raw gfx1151 MXFP4 SGL linear ABI on a real projection."""

import ctypes
import json
import os
from pathlib import Path

import torch
from safetensors import safe_open


MODEL = Path("/root/models/qwen36-mxfp4")
LIB = "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so"
KEY = "model.language_model.layers.0.linear_attn.in_proj_qkv.weight"


def load_tensor(key: str) -> torch.Tensor:
    index = json.loads((MODEL / "model.safetensors.index.json").read_text())
    with safe_open(MODEL / index["weight_map"][key], framework="pt") as f:
        return f.get_tensor(key)


def dequant(packed: torch.Tensor, scales: torch.Tensor) -> torch.Tensor:
    lut = torch.tensor([0, 0.5, 1, 1.5, 2, 3, 4, 6], dtype=torch.float64)
    low = packed & 15
    high = packed >> 4
    low_v = lut[(low & 7).long()] * torch.where((low & 8) != 0, -1.0, 1.0)
    high_v = lut[(high & 7).long()] * torch.where((high & 8) != 0, -1.0, 1.0)
    values = torch.stack((low_v, high_v), dim=-1).flatten(-2)
    return values * torch.exp2(scales.to(torch.float64) - 127).repeat_interleave(
        32, dim=-1
    )


def ptr(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def main() -> None:
    packed_cpu = load_tensor(KEY + "_packed")
    scales_cpu = load_tensor(KEY + "_scale")
    test_n = int(os.environ.get("NETRA_TEST_N", packed_cpu.shape[0]))
    packed_cpu = packed_cpu[:test_n].contiguous()
    scales_cpu = scales_cpu[:test_n].contiguous()
    n, packed_k = packed_cpu.shape
    k = packed_k * 2
    packed = packed_cpu.t().contiguous().cuda()
    scales = scales_cpu.t().contiguous().cuda()
    torch.manual_seed(20260729)
    m = int(os.environ.get("NETRA_TEST_M", "65"))
    activation = torch.randn((m, k), dtype=torch.bfloat16, device="cuda")

    lib = ctypes.CDLL(LIB)
    lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
    lib.netra_mxfp4_sgl_error.restype = ctypes.c_char_p
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
    status = lib.netra_mxfp4_sgl_init()
    if status:
        raise RuntimeError(lib.netra_mxfp4_sgl_error().decode())
    groups = (m + 63) // 64
    activation_groups = torch.zeros(
        (groups, 64, k), dtype=torch.bfloat16, device="cuda"
    )
    activation_groups.view(-1, k)[:m].copy_(activation)
    output_groups = torch.empty(
        (groups, 64, n), dtype=torch.float32, device="cuda"
    )
    status = lib.netra_mxfp4_sgl_linear_prefill(
        ptr(packed),
        ptr(scales),
        ptr(activation_groups),
        ptr(output_groups),
        groups,
        n,
        k,
        ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
    )
    if status:
        raise RuntimeError(f"launch failed: {status}")
    torch.cuda.synchronize()
    if os.environ.get("NETRA_ARGS_DEBUG") == "1":
        print(output.view(torch.int32).cpu()[0, :8].tolist())
        return

    weight64 = dequant(packed_cpu, scales_cpu)
    output = output_groups.view(-1, n)[:m].to(torch.bfloat16)
    reference = activation.cpu().to(torch.float64) @ weight64.t()
    ref_bf16 = reference.to(torch.bfloat16)
    got = output.cpu()
    diff = got.float() - ref_bf16.float()
    print(
        json.dumps(
            {
                "device": torch.cuda.get_device_properties(0).gcnArchName,
                "real_checkpoint": str(MODEL),
                "projection": KEY,
                "shape_mnk": [m, n, k],
                "finite_fraction": got.float().isfinite().float().mean().item(),
                "max_abs_bf16": diff.abs().max().item(),
                "normalized_l2_bf16": (
                    diff.norm() / ref_bf16.float().norm()
                ).item(),
                "exact_bf16_fraction": (got == ref_bf16).float().mean().item(),
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
