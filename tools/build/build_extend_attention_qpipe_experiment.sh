#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside the Netra LXC" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
out_dir=${1:-"${repo_dir}/build/experiments/attention-qpipe"}
rocm=/opt/rocm-7.2.1
clang=${rocm}/llvm/bin/clang
hipcc=${rocm}/bin/hipcc
serial=extend_attention_wmma_n64_qserial_gfx1151
accepted=extend_attention_wmma_n64_gfx1151
pipe16=extend_attention_wmma_n64_qpipe16_gfx1151
mkdir -p "${out_dir}"
for stem in "${serial}" "${accepted}" "${pipe16}"; do
  if [[ ${stem} == "${accepted}" ]]; then
    source_file=${repo_dir}/kernels/gfx1151/attention/${stem}.s
  else
    source_file=${repo_dir}/kernels/gfx1151/attention/experiments/${stem}.s
  fi
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
    "${source_file}" -o "${out_dir}/${stem}.o"
  "${clang}" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${out_dir}/${stem}.o" -o "${out_dir}/${stem}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.dis"
done
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${serial} \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  -o "${out_dir}/libextend_attention_qserial.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  -o "${out_dir}/libextend_attention_qpipe8.so"
"${hipcc}" --offload-arch=gfx1151 -O3 -shared -fPIC \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${pipe16} \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  -o "${out_dir}/libextend_attention_qpipe16.so"
"${hipcc}" --offload-arch=gfx1151 -O3 \
  -DNETRA_EXTEND_ATTENTION_KERNEL=${serial} \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
  -o "${out_dir}/extend_attention_counter_baseline"
"${hipcc}" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_wmma_launcher.hip" \
  "${repo_dir}/harness/gfx1151/attention/extend_attention_counter_harness.hip" \
  -o "${out_dir}/extend_attention_counter_candidate"
echo "Built gfx1151 attention Q-pipeline experiment in ${out_dir}"
