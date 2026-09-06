#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../../.." && pwd)
out=${1:?usage: build.sh OUTPUT_DIRECTORY}
rocm=${ROCM_PATH:-/opt/rocm}
mkdir -p "$out"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_h64_d128_gfx950.s" \
  -o "$out/scorer.o"
"$rocm/llvm/bin/ld.lld" -shared "$out/scorer.o" -o "$out/scorer.hsaco"
"$rocm/bin/hipcc" -O3 -shared -fPIC --offload-arch=gfx950 \
  "$root/runtime/gfx950/attention/indexer/dsv4_mqa_bridge.hip" \
  -o "$out/libnetra_mqa.so"
