#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../../.." && pwd)
out=${1:?usage: build.sh OUTPUT_DIRECTORY}
rocm=${ROCM_PATH:-/opt/rocm}
mkdir -p "$out"
python3 "$root/tools/benchmark/dsv4_numeric/prepare_wave4.py" \
  "$root/kernels/gfx950/numeric/dsv4" "$out"
objects=()
for file in "$root"/kernels/gfx950/numeric/dsv4/*.s "$out"/*_w4.s; do
  object="$out/$(basename "${file%.s}").o"
  "$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -mcode-object-version=6 -c "$file" -o "$object"
  objects+=("$object")
done
"$rocm/llvm/bin/ld.lld" -shared "${objects[@]}" -o "$out/numeric.hsaco"
"$rocm/bin/hipcc" -O3 -shared -fPIC --offload-arch=gfx950 \
  "$root/runtime/gfx950/numeric/dsv4/bridge.hip" -o "$out/libnetra_numeric.so"
