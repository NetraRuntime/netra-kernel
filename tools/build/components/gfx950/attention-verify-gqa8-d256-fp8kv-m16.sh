#!/usr/bin/env bash

netra_build_gfx950_attention_verify_gqa8_d256_fp8kv_m16() {
  local repo_dir=$1
  local output_root=$2
  local script_dir=$3
  local output_namespace=$4

  OUTPUT_DIR="${output_root}/${output_namespace}-extend-attention-gqa8-fp8kv" \
    "${script_dir}/build_gfx950_attention_verify_gqa8_d256_fp8kv_m16.sh"
}

netra_register_component \
  attention-verify-gqa8-d256-fp8kv-m16 \
  netra_build_gfx950_attention_verify_gqa8_d256_fp8kv_m16
