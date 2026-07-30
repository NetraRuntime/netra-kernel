#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside the Netra LXC" >&2; exit 1; }
repo_dir=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/gdn-kkt-blockwise-counters-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
profiler=${rocm}/bin/rocprofv3
binary=${repo_dir}/build/experiments/benchmark_gdn_kkt_blockwise
hsaco=${repo_dir}/build/experiments/gdn_kkt_solve_blockwise_gfx1151.hsaco
"${repo_dir}/scripts/rocm/tools/build/build_gdn_kkt_piecewise_experiment.sh" >/dev/null 2>&1
mkdir -p "${out_dir}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU Wavefronts L2CacheHit
  FETCH_SIZE WRITE_SIZE LDSBankConflict SQ_WAVE_CYCLES VALUInsts
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}
  mkdir -p "${pass_dir}"
  timeout -k 5 90 "${profiler}" --disable-signal-handlers true \
    -d "${pass_dir}" -o trace --pmc "${counter}" -f csv -- \
    "${binary}" "${hsaco}" 5 >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured GDN KKT blockwise counter ${counter}: PASS"
done
/root/sglvenv1151/bin/python \
  "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" \
  --kernel-prefix gdn_kkt_solve_blockwise_gfx1151 \
  --input-scope "Qwen3.6 B1 T8192 H32 Hg16 K128 beta FP32 GDN KKT raw ASM; zero-data standalone counter harness" \
  --out "${out_dir}/summary.json" >"${out_dir}/summary.stdout"
echo "gfx1151 measured rejected GDN KKT blockwise counters: ${out_dir}"
