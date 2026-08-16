#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/lib/gfx950_assembly.sh"
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-router-bf16"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_router_bf16_gemv_gfx950
kernel=${repo_dir}/kernels/gfx950/routing/verify/${stem}.s
harness=${repo_dir}/harness/gfx950/routing/verify/${stem}.hip
bridge=${repo_dir}/runtime/gfx950/routing/verify/qwen36_router_bf16_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/routing/verify/qwen36_router_bf16_bridge.h

mkdir -p "$out_dir"
netra_gfx950_require_device

netra_gfx950_build_kernel \
  "${rocm_dir}/llvm/bin/clang" \
  "${rocm_dir}/llvm/bin/ld.lld" \
  "${rocm_dir}/llvm/bin/llvm-objdump" \
  "${rocm_dir}/llvm/bin/llvm-readobj" \
  "$out_dir" "$kernel" "$stem"
grep -q 'v_pk_mul_f32' "${out_dir}/${stem}.disassembly.txt"
grep -q 'v_pk_fma_f32' "${out_dir}/${stem}.disassembly.txt"
grep -q 'row_bcast:31' "${out_dir}/${stem}.disassembly.txt"

binary=${out_dir}/${stem}_harness
if [[ ! -x "$binary" || "$harness" -nt "$binary" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 "$harness" -o "$binary"
fi

bridge_library=${out_dir}/libqwen36_router_bf16_bridge.so
if [[ ! -f "$bridge_library" || "$bridge" -nt "$bridge_library" ||
      "$bridge_header" -nt "$bridge_library" ]]; then
  "${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared \
    "$bridge" -o "$bridge_library"
fi

echo "gfx950 Qwen router BF16 assembly complete: ${out_dir}"
