#!/usr/bin/env bash
set -euo pipefail

# Run inside the Netra LXC. The first argument is the directory containing
# these sources after lxc file push; the second is the output directory.
src_dir=${1:-/root/work}
out_dir=${2:-/root/work/build-gfx1151-mxfp4}
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
  mxfp4_decode_gate_gfx1151.s
  mxfp4_decode_down_gfx1151.s
  mxfp4_verify_gate_gfx1151.s
  mxfp4_verify_gate_wmma_gfx1151.s
  mxfp4_verify_down_wmma_gfx1151.s
  mxfp4_prefill_gate_wmma_gfx1151.s
  mxfp4_prefill_down_wmma_gfx1151.s
  mxfp4_lm_head_decode_gfx1151.s
  mxfp4_lm_head_verify_wmma_gfx1151.s
  silu_mul_bf16_gfx1151.s
)

# Retained negative-result variants; built so their measurements remain
# reproducible, but they are not selected as shipping kernels.
experiment_sources=(
  mxfp4_prefill_gate_m32_wmma_gfx1151.s
  mxfp4_prefill_gate_m128_wmma_gfx1151.s
  mxfp4_decode_gate_up_fused_gfx1151.s
  mxfp4_decode_gate_up_fused_n64_gfx1151.s
)

for source_name in "${asm_sources[@]}" "${experiment_sources[@]}"; do
  stem=${source_name%.s}
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${src_dir}" -x assembler -c "${src_dir}/${source_name}" \
    -o "${out_dir}/${stem}.o"
  "${linker_bin}" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "${objdump_bin}" -d --mcpu=gfx1151 "${out_dir}/${stem}.hsaco" \
    > "${out_dir}/${stem}.dis"
done

harness_sources=(
  mxfp4_decode_gate_gfx1151.hip
  mxfp4_decode_down_gfx1151.hip
  mxfp4_verify_gate_gfx1151.hip
  mxfp4_verify_gate_wmma_gfx1151.hip
  mxfp4_verify_down_wmma_gfx1151.hip
  mxfp4_prefill_gate_wmma_gfx1151.hip
  mxfp4_prefill_down_wmma_gfx1151.hip
  mxfp4_lm_head_decode_gfx1151.hip
  mxfp4_lm_head_verify_wmma_gfx1151.hip
  mxfp4_lm_head_compiler_baseline.hip
  mxfp4_decode_gate_up_fused_gfx1151.hip
  mxfp4_decode_gate_up_pipeline_gfx1151.hip
)

for source_name in "${harness_sources[@]}"; do
  stem=${source_name%.hip}
  "${hipcc_bin}" --offload-arch=gfx1151 -O3 "${src_dir}/${source_name}" \
    -o "${out_dir}/${stem}"
done

(
  cd "${out_dir}"
  sha256sum ./*.hsaco ./*.dis > SHA256SUMS
)
echo "gfx1151 raw MXFP4 build complete: ${out_dir}"
