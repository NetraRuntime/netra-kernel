#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
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
core_variant=${NETRA_GDN_CORE_VARIANT:-fused-exact}
precompute_variant=${NETRA_GDN_PRECOMPUTE_VARIANT:-triton-exact}

case "$core_variant" in
  original) core_variant_id=0 ;;
  triton) core_variant_id=1 ;;
  forward-xor) core_variant_id=2 ;;
  reverse-scan) core_variant_id=3 ;;
  balanced-xor) core_variant_id=4 ;;
  forward-k-forward-q-fma) core_variant_id=5 ;;
  forward-k-reverse-q-fma) core_variant_id=6 ;;
  forward-k-reverse-q-add) core_variant_id=7 ;;
  forward-k-balanced-q-add) core_variant_id=8 ;;
  fused-exact) core_variant_id=13 ;;
  forward-k-q-fma-10234567) core_variant_id=9 ;;
  forward-k-q-fma-10325476) core_variant_id=10 ;;
  forward-k-q-fma-76452301) core_variant_id=11 ;;
  forward-k-q-fma-76543210) core_variant_id=12 ;;
  fused-packed-exact) core_variant_id=13 ;;
  *)
    echo "Unsupported NETRA_GDN_CORE_VARIANT: $core_variant" >&2
    exit 2
    ;;
esac

case "$precompute_variant" in
  original) precompute_variant_id=0 ;;
  triton-reduce-rcp) precompute_variant_id=1 ;;
  triton-div) precompute_variant_id=2 ;;
  original-reduce-div) precompute_variant_id=3 ;;
  triton-div-no-fixup) precompute_variant_id=4 ;;
  triton-contiguous-exact) precompute_variant_id=5 ;;
  triton-contiguous-exact-gates) precompute_variant_id=6 ;;
  triton-exact) precompute_variant_id=7 ;;
  *)
    echo "Unsupported NETRA_GDN_PRECOMPUTE_VARIANT: $precompute_variant" >&2
    exit 2
    ;;
esac

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

build_kernel() {
  local source_file=$1
  local stem=$2
  shift 2
  "${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -mwavefrontsize64 -x assembler "$@" -c "$source_file" \
    -o "${out_dir}/${stem}.o"
  "${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
  "${rocm_dir}/llvm/bin/llvm-readobj" --notes \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.metadata.txt"
  grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
  grep -q 'private_segment_fixed_size:[[:space:]]*0' \
    "${out_dir}/${stem}.metadata.txt"
}

build_kernel "$precompute" "$precompute_stem" \
  -Wa,-defsym,NETRA_GDN_PRECOMPUTE_VARIANT="$precompute_variant_id"
build_kernel "$core" "$core_stem" \
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
