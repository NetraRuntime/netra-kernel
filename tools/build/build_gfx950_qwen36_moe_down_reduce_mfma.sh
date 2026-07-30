#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
default_repo=$(cd "${script_dir}/../.." && pwd)
repo_dir=${1:-"${default_repo}"}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-moe-down-reduce-mfma"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
clang_bin=${CLANG_BIN:-"${rocm_dir}/llvm/bin/clang"}
linker_bin=${LINKER_BIN:-"${rocm_dir}/llvm/bin/ld.lld"}
objdump_bin=${OBJDUMP_BIN:-"${rocm_dir}/llvm/bin/llvm-objdump"}
readobj_bin=${READOBJ_BIN:-"${rocm_dir}/llvm/bin/llvm-readobj"}
hipcc_bin=${HIPCC_BIN:-"${rocm_dir}/bin/hipcc"}

for tool in \
  "${clang_bin}" "${linker_bin}" "${objdump_bin}" "${readobj_bin}" \
  "${hipcc_bin}"; do
  test -x "${tool}"
done
rocminfo_output=$(rocminfo 2>/dev/null)
if ! grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_output}"; then
  echo "gfx950 is not visible; refusing target-specific assembly" >&2
  exit 2
fi

stem=${STEM:-qwen36_moe_down_reduce_fp8_mfma_gfx950}
kernel=${KERNEL_SOURCE:-${repo_dir}/kernels/gfx950/fp8/moe/decode/experiments/${stem}.s}
harness=${repo_dir}/harness/gfx950/fp8/moe/decode/qwen36_moe_down_reduce_fp8_gfx950.hip
test -f "${kernel}"
mkdir -p "${out_dir}"

"${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "${kernel}" -o "${out_dir}/${stem}.o"
"${linker_bin}" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${objdump_bin}" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${readobj_bin}" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
harness_binary=${out_dir}/${stem}_harness
if [[ ! -x "${harness_binary}" || "${harness}" -nt "${harness_binary}" ]]; then
  "${hipcc_bin}" --offload-arch=gfx950 -O3 "${harness}" -o "${harness_binary}"
fi
(
  cd "${out_dir}"
  sha256sum \
    "${stem}.hsaco" \
    "${stem}.disassembly.txt" \
    "${stem}.metadata.txt" \
    "$(basename "${harness_binary}")" > SHA256SUMS
)
echo "gfx950 Qwen M=1 MoE down/reduce MFMA assembly complete: ${out_dir}"
