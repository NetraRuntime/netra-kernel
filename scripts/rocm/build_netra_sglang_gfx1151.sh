#!/usr/bin/env bash
set -euo pipefail

# Execute inside the Netra LXC.
repo_dir=${1:-/root/netra-mxfp4-gfx1151}
out_dir=${2:-"${repo_dir}/build/sglang"}
rocm_dir=/opt/rocm-7.2.1
clang_bin=${rocm_dir}/llvm/bin/clang
hipcc_bin=${rocm_dir}/bin/hipcc

test -x "${clang_bin}"
test -x "${hipcc_bin}"
mkdir -p "${out_dir}"

sources=(
  mxfp4_sgl_decode_gate_gfx1151.s
  mxfp4_sgl_decode_down_gfx1151.s
  mxfp4_sgl_reduce_gfx1151.s
  mxfp4_sgl_linear_decode_gfx1151.s
  mxfp4_sgl_linear_prefill_wmma_gfx1151.s
  mxfp4_prefill_gate_wmma_gfx1151.s
  mxfp4_prefill_down_wmma_gfx1151.s
  silu_mul_bf16_gfx1151.s
)

for source_name in "${sources[@]}"; do
  stem=${source_name%.s}
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${repo_dir}/scripts/rocm" -x assembler -c \
    "${repo_dir}/scripts/rocm/${source_name}" \
    -o "${out_dir}/${stem}.o"
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
done

"${hipcc_bin}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_HSACO_DIR="\"${out_dir}\"" \
  "${repo_dir}/scripts/rocm/netra_mxfp4_sgl_launcher.hip" \
  -o "${out_dir}/libnetra_mxfp4_sgl.so"

echo "Built Netra SGLang raw-ASM backend for gfx1151 in ${out_dir}"
