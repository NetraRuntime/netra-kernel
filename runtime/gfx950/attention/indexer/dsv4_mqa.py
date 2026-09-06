# SPDX-License-Identifier: MIT
"""Experimental gfx950 C4 scorer; explicit preload, no implicit production switch."""
import ctypes
from pathlib import Path

import torch


def select_schedule(rows, width):
    """Choose from CPU shape metadata; lengths stay on the caller's GPU.

    Query rows include speculative tokens, so these are not user counts.
    Retain the qualified original schedule for large/long workloads.
    Returns (mode, pages per wave); modes 1 and 4 ignore page reuse.
    """
    tasks = rows * ((width + 63) // 64)
    if rows >= 512 or width >= 65536 or tasks >= 65536:
        pages = 8 if width >= 65536 and rows >= 8 else 4
        return 0, 1 if tasks < 1024 else pages
    if tasks <= 128:
        return 1, 1
    if tasks <= 256:
        return 4, 1
    if tasks <= 512:
        return 5, 1
    # A four-wave CTA loads Q once. Prefetch the later K tiles when the
    # grid has at most 256 CTAs; above that, lower register use wins.
    if tasks <= 1024:
        return 13, 1
    if tasks <= 2048:
        return 10, 1
    if tasks <= 8192:
        return 10, 4 if tasks == 8192 else 2
    return 6, 4


class Scorer:
    def __init__(self, build_dir, device=None, pages_per_wave=None, mode=None):
        if mode not in (None, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13):
            raise ValueError("mode must be None (automatic) or an integer from 0 to 13")
        self.mode = mode
        if pages_per_wave not in (None, 1, 2, 4, 8):
            raise ValueError("pages_per_wave must be None, 1, 2, 4 or 8")
        self.pages_per_wave = pages_per_wave
        self.device = torch.device("cuda", torch.cuda.current_device() if device is None else device)
        self.lib = ctypes.CDLL(str(Path(build_dir) / "libnetra_mqa.so"))
        ptr, u32 = ctypes.c_void_p, ctypes.c_uint32
        self.lib.netra_mqa_error.restype = ctypes.c_char_p
        self.lib.netra_mqa_create.argtypes = [ctypes.c_char_p, ctypes.POINTER(ptr)]
        self.lib.netra_mqa_launch_v2.argtypes = [ptr] * 7 + [u32] * 9 + [ptr]
        self.lib.netra_mqa_destroy.argtypes = [ptr]
        self.handle = ptr()
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_mqa_create(
                str(Path(build_dir) / "scorer.hsaco").encode(), ctypes.byref(self.handle)))

    def _check(self, status):
        if status:
            raise RuntimeError(self.lib.netra_mqa_error().decode())

    def __call__(self, q, kv, weights, lengths, pages, out):
        tensors = (q, kv, weights, lengths, pages, out)
        if any(t.device != self.device for t in tensors):
            raise ValueError("all tensors must be on the module's owning device")
        if q.ndim != 4 or q.shape[1:] != (1, 64, 128) or q.dtype != torch.float8_e4m3fn:
            raise ValueError("requires Q [rows,1,64,128] E4M3FN")
        rows = q.shape[0]
        if q.stride(-1) != 1 or q.stride(-2) != 128:
            raise ValueError("requires contiguous query heads/dimensions")
        if kv.ndim != 4 or kv.shape[1:] != (64, 1, 132) or kv.dtype not in (torch.uint8, torch.int8, torch.float8_e4m3fn):
            raise ValueError("requires packed preshuffled KV [pages,64,1,132]")
        if kv.stride()[1:] != (132, 132, 1):
            raise ValueError("unsupported KV page layout")
        if weights.shape != (rows, 64) or weights.dtype != torch.float32 or weights.stride(1) != 1:
            raise ValueError("requires FP32 weights [rows,64]")
        if lengths.shape != (rows,) or lengths.dtype != torch.int32 or not lengths.is_contiguous():
            raise ValueError("requires contiguous int32 lengths [rows]")
        if pages.ndim != 2 or pages.shape[0] != rows or pages.dtype != torch.int32 or pages.stride(1) != 1:
            raise ValueError("requires int32 page table [rows,pages]")
        if out.ndim != 2 or out.shape[0] != rows or out.dtype != torch.float32 or out.stride(1) != 1:
            raise ValueError("requires FP32 output [rows,width]")
        width = out.shape[1]
        if not 1 <= rows <= 65535 or not 1 <= width <= 262144 or pages.shape[1] < (width + 63) // 64:
            raise ValueError("unsupported rows, width, or page-table capacity")
        strides = (out.stride(0), q.stride(0), weights.stride(0) * 4,
                   pages.stride(0) * 4, kv.stride(0))
        if any(s < 0 or s > 0xFFFFFFFF for s in strides):
            raise ValueError("stride exceeds ABI")
        # No scalar GPU reads, tensor copies, allocations, or stream synchronization.
        # lengths must be nonnegative and active page IDs must belong to the KV pool.
        if self.mode is None and self.pages_per_wave is None:
            mode, pages_per_wave = select_schedule(rows, width)
        else:
            # An explicit page count retains the original mode-0 override API.
            mode = 0 if self.mode is None else self.mode
            pages_per_wave = self.pages_per_wave
            if pages_per_wave is None:
                pages_per_wave = 8 if width >= 65536 and rows >= 8 else 4
                if rows * ((width + 63) // 64) < 1024:
                    pages_per_wave = 1
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_mqa_launch_v2(
                self.handle, *(t.data_ptr() for t in tensors), rows, *strides, width,
                pages_per_wave, mode,
                torch.cuda.current_stream(self.device).cuda_stream))
        return out

    def close(self):
        """Caller must first finish all eager and graph uses of this module."""
        if self.handle.value:
            with torch.cuda.device(self.device):
                self._check(self.lib.netra_mqa_destroy(self.handle))
            self.handle = ctypes.c_void_p()
