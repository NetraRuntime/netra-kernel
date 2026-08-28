#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_dir=${ROCM_PATH:-/opt/rocm}
out_dir=${1:?usage: build_gfx950_dsv4_dspark_greedy_accept.sh OUTPUT_DIR}
stem=dsv4_dspark_greedy_accept_gfx950
source_file=${repo_dir}/kernels/gfx950/sampling/verify/${stem}.s
bridge=${repo_dir}/runtime/gfx950/sampling/verify/dsv4_dspark_greedy_accept_bridge.hip

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
  "${bridge}" -I"${repo_dir}/runtime/gfx950/sampling/verify" \
  -o "${out_dir}/libdsv4_dspark_greedy_accept_bridge.so"

sha256sum \
  "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libdsv4_dspark_greedy_accept_bridge.so" \
  > "${out_dir}/sha256sums.txt"
