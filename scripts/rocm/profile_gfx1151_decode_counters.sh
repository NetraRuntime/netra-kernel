#!/usr/bin/env bash
set -euo pipefail
# Execute inside the Netra LXC. One counter per launch is required on gfx1151.
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/decode-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
binary=${out_dir}/gfx1151_decode_counter_harness
mkdir -p "${out_dir}"
env -u LD_LIBRARY_PATH "${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/gfx1151_decode_counter_harness.hip" \
  -L"${repo_dir}/build/sglang" -lnetra_mxfp4_sgl \
  -Wl,-rpath,"${repo_dir}/build/sglang" -o "${binary}"

counters=(
  OccupancyPercent MeanOccupancyPerActiveCU MeanOccupancyPerCU Wavefronts
  SQ_WAVES SQ_WAVE_CYCLES SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit
  GL2C_HIT_sum GL2C_MISS_sum MemUnitBusy LDSBankConflict VALUInsts SALUInsts
  SFetchInsts WriteUnitStalled SQ_INSTS_FLAT SQ_INSTS_LDS SQ_INSTS_SALU
  SQ_INSTS_SMEM SQ_INSTS_TEX_LOAD SQ_INSTS_TEX_STORE SQ_INSTS_VALU
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}
  mkdir -p "${pass_dir}"
  timeout -k 5 60 env -u LD_LIBRARY_PATH "${rocm}/bin/rocprofv3" \
    -d "${pass_dir}" -o trace --pmc "${counter}" -f csv -- \
    "${binary}" 1 >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured counter ${counter}: PASS"
done
python "${repo_dir}/scripts/rocm/summarize_rocprof_counters.py" \
  "${out_dir}" --out "${out_dir}/summary.json" >"${out_dir}/summary.stdout"
echo "gfx1151 measured counter report: ${out_dir}/summary.json"
