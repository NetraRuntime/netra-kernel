#!/usr/bin/env python3
"""Benchmark three uncached, exactly 210-token SGLang prefill requests."""

import json
import statistics
import time
import urllib.request
import uuid
from pathlib import Path

from transformers import AutoTokenizer


URL = "http://127.0.0.1:30000/generate"
MODEL = "/root/models/qwen36-sgl-mxfp4"
OUTPUT = Path(
    "/root/netra-mxfp4-gfx1151/results/sglang-exact210-m64-prefill.json"
)
BASE = " MXFP4 gfx1151 raw assembly kernel benchmark."


def make_ids(tokenizer) -> list[int]:
    text = uuid.uuid4().hex + BASE * 80
    ids = tokenizer.encode(text, add_special_tokens=False)[:210]
    if len(ids) != 210:
        raise RuntimeError(f"expected 210 tokens, got {len(ids)}")
    return ids


def request(input_ids: list[int]) -> tuple[float, dict]:
    body = json.dumps(
        {
            "input_ids": input_ids,
            "sampling_params": {
                "temperature": 0,
                "max_new_tokens": 1,
                "ignore_eos": True,
            },
        }
    ).encode()
    req = urllib.request.Request(
        URL, data=body, headers={"Content-Type": "application/json"}
    )
    start = time.perf_counter()
    with urllib.request.urlopen(req, timeout=600) as response:
        payload = json.load(response)
    return (time.perf_counter() - start) * 1000.0, payload


def main() -> None:
    tokenizer = AutoTokenizer.from_pretrained(MODEL)
    warmup_ms, warmup_payload = request(make_ids(tokenizer))
    samples = []
    payloads = []
    for _ in range(3):
        elapsed_ms, payload = request(make_ids(tokenizer))
        samples.append(elapsed_ms)
        payloads.append(payload)
    prompt_tokens = [p["meta_info"]["prompt_tokens"] for p in payloads]
    cached_tokens = [p["meta_info"]["cached_tokens"] for p in payloads]
    if prompt_tokens != [210, 210, 210] or cached_tokens != [0, 0, 0]:
        raise RuntimeError(
            f"invalid benchmark tokens: prompt={prompt_tokens}, cached={cached_tokens}"
        )
    report = {
        "target": "gfx1151",
        "deployment": "SGLang + Netra raw AMDGCN MXFP4",
        "input_tokens": 210,
        "output_tokens": 1,
        "cached_tokens": cached_tokens,
        "warmup_host_e2e_ms": warmup_ms,
        "warmup_prompt_tokens": warmup_payload["meta_info"]["prompt_tokens"],
        "measured_host_e2e_ms": samples,
        "median_host_e2e_ms": statistics.median(samples),
        "mean_host_e2e_ms": statistics.mean(samples),
        "effective_prefill_tokens_per_second_from_e2e_median": (
            210.0 / (statistics.median(samples) / 1000.0)
        ),
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
