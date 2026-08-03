#!/usr/bin/env python3
"""Replay the exact Qwen3.6 M=756 extend-attention capture on gfx950.

This is a tiling oracle for the raw-assembly design. It invokes the pinned
SGLang Triton kernel directly with identical tensors and scalars, validates
every variant against the captured deployed output, and uses device events for
timing. No tensor or checkpoint dtype is converted in the kernel path.
"""

from __future__ import annotations

import argparse
import ctypes
import json
import math
from pathlib import Path

import torch
import triton
import triton.language as tl

from sglang.srt.layers.attention.triton_ops.extend_attention import _fwd_kernel


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--warmup", type=int, default=5)
    parser.add_argument("--repeats", type=int, default=30)
    parser.add_argument(
        "--raw-hsaco",
        type=Path,
        help=(
            "optionally replay an independently assembled gfx950 code object "
            "with the exact specialized Triton ABI"
        ),
    )
    parser.add_argument(
        "--raw-symbol",
        default="_fwd_kernel",
        help="kernel symbol in --raw-hsaco",
    )
    parser.add_argument(
        "--grouped-gqa4",
        action="store_true",
        help="screen one 4-wave workgroup per sequence/KV head",
    )
    parser.add_argument(
        "--grouped-gqa8",
        action="store_true",
        help="screen grouped target-attention GQA8 tiles with native FP8 KV",
    )
    parser.add_argument(
        "--grouped-gqa8-sizes",
        default="2,4",
        help="comma-separated query-head group sizes dividing the GQA8 group",
    )
    parser.add_argument(
        "--sliding-window-size",
        type=int,
        default=4095,
        help="captured attention window; use -1 for target full attention",
    )
    parser.add_argument(
        "--grouped-raw-hsaco",
        type=Path,
        help="replay an independently assembled grouped-GQA4 code object",
    )
    parser.add_argument(
        "--grouped-raw-symbol",
        default="_grouped_gqa4_fwd_kernel",
    )
    parser.add_argument(
        "--grouped-gqa8-raw-hsaco",
        type=Path,
        help="replay the raw grouped GQA8/D256/native-FP8-KV code object",
    )
    parser.add_argument(
        "--grouped-gqa8-raw-symbol",
        default="qwen36_extend_attention_m16_gqa8_fp8kv_gfx950",
    )
    parser.add_argument(
        "--grouped-qo-indptr-int64",
        action="store_true",
        help="replay the live piecewise-graph int64 qo_indptr ABI",
    )
    parser.add_argument(
        "--variants",
        default="16x32x4,16x64x4,16x128x4,32x32x4,32x64x4,32x128x4,64x64x4,64x128x4",
        help=(
            "comma-separated BLOCK_M x BLOCK_N x num_warps, optionally "
            "followed by x kpack"
        ),
    )
    return parser.parse_args()


def percentiles(values: list[float]) -> dict[str, float]:
    samples = torch.tensor(values, dtype=torch.float64)
    return {
        "mean_us": float(samples.mean()),
        "median_us": float(samples.quantile(0.5)),
        "p90_us": float(samples.quantile(0.9)),
        "min_us": float(samples.min()),
        "max_us": float(samples.max()),
    }


