#!/usr/bin/env python3
"""Full-stack rocprofv3 kernel inventory summarizer for gfx1151.

Ranks kernels by total GPU duration, counts launches, estimates launch gaps,
and classifies families for the Qwen3.6 SGLang path.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import statistics
from collections import defaultdict
from pathlib import Path


FAMILY_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("netra_mxfp4_linear", re.compile(r"netra_mxfp4.*linear|mxfp4_sgl_linear", re.I)),
    ("netra_mxfp4_moe", re.compile(r"(?:netra_)?mxfp4.*(gate|up|down|reduce|silu)", re.I)),
    ("triton_moe_matmul", re.compile(r"matmul_ogs|_fused_moe|moe_.*matmul", re.I)),
    ("triton_attention", re.compile(r"attn|attention|flash|paged|context_attention|extend_attention|decode_attention|prefill_attention", re.I)),
    ("gdn_linear_attn", re.compile(r"gdn|gated_delta|delta_rule|linear_attn|chunk_gated|recurrent", re.I)),
    ("rmsnorm", re.compile(r"rms.?norm|fused_add_rms|layernorm", re.I)),
    ("rope", re.compile(r"rope|rotary", re.I)),
    ("activation", re.compile(r"silu|gelu|act_and_mul|fused_act", re.I)),
    ("moe_routing", re.compile(r"topk|router|moe_align|moe_sum|grouped_topk|fused_moe_routing", re.I)),
    ("sampling_lm_head", re.compile(r"sampling|softmax|top_p|top_k|lm_head|logits", re.I)),
    ("elementwise_copy", re.compile(r"\b(?:copy|fill|zero|arange|index|gather|scatter|cat|transpose|reshape|contiguous|memcpy)", re.I)),
    ("conv_short", re.compile(r"conv1d|causal_conv|short_conv", re.I)),
    ("embedding", re.compile(r"embedding|embed", re.I)),
    ("reduce_misc", re.compile(r"reduce|sum_kernel|cumsum|exclusive_scan", re.I)),
    ("hip_blas_gemm", re.compile(r"Cijk|gemm|rocblas|hipblas|wmma|mfma", re.I)),
]


def classify(name: str) -> str:
    for family, pat in FAMILY_RULES:
        if pat.search(name):
            return family
    return "other"


def short_name(name: str, limit: int = 120) -> str:
    name = name.strip()
    if len(name) <= limit:
        return name
    return name[: limit - 3] + "..."


def load_kernel_rows(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            try:
                start = int(row["Start_Timestamp"])
                end = int(row["End_Timestamp"])
            except (KeyError, ValueError):
                continue
            if end < start:
                continue
            rows.append(
                {
                    "name": row.get("Kernel_Name") or row.get("Name") or "unknown",
                    "start": start,
                    "end": end,
                    "duration_ns": end - start,
                    "queue": row.get("Queue_Id") or row.get("queue_id"),
                    "grid": row.get("Grid_Size") or row.get("grid_size") or "x".join(row.get(f"Grid_Size_{axis}", "?") for axis in "XYZ"),
                    "workgroup": row.get("Workgroup_Size") or row.get("workgroup_size") or "x".join(row.get(f"Workgroup_Size_{axis}", "?") for axis in "XYZ"),
                    "vgpr": row.get("vgpr_count") or row.get("VGPR_Count"),
                    "sgpr": row.get("sgpr_count") or row.get("SGPR_Count"),
                    "lds": row.get("lds_size") or row.get("LDS_Size") or row.get("LDS_Block_Size"),
                    "scratch": row.get("scratch_size") or row.get("Scratch_Size"),
                }
            )
    rows.sort(key=lambda r: r["start"])
    return rows


def load_hip_rows(path: Path) -> list[dict]:
    rows: list[dict] = []
    if not path.exists():
        return rows
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            try:
                start = int(row["Start_Timestamp"])
                end = int(row["End_Timestamp"])
            except (KeyError, ValueError):
                continue
            name = row.get("Function") or row.get("Name") or row.get("ApiName") or "hip"
            rows.append(
                {
                    "name": name,
                    "start": start,
                    "end": end,
                    "duration_ns": end - start,
                }
            )
    return rows


def summarize(
    kernel_rows: list[dict],
    hip_rows: list[dict] | None = None,
    window_begin_ns: int | None = None,
    window_end_ns: int | None = None,
) -> dict:
    if not kernel_rows:
        return {
            "target": "gfx1151",
            "measured": True,
            "error": "no kernel rows",
        }

    t0 = window_begin_ns if window_begin_ns is not None else kernel_rows[0]["start"]
    t1 = window_end_ns if window_end_ns is not None else kernel_rows[-1]["end"]
    if t1 <= t0:
        raise ValueError(f"invalid trace window: {t0}..{t1}")
    wall_ns = t1 - t0
    total_kernel_ns = sum(r["duration_ns"] for r in kernel_rows)

    # Launch gaps: idle time between consecutive kernel ends/starts on timeline
    # (conservative single-queue approximation using global sort).
    gaps = []
    if kernel_rows[0]["start"] > t0:
        gaps.append(kernel_rows[0]["start"] - t0)
    prev_end = kernel_rows[0]["end"]
    for r in kernel_rows[1:]:
        gap = r["start"] - prev_end
        if gap > 0:
            gaps.append(gap)
        prev_end = max(prev_end, r["end"])
    if t1 > prev_end:
        gaps.append(t1 - prev_end)
    total_gap_ns = sum(gaps)

    by_name: dict[str, list[int]] = defaultdict(list)
    by_family: dict[str, list[int]] = defaultdict(list)
    meta_by_name: dict[str, dict] = {}
    for r in kernel_rows:
        by_name[r["name"]].append(r["duration_ns"])
        fam = classify(r["name"])
        by_family[fam].append(r["duration_ns"])
        if r["name"] not in meta_by_name:
            meta_by_name[r["name"]] = {
                "vgpr": r["vgpr"],
                "sgpr": r["sgpr"],
                "lds": r["lds"],
                "scratch": r["scratch"],
                "grid": r["grid"],
                "workgroup": r["workgroup"],
                "family": fam,
            }

    def pack(groups: dict[str, list[int]], key_label: str) -> list[dict]:
        items = []
        for key, durs in groups.items():
            total = sum(durs)
            items.append(
                {
                    key_label: short_name(key) if key_label == "kernel" else key,
                    "kernel_full": key if key_label == "kernel" else None,
                    "invocations": len(durs),
                    "total_gpu_us": total / 1000.0,
                    "mean_gpu_us": statistics.fmean(durs) / 1000.0,
                    "median_gpu_us": statistics.median(durs) / 1000.0,
                    "min_gpu_us": min(durs) / 1000.0,
                    "max_gpu_us": max(durs) / 1000.0,
                    "pct_of_kernel_time": 100.0 * total / total_kernel_ns,
                    "pct_of_trace_wall": 100.0 * total / wall_ns,
                    **(
                        {
                            k: meta_by_name.get(key, {}).get(k)
                            for k in ("family", "vgpr", "sgpr", "lds", "scratch", "grid", "workgroup")
                        }
                        if key_label == "kernel"
                        else {}
                    ),
                }
            )
        items.sort(key=lambda x: x["total_gpu_us"], reverse=True)
        # drop bulky full name from family rows
        if key_label != "kernel":
            for it in items:
                it.pop("kernel_full", None)
        return items

    kernels_ranked = pack(by_name, "kernel")
    # keep full name only in separate field already; trim None
    for it in kernels_ranked:
        if it.get("kernel_full") == it.get("kernel"):
            it.pop("kernel_full", None)

    hip_by_name: dict[str, list[int]] = defaultdict(list)
    for row in hip_rows or []:
        hip_by_name[row["name"]].append(row["duration_ns"])
    hip_ranked = [
        {
            "api": name,
            "invocations": len(durations),
            "total_cpu_us": sum(durations) / 1000.0,
            "mean_cpu_us": statistics.fmean(durations) / 1000.0,
            "max_cpu_us": max(durations) / 1000.0,
        }
        for name, durations in hip_by_name.items()
    ]
    hip_ranked.sort(key=lambda item: item["total_cpu_us"], reverse=True)

    hip_sync = []
    if hip_rows:
        sync_re = re.compile(r"hip(DeviceSynchronize|StreamSynchronize|EventSynchronize|Memcpy|Malloc|Free|HostAlloc)", re.I)
        for r in hip_rows:
            if sync_re.search(r["name"]):
                hip_sync.append(r)
    hip_sync_total_ns = sum(r["duration_ns"] for r in hip_sync)
    hip_sync_by_name: dict[str, list[int]] = defaultdict(list)
    for row in hip_sync:
        hip_sync_by_name[row["name"]].append(row["duration_ns"])
    hip_sync_ranked = [
        {
            "api": name,
            "invocations": len(durations),
            "total_cpu_us": sum(durations) / 1000.0,
            "mean_cpu_us": statistics.fmean(durations) / 1000.0,
            "max_cpu_us": max(durations) / 1000.0,
        }
        for name, durations in hip_sync_by_name.items()
    ]
    hip_sync_ranked.sort(key=lambda item: item["total_cpu_us"], reverse=True)

    return {
        "target": "gfx1151",
        "measured": True,
        "timing_scope": (
            "rocprofv3_client_monotonic_request_window"
            if window_begin_ns is not None
            else "rocprofv3_process_kernel_trace"
        ),
        "request_window_start_monotonic_ns": window_begin_ns,
        "request_window_end_monotonic_ns": window_end_ns,
        "kernel_launches": len(kernel_rows),
        "unique_kernels": len(by_name),
        "trace_wall_us": wall_ns / 1000.0,
        "total_kernel_gpu_us": total_kernel_ns / 1000.0,
        "sum_positive_launch_gaps_us": total_gap_ns / 1000.0,
        "launch_gap_count": len(gaps),
        "mean_launch_gap_us": (statistics.fmean(gaps) / 1000.0) if gaps else 0.0,
        "median_launch_gap_us": (statistics.median(gaps) / 1000.0) if gaps else 0.0,
        "p90_launch_gap_us": (statistics.quantiles(gaps, n=10)[8] / 1000.0) if len(gaps) >= 10 else None,
        "kernel_occupancy_of_wall_pct": 100.0 * total_kernel_ns / wall_ns,
        "gap_occupancy_of_wall_pct": 100.0 * total_gap_ns / wall_ns,
        "hip_sync_or_memcpy_calls": len(hip_sync),
        "hip_sync_or_memcpy_total_us": hip_sync_total_ns / 1000.0,
        "hip_apis_ranked_by_total_cpu_us": hip_ranked,
        "hip_sync_or_memcpy_ranked_by_total_cpu_us": hip_sync_ranked,
        "families_ranked_by_total_gpu_us": pack(by_family, "family"),
        "kernels_ranked_by_total_gpu_us": kernels_ranked[:80],
        "top20_kernels": kernels_ranked[:20],
    }


def find_trace(root: Path, suffix: str) -> Path | None:
    hits = list(root.rglob(f"*{suffix}"))
    return hits[0] if hits else None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("root", type=Path, help="rocprof output directory for one scenario")
    ap.add_argument("--out", type=Path, default=None)
    ap.add_argument(
        "--window-json",
        type=Path,
        default=None,
        help="request JSON containing host_request_*_monotonic_ns boundaries",
    )
    args = ap.parse_args()

    kpath = find_trace(args.root, "_kernel_trace.csv")
    if kpath is None:
        # sometimes named differently
        hits = list(args.root.rglob("*kernel*.csv"))
        kpath = hits[0] if hits else None
    if kpath is None:
        raise SystemExit(f"no kernel trace csv under {args.root}")

    hpath = find_trace(args.root, "_hip_api_trace.csv")
    if hpath is None:
        hits = list(args.root.rglob("*hip*trace*.csv"))
        hpath = hits[0] if hits else None

    kernels = load_kernel_rows(kpath)
    hips = load_hip_rows(hpath) if hpath else []
    window_path = args.window_json
    if window_path is None and (args.root / "request.json").is_file():
        window_path = args.root / "request.json"
    window_begin_ns = window_end_ns = None
    if window_path is not None:
        request = json.loads(window_path.read_text())
        window_begin_ns = request.get("host_request_start_monotonic_ns")
        window_end_ns = request.get("host_request_end_monotonic_ns")
        if (window_begin_ns is None) != (window_end_ns is None):
            raise ValueError(f"incomplete monotonic request window in {window_path}")
        if window_begin_ns is not None:
            window_begin_ns = int(window_begin_ns)
            window_end_ns = int(window_end_ns)
            kernels = [
                row
                for row in kernels
                if window_begin_ns <= row["start"] and row["end"] <= window_end_ns
            ]
            hips = [
                row
                for row in hips
                if window_begin_ns <= row["start"] and row["end"] <= window_end_ns
            ]
    report = summarize(kernels, hips, window_begin_ns, window_end_ns)
    report["request_window_source"] = str(window_path) if window_begin_ns is not None else None
    report["source_kernel_trace"] = str(kpath)
    report["source_hip_trace"] = str(hpath) if hpath else None
    report["scenario_dir"] = str(args.root)

    text = json.dumps(report, indent=2) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text)
    print(text)


if __name__ == "__main__":
    main()
