#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_root=${ROCM_PATH:-/opt/rocm}
build_dir=${1:-"$repo_root/build/gfx950-qwen36-moe-gateup-m64"}
mkdir -p "$build_dir"

kernel="$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_gateup_m64n64_fp8_gfx950.s"
harness="$repo_root/harness/gfx950/fp8/moe/verify/qwen36_moe_gateup_m64_pipeline_gfx950.hip"
quant_kernel="$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_silu_quant_sorted_m64_fp8_gfx950.s"
down_kernel="$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_down_m64n64_partial_fp8_gfx950.s"
down_harness="$repo_root/harness/gfx950/fp8/moe/verify/qwen36_moe_down_m64_partial_pipeline_gfx950.hip"
paired_kernel="$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_gateup_silu_m64n64_fp8_gfx950.s"
quant_bf16_kernel="$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_quant_bf16_m64_fp8_gfx950.s"
masked_down_kernel="$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_down_m64n64_partial_masked_fp8_gfx950.s"
paired_harness="$repo_root/harness/gfx950/fp8/moe/verify/qwen36_moe_gateup_silu_m64_pipeline_gfx950.hip"
object="$build_dir/qwen36_moe_gateup_m64n64_fp8_gfx950.o"
code_object="$build_dir/qwen36_moe_gateup_m64n64_fp8_gfx950.hsaco"

"$rocm_root/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa \
  -mcpu=gfx950 -c "$kernel" -o "$object"
"$rocm_root/llvm/bin/ld.lld" -shared "$object" -o "$code_object"
"$rocm_root/bin/hipcc" -O3 --offload-arch=gfx950 "$harness" \
  -o "$build_dir/qwen36_moe_gateup_m64n64_gfx950_harness"
for source in "$quant_kernel" "$down_kernel" "$paired_kernel" \
  "$quant_bf16_kernel" "$masked_down_kernel"; do
  name=$(basename "$source" .s)
  "$rocm_root/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa \
    -mcpu=gfx950 -c "$source" -o "$build_dir/$name.o"
  "$rocm_root/llvm/bin/ld.lld" -shared "$build_dir/$name.o" \
    -o "$build_dir/$name.hsaco"
  "$rocm_root/llvm/bin/llvm-objdump" -d --mcpu=gfx950 \
    "$build_dir/$name.hsaco" > "$build_dir/$name.disassembly.txt"
  "$rocm_root/llvm/bin/llvm-readelf" --notes "$build_dir/$name.hsaco" \
    > "$build_dir/$name.metadata.txt"
done
"$rocm_root/bin/hipcc" -O3 --offload-arch=gfx950 "$down_harness" \
  -o "$build_dir/qwen36_moe_down_m64_partial_pipeline_gfx950_harness"
"$rocm_root/bin/hipcc" -O3 --offload-arch=gfx950 "$paired_harness" \
  -o "$build_dir/qwen36_moe_gateup_silu_m64_pipeline_gfx950_harness"
"$rocm_root/llvm/bin/llvm-objdump" -d --mcpu=gfx950 "$code_object" \
  > "$build_dir/qwen36_moe_gateup_m64n64_fp8_gfx950.disassembly.txt"
"$rocm_root/llvm/bin/llvm-readelf" --notes "$code_object" \
  > "$build_dir/qwen36_moe_gateup_m64n64_fp8_gfx950.metadata.txt"
sha256sum "$kernel" "$quant_kernel" "$down_kernel" "$paired_kernel" \
  "$quant_bf16_kernel" "$masked_down_kernel" "$build_dir"/*.hsaco \
  > "$build_dir/qwen36_moe_gateup_m64n64_fp8_gfx950.sha256"