@triton.jit
def _grouped_gqa4_fwd_kernel(
    q_extend,
    k_extend,
    v_extend,
    output,
    k_buffer,
    v_buffer,
    qo_indptr,
    kv_indptr,
    kv_indices,
    sm_scale,
    stride_qbs: tl.constexpr,
    stride_qh: tl.constexpr,
    stride_kbs: tl.constexpr,
    stride_kh: tl.constexpr,
    stride_vbs: tl.constexpr,
    stride_vh: tl.constexpr,
    stride_obs: tl.constexpr,
    stride_oh: tl.constexpr,
    stride_buf_kbs: tl.constexpr,
    stride_buf_kh: tl.constexpr,
    stride_buf_vbs: tl.constexpr,
    stride_buf_vh: tl.constexpr,
):
    """Exact Qwen dFlash M<=16 GQA4 attention tiling oracle."""

    cur_seq = tl.program_id(0)
    cur_kv_head = tl.program_id(1)
    q_start = tl.load(qo_indptr + cur_seq)
    q_len = tl.load(qo_indptr + cur_seq + 1) - q_start
    kv_start = tl.load(kv_indptr + cur_seq)
    prefix_len = tl.load(kv_indptr + cur_seq + 1) - kv_start

    offs_flat_m = tl.arange(0, 64)
    offs_token = offs_flat_m & 15
    offs_gqa_head = offs_flat_m >> 4
    offs_d = tl.arange(0, 128)
    offs_n = tl.arange(0, 64)
    mask_m = offs_token < q_len

    q_offsets = (
        (q_start + offs_token[:, None]) * stride_qbs
        + (cur_kv_head * 4 + offs_gqa_head[:, None]) * stride_qh
        + offs_d[None, :]
    )
    q = tl.load(q_extend + q_offsets, mask=mask_m[:, None], other=0.0)

    acc = tl.zeros([64, 128], tl.float32)
    deno = tl.zeros([64], tl.float32)
    e_max = tl.full([64], float("-inf"), tl.float32)

    for start_n in range(0, prefix_len, 64):
        start_n = tl.multiple_of(start_n, 64)
        mask_n = start_n + offs_n < prefix_len
        final_mask = mask_m[:, None] & mask_n[None, :]
        final_mask &= (prefix_len + offs_token[:, None]) <= (
            start_n + offs_n[None, :] + 4095
        )
        skip_tile = tl.max(tl.max(final_mask.to(tl.int32), axis=1), axis=0) == 0
        if not skip_tile:
            kv_locations = tl.load(
                kv_indices + kv_start + start_n + offs_n,
                mask=mask_n,
                other=0,
            )
            k_offsets = (
                kv_locations[None, :] * stride_buf_kbs
                + cur_kv_head * stride_buf_kh
                + offs_d[:, None]
            )
            k = tl.load(
                k_buffer + k_offsets,
                mask=mask_n[None, :],
                other=0.0,
            )
            qk = tl.dot(q, k, out_dtype=tl.float32) * sm_scale
            qk = tl.where(final_mask, qk, float("-inf"))
            row_max = tl.max(qk, axis=1)
            row_max = tl.where(row_max == float("-inf"), -1.0e20, row_max)
            next_max = tl.maximum(row_max, e_max)
            rescale = tl.exp(e_max - next_max)
            probabilities = tl.exp(qk - next_max[:, None])
            deno = deno * rescale + tl.sum(probabilities, axis=1)

            v_offsets = (
                kv_locations[:, None] * stride_buf_vbs
                + cur_kv_head * stride_buf_vh
                + offs_d[None, :]
            )
            v = tl.load(
                v_buffer + v_offsets,
                mask=mask_n[:, None],
                other=0.0,
            )
            acc = acc * rescale[:, None] + tl.dot(
                probabilities.to(v.dtype), v, out_dtype=tl.float32
            )
            e_max = next_max

    mask_n = offs_n < q_len
    final_mask = mask_m[:, None] & mask_n[None, :]
    final_mask &= offs_token[:, None] >= offs_n[None, :]
    k_offsets = (
        (q_start + offs_n[None, :]) * stride_kbs
        + cur_kv_head * stride_kh
        + offs_d[:, None]
    )
    k = tl.load(k_extend + k_offsets, mask=mask_n[None, :], other=0.0)
    qk = tl.dot(q, k, out_dtype=tl.float32) * sm_scale
    qk = tl.where(final_mask, qk, float("-inf"))
    row_max = tl.max(qk, axis=1)
    row_max = tl.where(row_max == float("-inf"), -1.0e20, row_max)
    next_max = tl.maximum(row_max, e_max)
    rescale = tl.exp(e_max - next_max)
    probabilities = tl.exp(qk - next_max[:, None])
    deno = deno * rescale + tl.sum(probabilities, axis=1)

    v_offsets = (
        (q_start + offs_n[:, None]) * stride_vbs
        + cur_kv_head * stride_vh
        + offs_d[None, :]
    )
    v = tl.load(v_extend + v_offsets, mask=mask_n[:, None], other=0.0)
    acc = acc * rescale[:, None] + tl.dot(
        probabilities.to(v.dtype), v, out_dtype=tl.float32
    )

    output_offsets = (
        (q_start + offs_token[:, None]) * stride_obs
        + (cur_kv_head * 4 + offs_gqa_head[:, None]) * stride_oh
        + offs_d[None, :]
    )
    tl.store(
        output + output_offsets,
        acc / deno[:, None],
        mask=mask_m[:, None],
    )


