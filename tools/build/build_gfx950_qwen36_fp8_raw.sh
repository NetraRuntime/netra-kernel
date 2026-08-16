#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/lib/gfx950_assembly.sh"
default_repo=$(cd "${script_dir}/../.." && pwd)
repo_dir=${1:-"${default_repo}"}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-fp8"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
clang_bin=${CLANG_BIN:-"${rocm_dir}/llvm/bin/clang"}
linker_bin=${LINKER_BIN:-"${rocm_dir}/llvm/bin/ld.lld"}
objdump_bin=${OBJDUMP_BIN:-"${rocm_dir}/llvm/bin/llvm-objdump"}
readobj_bin=${READOBJ_BIN:-"${rocm_dir}/llvm/bin/llvm-readobj"}
hipcc_bin=${HIPCC_BIN:-"${rocm_dir}/bin/hipcc"}

for tool in \
  "${clang_bin}" "${linker_bin}" "${objdump_bin}" \
  "${readobj_bin}" "${hipcc_bin}"; do
  test -x "${tool}"
done
rocminfo_output=$(rocminfo 2>/dev/null)
if ! grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_output}"; then
  echo "gfx950 is not visible; refusing to build a target-specific code object" >&2
  exit 2
fi

kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/qwen36_moe_silu_mul_quant_fp8_gfx950.s
down_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/experiments/qwen36_moe_down_reduce_fp8_mfma_gfx950.s
down_2wave_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950.s
gate_up_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/qwen36_moe_gate_up_fp8_mfma_gfx950.s
down_2wave_rowmajor_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/qwen36_moe_down_reduce_fp8_mfma_2wave_rowmajor_gfx950.s
gate_up_rowmajor_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/qwen36_moe_gate_up_fp8_mfma_rowmajor_gfx950.s
down_2wave_k32_rowmajor_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/experiments/qwen36_moe_down_reduce_fp8_mfma_2wave_k32_slotacc_rowmajor_gfx950.s
gate_up_k32_rowmajor_kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/experiments/qwen36_moe_gate_up_fp8_mfma_k32_rowmajor_gfx950.s
harness=${repo_dir}/harness/gfx950/fp8/moe/decode/qwen36_moe_silu_mul_quant_fp8_gfx950.hip
bridge=${repo_dir}/runtime/gfx950/fp8/moe/qwen36_moe_silu_mul_quant_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/fp8/moe/qwen36_moe_silu_mul_quant_bridge.h
stem=qwen36_moe_silu_mul_quant_fp8_gfx950
down_stem=qwen36_moe_down_reduce_fp8_mfma_gfx950
down_2wave_stem=qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
gate_up_stem=qwen36_moe_gate_up_fp8_mfma_gfx950
down_2wave_rowmajor_stem=qwen36_moe_down_reduce_fp8_mfma_2wave_rowmajor_gfx950
gate_up_rowmajor_stem=qwen36_moe_gate_up_fp8_mfma_rowmajor_gfx950
down_2wave_k32_rowmajor_stem=qwen36_moe_down_reduce_fp8_mfma_2wave_k32_slotacc_rowmajor_gfx950
gate_up_k32_rowmajor_stem=qwen36_moe_gate_up_fp8_mfma_k32_rowmajor_gfx950
mkdir -p "${out_dir}"

kernel_specs=(
  "$kernel:$stem"
  "$down_kernel:$down_stem"
  "$down_2wave_kernel:$down_2wave_stem"
  "$gate_up_kernel:$gate_up_stem"
  "$down_2wave_rowmajor_kernel:$down_2wave_rowmajor_stem"
  "$gate_up_rowmajor_kernel:$gate_up_rowmajor_stem"
  "$down_2wave_k32_rowmajor_kernel:$down_2wave_k32_rowmajor_stem"
  "$gate_up_k32_rowmajor_kernel:$gate_up_k32_rowmajor_stem"
)
for kernel_spec in "${kernel_specs[@]}"; do
  source_file=${kernel_spec%%:*}
  kernel_stem=${kernel_spec##*:}
  netra_gfx950_build_kernel \
    "$clang_bin" "$linker_bin" "$objdump_bin" "$readobj_bin" \
    "$out_dir" "$source_file" "$kernel_stem"
done

grep -q 'v_mfma_f32_16x16x32_fp8_fp8' \
  "${out_dir}/${down_2wave_k32_rowmajor_stem}.disassembly.txt"
grep -q 'v_mfma_f32_16x16x32_fp8_fp8' \
  "${out_dir}/${gate_up_k32_rowmajor_stem}.disassembly.txt"

harness_binary=${out_dir}/${stem}_harness
bridge_library=${out_dir}/lib${stem}_bridge.so
if [[ ! -x "$harness_binary" || "$harness" -nt "$harness_binary" ]]; then
  "${hipcc_bin}" --offload-arch=gfx950 -O3 \
    "${harness}" -o "$harness_binary"
fi
if [[ ! -e "$bridge_library" ||
      "$bridge" -nt "$bridge_library" ||
      "$bridge_header" -nt "$bridge_library" ]]; then
  "${hipcc_bin}" --offload-arch=gfx950 -O3 -fPIC -shared \
    "${bridge}" -o "$bridge_library"
fi
(
  cd "${out_dir}"
  sha256sum \
    "${stem}.hsaco" \
    "${stem}.disassembly.txt" \
    "${stem}.metadata.txt" \
    "${down_stem}.hsaco" \
    "${down_stem}.disassembly.txt" \
    "${down_stem}.metadata.txt" \
    "${down_2wave_stem}.hsaco" \
    "${down_2wave_stem}.disassembly.txt" \
    "${down_2wave_stem}.metadata.txt" \
    "${gate_up_stem}.hsaco" \
    "${gate_up_stem}.disassembly.txt" \
    "${gate_up_stem}.metadata.txt" \
    "${down_2wave_rowmajor_stem}.hsaco" \
    "${down_2wave_rowmajor_stem}.disassembly.txt" \
    "${down_2wave_rowmajor_stem}.metadata.txt" \
    "${gate_up_rowmajor_stem}.hsaco" \
    "${gate_up_rowmajor_stem}.disassembly.txt" \
    "${gate_up_rowmajor_stem}.metadata.txt" \
    "${down_2wave_k32_rowmajor_stem}.hsaco" \
    "${down_2wave_k32_rowmajor_stem}.disassembly.txt" \
    "${down_2wave_k32_rowmajor_stem}.metadata.txt" \
    "${gate_up_k32_rowmajor_stem}.hsaco" \
    "${gate_up_k32_rowmajor_stem}.disassembly.txt" \
    "${gate_up_k32_rowmajor_stem}.metadata.txt" \
    "$(basename "$harness_binary")" \
    "$(basename "$bridge_library")" > SHA256SUMS
)
echo "gfx950 Qwen FP8 raw experiment build complete: ${out_dir}"
