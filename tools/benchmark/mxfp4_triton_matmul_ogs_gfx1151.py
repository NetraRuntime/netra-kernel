#!/usr/bin/env python3
"""Matched Triton matmul_ogs MXFP4 baseline for the gfx1151 raw-ASM suite."""

import argparse
import json
import time

import numpy as np
import torch

from triton_kernels.matmul_ogs import PrecisionConfig, matmul_ogs
from triton_kernels.matmul_ogs_details import opt_flags
from triton_kernels.tensor import FP4, Storage, Tensor, wrap_torch_tensor


E2M1 = np.array(
    [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0,
     -0.0, -0.5, -1.0, -1.5, -2.0, -3.0, -4.0, -6.0],
    dtype=np.float64,
)


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--case", choices=("gate", "down", "lm"), required=True)
    p.add_argument("--m", type=int, required=True)
    p.add_argument("--iters", type=int, default=32)
    p.add_argument("--warmup", type=int, default=8)
    p.add_argument("--rotations", type=int, default=0)
    p.add_argument("--packed")
    p.add_argument("--scales")
    p.add_argument("--block-m", type=int)
    p.add_argument("--block-n", type=int)
    p.add_argument("--block-k", type=int)
    p.add_argument("--split-k", type=int)
    p.add_argument(
        "--rdna-manual-dequant",
        action="store_true",
        help="Use the published RDNAMXValueLayout manual-dequant path.",
    )
    return p.parse_args()


def case_spec(args):
    if args.case == "gate":
        return {
            "e": 8, "n": 512, "k": 2048,
            "packed": args.packed or
            "/root/work/real_gate_l0/gate8_packed_kmajor.bin",
            "scales": args.scales or
            "/root/work/real_gate_l0/gate8_scales_kmajor.bin",
        }
    if args.case == "down":
        return {
            "e": 8, "n": 2048, "k": 512,
            "packed": args.packed or
            "/root/work/real_down_l0/down8_packed_kmajor.bin",
            "scales": args.scales or
            "/root/work/real_down_l0/down8_scales_kmajor.bin",
        }
    return {
        "e": 1, "n": 248320, "k": 2048,
        "packed": args.packed or
        "/root/work/real_lm_head_mxfp4/lm_head_packed_kmajor.bin",
        "scales": args.scales or
        "/root/work/real_lm_head_mxfp4/lm_head_scales_kmajor.bin",
    }


def read_exact(path, count):
    out = np.fromfile(path, dtype=np.uint8)
    if out.size != count:
        raise RuntimeError(f"{path}: got {out.size} bytes, expected {count}")
    return out


def make_weight_pair(q_kmajor, s_kmajor, rdna_manual_dequant):
    # matmul_ogs wants a logical [E,K,N] column-major view. The physical
    # tensors below are [E,N,K/2] and [E,N,K/32]; transpose creates stride-K=1.
    q_storage = torch.from_numpy(
        np.transpose(q_kmajor, (0, 2, 1)).copy()
    ).to("cuda")
    s_storage = torch.from_numpy(
        np.transpose(s_kmajor, (0, 2, 1)).copy()
    ).to("cuda")
    q_view = q_storage.transpose(1, 2)
    if rdna_manual_dequant:
        from triton_kernels.tensor_details.layout_details.rdna_value import (
            RDNAMXValueLayout,
        )
        logical_shape = [
            q_view.shape[0], q_view.shape[1] * 2, q_view.shape[2]
        ]
        weight = Tensor(
            Storage(q_view, RDNAMXValueLayout(q_view.shape)),
            dtype=FP4,
            shape=logical_shape,
        )
    else:
        weight = wrap_torch_tensor(q_view, FP4)
    scale = Tensor(s_storage.transpose(1, 2))
    return weight, scale


