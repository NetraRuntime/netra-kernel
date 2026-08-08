#!/usr/bin/env bash
set -euo pipefail

[[ $(hostname) == Netra ]] || {
  echo "refusing to profile outside Netra" >&2
  exit 1
}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "$script_dir" rev-parse --show-toplevel)
rocm=/opt/rocm-7.2.1
before_hsaco=${1:-${repo}/build/experiments/linear-prefill-pair2-pipe-a/production-before.hsaco}
after_hsaco=${2:-${repo}/build/sglang/mxfp4_sgl_linear_prefill_wmma_gfx1151.hsaco}
out=${3:-${repo}/results/profiles/gfx1151/dense-prefill-pair2-pipe-counters-$(date -u +%Y%m%dT%H%M%SZ)}
binary=${repo}/build/experiments/linear_prefill_counter_driver
symbol=mxfp4_sgl_linear_prefill_wmma_gfx1151

[[ -f $before_hsaco && -f $after_hsaco ]] || {
  echo "missing before or after HSACO" >&2
  exit 1
}
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo}/harness/gfx1151/mxfp4/serving/linear_prefill_counter_driver.hip" \
  -o "$binary"

counters=(
  OccupancyPercent MeanOccupancyPerActiveCU SQ_WAVES SQ_WAVE_CYCLES
  SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit MemUnitBusy
  LDSBankConflict VALUInsts SQ_INSTS_LDS SQ_INSTS_FLAT
)
for variant in before after; do
  if [[ $variant == before ]]; then hsaco=$before_hsaco; else hsaco=$after_hsaco; fi
  for counter in "${counters[@]}"; do
    pass=${out}/${variant}/${counter}
    mkdir -p "$pass"
    timeout -k 5 120 env -u LD_LIBRARY_PATH "${rocm}/bin/rocprofv3" \
      --disable-signal-handlers true -d "$pass" -o trace \
      --pmc "$counter" -f csv -- \
      "$binary" "$hsaco" "$symbol" 1 >"${pass}/run.log" 2>&1
    echo "gfx1151 measured dense-prefill ${variant} ${counter}: PASS"
  done
  "${repo}/tools/profiling/summarize_rocprof_counters.py" "${out}/${variant}" \
    --kernel-prefix "$symbol" \
    --input-scope "exact Qwen3.6 N12288 K2048 G128 raw gfx1151 ASM ${variant}" \
    --out "${out}/${variant}-summary.json" >"${out}/${variant}-summary.stdout"
done
echo "gfx1151 measured dense-prefill counter report: ${out}"
