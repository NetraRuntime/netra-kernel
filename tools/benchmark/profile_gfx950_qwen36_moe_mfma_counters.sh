#!/usr/bin/env bash
set -euo pipefail

# Fast, isolated gfx950 counter loop for the accepted Qwen3.6 M=1 MoE MFMA
# kernels. Each metric gets its own rocprofv3 pass so incompatible hardware
# counter blocks cannot silently drop a requested measurement.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${REPO_DIR:-$(cd "${script_dir}/../.." && pwd)}
campaign_root=${CAMPAIGN_ROOT:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z}
profile_id=${PROFILE_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
output_dir=${OUTPUT_DIR:-"${campaign_root}/profiles/rocprof/isolated_raw_mfma_${profile_id}"}
rocprofv3=${ROCPROFV3:-/opt/rocm/bin/rocprofv3}
gpu=${GPU:-0}
iterations=${ITERATIONS:-1}
target=${TARGET:-all}
basic_counters=${BASIC_COUNTERS:-1}
xcd_counters=${XCD_COUNTERS:-1}
xcd_counter_yaml=${XCD_COUNTER_YAML:-/data/netra/repos/netra-server/scripts/rocm/mi350x/gfx950_xcd_counters.yaml}

gate_build=${repo_dir}/build/gfx950-qwen36-moe-gate-up-mfma
gate_stem=qwen36_moe_gate_up_fp8_mfma_gfx950
gate_capture=${GATE_CAPTURE:-"${campaign_root}/kernel_experiments/qwen36_moe_stage1_fp8_gfx950_20260730T020100Z/capture"}
down_build=${DOWN_BUILD:-${repo_dir}/build/gfx950-qwen36-moe-down-reduce-mfma}
down_stem=${DOWN_STEM:-qwen36_moe_down_reduce_fp8_mfma_gfx950}
down_block_x=${DOWN_BLOCK_X:-64}
down_capture=${DOWN_CAPTURE:-"${campaign_root}/kernel_experiments/qwen36_moe_down_reduce_fp8_gfx950_20260730T010200Z/capture"}

counters=(
  SQ_INSTS_MFMA
  SQ_INSTS_VALU_MFMA_F8
  SQ_INSTS_VALU_MFMA_MOPS_F8
  SQ_VALU_MFMA_BUSY_CYCLES
  SQ_VALU_MFMA_COEXEC_CYCLES
  SQ_WAVES
  SQ_WAIT_ANY
  SQ_INSTS_VALU
  SQ_INSTS_SALU
  SQ_INSTS_SMEM
  SQ_INSTS_VMEM
  SQ_INSTS_LDS
  OccupancyPercent
  VALUUtilization
  SALUBusy
  LDSBankConflict
  FetchSize
  WriteSize
  TCC_HIT_sum
  TCC_MISS_sum
  TCC_READ_SECTORS_sum
  TCC_WRITE_SECTORS_sum
  TA_BUFFER_WAVEFRONTS_sum
  TA_BUFFER_COALESCEABLE_WAVEFRONTS_sum
  TA_FLAT_WAVEFRONTS_sum
  TA_FLAT_COALESCEABLE_WAVEFRONTS_sum
  TA_FLAT_READ_WAVEFRONTS_sum
  TA_FLAT_WRITE_WAVEFRONTS_sum
)
xcd_families=(
  GRBM_GUI_ACTIVE
  SQ_WAVES
  SQ_MFMA_F8
  TCC_READ_SECTORS
  TCC_WRITE_SECTORS
)

if [[ ! -x "$rocprofv3" ]]; then
  echo "missing rocprofv3: $rocprofv3" >&2
  exit 2
fi
if docker ps --format '{{.Names}}' 2>/dev/null |
   grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; refusing concurrent profiling" >&2
  exit 2
fi
rocminfo_text=$(/opt/rocm/bin/rocminfo 2>/dev/null)
if ! grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"; then
  echo "gfx950 was not found by rocminfo" >&2
  exit 2
fi
if [[ "$target" != all && "$target" != gate_up &&
      "$target" != down_reduce ]]; then
  echo "TARGET must be all, gate_up, or down_reduce" >&2
  exit 2
fi
if [[ "$basic_counters" != 0 && "$basic_counters" != 1 ]]; then
  echo "BASIC_COUNTERS must be 0 or 1" >&2
  exit 2
fi
if [[ "$xcd_counters" != 0 && "$xcd_counters" != 1 ]]; then
  echo "XCD_COUNTERS must be 0 or 1" >&2
  exit 2
fi
if [[ "$xcd_counters" == 1 && ! -f "$xcd_counter_yaml" ]]; then
  echo "missing XCD counter definitions: $xcd_counter_yaml" >&2
  exit 2
fi

mkdir -p "$output_dir"

profile_target() {
  local label=$1
  local symbol=$2
  local harness=$3
  local hsaco=$4
  local capture=$5
  shift 5

  test -x "$harness"
  test -f "$hsaco"
  test -f "$capture/manifest.json"

  local counter
  if [[ "$basic_counters" == 1 ]]; then
    for counter in "${counters[@]}"; do
      local pass_dir=${output_dir}/${label}/${counter}
      mkdir -p "$pass_dir"
      HIP_VISIBLE_DEVICES=$gpu "$rocprofv3" \
        --pmc "$counter" \
        --kernel-include-regex "$symbol" \
        --output-format csv json \
        --output-file "${label}_${counter}" \
        --output-directory "$pass_dir" \
        -- "$harness" "$hsaco" "$capture" "$iterations" "$@"
    done
  fi

  local family
  if [[ "$xcd_counters" == 1 ]]; then
    for family in "${xcd_families[@]}"; do
      local pass_dir=${output_dir}/${label}/XCD_${family}
      local xcd_names=()
      local xcd
      for xcd in {0..7}; do
        xcd_names+=("NETRA_${family}_XCD${xcd}")
      done
      mkdir -p "$pass_dir"
      HIP_VISIBLE_DEVICES=$gpu "$rocprofv3" \
        --extra-counters "$xcd_counter_yaml" \
        --pmc "${xcd_names[@]}" \
        --kernel-include-regex "$symbol" \
        --output-format csv json \
        --output-file "${label}_XCD_${family}" \
        --output-directory "$pass_dir" \
        -- "$harness" "$hsaco" "$capture" "$iterations" "$@"
    done
  fi
}

start_ns=$(date +%s%N)
if [[ "$target" == all || "$target" == gate_up ]]; then
  profile_target \
    gate_up "$gate_stem" \
    "${gate_build}/${gate_stem}_harness" \
    "${gate_build}/${gate_stem}.hsaco" \
    "$gate_capture"
fi
if [[ "$target" == all || "$target" == down_reduce ]]; then
  profile_target \
    down_reduce "$down_stem" \
    "${down_build}/${down_stem}_harness" \
    "${down_build}/${down_stem}.hsaco" \
    "$down_capture" "$down_stem" 128 "$down_block_x"
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
agents = sorted(str(path) for path in output.rglob("*_agent_info.csv"))
payload = {
    "measurement_status": "profiler-instrumented",
    "timing_policy": "counter collection is intrusive; use HIP events for latency",
    "counter_collection_files": collections,
    "agent_info_files": agents,
    "elapsed_seconds": (done_ns - start_ns) / 1e9,
}
(output / "manifest.json").write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n"
)
print(f"output_dir={output}")
print(f"counter_passes={len(collections)}")
print(f"elapsed_seconds={(done_ns - start_ns) / 1e9:.6f}")
PY
