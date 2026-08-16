#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${BUILD_DIR:-"${repo_dir}/build/gfx950-qwen36-router-bf16"}
capture_dir=${CAPTURE_DIR:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/correctness/router_bf16_layer0_capture}
iterations=${ITERATIONS:-1}
rows=${ROWS:-1}
stem=qwen36_router_bf16_gemv_gfx950

test -f "${capture_dir}/manifest.json"
if docker ps --format '{{.Names}}' | grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; refusing concurrent validation" >&2
  exit 2
fi

start_ns=$(date +%s%N)
"${repo_dir}/tools/build/build_gfx950_router_bf16_k2048_n256.sh" \
  "$repo_dir" "$build_dir"
build_ns=$(date +%s%N)
set +e
HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0} \
  "${build_dir}/${stem}_harness" "${build_dir}/${stem}.hsaco" \
  "$capture_dir" "$iterations" "$rows"
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
