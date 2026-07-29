#!/usr/bin/env python3
"""Validate the rejected fixed-pairwise top-8 reduction on gfx1151."""
import ctypes
import json
import socket

import torch

if socket.gethostname() != "Netra":
    raise SystemExit("refusing outside Netra LXC")
lib = ctypes.CDLL("/root/netra-mxfp4-gfx1151/build/experiments/libexpert_weighted_reduce_top8_pairwise.so")
lib.netra_reduce_init.argtypes = [ctypes.c_char_p]
lib.netra_reduce_init.restype = ctypes.c_int
hsaco = b"/root/netra-mxfp4-gfx1151/build/experiments/expert_weighted_reduce_top8_pairwise_gfx1151.hsaco"
assert lib.netra_reduce_init(hsaco) == 0
lib.netra_reduce.argtypes = [ctypes.c_void_p] * 4 + [ctypes.c_uint, ctypes.c_void_p]
lib.netra_reduce.restype = ctypes.c_int
ptr = lambda tensor: ctypes.c_void_p(tensor.data_ptr())
stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
results = []
for tokens, rows in ((128, 1280), (8192, 81664)):
    torch.manual_seed(1151 + tokens)
    expert = torch.randn((rows, 2048), device="cuda")
    positions = torch.randperm(rows, device="cuda", dtype=torch.int64)[: tokens * 8].to(torch.int32).view(tokens, 8)
    weights = torch.rand((tokens, 8), device="cuda")
    weights /= weights.sum(1, keepdim=True)
    output = torch.empty((tokens, 2048), device="cuda", dtype=torch.bfloat16)
    selected = expert.index_select(0, positions.flatten()).view(tokens, 8, 2048)
    products = selected * weights[:, :, None]
    pairwise = ((products[:, 0] + products[:, 1]) + (products[:, 2] + products[:, 3])) + ((products[:, 4] + products[:, 5]) + (products[:, 6] + products[:, 7]))
    pairwise = pairwise.to(torch.bfloat16)
    fp64 = (selected.double() * weights.double()[:, :, None]).sum(1).to(torch.bfloat16)
    assert lib.netra_reduce(ptr(expert), ptr(positions), ptr(weights), ptr(output), tokens, stream) == 0
    torch.cuda.synchronize()
    delta = (output.float() - fp64.float()).abs()
    results.append({"tokens": tokens, "rows": rows, "pairwise_bit_equal": bool(torch.equal(output, pairwise)), "fp64_bf16_mismatches": int((output != fp64).sum()), "max_abs_vs_fp64_bf16": float(delta.max()), "mean_abs_vs_fp64_bf16": float(delta.mean())})
print(json.dumps({"target": "gfx1151", "measurement_status": "measured", "production_status": "rejected", "results": results}, indent=2))
