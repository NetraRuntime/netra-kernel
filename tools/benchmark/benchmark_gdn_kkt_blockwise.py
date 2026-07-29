#!/usr/bin/env python3
"""Correctness and HIP-event benchmark for the rejected gfx1151 raw GDN KKT kernel."""

import argparse
import ctypes
import json
import socket
import statistics
import sys
from pathlib import Path

import torch

if socket.gethostname() != "Netra":
    raise SystemExit("refusing to run outside the Netra LXC")

sys.path.insert(0, "/root/work/sglang-main/python")
from sglang.kernels.ops.attention.fla.chunk_fwd import (  # noqa: E402
    chunk_gated_delta_rule_fwd_kkt_solve_kernel as production_kernel,
)
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices  # noqa: E402

T, H, HG, K, BT, BC = 8192, 32, 16, 128, 64, 16
NT = T // BT


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--iterations", type=int, default=15)
    parser.add_argument("--seed", type=int, default=1151)
    parser.add_argument("--real-inputs", type=Path)
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def timed(function, iterations: int) -> list[float]:
    for _ in range(3):
        function()
    torch.cuda.synchronize()
    samples = []
    for _ in range(iterations):
        begin = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        begin.record()
        function()
        end.record()
        end.synchronize()
        samples.append(begin.elapsed_time(end))
    return samples


def main() -> None:
    args = parse_args()
    if args.iterations < 3:
        raise SystemExit("--iterations must be at least 3")
    repo = Path(__file__).resolve().parents[2]
    build = repo / "build" / "experiments"
    library = ctypes.CDLL(str(build / "libgdn_kkt_blockwise.so"))
    library.gdn_kkt_blockwise_init.argtypes = [ctypes.c_char_p]
    library.gdn_kkt_blockwise_init.restype = ctypes.c_int
    library.gdn_kkt_blockwise_launch.argtypes = [ctypes.c_void_p] * 5
    library.gdn_kkt_blockwise_launch.restype = ctypes.c_int
    library.gdn_kkt_blockwise_error.restype = ctypes.c_char_p
    hsaco = build / "gdn_kkt_solve_blockwise_gfx1151.hsaco"
    status = library.gdn_kkt_blockwise_init(str(hsaco).encode())
    if status:
        raise RuntimeError(library.gdn_kkt_blockwise_error().decode())

    if args.real_inputs:
        captured = torch.load(args.real_inputs, map_location="cpu")
        k = captured["k"].cuda().contiguous()
        g = captured["g"].cuda().float().contiguous()
        beta = captured["beta"].cuda().float().contiguous()
        input_scope = "real_checkpoint_capture"
    else:
        torch.manual_seed(args.seed)
        k = (torch.randn((1, T, HG, K), device="cuda") * 0.03).bfloat16()
        g = torch.cumsum(
            torch.randn((1, T, H), device="cuda") * 0.001, dim=1
        ).float()
        beta = torch.sigmoid(torch.randn((1, T, H), device="cuda")).float()
        k, g, beta = k.contiguous(), g.contiguous(), beta.contiguous()
        input_scope = "deterministic_synthetic_model_shape"

    cu_seqlens = torch.tensor([0, T], device="cuda", dtype=torch.int64)
    chunk_indices = prepare_chunk_indices(cu_seqlens, BT)
    reference = torch.zeros((1, T, H, BT), device="cuda", dtype=torch.bfloat16)
    candidate = torch.zeros_like(reference)

    def production() -> None:
        production_kernel[(NT, H)](
            k=k,
            g=g,
            beta=beta,
            A=reference,
            cu_seqlens=cu_seqlens,
            chunk_indices=chunk_indices,
            T=T,
            H=H,
            Hg=HG,
            K=K,
            BT=BT,
            BC=BC,
        )

    def raw() -> None:
        status = library.gdn_kkt_blockwise_launch(
            k.data_ptr(),
            g.data_ptr(),
            beta.data_ptr(),
            candidate.data_ptr(),
            torch.cuda.current_stream().cuda_stream,
        )
        if status:
            raise RuntimeError(library.gdn_kkt_blockwise_error().decode())

    production()
    raw()
    torch.cuda.synchronize()
    delta = (candidate.float() - reference.float()).abs()
    production_samples = timed(production, args.iterations)
    raw_samples = timed(raw, args.iterations)
    production_median = statistics.median(production_samples)
    raw_median = statistics.median(raw_samples)
    report = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "shape": "B1_T8192_H32_Hg16_K128_BT64_BC16_beta_fp32",
        "input_scope": input_scope,
        "reference": "SGLang autotuned Triton production kernel",
        "bf16_bit_mismatches": int(
            (candidate.view(torch.int16) != reference.view(torch.int16)).sum()
        ),
        "numerical_mismatches": int((delta != 0).sum()),
        "max_abs": float(delta.max()),
        "mean_abs": float(delta.mean()),
        "differences_subnormal_only": bool(delta.max() < torch.finfo(torch.float32).tiny),
        "production_samples_ms": production_samples,
        "production_median_ms": production_median,
        "raw_samples_ms": raw_samples,
        "raw_median_ms": raw_median,
        "raw_speedup_vs_production": production_median / raw_median,
        "decision": "reject" if raw_median >= production_median else "candidate",
        "raw_resources": {
            "vgpr": 208,
            "sgpr": 48,
            "lds_bytes": 16384,
            "scratch_bytes": 0,
            "wave_size": 32,
            "grid": [128, 32, 1],
            "block": [32, 1, 1],
        },
    }
    encoded = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded)
    print(encoded, end="")


if __name__ == "__main__":
    main()
