#!/usr/bin/env python3
"""Isolate HIP graph-replay kernels from a rocprofv3 process-start trace."""
from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path
from statistics import mean, median
from typing import Any


def _find_one(root: Path, pattern: str) -> Path:
    matches = sorted(root.glob(pattern))
    if len(matches) != 1:
        raise RuntimeError(f"expected one {pattern} in {root}, found {len(matches)}")
    return matches[0]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_dir", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    hip_path = _find_one(args.trace_dir, "*hip_api_trace.csv")
    kernel_path = _find_one(args.trace_dir, "*kernel_trace.csv")
    with hip_path.open(newline="") as handle:
        hip_rows = list(csv.DictReader(handle))
    launches = [row for row in hip_rows if row["Function"] == "hipGraphLaunch"]
    if not launches:
        raise RuntimeError("trace contains no hipGraphLaunch calls")
    launch_by_correlation = {int(row["Correlation_Id"]): row for row in launches}

    graph_rows: list[dict[str, str]] = []
    with kernel_path.open(newline="") as handle:
        for row in csv.DictReader(handle):
            if int(row["Correlation_Id"]) in launch_by_correlation:
                graph_rows.append(row)
    if not graph_rows:
        raise RuntimeError("no kernels correlate to hipGraphLaunch calls")

    by_replay: dict[int, list[dict[str, str]]] = defaultdict(list)
    by_kernel: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in graph_rows:
        by_replay[int(row["Correlation_Id"])].append(row)
        by_kernel[row["Kernel_Name"]].append(row)

    replay_reports = []
    positive_gaps_ns = []
    for correlation, rows in sorted(by_replay.items()):
        rows.sort(key=lambda row: int(row["Start_Timestamp"]))
        durations_ns = [
            int(row["End_Timestamp"]) - int(row["Start_Timestamp"]) for row in rows
        ]
        for previous, current in zip(rows, rows[1:]):
            gap = int(current["Start_Timestamp"]) - int(previous["End_Timestamp"])
            if gap > 0:
                positive_gaps_ns.append(gap)
        api = launch_by_correlation[correlation]
        replay_reports.append(
            {
                "correlation_id": correlation,
                "kernel_launches": len(rows),
                "hip_graph_launch_cpu_us": (
                    int(api["End_Timestamp"]) - int(api["Start_Timestamp"])
                )
                / 1000,
                "gpu_span_us": (
                    int(rows[-1]["End_Timestamp"]) - int(rows[0]["Start_Timestamp"])
                )
                / 1000,
                "summed_kernel_gpu_us": sum(durations_ns) / 1000,
            }
        )

    ranked = []
    for name, rows in by_kernel.items():
        durations_us = [
            (int(row["End_Timestamp"]) - int(row["Start_Timestamp"])) / 1000
            for row in rows
        ]
        first = rows[0]
        ranked.append(
            {
                "kernel": name,
                "invocations": len(rows),
                "total_gpu_us": sum(durations_us),
                "mean_gpu_us": mean(durations_us),
                "median_gpu_us": median(durations_us),
                "vgpr": int(first["VGPR_Count"]),
                "sgpr": int(first["SGPR_Count"]),
                "lds_bytes": int(first["LDS_Block_Size"]),
                "scratch_bytes": int(first["Scratch_Size"]),
                "grid": [
                    int(first["Grid_Size_X"]),
                    int(first["Grid_Size_Y"]),
                    int(first["Grid_Size_Z"]),
                ],
                "workgroup": [
                    int(first["Workgroup_Size_X"]),
                    int(first["Workgroup_Size_Y"]),
                    int(first["Workgroup_Size_Z"]),
                ],
            }
        )
    ranked.sort(key=lambda item: item["total_gpu_us"], reverse=True)
    total_kernel_us = sum(item["total_gpu_us"] for item in ranked)
    for item in ranked:
        item["pct_of_graph_kernel_time"] = item["total_gpu_us"] / total_kernel_us * 100

    report: dict[str, Any] = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "timing_scope": "rocprofv3_hip_graph_launch_correlation_only",
        "graph_launches": len(launches),
        "correlated_graph_kernel_launches": len(graph_rows),
        "kernels_per_replay": [item["kernel_launches"] for item in replay_reports],
        "mean_hip_graph_launch_cpu_us": mean(
            item["hip_graph_launch_cpu_us"] for item in replay_reports
        ),
        "mean_graph_gpu_span_us": mean(
            item["gpu_span_us"] for item in replay_reports
        ),
        "median_graph_gpu_span_us": median(
            item["gpu_span_us"] for item in replay_reports
        ),
        "mean_summed_kernel_gpu_us_per_replay": mean(
            item["summed_kernel_gpu_us"] for item in replay_reports
        ),
        "positive_inter_kernel_gap_count": len(positive_gaps_ns),
        "mean_positive_inter_kernel_gap_us": (
            mean(positive_gaps_ns) / 1000 if positive_gaps_ns else 0.0
        ),
        "median_positive_inter_kernel_gap_us": (
            median(positive_gaps_ns) / 1000 if positive_gaps_ns else 0.0
        ),
        "replays": replay_reports,
        "kernels_ranked_by_total_graph_gpu_time": ranked,
        "source_hip_trace": str(hip_path),
        "source_kernel_trace": str(kernel_path),
    }
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(rendered)
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
