#!/usr/bin/env python3
"""Compute reproducible descriptive statistics from retained benchmark samples."""

from __future__ import annotations

import argparse
import csv
import math
import random
import statistics
from collections import defaultdict
from pathlib import Path


def percentile(values: list[float], probability: float) -> float:
    """Return the R-7/NumPy-linear sample percentile."""
    if not values:
        raise ValueError("percentile requires at least one value")
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    fraction = position - lower
    return ordered[lower] + fraction * (ordered[upper] - ordered[lower])


def bootstrap_mean_ci(
    values: list[float], *, resamples: int = 20_000, seed: int = 20260821
) -> tuple[float, float]:
    if len(values) == 1:
        return values[0], values[0]
    rng = random.Random(seed)
    n = len(values)
    means = [statistics.fmean(rng.choices(values, k=n)) for _ in range(resamples)]
    return percentile(means, 0.025), percentile(means, 0.975)


def summarize(values: list[float]) -> dict[str, float | int]:
    if not values:
        raise ValueError("summarize requires at least one value")
    mean = statistics.fmean(values)
    stdev = statistics.stdev(values) if len(values) > 1 else 0.0
    ci_low, ci_high = bootstrap_mean_ci(values)
    return {
        "n": len(values),
        "mean": mean,
        "median": statistics.median(values),
        "minimum": min(values),
        "maximum": max(values),
        "p5_linear": percentile(values, 0.05),
        "p95_linear": percentile(values, 0.95),
        "sample_stddev": stdev,
        "coefficient_of_variation": stdev / mean if mean else math.nan,
        "bootstrap_mean_ci95_low": ci_low,
        "bootstrap_mean_ci95_high": ci_high,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--group-columns", default="model,experiment,metric,unit",
        help="comma-separated grouping columns",
    )
    parser.add_argument("--value-column", default="value")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        result = summarize([1.0, 2.0, 3.0, 4.0, 5.0])
        assert result["mean"] == 3.0
        assert result["median"] == 3.0
        assert abs(float(result["p5_linear"]) - 1.2) < 1e-12
        assert abs(float(result["p95_linear"]) - 4.8) < 1e-12
        print("self-test passed")
        return 0

    if args.input is None or args.output is None:
        parser.error("--input and --output are required unless --self-test is used")
    groups = [x.strip() for x in args.group_columns.split(",") if x.strip()]
    grouped: dict[tuple[str, ...], list[float]] = defaultdict(list)
    with args.input.open(newline="") as stream:
        for row in csv.DictReader(stream):
            grouped[tuple(row[column] for column in groups)].append(
                float(row[args.value_column])
            )

    stat_fields = list(summarize([0.0]).keys())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=groups + stat_fields + ["percentile_method", "ci_method"],
            lineterminator="\n",
        )
        writer.writeheader()
        for key in sorted(grouped):
            row = dict(zip(groups, key))
            row.update(summarize(grouped[key]))
            row["percentile_method"] = "R-7 linear interpolation"
            row["ci_method"] = "deterministic percentile bootstrap of mean; 20000 resamples; seed 20260821"
            writer.writerow(row)
    print(f"wrote {len(grouped)} aggregate rows to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
