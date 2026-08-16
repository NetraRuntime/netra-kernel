#!/usr/bin/env bash

netra_build_gfx950_gdn_replay_b64_t12_h16_hv32_k128_v128() {
  local repo_dir=$1
  local output_root=$2
  local script_dir=$3
  local output_namespace=$4

  "${script_dir}/build_gfx950_gdn_replay_b64_t12_h16_hv32_k128_v128.sh" \
    "$repo_dir" "${output_root}/${output_namespace}-gdn-state-replay-m12"
}

netra_register_component \
  gdn-replay-b64-t12-h16-hv32-k128-v128 \
  netra_build_gfx950_gdn_replay_b64_t12_h16_hv32_k128_v128
