#!/usr/bin/env bash
set -euo pipefail

# Isolated gfx950 counter loop for the exact Qwen3.6 dFlash verification
# argmax, logits=[16,248320] FP32. Each metric gets its own pass because the
# gfx950 counter blocks cannot necessarily be scheduled together. Counter
# timings are intrusive and must not be used as latency measurements.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${REPO_DIR:-$(cd "${script_dir}/../.." && pwd)}
campaign_root=${CAMPAIGN_ROOT:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z}
profile_id=${PROFILE_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
output_dir=${OUTPUT_DIR:-"${campaign_root}/profiles/rocprof/isolated_argmax_f32_${profile_id}"}
build_dir=${BUILD_DIR:-"${repo_dir}/build/gfx950-qwen36-argmax-f32"}
rocprofv3=${ROCPROFV3:-/opt/rocm/bin/rocprofv3}
gpu=${GPU:-0}
kernel_regex='qwen36_argmax_f32_(stage1|stage2)_gfx950'
harness=${build_dir}/qwen36_argmax_f32_gfx950
hsaco=${build_dir}/qwen36_argmax_f32_gfx950.hsaco
counters=(
  SQ_WAVES
  SQ_INSTS_VALU
  SQ_INSTS_VMEM
  SQ_INSTS_LDS
  TCC_READ_SECTORS_sum
  TCC_WRITE_SECTORS_sum
  TCC_HIT_sum
  TCC_MISS_sum
  OccupancyPercent
  LDSBankConflict
)

if [[ ! -x "$rocprofv3" ]]; then
  echo "missing rocprofv3: $rocprofv3" >&2
  exit 2
fi
if docker ps --format '{{.Names}} {{.Status}}' |
  grep -q '^netra-qwen36-.* Up '; then
  echo "a Qwen serving container is active; refusing concurrent profiling" >&2
  exit 2
fi
rocminfo_text=$(rocminfo 2>/dev/null)
if ! grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"; then
  echo "gfx950 was not found by rocminfo" >&2
  exit 2
fi

"${repo_dir}/tools/build/build_gfx950_qwen36_argmax_f32.sh" \
  "${repo_dir}" "${build_dir}"
mkdir -p "$output_dir"

start_ns=$(date +%s%N)
for counter in "${counters[@]}"; do
  pass_dir=${output_dir}/${counter}
  mkdir -p "$pass_dir"
  HIP_VISIBLE_DEVICES=$gpu "$rocprofv3" \
    --pmc "$counter" \
    --kernel-include-regex "$kernel_regex" \
    --output-format csv json \
    --output-file "argmax_f32_${counter}" \
    --output-directory "$pass_dir" \
    -- "$harness" "$hsaco"
done
done_ns=$(date +%s%N)

python3 - "$output_dir" "$start_ns" "$done_ns" <<'PY'
import csv
import json
import pathlib
import statistics
import sys

output = pathlib.Path(sys.argv[1])
start_ns = int(sys.argv[2])
done_ns = int(sys.argv[3])
collections = sorted(str(path) for path in output.rglob("*_counter_collection.csv"))
by_kernel = {}
for collection in collections:
    with open(collection, newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        raise RuntimeError(f"empty counter collection: {collection}")
    for row in rows:
        kernel = row["Kernel_Name"]
        counter = row["Counter_Name"]
        entry = by_kernel.setdefault(
            kernel,
            {
                "resources": set(),
                "counters": {},
            },
        )
        entry["resources"].add(
            (
                int(row["VGPR_Count"]),
                int(row["Accum_VGPR_Count"]),
                int(row["SGPR_Count"]),
                int(row["LDS_Block_Size"]),
                int(row["Scratch_Size"]),
                int(row["Grid_Size"]),
                int(row["Workgroup_Size"]),
            )
        )
        entry["counters"].setdefault(counter, []).append(
            float(row["Counter_Value"])
        )

summary = {}
for kernel, entry in sorted(by_kernel.items()):
    if len(entry["resources"]) != 1:
        raise RuntimeError(
            f"inconsistent launch resources for {kernel}: "
            f"{sorted(entry['resources'])}"
        )
    (
        vgprs,
        agprs,
        sgprs,
        lds_bytes,
        scratch_bytes,
        grid_threads,
        workgroup_threads,
    ) = next(iter(entry["resources"]))
    summary[kernel] = {
        "resources": {
            "vgpr_count_profiler": vgprs,
            "agpr_count_profiler": agprs,
            "sgpr_count_profiler": sgprs,
            "lds_bytes": lds_bytes,
            "scratch_bytes": scratch_bytes,
            "grid_threads": grid_threads,
            "workgroup_threads": workgroup_threads,
            "wavefront_size": 64,
        },
        "counters": {
            name: {
                "dispatches": len(values),
                "minimum": min(values),
                "median": statistics.median(values),
                "mean": statistics.fmean(values),
                "maximum": max(values),
            }
            for name, values in sorted(entry["counters"].items())
        },
    }

payload = {
    "measurement_status": "profiler-instrumented",
    "timing_policy": (
        "counter collection is intrusive; use HIP events or serving traces "
        "for latency"
    ),
    "counter_collection_files": collections,
    "elapsed_seconds": (done_ns - start_ns) / 1e9,
    "kernels": summary,
}
(output / "counter_summary.json").write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n"
)
print(f"output_dir={output}")
print(f"kernel_count={len(summary)}")
print(f"counter_passes={len(collections)}")
print(f"elapsed_seconds={(done_ns - start_ns) / 1e9:.6f}")
PY
