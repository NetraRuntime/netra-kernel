#!/usr/bin/env bash
# Screen Qwen dFlash M=16 GDN Triton launch geometry on eight MI350X GPUs.

set -euo pipefail

KERNEL_REPO=${KERNEL_REPO:-/data/netra/repos/netra-kernel}
SERVER_REPO=${SERVER_REPO:-/data/netra/repos/netra-server}
CAMPAIGN_ROOT=${CAMPAIGN_ROOT:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z}
CAPTURE_DIR=${CAPTURE_DIR:-${CAMPAIGN_ROOT}/kernel_experiments/qwen36_gdn_verify_m16_real_20260730T174213Z}
IMAGE=${IMAGE:-lmsysorg/sglang:v0.5.16-rocm720-mi35x}
EXPECTED_IMAGE_ID=${EXPECTED_IMAGE_ID:-sha256:54ac680bad1832b8acd469533ae66f608b525cec3449bbd5f3d0238351e9b965}
ITERATIONS=${ITERATIONS:-500}
CORRECTNESS_ITERATIONS=${CORRECTNESS_ITERATIONS:-10}
CORRECTNESS_POLICY=${CORRECTNESS_POLICY:-exact}
SCREEN_MODE=${SCREEN_MODE:-warp-stage}
RUN_ID=${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
RESULT_ROOT=${RESULT_ROOT:-${CAMPAIGN_ROOT}/kernel_experiments/qwen36_gdn_triton_${SCREEN_MODE}_8gpu_${RUN_ID}}

readonly KERNEL_REPO SERVER_REPO CAMPAIGN_ROOT CAPTURE_DIR IMAGE
readonly EXPECTED_IMAGE_ID ITERATIONS CORRECTNESS_ITERATIONS CORRECTNESS_POLICY
readonly SCREEN_MODE RUN_ID
readonly RESULT_ROOT

[[ -f "${CAPTURE_DIR}/manifest.json" ]] || {
  echo "missing capture manifest: ${CAPTURE_DIR}/manifest.json" >&2
  exit 2
}
[[ -f "${KERNEL_REPO}/tools/benchmark/qwen36_gdn_verify_triton_variants.py" ]] || {
  echo "missing benchmark harness" >&2
  exit 2
}
[[ "${CORRECTNESS_POLICY}" == exact || "${CORRECTNESS_POLICY}" == preregistered ]] || {
  echo "CORRECTNESS_POLICY must be exact or preregistered" >&2
  exit 2
}
command -v rocminfo >/dev/null
command -v amd-smi >/dev/null
command -v docker >/dev/null
rocminfo_output=$(rocminfo)
grep -q 'Name:.*gfx950' <<< "${rocminfo_output}" || {
  echo "gfx950 was not found; refusing to launch" >&2
  exit 2
}

actual_image_id=$(docker image inspect "${IMAGE}" --format '{{.Id}}')
[[ "${actual_image_id}" == "${EXPECTED_IMAGE_ID}" ]] || {
  echo "image ID mismatch: ${actual_image_id}" >&2
  exit 2
}

if ! amd-smi process --json | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
for gpu in payload:
    for process in gpu.get("process_list", []):
        if process.get("process_info") != "No running processes detected":
            raise SystemExit(1)
'; then
  echo "a GPU process is active; refusing parallel screening" >&2
  exit 2
fi

umask 002
mkdir -p "${RESULT_ROOT}"
printf '%s\n' "${RESULT_ROOT}" > /tmp/netra-current-gdn-triton-geometry.txt
printf '%s\n' "${SCREEN_MODE}" > "${RESULT_ROOT}/screen-mode.txt"
printf '%s\n' "${CORRECTNESS_POLICY}" > "${RESULT_ROOT}/correctness-policy.txt"
docker image inspect "${IMAGE}" > "${RESULT_ROOT}/image-inspect.json"
printf '%s\n' "${rocminfo_output}" > "${RESULT_ROOT}/rocminfo.txt"
amd-smi static -g all --json > "${RESULT_ROOT}/amd-smi-static.json"
amd-smi metric -g all --json > "${RESULT_ROOT}/amd-smi-metric-before.json"

case "${SCREEN_MODE}" in
  warp-stage)
    configs=(
      w1-s1 w1-s2 w1-s3 w1-s4
      w2-s1 w2-s2 w2-s3 w2-s4
      w4-s1 w4-s2 w4-s3 w4-s4
      w8-s1 w8-s2 w8-s3 w8-s4
    )
    ;;
  block-v)
    configs=(
      bv8-s3 bv16-s1 bv16-s2 bv16-s3
      bv16-s4 bv32-s3 bv64-s3 bv128-s3
    )
    ;;
  block-v-warp)
    configs=(
      w1-bv16-s2 w2-bv16-s2 w4-bv16-s2 w8-bv16-s2
      w1-bv32-s2 w2-bv32-s2 w4-bv32-s2 w8-bv32-s2
    )
    ;;
  block-v-paired)
    configs=()
    for round in 1 2 3 4; do
      for slot in {0..7}; do
        if ((round == 1 || round == 4)); then
          if ((slot % 2 == 0)); then
            block_v=16
          else
            block_v=32
          fi
        else
          if ((slot % 2 == 0)); then
            block_v=32
          else
            block_v=16
          fi
        fi
        configs+=("r${round}g${slot}__bv${block_v}-s3")
      done
    done
    ;;
  best-paired)
    configs=()
    for round in 1 2 3 4; do
      for slot in {0..7}; do
        if ((round == 1 || round == 4)); then
          if ((slot % 2 == 0)); then
            spec=w1-bv16-s2
          else
            spec=w4-bv32-s2
          fi
        else
          if ((slot % 2 == 0)); then
            spec=w4-bv32-s2
          else
            spec=w1-bv16-s2
          fi
        fi
        configs+=("r${round}g${slot}__${spec}")
      done
    done
    ;;
  normalization-paired)
    configs=()
    for round in 1 2 3 4; do
      for slot in {0..7}; do
        if ((round == 1 || round == 4)); then
          if ((slot % 2 == 0)); then
            spec=w1-bv16-s2-normdiv
          else
            spec=w1-bv16-s2-normrsqrt
          fi
        else
          if ((slot % 2 == 0)); then
            spec=w1-bv16-s2-normrsqrt
          else
            spec=w1-bv16-s2-normdiv
          fi
        fi
        configs+=("r${round}g${slot}__${spec}")
      done
    done
    ;;
  *)
    echo "unsupported SCREEN_MODE: ${SCREEN_MODE}" >&2
    exit 2
    ;;
