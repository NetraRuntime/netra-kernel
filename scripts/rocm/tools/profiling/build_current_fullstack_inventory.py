#!/usr/bin/env python3
"""Build the current measured gfx1151 Qwen3.6 full-stack inventory."""
from __future__ import annotations

import argparse
import collections
import csv
import json
import re
import statistics
from pathlib import Path

EAGER = [
    ("short-prefill", "current-baf85e8-short-prefill-20260731"),
    ("prefill-210", "current-baf85e8-prefill-210-20260731"),
    ("prefill-8192", "current-gdn-two-wave-windowed-8192-20260731"),
    ("prefill-32768", "runtime-refactor-new-windowed-32768p1-seed20260730"),
    ("decode-m1-32-output", "current-baf85e8-decode-m1-20260731"),
    ("serving-210-in-128-out", "current-baf85e8-serving-210p128-20260731"),
]
GRAPHS = [
    ("full-graph-b1", "runtime-refactor-new-fullgraph-b1-210-plus8-20260730"),
    ("full-graph-m12", "runtime-refactor-new-fullgraph-b12-210-plus8-20260730"),
]
SYNC_RE = re.compile(r"hip(DeviceSynchronize|StreamSynchronize|EventSynchronize|Memcpy|Malloc|Free|HostAlloc)", re.I)
FAMILY_RULES = [
    ("standard_attention", re.compile(r"attention|attn|paged|flash", re.I)),
    ("gdn_output", re.compile(r"chunk_fwd_kernel_o|gdn_chunk_o", re.I)),
    ("gdn_state_scan", re.compile(r"gated_delta|kkt|recompute_w_u|recurrent|chunk_delta|wy_fast", re.I)),
    ("mxfp4_dense", re.compile(r"mxfp4.*linear", re.I)),
    ("mxfp4_moe", re.compile(r"mxfp4.*(?:_gate|_up(?:_|$)|_down|silu)", re.I)),
    ("moe_pack_reduce", re.compile(r"expert_(activation_pack|weighted_reduce)", re.I)),
    ("blas_projection", re.compile(r"^Cijk_|rocblas|gemm", re.I)),
    ("normalization", re.compile(r"norm|meanops|rsqrt|pow_tensor", re.I)),
    ("routing", re.compile(r"topk|router|moe_align|sorting|prefix_sum", re.I)),
    ("rope_kv", re.compile(r"rope|mrope|rotary|kv_store", re.I)),
    ("copy_elementwise", re.compile(r"copy|fill|elementwise|memcpy|scatter|gather|index", re.I)),
    ("short_conv", re.compile(r"conv1d|causal_conv", re.I)),
    ("lm_head_sampling", re.compile(r"lm_head|sampling|softmax|multinomial|top_p|top_k", re.I)),
]


def load(path: Path) -> dict:
    return json.loads(path.read_text())


def one(root: Path, pattern: str) -> Path:
    paths = sorted(root.glob(pattern))
    if len(paths) != 1:
        raise RuntimeError(f"expected one {pattern} below {root}, found {len(paths)}")
    return paths[0]


def family(name: str) -> str:
    for label, pattern in FAMILY_RULES:
        if pattern.search(name):
            return label
    return "other"


def csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def kernel_window(trace_dir: Path) -> tuple[int, int]:
    rows = csv_rows(one(trace_dir, "*kernel_trace.csv"))
    return (
        min(int(row["Start_Timestamp"]) for row in rows),
        max(int(row["End_Timestamp"]) for row in rows),
    )


def api_window(trace_dir: Path, begin: int, end: int) -> dict:
    grouped: dict[str, list[float]] = collections.defaultdict(list)
    for row in csv_rows(one(trace_dir, "*hip_api_trace.csv")):
        start = int(row["Start_Timestamp"])
        if begin <= start <= end:
            grouped[row["Function"]].append(
                (int(row["End_Timestamp"]) - start) / 1000.0
            )
    ranked = []
    for name, values in grouped.items():
        ranked.append({
            "api": name,
            "invocations": len(values),
            "total_cpu_us": sum(values),
            "mean_cpu_us": statistics.mean(values),
            "median_cpu_us": statistics.median(values),
            "p90_cpu_us": sorted(values)[min(len(values) - 1, int(0.9 * len(values)))],
            "max_cpu_us": max(values),
        })
    ranked.sort(key=lambda item: item["total_cpu_us"], reverse=True)
    sync = [item for item in ranked if SYNC_RE.search(item["api"])]
    return {
        "all_ranked": ranked,
        "sync_allocation_copy_ranked": sync,
        "sync_allocation_copy_calls": sum(item["invocations"] for item in sync),
        "sync_allocation_copy_total_cpu_us": sum(item["total_cpu_us"] for item in sync),
    }


