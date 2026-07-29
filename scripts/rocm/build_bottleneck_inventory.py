#!/usr/bin/env python3
"""Build the measured gfx1151 full-stack bottleneck inventory."""
from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path

SCENARIO_ORDER = [
    "short-prefill", "prefill-210", "prefill-chunk-8192",
    "prefill-32768", "decode-m1", "serving-210-in-128-out",
]


def load(path: Path) -> dict:
    return json.loads(path.read_text())


def allocation_stats(path: Path) -> dict:
    count = total_bytes = total_ns = 0
    if not path.exists():
        return {"count": 0, "total_bytes": 0, "total_cpu_us": 0.0}
    with path.open(newline="") as handle:
        for row in csv.DictReader(handle):
            if row.get("Operation") != "MEMORY_ALLOCATION_ALLOCATE":
                continue
            count += 1
            total_bytes += int(row["Allocation_Size"])
            total_ns += int(row["End_Timestamp"]) - int(row["Start_Timestamp"])
    return {"count": count, "total_bytes": total_bytes, "total_cpu_us": total_ns / 1000}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trace-root", type=Path, required=True)
    parser.add_argument("--counter-summary", type=Path, required=True)
    parser.add_argument("--serving-json", type=Path, required=True)
    parser.add_argument("--out-json", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    args = parser.parse_args()

    scenarios = {}
    suite_kernel_cost = defaultdict(lambda: {"invocations": 0, "total_gpu_us": 0.0, "scenarios": []})
    for name in SCENARIO_ORDER:
        scenario_dir = args.trace_root / "scenarios" / name
        request = load(args.trace_root / "requests" / f"{name}.json")
        trace = load(scenario_dir / "summary.json")
        alloc = allocation_stats(scenario_dir / "trace_memory_allocation_trace.csv")
        host_ms = request["host_e2e_ms"]
        top = []
        for kernel in trace["kernels_ranked_by_total_gpu_us"]:
            item = dict(kernel)
            item["pct_of_host_e2e"] = item["total_gpu_us"] / 1000 / host_ms * 100
            top.append(item)
            key = item.get("kernel_full", item["kernel"])
            suite_kernel_cost[key]["invocations"] += item["invocations"]
            suite_kernel_cost[key]["total_gpu_us"] += item["total_gpu_us"]
            suite_kernel_cost[key]["scenarios"].append(name)
        scenarios[name] = {
            "target": "gfx1151",
            "measurement_status": "measured",
            "request": request,
            "trace": {k: trace[k] for k in (
                "kernel_launches", "unique_kernels", "trace_wall_us",
                "total_kernel_gpu_us", "sum_positive_launch_gaps_us",
                "launch_gap_count", "hip_sync_or_memcpy_calls",
                "hip_sync_or_memcpy_total_us",
                "families_ranked_by_total_gpu_us",
                "hip_apis_ranked_by_total_cpu_us",
                "hip_sync_or_memcpy_ranked_by_total_cpu_us",
            )},
            "allocation_trace": alloc,
            "kernels_ranked_by_total_request_cost": top,
        }

    suite_ranked = [
        {"kernel": name, **value}
        for name, value in suite_kernel_cost.items()
    ]
    suite_ranked.sort(key=lambda item: item["total_gpu_us"], reverse=True)
    serving = load(args.serving_json)
    counters = load(args.counter_summary)
    report = {
        "target": "gfx1151",
        "device": "AMD Ryzen AI Max+ PRO 395 / Radeon 8060S",
        "measurement_status": "measured except fields explicitly marked unavailable",
        "checkpoint": "/root/models/qwen36-sgl-mxfp4 (MXFP4 weights retained)",
        "graph_mode": "disabled for trace inventory",
        "dflash_mode": "disabled for trace inventory",
        "profiler": "rocprofv3 1.3.0 / ROCm 7.13 runtime trace; ROCm 7.2.1 hardware counters",
        "trace_clock_alignment_error_ns": load(args.trace_root / "scenario-slicing.json")["alignment_disagreement_ns"],
        "profiler_overhead_warning": "host E2E values in scenarios were measured while runtime tracing was active",
        "scenarios": scenarios,
        "suite_kernels_ranked_by_total_gpu_cost": suite_ranked,
        "decode_raw_asm_hardware_counters": counters,
        "serving_32768_input_16384_output": {
            "target": "gfx1151", "measurement_status": "measured",
            "cached_tokens": 0, "graph_mode": "disabled", "dflash_mode": "disabled",
            **serving,
        },
        "unavailable_or_pending": {
            "dflash": "Unavailable: checkpoint has no dflash_config and no DFlash draft checkpoint is installed.",
            "speculative_verify_m12": "Pending because no compatible draft/DFlash checkpoint is installed.",
            "piecewise_graph": "Native SGLang source disables tc_piecewise on HIP; no measured run yet.",
            "graph_enabled": "Separate validation run in progress; excluded from this eager inventory.",
            "direct_dependency_stalls": "No direct gfx1151 metric exposed by the available rocprofv3 set; not estimated.",
        },
    }
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, indent=2) + "\n")

    lines = [
        "# gfx1151 full-stack bottleneck inventory (2026-07-29)", "",
        "All numbers below are **measured on gfx1151** unless a row explicitly says unavailable or pending. "
        "The six scenario host timings include rocprofv3 tracing overhead; GPU times are rocprofv3 dispatch durations. "
        "Synchronization API time overlaps queued GPU execution and must not be added to GPU time.", "",
        "## Scenario overview", "",
        "| Scenario | Exact input/output | Host E2E ms | GPU kernel ms | Positive gaps ms | Launches | Blocking copy/sync ms | Alloc count / GiB | Peak VRAM GiB |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for name in SCENARIO_ORDER:
        s = scenarios[name]; r = s["request"]; t = s["trace"]; a = s["allocation_trace"]
        lines.append(
            f"| {name} | {r['input_tokens_requested']} / {r['output_tokens_requested']} | "
            f"{r['host_e2e_ms']:.3f} | {t['total_kernel_gpu_us']/1000:.3f} | "
            f"{t['sum_positive_launch_gaps_us']/1000:.3f} | {t['kernel_launches']} | "
            f"{t['hip_sync_or_memcpy_total_us']/1000:.3f} | {a['count']} / {a['total_bytes']/2**30:.3f} | "
            f"{r['peak_vram_bytes_sysfs_measured']/2**30:.3f} |"
        )

    lines += ["", "## Ranked kernels by total request cost", ""]
    for name in SCENARIO_ORDER:
        s = scenarios[name]
        lines += [f"### {name} — gfx1151 measured", "",
                  "| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |",
                  "|---:|---|---|---:|---:|---:|---:|---:|---:|"]
        for rank, k in enumerate(s["kernels_ranked_by_total_request_cost"][:12], 1):
            kernel = k["kernel"].replace("|", "\\|")
            lines.append(
                f"| {rank} | `{kernel}` | {k['family']} | {k['invocations']} | {k['mean_gpu_us']:.3f} | "
                f"{k['total_gpu_us']/1000:.3f} | {k['pct_of_host_e2e']:.2f}% | {k['vgpr']} / {k['sgpr']} | "
                f"{k['lds']} / {k['scratch']} |"
            )
        lines.append("")

    lines += ["## CPU/GPU orchestration", "",
              "`hipMemcpyWithStream` is a blocking host API in every measured scenario. The 32K request issued 402 calls totaling "
              f"{scenarios['prefill-32768']['trace']['hip_sync_or_memcpy_ranked_by_total_cpu_us'][0]['total_cpu_us']/1000:.3f} ms of CPU call duration. "
              "The integration contains `group_index[-1].item()` in grouped prefill, a source-derived device-to-host synchronization point, "
              "and allocates routing/group tensors dynamically.", "",
              "| Scenario | Top HIP API | Calls | Total CPU ms | Mean us |",
              "|---|---|---:|---:|---:|"]
    for name in SCENARIO_ORDER:
        api = scenarios[name]["trace"]["hip_apis_ranked_by_total_cpu_us"][0]
        lines.append(f"| {name} | `{api['api']}` | {api['invocations']} | {api['total_cpu_us']/1000:.3f} | {api['mean_cpu_us']:.3f} |")

    lines += ["", "## Raw-ASM decode hardware counters", "",
              "These are gfx1151 **measured** rocprofv3 counters with exact Qwen3.6 decode tensor shapes and synthetic zero data. "
              "One counter was collected per process launch because combined groups exceed hardware collection capacity.", "",
              "| Kernel | Waves | Occupancy % | Active-CU waves | Fetch KiB | Write KiB | L2 hit % | Mem busy % | VGPR / SGPR |",
              "|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for kernel in counters["kernels"]:
        c = kernel["counters"]
        mean = lambda key: c[key]["mean"]
        lines.append(
            f"| `{kernel['kernel']}` | {mean('Wavefronts'):.0f} | {mean('OccupancyPercent'):.3f} | "
            f"{mean('MeanOccupancyPerActiveCU'):.3f} | {mean('FETCH_SIZE'):.3f} | {mean('WRITE_SIZE'):.3f} | "
            f"{mean('L2CacheHit'):.3f} | {mean('MemUnitBusy'):.3f} | {kernel['vgpr']} / {kernel['sgpr']} |"
        )

    lines += ["", "## Full serving baseline", "",
              "| Target | Input/output | Cached | TTFT s | Input tok/s | Output tok/s | Total latency s | Graph | dFlash | Status |",
              "|---|---:|---:|---:|---:|---:|---:|---|---|---|",
              f"| gfx1151 | {serving['input_len']} / {serving['output_len']} | 0 | {serving['last_ttft']:.4f} | "
              f"{serving['input_throughput']:.2f} | {serving['output_throughput']:.2f} | {serving['latency']:.4f} | disabled | disabled | measured |", "",
              "## Evidence-backed priorities", "",
              "1. Remove grouped-prefill host reads and dynamic allocation. The 32K trace measures 402 blocking copies and 34.094 s inside `hipMemcpyWithStream`.",
              "2. Optimize the top 32K GDN kernels first: `_fwd_kernel`, `chunk_fwd_kernel_o`, and `recompute_w_u` collectively dominate several seconds and use 256 VGPR with scratch in the first two cases.",
              "3. Continue raw gfx1151 ASM work on MXFP4 gate/linear/down. Decode linear alone is 34.05% of decode GPU time; the raw gate/down counter passes are 85.8–90.3% memory-unit busy with low measured L2 hit rate.",
              "4. Reduce decode launch fragmentation: the 1+32 trace contains 59,984 launches; 210+128 contains 235,410 launches.", "",
              "## Negative results and missing coverage", "",
              "- ABI-mismatched ROCm 7.2.1 live attach emitted no trace and wedged the server; ABI-matched ROCm 7.13 live attach SIGSEGVed the scheduler. Launch-from-start delayed collection is the working method.",
              "- ROCm 7.13 wheel counter collection fails to load the AQL profiling API. ROCm 7.2.1 native harness collection succeeds and is used above.",
              "- Direct dependency-stall counters were not exposed for gfx1151 by the available metric set; no stall percentage is estimated.",
              "- Speculative M=12 and actual dFlash shapes are unavailable because the supplied checkpoint has no `dflash_config` and no compatible draft checkpoint exists on the system.",
              "- SGLang's pinned native `tc_piecewise` compatibility rules disable it on HIP. Full decode-graph validation is tracked separately.", "",
              "The raw JSON companion contains the top 80 kernels per scenario, full family tables, HIP API tables, allocation totals, and all collected hardware counters.", ""]
    args.out_md.parent.mkdir(parents=True, exist_ok=True)
    args.out_md.write_text("\n".join(lines))


if __name__ == "__main__":
    main()
