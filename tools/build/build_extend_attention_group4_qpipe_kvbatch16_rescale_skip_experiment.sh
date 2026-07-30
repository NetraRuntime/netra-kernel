#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments/attention-group4-qpipe-kvbatch16-rescale-skip"}
rocm=/opt/rocm-7.2.1
clang=${rocm}/llvm/bin/clang
hipcc=${rocm}/bin/hipcc
stem=extend_attention_wmma_n64_group4_qpipe_kvbatch16_rescale_skip_gfx1151
baseline_stem=extend_attention_wmma_n64_group4_qpipe_kvbatch16_gfx1151
mkdir -p "${out_dir}"
for name in "${baseline_stem}" "${stem}"; do
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
    "${repo_dir}/kernels/gfx1151/attention/experiments/${name}.s" -o "${out_dir}/${name}.o"
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${name}.o" -o "${out_dir}/${name}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${name}.hsaco" > "${out_dir}/${name}.dis"
done
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${baseline_stem} \
  -DNETRA_EXTEND_ATTENTION_GRID_Y=4 -DNETRA_EXTEND_ATTENTION_BLOCK_X=512 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  -o "${out_dir}/libextend_attention_group4_qpipe_kvbatch16.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${stem} \
  -DNETRA_EXTEND_ATTENTION_GRID_Y=4 -DNETRA_EXTEND_ATTENTION_BLOCK_X=512 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  -o "${out_dir}/libextend_attention_group4_qpipe_kvbatch16_rescale_skip.so"
"${hipcc}" --offload-arch=gfx1151 -O3 \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${baseline_stem} \
  -DNETRA_EXTEND_ATTENTION_GRID_Y=4 -DNETRA_EXTEND_ATTENTION_BLOCK_X=512 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
  -o "${out_dir}/extend_attention_counter_baseline"
"${hipcc}" --offload-arch=gfx1151 -O3 \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${stem} \
  -DNETRA_EXTEND_ATTENTION_GRID_Y=4 -DNETRA_EXTEND_ATTENTION_BLOCK_X=512 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
  -o "${out_dir}/extend_attention_counter_candidate"
echo "Built gfx1151 group4 qpipe kvbatch16 rescale-skip attention experiment in ${out_dir}"
