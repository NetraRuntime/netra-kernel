#!/usr/bin/env bash
set -euo pipefail

# Isolated gfx950 counter loop for retained Qwen3.6 dense M=1 experiments.
# Every metric is collected in its own rocprofv3 pass because gfx950 hardware
# counter blocks are not all compatible in one pass.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${REPO_DIR:-$(cd "${script_dir}/../.." && pwd)}
campaign_root=${CAMPAIGN_ROOT:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z}
profile_id=${PROFILE_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
output_dir=${OUTPUT_DIR:-"${campaign_root}/profiles/rocprof/isolated_dense_m1_${profile_id}"}
capture_dir=${CAPTURE_DIR:-"${campaign_root}/kernel_experiments/qwen36_dense_out_m1_capture_20260730T053315Z/capture-v2"}
build_dir=${BUILD_DIR:-"${repo_dir}/build/gfx950-qwen36-dense-m1"}
rocprofv3=${ROCPROFV3:-/opt/rocm/bin/rocprofv3}
gpu=${GPU:-0}
target=${TARGET:-all}

harness_stem=qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
harness=${build_dir}/${harness_stem}_harness
counters=(
  SQ_WAVES
  SQ_INSTS_MFMA
  SQ_INSTS_LDS
  SQ_INSTS_VMEM
  TCC_READ_SECTORS_sum
  TCC_HIT_sum
  TCC_MISS_sum
  OccupancyPercent
  LDSBankConflict
)

if [[ "$target" != all && "$target" != one_wave &&
      "$target" != four_wave_lds ]]; then
  echo "TARGET must be all, one_wave, or four_wave_lds" >&2
  exit 2
fi
if [[ ! -x "$rocprofv3" ]]; then
  echo "missing rocprofv3: $rocprofv3" >&2
  exit 2
fi
if docker ps --format '{{.Names}}' | grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; refusing concurrent profiling" >&2
  exit 2
fi
rocminfo_text=$(rocminfo 2>/dev/null)
if ! grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"; then
  echo "gfx950 was not found by rocminfo" >&2
  exit 2
fi
test -f "${capture_dir}/manifest.json"

"${repo_dir}/tools/build/build_gfx950_qwen36_dense_m1.sh" \
  "${repo_dir}" "${build_dir}"
mkdir -p "$output_dir"

profile_variant() {
  local label=$1
  local stem=$2
  local grid=$3
  local threads=$4
  local counter
  for counter in "${counters[@]}"; do
    local pass_dir=${output_dir}/${label}/${counter}
    mkdir -p "$pass_dir"
    HIP_VISIBLE_DEVICES=$gpu "$rocprofv3" \
      --pmc "$counter" \
      --kernel-include-regex "$stem" \
      --output-format csv json \
      --output-file "${label}_${counter}" \
      --output-directory "$pass_dir" \
      -- "$harness" "${build_dir}/${stem}.hsaco" "$capture_dir" 1 \
      "$stem" "$grid" "$threads"
  done
}

start_ns=$(date +%s%N)
if [[ "$target" == all || "$target" == one_wave ]]; then
  profile_variant one_wave \
    qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950 128 64
fi
if [[ "$target" == all || "$target" == four_wave_lds ]]; then
  profile_variant four_wave_lds \
    qwen36_dense_m1_n2048_k4096_fp8_mfma_4wave_lds_gfx950 32 256
fi
done_ns=$(date +%s%N)

python3 - "$output_dir" "$start_ns" "$done_ns" <<'PY'
import json
import pathlib
import sys

output = pathlib.Path(sys.argv[1])
start_ns = int(sys.argv[2])
done_ns = int(sys.argv[3])
collections = sorted(str(path) for path in output.rglob("*_counter_collection.csv"))
payload = {
    "measurement_status": "profiler-instrumented",
    "timing_policy": "counter collection is intrusive; use HIP events for latency",
    "counter_collection_files": collections,
    "elapsed_seconds": (done_ns - start_ns) / 1e9,
}
(output / "manifest.json").write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n"
)
print(f"output_dir={output}")
print(f"counter_passes={len(collections)}")
print(f"elapsed_seconds={(done_ns - start_ns) / 1e9:.6f}")
PY
