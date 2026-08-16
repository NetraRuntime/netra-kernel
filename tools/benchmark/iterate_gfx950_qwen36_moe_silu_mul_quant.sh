#!/usr/bin/env bash
set -euo pipefail

# Fast MI350X edit -> assemble -> live-request-tensor correctness loop.
# The expensive Qwen request capture is reused; this script never launches the
# model server and never profiles or benchmarks another model.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${REPO_DIR:-$(cd "${script_dir}/../.." && pwd)}
netra_server=${NETRA_SERVER:-/data/netra/repos/netra-server}
capture_run=${CAPTURE_RUN:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/correctness/eager_auto_aiter_moe_request_stage_dump_20260729T231345Z}
image=${IMAGE:-lmsysorg/sglang:v0.5.16-rocm720-mi35x}
container=${ITERATION_CONTAINER:-netra-gfx950-qwen36-kernel-validator}
gpu=${GPU:-0}

activation_capture=${capture_run}/aiter-moe-stage-dump/aiter_moe_activation_000.pt
quant_capture=${capture_run}/aiter-moe-stage-dump/aiter_moe_quant_000.pt
build_dir=${repo_dir}/build/gfx950-qwen36-fp8
bridge=${build_dir}/libqwen36_moe_silu_mul_quant_fp8_gfx950_bridge.so
hsaco=${build_dir}/qwen36_moe_silu_mul_quant_fp8_gfx950.hsaco

test -f "$activation_capture"
test -f "$quant_capture"
test -f "$netra_server/scripts/rocm/mi350x/validate_qwen36_moe_silu_mul_quant_capture.py"

build_start_ns=$(date +%s%N)
"$repo_dir/tools/build/build_gfx950_moe_decode_fp8_e4m3_h2048_i512_top9_block128_aiter.sh" \
  "$repo_dir" "$build_dir" >/dev/null
build_end_ns=$(date +%s%N)

if ! docker inspect "$container" >/dev/null 2>&1; then
  docker create --name "$container" \
    --device=/dev/kfd --device=/dev/dri --group-add video \
    --ipc=host \
    -e "HIP_VISIBLE_DEVICES=$gpu" \
    -v "$netra_server":/netra-server:ro \
    -v "$repo_dir":/netra-kernel:ro \
    -v "$capture_run":/capture:ro \
    --entrypoint /bin/bash \
    "$image" -lc 'exec sleep infinity' >/dev/null
fi

if [[ $(docker inspect "$container" --format '{{.State.Running}}') != true ]]; then
  docker start "$container" >/dev/null
fi

validate_start_ns=$(date +%s%N)
docker exec "$container" /opt/venv/bin/python \
  /netra-server/scripts/rocm/mi350x/validate_qwen36_moe_silu_mul_quant_capture.py \
  --activation-capture \
  /capture/aiter-moe-stage-dump/aiter_moe_activation_000.pt \
  --quant-capture \
  /capture/aiter-moe-stage-dump/aiter_moe_quant_000.pt \
  --library \
  /netra-kernel/build/gfx950-qwen36-fp8/libqwen36_moe_silu_mul_quant_fp8_gfx950_bridge.so \
  --hsaco \
  /netra-kernel/build/gfx950-qwen36-fp8/qwen36_moe_silu_mul_quant_fp8_gfx950.hsaco
validate_end_ns=$(date +%s%N)

python3 - "$build_start_ns" "$build_end_ns" \
  "$validate_start_ns" "$validate_end_ns" <<'PY'
import sys

build_start, build_end, validate_start, validate_end = map(int, sys.argv[1:])
print(
    "iteration timing: "
    f"build={(build_end - build_start) / 1e9:.3f}s "
    f"validate={(validate_end - validate_start) / 1e9:.3f}s "
    f"total={(validate_end - build_start) / 1e9:.3f}s"
)
PY
