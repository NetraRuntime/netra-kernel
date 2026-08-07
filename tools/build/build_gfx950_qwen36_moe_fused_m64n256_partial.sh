#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-fused-m64n256-partial"}
rocm_dir=${ROCM_DIR:-/opt/rocm}

source_stem=qwen36_moe_fused_m64n256_1wg_fp8_gfx950
output_stem=qwen36_moe_fused_m64n256_partial_fp8_gfx950
reduce_stem=qwen36_moe_route_reduce_f32_gfx950
source_path="${repo_dir}/kernels/gfx950/fp8/moe/verify/experiments/${source_stem}.s"
reduce_path="${repo_dir}/kernels/gfx950/fp8/moe/verify/${reduce_stem}.s"
harness_path="${repo_dir}/harness/gfx950/fp8/moe/verify/qwen36_moe_down_m64_partial_pipeline_gfx950.hip"
harness_out="${out_dir}/qwen36_moe_fused_m64n256_partial_pipeline_gfx950"

for tool in clang ld.lld llvm-objdump llvm-readobj; do
  test -x "${rocm_dir}/llvm/bin/${tool}"
done
test -x "${rocm_dir}/bin/hipcc"
command -v rocminfo >/dev/null
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"${rocminfo_text}"
mkdir -p "${out_dir}"

"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "${source_path}" -o "${out_dir}/${output_stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${output_stem}.o" \
  -o "${out_dir}/${output_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${output_stem}.hsaco" > \
  "${out_dir}/${output_stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes \
  "${out_dir}/${output_stem}.hsaco" > \
  "${out_dir}/${output_stem}.metadata.txt"

"${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
  -x assembler -c "${reduce_path}" -o "${out_dir}/${reduce_stem}.o"
"${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${reduce_stem}.o" \
  -o "${out_dir}/${reduce_stem}.hsaco"
"${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
  "${out_dir}/${reduce_stem}.hsaco" > \
  "${out_dir}/${reduce_stem}.disassembly.txt"
"${rocm_dir}/llvm/bin/llvm-readobj" --notes \
  "${out_dir}/${reduce_stem}.hsaco" > \
  "${out_dir}/${reduce_stem}.metadata.txt"

grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${output_stem}.metadata.txt"
grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${output_stem}.metadata.txt"
grep -q 'group_segment_fixed_size:[[:space:]]*65536' "${out_dir}/${output_stem}.metadata.txt"
grep -q 'v_mfma_f32_16x16x128_f8f6f4' "${out_dir}/${output_stem}.disassembly.txt"
if grep -q 'global_atomic' "${out_dir}/${output_stem}.disassembly.txt"; then
  echo "deterministic candidate unexpectedly contains global atomics" >&2
  exit 1
fi
grep -q 'global_store_dword' "${out_dir}/${output_stem}.disassembly.txt"

"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 "${harness_path}" \
  -o "${harness_out}"
(
  cd "${out_dir}"
  sha256sum ./*.hsaco ./*.disassembly.txt ./*.metadata.txt \
    ./qwen36_moe_fused_m64n256_partial_pipeline_gfx950 > SHA256SUMS
)
echo "gfx950 deterministic Qwen M64N256 partial FMoE build complete: ${out_dir}"
