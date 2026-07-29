#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments/attention-n32-persistent-q"}
rocm=/opt/rocm-7.2.1
clang=${rocm}/llvm/bin/clang
hipcc=${rocm}/bin/hipcc
stem=extend_attention_wmma_n32_persistent_q_gfx1151
mkdir -p "${out_dir}"
"${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
  "${repo_dir}/kernels/gfx1151/attention/experiments/${stem}.s" -o "${out_dir}/${stem}.o"
"${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
"${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" -o "${out_dir}/libextend_attention_n64_baseline.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC -DNETRA_EXTEND_ATTENTION_KERNEL=${stem} \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" -o "${out_dir}/libextend_attention_n32_persistent_q.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -DNETRA_EXTEND_ATTENTION_KERNEL=${stem} \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" -o "${out_dir}/extend_attention_counter"
echo "Built rejected gfx1151 N32 persistent-Q attention experiment in ${out_dir}"
