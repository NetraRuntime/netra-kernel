#!/usr/bin/env python3
"""Summarize the timed tail of rocprofv3 matmul_ogs kernel traces."""

import argparse
import csv
import statistics
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--timed-iters", type=int, default=64)
    parser.add_argument("--kernel-prefix", default="_matmul_ogs")
    args = parser.parse_args()

    for case_dir in sorted(path for path in args.root.iterdir()
                           if path.is_dir()):
        traces = list(case_dir.rglob("*_kernel_trace.csv"))
        if len(traces) != 1:
            continue
        with traces[0].open(newline="") as stream:
            rows = [
                row for row in csv.DictReader(stream)
                if row["Kernel_Name"].startswith(args.kernel_prefix)
            ]
        rows = rows[-args.timed_iters:]
        durations = [
            (int(row["End_Timestamp"]) - int(row["Start_Timestamp"])) / 1000
            for row in rows
        ]
        print(
            f"{case_dir.name} count={len(durations)} "
            f"mean_us={statistics.fmean(durations):.6f} "
            f"median_us={statistics.median(durations):.6f} "
            f"min_us={min(durations):.6f} max_us={max(durations):.6f}"
        )


if __name__ == "__main__":
    main()
