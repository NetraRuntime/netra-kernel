#!/usr/bin/env python3
"""Interleaved fresh-process initialization A/B for the gfx1151 runtime."""

from __future__ import annotations

import argparse
import ctypes
import json
import statistics
import subprocess
import sys
import time
from pathlib import Path


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = fraction * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def stats(values: list[float]) -> dict[str, float]:
    return {
        "median_us": statistics.median(values),
        "p90_us": percentile(values, 0.9),
        "mean_us": statistics.mean(values),
    }


def child(lib_path: str) -> int:
    start = time.perf_counter_ns()
    library = ctypes.CDLL(lib_path, mode=ctypes.RTLD_LOCAL)
    after_dlopen = time.perf_counter_ns()
    init = library.netra_mxfp4_sgl_init
    init.argtypes = []
    init.restype = ctypes.c_int
    status = init()
    after_init = time.perf_counter_ns()
    print(
        json.dumps(
            {
                "status": status,
                "dlopen_us": (after_dlopen - start) / 1000.0,
                "init_us": (after_init - after_dlopen) / 1000.0,
            }
        )
    )
    return 0 if status == 0 else 1


def run_once(script: Path, lib_path: Path) -> dict[str, float]:
    completed = subprocess.run(
        [sys.executable, str(script), "--child", str(lib_path)],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return json.loads(completed.stdout)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("old_lib", nargs="?")
    parser.add_argument("new_lib", nargs="?")
    parser.add_argument("--pairs", type=int, default=25)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--child")
    args = parser.parse_args()

    if args.child:
        return child(args.child)
    if not args.old_lib or not args.new_lib or args.pairs < 2:
        parser.error("OLD_LIB NEW_LIB and at least two --pairs are required")

    script = Path(__file__).resolve()
    old_path = Path(args.old_lib).resolve()
    new_path = Path(args.new_lib).resolve()
    records: list[dict[str, object]] = []
    for pair in range(args.pairs):
        order = (("old", old_path), ("new", new_path))
        if pair & 1:
            order = tuple(reversed(order))
        for label, path in order:
            measurement = run_once(script, path)
            records.append({"pair": pair, "label": label, **measurement})

    result: dict[str, object] = {
        "target": "gfx1151",
        "status": "measured",
        "fresh_process": True,
        "interleaved_order": True,
        "pairs": args.pairs,
        "old_lib": str(old_path),
        "new_lib": str(new_path),
        "summary": {},
        "records": records,
    }
    summary = result["summary"]
    assert isinstance(summary, dict)
    for label in ("old", "new"):
        selected = [record for record in records if record["label"] == label]
        summary[label] = {
            "dlopen": stats([float(record["dlopen_us"]) for record in selected]),
            "init": stats([float(record["init_us"]) for record in selected]),
        }

    encoded = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded)
    sys.stdout.write(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
