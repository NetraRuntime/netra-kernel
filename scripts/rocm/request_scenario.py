#!/usr/bin/env python3
"""Run one exact-length uncached SGLang request on Netra/gfx1151.

Host latency is labeled serving end-to-end timing. GPU timing comes separately
from rocprofv3. The input generator is stable across Python processes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import socket
import threading
import time
import urllib.request
import uuid
from pathlib import Path
from typing import Any


def exact_ids(count: int, seed: str) -> list[int]:
    state = int.from_bytes(hashlib.sha256(seed.encode()).digest()[:8], "little") | 1
    result = []
    for _ in range(count):
        state ^= state >> 12
        state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF
        state ^= state >> 27
        value = (state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF
        result.append(1000 + value % 200_000)
    return result


def vram_files() -> list[Path]:
    result = []
    for path in Path("/sys/class/drm").glob("card*/device/mem_info_vram_used"):
        try:
            if (path.parent / "vendor").read_text().strip().lower() == "0x1002":
                result.append(path)
        except OSError:
            pass
    return result


class VramSampler:
    def __init__(self, period_ms: float) -> None:
        self.paths = vram_files()
        self.period = max(period_ms, 1.0) / 1000.0
        self.stop = threading.Event()
        self.peak = 0
        self.samples = 0
        self.thread = threading.Thread(target=self.run, daemon=True)

    def read(self) -> int:
        total = 0
        for path in self.paths:
            try:
                total += int(path.read_text().strip())
            except (OSError, ValueError):
                pass
        return total

    def run(self) -> None:
        while not self.stop.is_set():
            self.peak = max(self.peak, self.read())
            self.samples += 1
            self.stop.wait(self.period)

    def __enter__(self) -> "VramSampler":
        self.thread.start()
        return self

    def __exit__(self, *_: object) -> None:
        self.stop.set()
        self.thread.join(timeout=1.0)
        self.peak = max(self.peak, self.read())


def first_number(meta: dict[str, Any], *keys: str) -> float | None:
    for key in keys:
        value = meta.get(key)
        if isinstance(value, (int, float)):
            return float(value)
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:30000/generate")
    parser.add_argument("--input-len", type=int, required=True)
    parser.add_argument("--output-len", type=int, required=True)
    parser.add_argument("--seed")
    parser.add_argument("--label", required=True)
    parser.add_argument("--graph-mode", default="disabled")
    parser.add_argument("--dflash-mode", default="disabled")
    parser.add_argument("--delay-ms", type=float, default=0.0)
    parser.add_argument("--timeout", type=float, default=7200.0)
    parser.add_argument("--vram-period-ms", type=float, default=5.0)
    parser.add_argument("--allow-cache", action="store_true")
    parser.add_argument("--stream", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if socket.gethostname() != "Netra":
        raise SystemExit("refusing to run outside the Netra LXC")
    if args.input_len <= 0 or args.output_len <= 0:
        raise SystemExit("input and output lengths must be positive")
    if args.delay_ms:
        time.sleep(args.delay_ms / 1000.0)

    seed = args.seed or f"{args.label}-{uuid.uuid4().hex}"
    ids = exact_ids(args.input_len, seed)
    body = {
        "input_ids": ids,
        "sampling_params": {
            "temperature": 0.0,
            "max_new_tokens": args.output_len,
            "ignore_eos": True,
        },
        "stream": args.stream,
    }
    request = urllib.request.Request(
        args.url,
        data=json.dumps(body, separators=(",", ":")).encode(),
        headers={"Content-Type": "application/json"},
    )
    first_token_ns = None
    stream_events = 0
    payload: dict[str, Any] = {}
    with VramSampler(args.vram_period_ms) as sampler:
        start = time.perf_counter_ns()
        with urllib.request.urlopen(request, timeout=args.timeout) as response:
            if args.stream:
                for raw_line in response:
                    line = raw_line.decode("utf-8").strip()
                    if not line.startswith("data:"):
                        continue
                    data = line[5:].strip()
                    if not data or data == "[DONE]":
                        continue
                    payload = json.loads(data)
                    stream_events += 1
                    event_meta = payload.get("meta_info") or {}
                    if first_token_ns is None and (
                        event_meta.get("completion_tokens", 0) > 0
                    ):
                        first_token_ns = time.perf_counter_ns()
            else:
                payload = json.load(response)
        end = time.perf_counter_ns()
    if args.stream and first_token_ns is None:
        raise RuntimeError("stream ended without a completion token")

    meta = payload.get("meta_info") or {}
    prompt = meta.get("prompt_tokens")
    completion = meta.get("completion_tokens")
    cached = meta.get("cached_tokens")
    if prompt != args.input_len:
        raise RuntimeError(f"prompt mismatch: {prompt} != {args.input_len}")
    if completion != args.output_len:
        raise RuntimeError(f"completion mismatch: {completion} != {args.output_len}")
    if not args.allow_cache and cached != 0:
        raise RuntimeError(f"uncached run required, cached_tokens={cached}")

    ttft = first_number(meta, "time_to_first_token", "ttft", "prefill_latency")
    decode_s = first_number(meta, "decode_latency", "decode_time")
    input_tps = first_number(meta, "input_throughput", "prefill_throughput")
    output_tps = first_number(meta, "output_throughput", "decode_throughput")
    host_ttft_s = (first_token_ns - start) / 1e9 if first_token_ns else None
    host_decode_s = (end - first_token_ns) / 1e9 if first_token_ns else None
    if host_ttft_s is not None:
        ttft = host_ttft_s
        input_tps = args.input_len / host_ttft_s
    if host_decode_s is not None and args.output_len > 1 and host_decode_s > 0:
        output_tps = (args.output_len - 1) / host_decode_s
    if input_tps is None and ttft and ttft > 0:
        input_tps = args.input_len / ttft
    if output_tps is None and decode_s and decode_s > 0:
        output_tps = args.output_len / decode_s
    text = payload.get("text") or ""
    report = {
        "target": "gfx1151",
        "device": "AMD Ryzen AI Max+ PRO 395 / Radeon 8060S",
        "measurement_status": "measured",
        "timing_scope": (
            "host_e2e_http_stream_monotonic" if args.stream
            else "host_e2e_http_monotonic"
        ),
        "label": args.label,
        "graph_mode": args.graph_mode,
        "dflash_mode": args.dflash_mode,
        "input_tokens_requested": args.input_len,
        "output_tokens_requested": args.output_len,
        "prompt_tokens_observed": prompt,
        "completion_tokens_observed": completion,
        "cached_tokens": cached,
        "host_e2e_ms": (end - start) / 1e6,
        "host_ttft_ms_measured": (host_ttft_s * 1000 if host_ttft_s is not None else None),
        "host_decode_ms_measured": (host_decode_s * 1000 if host_decode_s is not None else None),
        "stream_events": stream_events,
        "ttft_s_from_server_or_stream": ttft,
        "input_throughput_tokens_per_s": input_tps,
        "output_throughput_tokens_per_s": output_tps,
        "peak_vram_bytes_sysfs_measured": sampler.peak if sampler.paths else None,
        "vram_samples": sampler.samples,
        "input_ids_sha256": hashlib.sha256(
            b"".join(value.to_bytes(4, "little") for value in ids)
        ).hexdigest(),
        "output_text_sha256": hashlib.sha256(text.encode()).hexdigest(),
        "output_text_prefix": text[:160],
        "server_meta_info": meta,
    }
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
