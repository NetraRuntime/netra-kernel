#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${repo_dir}/build/experiments/attention-group4
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/extend-attention-group4-$(date -u +%Y%m%dT%H%M%SZ)"}
baseline_hsaco=${build_dir}/extend_attention_wmma_n64_qpipe8_baseline_gfx1151.hsaco
candidate_hsaco=${build_dir}/extend_attention_wmma_n64_group4_gfx1151.hsaco
[[ -x ${build_dir}/extend_attention_counter_candidate && -f ${candidate_hsaco} && -f ${baseline_hsaco} ]] || \
  "${repo_dir}/tools/build/build_extend_attention_group4_experiment.sh"
mkdir -p "${out_dir}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU Wavefronts
  FETCH_SIZE L2CacheHit LDSBankConflict VALUInsts
)
for variant in baseline candidate; do
  binary=${build_dir}/extend_attention_counter_${variant}
  if [[ ${variant} == baseline ]]; then
    hsaco=${baseline_hsaco}
    input_scope="synthetic zeros exact Qwen3.6 T8192 prefix24576 Hq16 Hkv2 D256 qpipe8 N64"
  else
    hsaco=${candidate_hsaco}
    input_scope="synthetic zeros exact Qwen3.6 T8192 prefix24576 Hq16 Hkv2 D256 group4 shared-KV"
  fi
  for counter in "${counters[@]}"; do
    pass_dir=${out_dir}/${variant}/${counter}
    mkdir -p "${pass_dir}"
    timeout -k 5 90 env -u LD_LIBRARY_PATH /opt/rocm-7.2.1/bin/rocprofv3 \
      --disable-signal-handlers true -d "${pass_dir}" -o trace \
      --pmc "${counter}" -f csv -- "${binary}" "${hsaco}" 8192 24576 \
      >"${pass_dir}/run.log" 2>&1
    echo "gfx1151 measured ${variant} attention counter ${counter}: PASS"
  done
  "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" "${out_dir}/${variant}" \
    --kernel-prefix extend_attention_ --input-scope "${input_scope}" \
    --out "${out_dir}/${variant}/summary.json" >"${out_dir}/${variant}/summary.stdout"
done
echo "gfx1151 measured group4 shared-KV counter reports: ${out_dir}/{baseline,candidate}/summary.json"
