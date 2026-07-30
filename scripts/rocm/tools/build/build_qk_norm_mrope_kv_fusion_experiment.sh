#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside Netra" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/build/experiments/qk-norm-mrope-kv-fusion"}
rocm=/opt/rocm-7.2.1
stem=qk_norm_mrope_gate_kv_store_gfx1151
mkdir -p "${out}"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c \
  "${repo}/kernels/gfx1151/attention/${stem}.s" \
  -o "${out}/${stem}.o"
"${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
  "${out}/${stem}.o" -o "${out}/${stem}.hsaco"
"${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 \
  "${out}/${stem}.hsaco" >"${out}/${stem}.dis"
"${rocm}/llvm/bin/llvm-readobj" --notes --symbols \
  "${out}/${stem}.hsaco" >"${out}/${stem}.metadata.txt"
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo}/scripts/rocm/harness/gfx1151/attention/qk_norm_mrope_gate_kv_store_launcher.hip" \
  -o "${out}/libqk_norm_mrope_kv_fusion.so"
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo}/scripts/rocm/harness/gfx1151/attention/qk_norm_mrope_gate_kv_store_counter_driver.hip" \
  -o "${out}/qk_norm_mrope_gate_kv_store_counter_driver"
echo "Built raw gfx1151 Q/K norm + MRoPE + KV-store fusion in ${out}"
