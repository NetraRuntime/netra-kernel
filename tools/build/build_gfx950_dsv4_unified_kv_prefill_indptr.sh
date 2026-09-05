#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_dir=${ROCM_PATH:-/opt/rocm}
out_dir=${1:?usage: build_gfx950_dsv4_unified_kv_prefill_indptr.sh OUTPUT_DIR}
stem=unified_kv_prefill_indptr_i64_i32_gfx950
source_file=${repo_dir}/kernels/gfx950/attention/dsv4/${stem}.hip
bridge=${repo_dir}/runtime/gfx950/attention/dsv4/unified_kv_prefill_indptr_i64_i32_bridge.hip
bundle=${out_dir}/${stem}.hipfb

mkdir -p "${out_dir}"
"${rocm_dir}/bin/hipcc" --genco --offload-arch=gfx950 -O3 -std=c++17 \
  "${source_file}" -o "${bundle}"
"${rocm_dir}/llvm/bin/clang-offload-bundler" --unbundle --type=o \
  --targets=hipv4-amdgcn-amd-amdhsa--gfx950 \
  --input="${bundle}" --output="${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes --symbols \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.metadata.txt"

"${rocm_dir}/bin/hipcc" -O2 -std=c++17 -fPIC -shared \
  "${bridge}" -I"${repo_dir}/runtime/gfx950/attention/dsv4" \
  -o "${out_dir}/libdsv4_unified_kv_prefill_indptr_bridge.so"

sha256sum \
  "${bundle}" \
  "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libdsv4_unified_kv_prefill_indptr_bridge.so" \
  > "${out_dir}/sha256sums.txt"
