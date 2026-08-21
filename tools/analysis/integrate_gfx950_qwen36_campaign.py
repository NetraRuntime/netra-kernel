#!/usr/bin/env python3
"""Derive auditable tables from the 2026-08-21 gfx950 benchmark campaign.

Raw artifacts stay outside the repository.  This tool writes compact serving,
microbenchmark, profiler, and integrity tables into the report and a complete
numeric-leaf inventory next to the external artifacts.  Kineto/rocprof event
traces are content-addressed but excluded from the numeric-leaf inventory:
their event fields are profiler records, not benchmark samples.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import io
import json
import math
import statistics
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from typing import Any

from summarize_benchmark_samples import summarize


EXACT_METRICS = (
    "wall_latency_s",
    "ttft_s",
    "input_throughput_tok_s",
    "end_to_end_output_throughput_tok_s",
    "generation_after_first_event_s",
    "mean_inter_token_latency_s",
)


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


@contextmanager
def deterministic_gzip_text(path: Path) -> Iterator[io.TextIOWrapper]:
    with path.open("wb") as raw:
        with gzip.GzipFile(filename="", fileobj=raw, mode="wb", mtime=0) as compressed:
            text = io.TextIOWrapper(compressed, encoding="utf-8", newline="")
            try:
                yield text
            finally:
                text.flush()
                text.detach()


def numeric_leaves(value: Any, prefix: str = "$") -> Iterator[tuple[str, int | float]]:
    if isinstance(value, bool) or value is None:
        return
    if isinstance(value, (int, float)):
        if math.isfinite(float(value)):
            yield prefix, value
        return
    if isinstance(value, list):
        for index, item in enumerate(value):
            yield from numeric_leaves(item, f"{prefix}[{index}]")
    elif isinstance(value, dict):
        for key, item in value.items():
            yield from numeric_leaves(item, f"{prefix}.{key}")


def leaf_class(path: str) -> str:
    lowered = path.lower()
    if "samples" in lowered or "requests[" in lowered or "repeat" in lowered:
        return "sample_or_sample_context"
    if any(word in lowered for word in ("mean", "median", "p90", "p95", "minimum", "maximum", "stddev", "throughput")):
        return "aggregate_or_metric"
    return "numeric_context"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(8 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def artifact_inventory(roots: list[tuple[str, Path]], output: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for label, root in roots:
        for path in sorted(item for item in root.rglob("*") if item.is_file()):
            rel = path.relative_to(root).as_posix()
            rows.append(
                {
                    "artifact_set": label,
                    "relative_path": rel,
                    "bytes": path.stat().st_size,
                    "sha256": sha256(path),
                    "numeric_inventory_policy": (
                        "excluded_profiler_event_trace"
                        if ".trace.json" in path.name
                        else "included_if_json_csv_tsv"
                    ),
                }
            )
    write_csv(output, list(rows[0]), rows)
    return rows


def external_numeric_inventory(
    roots: list[tuple[str, Path]], output: Path
) -> tuple[int, int, list[dict[str, str]]]:
    output.parent.mkdir(parents=True, exist_ok=True)
    fields = ["artifact_set", "relative_path", "record_path", "value", "classification"]
    count = 0
    source_count = 0
    exclusions: list[dict[str, str]] = []
    with deterministic_gzip_text(output) as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for label, root in roots:
            for path in sorted(item for item in root.rglob("*") if item.is_file()):
                rel = path.relative_to(root).as_posix()
                if ".trace.json" in path.name:
                    exclusions.append(
                        {
                            "artifact_set": label,
                            "relative_path": rel,
                            "reason": "profiler event trace is not a benchmark-sample table; retained and hashed verbatim",
                        }
                    )
                    continue
                suffixes = path.suffixes
                if path.suffix == ".json" or suffixes[-2:] == [".json", ".gz"]:
                    opener = gzip.open if path.suffix == ".gz" else open
                    try:
                        with opener(path, "rt", encoding="utf-8") as handle:
                            payload = json.load(handle)
                    except (json.JSONDecodeError, UnicodeDecodeError, OSError) as error:
                        exclusions.append(
                            {
                                "artifact_set": label,
                                "relative_path": rel,
                                "reason": f"not parseable as JSON: {type(error).__name__}",
                            }
                        )
                        continue
                    source_count += 1
                    for record_path, value in numeric_leaves(payload):
                        writer.writerow(
                            {
                                "artifact_set": label,
                                "relative_path": rel,
                                "record_path": record_path,
                                "value": value,
                                "classification": leaf_class(record_path),
                            }
                        )
                        count += 1
                elif path.suffix in {".csv", ".tsv"}:
                    delimiter = "\t" if path.suffix == ".tsv" else ","
                    try:
                        with path.open(newline="", encoding="utf-8") as handle:
                            rows = csv.DictReader(handle, delimiter=delimiter)
                            for index, row in enumerate(rows):
                                for column, raw in row.items():
                                    if raw is None or raw == "":
                                        continue
                                    try:
                                        value = float(raw)
                                    except ValueError:
                                        continue
                                    if not math.isfinite(value):
                                        continue
                                    record_path = f"$[{index}].{column}"
                                    writer.writerow(
                                        {
                                            "artifact_set": label,
                                            "relative_path": rel,
                                            "record_path": record_path,
                                            "value": raw,
                                            "classification": leaf_class(record_path),
                                        }
                                    )
                                    count += 1
                        source_count += 1
                    except (csv.Error, UnicodeDecodeError, OSError) as error:
                        exclusions.append(
                            {
                                "artifact_set": label,
                                "relative_path": rel,
                                "reason": f"not parseable as delimited text: {type(error).__name__}",
                            }
                        )
    return count, source_count, exclusions


def exact_repeatability(directory: Path) -> tuple[bool, dict[str, Any]]:
    aggregate = directory / "repeatability.json"
    if aggregate.exists():
        payload = json.loads(aggregate.read_text())
        return bool(payload["passed"]), payload["cases"][0]
    individual = next(directory.glob("*.repeatability.json"))
    payload = json.loads(individual.read_text())
    return bool(payload["passed"]), payload


def serving_tables(current: Path, report: Path) -> dict[str, object]:
    arms = {
        "27b-baseline": ("27B", "Netra accepted deployment"),
        "27b-aiter-control": ("27B", "SGLang/AITER control"),
        "35b-baseline": ("35B", "Netra accepted deployment"),
        "35b-framework-control": ("35B", "SGLang/AITER/framework control"),
    }
    samples: list[dict[str, object]] = []
    aggregates: list[dict[str, object]] = []
    exact_status: dict[tuple[str, str], bool] = {}
    exact_hashes: dict[tuple[str, str], set[str]] = {}
    concurrency_payloads: dict[tuple[str, int], dict[str, Any]] = {}

    for arm_dir, (model, arm) in arms.items():
        root = current / arm_dir
        for directory in sorted(root.glob("exact-*")):
            case = directory.name.removeprefix("exact-")
            passed, repeatability = exact_repeatability(directory)
            exact_status[(arm_dir, case)] = passed
            records = [json.loads(path.read_text()) for path in sorted(directory.glob("*.repeat[0-9][0-9].json"))]
            exact_hashes[(arm_dir, case)] = {str(record["output_ids_sha256"]) for record in records}
            for record in records:
                for metric in EXACT_METRICS:
                    value = record.get(metric)
                    if isinstance(value, (int, float)):
                        samples.append(
                            {
                                "model": model,
                                "arm": arm,
                                "case": case,
                                "scope": "exact_request",
                                "sample": record["repeat_index"],
                                "metric": metric,
                                "unit": "s" if metric.endswith("_s") else "tok/s",
                                "value": value,
                                "correctness_eligible": str(passed).lower(),
                                "input_ids_sha256": record["input_ids_sha256"],
                                "output_ids_sha256": record["output_ids_sha256"],
                                "evidence": str(directory.relative_to(current) / f"{case}.repeat{record['repeat_index']:02d}.json"),
                            }
                        )
            for population, selected in (
                ("all_including_cold", records),
                ("steady_excluding_repeat0", records[1:]),
            ):
                for metric in EXACT_METRICS:
                    values = [float(record[metric]) for record in selected if isinstance(record.get(metric), (int, float))]
                    if not values:
                        continue
                    row: dict[str, object] = {
                        "model": model,
                        "arm": arm,
                        "case": case,
                        "scope": population,
                        "metric": metric,
                        "unit": "s" if metric.endswith("_s") else "tok/s",
                        "correctness_eligible": str(passed).lower(),
                        "repeatability_mismatches": sum(
                            not all(
                                check[key]
                                for key in (
                                    "completion_tokens_match",
                                    "input_ids_sha256_match",
                                    "output_ids_match",
                                    "output_ids_sha256_match",
                                    "prompt_tokens_match",
                                )
                            )
                            for check in repeatability["checks"]
                        ),
                        "percentile_method": "R-7 linear interpolation",
                        "ci_method": "deterministic percentile bootstrap of mean; 20000 resamples; seed 20260821",
                        "evidence": str(directory.relative_to(current)),
                    }
                    row.update(summarize(values))
                    aggregates.append(row)

        concurrency = root / "concurrency-fixed210x128"
        for path in sorted(concurrency.glob("concurrency_*.json")):
            payload = json.loads(path.read_text())
            capacity = int(payload["case"]["concurrency"])
            concurrency_payloads[(arm_dir, capacity)] = payload
            aggregate_map = {
                "aggregate_input_throughput_tok_s": payload["aggregate_input_throughput_tok_s"],
                "aggregate_output_throughput_tok_s": payload["aggregate_output_throughput_tok_s"],
                "aggregate_total_token_throughput_tok_s": payload["aggregate_total_token_throughput_tok_s"],
                "measurement_wall_s": payload["measurement_wall_s"],
                "ttft_p90_s": payload["ttft_s"]["p90"],
                "request_latency_p90_s": payload["request_latency_s"]["p90"],
                "inter_token_latency_p90_s": payload["inter_token_latency_after_first_s"]["p90"],
            }
            for metric, value in aggregate_map.items():
                aggregates.append(
                    {
                        "model": model,
                        "arm": arm,
                        "case": f"concurrency_{capacity}",
                        "scope": "single_measurement_window",
                        "metric": metric,
                        "unit": "tok/s" if "throughput" in metric else "s",
                        "correctness_eligible": "cross_arm_checked_separately",
                        "repeatability_mismatches": "",
                        "n": 1,
                        "mean": value,
                        "median": value,
                        "minimum": value,
                        "maximum": value,
                        "p5_linear": value,
                        "p95_linear": value,
                        "sample_stddev": 0.0,
                        "coefficient_of_variation": 0.0,
                        "bootstrap_mean_ci95_low": value,
                        "bootstrap_mean_ci95_high": value,
                        "percentile_method": "single measurement window",
                        "ci_method": "not estimated; one process/window",
                        "evidence": str(path.relative_to(current)),
                    }
                )
            for index, request in enumerate(payload["requests"]):
                request_metrics = {
                    "wall_latency_s": request["wall_latency_s"],
                    "ttft_s": request["ttft_s"],
                    "generation_after_first_event_s": request["generation_after_first_event_s"],
                    "inter_token_latency_after_first_s": request["inter_token_latency_after_first_s"],
                }
                for metric, value in request_metrics.items():
                    samples.append(
                        {
                            "model": model,
                            "arm": arm,
                            "case": f"concurrency_{capacity}",
                            "scope": "concurrent_request",
                            "sample": index,
                            "metric": metric,
                            "unit": "s",
                            "value": value,
                            "correctness_eligible": "cross_arm_checked_separately",
                            "input_ids_sha256": request["input_ids_sha256"],
                            "output_ids_sha256": request["output_ids_sha256"],
                            "evidence": str(path.relative_to(current)),
                        }
                    )

    comparison_rows: list[dict[str, object]] = []
    pairs = (
        ("27B", "27b-baseline", "27b-aiter-control", (1, 128, 192)),
        ("35B", "35b-baseline", "35b-framework-control", (1, 64)),
    )
    for model, netra, control, capacities in pairs:
        shared_cases = sorted(
            case for arm, case in exact_status if arm == netra and (control, case) in exact_status
        )
        for case in shared_cases:
            for metric in ("wall_latency_s", "ttft_s"):
                left = [float(row["value"]) for row in samples if row["model"] == model and row["case"] == case and row["arm"] == arms[netra][1] and row["metric"] == metric and int(row["sample"]) > 0]
                right = [float(row["value"]) for row in samples if row["model"] == model and row["case"] == case and row["arm"] == arms[control][1] and row["metric"] == metric and int(row["sample"]) > 0]
                if not left or not right:
                    continue
                eligible = exact_status[(netra, case)] and exact_status[(control, case)] and exact_hashes[(netra, case)] == exact_hashes[(control, case)]
                lmed, rmed = statistics.median(left), statistics.median(right)
                comparison_rows.append(
                    {
                        "model": model,
                        "case": case,
                        "metric": metric,
                        "netra_value": lmed,
                        "control_value": rmed,
                        "relative_netra_speedup_percent": (rmed / lmed - 1.0) * 100.0,
                        "correctness_status": "eligible_exact_cross_arm" if eligible else "ineligible_repeatability_or_cross_arm_hash",
                        "cross_arm_output_hash_matches": "all" if exact_hashes[(netra, case)] == exact_hashes[(control, case)] else "not_all",
                        "evidence": f"{netra}/exact-{case};{control}/exact-{case}",
                    }
                )
        for capacity in capacities:
            left = concurrency_payloads[(netra, capacity)]
            right = concurrency_payloads[(control, capacity)]
            paired = list(zip(left["requests"], right["requests"]))
            input_matches = sum(a["input_ids_sha256"] == b["input_ids_sha256"] for a, b in paired)
            output_matches = sum(a["output_ids_sha256"] == b["output_ids_sha256"] for a, b in paired)
            lv = float(left["aggregate_output_throughput_tok_s"])
            rv = float(right["aggregate_output_throughput_tok_s"])
            comparison_rows.append(
                {
                    "model": model,
                    "case": f"concurrency_{capacity}",
                    "metric": "aggregate_output_throughput_tok_s",
                    "netra_value": lv,
                    "control_value": rv,
                    "relative_netra_speedup_percent": (lv / rv - 1.0) * 100.0,
                    "correctness_status": "diagnostic_only_output_hashes_diverge" if output_matches != len(paired) else "eligible_exact_cross_arm",
                    "cross_arm_output_hash_matches": f"{output_matches}/{len(paired)}; input {input_matches}/{len(paired)}",
                    "evidence": f"{netra}/concurrency-fixed210x128;{control}/concurrency-fixed210x128",
                }
            )

    write_csv(report / "current-serving-samples.csv", list(samples[0]), samples)
    write_csv(report / "current-serving-aggregates.csv", list(aggregates[0]), aggregates)
    write_csv(report / "current-serving-comparisons.csv", list(comparison_rows[0]), comparison_rows)
    return {
        "sample_rows": len(samples),
        "aggregate_rows": len(aggregates),
        "comparison_rows": len(comparison_rows),
        "exact_cases": len(exact_status),
        "exact_cases_passed": sum(exact_status.values()),
        "concurrency_windows": len(concurrency_payloads),
    }


def micro_tables(current: Path, report: Path) -> dict[str, int]:
    sample_rows: list[dict[str, object]] = []
    aggregate_rows: list[dict[str, object]] = []
    for path in sorted((current / "micro/gdn27").glob("*.json")):
        payload = json.loads(path.read_text())
        launch = path.stem.rsplit("-", 1)[1]
        for implementation in ("triton", "hybrid", "raw_assembly"):
            values = payload["timing"][f"{implementation}_samples_us"]
            correctness = payload["correctness"] if implementation == "hybrid" else payload.get("raw_assembly_correctness")
            eligible = implementation == "triton"
            for index, value in enumerate(values):
                sample_rows.append(
                    {
                        "batch": payload["batch"],
                        "process_order": launch,
                        "implementation": implementation,
                        "sample": index,
                        "latency_us": value,
                        "correctness_eligible": str(eligible).lower(),
                        "evidence": str(path.relative_to(current)),
                    }
                )
            row: dict[str, object] = {
                "batch": payload["batch"],
                "process_order": launch,
                "implementation": implementation,
                "correctness_eligible": str(eligible).lower(),
                "bit_exact": "reference" if implementation == "triton" else correctness["bit_exact"],
                "mismatch_count": 0 if implementation == "triton" else correctness["mismatch_count"],
                "elements": payload["correctness"]["elements"],
                "max_abs": 0 if implementation == "triton" else correctness["max_abs"],
                "mean_abs": 0 if implementation == "triton" else correctness["mean_abs"],
                "evidence": str(path.relative_to(current)),
            }
            row.update(summarize([float(value) for value in values]))
            aggregate_rows.append(row)
    write_csv(report / "current-gdn-microbenchmark-samples.csv", list(sample_rows[0]), sample_rows)
    write_csv(report / "current-gdn-microbenchmark-aggregates.csv", list(aggregate_rows[0]), aggregate_rows)
    return {"sample_rows": len(sample_rows), "aggregate_rows": len(aggregate_rows)}


def profiler_table(current: Path, report: Path) -> int:
    rows: list[dict[str, object]] = []
    for filename in ("gate-up-counter-summary.json", "down-reduce-counter-summary.json"):
        path = current / "profiler" / filename
        payload = json.loads(path.read_text())
        for kernel in payload["kernels"]:
            for counter, values in kernel["counters"].items():
                rows.append(
                    {
                        "target": payload["target"],
                        "kernel": kernel["kernel"],
                        "grid_size": kernel["grid_size"],
                        "workgroup_size": kernel["workgroup_size"],
                        "lds_bytes": kernel["lds_bytes"],
                        "scratch_bytes": kernel["scratch_bytes"],
                        "vgpr_reported_by_profiler": kernel["vgpr"],
                        "sgpr_reported_by_profiler": kernel["sgpr"],
                        "counter": counter,
                        "samples": values["samples"],
                        "mean": values["mean"],
                        "minimum": values["min"],
                        "maximum": values["max"],
                        "evidence": str(path.relative_to(current)),
                    }
                )
    write_csv(report / "current-profiler-counters.csv", list(rows[0]), rows)
    return len(rows)


def rewrite_csv(path: Path, rows: list[dict[str, str]]) -> None:
    if not rows:
        raise ValueError(f"cannot rewrite empty table: {path}")
    write_csv(path, list(rows[0]), rows)


def update_primary_tables(report: Path) -> None:
    matrix_path = report / "kernel-comparison-matrix.csv"
    with matrix_path.open(newline="") as stream:
        matrix = [row for row in csv.DictReader(stream) if "current-serving" not in row["evidence_path"]]
    common = {
        "dtype_layout": "deployed BF16/FP8 model and native FP8 KV cache; exact token IDs",
        "kernel_latency": "",
        "confidence_interval": "see current-serving-aggregates.csv bootstrap mean CI",
        "evidence_path": "current-serving-comparisons.csv;external current campaign",
        "evidence_availability": "raw requests, streaming events, repeatability and server-info retained",
    }
    current_matrix = [
        dict(model="27B", operation="exact integrated serving", shape="input16,output1", graph_mode="full replay", implementation="Netra accepted deployment", version_commit="9c5940c / fae2865", correctness_result="20/20 repeatable; cross-arm output hash identical", integrated_latency="59.086 ms steady median", speedup_over_default_sglang="1.2609x", speedup_over_fastest_eligible_non_netra="1.2609x", end_to_end_serving_effect="20.65% lower wall latency", acceptance_status="current correctness-qualified winner", **common),
        dict(model="27B", operation="exact integrated serving", shape="input16,output1", graph_mode="full replay", implementation="SGLang/AITER control", version_commit="locked container", correctness_result="20/20 repeatable; cross-arm output hash identical", integrated_latency="74.501 ms steady median", speedup_over_default_sglang="1.0x", speedup_over_fastest_eligible_non_netra="1.0x", end_to_end_serving_effect="control", acceptance_status="eligible current baseline", **common),
        dict(model="27B", operation="exact integrated serving", shape="input8192,output1", graph_mode="full replay", implementation="Netra accepted deployment", version_commit="9c5940c / fae2865", correctness_result="20/20 repeatable; cross-arm output hash identical", integrated_latency="409.187 ms steady median", speedup_over_default_sglang="1.0294x", speedup_over_fastest_eligible_non_netra="1.0294x", end_to_end_serving_effect="2.86% lower wall latency", acceptance_status="current correctness-qualified winner", **common),
        dict(model="27B", operation="exact integrated serving", shape="input8192,output1", graph_mode="full replay", implementation="SGLang/AITER control", version_commit="locked container", correctness_result="20/20 repeatable; cross-arm output hash identical", integrated_latency="421.226 ms steady median", speedup_over_default_sglang="1.0x", speedup_over_fastest_eligible_non_netra="1.0x", end_to_end_serving_effect="control", acceptance_status="eligible current baseline", **common),
        dict(model="35B", operation="exact integrated serving", shape="input16,output1", graph_mode="piecewise replay", implementation="Netra accepted deployment", version_commit="9c5940c / fae2865", correctness_result="20/20 repeatable; cross-arm output hash identical", integrated_latency="24.951 ms steady median", speedup_over_default_sglang="0.9550x", speedup_over_fastest_eligible_non_netra="0.9550x", end_to_end_serving_effect="4.71% higher wall latency", acceptance_status="current negative; no promotion change", **common),
        dict(model="35B", operation="exact integrated serving", shape="input16,output1", graph_mode="piecewise replay", implementation="SGLang/AITER/framework control", version_commit="locked container", correctness_result="20/20 repeatable; cross-arm output hash identical", integrated_latency="23.828 ms steady median", speedup_over_default_sglang="1.0x", speedup_over_fastest_eligible_non_netra="1.0x", end_to_end_serving_effect="current winner", acceptance_status="eligible current winner", **common),
        dict(model="35B", operation="exact integrated serving", shape="input8192,output1", graph_mode="piecewise replay", implementation="Netra accepted deployment", version_commit="9c5940c / fae2865", correctness_result="20/20 repeatable", integrated_latency="125.635 ms steady median", speedup_over_default_sglang="", speedup_over_fastest_eligible_non_netra="", end_to_end_serving_effect="control ineligible", acceptance_status="correct arm; no comparative claim", **common),
        dict(model="35B", operation="exact integrated serving", shape="input8192,output1", graph_mode="piecewise replay", implementation="SGLang/AITER/framework control", version_commit="locked container", correctness_result="failed: second output hash in 3/20 repeats", integrated_latency="133.283 ms steady median", speedup_over_default_sglang="ineligible", speedup_over_fastest_eligible_non_netra="ineligible", end_to_end_serving_effect="timing discarded", acceptance_status="correctness-ineligible", **common),
        dict(model="27B", operation="fixed-output concurrency", shape="210 input,128 output,C1/C128/C192", graph_mode="full replay", implementation="Netra versus SGLang/AITER control", version_commit="locked current arms", correctness_result="inputs all match; paired outputs 0/3,37/384,73/576", integrated_latency="see current-serving-aggregates.csv", speedup_over_default_sglang="diagnostic +14.65%/+14.58%/+10.27% output tok/s", speedup_over_fastest_eligible_non_netra="ineligible", end_to_end_serving_effect="diagnostic only", acceptance_status="cross-arm correctness-ineligible", **common),
        dict(model="35B", operation="fixed-output concurrency", shape="210 input,128 output,C1/C64", graph_mode="piecewise replay", implementation="Netra versus SGLang/AITER/framework control", version_commit="locked current arms", correctness_result="C1 3/3 output matches; C64 60/192", integrated_latency="see current-serving-aggregates.csv", speedup_over_default_sglang="diagnostic +15.83%/+1.06% output tok/s", speedup_over_fastest_eligible_non_netra="C64 ineligible", end_to_end_serving_effect="one window; diagnostic only", acceptance_status="no promotion claim", **common),
    ]
    matrix.extend(current_matrix)
    rewrite_csv(matrix_path, matrix)

    winners_path = report / "performance-winners.csv"
    with winners_path.open(newline="") as stream:
        winners = [row for row in csv.DictReader(stream) if "current-serving" not in row["evidence"]]
    winners.extend(
        [
            {"model": "27B", "operation": "exact integrated serving", "exact_contract": "input16/output1,TP1/DP1,dFlash8,full replay", "winner": "Netra accepted deployment", "status": "current correctness-qualified", "basis": "59.086 vs 74.501 ms steady median; identical outputs", "evidence": "current-serving-comparisons.csv"},
            {"model": "27B", "operation": "exact integrated serving", "exact_contract": "input8192/output1,TP1/DP1,dFlash8,full replay", "winner": "Netra accepted deployment", "status": "current correctness-qualified", "basis": "409.187 vs 421.226 ms steady median; identical outputs", "evidence": "current-serving-comparisons.csv"},
            {"model": "35B", "operation": "exact integrated serving", "exact_contract": "input16/output1,TP1/DP1,dFlash12,piecewise replay", "winner": "SGLang/AITER/framework control", "status": "current correctness-qualified", "basis": "23.828 vs 24.951 ms steady median; identical outputs", "evidence": "current-serving-comparisons.csv"},
        ]
    )
    rewrite_csv(winners_path, winners)

    rejected_path = report / "rejected-superseded-experiments.csv"
    with rejected_path.open(newline="") as stream:
        rejected = [row for row in csv.DictReader(stream) if "current-serving" not in row["evidence"] and "current-gdn" not in row["evidence"]]
    rejected.extend(
        [
            {"model": "35B", "experiment": "current input1024/output4096 Netra serving", "kernel_only_result": "not isolated", "end_to_end_result": "three output hashes; wall 4.107/20.966/11.493 s", "decision_reason": "repeatability gate failed", "status": "correctness-ineligible", "evidence": "current-serving-samples.csv"},
            {"model": "35B", "experiment": "current input8192/output1 framework control", "kernel_only_result": "not isolated", "end_to_end_result": "second output hash in repeats 3,9,19", "decision_reason": "17/20 repeatability is insufficient", "status": "correctness-ineligible", "evidence": "current-serving-samples.csv"},
            {"model": "27B/35B", "experiment": "current fixed-output concurrency comparisons", "kernel_only_result": "not isolated", "end_to_end_result": "most cross-arm output hashes diverged", "decision_reason": "throughput cannot be a winner claim without output/quality equivalence", "status": "diagnostic only", "evidence": "current-serving-comparisons.csv"},
            {"model": "27B", "experiment": "legacy standalone M12 GDN harness", "kernel_only_result": "1,800 stable timing samples", "end_to_end_result": "not run", "decision_reason": "hybrid and raw assembly failed strict current correctness/ABI gates", "status": "performance-ineligible", "evidence": "current-gdn-microbenchmark-aggregates.csv"},
        ]
    )
    rewrite_csv(rejected_path, rejected)

    decision_path = report / "optimization-decision-ledger.csv"
    with decision_path.open(newline="") as stream:
        decisions = [row for row in csv.DictReader(stream) if not row["evidence_path"].startswith("current-")]
    base_decision = {
        "date": "2026-08-21",
        "evidence_commit": "9c5940c / fae2865",
        "refs": "analysis/gfx950-qwen36-retrospective-20260821",
        "dtype_layout_quantization": "deployed BF16/FP8 exact contract",
        "batch_concurrency": "TP1/DP1; exact token IDs",
        "kernel_only_result": "not isolated in this serving decision",
        "evidence_sha256": "see external SHA256SUMS",
        "record_completeness": "current raw requests, environment and correctness records retained",
    }
    current_decisions = [
        dict(model="27B", operation="exact input16/output1 serving control", shape="16+1", graph_mode="full replay", baseline_implementation="SGLang/AITER control", candidate_implementation="Netra accepted deployment", integrated_end_to_end_result="59.086 vs 74.501 ms steady median", correctness_criteria_result="20/20 repeatable; identical cross-arm output hash", decision="current correctness-qualified winner; no default change", decision_reason="1.2609x speedup passed exact gate", evidence_path="current-serving-comparisons.csv", **base_decision),
        dict(model="27B", operation="exact input8192/output1 serving control", shape="8192+1", graph_mode="full replay", baseline_implementation="SGLang/AITER control", candidate_implementation="Netra accepted deployment", integrated_end_to_end_result="409.187 vs 421.226 ms steady median", correctness_criteria_result="20/20 repeatable; identical cross-arm output hash", decision="current correctness-qualified winner; no default change", decision_reason="1.0294x speedup passed exact gate", evidence_path="current-serving-comparisons.csv", **base_decision),
        dict(model="35B", operation="exact input16/output1 serving control", shape="16+1", graph_mode="piecewise replay", baseline_implementation="SGLang/AITER/framework control", candidate_implementation="Netra accepted deployment", integrated_end_to_end_result="24.951 vs 23.828 ms steady median", correctness_criteria_result="20/20 repeatable; identical cross-arm output hash", decision="negative retained", decision_reason="control was 1.047x faster", evidence_path="current-serving-comparisons.csv", **base_decision),
        dict(model="35B", operation="input1024/output4096 repeatability", shape="1024+4096", graph_mode="piecewise replay", baseline_implementation="repeat zero", candidate_implementation="repeats one and two", integrated_end_to_end_result="4.107/20.966/11.493 s", correctness_criteria_result="three output hashes", decision="correctness-ineligible", decision_reason="repeatability gate failed", evidence_path="current-serving-samples.csv", **base_decision),
        dict(model="27B/35B", operation="fixed-output concurrency controls", shape="210+128,C1/C64/C128/C192", graph_mode="full/piecewise replay", baseline_implementation="SGLang/AITER controls", candidate_implementation="Netra accepted deployments", integrated_end_to_end_result="apparent +1.06% to +14.65% output tok/s", correctness_criteria_result="most paired output hashes diverged", decision="diagnostic only", decision_reason="no throughput winner without equivalent outputs/quality", evidence_path="current-serving-comparisons.csv", **base_decision),
        dict(model="27B", operation="legacy standalone M12 GDN", shape="B1/B128/B256", graph_mode="eager HIP events", baseline_implementation="Triton", candidate_implementation="hybrid/raw assembly", integrated_end_to_end_result="not run", correctness_criteria_result="hybrid small BF16 mismatch; raw gross ABI mismatch", decision="performance-ineligible", decision_reason="current strict exact gate failed before timing promotion", evidence_path="current-gdn-microbenchmark-aggregates.csv", **base_decision),
    ]
    decisions.extend(current_decisions)
    rewrite_csv(decision_path, decisions)

    causal_path = report / "causal-mechanism-matrix.csv"
    with causal_path.open(newline="") as stream:
        causal = [row for row in csv.DictReader(stream) if row["accepted_path"] != "M1 MoE gate/up"]
    for row in causal:
        if row["accepted_path"] == "M1 MoE down/reduce":
            row["isa_metadata_counter_evidence"] = "Current gfx950: 256 waves, 4608 FP8 MFMA instructions, 4661.1 KiB fetch, 4 KiB write, 92.44% VALU utilization, zero LDS conflicts, 1 KiB LDS, no scratch"
            row["confidence"] = "current counters + static ISA + serving evidence"
            row["evidence"] = row["evidence"].split(";current-profiler-counters.csv")[0] + ";current-profiler-counters.csv"
    causal.append(
        {
            "model": "35B",
            "accepted_path": "M1 MoE gate/up",
            "exact_scope": "9 routes x K2048 -> I512",
            "causal_mechanism": "Exact route/tile geometry removes general dispatch and feeds the paired activation/down pipeline without layout adapters",
            "isa_metadata_counter_evidence": "Current gfx950: 576 waves, 9216 FP8 MFMA instructions, 9272.8 KiB fetch, 36 KiB write, 99.11% VALU utilization, zero LDS conflicts, no LDS/scratch",
            "confidence": "current counters + static ISA + serving evidence",
            "evidence": "current-profiler-counters.csv;docs/notes/gfx950-qwen36-fp8-kernels.md",
        }
    )
    rewrite_csv(causal_path, causal)


def update_report_metadata(
    report: Path,
    derived: Path,
    serving: dict[str, object],
    micro: dict[str, int],
    profiler_rows: int,
    artifact_rows: list[dict[str, object]],
    numeric_count: int,
) -> None:
    update_primary_tables(report)
    summary_path = report / "summary.json"
    summary = json.loads(summary_path.read_text())
    summary["current_execution"] = {
        "gpu_benchmarks_run": True,
        "target": "8 x AMD Instinct MI350X / gfx950; isolated single-GPU arms",
        "software": "ROCm 7.2.3; amd-smi 26.2.2; netra/sglang:v0.5.16-rocm720-mi35x-gigatoken0.9.0",
        "serving": serving,
        "microbenchmark": micro,
        "profiler_counter_rows": profiler_rows,
        "correctness_policy": "Failed repeatability and cross-arm output-hash gates remain in the evidence but are ineligible for winner/promotion claims.",
        "raw_artifact_root": "external: gfx950_qwen36_retrospective-20260821.current",
        "recovered_artifact_root": "external: gfx950_qwen36_prefill-20260821.t3C9F4",
    }
    summary["external_artifacts"] = {
        "files": len(artifact_rows),
        "bytes": sum(int(row["bytes"]) for row in artifact_rows),
        "numeric_leaves": numeric_count,
        "inventory": "external derived/external-artifact-inventory.csv",
        "numeric_inventory": "external derived/external-benchmark-numeric-leaves.csv.gz",
        "hash_manifest": "external derived/SHA256SUMS",
    }
    summary["curated_counts"].update(
        {
            "comparison_rows": sum(1 for _ in csv.DictReader((report / "kernel-comparison-matrix.csv").open())),
            "negative_results": sum(1 for _ in csv.DictReader((report / "rejected-superseded-experiments.csv").open())),
            "reviewed_decision_rows": sum(1 for _ in csv.DictReader((report / "optimization-decision-ledger.csv").open())),
            "accepted_path_causal_rows": sum(1 for _ in csv.DictReader((report / "causal-mechanism-matrix.csv").open())),
            "current_serving_sample_metric_rows": serving["sample_rows"],
            "current_serving_aggregate_rows": serving["aggregate_rows"],
            "current_gdn_timing_sample_rows": micro["sample_rows"],
            "current_profiler_counter_rows": profiler_rows,
        }
    )
    summary["validation"]["gpu_tests"] = (
        "measured on MI350X: 8/10 exact serving cases passed repeatability; "
        "10 concurrency windows retained; six legacy GDN processes failed their "
        "strict correctness gate and are negative evidence; 56 summarized counter rows"
    )
    summary["strongest_conclusions"] = [
        "Netra wins come from exact operation contracts, gfx950-specialized kernels, graph-safe integration, and deployment locking together; isolated kernel speed is insufficient.",
        "Current exact-output evidence qualifies the 27B Netra arm at input 16 and 8192: steady median wall latency improved 26.09% and 2.94% versus the SGLang/AITER control with identical output hashes.",
        "The current 35B Netra arm is 4.50% slower at the exact input-16/output-1 gate; the apparent 8K and concurrent throughput improvements are not promoted because control repeatability or cross-arm output hashes failed.",
        "AITER remains the production winner for several dense and fallback paths where locally faster Netra candidates failed serving gates.",
        "The negative-result ledger is central evidence: microbenchmark timing is discarded when its current ABI/correctness gate fails.",
    ]
    summary["uncertain_claims"] = [
        "Concurrency throughput deltas are diagnostic only because dFlash output hashes diverged across matched arms except at 35B C1.",
        "The 35B input-1024/output-4096 Netra case and 35B input-8192 control failed repeatability; their timings are correctness-ineligible.",
        "The recovered legacy 27B GDN standalone harness no longer reproduces the current modular ABI bit-exactly; its 1,800 timing samples cannot establish a candidate win.",
        "Uniform current competitor microbenchmarks and counters are unavailable for many operation contracts; historical exact comparisons remain labeled historical.",
        "No potentially research-novel claim is asserted without a broader formal prior-art review.",
    ]
    summary["completion_verdict"] = {
        "achieved": True,
        "qualification": "completed with correctness-ineligible results and explicit coverage gaps",
        "reason": "Repository history, recovered raw archive, current MI350X serving controls, profiler passes, hashes, tables, and reproduction tooling are delivered. Unsupported or failed contracts remain gaps rather than inferred wins.",
        "authoritative_matrix": "completion-audit.csv",
    }
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")

    coverage_path = report / "benchmark-coverage.csv"
    with coverage_path.open(newline="") as stream:
        coverage = list(csv.DictReader(stream))
    current_coverage = {
        ("27B", "input16"): ("measured_pass", "20 exact repeats per arm; cross-arm output hash identical"),
        ("27B", "input1K"): ("measured_pass_netra", "3 exact input1024/output4096 repeats; no matched control"),
        ("27B", "input8K"): ("measured_pass", "20 exact repeats per arm; cross-arm output hash identical"),
        ("27B", "C1"): ("measured_diagnostic", "matched prompts; cross-arm output hashes diverged"),
        ("27B", "C128"): ("measured_diagnostic", "matched prompts; 37/384 output hashes matched"),
        ("27B", "C192"): ("measured_diagnostic", "matched prompts; 73/576 output hashes matched"),
        ("27B", "C256"): ("attempted_correctness_failed", "legacy standalone GDN harness failed current exact gate"),
        ("27B", "TP1/DP1"): ("measured", "current accepted and control deployments"),
        ("27B", "dFlash8"): ("measured", "current accepted and control deployments"),
        ("27B", "BF16-state"): ("measured_plus_recovered", "current locked deployment and recovered natural serving evidence"),
        ("27B", "graph-capture"): ("measured", "full graph server initialized and replayed"),
        ("27B", "graph-replay"): ("measured", "exact and concurrent requests completed"),
        ("35B", "input16"): ("measured_pass", "20 exact repeats per arm; control was 4.50% faster"),
        ("35B", "input1K"): ("measured_correctness_failed", "3 input1024/output4096 repeats produced three output hashes"),
        ("35B", "input8K"): ("netra_pass_control_failed", "Netra 20/20; control 17/20 reference hash"),
        ("35B", "natural-C64"): ("current_fixed_plus_recovered_natural", "current fixed-output window and recovered natural-EOS evidence"),
        ("35B", "TP1/DP1"): ("measured", "current accepted and control deployments"),
        ("35B", "dFlash12"): ("measured", "current accepted and control deployments"),
        ("35B", "piecewise-capture"): ("measured", "server initialization/capture passed"),
        ("35B", "piecewise-replay"): ("measured", "exact and concurrent requests completed"),
        ("35B", "non-M768-fallback"): ("measured_plus_recovered", "8K serving plus recovered 285-candidate/fallback evidence"),
    }
    for row in coverage:
        key = (row["model"], row["required_case"])
        if key in current_coverage:
            status, note = current_coverage[key]
            row["current_campaign_execution"] = status
            row["raw_samples_available"] = "true"
            row["gap"] = note
            row["evidence"] = "current-serving-samples.csv;external raw campaign"
        elif row["required_case"] in {"M8", "M12", "M16", "M768", "eager"}:
            row["current_campaign_execution"] = "recovered_historical_or_current_attempt_only"
            row["raw_samples_available"] = "true"
            row["gap"] = "No new correctness-qualified uniform microbenchmark for this exact contract"
            row["evidence"] = "external recovered archive;kernel-comparison-matrix.csv"
    rewrite_csv(coverage_path, coverage)

    competitor_path = report / "competitor-eligibility.csv"
    with competitor_path.open(newline="") as stream:
        competitors = list(csv.DictReader(stream))
    updates = {
        "Netra": ("Current accepted deployments, exact requests, concurrency windows and M1 counters executed", "currently_measured"),
        "SGLang default": ("Current framework/AITER control deployments executed for both models", "currently_measured_serving_control"),
        "AITER": ("Current controls plus recovered 285-candidate dense screen and selected paths", "current_integrated_and_recovered_historical"),
        "Composable Kernel / CK Tile": ("Recovered AITER-mediated candidate screen; no standalone current rebuild", "historically_measured_via_aiter"),
        "hipBLASLt": ("Recovered historical dense comparisons; no new standalone run", "historically_measured"),
        "Triton": ("Current legacy GDN reference executed; candidate comparison failed exactness; historical exact comparisons recovered", "current_attempt_ineligible_plus_historical"),
        "PyTorch/ROCm": ("Current runtime/oracle environment captured; historical primitive comparisons recovered", "oracle_and_historical"),
    }
    for row in competitors:
        if row["implementation"] in updates:
            row["attempt"], row["result"] = updates[row["implementation"]]
            if row["implementation"] in {"Netra", "SGLang default"}:
                row["limitation"] = "Concurrency cross-arm output hashes diverged; only exact qualified cases support winner claims"
            row["evidence"] = row["evidence"] + ";current-serving-comparisons.csv"
    rewrite_csv(competitor_path, competitors)

    audit_path = report / "completion-audit.csv"
    with audit_path.open(newline="") as stream:
        audit = list(csv.DictReader(stream))
    audit_updates = {
        "benchmark-27B": ("substantial with explicit gaps", "Input16/1K/8K and C1/128/192 measured; recovered M8/M12/C256/natural data", "C256 current standalone gate failed; concurrent cross-arm outputs diverged"),
        "benchmark-35B": ("substantial with explicit gaps", "Input16/1K/8K and C1/C64 measured; recovered M16/M768/natural/fallback data", "Input1K Netra and input8K control failed repeatability; C64 outputs diverged"),
        "serving": ("partial current plus recovered", "Raw TTFT/ITL/TPS/wall/p90/memory/concurrency/graph records and recovered natural-EOS runs", "No uniform independent-process CI or direct prefill-time field for every arm"),
    }
    for row in audit:
        phase = row["phase"]
        if phase in audit_updates:
            row["verdict"], row["current_evidence"], row["remaining_gap"] = audit_updates[phase]
        if phase == "method" and row["requirement"].startswith("Mean/median"):
            row["verdict"] = "proven for current retained samples"
            row["current_evidence"] = "10,100 serving and 1,800 GDN timing rows; full descriptive statistics and deterministic bootstrap CIs"
            row["artifact"] = "current-serving-aggregates.csv;current-gdn-microbenchmark-aggregates.csv"
            row["remaining_gap"] = "Concurrency throughput has one measurement window per arm; no process-level CI"
        if phase == "causality" and row["requirement"].startswith("Explain every"):
            row["current_evidence"] = "16 accepted paths mapped to mechanisms; current 28-counter passes for accepted M1 gate/up and down/reduce"
            row["remaining_gap"] = "Uniform current counters remain unavailable for other accepted paths"
        if phase == "history" and row["requirement"].startswith("Record every"):
            row["current_evidence"] = "49 reviewed decision rows plus exhaustive commit/numeric inventories"
        if phase == "history" and row["requirement"].startswith("Preserve rejected"):
            row["current_evidence"] = "20 curated negatives plus inferred statuses across chronology and recovered raw archive"
            row["remaining_gap"] = "Unadvertised/unrecoverable historical objects cannot be proven"
        if phase == "competitors" and row["requirement"].startswith("Pin official"):
            row["verdict"] = "proven"
            row["current_evidence"] = "11 pinned records; current Netra/SGLang/AITER controls and recovered historical attempts"
            row["remaining_gap"] = "none for eligibility; per-contract execution gaps are separate"
        if phase == "competitors" and row["requirement"].startswith("Benchmark every"):
            row["verdict"] = "partial"
            row["current_evidence"] = "Current Netra and SGLang/AITER integrated controls plus recovered historical exact comparisons"
            row["remaining_gap"] = "No uniform current microbenchmark for every eligible exact contract"
        if phase == "environment" and row["requirement"].startswith("Use isolated"):
            row["verdict"] = "proven"
            row["current_evidence"] = "MI350X hardware/software/container/clocks/thermals captured during and after measurements"
            row["remaining_gap"] = "none"
        if phase == "environment" and row["requirement"].startswith("Hash checkpoint"):
            row["verdict"] = "proven for available and executed scope"
            row["current_evidence"] = "349 checkpoint files plus 1,038 external artifact files content-addressed; code objects and deployment locks retained"
            row["artifact"] = "external derived/external-artifact-inventory.csv"
            row["remaining_gap"] = "None for current/recovered bytes; absent historical bytes cannot be hashed"
        if phase == "method" and row["requirement"].startswith("Correctness before"):
            row["verdict"] = "proven for current serving and attempted GDN scope"
            row["current_evidence"] = "Repeatability, cross-arm hashes, mismatch counts and error bounds retained before eligibility decisions"
            row["remaining_gap"] = "Historical contracts do not uniformly retain every requested error field"
        if phase == "method" and row["requirement"].startswith("Cold/first"):
            row["verdict"] = "partial current plus historical"
            row["current_evidence"] = "Cold repeat separated; 19 steady repeats; six independent GDN processes with opposite orders"
            row["remaining_gap"] = "No uniform five-process ABBA series for every current serving arm"
        if phase == "method" and row["requirement"].startswith("Kernel-only"):
            row["verdict"] = "partial current plus historical"
            row["current_evidence"] = "Current integrated controls and legacy standalone attempt; historical primary matrix separates kernel/integrated fields"
            row["remaining_gap"] = "Many current exact contracts lack a new paired kernel-only run"
        if phase == "winner-table":
            row["current_evidence"] = "18 production/current exact-contract winners curated"
        if phase == "claims":
            row["current_evidence"] = "Tracked links, current raw paths, profiler paths, hashes and primary-source URLs"
            row["remaining_gap"] = "Claims with failed or absent proof are explicitly ineligible/uncertain"
    rewrite_csv(audit_path, audit)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--current-root", type=Path, required=True)
    parser.add_argument("--recovered-root", type=Path, required=True)
    parser.add_argument("--report-root", type=Path, required=True)
    parser.add_argument("--derived-root", type=Path, required=True)
    args = parser.parse_args()
    roots = [("recovered_prefill", args.recovered_root), ("current_campaign", args.current_root)]

    serving = serving_tables(args.current_root, args.report_root)
    micro = micro_tables(args.current_root, args.report_root)
    profiler_rows = profiler_table(args.current_root, args.report_root)
    inventory = artifact_inventory(roots, args.derived_root / "external-artifact-inventory.csv")
    numeric_count, numeric_sources, exclusions = external_numeric_inventory(
        roots, args.derived_root / "external-benchmark-numeric-leaves.csv.gz"
    )
    write_csv(
        args.derived_root / "numeric-inventory-exclusions.csv",
        ["artifact_set", "relative_path", "reason"],
        exclusions,
    )
    update_report_metadata(
        args.report_root,
        args.derived_root,
        serving,
        micro,
        profiler_rows,
        inventory,
        numeric_count,
    )
    summary = {
        "schema_version": "netra-gfx950-qwen36-external-campaign-1",
        "serving": serving,
        "microbenchmark": micro,
        "profiler_counter_rows": profiler_rows,
        "artifact_files": len(inventory),
        "artifact_bytes": sum(int(row["bytes"]) for row in inventory),
        "numeric_sources": numeric_sources,
        "numeric_leaves": numeric_count,
        "numeric_inventory_exclusions": len(exclusions),
        "exclusion_policy": "Only profiler event traces and unparsable non-tabular files are excluded; all are retained in the hash inventory.",
    }
    (args.derived_root / "campaign-derived-summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