esac
cpusets=(
  0-7 8-15 16-23 24-31
  64-71 72-79 80-87 88-95
)

run_config() {
  local config=$1
  local gpu=$2
  local cpuset=$3
  local spec warps stages block_v normalization config_root container rc
  spec=${config##*__}
  warps=1
  block_v=32
  normalization=div
  if [[ "${spec}" == *-norm* ]]; then
    normalization=${spec##*-norm}
  fi
  stages=${spec#*-s}
  stages=${stages%%-*}
  if [[ "${spec}" == w* ]]; then
    warps=${spec#w}
    warps=${warps%%-*}
    if [[ "${spec}" == *-bv* ]]; then
      block_v=${spec#*-bv}
      block_v=${block_v%%-*}
    fi
  else
    block_v=${spec#bv}
    block_v=${block_v%%-*}
  fi
  config_root=${RESULT_ROOT}/${config}
  container=netra-gdn-${RUN_ID,,}-${config}
  mkdir -p "${config_root}/triton-cache"
  set +e
  docker run --rm \
    --name "${container}" \
    --network=none \
    --device=/dev/kfd \
    --device=/dev/dri \
    --group-add video \
    --ipc=host \
    --shm-size=16g \
    --cpuset-cpus="${cpuset}" \
    -e HIP_VISIBLE_DEVICES="${gpu}" \
    -e PYTHONPATH=/netra-server/python \
    -e TRITON_CACHE_DIR=/results/triton-cache \
    -v "${SERVER_REPO}:/netra-server:ro" \
    -v "${KERNEL_REPO}:/netra-kernel:ro" \
    -v "${CAPTURE_DIR}:/capture:ro" \
    -v "${config_root}:/results" \
    "${IMAGE}" \
    python3 /netra-kernel/tools/benchmark/qwen36_gdn_verify_triton_variants.py \
      --capture-dir /capture \
      --output "/results/${config}.json" \
      --iterations "${ITERATIONS}" \
      --correctness-iterations "${CORRECTNESS_ITERATIONS}" \
      --correctness-policy "${CORRECTNESS_POLICY}" \
      --num-warps "${warps}" \
      --num-stages "${stages}" \
      --block-v "${block_v}" \
      --normalization "${normalization}" \
      > "${config_root}/stdout.json" \
      2> "${config_root}/stderr.log"
  rc=$?
  set -e
  printf '%s\n' "${rc}" > "${config_root}/exit-status.txt"
  return "${rc}"
}

failures=0
wave_count=$((( ${#configs[@]} + 7 ) / 8))
for ((wave = 0; wave < wave_count; wave++)); do
  pids=()
  labels=()
  remaining=$((${#configs[@]} - wave * 8))
  slots=$((remaining < 8 ? remaining : 8))
  for ((slot = 0; slot < slots; slot++)); do
    index=$((wave * 8 + slot))
    config=${configs[index]}
    run_config "${config}" "${slot}" "${cpusets[slot]}" &
    pids+=("$!")
    labels+=("${config}")
  done
  for ((slot = 0; slot < slots; slot++)); do
    if ! wait "${pids[slot]}"; then
      echo "${labels[slot]} failed; see its stderr.log" >&2
      failures=$((failures + 1))
    fi
  done
done

amd-smi metric -g all --json > "${RESULT_ROOT}/amd-smi-metric-after.json"
printf '%s\n' "${failures}" > "${RESULT_ROOT}/failure-count.txt"
printf '%s\n' "${RESULT_ROOT}"
if ((failures != 0)); then
  exit 1
fi
