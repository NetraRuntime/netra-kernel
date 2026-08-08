#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-qkvzba-split-copy"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_qkvzba_split_copy_bf16_x64_gfx950
source_file=${repo_dir}/kernels/gfx950/linear_attention/common/${stem}.s
bridge=${repo_dir}/runtime/gfx950/linear_attention/common/qwen36_qkvzba_split_copy_bridge.hip

command -v "${rocm_dir}/llvm/bin/clang" >/dev/null
command -v "${rocm_dir}/llvm/bin/llvm-objdump" >/dev/null
command -v "${rocm_dir}/bin/hipcc" >/dev/null
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_text}"
mkdir -p "${out_dir}"

"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mwavefrontsize64 -x assembler -c "${source_file}" \
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
grep -q 'group_segment_fixed_size:[[:space:]]*0' \
  "${out_dir}/${stem}.metadata.txt"
grep -q 'global_load_dwordx4' "${out_dir}/${stem}.disassembly.txt"
grep -q 'global_store_dwordx4' "${out_dir}/${stem}.disassembly.txt"
! grep -qE 's_barrier|ds_read|ds_write|scratch_' \
  "${out_dir}/${stem}.disassembly.txt"

"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "${bridge}" \
  -o "${out_dir}/libqwen36_qkvzba_split_copy_bridge.so"

sha256sum \
  "${source_file}" \
  "${bridge}" \
  "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libqwen36_qkvzba_split_copy_bridge.so" \
  > "${out_dir}/sha256sums.txt"

printf 'gfx950 Qwen QKVZ/BA split-copy build complete: %s\n' "${out_dir}"
