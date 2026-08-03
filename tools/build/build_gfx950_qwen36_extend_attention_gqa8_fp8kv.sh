#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_root=${ROCM_ROOT:-/opt/rocm}
clang=${CLANG:-$rocm_root/llvm/bin/clang}
ld_lld=${LD_LLD:-$rocm_root/llvm/bin/ld.lld}
objdump=${LLVM_OBJDUMP:-$rocm_root/llvm/bin/llvm-objdump}
readobj=${LLVM_READOBJ:-$rocm_root/llvm/bin/llvm-readobj}
hipcc=${HIPCC:-$rocm_root/bin/hipcc}
output_dir=${OUTPUT_DIR:-$repo_root/build/gfx950-qwen36-extend-attention-gqa8-fp8kv}

assembly=$repo_root/kernels/gfx950/attention/verify/qwen36_extend_attention_m16_gqa8_fp8kv_gfx950.s
object_i32=$output_dir/qwen36_extend_attention_m16_gqa8_fp8kv_i32_gfx950.o
object_i64=$output_dir/qwen36_extend_attention_m16_gqa8_fp8kv_i64_gfx950.o
base_symbol=qwen36_extend_attention_m16_gqa8_fp8kv_gfx950
hsaco=$output_dir/qwen36_extend_attention_m16_gqa8_fp8kv_gfx950.hsaco
bridge=$repo_root/runtime/gfx950/attention/verify/qwen36_extend_attention_m16_gqa8_fp8kv_bridge.hip
header_dir=$repo_root/runtime/gfx950/attention/verify
library=$output_dir/libqwen36_extend_attention_m16_gqa8_fp8kv_bridge.so

for tool in "$clang" "$ld_lld" "$objdump" "$readobj" "$hipcc"; do
  if [[ ! -x "$tool" ]]; then
    echo "required ROCm tool is unavailable: $tool" >&2
    exit 2
  fi
done

mkdir -p "$output_dir"
build_variant() {
  local width=$1
  local symbol=${base_symbol%_gfx950}_i${width}_gfx950
  local object=$output_dir/${symbol}.o
  if [[ $width == 32 ]]; then
    sed -e "s/$base_symbol/$symbol/g" \
      -e "s/s_cmp_eq_u32 s22, 4/s_branch .Lnetra_qo_i32/" "$assembly" | \
      "$clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 -x assembler -c -o "$object" -
  else
    sed -e "s/$base_symbol/$symbol/g" \
      -e "s/s_cmp_eq_u32 s22, 4/s_nop 0/" \
      -e "s/s_cbranch_scc1 .Lnetra_qo_i32/s_nop 0/" "$assembly" | \
      "$clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 -x assembler -c -o "$object" -
  fi
}
build_variant 32
build_variant 64
"$ld_lld" -shared "$object_i32" "$object_i64" -o "$hsaco"
"$hipcc" -O3 -shared -fPIC -std=c++17 -I"$header_dir" \
  "$bridge" -o "$library"
"$objdump" -d --mcpu=gfx950 "$hsaco" \
  > "$output_dir/qwen36_extend_attention_m16_gqa8_fp8kv_gfx950.disassembly.txt"
"$readobj" --notes "$hsaco" \
  > "$output_dir/qwen36_extend_attention_m16_gqa8_fp8kv_gfx950.metadata.txt"

if ! grep -q 'amdgcn-amd-amdhsa--gfx950' \
    "$output_dir/qwen36_extend_attention_m16_gqa8_fp8kv_gfx950.metadata.txt"; then
  echo "built code object does not declare gfx950" >&2
  exit 2
fi

sha256sum "$assembly" "$bridge" "$hsaco" "$library" \
  > "$output_dir/sha256sums.txt"
printf 'Built %s\nBuilt %s\n' "$hsaco" "$library"
