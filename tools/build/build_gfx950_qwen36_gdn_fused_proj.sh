#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_dir=${ROCM_PATH:-/opt/rocm}
out_dir=${1:?usage: build_gfx950_qwen36_gdn_fused_proj.sh OUTPUT_DIR}
stem=qwen36_gdn_fused_proj_bf16_gfx950
source_file=${repo_dir}/kernels/gfx950/linear_attention/prefill/${stem}.s
bridge=${repo_dir}/runtime/gfx950/linear_attention/prefill/qwen36_gdn_fused_proj_bridge.hip
harness=${repo_dir}/harness/gfx950/linear_attention/prefill/qwen36_gdn_fused_proj_gfx950.hip

mkdir -p "${out_dir}"
"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -c "${source_file}" -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes --symbols \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.metadata.txt"

"${rocm_dir}/bin/hipcc" -O2 -std=c++17 -fPIC -shared \
  "${bridge}" -I"${repo_dir}/runtime/gfx950/linear_attention/prefill" \
  -o "${out_dir}/libqwen36_gdn_fused_proj_bridge.so"
"${rocm_dir}/bin/hipcc" -O2 -std=c++17 \
  "${harness}" "${bridge}" \
  -I"${repo_dir}/runtime/gfx950/linear_attention/prefill" \
  -o "${out_dir}/qwen36_gdn_fused_proj_gfx950"

sha256sum \
  "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libqwen36_gdn_fused_proj_bridge.so" \
  "${out_dir}/qwen36_gdn_fused_proj_gfx950" \
  > "${out_dir}/sha256sums.txt"
