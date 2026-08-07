#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-gdn-causal-conv-m8192"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_gdn_causal_conv_m8192_bm32_gfx950
source_file=${repo_dir}/kernels/gfx950/linear_attention/prefill/experiments/${stem}.s
bridge=${repo_dir}/runtime/gfx950/linear_attention/prefill/qwen36_gdn_causal_conv_m8192_bridge.hip
header=${repo_dir}/runtime/gfx950/linear_attention/prefill/qwen36_gdn_causal_conv_m8192_bridge.h

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
grep -q 'private_segment_fixed_size:[[:space:]]*0' \
  "${out_dir}/${stem}.metadata.txt"
grep -q 'vgpr_spill_count:[[:space:]]*0' "${out_dir}/${stem}.metadata.txt"
grep -q 'v_exp_f32' "${out_dir}/${stem}.disassembly.txt"
grep -q 'v_div_fixup_f32' "${out_dir}/${stem}.disassembly.txt"
! grep -q 's_barrier' "${out_dir}/${stem}.disassembly.txt"

library=${out_dir}/libqwen36_gdn_causal_conv_m8192_bridge.so
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "$bridge" -o "$library"
nm -D "$library" | grep -q 'netra_qwen36_gdn_causal_conv_m8192_launch'

sha256sum "$source_file" "$bridge" "$header" "${out_dir}/${stem}.hsaco" \
  "$library" > "${out_dir}/sha256sums.txt"
printf 'target=gfx950\nwavefront_size=64\nshape=B1,M8192,D8192,W4\n' \
  > "${out_dir}/build-variant.txt"
echo "gfx950 Qwen GDN M8192 causal convolution build complete: ${out_dir}"