@triton.jit
def _grouped_gqa8_fp8kv_fwd_kernel(
    q_extend,
    k_extend,
    v_extend,
    output,
    k_buffer,
    v_buffer,
    qo_indptr,
    kv_indptr,
    kv_indices,
    sm_scale,
    stride_qbs: tl.constexpr,
    stride_qh: tl.constexpr,
    stride_kbs: tl.constexpr,
    stride_kh: tl.constexpr,
    stride_vbs: tl.constexpr,
    stride_vh: tl.constexpr,
    stride_obs: tl.constexpr,
    stride_oh: tl.constexpr,
    stride_buf_kbs: tl.constexpr,
    stride_buf_kh: tl.constexpr,
    stride_buf_vbs: tl.constexpr,
    stride_buf_vh: tl.constexpr,
    GROUPED_Q_HEADS: tl.constexpr,
    GROUPED_M: tl.constexpr,
    HEAD_DIM: tl.constexpr,
    KV_GROUP_NUM: tl.constexpr,
    SLIDING_WINDOW_SIZE: tl.constexpr,
):
    """Qwen target GQA8 attention with native E4M3 prefix K/V."""

    cur_seq = tl.program_id(0)
    cur_kv_head = tl.program_id(1)
    cur_q_head_group = tl.program_id(2)
    q_start = tl.load(qo_indptr + cur_seq)
    q_len = tl.load(qo_indptr + cur_seq + 1) - q_start
    kv_start = tl.load(kv_indptr + cur_seq)
    prefix_len = tl.load(kv_indptr + cur_seq + 1) - kv_start

    offs_flat_m = tl.arange(0, GROUPED_M)
    offs_token = offs_flat_m & 15
    offs_group_head = offs_flat_m >> 4
    offs_d = tl.arange(0, HEAD_DIM)
    offs_n = tl.arange(0, 64)
    mask_m = offs_token < q_len
    q_head = (
        cur_kv_head * KV_GROUP_NUM
        + cur_q_head_group * GROUPED_Q_HEADS
        + offs_group_head
    )

    q_offsets = (
        (q_start + offs_token[:, None]) * stride_qbs
        + q_head[:, None] * stride_qh
        + offs_d[None, :]
    )
    q = tl.load(q_extend + q_offsets, mask=mask_m[:, None], other=0.0)

    acc = tl.zeros([GROUPED_M, HEAD_DIM], tl.float32)
    deno = tl.zeros([GROUPED_M], tl.float32)
    e_max = tl.full([GROUPED_M], float("-inf"), tl.float32)

    for start_n in range(0, prefix_len, 64):
        start_n = tl.multiple_of(start_n, 64)
        mask_n = start_n + offs_n < prefix_len
        final_mask = mask_m[:, None] & mask_n[None, :]
        if SLIDING_WINDOW_SIZE > 0:
            final_mask &= (prefix_len + offs_token[:, None]) <= (
                start_n + offs_n[None, :] + SLIDING_WINDOW_SIZE
            )
        skip_tile = tl.max(tl.max(final_mask.to(tl.int32), axis=1), axis=0) == 0
        if not skip_tile:
            kv_locations = tl.load(
                kv_indices + kv_start + start_n + offs_n,
                mask=mask_n,
                other=0,
            )
            k_offsets = (
                kv_locations[None, :] * stride_buf_kbs
                + cur_kv_head * stride_buf_kh
                + offs_d[:, None]
            )
            k = tl.load(k_buffer + k_offsets, mask=mask_n[None, :], other=0.0)
            qk = tl.dot(q.to(k.dtype), k, out_dtype=tl.float32) * sm_scale
            qk = tl.where(final_mask, qk, float("-inf"))
            row_max = tl.max(qk, axis=1)
            row_max = tl.where(row_max == float("-inf"), -1.0e20, row_max)
            next_max = tl.maximum(row_max, e_max)
            rescale = tl.exp(e_max - next_max)
            probabilities = tl.exp(qk - next_max[:, None])
            deno = deno * rescale + tl.sum(probabilities, axis=1)

            v_offsets = (
                kv_locations[:, None] * stride_buf_vbs
                + cur_kv_head * stride_buf_vh
                + offs_d[None, :]
            )
            v = tl.load(v_buffer + v_offsets, mask=mask_n[:, None], other=0.0)
            acc = acc * rescale[:, None] + tl.dot(
                probabilities.to(v.dtype), v, out_dtype=tl.float32
            )
            e_max = next_max

    mask_n = offs_n < q_len
    final_mask = mask_m[:, None] & mask_n[None, :]
    final_mask &= offs_token[:, None] >= offs_n[None, :]
    k_offsets = (
        (q_start + offs_n[None, :]) * stride_kbs
        + cur_kv_head * stride_kh
        + offs_d[:, None]
    )
    k = tl.load(k_extend + k_offsets, mask=mask_n[None, :], other=0.0)
    qk = tl.dot(q.to(k.dtype), k, out_dtype=tl.float32) * sm_scale
    qk = tl.where(final_mask, qk, float("-inf"))
    row_max = tl.max(qk, axis=1)
    row_max = tl.where(row_max == float("-inf"), -1.0e20, row_max)
    next_max = tl.maximum(row_max, e_max)
    rescale = tl.exp(e_max - next_max)
    probabilities = tl.exp(qk - next_max[:, None])
    deno = deno * rescale + tl.sum(probabilities, axis=1)

    v_offsets = (
        (q_start + offs_n[:, None]) * stride_vbs
        + cur_kv_head * stride_vh
        + offs_d[None, :]
    )
    v = tl.load(v_extend + v_offsets, mask=mask_n[:, None], other=0.0)
    acc = acc * rescale[:, None] + tl.dot(
        probabilities.to(v.dtype), v, out_dtype=tl.float32
    )

    output_offsets = (
        (q_start + offs_token[:, None]) * stride_obs
        + q_head[:, None] * stride_oh
        + offs_d[None, :]
    )
    tl.store(output + output_offsets, acc / deno[:, None], mask=mask_m[:, None])


