#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${repo_dir}/build/experiments/attention-n32-persistent-q
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/extend-attention-n32-persistent-q-$(date -u +%Y%m%dT%H%M%SZ)"}
binary=${build_dir}/extend_attention_counter
hsaco=${build_dir}/extend_attention_wmma_n32_persistent_q_gfx1151.hsaco
[[ -x ${binary} && -f ${hsaco} ]] || "${repo_dir}/tools/build/build_extend_attention_n32_persistent_q_experiment.sh"
mkdir -p "${out_dir}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU Wavefronts SQ_WAVE_CYCLES
  FETCH_SIZE L2CacheHit LDSBankConflict VALUInsts
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}
  mkdir -p "${pass_dir}"
  timeout -k 5 90 env -u LD_LIBRARY_PATH /opt/rocm-7.2.1/bin/rocprofv3 \
    --disable-signal-handlers true -d "${pass_dir}" -o trace \
    --pmc "${counter}" -f csv -- "${binary}" "${hsaco}" 8192 24576 \
    >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured N32 persistent-Q attention counter ${counter}: PASS"
done
"${repo_dir}/tools/profiling/summarize_rocprof_counters.py" "${out_dir}" \
  --kernel-prefix extend_attention_ \
  --input-scope "synthetic zeros exact Qwen3.6 T8192 prefix24576 Hq16 Hkv2 D256 N32 persistent-Q" \
  --out "${out_dir}/summary.json" >"${out_dir}/summary.stdout"
echo "gfx1151 measured N32 persistent-Q counter report: ${out_dir}/summary.json"
