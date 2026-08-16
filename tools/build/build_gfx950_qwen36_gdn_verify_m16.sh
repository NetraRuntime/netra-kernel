#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/lib/gfx950_assembly.sh"
source "${script_dir}/lib/gdn_variants.sh"
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-gdn-verify-m16"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
kernel_dir=${repo_dir}/kernels/gfx950/linear_attention/verify
precompute_stem=qwen36_gdn_verify_m16_precompute_gfx950
core_stem=qwen36_gdn_verify_m16_precomputed_bv16_gfx950
precompute=${kernel_dir}/${precompute_stem}.s
core=${kernel_dir}/${core_stem}.s
harness=${repo_dir}/harness/gfx950/linear_attention/verify/qwen36_gdn_verify_m16_raw_pipeline_gfx950.hip
core_harness=${repo_dir}/harness/gfx950/linear_attention/verify/qwen36_gdn_verify_m16_precomputed_gfx950.hip
bridge=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_verify_m16_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_verify_m16_bridge.h
core_variant=${NETRA_GDN_CORE_VARIANT:-fused-packed-decode-sequence}
precompute_variant=${NETRA_GDN_PRECOMPUTE_VARIANT:-packed-decode-beta}

core_variant_id=$(netra_gdn_core_variant_id "$core_variant" m16)
precompute_variant_id=$(netra_gdn_precompute_variant_id "$precompute_variant")

mkdir -p "$out_dir"
netra_gfx950_require_device

netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" \
  "$precompute" "$precompute_stem" \
  -Wa,-defsym,NETRA_GDN_PRECOMPUTE_VARIANT="$precompute_variant_id"
netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" \
  "$core" "$core_stem" \
  -Wa,-defsym,NETRA_GDN_CORE_VARIANT="$core_variant_id"
grep -q 'v_exp_f32' "${out_dir}/${precompute_stem}.disassembly.txt"
grep -q 'v_log_f32' "${out_dir}/${precompute_stem}.disassembly.txt"
grep -q 'v_sqrt_f32' "${out_dir}/${precompute_stem}.disassembly.txt"
grep -q 'v_pk_fma_f32' "${out_dir}/${core_stem}.disassembly.txt"
if [[ "$core_variant_id" == 0 || "$core_variant_id" == 3 ]]; then
  grep -q 'ds_bpermute_b32' "${out_dir}/${core_stem}.disassembly.txt"
else
  ! grep -q 'ds_bpermute_b32' "${out_dir}/${core_stem}.disassembly.txt"
  grep -q 'row_shl:8' "${out_dir}/${core_stem}.disassembly.txt"
  grep -q 'quad_perm:\[2,3,0,1\]' \
    "${out_dir}/${core_stem}.disassembly.txt"
fi

harness_binary=${out_dir}/qwen36_gdn_verify_m16_raw_pipeline_harness
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 \
  "$harness" -o "$harness_binary"

core_harness_binary=${out_dir}/qwen36_gdn_verify_m16_precomputed_harness
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 \
  "$core_harness" -o "$core_harness_binary"

bridge_library=${out_dir}/libqwen36_gdn_verify_m16_bridge.so
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "$bridge" -o "$bridge_library"

sha256sum \
  "$precompute" \
  "$core" \
  "$harness" \
  "$core_harness" \
  "$bridge" \
  "$bridge_header" \
  "${out_dir}/${precompute_stem}.hsaco" \
  "${out_dir}/${core_stem}.hsaco" \
  "$harness_binary" \
  "$core_harness_binary" \
  "$bridge_library" \
  > "${out_dir}/sha256sums.txt"

{
  printf 'core_variant=%s\n' "$core_variant"
  printf 'core_variant_id=%s\n' "$core_variant_id"
  printf 'precompute_variant=%s\n' "$precompute_variant"
  printf 'precompute_variant_id=%s\n' "$precompute_variant_id"
  printf 'target=gfx950\nwavefront_size=64\n'
} > "${out_dir}/build-variant.txt"

echo "gfx950 Qwen GDN M16 verify pipeline build complete: ${out_dir}"
