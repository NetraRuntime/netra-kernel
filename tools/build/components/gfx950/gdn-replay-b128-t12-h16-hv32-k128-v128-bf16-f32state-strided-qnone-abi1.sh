#!/usr/bin/env bash

netra_build_gfx950_gdn_replay_b128_t12_h16_hv32_k128_v128_bf16_f32state_strided_qnone_abi1() {
  local repo_dir=$1
  local output_root=$2
  local script_dir=$3
  local output_namespace=$4

  "${script_dir}/build_gfx950_gdn_replay_b128_t12_h16_hv32_k128_v128_bf16_f32state_strided_qnone_abi1.sh" \
    "$repo_dir" "${output_root}/${output_namespace}-gdn-state-replay-m12"
}

netra_register_component \
  gdn-replay-b128-t12-h16-hv32-k128-v128-bf16-f32state-strided-qnone-abi1 \
  netra_build_gfx950_gdn_replay_b128_t12_h16_hv32_k128_v128_bf16_f32state_strided_qnone_abi1
