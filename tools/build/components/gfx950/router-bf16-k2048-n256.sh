#!/usr/bin/env bash

netra_build_gfx950_router_bf16_k2048_n256() {
  local repo_dir=$1
  local output_root=$2
  local script_dir=$3
  local output_namespace=$4

  "${script_dir}/build_gfx950_router_bf16_k2048_n256.sh" \
    "$repo_dir" "${output_root}/${output_namespace}-router-bf16"
}

netra_register_component \
  router-bf16-k2048-n256 \
  netra_build_gfx950_router_bf16_k2048_n256
