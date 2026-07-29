#!/usr/bin/env bash
set -euo pipefail

# Execute inside the Netra LXC.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
default_repo=$(cd "${script_dir}/../.." && pwd)
repo_dir=${1:-"${default_repo}"}
out_dir=${2:-"${repo_dir}/build/sglang"}
kernel_dir=${repo_dir}/kernels/gfx1151/mxfp4
integration_dir=${repo_dir}/integrations/sglang
rocm_dir=/opt/rocm-7.2.1
clang_bin=${rocm_dir}/llvm/bin/clang
hipcc_bin=${rocm_dir}/bin/hipcc

test -x "${clang_bin}"
test -x "${hipcc_bin}"
mkdir -p "${out_dir}"

sources=(
  serving/mxfp4_sgl_decode_gate_gfx1151.s
  serving/mxfp4_sgl_decode_down_gfx1151.s
  serving/mxfp4_sgl_reduce_gfx1151.s
  serving/mxfp4_sgl_linear_decode_gfx1151.s
  serving/mxfp4_sgl_linear_prefill_wmma_gfx1151.s
  prefill/mxfp4_prefill_gate_wmma_gfx1151.s
  prefill/mxfp4_prefill_down_wmma_gfx1151.s
  epilogue/silu_mul_bf16_gfx1151.s
)

for source_rel in "${sources[@]}"; do
  source_name=${source_rel##*/}
  stem=${source_name%.s}
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${kernel_dir}/prefill" -x assembler -c \
    "${kernel_dir}/${source_rel}" -o "${out_dir}/${stem}.o"
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
done

split_stem=qkvzba_split_copy_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c \
  "${repo_dir}/scripts/rocm/${split_stem}.s" \
  -o "${out_dir}/${split_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${split_stem}.o" -o "${out_dir}/${split_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${split_stem}.hsaco" > "${out_dir}/${split_stem}.dis"

attention_stem=extend_attention_wmma_n64_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c \
  "${repo_dir}/scripts/rocm/${attention_stem}.s" \
  -o "${out_dir}/${attention_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${attention_stem}.o" -o "${out_dir}/${attention_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${attention_stem}.hsaco" > "${out_dir}/${attention_stem}.dis"

pack_stem=expert_activation_pack_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c "${repo_dir}/scripts/rocm/${pack_stem}.s" \
  -o "${out_dir}/${pack_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${pack_stem}.o" -o "${out_dir}/${pack_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${pack_stem}.hsaco" > "${out_dir}/${pack_stem}.dis"

gdn_stem=gdn_chunk_o_bv32_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c "${repo_dir}/scripts/rocm/${gdn_stem}.s" \
  -o "${out_dir}/${gdn_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${gdn_stem}.o" -o "${out_dir}/${gdn_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${gdn_stem}.hsaco" > "${out_dir}/${gdn_stem}.dis"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_HSACO_DIR="\"${out_dir}\"" \
  "${integration_dir}/netra_mxfp4_sgl_launcher.hip" \
  -o "${out_dir}/libnetra_mxfp4_sgl.so"

echo "Built Netra SGLang raw-ASM backend for gfx1151 in ${out_dir}"
