#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir=${BUILD_DIR:-"${repo_dir}/build/gfx950-qwen36-dense-m1"}
capture_dir=${CAPTURE_DIR:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/kernel_experiments/qwen36_dense_out_m1_capture_20260730T053315Z/capture-v2}
iterations=${ITERATIONS:-200}
harness_stem=qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
variant=${VARIANT:-one_wave}
case "$variant" in
  one_wave)
    stem=qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
    grid=128
    threads=64
    ;;
  four_wave_lds)
    stem=qwen36_dense_m1_n2048_k4096_fp8_mfma_4wave_lds_gfx950
    grid=32
    threads=256
    ;;
  *)
    echo "VARIANT must be one_wave or four_wave_lds" >&2
    exit 2
    ;;
esac
test -f "${capture_dir}/manifest.json"
if docker ps --format '{{.Names}}' | grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; refusing concurrent validation" >&2
  exit 2
fi
start_ns=$(date +%s%N)
"${repo_dir}/tools/build/build_gfx950_qwen36_dense_m1.sh" \
  "${repo_dir}" "${build_dir}"
build_ns=$(date +%s%N)
HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0} \
  "${build_dir}/${harness_stem}_harness" "${build_dir}/${stem}.hsaco" \
  "${capture_dir}" "${iterations}" "${stem}" "${grid}" "${threads}"
done_ns=$(date +%s%N)
python3 - "${start_ns}" "${build_ns}" "${done_ns}" <<'PY'
import sys
s, b, d = map(int, sys.argv[1:])
print(f"build_seconds={(b-s)/1e9:.6f}")
print(f"validation_seconds={(d-b)/1e9:.6f}")
print(f"iteration_seconds={(d-s)/1e9:.6f}")
PY
