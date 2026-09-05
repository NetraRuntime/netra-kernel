#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-dense-m1"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
lds_stem=qwen36_dense_m1_n2048_k4096_fp8_mfma_4wave_lds_gfx950
kernel=${repo_dir}/kernels/gfx950/fp8/dense/decode/experiments/${stem}.s
lds_kernel=${repo_dir}/kernels/gfx950/fp8/dense/decode/experiments/${lds_stem}.s
harness=${repo_dir}/harness/gfx950/fp8/dense/decode/${stem}.hip
bridge=${repo_dir}/runtime/gfx950/fp8/dense/qwen36_dense_m1_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/fp8/dense/qwen36_dense_m1_bridge.h
mkdir -p "${out_dir}"
rocminfo_output=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_output}"
"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "${kernel}" -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "${lds_kernel}" -o "${out_dir}/${lds_stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${lds_stem}.o" \
  -o "${out_dir}/${lds_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${lds_stem}.hsaco" > "${out_dir}/${lds_stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${lds_stem}.hsaco" \
  > "${out_dir}/${lds_stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${lds_stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${lds_stem}.metadata.txt"
binary=${out_dir}/${stem}_harness
bridge_library=${out_dir}/libqwen36_dense_m1_bridge.so
if [[ ! -x "${binary}" || "${harness}" -nt "${binary}" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 "${harness}" -o "${binary}"
fi
if [[ ! -e "${bridge_library}" ||
      "${bridge}" -nt "${bridge_library}" ||
      "${bridge_header}" -nt "${bridge_library}" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared \
    "${bridge}" -o "${bridge_library}"
fi
echo "gfx950 Qwen dense M=1 assembly complete: ${out_dir}"
