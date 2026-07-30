#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to profile outside Netra" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/results/profiles/gfx1151/qk-mrope-kv-$(date -u +%Y%m%dT%H%M%SZ)"}
build=${repo}/build/experiments/qk-norm-mrope-kv-fusion
profiler=/opt/rocm-7.2.1/bin/rocprofv3
"${repo}/scripts/rocm/tools/build/build_qk_norm_mrope_kv_fusion_experiment.sh" "${build}" >/dev/null
hsaco=${build}/qk_norm_mrope_gate_kv_store_gfx1151.hsaco
driver=${build}/qk_norm_mrope_gate_kv_store_counter_driver
counters=(SALUInsts VALUInsts LDSBankConflict WriteUnitStalled FETCH_SIZE WRITE_SIZE L2CacheHit OccupancyPercent MeanOccupancyPerActiveCU Wavefronts)
for counter in "${counters[@]}"; do
  pass=${out}/${counter}
  mkdir -p "${pass}"
  timeout -k 5 90 env -u LD_LIBRARY_PATH "${profiler}" \
    --disable-signal-handlers true -d "${pass}" -o trace \
    --pmc "${counter}" --kernel-include-regex qk_norm_mrope_gate_kv_store_gfx1151 -f csv -- \
    "${driver}" "${hsaco}" 8192 >"${pass}/run.log" 2>&1
  echo "gfx1151 measured Q/K-MRoPE-KV ${counter}: PASS"
done
"${repo}/tools/profiling/summarize_rocprof_counters.py" "${out}" \
  --kernel-prefix qk_norm_mrope_gate_kv_store_gfx1151 \
  --input-scope "M8192 Hq16 Hkv2 D256 rotary64 page1" \
  --out "${out}/summary.json" >"${out}/summary.stdout"
echo "gfx1151 measured Q/K norm + MRoPE + KV-store counters: ${out}"
