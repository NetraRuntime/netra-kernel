#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out=${1:-"$repo/build/gfx950-qwen36-gdn-chunk-o-m8192-bv128-fixed-t8192"}
clang=${CLANG:-/opt/rocm/llvm/bin/clang}
hipcc=${HIPCC:-/opt/rocm/bin/hipcc}
objdump=${LLVM_OBJDUMP:-/opt/rocm/llvm/bin/llvm-objdump}
readelf=${LLVM_READELF:-/opt/rocm/llvm/bin/llvm-readelf}
kernel_stem=${NETRA_GDN_CHUNK_O_KERNEL_STEM:-qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950}
source=${NETRA_GDN_CHUNK_O_SOURCE:-"$repo/kernels/gfx950/linear_attention/prefill/${kernel_stem}.s"}
bridge="$repo/runtime/gfx950/linear_attention/prefill/qwen36_gdn_chunk_o_m8192_bv128_bridge.hip"

mkdir -p "$out"
"$clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 -x assembler -c \
  "$source" -o "$out/kernel.o"
"$clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  "$out/kernel.o" -o "$out/${kernel_stem}.hsaco"
"$hipcc" --offload-arch=gfx950 -O3 -shared -fPIC "$bridge" \
  -o "$out/libqwen36_gdn_chunk_o_m8192_bridge.so"
"$objdump" -d --mcpu=gfx950 \
  "$out/${kernel_stem}.hsaco" \
  > "$out/disassembly.txt"
"$readelf" --notes "$out/${kernel_stem}.hsaco" \
  > "$out/code-object-notes.txt"
grep -q 'amdgcn-amd-amdhsa--gfx950' "$out/code-object-notes.txt"
grep -Eq 'v_mfma_f32_(16x16x32|32x32x16)_bf16' "$out/disassembly.txt"
sha256sum "$source" "$out/${kernel_stem}.hsaco" \
  "$out/libqwen36_gdn_chunk_o_m8192_bridge.so" > "$out/sha256.txt"
printf 'built %s\n' "$out"
