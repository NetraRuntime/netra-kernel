#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/gate-chunk4-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
build_dir=${repo_dir}/build/experiments/gate-chunk4
binary=${build_dir}/benchmark_decode_gate_chunk4
hsaco_dir=${repo_dir}/build/sglang
baseline_compute=${hsaco_dir}/mxfp4_decode_gate_block64_gfx1151.hsaco
baseline_reduce=${hsaco_dir}/mxfp4_decode_gate_block64_reduce_gfx1151.hsaco
candidate_compute=${hsaco_dir}/mxfp4_decode_gate_chunk4_gfx1151.hsaco
candidate_reduce=${hsaco_dir}/mxfp4_decode_gate_chunk4_reduce_gfx1151.hsaco

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
detected=$(${rocm}/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

mkdir -p "$out_dir" "$build_dir"
"${repo_dir}/scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh" >/dev/null
"${rocm}/bin/hipcc" -O3 -std=c++20 --offload-arch=gfx1151 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_decode_gate_chunk4.hip" \
  -o "$binary"

{
  echo target=gfx1151
  echo measurement_status=measured
  echo estimated_values=false
  echo shape=M1_selected8_N512_K2048_MXFP4
  echo profiler="$profiler"
  echo signal_handlers=disabled
  echo collection=one_counter_per_fresh_process
  sha256sum "$baseline_compute" "$baseline_reduce" \
    "$candidate_compute" "$candidate_reduce"
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
        "$binary" "$baseline_compute" "$baseline_reduce" \
          "$candidate_compute" "$candidate_reduce" \
        >"$pass_dir/run.log" 2>&1
    else
      timeout -k 5 90 env NETRA_COUNTER_MODE=1 \
        "$profiler" --disable-signal-handlers true \
        -d "$pass_dir" -o trace --pmc "$counter" -f csv -- \
        "$binary" "$baseline_compute" "$baseline_reduce" \
          "$candidate_compute" "$candidate_reduce" \
        >"$pass_dir/run.log" 2>&1
    fi
    echo "gfx1151 measured ${variant} routed gate/up ${counter}: PASS"
  done
}

profile_variant baseline 1
profile_variant candidate 0

python=/root/sglvenv1151/bin/python
summarizer=${repo_dir}/tools/profiling/summarize_rocprof_counters.py
summarize() {
  local variant=$1
  local kernel=$2
  local suffix=$3
  "$python" "$summarizer" "$out_dir/$variant" \
    --kernel-prefix "$kernel" \
    --input-scope "Qwen3.6 routed gate/up M1 selected8 N512 K2048 ${variant} raw ASM on gfx1151" \
    --method "one counter per fresh process; one compute+reduce dispatch" \
    --out "$out_dir/${variant}-${suffix}-summary.json" \
    > "$out_dir/${variant}-${suffix}-summary.stdout"
}
summarize baseline mxfp4_decode_gate_block64_gfx1151 compute
summarize baseline mxfp4_decode_gate_block64_reduce_gfx1151 reduce
summarize candidate mxfp4_decode_gate_chunk4_gfx1151 compute
summarize candidate mxfp4_decode_gate_chunk4_reduce_gfx1151 reduce

echo "gfx1151 measured routed gate/up counter report: $out_dir"
