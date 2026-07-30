#!/usr/bin/env python3
"""Run synchronized exact-token concurrent requests against SGLang on Netra/gfx1151."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import socket
import sys
import threading
import time
import urllib.request
from pathlib import Path
from statistics import median
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO_ROOT))

from tools.profiling.request_scenario import VramSampler, exact_ids


def _sha_ids(values: list[int]) -> str:
    return hashlib.sha256(
        b"".join(int(value).to_bytes(4, "little", signed=False) for value in values)
    ).hexdigest()


def _one_request(
    *,
    index: int,
    barrier: threading.Barrier,
    url: str,
    input_len: int,
    output_len: int,
    seed_prefix: str,
    timeout: float,
) -> dict[str, Any]:
    seed = f"{seed_prefix}-{index:03d}"
    input_ids = exact_ids(input_len, seed)
    body = {
        "input_ids": input_ids,
        "sampling_params": {
            "temperature": 0.0,
            "max_new_tokens": output_len,
            "ignore_eos": True,
        },
        "stream": True,
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(body, separators=(",", ":")).encode(),
        headers={"Content-Type": "application/json"},
    )
    barrier.wait()
    start_ns = time.perf_counter_ns()
    first_token_ns: int | None = None
    end_ns: int
    payload: dict[str, Any] = {}
    stream_events = 0
    with urllib.request.urlopen(request, timeout=timeout) as response:
        for raw_line in response:
            line = raw_line.decode("utf-8").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if not data or data == "[DONE]":
                continue
            payload = json.loads(data)
            stream_events += 1
            meta = payload.get("meta_info") or {}
            if first_token_ns is None and meta.get("completion_tokens", 0) > 0:
                first_token_ns = time.perf_counter_ns()
    end_ns = time.perf_counter_ns()
    if first_token_ns is None:
        raise RuntimeError(f"request {index} ended without a completion token")

    meta = payload.get("meta_info") or {}
    prompt = meta.get("prompt_tokens")
    completion = meta.get("completion_tokens")
    cached = meta.get("cached_tokens")
    if prompt != input_len:
        raise RuntimeError(f"request {index}: prompt mismatch {prompt} != {input_len}")
    if completion != output_len:
        raise RuntimeError(
            f"request {index}: completion mismatch {completion} != {output_len}"
        )
    if cached != 0:
        raise RuntimeError(f"request {index}: uncached run required, cached={cached}")

    output_ids = payload.get("output_ids") or []
    return {
        "index": index,
        "seed": seed,
        "input_tokens_requested": input_len,
        "output_tokens_requested": output_len,
        "prompt_tokens_observed": prompt,
        "completion_tokens_observed": completion,
        "cached_tokens": cached,
        "host_start_ns": start_ns,
        "host_first_token_ns": first_token_ns,
        "host_end_ns": end_ns,
        "host_ttft_ms_measured": (first_token_ns - start_ns) / 1e6,
        "host_decode_ms_measured": (end_ns - first_token_ns) / 1e6,
        "host_e2e_ms_measured": (end_ns - start_ns) / 1e6,
        "output_throughput_tokens_per_s_measured": (
            (output_len - 1) / ((end_ns - first_token_ns) / 1e9)
            if output_len > 1 and end_ns > first_token_ns
            else None
        ),
        "stream_events": stream_events,
        "input_ids_sha256": _sha_ids(input_ids),
        "output_ids_sha256": _sha_ids(output_ids),
        "output_ids": output_ids,
        "server_meta_info": meta,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:30000/generate")
    parser.add_argument("--concurrency", type=int, required=True)
    parser.add_argument("--input-len", type=int, required=True)
    parser.add_argument("--output-len", type=int, required=True)
    parser.add_argument("--seed-prefix", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--graph-mode", required=True)
    parser.add_argument("--dflash-mode", default="disabled")
    parser.add_argument("--timeout", type=float, default=7200.0)
    parser.add_argument("--vram-period-ms", type=float, default=5.0)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    if socket.gethostname() != "Netra":
        raise SystemExit("refusing to run outside the Netra LXC")
    if args.concurrency <= 0 or args.input_len <= 0 or args.output_len <= 0:
        raise SystemExit("concurrency and token lengths must be positive")

    barrier = threading.Barrier(args.concurrency + 1, timeout=60.0)
    with VramSampler(args.vram_period_ms) as sampler:
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=args.concurrency
        ) as executor:
            futures = [
                executor.submit(
                    _one_request,
                    index=index,
                    barrier=barrier,
                    url=args.url,
                    input_len=args.input_len,
                    output_len=args.output_len,
                    seed_prefix=args.seed_prefix,
                    timeout=args.timeout,
                )
                for index in range(args.concurrency)
            ]
            batch_start_ns = time.perf_counter_ns()
            barrier.wait()
            requests = [future.result() for future in futures]
            batch_end_ns = time.perf_counter_ns()

    requests.sort(key=lambda item: item["index"])
    first_token_ns = min(item["host_first_token_ns"] for item in requests)
    last_token_ns = max(item["host_end_ns"] for item in requests)
    wall_s = (batch_end_ns - batch_start_ns) / 1e9
    decode_window_s = (last_token_ns - first_token_ns) / 1e9
    ttfts = sorted(item["host_ttft_ms_measured"] for item in requests)
    e2es = sorted(item["host_e2e_ms_measured"] for item in requests)
    per_request_tps = sorted(
        value
        for item in requests
        if (value := item["output_throughput_tokens_per_s_measured"]) is not None
    )
    report = {
        "target": "gfx1151",
        "device": "AMD Ryzen AI Max+ PRO 395 / Radeon 8060S",
        "measurement_status": "measured",
        "timing_scope": "host_e2e_http_stream_monotonic_synchronized_concurrent",
        "label": args.label,
        "graph_mode": args.graph_mode,
        "dflash_mode": args.dflash_mode,
        "concurrency": args.concurrency,
        "input_tokens_per_request": args.input_len,
        "output_tokens_per_request": args.output_len,
        "cached_tokens_total": sum(item["cached_tokens"] for item in requests),
        "batch_wall_ms_measured": wall_s * 1000,
        "aggregate_input_throughput_tokens_per_s_measured": (
            args.concurrency * args.input_len / wall_s
        ),
        "aggregate_output_throughput_tokens_per_s_e2e_measured": (
            args.concurrency * args.output_len / wall_s
        ),
        "aggregate_decode_throughput_tokens_per_s_measured": (
            args.concurrency * max(args.output_len - 1, 0) / decode_window_s
            if decode_window_s > 0
            else None
        ),
        "median_request_ttft_ms_measured": median(ttfts),
        "median_request_e2e_ms_measured": median(e2es),
        "median_request_output_throughput_tokens_per_s_measured": (
            median(per_request_tps) if per_request_tps else None
        ),
        "peak_vram_bytes_sysfs_measured": sampler.peak if sampler.paths else None,
        "vram_samples": sampler.samples,
        "requests": requests,
    }
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
