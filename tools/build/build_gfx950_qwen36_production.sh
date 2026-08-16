#!/usr/bin/env bash
set -euo pipefail

# Canonical MI350X Qwen3.6 DFlash kernel bundle.
#
# Add promoted components here instead of creating another bundle script. The
# component builders remain independently usable for kernel development.

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "${script_dir}/../.." && pwd)
output_root=${NETRA_BUILD_ROOT:-${repo_dir}/build}
action=${1:-all}

components=(
  fp8-decode
  router-bf16
  target-attention-gqa8-fp8kv
  gdn-verify-m12-k0
  gdn-state-replay-m12
)

list_components() {
  printf '%s\n' "${components[@]}"
}

build_component() {
  local component=$1

  case "$component" in
    fp8-decode)
      "${script_dir}/build_gfx950_qwen36_fp8_raw.sh" \
        "$repo_dir" "${output_root}/gfx950-qwen36-fp8"
      ;;
    router-bf16)
      "${script_dir}/build_gfx950_qwen36_router_bf16.sh" \
        "$repo_dir" "${output_root}/gfx950-qwen36-router-bf16"
      ;;
    target-attention-gqa8-fp8kv)
      OUTPUT_DIR="${output_root}/gfx950-qwen36-extend-attention-gqa8-fp8kv" \
        "${script_dir}/build_gfx950_qwen36_extend_attention_gqa8_fp8kv.sh"
      ;;
    gdn-verify-m12-k0)
      NETRA_GDN_CORE_VARIANT=packed-pair-interleaved \
      NETRA_GDN_PRECOMPUTE_VARIANT=triton-exact \
      NETRA_GDN_K0_NO_INTERMEDIATE=1 \
      NETRA_GDN_WAVES_PER_WORKGROUP=1 \
      NETRA_GDN_SHARE_QK=1 \
      NETRA_GDN_DYNAMIC_WAVEGROUPS=1 \
        "${script_dir}/build_gfx950_qwen36_gdn_verify_m12_batched.sh" \
        "$repo_dir" "${output_root}/gfx950-qwen36-gdn-verify-m12-batched"
      ;;
    gdn-state-replay-m12)
      "${script_dir}/build_gfx950_qwen36_gdn_state_replay_m12.sh" \
        "$repo_dir" "${output_root}/gfx950-qwen36-gdn-state-replay-m12"
      ;;
    *)
      echo "unknown production component: $component" >&2
      return 2
      ;;
  esac
}

case "$action" in
  list)
    list_components
    ;;
  all)
    for component in "${components[@]}"; do
      build_component "$component"
    done
    ;;
  *)
    build_component "$action"
    ;;
esac
