#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "refusing to build outside Netra" >&2; exit 1; }
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "${script_dir}" rev-parse --show-toplevel)
out=${1:-"${repo}/build/experiments/recompute-w-u-breuse"}
rocm=/opt/rocm-7.2.1
mkdir -p "${out}"
sources=(
  recompute_w_u_ordered_baseline_gfx1151.s
  recompute_w_u_ordered_breuse_gfx1151.s
)
for source_name in "${sources[@]}"; do
  stem=${source_name%.s}
  source="${repo}/kernels/gfx1151/gdn/experiments/${source_name}"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 -x assembler -c "${source}" -o "${out}/${stem}.o"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 "${out}/${stem}.o" -o "${out}/${stem}.hsaco"
  "${rocm}/llvm/bin/llvm-objdump" -d --mcpu=gfx1151 "${out}/${stem}.hsaco" >"${out}/${stem}.dis"
done
"${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 -shared -fPIC \
  "${repo}/scripts/rocm/harness/gfx1151/gdn/recompute_w_u_dual_launcher.hip" \
  -o "${out}/librecompute_w_u_dual.so"
echo "Built gfx1151 recompute W/U B-reuse experiment in ${out}"
