#!/usr/bin/env bash

netra_build_gfx950_gdn_verify_b64_t12_h16_hv32_k128_v128_k0() {
  local repo_dir=$1
  local output_root=$2
  local script_dir=$3
  local output_namespace=$4

  NETRA_GDN_CORE_VARIANT=packed-pair-interleaved \
  NETRA_GDN_PRECOMPUTE_VARIANT=triton-exact \
  NETRA_GDN_K0_NO_INTERMEDIATE=1 \
  NETRA_GDN_WAVES_PER_WORKGROUP=1 \
  NETRA_GDN_SHARE_QK=1 \
  NETRA_GDN_DYNAMIC_WAVEGROUPS=1 \
    "${script_dir}/build_gfx950_gdn_verify_b64_t12_h16_hv32_k128_v128_k0.sh" \
    "$repo_dir" "${output_root}/${output_namespace}-gdn-verify-m12-batched"
}

netra_register_component \
  gdn-verify-b64-t12-h16-hv32-k128-v128-k0 \
  netra_build_gfx950_gdn_verify_b64_t12_h16_hv32_k128_v128_k0
