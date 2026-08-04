#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_root=${ROCM_ROOT:-/opt/rocm}
clang=${CLANG:-$rocm_root/llvm/bin/clang}
ld_lld=${LD_LLD:-$rocm_root/llvm/bin/ld.lld}
objdump=${LLVM_OBJDUMP:-$rocm_root/llvm/bin/llvm-objdump}
readobj=${LLVM_READOBJ:-$rocm_root/llvm/bin/llvm-readobj}
hipcc=${HIPCC:-$rocm_root/bin/hipcc}
output_dir=${OUTPUT_DIR:-$repo_root/build/gfx950-qwen36-extend-attention-gqa4-fp8kv}

assembly=$repo_root/kernels/gfx950/attention/verify/experiments/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.s
bridge=$repo_root/runtime/gfx950/attention/verify/qwen36_extend_attention_m16_gqa4_fp8kv_bridge.hip
header_dir=$repo_root/runtime/gfx950/attention/verify
object=$output_dir/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.o
hsaco=$output_dir/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.hsaco
library=$output_dir/libqwen36_extend_attention_m16_gqa4_fp8kv_bridge.so

for tool in "$clang" "$ld_lld" "$objdump" "$readobj" "$hipcc"; do
  if [[ ! -x "$tool" ]]; then
    echo "required ROCm tool is unavailable: $tool" >&2
    exit 2
  fi
done
if [[ ! -f "$assembly" || ! -f "$bridge" ]]; then
  echo "missing grouped-attention source" >&2
  exit 2
fi

mkdir -p "$output_dir"
"$clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 -x assembler \
  -c "$assembly" -o "$object"
"$ld_lld" -shared "$object" -o "$hsaco"
"$hipcc" -O3 -shared -fPIC -std=c++17 -I"$header_dir" \
  "$bridge" -o "$library"
"$objdump" -d --mcpu=gfx950 "$hsaco" \
  > "$output_dir/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.disassembly.txt"
"$readobj" --notes "$hsaco" \
  > "$output_dir/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.metadata.txt"

if ! grep -q 'amdgcn-amd-amdhsa--gfx950' \
    "$output_dir/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.metadata.txt"; then
  echo "built code object does not declare gfx950" >&2
  exit 2
fi

sha256sum "$assembly" "$bridge" "$hsaco" "$library" \
  > "$output_dir/sha256sums.txt"
printf 'Built %s\nBuilt %s\n' "$hsaco" "$library"
