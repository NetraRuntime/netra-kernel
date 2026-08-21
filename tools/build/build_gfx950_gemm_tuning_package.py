#!/usr/bin/env python3
"""Build a deterministic, model-neutral gfx950 GEMM tuning package."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Table:
    source: str
    output: str
    header: tuple[str, ...]
    key: tuple[str, ...]
    dimensions: tuple[str, ...] = ("M", "N", "K")


TABLES = (
    Table(
        "manifests/gfx950/tuning/a8w8_blockscale_bpreshuffle.csv",
        "a8w8_blockscale_bpreshuffle.csv",
        (
            "gfx", "cu_num", "M", "N", "K", "libtype", "kernelId",
            "splitK", "us", "kernelName", "tflops", "bw", "errRatio",
        ),
        ("gfx", "cu_num", "M", "N", "K"),
    ),
    Table(
        "manifests/gfx950/tuning/bf16_gemm.csv",
        "bf16_gemm.csv",
        (
            "gfx", "cu_num", "M", "N", "K", "bias", "dtype",
            "outdtype", "scaleAB", "bpreshuffle", "libtype", "solidx",
            "splitK", "us", "kernelName", "err_ratio", "tflops", "bw",
        ),
        (
            "gfx", "cu_num", "M", "N", "K", "bias", "dtype",
            "outdtype", "scaleAB", "bpreshuffle",
        ),
    ),
    Table(
        "manifests/gfx950/tuning/a8w8_blockscale_bpreshuffle_m768.csv",
        "a8w8_blockscale_bpreshuffle_m768.csv",
        (
            "gfx", "cu_num", "M", "N", "K", "libtype", "kernelId",
            "splitK", "us", "kernelName", "tflops", "bw", "errRatio",
        ),
        ("gfx", "cu_num", "M", "N", "K"),
    ),
    Table(
        "manifests/gfx950/tuning/a8w8_blockscale_bpreshuffle_m768_stock.csv",
        "a8w8_blockscale_bpreshuffle_m768_stock.csv",
        (
            "gfx", "cu_num", "M", "N", "K", "libtype", "kernelId",
            "splitK", "us", "kernelName", "tflops", "bw", "errRatio",
        ),
        ("gfx", "cu_num", "M", "N", "K"),
    ),
    Table(
        "manifests/gfx950/tuning/bf16_gemm_m768.csv",
        "bf16_gemm_m768.csv",
        (
            "gfx", "cu_num", "M", "N", "K", "bias", "dtype",
            "outdtype", "scaleAB", "bpreshuffle", "libtype", "solidx",
            "splitK", "us", "kernelName", "err_ratio", "tflops", "bw",
        ),
        (
            "gfx", "cu_num", "M", "N", "K", "bias", "dtype",
            "outdtype", "scaleAB", "bpreshuffle",
        ),
    ),
    Table(
        "manifests/gfx950/tuning/fmoe_fp8_blockscale.csv",
        "fmoe_fp8_blockscale.csv",
        (
            "gfx", "cu_num", "token", "model_dim", "inter_dim", "expert",
            "topk", "act_type", "dtype", "q_dtype_a", "q_dtype_w", "q_type",
            "use_g1u1", "doweight_stage1", "block_m", "ksplit", "kernelName1",
            "kernelName2", "run_1stage",
        ),
        (
            "gfx", "cu_num", "token", "model_dim", "inter_dim", "expert",
            "topk", "act_type", "dtype", "q_dtype_a", "q_dtype_w", "q_type",
        ),
        ("token", "model_dim", "inter_dim", "expert", "topk"),
    ),
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _validate(source: Path, table: Table) -> int:
    with source.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != table.header:
            raise ValueError(f"unexpected header in {source}")
        rows = list(reader)
    if not rows:
        raise ValueError(f"empty tuning table: {source}")
    seen: set[tuple[str, ...]] = set()
    for row in rows:
        if row["gfx"] != "gfx950" or row["cu_num"] != "256":
            raise ValueError(f"unsupported target in {source}: {row}")
        for dimension in table.dimensions:
            if int(row[dimension]) <= 0:
                raise ValueError(f"invalid {dimension} in {source}: {row}")
        key = tuple(row[name] for name in table.key)
        if key in seen:
            raise ValueError(f"ambiguous duplicate tuning key in {source}: {key}")
        seen.add(key)
    return len(rows)


def build(repo: Path, output: Path) -> dict[str, object]:
    output.mkdir(parents=True, exist_ok=True)
    artifacts = []
    for table in TABLES:
        source = repo / table.source
        rows = _validate(source, table)
        destination = output / table.output
        shutil.copyfile(source, destination)
        source_hash = _sha256(source)
        output_hash = _sha256(destination)
        if output_hash != source_hash:
            raise RuntimeError(f"non-identical packaged table: {table.output}")
        artifacts.append(
            {
                "kind": "external_kernel_selection_table",
                "name": table.output,
                "rows": rows,
                "sha256": output_hash,
                "selection_key": list(table.key),
            }
        )
    report = {
        "format": "netra-gfx950-gemm-tuning-package-1",
        "target": "gfx950",
        "compute_units": 256,
        "runtime_selection": "exact_table_key",
        "netra_kernel_ownership": False,
        "framework_fallback": "AITER",
        "artifacts": artifacts,
    }
    (output / "package.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parents[2]
    )
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = build(args.repo_root.resolve(), args.output.resolve())
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
