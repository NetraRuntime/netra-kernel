#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-shared-gate-append"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_shared_gate_append_m1_gfx950
kernel=${repo_dir}/kernels/gfx950/routing/decode/${stem}.s
harness=${repo_dir}/harness/gfx950/routing/decode/${stem}.hip
bridge=${repo_dir}/runtime/gfx950/routing/decode/qwen36_shared_gate_append_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/routing/decode/qwen36_shared_gate_append_bridge.h

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "$kernel" -o "${out_dir}/${stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
  -o "${out_dir}/${stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes "${out_dir}/${stem}.hsaco" \
  > "${out_dir}/${stem}.metadata.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
grep -q 'v_dot2_f32_bf16' "${out_dir}/${stem}.disassembly.txt"

binary=${out_dir}/${stem}_harness
if [[ ! -x "$binary" || "$harness" -nt "$binary" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 "$harness" -o "$binary"
fi

bridge_library=${out_dir}/libqwen36_shared_gate_append_bridge.so
if [[ ! -f "$bridge_library" || "$bridge" -nt "$bridge_library" ||
      "$bridge_header" -nt "$bridge_library" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared \
    "$bridge" -o "$bridge_library"
fi

echo "gfx950 Qwen shared-gate/append assembly complete: ${out_dir}"
