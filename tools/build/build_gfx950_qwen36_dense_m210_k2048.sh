#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-dense-m210-k2048"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_dense_m210_k2048_fp8_mfma_m32n32_gfx950
kernel=${repo_dir}/kernels/gfx950/fp8/dense/prefill/${stem}.s
bridge=${repo_dir}/runtime/gfx950/fp8/dense/qwen36_dense_m210_k2048_bridge.hip

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "$kernel" -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" >"${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  >"${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
grep -q 'v_mfma_f32_16x16x128_f8f6f4' \
  "${out_dir}/${stem}.disassembly.txt"

bridge_library=${out_dir}/libqwen36_dense_m210_k2048_bridge.so
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared \
  "$bridge" -o "$bridge_library"

sha256sum \
  "${out_dir}/${stem}.hsaco" \
  "$bridge_library" \
  >"${out_dir}/sha256sums.txt"

echo "gfx950 Qwen dense M=210 K=2048 complete: ${out_dir}"
