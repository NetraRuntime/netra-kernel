#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside Netra" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/results/profiles/gfx1151/recompute-w-u-breuse-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
build=${repo}/build/experiments/recompute-w-u-breuse
binary=${build}/benchmark_recompute_w_u_variant
mkdir -p "${out}"
"${repo}/scripts/rocm/tools/build/build_recompute_w_u_breuse_experiment.sh" "${build}" >/dev/null
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo}/scripts/rocm/harness/gfx1151/gdn/benchmark_recompute_w_u_variant.hip" \
  -o "${binary}"
counters=(
  MeanOccupancyPerActiveCU Wavefronts SQ_WAVES SQ_WAVE_CYCLES
  SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit MemUnitBusy
  LDSBankConflict VALUInsts SQ_INSTS_FLAT SQ_INSTS_LDS
)
for variant in baseline candidate; do
  if [[ ${variant} == baseline ]]; then
    stem=recompute_w_u_ordered_baseline_gfx1151
    symbol=recompute_w_u_reuse_a_ordered_gfx1151
  else
    stem=recompute_w_u_ordered_breuse_gfx1151
    symbol=recompute_w_u_reuse_a_ordered_breuse_gfx1151
  fi
  for counter in "${counters[@]}"; do
    pass=${out}/${variant}/${counter}
    mkdir -p "${pass}"
    timeout -k 5 90 "${profiler}" --disable-signal-handlers true \
      -d "${pass}" -o trace --pmc "${counter}" -f csv -- \
      "${binary}" "${build}/${stem}.hsaco" "${symbol}" 1 \
      >"${pass}/run.log" 2>&1
    echo "gfx1151 measured ${variant} recompute counter ${counter}: PASS"
  done
  /root/sglvenv1151/bin/python \
    "${repo}/tools/profiling/summarize_rocprof_counters.py" \
    "${out}/${variant}" --kernel-prefix "${symbol}" \
    --input-scope "exact Qwen3.6 B1 T8192 H32 Hg16 K128 V128 BT64 zero-input raw ASM" \
    --out "${out}/${variant}/summary.json" \
    >"${out}/${variant}/summary.stdout"
done
echo "gfx1151 measured recompute B-reuse counters: ${out}"
