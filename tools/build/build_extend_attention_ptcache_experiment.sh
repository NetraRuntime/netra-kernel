#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments/attention-ptcache"}
rocm=/opt/rocm-7.2.1
clang=${rocm}/llvm/bin/clang
hipcc=${rocm}/bin/hipcc
baseline=extend_attention_wmma_n64_qpipe8_baseline_gfx1151
variants=(
  "${baseline}"
  extend_attention_wmma_n64_ptcache8_gfx1151
  extend_attention_wmma_n64_ptcache8_first_gfx1151
  extend_attention_wmma_n64_ptcache16_gfx1151
)
mkdir -p "${out_dir}"
for stem in "${variants[@]}"; do
  if [[ ${stem} == "${baseline}" ]]; then
    source_file=${repo_dir}/kernels/gfx1151/attention/experiments/${stem}.s
  else
    source_file=${repo_dir}/kernels/gfx1151/attention/experiments/${stem}.s
  fi
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
    "${source_file}" -o "${out_dir}/${stem}.o"
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
  if [[ ${stem} == "${baseline}" ]]; then
    "${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC -DNETRA_EXTEND_ATTENTION_GRID_Y=16 -DNETRA_EXTEND_ATTENTION_BLOCK_X=128 \
      -DNETRA_EXTEND_ATTENTION_KERNEL=${stem} \
      "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
      -o "${out_dir}/lib${stem}.so"
  else
    "${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC -DNETRA_EXTEND_ATTENTION_GRID_Y=16 -DNETRA_EXTEND_ATTENTION_BLOCK_X=128 \
      -DNETRA_EXTEND_ATTENTION_KERNEL=${stem} \
      "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
      -o "${out_dir}/lib${stem}.so"
  fi
done
"${hipcc}" --offload-arch=gfx1151 -O3 -DNETRA_EXTEND_ATTENTION_KERNEL=${baseline} -DNETRA_EXTEND_ATTENTION_GRID_Y=16 -DNETRA_EXTEND_ATTENTION_BLOCK_X=128 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
  -o "${out_dir}/extend_attention_counter_qpipe8"
candidate=extend_attention_wmma_n64_ptcache16_gfx1151
"${hipcc}" --offload-arch=gfx1151 -O3 -DNETRA_EXTEND_ATTENTION_KERNEL=${candidate} -DNETRA_EXTEND_ATTENTION_GRID_Y=16 -DNETRA_EXTEND_ATTENTION_BLOCK_X=128 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
  -o "${out_dir}/extend_attention_counter_ptcache16"
echo "Built gfx1151 attention page-table-cache experiments in ${out_dir}"
