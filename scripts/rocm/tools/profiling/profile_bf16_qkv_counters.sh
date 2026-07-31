#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/bf16-qkv-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
build_dir=${repo_dir}/build/experiments/bf16-qkv
raw_binary=${build_dir}/raw-counter-driver
rocblas_binary=${build_dir}/rocblas-counter-driver
raw_stem=${NETRA_QKV_STEM:-bf16_qkv_decode_wave1_gfx1151}
raw_hsaco=${repo_dir}/build/sglang/${raw_stem}.hsaco
raw_symbol=${NETRA_QKV_SYMBOL:-${raw_stem}}

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
detected=$(${rocm}/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

mkdir -p "$out_dir" "$build_dir"
"${repo_dir}/scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh" >/dev/null
"${rocm}/bin/hipcc" -O3 --offload-arch=gfx1151 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/dense/bf16_qkv_decode_counter_driver.hip" \
  -o "$raw_binary"
"${rocm}/bin/hipcc" -O3 --offload-arch=gfx1151 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/dense/bf16_qkv_rocblas_counter_driver.hip" \
  -L"${rocm}/lib" -lrocblas -o "$rocblas_binary"

raw_grid=${NETRA_QKV_GRID:-1152}
raw_block=${NETRA_QKV_BLOCK:-256}
{
  echo target=gfx1151
  echo measurement_status=measured
  echo estimated_values=false
  echo shape=M1_N9216_K2048_BF16
  echo profiler="$profiler"
  echo signal_handlers=disabled
  echo collection=one_counter_per_fresh_process
  echo raw_stem="$raw_stem"
  echo raw_symbol="$raw_symbol"
  echo raw_grid="$raw_grid"
  echo raw_block="$raw_block"
  sha256sum "$raw_hsaco"
  "$profiler" --version
} > "$out_dir/manifest.txt"

counters=(
  FETCH_SIZE WRITE_SIZE L2CacheHit MeanOccupancyPerActiveCU
  OccupancyPercent MemUnitBusy SQ_WAVES SQ_WAVE_CYCLES VALUInsts
)

profile_variant() {
  local variant=$1
  shift
  local -a command=("$@")
  local counter pass_dir
  for counter in "${counters[@]}"; do
    pass_dir=${out_dir}/${variant}/${counter}
    mkdir -p "$pass_dir"
    timeout -k 5 90 "$profiler" --disable-signal-handlers true \
      -d "$pass_dir" -o trace --pmc "$counter" -f csv -- \
      "${command[@]}" >"$pass_dir/run.log" 2>&1
    echo "gfx1151 measured ${variant} BF16 QKV ${counter}: PASS"
  done
}

profile_variant raw "$raw_binary" "$raw_hsaco" "$raw_symbol" "$raw_grid" "$raw_block" 1
profile_variant rocblas "$rocblas_binary" 1

python=/root/sglvenv1151/bin/python
summarizer=${repo_dir}/tools/profiling/summarize_rocprof_counters.py
"$python" "$summarizer" "$out_dir/raw" \
  --kernel-prefix "$raw_symbol" \
  --input-scope "exact Qwen3.6 M1 N9216 K2048 BF16 raw ASM on gfx1151" \
  --method "one counter per fresh process; one warmup and one measured dispatch" \
  --out "$out_dir/raw-summary.json" > "$out_dir/raw-summary.stdout"
"$python" "$summarizer" "$out_dir/rocblas" \
  --kernel-prefix Cijk_Alik_Bljk \
  --input-scope "exact Qwen3.6 M1 N9216 K2048 BF16 rocBLAS on gfx1151" \
  --method "one counter per fresh process; one warmup and one measured dispatch" \
  --out "$out_dir/rocblas-summary.json" > "$out_dir/rocblas-summary.stdout"

echo "gfx1151 measured BF16 QKV counter report: $out_dir"
