#!/usr/bin/env python3
"""Compare Qwen3.6 QKVZ/BA split-copy kernels with HIP events on gfx1151."""

import argparse
import ctypes
import json
import statistics
from pathlib import Path

import torch

from sglang.kernels.ops.attention.triton_gdn_fused_proj import (
    fused_qkvzba_split_reshape_cat_contiguous_kernel,
)


LIBRARY = "/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so"


def pointer(tensor: torch.Tensor) -> ctypes.c_void_p:
    return ctypes.c_void_p(tensor.data_ptr())


class RawKernel:
    def __init__(self) -> None:
        self.library = ctypes.CDLL(LIBRARY)
        self.library.netra_mxfp4_sgl_init.restype = ctypes.c_int
        self.library.netra_mxfp4_sgl_error.restype = ctypes.c_char_p
        self.library.netra_qkvzba_split_copy.argtypes = (
            [ctypes.c_void_p] * 6
            + [ctypes.c_uint, ctypes.c_void_p]
        )
        self.library.netra_qkvzba_split_copy.restype = ctypes.c_int
        status = self.library.netra_mxfp4_sgl_init()
        if status:
            raise RuntimeError(
                self.library.netra_mxfp4_sgl_error().decode()
            )

    def __call__(
        self,
        mixed_qkvz: torch.Tensor,
        mixed_ba: torch.Tensor,
        mixed_qkv: torch.Tensor,
        z: torch.Tensor,
        b: torch.Tensor,
        a: torch.Tensor,
    ) -> None:
        stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
        status = self.library.netra_qkvzba_split_copy(
            pointer(mixed_qkvz),
            pointer(mixed_ba),
            pointer(mixed_qkv),
            pointer(z),
            pointer(b),
            pointer(a),
            mixed_qkvz.shape[0],
            stream,
        )
        if status:
            raise RuntimeError(f"raw gfx1151 launch failed: {status}")


def allocate_outputs(tokens: int) -> tuple[torch.Tensor, ...]:
    device = torch.device("cuda")
    return (
        torch.empty((tokens, 8192), dtype=torch.bfloat16, device=device),
        torch.empty((tokens, 32, 128), dtype=torch.bfloat16, device=device),
        torch.empty((tokens, 32), dtype=torch.bfloat16, device=device),
        torch.empty((tokens, 32), dtype=torch.bfloat16, device=device),
    )


def allocate(tokens: int) -> tuple[torch.Tensor, ...]:
    device = torch.device("cuda")
    return (
        torch.randn((tokens, 12288), dtype=torch.bfloat16, device=device),
        torch.randn((tokens, 64), dtype=torch.bfloat16, device=device),
        *allocate_outputs(tokens),
    )


def time_call(call, warmup: int, repetitions: int) -> list[float]:
    for _ in range(warmup):
        call()
    torch.cuda.synchronize()
    values = []
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    for _ in range(repetitions):
        start.record()
        call()
        end.record()
        end.synchronize()
        values.append(start.elapsed_time(end))
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tokens", nargs="+", type=int, default=[1, 64, 210, 8192])
    parser.add_argument("--warmup", type=int, default=20)
    parser.add_argument("--repetitions", type=int, default=100)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("results/kernels/gfx1151/qkvzba-split-copy.json"),
    )
    args = parser.parse_args()
    torch.manual_seed(20260729)
    raw = RawKernel()
    results = []

    for tokens in args.tokens:
        raw_tensors = allocate(tokens)
        triton_tensors = (
            raw_tensors[0],
            raw_tensors[1],
            *allocate_outputs(tokens),
        )

        def launch_raw() -> None:
            raw(*raw_tensors)

        def launch_triton() -> None:
            qkvz, ba, qkv, z, b, a = triton_tensors
            fused_qkvzba_split_reshape_cat_contiguous_kernel[(tokens, 16)](
                qkv, z, b, a, qkvz, ba, 16, 32, 128, 128,
                num_warps=1, num_stages=3,
            )

        launch_raw()
        launch_triton()
        torch.cuda.synchronize()
        mismatches = [
            int(torch.count_nonzero(x.view(torch.int16) != y.view(torch.int16)).item())
            for x, y in zip(raw_tensors[2:], triton_tensors[2:])
        ]
        raw_ms = time_call(launch_raw, args.warmup, args.repetitions)
        triton_ms = time_call(launch_triton, args.warmup, args.repetitions)
        raw_median = statistics.median(raw_ms)
        triton_median = statistics.median(triton_ms)
        bytes_total = tokens * (12288 + 64 + 8192 + 4096 + 32 + 32) * 2
        results.append(
            {
                "tokens": tokens,
                "shape": [[tokens, 12288], [tokens, 64]],
                "bytes_read_written": bytes_total,
                "raw_asm_median_ms_hip_event": raw_median,
                "triton_median_ms_hip_event": triton_median,
                "speedup": triton_median / raw_median,
                "raw_asm_min_max_ms": [min(raw_ms), max(raw_ms)],
                "triton_min_max_ms": [min(triton_ms), max(triton_ms)],
                "bit_mismatches_qkv_z_b_a": mismatches,
            }
        )
        del raw_tensors, triton_tensors
        torch.cuda.empty_cache()

    report = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "timing": "HIP events",
        "raw_compute": "hand-written AMDGCN .s",
        "baseline_compute": "SGLang Triton",
        "warmup": args.warmup,
        "repetitions": args.repetitions,
        "results": results,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
