#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(git -C "${script_dir}" rev-parse --show-toplevel)
out_dir=${1:-"${repo_dir}/build/experiments"}
clang=/opt/rocm-7.2.1/llvm/bin/clang
hipcc=/opt/rocm-7.2.1/bin/hipcc
mkdir -p "${out_dir}"
for stem in gdn_kkt_build_fp32_gfx1151 gdn_kkt_build_fp32_compiler_frag_gfx1151; do
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
    "${repo_dir}/kernels/gfx1151/gdn/experiments/${stem}.s" -o "${out_dir}/${stem}.o"
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  /opt/rocm-7.2.1/llvm/bin/llvm-objdump -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
done
blockwise_stem=gdn_kkt_solve_blockwise_gfx1151
"${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
  "${repo_dir}/kernels/gfx1151/gdn/experiments/${blockwise_stem}.s" \
  -o "${out_dir}/${blockwise_stem}.o"
"${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${blockwise_stem}.o" -o "${out_dir}/${blockwise_stem}.hsaco"
/opt/rocm-7.2.1/llvm/bin/llvm-objdump -d --mcpu=gfx1151 \
  "${out_dir}/${blockwise_stem}.hsaco" > "${out_dir}/${blockwise_stem}.dis"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/scripts/rocm/integrations/sglang/experiments/gdn_kkt_blockwise_bridge.hip" \
  -o "${out_dir}/libgdn_kkt_blockwise.so"
"${hipcc}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/gdn/benchmark_gdn_kkt_blockwise.hip" \
  -o "${out_dir}/benchmark_gdn_kkt_blockwise"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/scripts/rocm/integrations/sglang/experiments/gdn_kkt_build_bridge.hip" \
  -o "${out_dir}/libgdn_kkt_build.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/scripts/rocm/integrations/sglang/experiments/gdn_kkt_build_compiler_frag_bridge.hip" \
  -o "${out_dir}/libgdn_kkt_build_compiler_frag.so"
echo "Built rejected split, exact builder, and blockwise gfx1151 GDN KKT experiments in ${out_dir}"
