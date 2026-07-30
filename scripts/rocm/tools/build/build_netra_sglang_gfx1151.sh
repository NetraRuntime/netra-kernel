#!/usr/bin/env bash
set -euo pipefail

# Execute inside the Netra LXC.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
default_repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
repo_dir=${1:-"${default_repo}"}
out_dir=${2:-"${repo_dir}/build/sglang"}
kernel_dir=${repo_dir}/kernels/gfx1151/mxfp4
integration_dir=${repo_dir}/scripts/rocm/integrations/sglang
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
  serving/mxfp4_sgl_linear_prefill_repack_dword_gfx1151.s
  prefill/mxfp4_prefill_gate_wmma_gfx1151.s
  prefill/mxfp4_prefill_repack_dword_gfx1151.s
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

script_mxfp4_sources=(
  mxfp4_prefill_up_silu_wmma_gfx1151.s
  mxfp4_sgl_linear_prefill_group4_a_gfx1151.s
  mxfp4_m12_group_gate_wmma_gfx1151.s
  mxfp4_m12_group_gate_up_wmma_gfx1151.s
  mxfp4_m12_group_gate_up_silu_wmma_gfx1151.s
  silu_mul_m12_group_bf16_gfx1151.s
  mxfp4_m12_group_down_wmma_gfx1151.s
)
for source_name in "${script_mxfp4_sources[@]}"; do
  stem=${source_name%.s}
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${kernel_dir}/prefill" -x assembler -c \
    "${repo_dir}/scripts/rocm/kernels/gfx1151/mxfp4/${source_name}" \
    -o "${out_dir}/${stem}.o"
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
done

split_stem=qkvzba_split_copy_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c \
  "${repo_dir}/kernels/gfx1151/gdn/${split_stem}.s" \
  -o "${out_dir}/${split_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${split_stem}.o" -o "${out_dir}/${split_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${split_stem}.hsaco" > "${out_dir}/${split_stem}.dis"

attention_stem=extend_attention_wmma_n64_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c \
  "${repo_dir}/kernels/gfx1151/attention/${attention_stem}.s" \
  -o "${out_dir}/${attention_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${attention_stem}.o" -o "${out_dir}/${attention_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${attention_stem}.hsaco" > "${out_dir}/${attention_stem}.dis"

qk_mrope_stem=qk_norm_mrope_gate_kv_store_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c \
  "${repo_dir}/kernels/gfx1151/attention/${qk_mrope_stem}.s" \
  -o "${out_dir}/${qk_mrope_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${qk_mrope_stem}.o" -o "${out_dir}/${qk_mrope_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${qk_mrope_stem}.hsaco" > "${out_dir}/${qk_mrope_stem}.dis"

pack_stem=expert_activation_pack_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c "${repo_dir}/kernels/gfx1151/moe/${pack_stem}.s" \
  -o "${out_dir}/${pack_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${pack_stem}.o" -o "${out_dir}/${pack_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${pack_stem}.hsaco" > "${out_dir}/${pack_stem}.dis"

gdn_stem=gdn_chunk_o_bv32_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c "${repo_dir}/kernels/gfx1151/gdn/${gdn_stem}.s" \
  -o "${out_dir}/${gdn_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${gdn_stem}.o" -o "${out_dir}/${gdn_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${gdn_stem}.hsaco" > "${out_dir}/${gdn_stem}.dis"

recompute_stem=recompute_w_u_ordered_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c "${repo_dir}/scripts/rocm/kernels/gfx1151/gdn/${recompute_stem}.s" \
  -o "${out_dir}/${recompute_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${recompute_stem}.o" -o "${out_dir}/${recompute_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${recompute_stem}.hsaco" > "${out_dir}/${recompute_stem}.dis"

for causal_stem in causal_conv1d_stream64_ordered_gfx1151 causal_conv1d_state_update_gfx1151; do
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -x assembler -c "${repo_dir}/kernels/gfx1151/gdn/${causal_stem}.s" \
    -o "${out_dir}/${causal_stem}.o"
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${causal_stem}.o" -o "${out_dir}/${causal_stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${causal_stem}.hsaco" > "${out_dir}/${causal_stem}.dis"
done

reduce_stem=expert_weighted_reduce_top8_fp64_gfx1151
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  -x assembler -c "${repo_dir}/kernels/gfx1151/moe/${reduce_stem}.s" \
  -o "${out_dir}/${reduce_stem}.o"
"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${reduce_stem}.o" -o "${out_dir}/${reduce_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out_dir}/${reduce_stem}.hsaco" > "${out_dir}/${reduce_stem}.dis"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_HSACO_DIR="\"${out_dir}\"" \
  "${integration_dir}/netra_mxfp4_sgl_launcher.hip" \
  -o "${out_dir}/libnetra_mxfp4_sgl.so"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  -o "${out_dir}/libextend_attention_wmma.so"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_m12_group_wmma_pair.hip" \
  -o "${out_dir}/benchmark_m12_group_wmma_pair"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_m12_fused_gate_up_pair.hip" \
  -o "${out_dir}/benchmark_m12_fused_gate_up_pair"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_m12_group_silu_pair.hip" \
  -o "${out_dir}/benchmark_m12_group_silu_pair"
"${hipcc_bin}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_m12_fused_gate_up_variants.hip" \
  -o "${out_dir}/benchmark_m12_fused_gate_up_variants"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_m12_gate_up_silu_fusion.hip" \
  -o "${out_dir}/benchmark_m12_gate_up_silu_fusion"

"${hipcc_bin}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/mxfp4/benchmark_prefill_up_silu_fusion.hip" \
  -o "${out_dir}/benchmark_prefill_up_silu_fusion"


echo "Built Netra SGLang raw-ASM backend for gfx1151 in ${out_dir}"
