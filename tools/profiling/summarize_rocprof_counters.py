#!/usr/bin/env python3
"""Merge one-counter-per-pass rocprofv3 CSVs for gfx1151 kernels."""
from __future__ import annotations

import argparse
import csv
import json
import statistics
from collections import defaultdict
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--kernel-prefix", action="append")
    parser.add_argument(
        "--input-scope",
        default="synthetic data with exact Qwen3.6 decode tensor shapes",
    )
    parser.add_argument(
        "--method",
        default="one counter per process launch; identical kernel dispatch shapes",
    )
    args = parser.parse_args()
    prefixes = tuple(args.kernel_prefix or ("mxfp4_", "silu_"))
    values: dict[str, dict[str, list[float]]] = defaultdict(lambda: defaultdict(list))
    resources: dict[str, dict[str, int]] = {}
    for path in sorted(args.root.glob("*/*counter_collection.csv")):
        with path.open(newline="") as handle:
            for row in csv.DictReader(handle):
                name = row["Kernel_Name"]
                if not name.startswith(prefixes):
                    continue
                values[name][row["Counter_Name"]].append(float(row["Counter_Value"]))
                resources[name] = {
                    "grid_size": int(row["Grid_Size"]),
                    "workgroup_size": int(row["Workgroup_Size"]),
                    "lds_bytes": int(row["LDS_Block_Size"]),
                    "scratch_bytes": int(row["Scratch_Size"]),
                    "vgpr": int(row["VGPR_Count"]),
                    "sgpr": int(row["SGPR_Count"]),
                }
    kernels = []
    for name, counters in sorted(values.items()):
        packed = {
            counter: {
                "samples": len(samples),
                "mean": statistics.fmean(samples),
                "min": min(samples),
                "max": max(samples),
            }
            for counter, samples in sorted(counters.items())
        }
        kernels.append({"kernel": name, **resources[name], "counters": packed})
    report = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "input_scope": args.input_scope,
        "profiler": "/opt/rocm-7.2.1/bin/rocprofv3",
        "method": args.method,
        "units": {
            "FETCH_SIZE": "KiB fetched from video memory per dispatch",
            "WRITE_SIZE": "KiB written to video memory per dispatch",
            "OccupancyPercent": "percent of device maximum",
            "L2CacheHit": "percent",
            "MemUnitBusy": "percent of GPUTime",
            "WriteUnitStalled": "percent of GPUTime",
        },
        "direct_dependency_stall_counter": "not exposed for gfx1151 by this rocprofv3 metric set",
        "kernels": kernels,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
