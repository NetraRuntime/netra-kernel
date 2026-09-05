#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
campaign_root=${CAMPAIGN_ROOT:-/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z}
run_id=${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
output_dir=${OUTPUT_DIR:-"${campaign_root}/kernel_experiments/qwen36_moe_down_parallel_8gpu_${run_id}"}
capture_dir=${CAPTURE_DIR:-"${campaign_root}/kernel_experiments/qwen36_moe_down_reduce_fp8_gfx950_20260730T010200Z/capture"}
iterations=${ITERATIONS:-500}
rocm_dir=${ROCM_DIR:-/opt/rocm}
clang_bin=${CLANG_BIN:-"${rocm_dir}/llvm/bin/clang"}
linker_bin=${LINKER_BIN:-"${rocm_dir}/llvm/bin/ld.lld"}
objdump_bin=${OBJDUMP_BIN:-"${rocm_dir}/llvm/bin/llvm-objdump"}
readobj_bin=${READOBJ_BIN:-"${rocm_dir}/llvm/bin/llvm-readobj"}
hipcc_bin=${HIPCC_BIN:-"${rocm_dir}/bin/hipcc"}
source_file=${repo_dir}/kernels/gfx950/fp8/moe/decode/experiments/qwen36_moe_down_reduce_fp8_mfma_parallel_gfx950.s
control_source=${repo_dir}/kernels/gfx950/fp8/moe/decode/qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950.s
harness_source=${repo_dir}/harness/gfx950/fp8/moe/decode/qwen36_moe_down_reduce_fp8_gfx950.hip
symbol=qwen36_moe_down_reduce_fp8_mfma_parallel_gfx950
control_symbol=qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950

for tool in \
  "${clang_bin}" "${linker_bin}" "${objdump_bin}" "${readobj_bin}" \
  "${hipcc_bin}" numactl; do
  command -v "${tool}" >/dev/null 2>&1 || test -x "${tool}"
done
test -f "${capture_dir}/manifest.json"
test -f "${source_file}"
test -f "${control_source}"

if docker ps --format '{{.Names}}' 2>/dev/null |
   grep -q '^netra-qwen36-'; then
  echo "a Qwen serving container is active; refusing concurrent validation" >&2
  exit 2
fi
rocminfo_text=$(rocminfo 2>/dev/null)
if [[ $(grep -c 'Name:[[:space:]]*gfx950' <<<"${rocminfo_text}") -lt 8 ]]; then
  echo "eight gfx950 agents are not visible" >&2
  exit 2
fi

mkdir -p "${output_dir}/build"
harness_binary=${output_dir}/build/qwen36_moe_down_parallel_harness
"${hipcc_bin}" --offload-arch=gfx950 -O3 \
  "${harness_source}" -o "${harness_binary}"

build_variant() {
  local label=$1
  local input=$2
  local variant_symbol=$3
  local slot_waves=${4:-}
  local build_dir=${output_dir}/build/${label}
  mkdir -p "${build_dir}"
  local assembler_args=()
  if [[ -n "${slot_waves}" ]]; then
    assembler_args+=("-Wa,-defsym,NETRA_SLOT_WAVES=${slot_waves}")
  fi
  "${clang_bin}" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    "${assembler_args[@]}" -x assembler -c "${input}" \
    -o "${build_dir}/${label}.o"
  "${linker_bin}" -shared "${build_dir}/${label}.o" \
    -o "${build_dir}/${label}.hsaco"
  "${objdump_bin}" --disassemble --mcpu=gfx950 \
    "${build_dir}/${label}.hsaco" >"${build_dir}/${label}.disassembly.txt"
  "${readobj_bin}" --notes "${build_dir}/${label}.hsaco" \
    >"${build_dir}/${label}.metadata.txt"
  grep -q 'amdgcn-amd-amdhsa--gfx950' "${build_dir}/${label}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' "${build_dir}/${label}.metadata.txt"
  printf '%s\n' "${variant_symbol}" >"${build_dir}/symbol.txt"
}

build_variant control_2wave "${control_source}" "${control_symbol}"
for waves in 3 4 5 6 7 8 9; do
  build_variant "parallel_${waves}wave" "${source_file}" "${symbol}" "${waves}"
done

labels=(
  control_2wave
  parallel_3wave
  parallel_4wave
  parallel_5wave
  parallel_6wave
  parallel_7wave
  parallel_8wave
  parallel_9wave
)
symbols=(
  "${control_symbol}"
  "${symbol}" "${symbol}" "${symbol}" "${symbol}" "${symbol}" "${symbol}" "${symbol}"
)
blocks=(128 192 256 320 384 448 512 576)
cpulists=(
  0-15,128-143
  16-31,144-159
  32-47,160-175
  48-63,176-191
  64-79,192-207
  80-95,208-223
  96-111,224-239
  112-127,240-255
)
nodes=(0 0 0 0 1 1 1 1)

for gpu in 0 1 2 3 4 5 6 7; do
  label=${labels[$gpu]}
  variant_symbol=${symbols[$gpu]}
  block=${blocks[$gpu]}
  build_dir=${output_dir}/build/${label}
  (
    printf 'gpu=%s\nlabel=%s\nblock=%s\nnuma_node=%s\ncpus=%s\n' \
      "${gpu}" "${label}" "${block}" "${nodes[$gpu]}" "${cpulists[$gpu]}"
    HIP_VISIBLE_DEVICES=${gpu} \
      numactl --physcpubind="${cpulists[$gpu]}" --membind="${nodes[$gpu]}" \
      "${harness_binary}" "${build_dir}/${label}.hsaco" "${capture_dir}" \
      "${iterations}" "${variant_symbol}" 128 "${block}" 16
  ) >"${output_dir}/gpu${gpu}-${label}.log" 2>&1 &
done
wait

for gpu in 0 1 2 3 4 5 6 7; do
  label=${labels[$gpu]}
  printf 'gpu=%s label=%s ' "${gpu}" "${label}"
  grep -E 'nondeterministic_iterations=|median_us=' \
    "${output_dir}/gpu${gpu}-${label}.log" | tr '\n' ' '
  printf '\n'
done
find "${output_dir}/build" -type f -name '*.hsaco' -print0 |
  sort -z | xargs -0 sha256sum >"${output_dir}/hsaco-sha256.txt"
amd-smi process >"${output_dir}/final-gpu-processes.txt" 2>&1
amd-smi metric >"${output_dir}/final-gpu-metrics.txt" 2>&1
printf 'output_dir=%s\n' "${output_dir}"
