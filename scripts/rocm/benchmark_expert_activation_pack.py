#!/usr/bin/env python3
"""HIP-event and guard benchmark for the raw gfx1151 expert activation pack."""
import argparse
import ctypes
import json
import socket
import statistics
from pathlib import Path

import torch

if socket.gethostname() != "Netra":
    raise SystemExit("refusing outside Netra LXC")
parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path)
args = parser.parse_args()
lib = ctypes.CDLL("/root/netra-mxfp4-gfx1151/build/experiments/libexpert_activation_pack.so")
lib.netra_pack_init.argtypes = [ctypes.c_char_p]
lib.netra_pack_init.restype = ctypes.c_int
hsaco = b"/root/netra-mxfp4-gfx1151/build/experiments/expert_activation_pack_gfx1151.hsaco"
assert lib.netra_pack_init(hsaco) == 0
lib.netra_pack.argtypes = [ctypes.c_void_p] * 4 + [ctypes.c_uint32, ctypes.c_uint32, ctypes.c_void_p]
lib.netra_pack.restype = ctypes.c_int
ptr = lambda tensor: ctypes.c_void_p(tensor.data_ptr())

# Exact Qwen3.6 8,192-token routed-MoE shape.
torch.manual_seed(1151)
tokens, topk, experts = 8192, 8, 256
hidden = torch.randn((tokens, 2048), device="cuda", dtype=torch.bfloat16)
flat_ids = torch.randint(0, experts, (tokens * topk,), device="cuda", dtype=torch.int64)
sorted_ids, order = torch.sort(flat_ids)
pairs = sorted_ids.numel()
group_count = experts + (pairs - experts) // 64
sequence = torch.arange(pairs, device="cuda")
new_expert = torch.ones(pairs, dtype=torch.bool, device="cuda")
new_expert[1:] = sorted_ids[1:] != sorted_ids[:-1]
start = torch.cummax(torch.where(new_expert, sequence, 0), 0).values
rank = sequence - start
group = torch.cumsum((new_expert | ((rank & 63) == 0)).to(torch.int64), 0) - 1
position = (group * 64 + (rank & 63)).contiguous()
pair_tokens = torch.div(order, topk, rounding_mode="floor").contiguous()
rows = group_count * 64
out = torch.empty((rows, 2048), device="cuda", dtype=torch.bfloat16)
stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)

def raw(output=out):
    assert lib.netra_pack(ptr(hidden), ptr(pair_tokens), ptr(position), ptr(output), pairs, rows, stream) == 0

def reference():
    result = torch.zeros((rows, 2048), device="cuda", dtype=torch.bfloat16)
    result.index_copy_(0, position, hidden.index_select(0, pair_tokens))
    return result

def measure(function, count):
    for _ in range(2):
        function()
    torch.cuda.synchronize()
    samples = []
    for _ in range(count):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        function()
        end.record()
        end.synchronize()
        samples.append(begin.elapsed_time(end))
    return samples

ref = reference()
raw()
torch.cuda.synchronize()
delta = (out.float() - ref.float()).abs()
raw_samples = measure(raw, 11)
torch_samples = measure(reference, 7)

# Detect any store before or after the output allocation.
guard_words = 65536
sentinel = 0x5A3C
storage = torch.full((guard_words + rows * 2048 + guard_words,), sentinel, device="cuda", dtype=torch.uint16)
guarded_out = storage[guard_words : guard_words + rows * 2048].view(torch.bfloat16).reshape(rows, 2048)
raw(guarded_out)
torch.cuda.synchronize()
prefix_corrupt = int((storage[:guard_words] != sentinel).sum())
suffix_corrupt = int((storage[-guard_words:] != sentinel).sum())

report = {
    "target": "gfx1151",
    "measurement_status": "measured_hip_events",
    "shape": {"tokens": tokens, "topk": topk, "experts": experts, "pairs": pairs, "group_capacity": group_count, "rows": rows, "hidden": 2048},
    "bit_equal": bool(torch.equal(out, ref)),
    "max_abs": float(delta.max()),
    "mean_abs": float(delta.mean()),
    "raw_median_ms": statistics.median(raw_samples),
    "torch_pipeline_median_ms": statistics.median(torch_samples),
    "speedup": statistics.median(torch_samples) / statistics.median(raw_samples),
    "raw_samples_ms": raw_samples,
    "torch_samples_ms": torch_samples,
    "guard": {"words_each_side": guard_words, "prefix_corrupt_words": prefix_corrupt, "suffix_corrupt_words": suffix_corrupt},
}
rendered = json.dumps(report, indent=2) + "\n"
if args.output:
    args.output.write_text(rendered)
print(rendered, end="")
