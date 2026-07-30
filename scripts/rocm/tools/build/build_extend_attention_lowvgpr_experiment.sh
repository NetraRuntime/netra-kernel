#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside Netra" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/build/experiments/attention-lowvgpr"}
rocm=/opt/rocm-7.2.1
baseline=extend_attention_wmma_n64_gfx1151
candidate=extend_attention_wmma_n64_group4_qpipe_kvbatch16_lowvgpr_gfx1151
mkdir -p "${out}"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
  "${repo}/kernels/gfx1151/attention/${baseline}.s" -o "${out}/${baseline}.o"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out}/${baseline}.o" -o "${out}/${baseline}.hsaco"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
  "${repo}/scripts/rocm/kernels/gfx1151/attention/experiments/${candidate}.s" \
  -o "${out}/${candidate}.o"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out}/${candidate}.o" -o "${out}/${candidate}.hsaco"
for stem in "${baseline}" "${candidate}"; do
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out}/${stem}.hsaco" >"${out}/${stem}.dis"
done
for variant in baseline candidate; do
  if [[ ${variant} == baseline ]]; then stem=${baseline}; else stem=${candidate}; fi
  "${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 -shared -fPIC \
    -DNETRA_EXTEND_ATTENTION_KERNEL="${stem}" \
    -DNETRA_EXTEND_ATTENTION_GRID_Y=4 -DNETRA_EXTEND_ATTENTION_BLOCK_X=512 \
    "${repo}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
    -o "${out}/libextend_attention_${variant}.so"
done
for variant in baseline candidate; do
  if [[ ${variant} == baseline ]]; then stem=${baseline}; else stem=${candidate}; fi
  "${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
    -DNETRA_EXTEND_ATTENTION_KERNEL="${stem}" \
    -DNETRA_EXTEND_ATTENTION_GRID_Y=4 -DNETRA_EXTEND_ATTENTION_BLOCK_X=512 \
    "${repo}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
    "${repo}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
    -o "${out}/extend_attention_counter_${variant}"
done
echo "Built gfx1151 N64 low-VGPR attention experiment in ${out}"