class RawHipModule:
    """Minimal HIP module bridge for the exact captured attention ABI."""

    def __init__(self, hsaco: Path, symbol: str) -> None:
        self._hip = ctypes.CDLL("libamdhip64.so")
        self._module = ctypes.c_void_p()
        self._function = ctypes.c_void_p()
        self._hip.hipModuleLoad.argtypes = [
            ctypes.POINTER(ctypes.c_void_p),
            ctypes.c_char_p,
        ]
        self._hip.hipModuleLoad.restype = ctypes.c_int
        self._hip.hipModuleGetFunction.argtypes = [
            ctypes.POINTER(ctypes.c_void_p),
            ctypes.c_void_p,
            ctypes.c_char_p,
        ]
        self._hip.hipModuleGetFunction.restype = ctypes.c_int
        self._hip.hipModuleLaunchKernel.argtypes = [
            ctypes.c_void_p,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_void_p),
            ctypes.c_void_p,
        ]
        self._hip.hipModuleLaunchKernel.restype = ctypes.c_int
        self._hip.hipModuleUnload.argtypes = [ctypes.c_void_p]
        self._hip.hipModuleUnload.restype = ctypes.c_int
        self._check(
            self._hip.hipModuleLoad(
                ctypes.byref(self._module), str(hsaco).encode("utf-8")
            ),
            "hipModuleLoad",
        )
        self._check(
            self._hip.hipModuleGetFunction(
                ctypes.byref(self._function),
                self._module,
                symbol.encode("utf-8"),
            ),
            "hipModuleGetFunction",
        )

    def close(self) -> None:
        if self._module.value:
            self._check(self._hip.hipModuleUnload(self._module), "hipModuleUnload")
            self._module = ctypes.c_void_p()
            self._function = ctypes.c_void_p()

    @staticmethod
    def _check(status: int, operation: str) -> None:
        if status != 0:
            raise RuntimeError(f"{operation} failed with HIP status {status}")

    @staticmethod
    def _device_pointer(tensor: torch.Tensor | None) -> ctypes.c_void_p:
        return ctypes.c_void_p(0 if tensor is None else tensor.data_ptr())

    def launch(
        self,
        *,
        q: torch.Tensor,
        k_extend: torch.Tensor,
        v_extend: torch.Tensor,
        output: torch.Tensor,
        k_buffer: torch.Tensor,
        v_buffer: torch.Tensor,
        qo_indptr: torch.Tensor,
        kv_indptr: torch.Tensor,
        kv_indices: torch.Tensor,
        mask_indptr: torch.Tensor | None,
        window_kv_offsets: torch.Tensor | None,
        sm_scale: float,
        kv_group_num: int,
        batch_size: int,
        heads: int,
    ) -> None:
        values: list[ctypes._SimpleCData] = [
            self._device_pointer(q),
            self._device_pointer(k_extend),
            self._device_pointer(v_extend),
            self._device_pointer(output),
            self._device_pointer(k_buffer),
            self._device_pointer(v_buffer),
            self._device_pointer(qo_indptr),
            self._device_pointer(kv_indptr),
            self._device_pointer(kv_indices),
            self._device_pointer(mask_indptr),
            self._device_pointer(window_kv_offsets),
            ctypes.c_float(sm_scale),
            ctypes.c_float(1.0),
            ctypes.c_float(1.0),
            ctypes.c_int32(kv_group_num),
            ctypes.c_int32(q.stride(0)),
            ctypes.c_int32(q.stride(1)),
            ctypes.c_int32(k_extend.stride(0)),
            ctypes.c_int32(k_extend.stride(1)),
            ctypes.c_int32(v_extend.stride(0)),
            ctypes.c_int32(v_extend.stride(1)),
            ctypes.c_int32(output.stride(0)),
            ctypes.c_int32(output.stride(1)),
            ctypes.c_int32(k_buffer.stride(0)),
            ctypes.c_int32(k_buffer.stride(1)),
            ctypes.c_int32(v_buffer.stride(0)),
            ctypes.c_int32(v_buffer.stride(1)),
            ctypes.c_int32(batch_size),
            ctypes.c_void_p(),
            ctypes.c_void_p(),
        ]
        arguments = (ctypes.c_void_p * len(values))(
            *(ctypes.cast(ctypes.byref(value), ctypes.c_void_p) for value in values)
        )
        self._check(
            self._hip.hipModuleLaunchKernel(
                self._function,
                batch_size,
                heads,
                1,
                64,
                1,
                1,
                16384,
                ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
                arguments,
                None,
            ),
            "hipModuleLaunchKernel",
        )

    def launch_grouped_gqa4(
        self,
        *,
        q: torch.Tensor,
        k_extend: torch.Tensor,
        v_extend: torch.Tensor,
        output: torch.Tensor,
        k_buffer: torch.Tensor,
        v_buffer: torch.Tensor,
        qo_indptr: torch.Tensor,
        kv_indptr: torch.Tensor,
        kv_indices: torch.Tensor,
        sm_scale: float,
        batch_size: int,
        kv_heads: int,
    ) -> None:
        values: list[ctypes._SimpleCData] = [
            self._device_pointer(q),
            self._device_pointer(k_extend),
            self._device_pointer(v_extend),
            self._device_pointer(output),
            self._device_pointer(k_buffer),
            self._device_pointer(v_buffer),
            self._device_pointer(qo_indptr),
            self._device_pointer(kv_indptr),
            self._device_pointer(kv_indices),
            ctypes.c_float(sm_scale),
            ctypes.c_void_p(),
            ctypes.c_void_p(),
        ]
        arguments = (ctypes.c_void_p * len(values))(
            *(ctypes.cast(ctypes.byref(value), ctypes.c_void_p) for value in values)
        )
        self._check(
            self._hip.hipModuleLaunchKernel(
                self._function,
                batch_size,
                kv_heads,
                1,
                256,
                1,
                1,
                16384,
                ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
                arguments,
                None,
            ),
            "hipModuleLaunchKernel(grouped_gqa4)",
        )

    def launch_grouped_gqa8(
        self,
        *,
        q: torch.Tensor,
        k_extend: torch.Tensor,
        v_extend: torch.Tensor,
        output: torch.Tensor,
        k_buffer: torch.Tensor,
        v_buffer: torch.Tensor,
        qo_indptr: torch.Tensor,
        kv_indptr: torch.Tensor,
        kv_indices: torch.Tensor,
        sm_scale: float,
        batch_size: int,
        kv_heads: int,
        q_head_groups: int,
    ) -> None:
        values: list[ctypes._SimpleCData] = [
            self._device_pointer(q),
            self._device_pointer(k_extend),
            self._device_pointer(v_extend),
            self._device_pointer(output),
            self._device_pointer(k_buffer),
            self._device_pointer(v_buffer),
            self._device_pointer(qo_indptr),
            self._device_pointer(kv_indptr),
            self._device_pointer(kv_indices),
            ctypes.c_float(sm_scale),
            ctypes.c_uint32(qo_indptr.element_size()),
            ctypes.c_void_p(),
            ctypes.c_void_p(),
        ]
        arguments = (ctypes.c_void_p * len(values))(
            *(ctypes.cast(ctypes.byref(value), ctypes.c_void_p) for value in values)
        )
        self._check(
            self._hip.hipModuleLaunchKernel(
                self._function,
                batch_size,
                kv_heads,
                q_head_groups,
                512,
                1,
                1,
                32768,
                ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
                arguments,
                None,
            ),
            "hipModuleLaunchKernel(grouped_gqa8)",
        )


