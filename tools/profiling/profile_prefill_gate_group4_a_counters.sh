#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside Netra" >&2; exit 1; }
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/prefill-gate-group4-a-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
build_dir=${repo_dir}/build/experiments/prefill-gate-group4-a
binary=${build_dir}/benchmark_prefill_gate_group4_a
baseline=${build_dir}/mxfp4_prefill_gate_dword_layout_gfx1151.hsaco
candidate=${build_dir}/mxfp4_prefill_gate_group4_a_gfx1151.hsaco
repacker=${build_dir}/mxfp4_prefill_repack_dword_gfx1151.hsaco
if [[ ! -x "${binary}" || ! -f "${baseline}" || ! -f "${candidate}" || ! -f "${repacker}" ]]; then
  "${repo_dir}/tools/build/build_prefill_gate_group4_a_experiment.sh"
fi
repeats=${NETRA_ROCPROF_REPEATS:-3}
mkdir -p "${out_dir}"
counters=(MeanOccupancyPerActiveCU Wavefronts FETCH_SIZE L2CacheHit LDSBankConflict VALUInsts SALUInsts SQ_BUSY_CYCLES MemUnitBusy)
for counter in "${counters[@]}"; do
  for repeat in $(seq 1 "${repeats}"); do
    pass_dir=${out_dir}/${counter}-r${repeat}; mkdir -p "${pass_dir}"
    timeout -k 5 90 env -u LD_LIBRARY_PATH "${rocm}/bin/rocprofv3" --disable-signal-handlers true \
      -d "${pass_dir}" -o trace --pmc "${counter}" -f csv -- "${binary}" \
      "${baseline}" "${candidate}" "${repacker}" 1276 1 >"${pass_dir}/run.log" 2>&1
    echo "gfx1151 measured prefill-gate group4-A ${counter} ${repeat}/${repeats}: PASS"
  done
done
python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" "${out_dir}" \
  --kernel-prefix mxfp4_prefill_gate_wmma_gfx1151 --input-scope "exact Qwen3.6 G1276 M64 N512 K2048 production dword" --out "${out_dir}/baseline-summary.json" >"${out_dir}/baseline-summary.stdout"
python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" "${out_dir}" \
  --kernel-prefix mxfp4_prefill_gate_group4_a_gfx1151 --input-scope "exact Qwen3.6 G1276 M64 N512 K2048 group4-A" --out "${out_dir}/candidate-summary.json" >"${out_dir}/candidate-summary.stdout"
echo "gfx1151 measured prefill-gate group4-A counter reports: ${out_dir}"
