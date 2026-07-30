#!/usr/bin/env python3
"""Summarize kernel dispatches from a rocprofv3 rocpd SQLite database."""

from __future__ import annotations

import argparse
import json
import sqlite3
import statistics
from collections import defaultdict
from pathlib import Path


def table(connection: sqlite3.Connection, prefix: str) -> str:
    rows = connection.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE ?",
        (prefix + "_%",),
    ).fetchall()
    if len(rows) != 1:
        raise RuntimeError(
            f"expected one {prefix}_* table, found {[row[0] for row in rows]}"
        )
    return str(rows[0][0])


def percentile_nearest_rank(values: list[int], quantile: float) -> int:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, int(quantile * len(ordered)))]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("database", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    connection = sqlite3.connect(f"file:{args.database}?mode=ro", uri=True)
    dispatch = table(connection, "rocpd_kernel_dispatch")
    symbols = table(connection, "rocpd_info_kernel_symbol")
    rows = connection.execute(
        f"""
        SELECT COALESCE(s.display_name, s.kernel_name, 'unknown'),
               d.end - d.start
          FROM "{dispatch}" AS d
          JOIN "{symbols}" AS s ON s.id = d.kernel_id
         WHERE d.end >= d.start
        """
    ).fetchall()
    connection.close()
    if not rows:
        raise RuntimeError(f"no kernel dispatches in {args.database}")

    grouped: dict[str, list[int]] = defaultdict(list)
    for name, duration_ns in rows:
        grouped[str(name)].append(int(duration_ns))
    total_ns = sum(sum(values) for values in grouped.values())
    kernels = []
    for name, values in grouped.items():
        kernel_total = sum(values)
        kernels.append(
            {
                "kernel": name,
                "invocations": len(values),
                "minimum_us": min(values) / 1000.0,
                "median_us": statistics.median(values) / 1000.0,
                "mean_us": statistics.fmean(values) / 1000.0,
                "p90_us": percentile_nearest_rank(values, 0.9) / 1000.0,
                "maximum_us": max(values) / 1000.0,
                "total_us": kernel_total / 1000.0,
                "percent_of_kernel_time": 100.0 * kernel_total / total_ns,
            }
        )
    kernels.sort(key=lambda item: item["total_us"], reverse=True)
    report = {
        "source": str(args.database),
        "timing_scope": "rocprofv3_kernel_dispatch",
        "kernel_launches": len(rows),
        "unique_kernels": len(grouped),
        "total_kernel_us": total_ns / 1000.0,
        "kernels_ranked_by_total_us": kernels,
    }
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        if args.output.exists():
            raise FileExistsError(f"refusing to overwrite {args.output}")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
