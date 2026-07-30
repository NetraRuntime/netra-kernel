#!/usr/bin/env python3
"""Run one ordered multi-prompt SGLang batch on Netra/gfx1151."""
from __future__ import annotations

import argparse
import hashlib
import json
import socket
import sys
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:30000/generate")
    parser.add_argument("--batch-size", type=int, required=True)
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
    if args.batch_size <= 0 or args.input_len <= 0 or args.output_len <= 0:
        raise SystemExit("batch size and token lengths must be positive")

    seeds = [f"{args.seed_prefix}-{index:03d}" for index in range(args.batch_size)]
    inputs = [exact_ids(args.input_len, seed) for seed in seeds]
    body = {
        "input_ids": inputs,
        "sampling_params": {
            "temperature": 0.0,
            "max_new_tokens": args.output_len,
            "ignore_eos": True,
        },
        "stream": False,
    }
    request = urllib.request.Request(
        args.url,
        data=json.dumps(body, separators=(",", ":")).encode(),
        headers={"Content-Type": "application/json"},
    )
    with VramSampler(args.vram_period_ms) as sampler:
        start_ns = time.perf_counter_ns()
        with urllib.request.urlopen(request, timeout=args.timeout) as response:
            payload: Any = json.load(response)
        end_ns = time.perf_counter_ns()

    if not isinstance(payload, list) or len(payload) != args.batch_size:
        raise RuntimeError(
            f"expected {args.batch_size} ordered results, got {type(payload).__name__}"
        )
    requests = []
    for index, item in enumerate(payload):
        meta = item.get("meta_info") or {}
        prompt = meta.get("prompt_tokens")
        completion = meta.get("completion_tokens")
        cached = meta.get("cached_tokens")
        if prompt != args.input_len:
            raise RuntimeError(
                f"result {index}: prompt mismatch {prompt} != {args.input_len}"
            )
        if completion != args.output_len:
            raise RuntimeError(
                f"result {index}: completion mismatch {completion} != {args.output_len}"
            )
        if cached != 0:
            raise RuntimeError(f"result {index}: uncached run required, cached={cached}")
        output_ids = item.get("output_ids") or []
        requests.append(
            {
                "index": index,
                "seed": seeds[index],
                "input_ids_sha256": _sha_ids(inputs[index]),
                "output_ids_sha256": _sha_ids(output_ids),
                "output_ids": output_ids,
                "prompt_tokens_observed": prompt,
                "completion_tokens_observed": completion,
                "cached_tokens": cached,
                "server_meta_info": meta,
            }
        )

    wall_s = (end_ns - start_ns) / 1e9
    server_e2e = [
        float(item["server_meta_info"]["e2e_latency"])
        for item in requests
        if isinstance(item["server_meta_info"].get("e2e_latency"), (int, float))
    ]
    report = {
        "target": "gfx1151",
        "device": "AMD Ryzen AI Max+ PRO 395 / Radeon 8060S",
        "measurement_status": "measured",
        "timing_scope": "host_e2e_http_monotonic_ordered_single_batch_request",
        "label": args.label,
        "graph_mode": args.graph_mode,
        "dflash_mode": args.dflash_mode,
        "batch_size": args.batch_size,
        "input_tokens_per_request": args.input_len,
        "output_tokens_per_request": args.output_len,
        "cached_tokens_total": sum(item["cached_tokens"] for item in requests),
        "host_batch_e2e_ms_measured": wall_s * 1000,
        "aggregate_input_tokens_per_s_e2e_measured": (
            args.batch_size * args.input_len / wall_s
        ),
        "aggregate_output_tokens_per_s_e2e_measured": (
            args.batch_size * args.output_len / wall_s
        ),
        "median_server_e2e_ms_reported": (
            median(server_e2e) * 1000 if server_e2e else None
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
