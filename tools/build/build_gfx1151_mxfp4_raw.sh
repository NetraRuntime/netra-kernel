#!/usr/bin/env bash
set -euo pipefail

# Execute inside the Netra LXC.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
default_repo=$(cd "${script_dir}/../.." && pwd)
repo_dir=${1:-"${default_repo}"}
out_dir=${2:-"${repo_dir}/build/raw"}
kernel_dir=${repo_dir}/kernels/gfx1151/mxfp4
harness_dir=${repo_dir}/harness/gfx1151/mxfp4
rocm_dir=/opt/rocm-7.2.1
clang_bin=${rocm_dir}/llvm/bin/clang
linker_bin=${rocm_dir}/llvm/bin/ld.lld
objdump_bin=${rocm_dir}/llvm/bin/llvm-objdump
hipcc_bin=${rocm_dir}/bin/hipcc

test -x "${clang_bin}"
test -x "${linker_bin}"
test -x "${objdump_bin}"
test -x "${hipcc_bin}"
mkdir -p "${out_dir}"

asm_sources=(
  decode/mxfp4_decode_gate_gfx1151.s
  decode/mxfp4_decode_down_gfx1151.s
  verify/mxfp4_verify_gate_gfx1151.s
  verify/mxfp4_verify_gate_wmma_gfx1151.s
  verify/mxfp4_verify_down_wmma_gfx1151.s
  prefill/mxfp4_prefill_gate_wmma_gfx1151.s
  prefill/mxfp4_prefill_down_wmma_gfx1151.s
  lm_head/mxfp4_lm_head_decode_gfx1151.s
  lm_head/mxfp4_lm_head_verify_wmma_gfx1151.s
  epilogue/silu_mul_bf16_gfx1151.s
)

# Retained measured negative results. These build for reproducibility but are
# not selected as shipping kernels.
experiment_sources=(
  prefill/experiments/mxfp4_prefill_gate_m32_wmma_gfx1151.s
  prefill/experiments/mxfp4_prefill_gate_m128_wmma_gfx1151.s
  decode/experiments/mxfp4_decode_gate_up_fused_gfx1151.s
  decode/experiments/mxfp4_decode_gate_up_fused_n64_gfx1151.s
)

for source_rel in "${asm_sources[@]}" "${experiment_sources[@]}"; do
  source_name=${source_rel##*/}
  stem=${source_name%.s}
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${kernel_dir}/prefill" -x assembler -c \
    "${kernel_dir}/${source_rel}" -o "${out_dir}/${stem}.o"
  "${linker_bin}" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "${objdump_bin}" -d --mcpu=gfx1151 "${out_dir}/${stem}.hsaco" \
    > "${out_dir}/${stem}.dis"
done

harness_sources=(
  decode/mxfp4_decode_gate_gfx1151.hip
  decode/mxfp4_decode_down_gfx1151.hip
  verify/mxfp4_verify_gate_gfx1151.hip
  verify/mxfp4_verify_gate_wmma_gfx1151.hip
  verify/mxfp4_verify_down_wmma_gfx1151.hip
  prefill/mxfp4_prefill_gate_wmma_gfx1151.hip
  prefill/mxfp4_prefill_down_wmma_gfx1151.hip
  lm_head/mxfp4_lm_head_decode_gfx1151.hip
  lm_head/mxfp4_lm_head_verify_wmma_gfx1151.hip
  lm_head/mxfp4_lm_head_compiler_baseline.hip
  decode/mxfp4_decode_gate_up_fused_gfx1151.hip
  decode/mxfp4_decode_gate_up_pipeline_gfx1151.hip
)

for source_rel in "${harness_sources[@]}"; do
  source_name=${source_rel##*/}
  stem=${source_name%.hip}
  "${hipcc_bin}" --offload-arch=gfx1151 -O3 \
    "${harness_dir}/${source_rel}" -o "${out_dir}/${stem}"
done

(
  cd "${out_dir}"
  sha256sum ./*.hsaco ./*.dis > SHA256SUMS
)
echo "gfx1151 raw MXFP4 build complete: ${out_dir}"
