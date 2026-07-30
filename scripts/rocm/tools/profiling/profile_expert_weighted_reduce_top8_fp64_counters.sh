#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/expert-reduce-fp64-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
binary=${repo_dir}/build/experiments/benchmark_expert_weighted_reduce_top8_fp64
mkdir -p "${out_dir}" "${repo_dir}/build/experiments"
"${repo_dir}/scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh" >/dev/null
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/moe/benchmark_expert_weighted_reduce_top8_fp64.hip" \
  -o "${binary}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU Wavefronts SQ_WAVES
  SQ_WAVE_CYCLES SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit
  MemUnitBusy LDSBankConflict VALUInsts SQ_INSTS_FLAT SQ_INSTS_LDS
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}
  mkdir -p "${pass_dir}"
  timeout -k 5 90 "${profiler}" --disable-signal-handlers true \
    -d "${pass_dir}" -o trace --pmc "${counter}" -f csv -- \
    "${binary}" \
    "${repo_dir}/build/sglang/expert_weighted_reduce_top8_fp64_gfx1151.hsaco" 1 \
    >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured expert reduce counter ${counter}: PASS"
done
/root/sglvenv1151/bin/python \
  "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" \
  --kernel-prefix expert_weighted_reduce_top8_fp64_gfx1151 \
  --input-scope "Qwen3.6 M8192 H2048 top-8 FP32 expert rows and router weights to BF16 raw ASM" \
  --out "${out_dir}/summary.json" >"${out_dir}/summary.stdout"
echo "gfx1151 measured expert reduce counter report: ${out_dir}"
