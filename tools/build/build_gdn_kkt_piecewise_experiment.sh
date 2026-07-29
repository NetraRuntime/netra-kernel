#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments"}
clang=/opt/rocm-7.2.1/llvm/bin/clang
hipcc=/opt/rocm-7.2.1/bin/hipcc
for stem in gdn_kkt_build_fp32_gfx1151 gdn_kkt_build_fp32_compiler_frag_gfx1151; do
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
    "${repo_dir}/kernels/gfx1151/gdn/experiments/${stem}.s" -o "${out_dir}/${stem}.o"
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  /opt/rocm-7.2.1/llvm/bin/llvm-objdump -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
done
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/integrations/sglang/experiments/gdn_kkt_build_bridge.hip" \
  -o "${out_dir}/libgdn_kkt_build.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/integrations/sglang/experiments/gdn_kkt_build_compiler_frag_bridge.hip" \
  -o "${out_dir}/libgdn_kkt_build_compiler_frag.so"
echo "Built rejected split and exact gfx1151 GDN KKT builders in ${out_dir}"
