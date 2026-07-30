#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside Netra" >&2; exit 1; }
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments/prefill-gate-group4-a"}
rocm=/opt/rocm-7.2.1
mkdir -p "${out_dir}"
for stem in mxfp4_prefill_gate_dword_layout_gfx1151 mxfp4_prefill_gate_group4_a_gfx1151; do
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
    "${repo_dir}/kernels/gfx1151/mxfp4/prefill/experiments/${stem}.s" -o "${out_dir}/${stem}.o"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 "${out_dir}/${stem}.hsaco" >"${out_dir}/${stem}.dis"
done
stem=mxfp4_prefill_repack_dword_gfx1151
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
  "${repo_dir}/kernels/gfx1151/mxfp4/prefill/${stem}.s" -o "${out_dir}/${stem}.o"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/mxfp4/prefill/benchmark_prefill_gate_group4_a.hip" \
  -o "${out_dir}/benchmark_prefill_gate_group4_a"
echo "Built gfx1151 prefill gate group4-A experiment in ${out_dir}"
