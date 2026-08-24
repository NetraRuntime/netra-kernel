#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
rocm_root=${ROCM_PATH:-/opt/rocm}
out_dir=${1:-"$repo_root/build/gfx950-qwen36-moe-m64-verify"}
mkdir -p "$out_dir"

sources=(
  "$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_gateup_silu_m64n64_fp8_gfx950.s"
  "$repo_root/kernels/gfx950/fp8/moe/verify/experiments/qwen36_moe_down_m64n128_partial_masked_fp8_gfx950.s"
  "$repo_root/kernels/gfx950/fp8/moe/verify/qwen36_moe_route_reduce_f32_gfx950.s"
)
for source in "${sources[@]}"; do
  stem=$(basename "$source" .s)
  "$rocm_root/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa \
    -mcpu=gfx950 -c "$source" -o "$out_dir/$stem.o"
  "$rocm_root/llvm/bin/ld.lld" -shared "$out_dir/$stem.o" \
    -o "$out_dir/$stem.hsaco"
  "$rocm_root/llvm/bin/llvm-objdump" -d --mcpu=gfx950 \
    "$out_dir/$stem.hsaco" > "$out_dir/$stem.disassembly.txt"
  "$rocm_root/llvm/bin/llvm-readelf" --notes "$out_dir/$stem.hsaco" \
    > "$out_dir/$stem.metadata.txt"
done

"$rocm_root/bin/hipcc" -O3 -shared -fPIC --offload-arch=gfx950 \
  "$repo_root/runtime/gfx950/fp8/moe/qwen36_moe_m64_verify_bridge.hip" \
  -o "$out_dir/libqwen36_moe_m64_verify_bridge.so"

sha256sum "${sources[@]}" "$out_dir"/*.hsaco \
  "$out_dir/libqwen36_moe_m64_verify_bridge.so" > "$out_dir/SHA256SUMS"
