#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-gdn-fused-h-o-m8192-experiment"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
source_file=${NETRA_FUSED_GDN_SOURCE:-${repo_dir}/kernels/gfx950/linear_attention/prefill/experiments/qwen36_gdn_fused_h_o_m8192_bv16_gfx950.s}
bridge=${repo_dir}/harness/gfx950/linear_attention/prefill/qwen36_gdn_fused_h_o_m8192_bridge.hip
stem=$(basename "${source_file%.s}")

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

assembler_flags=(-target amdgcn-amd-amdhsa -mcpu=gfx950 -mwavefrontsize64 -x assembler)
if [[ -n ${NETRA_FUSED_GDN_DEFSYM:-} ]]; then
  assembler_flags+=("-Wa,-defsym,${NETRA_FUSED_GDN_DEFSYM}=1")
fi
"${rocm_dir}/llvm/bin/clang" "${assembler_flags[@]}" -c "$source_file" \
  -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"

grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
grep -q 'private_segment_fixed_size:[[:space:]]*0' "${out_dir}/${stem}.metadata.txt"
grep -q 'v_mfma_f32_16x16x32_bf16' "${out_dir}/${stem}.disassembly.txt"

"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "$bridge" \
  -o "${out_dir}/libqwen36_gdn_fused_h_o_m8192_bridge.so"

sha256sum "$source_file" "$bridge" "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libqwen36_gdn_fused_h_o_m8192_bridge.so" \
  > "${out_dir}/sha256sums.txt"
{
  printf 'target=gfx950\nwavefront_size=64\n'
  if [[ $stem == *_n16_t1024_bv64_* ]]; then
    printf 'shape=B16_T16384_16x1024_H32_Hg16_K128_V128_BT64_BV64\n'
    printf 'grid=2x512x1\nblock=256x1x1\nfixed_lds_bytes=40960\n'
  elif [[ $stem == *_n16_t1024_bv32_* ]]; then
    printf 'shape=B16_T16384_16x1024_H32_Hg16_K128_V128_BT64_BV32\n'
    printf 'grid=4x512x1\nblock=256x1x1\nfixed_lds_bytes=24576\n'
  elif [[ $stem == *_bv32_* ]]; then
    printf 'shape=B1_T8192_H32_Hg16_K128_V128_BT64_BV32\n'
    printf 'grid=4x32x1\nblock=256x1x1\nfixed_lds_bytes=24576\n'
  else
    printf 'shape=B1_T8192_H32_Hg16_K128_V128_BT64_BV16\n'
    printf 'grid=8x32x1\nblock=256x1x1\nfixed_lds_bytes=18432\n'
  fi
  printf 'status=rejected_full_path_experiment\n'
  printf 'defsym=%s\n' "${NETRA_FUSED_GDN_DEFSYM:-none}"
} > "${out_dir}/build-variant.txt"

printf 'gfx950 Qwen fused GDN experiment build complete: %s\n' "$out_dir"