def evaluate_launch(
    launch,
    output: torch.Tensor,
    expected: torch.Tensor,
    warmup: int,
    repeats: int,
) -> tuple[dict[str, object], dict[str, float]]:
    for _ in range(warmup):
        launch()
    torch.cuda.synchronize()
    first = output.clone()
    launch()
    torch.cuda.synchronize()
    deterministic = bool(torch.equal(first, output))

    actual_f32 = output.float()
    expected_f32 = expected.float()
    delta = actual_f32 - expected_f32
    absolute_delta = delta.abs()
    worst_flat_index = int(absolute_delta.reshape(-1).argmax().item())
    relative_delta = absolute_delta / expected_f32.abs().clamp_min(1.0e-6)
    applicable_relative = ~(
        (actual_f32.abs() < 0.0625) & (expected_f32.abs() < 0.0625)
    )
    max_relative = (
        float(relative_delta[applicable_relative].max().item())
        if bool(applicable_relative.any().item())
        else 0.0
    )
    correctness: dict[str, object] = {
        "bf16_mismatches": int(torch.ne(output, expected).sum().item()),
        "elements": output.numel(),
        "max_abs": float(absolute_delta.max().item()),
        "mean_abs": float(absolute_delta.mean().item()),
        "rmse": float(torch.sqrt(torch.mean(delta * delta)).item()),
        "max_relative": max_relative,
        "worst_flat_index": worst_flat_index,
        "nan_count": int(torch.isnan(actual_f32).sum().item()),
        "inf_count": int(torch.isinf(actual_f32).sum().item()),
        "cosine": float(
            torch.nn.functional.cosine_similarity(
                actual_f32.reshape(1, -1), expected_f32.reshape(1, -1)
            ).item()
        ),
        "deterministic_two_launches": deterministic,
    }

    timings: list[float] = []
    start = torch.cuda.Event(enable_timing=True)
    stop = torch.cuda.Event(enable_timing=True)
    for _ in range(repeats):
        start.record()
        launch()
        stop.record()
        stop.synchronize()
        timings.append(start.elapsed_time(stop) * 1000.0)
    return correctness, percentiles(timings)