def allocation_window(trace_dir: Path, begin: int, end: int) -> dict:
    paths = sorted(trace_dir.glob("*memory_allocation_trace.csv"))
    if not paths:
        return {"status": "trace_not_emitted", "allocations": 0, "frees": 0, "allocated_bytes": 0}
    allocations = frees = allocated_bytes = 0
    total_cpu_us = 0.0
    for row in csv_rows(paths[0]):
        start = int(row["Start_Timestamp"])
        if not begin <= start <= end:
            continue
        operation = row["Operation"]
        if operation == "MEMORY_ALLOCATION_ALLOCATE":
            allocations += 1
            allocated_bytes += int(row["Allocation_Size"])
        elif operation == "MEMORY_ALLOCATION_FREE":
            frees += 1
        total_cpu_us += (int(row["End_Timestamp"]) - start) / 1000.0
    return {
        "status": "measured_request_kernel_window",
        "allocations": allocations,
        "frees": frees,
        "allocated_bytes": allocated_bytes,
        "total_cpu_us": total_cpu_us,
    }


def eager_case(repo: Path, label: str, directory: str) -> dict:
    root = repo / "results/profiles/gfx1151" / directory
    request = load(root / "request.json")
    trace = load(root / "summary.json")
    begin, end = kernel_window(root)
    kernels = []
    for item in trace["kernels_ranked_by_total_gpu_us"]:
        entry = dict(item)
        full = entry.get("kernel_full", entry["kernel"])
        entry["family_current_inventory"] = family(full)
        entry["pct_of_host_e2e"] = entry["total_gpu_us"] / 1000.0 / request["host_e2e_ms"] * 100.0
        entry["hardware_counter_status"] = "not_collected_in_request_trace"
        entry["bytes_read_kib"] = None
        entry["bytes_written_kib"] = None
        entry["occupancy_percent"] = None
        entry["wave_count"] = None
        entry["l2_hit_percent"] = None
        entry["wait_dependency_stalls"] = "metric_not_exposed_on_gfx1151"
        kernels.append(entry)
    return {
        "target": "gfx1151",
        "measurement_status": "measured",
        "label": label,
        "source": directory,
        "input_tokens": request["input_tokens_requested"],
        "output_tokens": request["output_tokens_requested"],
        "cached_tokens": request["cached_tokens"],
        "graph_mode": request["graph_mode"],
        "dflash_mode": request["dflash_mode"],
        "host_e2e_ms": request["host_e2e_ms"],
        "ttft_ms": request.get("host_ttft_ms_measured"),
        "ttft_status": "measured" if request.get("host_ttft_ms_measured") is not None else "not_measured_nonstreaming",
        "peak_vram_bytes": request["peak_vram_bytes_sysfs_measured"],
        "trace": {key: trace[key] for key in (
            "kernel_launches", "unique_kernels", "trace_wall_us", "total_kernel_gpu_us",
            "sum_positive_launch_gaps_us", "launch_gap_count", "mean_launch_gap_us",
            "median_launch_gap_us", "p90_launch_gap_us", "kernel_occupancy_of_wall_pct",
            "gap_occupancy_of_wall_pct")},
        "request_window_hip_api": api_window(root, begin, end),
        "request_window_allocations": allocation_window(root, begin, end),
        "kernels_ranked_by_total_request_cost": kernels,
    }


def graph_window_api(trace_dir: Path) -> dict:
    rows = csv_rows(one(trace_dir, "*hip_api_trace.csv"))
    launches = [row for row in rows if row["Function"] == "hipGraphLaunch"]
    begin = min(int(row["Start_Timestamp"]) for row in launches)
    end = max(int(row["End_Timestamp"]) for row in launches)
    return api_window(trace_dir, begin, end)


def graph_case(repo: Path, label: str, directory: str) -> dict:
    root = repo / "results/profiles/gfx1151" / directory
    request = load(root / "request.json")
    replay = load(root / "graph-replay-summary.json")
    return {
        "target": "gfx1151",
        "measurement_status": "measured",
        "label": label,
        "source": directory,
        "request": request,
        "replay": replay,
        "replay_window_hip_api": graph_window_api(root),
    }