def fp64_reference(x, q_kmajor, s_kmajor, got):
    rows = min(x.shape[1], 12)
    cols = min(q_kmajor.shape[2], 128)
    q = q_kmajor[0, :, :cols]
    s = s_kmajor[0, :, :cols]
    w = np.empty((q.shape[0] * 2, cols), dtype=np.float64)
    w[0::2] = E2M1[q & 15]
    w[1::2] = E2M1[q >> 4]
    scale = np.ldexp(np.ones(s.shape, dtype=np.float64),
                     s.astype(np.int16) - 127)
    w *= np.repeat(scale, 32, axis=0)
    a = x[0, :rows].float().cpu().numpy().astype(np.float64)
    ref = a @ w
    out = got[0, :rows, :cols].double().cpu().numpy()
    diff = np.abs(out - ref)
    denom = np.maximum(np.abs(ref), 1.0e-30)
    return {
        "reference_rows": rows,
        "reference_cols": cols,
        "reference_sample": ref.reshape(-1)[:8].tolist(),
        "output_sample": out.reshape(-1)[:8].tolist(),
        "max_abs": float(diff.max()),
        "max_rel": float((diff / denom).max()),
        "normalized_l2": float(
            np.linalg.norm(diff) / max(np.linalg.norm(ref), 1.0e-30)
        ),
    }


def main():
    args = parse_args()
    spec = case_spec(args)
    e, n, k, m = spec["e"], spec["n"], spec["k"], args.m
    q = read_exact(spec["packed"], e * (k // 2) * n).reshape(
        e, k // 2, n
    )
    s = read_exact(spec["scales"], e * (k // 32) * n).reshape(
        e, k // 32, n
    )

    if args.rotations:
        rotations = args.rotations
    else:
        bytes_per_copy = q.nbytes + s.nbytes
        rotations = 1 if bytes_per_copy > 32 * 1024 * 1024 else max(
            1, (64 * 1024 * 1024 + bytes_per_copy - 1) // bytes_per_copy
        )

    torch.manual_seed(23)
    x = (torch.rand((e, m, k), device="cuda", dtype=torch.float32) * 2 - 1
         ).to(torch.bfloat16)
    pairs = [
        make_weight_pair(q, s, args.rdna_manual_dequant)
        for _ in range(rotations)
    ]
    outputs = [
        torch.empty((e, m, n), device="cuda", dtype=torch.float32)
        for _ in range(rotations)
    ]

    constraints = {
        key: value for key, value in {
            "block_m": args.block_m,
            "block_n": args.block_n,
            "block_k": args.block_k,
            "split_k": args.split_k,
            "is_persistent": False,
        }.items() if value is not None
    }
    opt_flags.reset_opt_flags_constraints()
    opt_flags.update_opt_flags_constraints(constraints)

    def launch(i):
        weight, scale = pairs[i % rotations]
        cfg = PrecisionConfig(weight_scale=scale, out_dtype=torch.float32)
        return matmul_ogs(
            x, weight, None, precision_config=cfg,
            y=outputs[i % rotations],
        )

    # Compile, then validate real checkpoint data against an fp64 subset.
    got = launch(0)
    torch.cuda.synchronize()
    correctness = fp64_reference(x, q, s, got)

    for i in range(args.warmup):
        launch(i)
    torch.cuda.synchronize()
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    start.record()
    host_start = time.perf_counter()
    for i in range(args.iters):
        launch(i)
    end.record()
    end.synchronize()
    host_end = time.perf_counter()
    event_us = start.elapsed_time(end) * 1000.0 / args.iters

    result = {
        "target": "gfx1151",
        "baseline": "Triton 3.5.1 matmul_ogs v3.5.1",
        "triton_kernels_commit":
            "0add68262ab0a2e33b84524346cb27cbb2787356",
        "case": args.case,
        "shape": {"E": e, "M": m, "N": n, "K": k},
        "constraints": constraints,
        "rdna_manual_dequant": args.rdna_manual_dequant,
        "rotations": rotations,
        "rotating_weight_mib":
            rotations * (q.nbytes + s.nbytes) / (1024.0 * 1024.0),
        "event_us": event_us,
        "host_loop_us": (host_end - host_start) * 1.0e6 / args.iters,
        "correctness_vs_fp64_subset": correctness,
    }
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
