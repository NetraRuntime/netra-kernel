#!/usr/bin/env python3
"""Split one delayed rocprofv3 trace into exact SGLang request windows."""
from __future__ import annotations

import argparse
import csv
import json
import re
import statistics
from pathlib import Path

LINE_RE = re.compile(r"^(\S+) (start|end)_epoch_ns=(\d+)$")


def load_windows(path: Path) -> dict[str, dict[str, int]]:
    windows: dict[str, dict[str, int]] = {}
    for line in path.read_text().splitlines():
        match = LINE_RE.match(line)
        if match:
            windows.setdefault(match.group(1), {})[match.group(2)] = int(match.group(3))
    return {name: value for name, value in windows.items() if set(value) == {"start", "end"}}


def significant_clusters(path: Path, gap_ns: int = 100_000_000) -> list[dict[str, int]]:
    clusters: list[dict[str, int]] = []
    current = None
    with path.open(newline="") as handle:
        for row in csv.DictReader(handle):
            start = int(row["Start_Timestamp"])
            end = int(row["End_Timestamp"])
            if current is None or start - current["last_end"] > gap_ns:
                if current is not None:
                    clusters.append(current)
                current = {"start": start, "end": end, "last_end": end, "launches": 1}
            else:
                current["end"] = max(current["end"], end)
                current["last_end"] = max(current["last_end"], end)
                current["launches"] += 1
    if current is not None:
        clusters.append(current)
    return [cluster for cluster in clusters if cluster["launches"] >= 1000]


def slice_csv(source: Path, destination: Path, start: int, end: int) -> int:
    count = 0
    with source.open(newline="") as src, destination.open("w", newline="") as dst:
        reader = csv.DictReader(src)
        writer = csv.DictWriter(dst, fieldnames=reader.fieldnames)
        writer.writeheader()
        for row in reader:
            try:
                row_start = int(row["Start_Timestamp"])
                row_end = int(row["End_Timestamp"])
            except (KeyError, ValueError):
                continue
            if row_start >= start and row_end <= end:
                writer.writerow(row)
                count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--padding-ms", type=float, default=50.0)
    args = parser.parse_args()
    root = args.root.resolve()
    windows = load_windows(root / "requests" / "timeline.txt")
    names = list(windows)
    if len(names) < 2:
        raise SystemExit("need at least two completed request windows")
    kernel_trace = root / "trace_kernel_trace.csv"
    clusters = significant_clusters(kernel_trace)
    if len(clusters) < 2:
        raise SystemExit("could not find final request kernel clusters")

    # The final two scenarios are dense decode windows with continuous dispatch,
    # so their first significant clusters robustly align epoch and profiler clocks.
    estimates = [
        clusters[-2]["start"] - windows[names[-2]]["start"],
        clusters[-1]["start"] - windows[names[-1]]["start"],
    ]
    offset = round(statistics.median(estimates))
    disagreement = max(estimates) - min(estimates)
    if disagreement > 10_000_000:
        raise RuntimeError(f"clock alignment disagreement is {disagreement / 1e6:.3f} ms")
    padding = round(args.padding_ms * 1e6)

    sources = {
        "trace_kernel_trace.csv": kernel_trace,
        "trace_hip_api_trace.csv": root / "trace_hip_api_trace.csv",
        "trace_memory_copy_trace.csv": root / "trace_memory_copy_trace.csv",
        "trace_memory_allocation_trace.csv": root / "trace_memory_allocation_trace.csv",
        "trace_scratch_memory_trace.csv": root / "trace_scratch_memory_trace.csv",
    }
    manifest = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "clock_alignment": "median offset from final two continuous decode windows",
        "epoch_to_rocprof_offset_ns": offset,
        "alignment_disagreement_ns": disagreement,
        "padding_ns": padding,
        "scenarios": {},
    }
    for name, window in windows.items():
        destination = root / "scenarios" / name
        destination.mkdir(parents=True, exist_ok=True)
        start = window["start"] + offset - padding
        end = window["end"] + offset + padding
        counts = {}
        for filename, source in sources.items():
            if source.exists():
                counts[filename] = slice_csv(source, destination / filename, start, end)
        manifest["scenarios"][name] = {
            "source_epoch_start_ns": window["start"],
            "source_epoch_end_ns": window["end"],
            "rocprof_start_ns": start,
            "rocprof_end_ns": end,
            "record_counts": counts,
        }
    rendered = json.dumps(manifest, indent=2) + "\n"
    (root / "scenario-slicing.json").write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
