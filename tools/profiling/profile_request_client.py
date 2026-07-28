#!/usr/bin/env python3
"""Fire a single uncached SGLang generate request for rocprof attach windows.

Host-only timing is labeled as such. GPU claims come from rocprofv3.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.request
import uuid


def build_ids(n: int, seed: str | None = None) -> list[int]:
    # Deterministic-ish unique ids in vocab range without tokenizer dependency.
    # Qwen3.6 vocab is 248320; stay in a safe mid range.
    base = abs(hash(seed or uuid.uuid4().hex)) % 200000 + 1000
    return [((base + i * 7919) % 200000) + 1000 for i in range(n)]


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--url", default="http://127.0.0.1:30000/generate")
    p.add_argument("--input-len", type=int, required=True)
    p.add_argument("--output-len", type=int, default=1)
    p.add_argument("--temperature", type=float, default=0.0)
    p.add_argument("--ignore-eos", action="store_true", default=True)
    p.add_argument("--no-ignore-eos", action="store_false", dest="ignore_eos")
    p.add_argument("--seed", default=None)
    p.add_argument("--timeout", type=float, default=3600.0)
    p.add_argument("--delay-ms", type=float, default=500.0,
                   help="Sleep before request so rocprof attach can settle")
    p.add_argument("--label", default="")
    args = p.parse_args()

    if args.delay_ms > 0:
        time.sleep(args.delay_ms / 1000.0)

    input_ids = build_ids(args.input_len, args.seed)
    body = {
        "input_ids": input_ids,
        "sampling_params": {
            "temperature": args.temperature,
            "max_new_tokens": args.output_len,
            "ignore_eos": args.ignore_eos,
        },
    }
    raw = json.dumps(body).encode()
    req = urllib.request.Request(
        args.url, data=raw, headers={"Content-Type": "application/json"}
    )
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=args.timeout) as resp:
        payload = json.load(resp)
    host_ms = (time.perf_counter() - t0) * 1000.0
    meta = payload.get("meta_info") or {}
    report = {
        "target": "gfx1151",
        "label": args.label or f"in{args.input_len}_out{args.output_len}",
        "timing_scope": "host_e2e_http_measured",
        "measured": True,
        "input_len_requested": args.input_len,
        "output_len_requested": args.output_len,
        "host_e2e_ms": host_ms,
        "prompt_tokens": meta.get("prompt_tokens"),
        "completion_tokens": meta.get("completion_tokens"),
        "cached_tokens": meta.get("cached_tokens"),
        "e2e_latency_s_meta": meta.get("e2e_latency"),
        "finish_reason": meta.get("finish_reason"),
    }
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
