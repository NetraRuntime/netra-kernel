#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
out_dir=${1:?usage: build_gfx950_dsv4_router_shared_topk_bf16_v1.sh OUTPUT_DIR}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=dsv4_router_shared_topk_bf16_v1_gfx950
bundle=${out_dir}/${stem}.hipfb
kernel=${repo_dir}/kernels/gfx950/routing/verify/${stem}.hip
bridge=${repo_dir}/runtime/gfx950/routing/verify/dsv4_router_shared_topk_bf16_v1_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/routing/verify/dsv4_router_shared_topk_bf16_v1_bridge.h

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

"${rocm_dir}/bin/hipcc" --genco --offload-arch=gfx950 -O3 -std=c++17 \
  "$kernel" -o "$bundle"
"${rocm_dir}/llvm/bin/clang-offload-bundler" --unbundle --type=o \
  --targets=hipv4-amdgcn-amd-amdhsa--gfx950 \
  --input="$bundle" --output="${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'netra_dsv4_router_shared_topk_bf16_v1_gfx950' \
  "${out_dir}/${stem}.disassembly.txt"

"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared \
  "$bridge" -o "${out_dir}/libdsv4_router_shared_topk_bf16_v1_bridge.so"

sha256sum \
  "$bundle" \
  "${out_dir}/${stem}.hsaco" \
  "${out_dir}/${stem}.disassembly.txt" \
  "${out_dir}/${stem}.metadata.txt" \
  "${out_dir}/libdsv4_router_shared_topk_bf16_v1_bridge.so" \
  > "${out_dir}/sha256sums.txt"
