#!/usr/bin/env python3
"""Summarize paired real-checkpoint gfx1151 runtime serving measurements."""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from pathlib import Path


def percentile(values: list[float], fraction: float) -> float:
    values = sorted(values)
    position = fraction * (len(values) - 1)
    lower = int(position)
    upper = min(lower + 1, len(values) - 1)
    weight = position - lower
    return values[lower] * (1 - weight) + values[upper] * weight


def stats(values: list[float]) -> dict[str, float]:
    return {
        "median": statistics.median(values),
        "p90": percentile(values, 0.9),
        "mean": statistics.mean(values),
    }


def ids_sha256(values: list[int]) -> str:
    return hashlib.sha256(
        b"".join(int(value).to_bytes(4, "little", signed=False) for value in values)
    ).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    records: list[dict[str, object]] = []
    by_case: dict[tuple[int, str], dict[str, dict[str, object]]] = {}
    graph_modes: set[str] = set()
    for path in sorted(args.directory.glob("round-*-*/request-*.json")):
        parts = path.parent.name.split("-")
        round_index = int(parts[1])
        variant = parts[2]
        sample = path.stem.removeprefix("request-")
        payload = json.loads(path.read_text())
        if payload["target"] != "gfx1151" or payload["measurement_status"] != "measured":
            raise RuntimeError(f"invalid measurement identity: {path}")
        if payload["cached_tokens"] != 0:
            raise RuntimeError(f"cached result is not an uncached A/B sample: {path}")
        graph_modes.add(str(payload["graph_mode"]))
        output_hash = ids_sha256(payload["output_ids"])
        record = {
            "round": round_index,
            "sample": sample,
            "variant": variant,
            "path": str(path),
            "input_sha256": payload["input_ids_sha256"],
            "output_ids_sha256": output_hash,
            "host_e2e_ms": float(payload["host_e2e_ms"]),
            "server_e2e_ms": float(payload["server_meta_info"]["e2e_latency"]) * 1000,
            "peak_vram_bytes": payload["peak_vram_bytes_sysfs_measured"],
        }
        records.append(record)
        by_case.setdefault((round_index, sample), {})[variant] = record

    if not records:
        raise RuntimeError(f"no serving records below {args.directory}")
    mismatches = []
    paired_delta_ms = []
    for case, variants in sorted(by_case.items()):
        if set(variants) != {"old", "new"}:
            raise RuntimeError(f"unpaired case {case}: {sorted(variants)}")
        old = variants["old"]
        new = variants["new"]
        if old["input_sha256"] != new["input_sha256"] or old["output_ids_sha256"] != new["output_ids_sha256"]:
            mismatches.append({"case": case, "old": old, "new": new})
        paired_delta_ms.append(float(new["host_e2e_ms"]) - float(old["host_e2e_ms"]))

    if len(graph_modes) != 1:
        raise RuntimeError(f"mixed graph modes in A/B results: {sorted(graph_modes)}")
    summary: dict[str, object] = {
        "target": "gfx1151",
        "measurement_status": "measured",
        "graph_mode": next(iter(graph_modes)),
        "dflash_mode": "disabled",
        "uncached": True,
        "paired_cases": len(by_case),
        "tokens_bit_exact": not mismatches,
        "mismatches": mismatches,
        "paired_host_e2e_delta_ms": stats(paired_delta_ms),
        "variants": {},
        "records": records,
    }
    variants_summary = summary["variants"]
    assert isinstance(variants_summary, dict)
    for variant in ("old", "new"):
        selected = [record for record in records if record["variant"] == variant]
        host = [float(record["host_e2e_ms"]) for record in selected]
        server = [float(record["server_e2e_ms"]) for record in selected]
        variants_summary[variant] = {
            "samples": len(selected),
            "host_e2e_ms": stats(host),
            "server_e2e_ms": stats(server),
            "peak_vram_bytes_max": max(
                int(record["peak_vram_bytes"])
                for record in selected
                if record["peak_vram_bytes"] is not None
            ),
        }
    old_median = variants_summary["old"]["host_e2e_ms"]["median"]
    new_median = variants_summary["new"]["host_e2e_ms"]["median"]
    summary["host_e2e_median_delta_percent"] = (new_median / old_median - 1) * 100

    rendered = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    output = args.output or args.directory / "summary.json"
    output.write_text(rendered)
    print(rendered, end="")
    return 0 if not mismatches else 1


if __name__ == "__main__":
    raise SystemExit(main())
