#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-attention-gate"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_attention_gate_bf16_gfx950
source_file=${repo_dir}/kernels/gfx950/attention/gate/${stem}.s
bridge=${repo_dir}/runtime/gfx950/attention/qwen36_attention_gate_bridge.hip

mkdir -p "${out_dir}"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_text}"
"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mwavefrontsize64 -x assembler -c "${source_file}" -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
grep -q 'private_segment_fixed_size:[[:space:]]*0' "${out_dir}/${stem}.metadata.txt"
grep -q 'v_exp_f32' "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC -shared \
  "${bridge}" -o "${out_dir}/libqwen36_attention_gate_bridge.so"
sha256sum "${source_file}" "${bridge}" "${out_dir}/${stem}.hsaco" \
  "${out_dir}/libqwen36_attention_gate_bridge.so" > "${out_dir}/sha256sums.txt"
printf 'target=gfx950\nwavefront_size=64\nshape=[T,16,256]\n' \
  > "${out_dir}/build-variant.txt"
echo "gfx950 Qwen attention gate build complete: ${out_dir}"
