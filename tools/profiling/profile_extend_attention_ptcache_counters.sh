#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${repo_dir}/build/experiments/attention-ptcache
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/extend-attention-ptcache-$(date -u +%Y%m%dT%H%M%SZ)"}
baseline_hsaco=${build_dir}/extend_attention_wmma_n64_gfx1151.hsaco
candidate_hsaco=${build_dir}/extend_attention_wmma_n64_ptcache16_gfx1151.hsaco
[[ -x ${build_dir}/extend_attention_counter_ptcache16 && -f ${candidate_hsaco} && -f ${baseline_hsaco} ]] || \
  "${repo_dir}/tools/build/build_extend_attention_ptcache_experiment.sh"
mkdir -p "${out_dir}"
variable_counters=(SQ_BUSY_CYCLES FETCH_SIZE L2CacheHit MeanOccupancyPerActiveCU)
fixed_counters=(SALUInsts Wavefronts)
for variant in qpipe8 ptcache16; do
  if [[ ${variant} == qpipe8 ]]; then
    binary=${build_dir}/extend_attention_counter_qpipe8
    hsaco=${baseline_hsaco}
    input_scope="synthetic zeros exact Qwen3.6 T8192 prefix24576 Hq16 Hkv2 D256 qpipe8 N64; three independent passes for SQ/FETCH/L2/occupancy"
  else
    binary=${build_dir}/extend_attention_counter_ptcache16
    hsaco=${candidate_hsaco}
    input_scope="synthetic zeros exact Qwen3.6 T8192 prefix24576 Hq16 Hkv2 D256 ptcache16 N64; three independent passes for SQ/FETCH/L2/occupancy"
  fi
  for counter in "${variable_counters[@]}"; do
    for rep in 1 2 3; do
      pass_dir=${out_dir}/${variant}/${counter}-rep${rep}
      mkdir -p "${pass_dir}"
      timeout -k 5 90 env -u LD_LIBRARY_PATH /opt/rocm-7.2.1/bin/rocprofv3 \
        --disable-signal-handlers true -d "${pass_dir}" -o trace \
        --pmc "${counter}" -f csv -- "${binary}" "${hsaco}" 8192 24576 \
        >"${pass_dir}/run.log" 2>&1
      echo "gfx1151 measured ${variant} ${counter} rep${rep}: PASS"
    done
  done
  for counter in "${fixed_counters[@]}"; do
    pass_dir=${out_dir}/${variant}/${counter}
    mkdir -p "${pass_dir}"
    timeout -k 5 90 env -u LD_LIBRARY_PATH /opt/rocm-7.2.1/bin/rocprofv3 \
      --disable-signal-handlers true -d "${pass_dir}" -o trace \
      --pmc "${counter}" -f csv -- "${binary}" "${hsaco}" 8192 24576 \
      >"${pass_dir}/run.log" 2>&1
    echo "gfx1151 measured ${variant} ${counter}: PASS"
  done
  "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" "${out_dir}/${variant}" \
    --kernel-prefix extend_attention_ --input-scope "${input_scope}" \
    --out "${out_dir}/${variant}/summary.json" >"${out_dir}/${variant}/summary.stdout"
done
echo "gfx1151 measured page-table-cache reports: ${out_dir}/{qpipe8,ptcache16}/summary.json"
