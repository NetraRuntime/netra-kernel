#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${BUILD_DIR:-"${repo_dir}/build/gfx950-qwen36-moe-down-reduce"}
capture_dir=${CAPTURE_DIR:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/kernel_experiments/qwen36_moe_down_reduce_fp8_gfx950_20260730T010200Z/capture}
iterations=${ITERATIONS:-20}
stem=qwen36_moe_down_reduce_fp8_gfx950

if [[ ! -f "${capture_dir}/manifest.json" ]]; then
  echo "missing exported stage-2 capture: ${capture_dir}" >&2
  exit 2
fi
if docker ps --format '{{.Names}}' 2>/dev/null |
   grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; stop/finalize it before validation" >&2
  exit 2
fi

start_ns=$(date +%s%N)
"${repo_dir}/tools/build/build_gfx950_qwen36_moe_down_reduce.sh" \
  "${repo_dir}" "${build_dir}"
build_done_ns=$(date +%s%N)
HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0} \
  "${build_dir}/${stem}_harness" \
  "${build_dir}/${stem}.hsaco" \
  "${capture_dir}" \
  "${iterations}"
validation_done_ns=$(date +%s%N)

python3 - \
  "${start_ns}" "${build_done_ns}" "${validation_done_ns}" <<'PY'
import sys

start, built, done = map(int, sys.argv[1:])
print(f"build_seconds={(built - start) / 1e9:.6f}")
print(f"validation_seconds={(done - built) / 1e9:.6f}")
print(f"iteration_seconds={(done - start) / 1e9:.6f}")
PY
