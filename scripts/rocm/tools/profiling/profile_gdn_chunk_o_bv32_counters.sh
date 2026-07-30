#!/usr/bin/env bash
set -euo pipefail

[[ $(hostname) == Netra ]] || {
  echo "refusing to profile outside Netra" >&2
  exit 1
}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/results/profiles/gfx1151/gdn-chunk-o-two-wave-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
binary=${repo}/build/experiments/benchmark_gdn_chunk_o_bv32
hsaco=${repo}/build/sglang/gdn_chunk_o_bv32_gfx1151.hsaco

"${repo}/scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh" \
  "${repo}" "${repo}/build/sglang" >/dev/null
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 -I"${repo}" \
  "${repo}/scripts/rocm/harness/gfx1151/gdn/benchmark_gdn_chunk_o_bv32.hip" \
  -o "${binary}"

counters=(
  OccupancyPercent MeanOccupancyPerActiveCU SQ_WAVES
  SQ_WAVE_CYCLES SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit
  MemUnitBusy LDSBankConflict VALUInsts SQ_INSTS_LDS SQ_INSTS_FLAT
)
for counter in "${counters[@]}"; do
  pass=${out}/${counter}
  mkdir -p "${pass}"
  timeout -k 5 120 env -u LD_LIBRARY_PATH "${profiler}" \
    --disable-signal-handlers true -d "${pass}" -o trace \
    --pmc "${counter}" -f csv -- \
    "${binary}" "${hsaco}" 1 >"${pass}/run.log" 2>&1
  echo "gfx1151 measured GDN chunk-o ${counter}: PASS"
done

"${repo}/tools/profiling/summarize_rocprof_counters.py" "${out}" \
  --kernel-prefix gdn_chunk_o_bv32_gfx1151 \
  --input-scope "exact Qwen3.6 B1 T8192 H32 Hg16 K128 V128 BT64 raw ASM" \
  --out "${out}/summary.json" >"${out}/summary.stdout"
echo "gfx1151 measured GDN chunk-o counter report: ${out}"
