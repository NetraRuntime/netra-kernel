#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside Netra" >&2; exit 1; }
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out=${1:-"${repo}/build/experiments/gdn-chunk-o-staging"}; rocm=/opt/rocm-7.2.1
mkdir -p "${out}"
for stem in gdn_chunk_o_bv32_gfx1151 gdn_chunk_o_bv32_batch2_gfx1151 gdn_chunk_o_bv32_qhpipe_gfx1151 gdn_chunk_o_bv32_qkpipe_gfx1151 gdn_chunk_o_bv32_avpipe_gfx1151 gdn_chunk_o_bv32_qkpipe2_gfx1151 gdn_chunk_o_bv32_qkpipe1_gfx1151 gdn_chunk_o_bv32_ldspipe_combined_gfx1151; do
  source="${repo}/kernels/gfx1151/gdn/${stem}.s"
  [[ -f ${source} ]] || source="${repo}/kernels/gfx1151/gdn/experiments/${stem}.s"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c "${source}" -o "${out}/${stem}.o"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 "${out}/${stem}.o" -o "${out}/${stem}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 "${out}/${stem}.hsaco" >"${out}/${stem}.dis"
done
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo}/harness/gfx1151/gdn/gdn_chunk_o_dual_launcher.hip" -o "${out}/libgdn_chunk_o_dual.so"
echo "Built gfx1151 GDN chunk-o staging experiments in ${out}"
