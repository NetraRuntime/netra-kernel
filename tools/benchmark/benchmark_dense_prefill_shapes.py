#!/usr/bin/env python3
"""Benchmark and bit-compare the exact gfx1151 dense-prefill shapes."""
import argparse
import ctypes
import json
import os
import statistics
from pathlib import Path
import torch

LIB = os.environ.get("NETRA_MXFP4_SGL_LIB", "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so")
SHAPES = (("qkvz", 12288, 2048), ("gdn_out", 2048, 4096), ("ab", 64, 2048))

def ptr(tensor):
    return ctypes.c_void_p(tensor.data_ptr())

def launch(lib, packed, scales, activation, output, groups, n, k, stream):
    status = lib.netra_mxfp4_sgl_linear_prefill(ptr(packed), ptr(scales), ptr(activation), ptr(output), groups, n, k, stream)
    if status:
        raise RuntimeError(f"raw dense-prefill launch failed: {status}")

def time_shape(lib, packed, scales, activation, output, groups, n, k, stream, inner):
    for _ in range(5):
        launch(lib, packed, scales, activation, output, groups, n, k, stream)
    torch.cuda.synchronize()
    samples = []
    for _ in range(11):
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        start.record()
        for _ in range(inner):
            launch(lib, packed, scales, activation, output, groups, n, k, stream)
        stop.record()
        stop.synchronize()
        samples.append(start.elapsed_time(stop) / inner)
    return samples

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--groups", type=int, default=128)
    parser.add_argument("--inner", type=int, default=1)
    parser.add_argument("--save", type=Path)
    parser.add_argument("--compare", type=Path)
    parser.add_argument("--save-all-gdn", action="store_true")
    args = parser.parse_args()
    torch.manual_seed(1151)
    lib = ctypes.CDLL(LIB)
    lib.netra_mxfp4_sgl_init.restype = ctypes.c_int
    lib.netra_mxfp4_sgl_linear_prefill.argtypes = [ctypes.c_void_p] * 4 + [ctypes.c_uint] * 3 + [ctypes.c_void_p]
    lib.netra_mxfp4_sgl_linear_prefill.restype = ctypes.c_int
    if lib.netra_mxfp4_sgl_init():
        raise RuntimeError("Netra raw-ASM runtime init failed")
    stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
    reference = torch.load(args.compare) if args.compare else {}
    saved = {}
    results = []
    for name, n, k in SHAPES:
        packed = torch.randint(0, 256, (k // 2, n), dtype=torch.uint8, device="cuda")
        scales = torch.full((k // 32, n), 127, dtype=torch.uint8, device="cuda")
        activation = torch.randn((args.groups, 64, k), dtype=torch.bfloat16, device="cuda")
        output = torch.empty((args.groups, 64, n), dtype=torch.float32, device="cuda")
        samples = time_shape(lib, packed, scales, activation, output, args.groups, n, k, stream, args.inner)
        one_group = output[0].cpu()
        saved[name] = output.cpu() if args.save_all_gdn and name == "gdn_out" else one_group
        item = {"name": name, "n": n, "k": k, "groups": args.groups, "median_ms": statistics.median(samples), "mean_ms": statistics.mean(samples), "min_ms": min(samples), "max_ms": max(samples), "samples_ms": samples}
        if name in reference:
            expected = reference[name]
            actual = output.cpu() if expected.ndim == 3 else one_group
            delta = (actual - expected).abs()
            item["bit_exact"] = bool(torch.equal(actual, expected))
            item["max_abs_diff"] = float(delta.max())
        results.append(item)
    if args.save:
        args.save.parent.mkdir(parents=True, exist_ok=True)
        torch.save(saved, args.save)
    print(json.dumps({"device": torch.cuda.get_device_properties(0).gcnArchName, "measurement": f"gfx1151 HIP events, {args.inner} launch(es) per sample; reported per launch", "results": results}, indent=2))

if __name__ == "__main__":
    main()
