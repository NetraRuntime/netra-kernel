#!/usr/bin/env bash

netra_build_gfx950_moe_decode_fp8_e4m3_h2048_i512_top9_block128_aiter() {
  local repo_dir=$1
  local output_root=$2
  local script_dir=$3
  local output_namespace=$4

  "${script_dir}/build_gfx950_moe_decode_fp8_e4m3_h2048_i512_top9_block128_aiter.sh" \
    "$repo_dir" "${output_root}/${output_namespace}-fp8"
}

netra_register_component \
  moe-decode-fp8-e4m3-h2048-i512-top9-block128-aiter \
  netra_build_gfx950_moe_decode_fp8_e4m3_h2048_i512_top9_block128_aiter
