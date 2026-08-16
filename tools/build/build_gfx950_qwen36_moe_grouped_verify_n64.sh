#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-grouped-down-m16n64"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_moe_grouped_down_m16n64_fp8_gfx950
kernel=${repo_dir}/kernels/gfx950/fp8/moe/verify/${stem}.s
reduce_stem=qwen36_moe_route_reduce_f32_gfx950
reduce_kernel=${repo_dir}/kernels/gfx950/fp8/moe/verify/${reduce_stem}.s
harness=${repo_dir}/harness/gfx950/fp8/moe/verify/qwen36_moe_grouped_m1024_n64_pipeline_gfx950.hip
bridge=${repo_dir}/runtime/gfx950/fp8/moe/qwen36_moe_grouped_verify_n64_bridge.hip

for tool in clang ld.lld llvm-objdump llvm-readobj hipcc rocminfo; do
  command -v "${rocm_dir}/llvm/bin/${tool}" >/dev/null 2>&1 ||
    command -v "${rocm_dir}/bin/${tool}" >/dev/null 2>&1 ||
    command -v "${tool}" >/dev/null 2>&1
done
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_text}"
mkdir -p "${out_dir}"

for kernel_stem in "${stem}" "${reduce_stem}"; do
  source_path=${kernel}
  if [[ "${kernel_stem}" == "${reduce_stem}" ]]; then
    source_path=${reduce_kernel}
  fi
  "${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -x assembler -c "${source_path}" -o "${out_dir}/${kernel_stem}.o"
  "${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${kernel_stem}.o" \
    -o "${out_dir}/${kernel_stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
    "${out_dir}/${kernel_stem}.hsaco" > \
    "${out_dir}/${kernel_stem}.disassembly.txt"
  "${rocm_dir}/llvm/bin/llvm-readobj" --notes \
    "${out_dir}/${kernel_stem}.hsaco" > \
    "${out_dir}/${kernel_stem}.metadata.txt"
  grep -q 'amdgcn-amd-amdhsa--gfx950' \
    "${out_dir}/${kernel_stem}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' \
    "${out_dir}/${kernel_stem}.metadata.txt"
done
grep -q 'v_mfma_f32_16x16x128_f8f6f4' \
  "${out_dir}/${stem}.disassembly.txt"

"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 "${harness}" \
  -o "${out_dir}/qwen36_moe_grouped_m1024_n64_pipeline_gfx950_harness"
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared "${bridge}" \
  -o "${out_dir}/libqwen36_moe_grouped_verify_bridge.so"

(
  cd "${out_dir}"
  sha256sum ./*.hsaco ./*.disassembly.txt ./*.metadata.txt \
    ./qwen36_moe_grouped_m1024_n64_pipeline_gfx950_harness \
    ./libqwen36_moe_grouped_verify_bridge.so > SHA256SUMS
)
echo "gfx950 Qwen grouped verification N64 assembly complete: ${out_dir}"
