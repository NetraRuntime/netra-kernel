#!/usr/bin/env python3
"""HIP-event benchmark of raw-ASM QKVZ+BA fusion on real MXFP4 weights."""

import ctypes
import json
import statistics
from pathlib import Path

import torch
from safetensors import safe_open

MODEL = Path("/root/models/qwen36-mxfp4")
LIB = "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so"
ROOT = "model.language_model.layers.0.linear_attn"
PARTS = ("in_proj_qkv", "in_proj_z", "in_proj_b", "in_proj_a")


def load_tensor(key):
    index = json.loads((MODEL / "model.safetensors.index.json").read_text())
    with safe_open(MODEL / index["weight_map"][key], framework="pt") as handle:
        return handle.get_tensor(key)


def ptr(tensor):
    return ctypes.c_void_p(tensor.data_ptr())


def dequant(packed, scales):
    lut = torch.tensor([0, 0.5, 1, 1.5, 2, 3, 4, 6], dtype=torch.float64)
    low, high = packed & 15, packed >> 4
    low_v = lut[(low & 7).long()] * torch.where((low & 8) != 0, -1.0, 1.0)
    high_v = lut[(high & 7).long()] * torch.where(
        (high & 8) != 0, -1.0, 1.0
    )
    values = torch.stack((low_v, high_v), dim=-1).flatten(-2)
    return values * torch.exp2(scales.double() - 127).repeat_interleave(32, -1)


def main():
    torch.manual_seed(20260729)
    packed_parts, scale_parts = [], []
    for part in PARTS:
        packed_parts.append(load_tensor(f"{ROOT}.{part}.weight_packed").contiguous())
        scale_parts.append(load_tensor(f"{ROOT}.{part}.weight_scale").contiguous())
    sizes = [part.shape[0] for part in packed_parts]
    qkvz_n, ba_n = sum(sizes[:2]), sum(sizes[2:])
    fused_n = qkvz_n + ba_n
    padded_n = ((fused_n + 511) // 512) * 512
    assert (qkvz_n, ba_n, fused_n, padded_n) == (12288, 64, 12352, 12800)

    qkvz_p_cpu = torch.cat(packed_parts[:2])
    qkvz_s_cpu = torch.cat(scale_parts[:2])
    ba_p_cpu = torch.cat(packed_parts[2:])
    ba_s_cpu = torch.cat(scale_parts[2:])
    fused_p_cpu = torch.cat(packed_parts)
    fused_s_cpu = torch.cat(scale_parts)
    pad = padded_n - fused_n
    fused_p_pad = torch.cat(
        (fused_p_cpu, torch.zeros((pad, fused_p_cpu.shape[1]), dtype=torch.uint8))
    )
    fused_s_pad = torch.cat(
        (fused_s_cpu, torch.zeros((pad, fused_s_cpu.shape[1]), dtype=torch.uint8))
    )

    qkvz_p, qkvz_s = qkvz_p_cpu.t().contiguous().cuda(), qkvz_s_cpu.t().contiguous().cuda()
    ba_p, ba_s = ba_p_cpu.t().contiguous().cuda(), ba_s_cpu.t().contiguous().cuda()
    fused_p = fused_p_pad.t().contiguous().cuda()
    fused_s = fused_s_pad.t().contiguous().cuda()
    k = fused_p_cpu.shape[1] * 2
    activation = torch.randn((1, k), dtype=torch.bfloat16, device="cuda")
    qkvz_out = torch.empty((1, qkvz_n), dtype=torch.bfloat16, device="cuda")
    ba_out = torch.empty((1, ba_n), dtype=torch.bfloat16, device="cuda")
    fused_out = torch.empty((1, padded_n), dtype=torch.bfloat16, device="cuda")

    lib = ctypes.CDLL(LIB)
    lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
    lib.netra_mxfp4_sgl_error.restype = ctypes.c_char_p
    lib.netra_mxfp4_sgl_linear.argtypes = [ctypes.c_void_p] * 4 + [ctypes.c_uint] * 3 + [ctypes.c_void_p]
    lib.netra_mxfp4_sgl_linear.restype = ctypes.c_int
    if lib.netra_mxfp4_sgl_init():
        raise RuntimeError(lib.netra_mxfp4_sgl_error().decode())
    stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)

    def launch(packed, scale, output, n):
        status = lib.netra_mxfp4_sgl_linear(
            ptr(packed), ptr(scale), ptr(activation), ptr(output), 1, n, k, stream
        )
        if status:
            raise RuntimeError(f"raw gfx1151 launch failed: {status}")

    def baseline():
        launch(qkvz_p, qkvz_s, qkvz_out, qkvz_n)
        launch(ba_p, ba_s, ba_out, ba_n)

    def fused():
        launch(fused_p, fused_s, fused_out, padded_n)

    for _ in range(20):
        baseline()
        fused()
    torch.cuda.synchronize()

    def time_ms(call):
        values = []
        for _ in range(200):
            begin = torch.cuda.Event(enable_timing=True)
            end = torch.cuda.Event(enable_timing=True)
            begin.record()
            call()
            end.record()
            end.synchronize()
            values.append(begin.elapsed_time(end))
        return values

    baseline_ms, fused_ms = time_ms(baseline), time_ms(fused)
    baseline()
    fused()
    torch.cuda.synchronize()
    separate = torch.cat((qkvz_out, ba_out), 1).cpu()
    combined = fused_out[:, :fused_n].cpu()
    fusion_diff = combined.float() - separate.float()

    activation64 = activation.cpu().double().view(-1)
    reference = []
    for start in range(0, fused_n, 256):
        stop = min(start + 256, fused_n)
        reference.append(
            (dequant(fused_p_cpu[start:stop], fused_s_cpu[start:stop]) @ activation64).bfloat16()
        )
    reference = torch.cat(reference).view(1, -1)
    ref_diff = combined.float() - reference.float()
    baseline_median = statistics.median(baseline_ms)
    fused_median = statistics.median(fused_ms)
    result = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "checkpoint": str(MODEL),
        "shape_m_nqkvz_nba_k": [1, qkvz_n, ba_n, k],
        "compute": "raw AMDGCN mxfp4_sgl_linear_decode_gfx1151",
        "baseline_two_dispatch_median_ms_hip_event": baseline_median,
        "fused_one_dispatch_padded_median_ms_hip_event": fused_median,
        "speedup": baseline_median / fused_median,
        "padded_outputs": pad,
        "fusion_max_abs_bf16": fusion_diff.abs().max().item(),
        "fusion_exact_bf16_fraction": (combined == separate).float().mean().item(),
        "fp64_reference_max_abs_bf16": ref_diff.abs().max().item(),
        "fp64_reference_normalized_l2_bf16": (ref_diff.norm() / reference.float().norm()).item(),
        "fp64_reference_exact_bf16_fraction": (combined == reference).float().mean().item(),
        "baseline_min_max_ms": [min(baseline_ms), max(baseline_ms)],
        "fused_min_max_ms": [min(fused_ms), max(fused_ms)],
    }
    output = Path("results/kernels/gfx1151/qkvz-ba-fusion.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
