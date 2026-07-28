#!/usr/bin/env python3
"""Validate the SGL decode ABI against a staged-fp64 reference on real weights."""

import ctypes
import json
import math
from pathlib import Path

import torch
from safetensors import safe_open


MODEL = Path("/root/models/qwen36-mxfp4")
LIB = "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so"


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
    scale = torch.exp2(scales.to(torch.float64) - 127.0)
    return values * scale.repeat_interleave(32, dim=-1)


def ptr(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


def main() -> None:
    torch.manual_seed(20260729)
    device = "cuda"
    ids_host = [7, 1, 5, 2, 6, 3, 4, 0]
    root = "model.language_model.layers.0.mlp.experts"

    gate_w = torch.zeros((256, 1024, 512), dtype=torch.uint8, device=device)
    gate_s = torch.zeros((256, 64, 512), dtype=torch.uint8, device=device)
    up_w = torch.zeros_like(gate_w)
    up_s = torch.zeros_like(gate_s)
    down_w = torch.zeros((256, 256, 2048), dtype=torch.uint8, device=device)
    down_s = torch.zeros((256, 16, 2048), dtype=torch.uint8, device=device)

    cpu_weights = {}
    for expert in ids_host:
        for projection in ("gate", "up", "down"):
            packed = load_tensor(f"{root}.{expert}.{projection}_proj.weight_packed")
            scales = load_tensor(f"{root}.{expert}.{projection}_proj.weight_scale")
            cpu_weights[(expert, projection)] = (packed, scales)
            if projection == "gate":
                gate_w[expert].copy_(packed.t())
                gate_s[expert].copy_(scales.t())
            elif projection == "up":
                up_w[expert].copy_(packed.t())
                up_s[expert].copy_(scales.t())
            else:
                down_w[expert].copy_(packed.t())
                down_s[expert].copy_(scales.t())

    activation = torch.randn(2048, dtype=torch.bfloat16, device=device)
    expert_ids = torch.tensor(ids_host, dtype=torch.int32, device=device)
    topk_weights = torch.softmax(torch.randn(8, device=device), dim=0)
    gate_tmp = torch.empty((8, 512), dtype=torch.float32, device=device)
    up_tmp = torch.empty_like(gate_tmp)
    intermediate = torch.empty((8, 512), dtype=torch.bfloat16, device=device)
    expert_output = torch.empty((8, 2048), dtype=torch.float32, device=device)
    output = torch.empty(2048, dtype=torch.bfloat16, device=device)

    lib = ctypes.CDLL(LIB)
    lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
    lib.netra_mxfp4_sgl_error.restype = ctypes.c_char_p
    lib.netra_mxfp4_sgl_decode.argtypes = [ctypes.c_void_p] * 15
    lib.netra_mxfp4_sgl_decode.restype = ctypes.c_int
    status = lib.netra_mxfp4_sgl_init()
    if status:
        raise RuntimeError(lib.netra_mxfp4_sgl_error().decode())

    args = [
        gate_w,
        gate_s,
        up_w,
        up_s,
        down_w,
        down_s,
        activation,
        expert_ids,
        topk_weights,
        gate_tmp,
        up_tmp,
        intermediate,
        expert_output,
        output,
    ]
    status = lib.netra_mxfp4_sgl_decode(
        *(ptr(x) for x in args),
        ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
    )
    if status:
        raise RuntimeError(f"launch failed: {status}")
    torch.cuda.synchronize()
    for name, tensor in (
        ("gate", gate_tmp),
        ("up", up_tmp),
        ("intermediate", intermediate),
        ("expert_output", expert_output),
        ("output", output),
    ):
        value = tensor.float()
        print(
            name,
            "finite=",
            value.isfinite().float().mean().item(),
            "max=",
            value.abs().max().item(),
        )

    act64 = activation.cpu().to(torch.float64)
    refs = []
    for slot, expert in enumerate(ids_host):
        gp, gs = cpu_weights[(expert, "gate")]
        up, us = cpu_weights[(expert, "up")]
        dp, ds = cpu_weights[(expert, "down")]
        gate = dequant(gp, gs) @ act64
        up_value = dequant(up, us) @ act64
        mid = (torch.nn.functional.silu(gate) * up_value).to(torch.bfloat16)
        refs.append(dequant(dp, ds) @ mid.to(torch.float64))
    ref = torch.stack(refs)
    ref = (ref * topk_weights.cpu().to(torch.float64)[:, None]).sum(0)
    ref_bf16 = ref.to(torch.bfloat16)
    got = output.cpu()
    diff = got.float() - ref_bf16.float()
    denom = ref_bf16.float().norm().item()
    print(
        json.dumps(
            {
                "device": torch.cuda.get_device_properties(0).gcnArchName,
                "real_checkpoint": str(MODEL),
                "expert_ids": ids_host,
                "max_abs_bf16": diff.abs().max().item(),
                "normalized_l2_bf16": diff.norm().item() / denom,
                "exact_bf16_fraction": (got == ref_bf16).float().mean().item(),
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
