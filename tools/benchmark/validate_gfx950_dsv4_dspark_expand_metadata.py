#!/usr/bin/env python3
"""Validate and time raw gfx950 DSpARK metadata against fused Triton."""

from __future__ import annotations

import argparse
import ctypes
import json
from pathlib import Path

import torch
import triton
import triton.language as tl


@triton.jit
def _reference_kernel(
    req_pool_ptr,
    seq_lens_ptr,
    extend_lens_ptr,
    causal_ptr,
    repeated_ptr,
    batch,
    real_tokens,
    total_tokens,
    BLOCK: tl.constexpr,
    BS_P2: tl.constexpr,
):
    offs = tl.program_id(0) * BLOCK + tl.arange(0, BLOCK)
    mask = offs < total_tokens
    b = tl.arange(0, BS_P2)
    bmask = b < batch
    extend = tl.load(extend_lens_ptr + b, mask=bmask, other=0).to(tl.int32)
    starts = tl.cumsum(extend, axis=0) - extend
    is_real = offs < real_tokens
    token = tl.where(is_real, offs, 0).to(tl.int32)
    started = (starts[None, :] <= token[:, None]) & bmask[None, :]
    request = tl.sum(started.to(tl.int32), axis=1) - 1
    request = tl.where(is_real, request, batch - 1).to(tl.int64)
    seq_len = tl.load(seq_lens_ptr + request, mask=mask, other=0).to(tl.int32)
    ext = tl.load(extend_lens_ptr + request, mask=mask, other=0).to(tl.int32)
    start = tl.sum(
        tl.where(started, extend[None, :], 0).to(tl.int32), axis=1
    ) - ext
    causal = (seq_len - ext + 1) + (token - start)
    causal = tl.where(is_real, causal, 1)
    req = tl.load(req_pool_ptr + request, mask=mask, other=0)
    tl.store(causal_ptr + offs, causal, mask=mask)
    tl.store(repeated_ptr + offs, req, mask=mask)


class Bridge:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.library = ctypes.CDLL(str(library))
        self.library.netra_dsv4_dspark_expand_metadata_load.argtypes = [ctypes.c_char_p]
        self.library.netra_dsv4_dspark_expand_metadata_load.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_expand_metadata_launch.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_uint32,
            ctypes.c_uint32,
            ctypes.c_uint32,
            ctypes.c_void_p,
        ]
        self.library.netra_dsv4_dspark_expand_metadata_launch.restype = ctypes.c_int
        self.library.netra_dsv4_dspark_expand_metadata_last_error.restype = ctypes.c_char_p
        self.check(
            self.library.netra_dsv4_dspark_expand_metadata_load(str(hsaco).encode()),
            "load",
        )

    def check(self, status: int, operation: str) -> None:
        if status == 0:
            return
        raw = self.library.netra_dsv4_dspark_expand_metadata_last_error()
        raise RuntimeError(f"{operation}: {raw.decode() if raw else status}")

    def launch(
        self,
        causal: torch.Tensor,
        repeated: torch.Tensor,
        req: torch.Tensor,
        seq: torch.Tensor,
        ext: torch.Tensor,
        starts: torch.Tensor | None,
        real_tokens: int,
    ) -> None:
        ptr = lambda tensor: ctypes.c_void_p(0 if tensor is None else tensor.data_ptr())
        self.check(
            self.library.netra_dsv4_dspark_expand_metadata_launch(
                ptr(causal),
                ptr(repeated),
                ptr(req),
                ptr(seq),
                ptr(ext),
                ptr(starts),
                ctypes.c_uint32(req.numel()),
                ctypes.c_uint32(real_tokens),
                ctypes.c_uint32(causal.numel()),
                ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
            ),
            "launch",
        )


