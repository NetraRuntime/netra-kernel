#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside Netra" >&2; exit 1; }
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments/linear-prefill-group4-a"}
rocm=/opt/rocm-7.2.1
mkdir -p "${out_dir}"
build_asm() {
  local source=$1 stem=$2
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${repo_dir}/kernels/gfx1151/mxfp4/prefill" -x assembler -c \
    "${source}" -o "${out_dir}/${stem}.o"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" >"${out_dir}/${stem}.dis"
}
build_asm "${repo_dir}/kernels/gfx1151/mxfp4/serving/mxfp4_sgl_linear_prefill_wmma_gfx1151.s" mxfp4_sgl_linear_prefill_wmma_gfx1151
build_asm "${repo_dir}/kernels/gfx1151/mxfp4/serving/experiments/mxfp4_sgl_linear_prefill_group4_a_gfx1151.s" mxfp4_sgl_linear_prefill_group4_a_gfx1151
build_asm "${repo_dir}/kernels/gfx1151/mxfp4/serving/mxfp4_sgl_linear_prefill_repack_dword_gfx1151.s" mxfp4_sgl_linear_prefill_repack_dword_gfx1151
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/mxfp4/serving/benchmark_linear_prefill_group4_a.hip" \
  -o "${out_dir}/benchmark_linear_prefill_group4_a"
echo "Built gfx1151 linear-prefill group4-A experiment in ${out_dir}"