def counter_sources(repo: Path) -> list[dict]:
    paths = [
        "results/profiles/gfx1151/decode-synthetic-identical-counters-20260729/summary.json",
        "results/profiles/gfx1151/prefill-gate-dword-layout-counters-20260729/candidate-summary.json",
        "results/profiles/gfx1151/causal-conv1d-ordered-counters-hip72-20260729/summary.json",
        "results/profiles/gfx1151/expert-reduce-fp64-counters-hip72-20260729/summary.json",
        "results/profiles/gfx1151/recompute-w-u-ordered-counters-hip72-20260729/summary.json",
        "results/profiles/gfx1151/gdn-chunk-o-two-wave-counters-20260731/summary.json",
        "results/profiles/gfx1151/qkvzba-split-copy-counters-repro/summary.json",
        "results/profiles/gfx1151/extend-attention-group4-qpipe-kvbatch16-3x-20260730/candidate/summary.json",
    ]
    result = []
    for relative in paths:
        data = load(repo / relative)
        result.append({
            "source": relative,
            "input_scope": data.get("input_scope"),
            "direct_dependency_stall_counter": data.get("direct_dependency_stall_counter"),
            "kernels": data.get("kernels", []),
        })
    return result


def markdown(report: dict) -> str:
    lines = [
        "# Current gfx1151 full-stack bottleneck inventory — 2026-07-31", "",
        "All numeric results are **measured on gfx1151** unless explicitly marked unavailable. "
        "MXFP4 checkpoint weights are unchanged. Eager traces are independent, uncached, timed request-only windows. "
        "CPU API statistics below are filtered to the first-to-last request kernel window, excluding server startup and teardown.", "",
        "## Eager scenario overview", "",
        "| Scenario | Input/output | Host E2E ms | GPU ms | Gaps ms | Launches | Kernel occupancy | Alloc/free | Peak VRAM GiB |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for case in report["eager_scenarios"]:
        t = case["trace"]; a = case["request_window_allocations"]
        lines.append(
            f"| {case['label']} | {case['input_tokens']} / {case['output_tokens']} | {case['host_e2e_ms']:.3f} | "
            f"{t['total_kernel_gpu_us']/1000:.3f} | {t['sum_positive_launch_gaps_us']/1000:.3f} | "
            f"{t['kernel_launches']:,} | {t['kernel_occupancy_of_wall_pct']:.2f}% | "
            f"{a['allocations']} / {a['frees']} | {case['peak_vram_bytes']/2**30:.3f} |"
        )
    lines += ["", "## CPU/GPU orchestration in the request window", "",
              "HIP API durations are measured gfx1151 host-call durations. Synchronization durations overlap GPU execution and must not be added to GPU or host E2E time. "
              "The launch columns report both compiler/HIP launches and cached raw-module launches; allocation bytes are measured in the same request-kernel window.", "",
              "| Scenario | Dominant sync calls / total ms | hipLaunchKernel calls / ms | hipModuleLaunchKernel calls / ms | Blocking copies calls / ms | Allocations / KiB | Device queries |",
              "|---|---:|---:|---:|---:|---:|---:|"]
    for case in report["eager_scenarios"]:
        api = {item["api"]: item for item in case["request_window_hip_api"]["all_ranked"]}

        def calls_ms(name: str) -> tuple[int, float]:
            item = api.get(name)
            return (0, 0.0) if item is None else (item["invocations"], item["total_cpu_us"] / 1000.0)

        sync_calls, sync_ms = calls_ms("hipEventSynchronize")
        launch_calls, launch_ms = calls_ms("hipLaunchKernel")
        module_calls, module_ms = calls_ms("hipModuleLaunchKernel")
        copy_calls, copy_ms = calls_ms("hipMemcpyWithStream")
        device_queries = sum(api.get(name, {}).get("invocations", 0) for name in (
            "hipGetDevice", "hipSetDevice", "hipGetDevicePropertiesR0600"))
        alloc = case["request_window_allocations"]
        lines.append(
            f"| {case['label']} | {sync_calls:,} / {sync_ms:.3f} | "
            f"{launch_calls:,} / {launch_ms:.3f} | {module_calls:,} / {module_ms:.3f} | "
            f"{copy_calls:,} / {copy_ms:.3f} | {alloc['allocations']} / {alloc['allocated_bytes']/1024:.1f} | "
            f"{device_queries:,} |"
        )
    lines += ["", "## Per-scenario ranked kernels", ""]
    for case in report["eager_scenarios"]:
        lines += [f"### {case['label']} — gfx1151 measured", "",
                  "| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |",
                  "|---:|---|---|---:|---:|---:|---:|---:|---:|"]
        for rank, item in enumerate(case["kernels_ranked_by_total_request_cost"][:15], 1):
            name = item["kernel"].replace("|", "\\|")
            lines.append(
                f"| {rank} | `{name}` | {item['family_current_inventory']} | {item['invocations']} | "
                f"{item['mean_gpu_us']:.3f} | {item['total_gpu_us']/1000:.3f} | {item['pct_of_host_e2e']:.2f}% | "
                f"{item['vgpr']}/{item['sgpr']} | {item['lds']}/{item['scratch']} |"
            )
        lines.append("")
    lines += ["## Suite ranking", "",
              "This sum is a workload-suite prioritization, not a frequency-weighted production traffic estimate.", "",
              "| Rank | Kernel | Calls | Total ms | Scenarios |", "|---:|---|---:|---:|---:|"]
    for rank, item in enumerate(report["suite_kernels_ranked_by_total_gpu_cost"][:25], 1):
        lines.append(f"| {rank} | `{item['kernel'][:120]}` | {item['invocations']} | {item['total_gpu_us']/1000:.3f} | {len(item['scenarios'])} |")
    lines += ["", "## Full graph replay", "",
              "| Graph | Batch | Graph launches | Kernels/replay | Graph CPU us | GPU span ms | Summed GPU ms | Replay alloc/free/sync |",
              "|---|---:|---:|---:|---:|---:|---:|---:|"]
    for graph in report["graph_scenarios"]:
        r = graph["request"]; g = graph["replay"]; api = graph["replay_window_hip_api"]
        blocked = sum(x["invocations"] for x in api["sync_allocation_copy_ranked"] if x["api"] in ("hipMalloc", "hipFree", "hipDeviceSynchronize", "hipStreamSynchronize"))
        lines.append(
            f"| {graph['label']} | {r['batch_size']} | {g['graph_launches']} | {g['kernels_per_replay'][0]} | "
            f"{g['mean_hip_graph_launch_cpu_us']:.3f} | {g['median_graph_gpu_span_us']/1000:.3f} | "
            f"{g['mean_summed_kernel_gpu_us_per_replay']/1000:.3f} | {blocked} |"
        )
        lines += ["", f"Top {graph['label']} replay kernels:", "",
                  "| Rank | Kernel | Calls | Total ms | % graph GPU | VGPR/SGPR | LDS/scratch B |",
                  "|---:|---|---:|---:|---:|---:|---:|"]
        for rank, item in enumerate(g["kernels_ranked_by_total_graph_gpu_time"][:12], 1):
            lines.append(f"| {rank} | `{item['kernel'][:120]}` | {item['invocations']} | {item['total_gpu_us']/1000:.3f} | {item['pct_of_graph_kernel_time']:.2f}% | {item['vgpr']}/{item['sgpr']} | {item['lds_bytes']}/{item['scratch_bytes']} |")
        lines.append("")
    lines += ["## Hardware-counter coverage", "",
              "rocprofv3 counters were collected one metric per fresh process for selected hot raw kernels. "
              "The request traces do not contain counters. Direct dependency/wait-state stall percentage is unavailable in the exposed gfx1151 metric set and is not estimated. "
              "Compiler/Triton and rocBLAS kernels still need isolated counter passes.", "",
              "| Counter artifact | Kernel | Fetch KiB | Write KiB | Occupancy % | Waves | L2 hit % | Mem busy % |",
              "|---|---|---:|---:|---:|---:|---:|---:|"]
    for source in report["hardware_counter_sources"]:
        for kernel in source["kernels"]:
            c = kernel.get("counters", {})
            def metric(name):
                value = c.get(name)
                if isinstance(value, dict): return value.get("mean")
                return value
            vals = [metric(x) for x in ("FETCH_SIZE", "WRITE_SIZE", "OccupancyPercent", "Wavefronts", "L2CacheHit", "MemUnitBusy")]
            def fmt(value): return "unavailable" if value is None or not (0 <= value < 1e8) else f"{value:.3f}"
            # Exclude known corrupt occupancy samples outside the physical 0..100 range.
            if vals[2] is not None and not 0 <= vals[2] <= 100: vals[2] = None
            lines.append(f"| `{Path(source['source']).parent.name}` | `{kernel['kernel']}` | " + " | ".join(fmt(v) for v in vals) + " |")
    long = report["serving_32768_in_16384_out"]
    lines += ["", "## Long serving and coverage status", "",
              f"The existing exact 32,768-input/16,384-output result is **gfx1151 measured** but predates the current accepted stack: "
              f"{long['latency']:.4f} s total, {long['last_ttft']:.4f} s TTFT, {long['input_throughput']:.2f} input tok/s, "
              f"and {long['output_throughput']:.2f} output tok/s. A current-stack rerun is required and is not estimated.", "",
              "- Native full graph tiers M1 and M12 are measured above; M2/4/8/16 correctness exists, but per-tier profiler inventories remain pending.",
              "- Native `tc_piecewise` M64 correctness and construction are measured; piecewise profiler coverage for all requested tiers remains pending.",
              "- Actual speculative verify/dFlash remains unavailable because no compatible draft checkpoint or checkpoint `dflash_config` is installed. Non-speculative M12 is not labeled as verify.",
              "- LM-head/sampling and CPU routing are present in the complete JSON tables, but need focused counter and host-stack instrumentation where they do not rank in the top 15.",
              "- Every kernel row records unavailable counter fields as null rather than estimating bytes, occupancy, cache, waves, or dependency stalls.", "",
              "## Evidence-backed next targets", "",
              "1. Continue from the updated ranking after accepting the correctness-stable raw two-wave GDN chunk-output kernel; attention and MXFP4 dense remain ahead in the 8K request window.",
              "2. Specialize short/210-token MoE gate/up/down: they consume most GPU time at those tiers.",
              "3. Continue attention only with a materially different transaction/accumulator schedule; eighteen incremental ideas already have measured accept/reject evidence.",
              "4. Reduce M=1 graph/eager dense projection and launch cost; attention preparation is not a decode bottleneck.", ""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path("/root/netra-mxfp4-gfx1151"))
    parser.add_argument("--out-json", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    args = parser.parse_args()
    eager = [eager_case(args.repo, label, directory) for label, directory in EAGER]
    suite: dict[str, dict] = {}
    for case in eager:
        for item in case["kernels_ranked_by_total_request_cost"]:
            name = item.get("kernel_full", item["kernel"])
            record = suite.setdefault(name, {"kernel": name, "invocations": 0, "total_gpu_us": 0.0, "scenarios": []})
            record["invocations"] += item["invocations"]
            record["total_gpu_us"] += item["total_gpu_us"]
            record["scenarios"].append(case["label"])
    ranked = sorted(suite.values(), key=lambda item: item["total_gpu_us"], reverse=True)
    report = {
        "target": "gfx1151",
        "device": "AMD Ryzen AI Max+ PRO 395 / Radeon 8060S",
        "measurement_status": "measured except explicit unavailable fields",
        "checkpoint": "/root/models/qwen36-sgl-mxfp4",
        "quantized_weight_format": "MXFP4 unchanged",
        "current_commit": "baf85e8dfbc8f281a03eedf59cc1ca49eb525240",
        "eager_scenarios": eager,
        "suite_kernels_ranked_by_total_gpu_cost": ranked,
        "graph_scenarios": [graph_case(args.repo, label, directory) for label, directory in GRAPHS],
        "hardware_counter_sources": counter_sources(args.repo),
        "serving_32768_in_16384_out": {**load(args.repo / "results/sglang-32k-in-16k-out.json"), "target": "gfx1151", "measurement_status": "measured_historical_current_rerun_pending", "cached_tokens": 0, "graph_mode": "disabled", "dflash_mode": "disabled"},
        "unavailable": {
            "direct_dependency_stall_counter": "not exposed by available gfx1151 rocprofv3 metrics; not estimated",
            "actual_dflash": "no compatible draft checkpoint and no checkpoint dflash_config installed",
            "current_32768_in_16384_out": "pending rerun on accepted stack",
        },
    }
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_md.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    args.out_md.write_text(markdown(report))
    print(args.out_json)
    print(args.out_md)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