def main() -> None:
    args = parse_args()
    if args.warmup < 1 or args.repeats < 2:
        raise ValueError("warmup must be >=1 and repeats must be >=2")
    props = torch.cuda.get_device_properties(0)
    arch = str(getattr(props, "gcnArchName", ""))
    if not arch.startswith("gfx950"):
        raise RuntimeError(f"refusing non-gfx950 device: {arch}")

    retained = torch.load(args.capture, map_location="cpu", weights_only=True)
    expected = retained.pop("output").contiguous()
    tensors = {
        name: None if value is None else value.cuda().contiguous()
        for name, value in retained.items()
        if name != "kv_indices_original"
    }
    q = tensors["q_extend"]
    k_extend = tensors["k_extend"]
    v_extend = tensors["v_extend"]
    k_buffer = tensors["k_buffer"]
    v_buffer = tensors["v_buffer"]
    qo_indptr = tensors["qo_indptr"]
    if args.grouped_qo_indptr_int64:
        qo_indptr = qo_indptr.to(torch.int64)
    kv_indptr = tensors["kv_indptr"]
    kv_indices = tensors["kv_indices"]
    custom_mask = tensors["custom_mask"]
    mask_indptr = tensors["mask_indptr"]
    sinks = tensors["sinks"]
    window_kv_offsets = tensors["window_kv_offsets"]

    batch_size = qo_indptr.numel() - 1
    heads = q.shape[1]
    kv_group_num = heads // k_buffer.shape[1]
    max_len_extend = int((qo_indptr[1:] - qo_indptr[:-1]).max().item())
    head_dim = q.shape[-1]
    sm_scale = 1.0 / math.sqrt(q.shape[-1])
    output = torch.empty_like(q)
    expected_device = expected.cuda()

    results: list[dict[str, object]] = []
    for encoded in (value for value in args.variants.split(",") if value):
        fields = tuple(int(value) for value in encoded.split("x"))
        if len(fields) == 3:
            block_m, block_n, num_warps = fields
            kpack = 1
        elif len(fields) == 4:
            block_m, block_n, num_warps, kpack = fields
        else:
            raise ValueError(f"expected MxNxwarps[xkpack], got {encoded}")
        if block_m not in (8, 16, 32, 64, 128) or block_n not in (
            16,
            32,
            64,
            128,
        ):
            raise ValueError(f"unsupported tile in {encoded}")
        if kpack not in (1, 2, 4):
            raise ValueError(f"unsupported kpack in {encoded}")
        grid = (batch_size, heads, triton_cdiv(max_len_extend, block_m))

        def launch() -> None:
            _fwd_kernel[grid](
                q,
                k_extend,
                v_extend,
                output,
                k_buffer,
                v_buffer,
                qo_indptr,
                kv_indptr,
                kv_indices,
                custom_mask,
                mask_indptr,
                sinks,
                window_kv_offsets,
                sm_scale,
                1.0,
                1.0,
                kv_group_num,
                q.stride(0),
                q.stride(1),
                k_extend.stride(0),
                k_extend.stride(1),
                v_extend.stride(0),
                v_extend.stride(1),
                output.stride(0),
                output.stride(1),
                k_buffer.stride(0),
                k_buffer.stride(1),
                v_buffer.stride(0),
                v_buffer.stride(1),
                batch_size,
                SLIDING_WINDOW_SIZE=args.sliding_window_size,
                logit_cap=0.0,
                xai_temperature_len=-1,
                BLOCK_DMODEL=head_dim,
                BLOCK_DPE=0,
                BLOCK_DV=head_dim,
                BLOCK_M=block_m,
                BLOCK_N=block_n,
                Lq=head_dim,
                Lv=head_dim,
                USE_CUSTOM_MASK=False,
                IS_CAUSAL=True,
                SKIP_PREFIX_CUSTOM_MASK=True,
                HAS_SINK=False,
                STORE_TRANSPOSE=True,
                USE_COMPACT_TILE_GRID=False,
                num_warps=num_warps,
                num_stages=1,
                waves_per_eu=1,
                matrix_instr_nonkdim=16,
                kpack=kpack,
            )

        correctness, timing = evaluate_launch(
            launch, output, expected_device, args.warmup, args.repeats
        )
        item = {
            "variant": encoded,
            "grid": list(grid),
            "correctness": correctness,
            "timing": timing,
        }
        results.append(item)
        print(json.dumps(item, sort_keys=True), flush=True)

    if args.grouped_gqa8:
        if kv_group_num != 8 or head_dim != 256:
            raise ValueError(
                "--grouped-gqa8 requires the target GQA8, head_dim=256 capture"
            )
        for grouped_q_heads in (
            int(value) for value in args.grouped_gqa8_sizes.split(",") if value
        ):
            if grouped_q_heads not in (1, 2, 4, 8):
                raise ValueError("grouped GQA8 size must be one of 1,2,4,8")
            grouped_m = grouped_q_heads * 16
            grouped_grid = (
                batch_size,
                k_buffer.shape[1],
                kv_group_num // grouped_q_heads,
            )

            def launch_grouped_gqa8() -> None:
                _grouped_gqa8_fp8kv_fwd_kernel[grouped_grid](
                    q,
                    k_extend,
                    v_extend,
                    output,
                    k_buffer,
                    v_buffer,
                    qo_indptr,
                    kv_indptr,
                    kv_indices,
                    sm_scale,
                    stride_qbs=q.stride(0),
                    stride_qh=q.stride(1),
                    stride_kbs=k_extend.stride(0),
                    stride_kh=k_extend.stride(1),
                    stride_vbs=v_extend.stride(0),
                    stride_vh=v_extend.stride(1),
                    stride_obs=output.stride(0),
                    stride_oh=output.stride(1),
                    stride_buf_kbs=k_buffer.stride(0),
                    stride_buf_kh=k_buffer.stride(1),
                    stride_buf_vbs=v_buffer.stride(0),
                    stride_buf_vh=v_buffer.stride(1),
                    GROUPED_Q_HEADS=grouped_q_heads,
                    GROUPED_M=grouped_m,
                    HEAD_DIM=head_dim,
                    KV_GROUP_NUM=kv_group_num,
                    SLIDING_WINDOW_SIZE=args.sliding_window_size,
                    num_warps=8,
                    num_stages=1,
                    waves_per_eu=1,
                    matrix_instr_nonkdim=16,
                    kpack=2,
                )

            correctness, timing = evaluate_launch(
                launch_grouped_gqa8,
                output,
                expected_device,
                args.warmup,
                args.repeats,
            )
            item = {
                "variant": f"grouped_gqa8_fp8kv_h{grouped_q_heads}",
                "grid": list(grouped_grid),
                "correctness": correctness,
                "timing": timing,
            }
            results.append(item)
            print(json.dumps(item, sort_keys=True), flush=True)

    if args.grouped_gqa8_raw_hsaco is not None:
        if kv_group_num != 8 or head_dim != 256:
            raise ValueError(
                "--grouped-gqa8-raw-hsaco requires GQA8 with head_dim=256"
            )
        grouped_gqa8_raw = RawHipModule(
            args.grouped_gqa8_raw_hsaco,
            args.grouped_gqa8_raw_symbol,
        )
        try:

            def launch_grouped_gqa8_raw() -> None:
                grouped_gqa8_raw.launch_grouped_gqa8(
                    q=q,
                    k_extend=k_extend,
                    v_extend=v_extend,
                    output=output,
                    k_buffer=k_buffer,
                    v_buffer=v_buffer,
                    qo_indptr=qo_indptr,
                    kv_indptr=kv_indptr,
                    kv_indices=kv_indices,
                    sm_scale=sm_scale,
                    batch_size=batch_size,
                    kv_heads=k_buffer.shape[1],
                    q_head_groups=2,
                )

            correctness, timing = evaluate_launch(
                launch_grouped_gqa8_raw,
                output,
                expected_device,
                args.warmup,
                args.repeats,
            )
            item = {
                "variant": "grouped_gqa8_fp8kv_h4_raw_hsaco",
                "hsaco": str(args.grouped_gqa8_raw_hsaco),
                "symbol": args.grouped_gqa8_raw_symbol,
                "grid": [batch_size, k_buffer.shape[1], 2],
                "block": [512, 1, 1],
                "dynamic_shared_bytes": 32768,
                "correctness": correctness,
                "timing": timing,
            }
            results.append(item)
            print(json.dumps(item, sort_keys=True), flush=True)
        finally:
            grouped_gqa8_raw.close()

    if args.grouped_gqa4:
        grouped_grid = (batch_size, k_buffer.shape[1])

        def launch_grouped_gqa4() -> None:
            _grouped_gqa4_fwd_kernel[grouped_grid](
                q,
                k_extend,
                v_extend,
                output,
                k_buffer,
                v_buffer,
                qo_indptr,
                kv_indptr,
                kv_indices,
                sm_scale,
                stride_qbs=q.stride(0),
                stride_qh=q.stride(1),
                stride_kbs=k_extend.stride(0),
                stride_kh=k_extend.stride(1),
                stride_vbs=v_extend.stride(0),
                stride_vh=v_extend.stride(1),
                stride_obs=output.stride(0),
                stride_oh=output.stride(1),
                stride_buf_kbs=k_buffer.stride(0),
                stride_buf_kh=k_buffer.stride(1),
                stride_buf_vbs=v_buffer.stride(0),
                stride_buf_vh=v_buffer.stride(1),
                num_warps=4,
                num_stages=1,
                waves_per_eu=1,
                matrix_instr_nonkdim=16,
                kpack=1,
            )

        correctness, timing = evaluate_launch(
            launch_grouped_gqa4,
            output,
            expected_device,
            args.warmup,
            args.repeats,
        )
        item = {
            "variant": "grouped_gqa4_64x64x4",
            "grid": list(grouped_grid),
            "correctness": correctness,
            "timing": timing,
        }
        results.append(item)
        print(json.dumps(item, sort_keys=True), flush=True)

    if args.grouped_raw_hsaco is not None:
        grouped_raw = RawHipModule(
            args.grouped_raw_hsaco, args.grouped_raw_symbol
        )
        try:

            def launch_grouped_raw() -> None:
                grouped_raw.launch_grouped_gqa4(
                    q=q,
                    k_extend=k_extend,
                    v_extend=v_extend,
                    output=output,
                    k_buffer=k_buffer,
                    v_buffer=v_buffer,
                    qo_indptr=qo_indptr,
                    kv_indptr=kv_indptr,
                    kv_indices=kv_indices,
                    sm_scale=sm_scale,
                    batch_size=batch_size,
                    kv_heads=k_buffer.shape[1],
                )

            correctness, timing = evaluate_launch(
                launch_grouped_raw,
                output,
                expected_device,
                args.warmup,
                args.repeats,
            )
            item = {
                "variant": "grouped_gqa4_raw_hsaco",
                "hsaco": str(args.grouped_raw_hsaco),
                "symbol": args.grouped_raw_symbol,
                "grid": [batch_size, k_buffer.shape[1], 1],
                "block": [256, 1, 1],
                "dynamic_shared_bytes": 16384,
                "correctness": correctness,
                "timing": timing,
            }
            results.append(item)
            print(json.dumps(item, sort_keys=True), flush=True)
        finally:
            grouped_raw.close()

    if args.raw_hsaco is not None:
        raw = RawHipModule(args.raw_hsaco, args.raw_symbol)
        try:

            def launch_raw() -> None:
                raw.launch(
                    q=q,
                    k_extend=k_extend,
                    v_extend=v_extend,
                    output=output,
                    k_buffer=k_buffer,
                    v_buffer=v_buffer,
                    qo_indptr=qo_indptr,
                    kv_indptr=kv_indptr,
                    kv_indices=kv_indices,
                    mask_indptr=mask_indptr,
                    window_kv_offsets=window_kv_offsets,
                    sm_scale=sm_scale,
                    kv_group_num=kv_group_num,
                    batch_size=batch_size,
                    heads=heads,
                )

            correctness, timing = evaluate_launch(
                launch_raw, output, expected_device, args.warmup, args.repeats
            )
            item = {
                "variant": "raw_hsaco",
                "hsaco": str(args.raw_hsaco),
                "symbol": args.raw_symbol,
                "grid": [batch_size, heads, 1],
                "block": [64, 1, 1],
                "dynamic_shared_bytes": 16384,
                "correctness": correctness,
                "timing": timing,
            }
            results.append(item)
            print(json.dumps(item, sort_keys=True), flush=True)
        finally:
            raw.close()

    payload = {
        "schema_version": 1,
        "architecture": arch,
        "capture": str(args.capture),
        "shape": {
            "query": list(q.shape),
            "key_buffer": list(k_buffer.shape),
            "value_buffer": list(v_buffer.shape),
            "batch_size": batch_size,
            "max_len_extend": max_len_extend,
            "kv_group_num": kv_group_num,
        },
        "results": results,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def triton_cdiv(left: int, right: int) -> int:
    return (left + right - 1) // right


if __name__ == "__main__":
    main()
