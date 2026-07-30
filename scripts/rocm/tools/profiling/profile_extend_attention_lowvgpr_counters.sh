#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside Netra" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/results/profiles/gfx1151/attention-lowvgpr-$(date -u +%Y%m%dT%H%M%SZ)"}
build=${repo}/build/experiments/attention-lowvgpr
profiler=/opt/rocm-7.2.1/bin/rocprofv3
"${repo}/scripts/rocm/tools/build/build_extend_attention_lowvgpr_experiment.sh" "${build}" >/dev/null
counters=(OccupancyPercent MeanOccupancyPerActiveCU SQ_WAVES SQ_WAVE_CYCLES)
for variant in baseline candidate; do
  if [[ ${variant} == baseline ]]; then
    hsaco=${build}/extend_attention_wmma_n64_gfx1151.hsaco
  else
    hsaco=${build}/extend_attention_wmma_n64_group4_qpipe_kvbatch16_lowvgpr_gfx1151.hsaco
  fi
  for counter in "${counters[@]}"; do
    pass=${out}/${variant}/${counter}
    mkdir -p "${pass}"
    timeout -k 5 90 env -u LD_LIBRARY_PATH "${profiler}" \
      --disable-signal-handlers true -d "${pass}" -o trace \
      --pmc "${counter}" -f csv -- \
      "${build}/extend_attention_counter_${variant}" "${hsaco}" 8192 24576 \
      >"${pass}/run.log" 2>&1
    echo "gfx1151 measured ${variant} attention ${counter}: PASS"
  done
  "${repo}/tools/profiling/summarize_rocprof_counters.py" "${out}/${variant}" \
    --kernel-prefix extend_attention_ \
    --input-scope "T8192 prefix24576 Hq16 Hkv2 D256 ${variant}" \
    --out "${out}/${variant}/summary.json" >"${out}/${variant}/summary.stdout"
done
echo "gfx1151 measured N64 low-VGPR counters: ${out}"
