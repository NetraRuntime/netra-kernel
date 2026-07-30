#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-moe-gate-up-mfma"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_moe_gate_up_fp8_mfma_gfx950
kernel=${repo_dir}/kernels/gfx950/fp8/moe/decode/experiments/${stem}.s
harness=${repo_dir}/harness/gfx950/fp8/moe/decode/${stem}.hip
mkdir -p "${out_dir}"
rocminfo_output=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_output}"
"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "${kernel}" -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
binary=${out_dir}/${stem}_harness
if [[ ! -x "${binary}" || "${harness}" -nt "${binary}" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 "${harness}" -o "${binary}"
fi
echo "gfx950 Qwen M=1 MoE gate/up MFMA assembly complete: ${out_dir}"
