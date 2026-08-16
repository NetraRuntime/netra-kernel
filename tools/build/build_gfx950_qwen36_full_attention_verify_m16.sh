#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/lib/gfx950_assembly.sh"
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-full-attention-verify-m16"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
kernel_dir=${repo_dir}/kernels/gfx950/attention/verify
runtime_dir=${repo_dir}/runtime/gfx950/attention/verify
prepare_stem=qwen36_full_attention_verify_prepare_m16_gfx950
stage1_stem=qwen36_full_attention_verify_m16_stage1_gfx950
stage2_stem=qwen36_full_attention_verify_m16_stage2_gfx950
prepare=${kernel_dir}/${prepare_stem}.s
stage1=${kernel_dir}/${stage1_stem}.s
stage2=${kernel_dir}/${stage2_stem}.s
bridge=${runtime_dir}/qwen36_full_attention_verify_m16_bridge.hip
bridge_header=${runtime_dir}/qwen36_full_attention_verify_m16_bridge.h

mkdir -p "$out_dir"
netra_gfx950_require_device

netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" "$prepare" "$prepare_stem"
netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" "$stage1" "$stage1_stem"
netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" "$stage2" "$stage2_stem"
grep -q 'v_mfma_f32_16x16x32_fp8_fp8' \
  "${out_dir}/${stage1_stem}.disassembly.txt"
grep -q "$prepare_stem" "${out_dir}/${prepare_stem}.metadata.txt"
grep -q "$stage1_stem" "${out_dir}/${stage1_stem}.metadata.txt"
grep -q "$stage2_stem" "${out_dir}/${stage2_stem}.metadata.txt"

bridge_library=${out_dir}/libqwen36_full_attention_verify_m16_bridge.so
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "$bridge" -o "$bridge_library"

sha256sum \
  "$prepare" \
  "$stage1" \
  "$stage2" \
  "$bridge" \
  "$bridge_header" \
  "${out_dir}/${prepare_stem}.hsaco" \
  "${out_dir}/${stage1_stem}.hsaco" \
  "${out_dir}/${stage2_stem}.hsaco" \
  "$bridge_library" \
  >"${out_dir}/sha256sums.txt"

{
  printf 'target=gfx950\n'
  printf 'wavefront_size=64\n'
  printf 'verify_tokens=1..16\n'
  printf 'prepare_grid=1x1x1,workgroup=64\n'
  printf 'query_heads=16\n'
  printf 'kv_heads=2\n'
  printf 'head_dim=256\n'
  printf 'kv_dtype=fp8_e4m3\n'
  printf 'max_kv_splits=129\n'
  printf 'stage1_grid=Mx2x129\n'
  printf 'stage2_grid=Mx16x1\n'
  printf 'workgroup_size=256\n'
  printf 'stage1_dynamic_lds_bytes=8192\n'
} >"${out_dir}/build-contract.txt"

echo "gfx950 Qwen full-attention M16 verify build complete: ${out_dir}"
