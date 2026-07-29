#!/usr/bin/env python3
"""Launch one exact Qwen3.6 gfx1151 ordered raw-ASM GDN recompute."""
import socket

import torch

from sglang.srt.layers.quantization.netra_gfx1151 import (
    netra_gdn_recompute_w_u_with_output,
)

if socket.gethostname() != "Netra":
    raise SystemExit("must run inside Netra")
B, T, HG, K, H, V, BT = 1, 8192, 16, 128, 32, 128, 64
device = "cuda"
k = torch.zeros((B, T, HG, K), dtype=torch.bfloat16, device=device)
v = torch.zeros((B, T, H, V), dtype=torch.bfloat16, device=device)
beta = torch.ones((B, T, H), dtype=torch.float32, device=device)
A = torch.zeros((B, T, H, BT), dtype=torch.bfloat16, device=device)
g = torch.zeros((B, T, H), dtype=torch.float32, device=device)
w = torch.empty((B, T, H, K), dtype=torch.bfloat16, device=device)
u = torch.empty_like(v)
torch.cuda.synchronize()
netra_gdn_recompute_w_u_with_output(k, v, beta, w, u, A, g, T)
torch.cuda.synchronize()
print("gfx1151 measured ordered raw-ASM recompute launch complete")
