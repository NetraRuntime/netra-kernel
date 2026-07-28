#!/usr/bin/env python3
"""Small reproducible SGLang serving benchmark for the gfx1151 MXFP4 backend."""

import argparse
import json
import statistics
import time
import urllib.request
import uuid


def request(url: str, prompt: str, output_tokens: int) -> tuple[float, dict]:
    body = json.dumps(
        {
            "text": prompt,
            "sampling_params": {
                "temperature": 0,
                "max_new_tokens": output_tokens,
                "ignore_eos": True,
            },
        }
    ).encode()
    req = urllib.request.Request(
        url + "/generate",
        data=body,
        headers={"Content-Type": "application/json"},
    )
    start = time.perf_counter()
    with urllib.request.urlopen(req, timeout=600) as response:
        payload = json.load(response)
    elapsed = time.perf_counter() - start
    return elapsed, payload


def run_case(
    url: str, name: str, prompt: str, output_tokens: int, warmup: int, iters: int
) -> dict:
    for _ in range(warmup):
        request(url, uuid.uuid4().hex + " " + prompt, output_tokens)
    samples = []
    payload = None
    for _ in range(iters):
        elapsed, payload = request(
            url, uuid.uuid4().hex + " " + prompt, output_tokens
        )
        samples.append(elapsed * 1000)
    assert payload is not None
    return {
        "name": name,
        "requested_output_tokens": output_tokens,
        "measured_host_e2e_ms": samples,
        "median_host_e2e_ms": statistics.median(samples),
        "mean_host_e2e_ms": statistics.mean(samples),
        "response_meta_info": payload.get("meta_info", {}),
        "output_text_sample": payload.get("text", "")[:160],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:30000")
    parser.add_argument("--warmup", type=int, default=1)
    parser.add_argument("--iters", type=int, default=3)
    parser.add_argument(
        "--output", default="/root/netra-mxfp4-gfx1151/results/sglang.json"
    )
    args = parser.parse_args()
    cases = [
        ("short_decode_8", "The capital of France is", 8),
        ("short_decode_16", "Write a short factual sentence about AMD.", 16),
        (
            "prefill_target_128_decode_1",
            ("MXFP4 gfx1151 raw assembly kernel benchmark. " * 14),
            1,
        ),
    ]
    results = [
        run_case(args.url, name, prompt, tokens, args.warmup, args.iters)
        for name, prompt, tokens in cases
    ]
    report = {
        "target": "gfx1151",
        "deployment": "SGLang + Netra raw AMDGCN MXFP4",
        "timing_scope": "HTTP request end-to-end; host monotonic clock",
        "warmup": args.warmup,
        "iterations": args.iters,
        "cases": results,
    }
    output = __import__("pathlib").Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
