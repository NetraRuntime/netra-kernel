#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/extend-attention-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
binary=${out_dir}/extend_attention_counter
mkdir -p "${out_dir}"
env -u LD_LIBRARY_PATH "${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" -o "${binary}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU MeanOccupancyPerCU Wavefronts
  SQ_WAVES SQ_WAVE_CYCLES SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit
  GL2C_HIT_sum GL2C_MISS_sum MemUnitBusy LDSBankConflict VALUInsts SALUInsts
  WriteUnitStalled SQ_INSTS_FLAT SQ_INSTS_LDS SQ_INSTS_SALU SQ_INSTS_SMEM
  SQ_INSTS_TEX_LOAD SQ_INSTS_TEX_STORE SQ_INSTS_VALU
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}; mkdir -p "${pass_dir}"
  timeout -k 5 90 env -u LD_LIBRARY_PATH "${rocm}/bin/rocprofv3" \
    --disable-signal-handlers true -d "${pass_dir}" -o trace \
    --pmc "${counter}" -f csv -- "${binary}" \
    "${repo_dir}/build/sglang/extend_attention_wmma_n64_gfx1151.hsaco" \
    8192 24576 >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured attention counter ${counter}: PASS"
done
/root/sglvenv1151/bin/python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" --kernel-prefix extend_attention_ \
  --input-scope "synthetic zeros with exact Qwen3.6 T8192 prefix24576 Hq16 Hkv2 D256 and sequential page indices" \
  --out "${out_dir}/summary.json" >"${out_dir}/summary.stdout"
echo "gfx1151 measured attention counter report: ${out_dir}/summary.json"
