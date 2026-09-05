#!/usr/bin/env python3
"""Independent correctness, graph, stream, boundary, and timing validator."""

from __future__ import annotations

import argparse
import ctypes
import json
from pathlib import Path

import torch


MAX_TOKENS = 8192
WIDTHS = (0, 64, 320, 512)
TOKEN_BOUNDARIES = (0, 1, 255, 256, 257, 8191, 8192)


class Bridge:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.library = ctypes.CDLL(str(library))
        prefix = "netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1"
        self.load_fn = getattr(self.library, f"{prefix}_load")
        self.launch_fn = getattr(self.library, f"{prefix}_launch")
        self.error_fn = getattr(self.library, f"{prefix}_last_error")
        self.load_fn.argtypes = [ctypes.c_char_p]
        self.load_fn.restype = ctypes.c_int
        self.launch_fn.argtypes = [
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
        self.launch_fn.restype = ctypes.c_int
        self.error_fn.restype = ctypes.c_char_p
        self.check(self.load_fn(str(hsaco).encode()), "load")

    def error(self) -> str:
        raw = self.error_fn()
        return raw.decode() if raw else "unknown bridge error"

    def check(self, status: int, operation: str) -> None:
        if status != 0:
            raise RuntimeError(f"{operation}: {self.error()}")

    def launch(
        self,
        positions: torch.Tensor,
        chunk_start: torch.Tensor,
        compressed_lengths: torch.Tensor | None,
        prefix: torch.Tensor,
        extend: torch.Tensor,
        window: int,
        *,
        stream: torch.cuda.Stream | None = None,
        tokens_override: int | None = None,
        has_compress_override: int | None = None,
        check: bool = True,
    ) -> int:
        selected_stream = stream or torch.cuda.current_stream(positions.device)
        tokens = positions.numel() if tokens_override is None else tokens_override
        has_compress = (
            int(compressed_lengths is not None)
            if has_compress_override is None
            else has_compress_override
        )
        status = self.launch_fn(
            ctypes.c_void_p(positions.data_ptr()),
            ctypes.c_void_p(chunk_start.data_ptr()),
            ctypes.c_void_p(
                compressed_lengths.data_ptr()
                if compressed_lengths is not None
                else 0
            ),
            ctypes.c_void_p(prefix.data_ptr()),
            ctypes.c_void_p(extend.data_ptr()),
            ctypes.c_uint32(tokens),
            ctypes.c_uint32(window),
            ctypes.c_uint32(has_compress),
            ctypes.c_void_p(selected_stream.cuda_stream),
        )
        if check:
            self.check(status, "launch")
        return status


def make_case(tokens: int, width: int, seed: int, device: torch.device):
    generator = torch.Generator(device=device).manual_seed(seed)
    window = 128
    chunk_start = torch.randint(
        0, 32768, (tokens,), dtype=torch.int64, device=device, generator=generator
    )
    token_in_chunk = torch.randint(
        0, 384, (tokens,), dtype=torch.int64, device=device, generator=generator
    )
    positions = (chunk_start + token_in_chunk).contiguous()
    pages = None
    if width:
        counts = torch.randint(
            0, width + 1, (tokens,), dtype=torch.int32, device=device, generator=generator
        )
        if tokens:
            counts[0] = 0
        if tokens > 1:
            counts[1] = width
        columns = torch.arange(width, dtype=torch.int32, device=device)
        pages = torch.where(
            columns[None, :] < counts[:, None],
            columns[None, :] + 17,
            torch.full((), -1, dtype=torch.int32, device=device),
        ).contiguous()
    compressed_lengths = (
        (pages >= 0).sum(dim=1, dtype=torch.int32).contiguous()
        if pages is not None
        else None
    )
    return positions, chunk_start, pages, compressed_lengths, window


def oracle(
    positions: torch.Tensor,
    chunk_start: torch.Tensor,
    pages: torch.Tensor | None,
    window: int,
) -> tuple[torch.Tensor, torch.Tensor]:
    # Compute separately on CPU; do not call the production Triton or torch scan path.
    position_values = positions.cpu().tolist()
    start_values = chunk_start.cpu().tolist()
    page_values = pages.cpu().tolist() if pages is not None else None
    prefix = [0]
    extend = [0]
    for token, (position, start) in enumerate(zip(position_values, start_values)):
        position = ctypes.c_int32(position).value
        start = ctypes.c_int32(start).value
        token_in_chunk = position - start
        swa_low = max(position - window + 1, 0)
        extend_count = min(token_in_chunk + 1, window)
        prefix_count = min(max(start - swa_low, 0), window)
        if page_values is not None:
            prefix_count += sum(value >= 0 for value in page_values[token])
        prefix.append(prefix[-1] + prefix_count)
        extend.append(extend[-1] + extend_count)
    return (
        torch.tensor(prefix, dtype=torch.int32),
        torch.tensor(extend, dtype=torch.int32),
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
    parser.add_argument("--iterations", type=int, default=1000)
    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise SystemExit("HIP device is unavailable")
    target = torch.cuda.get_device_properties(0).gcnArchName
    if "gfx950" not in target:
        raise SystemExit(f"requires gfx950, got {target}")
    device = torch.device("cuda:0")
    bridge = Bridge(args.bridge.resolve(), args.hsaco.resolve())
    cases: list[dict[str, object]] = []

    case_id = 0
    for tokens in TOKEN_BOUNDARIES:
        widths = WIDTHS if tokens in (0, 1, 257, 8192) else (0, 320)
        for width in widths:
            positions, starts, pages, compressed_lengths, window = make_case(
                tokens, width, 424242 + case_id, device
            )
            expected_prefix, expected_extend = oracle(
                positions, starts, pages, window
            )
            prefix = torch.full(
                (tokens + 1,), -777, dtype=torch.int32, device=device
            )
            extend = torch.full_like(prefix, -888)
            bridge.launch(
                positions, starts, compressed_lengths, prefix, extend, window
            )
            torch.cuda.synchronize()
            actual_prefix = prefix.cpu()
            actual_extend = extend.cpu()
            exact = torch.equal(actual_prefix, expected_prefix) and torch.equal(
                actual_extend, expected_extend
            )
            cases.append(
                {
                    "tokens": tokens,
                    "compressed_width": width,
                    "prefix_exact": torch.equal(actual_prefix, expected_prefix),
                    "extend_exact": torch.equal(actual_extend, expected_extend),
                    "pass": exact,
                }
            )
            case_id += 1

    # Caller-stream ordering: mutate the input on a nondefault stream immediately
    # before launch and compare only after synchronizing that stream.
    positions, starts, pages, compressed_lengths, window = make_case(
        257, 512, 424900, device
    )
    stream = torch.cuda.Stream(device=device)
    prefix = torch.empty((258,), dtype=torch.int32, device=device)
    extend = torch.empty_like(prefix)
    with torch.cuda.stream(stream):
        positions.add_(3)
        starts.add_(3)
        bridge.launch(
            positions,
            starts,
            compressed_lengths,
            prefix,
            extend,
            window,
            stream=stream,
        )
    stream.synchronize()
    expected_prefix, expected_extend = oracle(positions, starts, pages, window)
    nondefault_stream_exact = torch.equal(prefix.cpu(), expected_prefix) and torch.equal(
        extend.cpu(), expected_extend
    )

    # Repeatability and graph replay with input mutation between replays.
    positions, starts, pages, compressed_lengths, window = make_case(
        8192, 320, 425000, device
    )
    prefix = torch.empty((8193,), dtype=torch.int32, device=device)
    extend = torch.empty_like(prefix)
    bridge.launch(positions, starts, compressed_lengths, prefix, extend, window)
    torch.cuda.synchronize()
    first_prefix = prefix.clone()
    first_extend = extend.clone()
    for _ in range(100):
        bridge.launch(positions, starts, compressed_lengths, prefix, extend, window)
    torch.cuda.synchronize()
    repeat_exact = torch.equal(prefix, first_prefix) and torch.equal(extend, first_extend)

    graph = torch.cuda.CUDAGraph()
    capture_stream = torch.cuda.Stream(device=device)
    capture_stream.wait_stream(torch.cuda.current_stream(device))
    with torch.cuda.stream(capture_stream):
        graph.capture_begin()
        bridge.launch(
            positions,
            starts,
            compressed_lengths,
            prefix,
            extend,
            window,
            stream=capture_stream,
        )
        graph.capture_end()
    torch.cuda.current_stream(device).wait_stream(capture_stream)
    positions.add_(1)
    starts.add_(1)
    graph.replay()
    torch.cuda.synchronize()
    graph_prefix, graph_extend = oracle(positions, starts, pages, window)
    graph_exact = torch.equal(prefix.cpu(), graph_prefix) and torch.equal(
        extend.cpu(), graph_extend
    )

    invalid = {}
    tiny_positions = torch.zeros((1,), dtype=torch.int64, device=device)
    tiny_output = torch.zeros((1,), dtype=torch.int32, device=device)
    invalid["tokens_8193"] = bridge.launch(
        tiny_positions,
        tiny_positions,
        None,
        tiny_output,
        tiny_output,
        128,
        tokens_override=8193,
        check=False,
    ) != 0
    invalid["window_zero"] = bridge.launch(
        tiny_positions,
        tiny_positions,
        None,
        tiny_output,
        tiny_output,
        0,
        check=False,
    ) != 0
    invalid["missing_compressed_lengths"] = bridge.launch(
        tiny_positions,
        tiny_positions,
        None,
        tiny_output,
        tiny_output,
        128,
        has_compress_override=1,
        check=False,
    ) != 0
    invalid["has_compress_2"] = bridge.launch(
        tiny_positions,
        tiny_positions,
        None,
        tiny_output,
        tiny_output,
        128,
        has_compress_override=2,
        check=False,
    ) != 0

    timings = []
    for width in WIDTHS:
        positions, starts, pages, compressed_lengths, window = make_case(
            8192, width, 426000 + width, device
        )
        prefix = torch.empty((8193,), dtype=torch.int32, device=device)
        extend = torch.empty_like(prefix)
        for _ in range(20):
            bridge.launch(
                positions, starts, compressed_lengths, prefix, extend, window
            )
        torch.cuda.synchronize()
        timings.append(
            {
                "tokens": 8192,
                "compressed_width": width,
                "netra_mean_us": elapsed_us(
                    lambda: bridge.launch(
                        positions,
                        starts,
                        compressed_lengths,
                        prefix,
                        extend,
                        window,
                    ),
                    args.iterations,
                ),
            }
        )

    passed = (
        all(bool(case["pass"]) for case in cases)
        and nondefault_stream_exact
        and repeat_exact
        and graph_exact
        and all(invalid.values())
    )
    result = {
        "target": target,
        "abi": "netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1",
        "front_packed_contract": True,
        "token_boundaries": list(TOKEN_BOUNDARIES) + [8193],
        "compressed_widths": list(WIDTHS),
        "case_count": len(cases),
        "failed_case_count": sum(not bool(case["pass"]) for case in cases),
        "nondefault_stream_exact": nondefault_stream_exact,
        "repeat_count": 100,
        "repeat_exact": repeat_exact,
        "graph_replay_exact_after_input_mutation": graph_exact,
        "invalid_abi_rejected": invalid,
        "iterations": args.iterations,
        "timings": timings,
        "pass": passed,
        "cases": cases,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
