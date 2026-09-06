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
for waves in 1 4; do
  "$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -mcode-object-version=6 -c \
    "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_tile16_w${waves}_gfx950.s" \
    -o "$out/small${waves}.o"
done
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_pipeline_gfx950.s" \
  -o "$out/pipeline.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_tile32_gfx950.s" \
  -o "$out/tile32.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_pair32_gfx950.s" \
  -o "$out/pair32.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_pair32_w4_gfx950.s" \
  -o "$out/pair32_w4.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_transposed_gfx950.s" \
  -o "$out/transposed.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_pair_prefetch_gfx950.s" \
  -o "$out/pair_prefetch.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_headsplit_gfx950.s" \
  -o "$out/headsplit.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_shared_q_gfx950.s" \
  -o "$out/shared_q.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_preload_pair_gfx950.s" \
  -o "$out/preload_pair.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_preload_shared_gfx950.s" \
  -o "$out/preload_shared.o"
"$rocm/llvm/bin/clang" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -mcode-object-version=6 -c \
  "$root/kernels/gfx950/attention/indexer/experiments/dsv4_mqa_fp8_shared_prefetch_gfx950.s" \
  -o "$out/shared_prefetch.o"
"$rocm/llvm/bin/ld.lld" -shared "$out/scorer.o" "$out/small1.o" "$out/small4.o" "$out/pipeline.o" "$out/tile32.o" "$out/pair32.o" "$out/pair32_w4.o" "$out/transposed.o" "$out/pair_prefetch.o" "$out/headsplit.o" "$out/shared_q.o" "$out/preload_pair.o" "$out/preload_shared.o" "$out/shared_prefetch.o" -o "$out/scorer.hsaco"
"$rocm/bin/hipcc" -O3 -shared -fPIC --offload-arch=gfx950 \
  "$root/runtime/gfx950/attention/indexer/dsv4_mqa_bridge.hip" \
  -o "$out/libnetra_mqa.so"