def elapsed_us(fn, iterations: int) -> float:
    begin = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    begin.record()
    for _ in range(iterations):
        fn()
    end.record()
    end.synchronize()
    return begin.elapsed_time(end) * 1000.0 / iterations


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", required=True, type=Path)
    parser.add_argument("--hsaco", required=True, type=Path)
    parser.add_argument("--iterations", type=int, default=2000)
    args = parser.parse_args()
    target = torch.cuda.get_device_properties(0).gcnArchName
    if "gfx950" not in target:
        raise SystemExit(f"requires gfx950, got {target}")
    bridge = Bridge(args.bridge.resolve(), args.hsaco.resolve())
    rows = []
    for batch in (1, 16, 32, 64, 128, 256):
        for ragged, padded, uniform_width in (
            (False, False, 5),
            (False, True, 5),
            (False, False, 6),
            (False, True, 6),
            (True, False, 0),
            (True, True, 0),
        ):
            if ragged:
                ext = 1 + (torch.arange(batch, device="cuda", dtype=torch.int32) * 5 + 3) % 6
            else:
                ext = torch.full(
                    (batch,), uniform_width, device="cuda", dtype=torch.int32
                )
            starts = (torch.cumsum(ext, 0) - ext).to(torch.int32)
            real_tokens = int(ext.sum().item())
            total_tokens = min(1536, real_tokens + (17 if padded else 0))
            req = (1 << 40) + 1000 + torch.arange(
                batch, device="cuda", dtype=torch.int64
            ) * 7
            seq = (
                128
                + torch.arange(batch, device="cuda", dtype=torch.int64) * 13
                + ext.to(torch.int64)
            )
            raw_causal = torch.empty(total_tokens, device="cuda", dtype=torch.int32)
            raw_repeated = torch.empty(total_tokens, device="cuda", dtype=torch.int64)
            tri_causal = torch.empty_like(raw_causal)
            tri_repeated = torch.empty_like(raw_repeated)

            raw_starts = starts if ragged else None
            bridge.launch(raw_causal, raw_repeated, req, seq, ext, raw_starts, real_tokens)
            launch_reference = lambda: _reference_kernel[(triton.cdiv(total_tokens, 256),)](
                req,
                seq,
                ext,
                tri_causal,
                tri_repeated,
                batch,
                real_tokens,
                total_tokens,
                BLOCK=256,
                BS_P2=triton.next_power_of_2(batch),
            )
            launch_reference()
            torch.cuda.synchronize()
            exact = torch.equal(raw_causal, tri_causal) and torch.equal(raw_repeated, tri_repeated)
            if not exact:
                mismatch = torch.nonzero(
                    (raw_causal != tri_causal) | (raw_repeated != tri_repeated)
                ).flatten()
                indices = mismatch[:8].cpu().tolist()
                detail = [
                    {
                        "token": i,
                        "raw": (int(raw_causal[i]), int(raw_repeated[i])),
                        "triton": (int(tri_causal[i]), int(tri_repeated[i])),
                    }
                    for i in indices
                ]
                raise RuntimeError(
                    f"parity failed: batch={batch} ragged={ragged} padded={padded} "
                    f"ext={ext.cpu().tolist()} starts={starts.cpu().tolist()} detail={detail}"
                )
            for _ in range(20):
                bridge.launch(raw_causal, raw_repeated, req, seq, ext, raw_starts, real_tokens)
                launch_reference()
            torch.cuda.synchronize()
            raw_us = elapsed_us(
                lambda: bridge.launch(raw_causal, raw_repeated, req, seq, ext, raw_starts, real_tokens),
                args.iterations,
            )
            triton_us = elapsed_us(launch_reference, args.iterations)
            rows.append(
                {
                    "batch": batch,
                    "real_tokens": real_tokens,
                    "total_tokens": total_tokens,
                    "ragged": ragged,
                    "padded": padded,
                    "uniform_width": uniform_width,
                    "raw_us": raw_us,
                    "triton_us": triton_us,
                    "speedup": triton_us / raw_us,
                    "exact": exact,
                }
            )
    print(json.dumps({"target": target, "iterations": args.iterations, "pass": True, "cases": rows}, indent=2))


if __name__ == "__main__":
    main()
