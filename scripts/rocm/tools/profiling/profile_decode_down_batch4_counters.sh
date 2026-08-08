#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/decode-down-batch4-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
build_dir=${repo_dir}/build/experiments/decode-down-batch4
binary=${build_dir}/benchmark_decode_down_pipeline
hsaco_dir=${repo_dir}/build/sglang
baseline=${hsaco_dir}/mxfp4_sgl_decode_down_gfx1151.hsaco
candidate=${hsaco_dir}/mxfp4_decode_down_batch4_wg32_gfx1151.hsaco

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
detected=$(${rocm}/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

mkdir -p "$out_dir" "$build_dir"
"${repo_dir}/scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh" >/dev/null
"${rocm}/bin/hipcc" -O3 -std=c++20 --offload-arch=gfx1151 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_decode_down_pipeline.hip" \
  -o "$binary"

{
  echo target=gfx1151
  echo measurement_status=measured
  echo estimated_values=false
  echo shape=M1_selected8_N2048_K512_MXFP4
  echo profiler="$profiler"
  echo signal_handlers=disabled
  echo collection=one_counter_per_fresh_process
  sha256sum "$baseline" "$candidate"
  "$profiler" --version
} > "$out_dir/manifest.txt"

counters=(
  FETCH_SIZE WRITE_SIZE L2CacheHit MeanOccupancyPerActiveCU
  OccupancyPercent MemUnitBusy SQ_WAVES SQ_WAVE_CYCLES VALUInsts
)

profile_variant() {
  local variant=$1
  local baseline_flag=$2
  local counter pass_dir
  for counter in "${counters[@]}"; do
    pass_dir=${out_dir}/${variant}/${counter}
    mkdir -p "$pass_dir"
    if [[ $baseline_flag == 1 ]]; then
      timeout -k 5 90 env NETRA_COUNTER_MODE=1 NETRA_COUNTER_BASELINE=1 \
        "$profiler" --disable-signal-handlers true \
        -d "$pass_dir" -o trace --pmc "$counter" -f csv -- \
        "$binary" "$baseline" "$candidate" \
        >"$pass_dir/run.log" 2>&1
    else
      timeout -k 5 90 env NETRA_COUNTER_MODE=1 \
        "$profiler" --disable-signal-handlers true \
        -d "$pass_dir" -o trace --pmc "$counter" -f csv -- \
        "$binary" "$baseline" "$candidate" \
        >"$pass_dir/run.log" 2>&1
    fi
    echo "gfx1151 measured ${variant} routed down ${counter}: PASS"
  done
}

profile_variant baseline 1
profile_variant candidate 0

python=/root/sglvenv1151/bin/python
summarizer=${repo_dir}/tools/profiling/summarize_rocprof_counters.py
"$python" "$summarizer" "$out_dir/baseline" \
  --kernel-prefix mxfp4_decode_down_gfx1151 \
  --input-scope "Qwen3.6 routed down M1 selected8 N2048 K512 baseline raw ASM on gfx1151" \
  --method "one counter per fresh process; one dispatch" \
  --out "$out_dir/baseline-summary.json" \
  > "$out_dir/baseline-summary.stdout"
"$python" "$summarizer" "$out_dir/candidate" \
  --kernel-prefix mxfp4_decode_down_pipeline_gfx1151 \
  --input-scope "Qwen3.6 routed down M1 selected8 N2048 K512 batch4 WG32 raw ASM on gfx1151" \
  --method "one counter per fresh process; one dispatch" \
  --out "$out_dir/candidate-summary.json" \
  > "$out_dir/candidate-summary.stdout"

echo "gfx1151 measured routed-down counter report: $out_dir"
