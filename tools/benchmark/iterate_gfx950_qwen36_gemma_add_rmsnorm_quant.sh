#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${BUILD_DIR:-"${repo_dir}/build/gfx950-qwen36-gemma-add-rmsnorm-quant"}
capture_dir=${CAPTURE_DIR:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/correctness/eager_gemma_add_rmsnorm_capture_20260730T062500Z/kernel-capture}
quant_reference_dir=${QUANT_REFERENCE_DIR:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/correctness/eager_gemma_add_rmsnorm_capture_20260730T062500Z/group-quant-reference}
iterations=${ITERATIONS:-1}
stem=qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950

test -f "${capture_dir}/manifest.json"
test -f "${quant_reference_dir}/manifest.json"
if docker ps --format '{{.Names}}' | grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; refusing concurrent validation" >&2
  exit 2
fi

start_ns=$(date +%s%N)
"${repo_dir}/tools/build/build_gfx950_qwen36_gemma_add_rmsnorm_quant.sh" \
  "$repo_dir" "$build_dir"
build_ns=$(date +%s%N)
set +e
HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0} \
  "${build_dir}/${stem}_harness" "${build_dir}/${stem}.hsaco" \
  "$capture_dir" "$quant_reference_dir" "$iterations"
harness_status=$?
set -e
done_ns=$(date +%s%N)

python3 - "$start_ns" "$build_ns" "$done_ns" <<'PY'
import sys
s, b, d = map(int, sys.argv[1:])
print(f"build_seconds={(b-s)/1e9:.6f}")
print(f"validation_seconds={(d-b)/1e9:.6f}")
print(f"iteration_seconds={(d-s)/1e9:.6f}")
PY
exit "$harness_status"
