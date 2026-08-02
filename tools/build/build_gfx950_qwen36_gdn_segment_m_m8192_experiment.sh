#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-gdn-segment-m-seg32-hilo-v2"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
source_file=${repo_dir}/kernels/gfx950/linear_attention/prefill/experiments/qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950.s
bridge=${repo_dir}/harness/gfx950/linear_attention/prefill/qwen36_gdn_segment_m_m8192_bridge.hip
stem=qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mwavefrontsize64 -x assembler -c "$source_file" \
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
grep -q 'group_segment_fixed_size:[[:space:]]*20480' "${out_dir}/${stem}.metadata.txt"
grep -q 'v_mfma_f32_16x16x32_bf16' "${out_dir}/${stem}.disassembly.txt"

"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "$bridge" -o "${out_dir}/libqwen36_gdn_segment_m_m8192_bridge.so"

sha256sum "$source_file" "$bridge" "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libqwen36_gdn_segment_m_m8192_bridge.so" \
  > "${out_dir}/sha256sums.txt"
{
  printf 'target=gfx950\nwavefront_size=64\n'
  printf 'shape=B1_T8192_H32_Hg16_K128_V128_BT64_segments4_chunks32\n'
  printf 'grid=32x32x1\nblock=256x1x1\nfixed_lds_bytes=20480\n'
  printf 'status=rejected_transition_overhead\n'
} > "${out_dir}/build-variant.txt"

printf 'gfx950 Qwen GDN segment-transition experiment built: %s\n' "$out_dir"
