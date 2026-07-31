#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
default_repo=$(cd "${script_dir}/../.." && pwd)
repo_dir=${1:-"${default_repo}"}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-fp8-gateup-silu-quant"}
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
  echo "gfx950 is not visible; refusing the target-specific build" >&2
  exit 2
fi

gate_stem=qwen36_moe_gate_up_silu_bf16_m1_gfx950
quant_stem=qwen36_moe_quant_bf16_fp8_m1_gfx950
down_stem=qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
gate_source=${repo_dir}/kernels/gfx950/fp8/moe/decode/${gate_stem}.s
quant_source=${repo_dir}/kernels/gfx950/fp8/moe/decode/${quant_stem}.s
down_source=${repo_dir}/kernels/gfx950/fp8/moe/decode/${down_stem}.s
harness_source=${repo_dir}/harness/gfx950/fp8/moe/decode/qwen36_moe_gate_up_silu_quant_fp8_gfx950.hip
bridge_source=${repo_dir}/runtime/gfx950/fp8/moe/qwen36_moe_silu_mul_quant_bridge.hip
bridge_name=libqwen36_moe_silu_mul_quant_fp8_gfx950_bridge.so
harness_name=qwen36_moe_gate_up_silu_quant_fp8_gfx950_harness

mkdir -p "${out_dir}"
for stem in "${gate_stem}" "${quant_stem}" "${down_stem}"; do
  if [[ "${stem}" == "${gate_stem}" ]]; then
    source_path=${gate_source}
  elif [[ "${stem}" == "${quant_stem}" ]]; then
    source_path=${quant_source}
  else
    source_path=${down_source}
  fi
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -x assembler -c "${source_path}" -o "${out_dir}/${stem}.o"
  "${linker_bin}" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "${objdump_bin}" --disassemble --mcpu=gfx950 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
  "${readobj_bin}" --notes "${out_dir}/${stem}.hsaco" \
    > "${out_dir}/${stem}.metadata.txt"
  grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
done

"${hipcc_bin}" --offload-arch=gfx950 -O3 -fPIC -shared \
  "${bridge_source}" -o "${out_dir}/${bridge_name}"
"${hipcc_bin}" --offload-arch=gfx950 -O3 \
  "${harness_source}" -o "${out_dir}/${harness_name}"

(
  cd "${out_dir}"
  sha256sum \
    "${gate_stem}.hsaco" \
    "${gate_stem}.disassembly.txt" \
    "${gate_stem}.metadata.txt" \
    "${quant_stem}.hsaco" \
    "${quant_stem}.disassembly.txt" \
    "${quant_stem}.metadata.txt" \
    "${down_stem}.hsaco" \
    "${down_stem}.disassembly.txt" \
    "${down_stem}.metadata.txt" \
    "${bridge_name}" \
    "${harness_name}" > SHA256SUMS
)

echo "gfx950 Qwen gate/up-SiLU-quant build complete: ${out_dir}"
