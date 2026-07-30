#!/usr/bin/env python3
"""Compare old/new gfx1151 runtime launch signatures in rocprofv3 traces."""

from __future__ import annotations

import argparse
import collections
import csv
import json
import statistics
from pathlib import Path

SIGNATURE_FIELDS = (
    "Kernel_Name",
    "Queue_Id",
    "Stream_Id",
    "LDS_Block_Size",
    "Scratch_Size",
    "VGPR_Count",
    "Accum_VGPR_Count",
    "SGPR_Count",
    "Workgroup_Size_X",
    "Workgroup_Size_Y",
    "Workgroup_Size_Z",
    "Grid_Size_X",
    "Grid_Size_Y",
    "Grid_Size_Z",
)
APIS = (
    "hipModuleLaunchKernel",
    "hipMalloc",
    "hipFree",
    "hipDeviceSynchronize",
    "hipStreamSynchronize",
    "hipGraphLaunch",
)


def find_one(directory: Path, pattern: str) -> Path:
    matches = sorted(directory.glob(pattern))
    if len(matches) != 1:
        raise RuntimeError(f"expected one {pattern} in {directory}, found {len(matches)}")
    return matches[0]


def hip_rows(directory: Path) -> list[dict[str, str]]:
    with find_one(directory, "*hip_api_trace.csv").open(newline="") as handle:
        return list(csv.DictReader(handle))


def signatures(directory: Path, graph_only: bool) -> list[tuple[str, ...]]:
    correlations: set[str] | None = None
    if graph_only:
        correlations = {
            row["Correlation_Id"]
            for row in hip_rows(directory)
            if row["Function"] == "hipGraphLaunch"
        }
        if not correlations:
            raise RuntimeError(f"no hipGraphLaunch in {directory}")
    with find_one(directory, "*kernel_trace.csv").open(newline="") as handle:
        rows = csv.DictReader(handle)
        return [
            tuple(row[field] for field in SIGNATURE_FIELDS)
            for row in rows
            if correlations is None or row["Correlation_Id"] in correlations
        ]


def request_hashes(directory: Path) -> list[tuple[str, str]]:
    payload = json.loads((directory / "request.json").read_text())
    if "requests" in payload:
        return [
            (item["input_ids_sha256"], item["output_ids_sha256"])
            for item in payload["requests"]
        ]
    output_ids = payload["output_ids"]
    import hashlib

    output_hash = hashlib.sha256(
        b"".join(int(value).to_bytes(4, "little", signed=False) for value in output_ids)
    ).hexdigest()
    return [(payload["input_ids_sha256"], output_hash)]


def api_summary(directory: Path) -> dict[str, dict[str, float | int]]:
    grouped: dict[str, list[float]] = collections.defaultdict(list)
    for row in hip_rows(directory):
        if row["Function"] in APIS:
            grouped[row["Function"]].append(
                (int(row["End_Timestamp"]) - int(row["Start_Timestamp"])) / 1000
            )
    result: dict[str, dict[str, float | int]] = {}
    for name in APIS:
        values = grouped[name]
        result[name] = {
            "calls": len(values),
            "total_cpu_us": sum(values),
            "mean_cpu_us": statistics.mean(values) if values else 0.0,
            "median_cpu_us": statistics.median(values) if values else 0.0,
        }
    return result


def graph_replay_window_api_summary(directory: Path) -> dict[str, dict[str, float | int]]:
    rows = hip_rows(directory)
    launches = [row for row in rows if row["Function"] == "hipGraphLaunch"]
    if not launches:
        raise RuntimeError(f"no hipGraphLaunch in {directory}")
    first = min(int(row["Start_Timestamp"]) for row in launches)
    last = max(int(row["End_Timestamp"]) for row in launches)
    grouped: dict[str, list[float]] = collections.defaultdict(list)
    for row in rows:
        if row["Function"] in APIS and first <= int(row["Start_Timestamp"]) <= last:
            grouped[row["Function"]].append(
                (int(row["End_Timestamp"]) - int(row["Start_Timestamp"])) / 1000
            )
    return {
        name: {
            "calls": len(grouped[name]),
            "total_cpu_us": sum(grouped[name]),
            "mean_cpu_us": statistics.mean(grouped[name]) if grouped[name] else 0.0,
            "median_cpu_us": statistics.median(grouped[name]) if grouped[name] else 0.0,
        }
        for name in APIS
    }



def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("old_trace", type=Path)
    parser.add_argument("new_trace", type=Path)
    parser.add_argument("--scope", choices=("window", "graph"), required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    graph_only = args.scope == "graph"
    old_signatures = signatures(args.old_trace, graph_only)
    new_signatures = signatures(args.new_trace, graph_only)
    old_counter = collections.Counter(old_signatures)
    new_counter = collections.Counter(new_signatures)
    old_api = api_summary(args.old_trace)
    new_api = api_summary(args.new_trace)
    requests_exact = request_hashes(args.old_trace) == request_hashes(args.new_trace)
    old_hot_api = graph_replay_window_api_summary(args.old_trace) if graph_only else old_api
    new_hot_api = graph_replay_window_api_summary(args.new_trace) if graph_only else new_api
    if graph_only:
        launch_counts_exact = all(
            old_api[name]["calls"] == new_api[name]["calls"]
            for name in ("hipModuleLaunchKernel", "hipGraphLaunch")
        ) and all(
            old_hot_api[name]["calls"] == new_hot_api[name]["calls"] == 0
            for name in ("hipMalloc", "hipFree", "hipDeviceSynchronize", "hipStreamSynchronize")
        )
    else:
        launch_counts_exact = all(
            old_api[name]["calls"] == new_api[name]["calls"] for name in APIS
        )
    report = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "scope": args.scope,
        "old_trace": str(args.old_trace),
        "new_trace": str(args.new_trace),
        "request_inputs_and_tokens_exact": requests_exact,
        "kernel_launches_old": len(old_signatures),
        "kernel_launches_new": len(new_signatures),
        "launch_signature_multiset_exact": old_counter == new_counter,
        "launch_signature_order_exact": old_signatures == new_signatures,
        "launch_signature_fields": list(SIGNATURE_FIELDS),
        "tracked_hip_api_call_counts_exact": launch_counts_exact,
        "old_hip_api": old_api,
        "new_hip_api": new_api,
        "old_graph_replay_window_hip_api": old_hot_api if graph_only else None,
        "new_graph_replay_window_hip_api": new_hot_api if graph_only else None,
        "old_only_signatures": [
            {"count": count, "signature": list(signature)}
            for signature, count in (old_counter - new_counter).most_common()
        ],
        "new_only_signatures": [
            {"count": count, "signature": list(signature)}
            for signature, count in (new_counter - old_counter).most_common()
        ],
    }
    passed = (
        requests_exact
        and old_counter == new_counter
        and launch_counts_exact
        and (not graph_only or old_signatures == new_signatures)
    )
    report["passed"] = passed
    args.output.parent.mkdir(parents=True, exist_ok=True)
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    args.output.write_text(rendered)
    print(rendered, end="")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
