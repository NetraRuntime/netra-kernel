#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
if (( $# < 3 )); then
  echo "usage: $0 N K GROUPS [OUT_DIR]" >&2
  exit 2
fi
n=$1
k=$2
groups=$3
out_dir=${4:-"${repo_dir}/results/profiles/gfx1151/dense-prefill-dword-n${n}-k${k}-g${groups}-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
binary=${repo_dir}/build/experiments/benchmark_linear_prefill_dword_layout
baseline=${repo_dir}/build/experiments/mxfp4_sgl_linear_prefill_strided_layout_gfx1151.hsaco
candidate=${repo_dir}/build/experiments/mxfp4_sgl_linear_prefill_dword_layout_gfx1151.hsaco
repacker=${repo_dir}/build/experiments/mxfp4_sgl_linear_prefill_repack_dword_gfx1151.hsaco
build_dir=${repo_dir}/build/experiments
mkdir -p "${out_dir}" "${build_dir}"
build_asm() {
  local source=$1
  local output=$2
  local object=${output%.hsaco}.o
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${repo_dir}/kernels/gfx1151/mxfp4/prefill" -x assembler -c \
    "${source}" -o "${object}"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "${object}" -o "${output}"
}
build_asm \
  "${repo_dir}/kernels/gfx1151/mxfp4/serving/experiments/mxfp4_sgl_linear_prefill_strided_layout_gfx1151.s" \
  "${baseline}"
build_asm \
  "${repo_dir}/kernels/gfx1151/mxfp4/serving/experiments/mxfp4_sgl_linear_prefill_dword_layout_gfx1151.s" \
  "${candidate}"
build_asm \
  "${repo_dir}/kernels/gfx1151/mxfp4/serving/mxfp4_sgl_linear_prefill_repack_dword_gfx1151.s" \
  "${repacker}"
env -u LD_LIBRARY_PATH "${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/mxfp4/serving/benchmark_linear_prefill_dword_layout.hip" \
  -o "${binary}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU MeanOccupancyPerCU Wavefronts
  SQ_WAVES SQ_WAVE_CYCLES SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit
  GL2C_HIT_sum GL2C_MISS_sum MemUnitBusy LDSBankConflict VALUInsts SALUInsts
  WriteUnitStalled SQ_INSTS_FLAT SQ_INSTS_LDS SQ_INSTS_SALU SQ_INSTS_SMEM
  SQ_INSTS_TEX_LOAD SQ_INSTS_TEX_STORE SQ_INSTS_VALU
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}
  mkdir -p "${pass_dir}"
  timeout -k 5 90 env -u LD_LIBRARY_PATH "${rocm}/bin/rocprofv3" \
    --disable-signal-handlers true -d "${pass_dir}" -o trace \
    --pmc "${counter}" -f csv -- "${binary}" \
    "${baseline}" "${candidate}" "${repacker}" "${n}" "${k}" "${groups}" 1 \
    >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured dense-prefill N=${n} K=${k} G=${groups} counter ${counter}: PASS"
done
scope="synthetic deterministic nonzero exact Qwen3.6 dense prefill G${groups} M64 N${n} K${k}"
/root/sglvenv1151/bin/python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" --kernel-prefix mxfp4_sgl_linear_prefill_wmma_gfx1151 \
  --input-scope "${scope} baseline strided MXFP4 layout" \
  --out "${out_dir}/baseline-summary.json" >"${out_dir}/baseline-summary.stdout"
/root/sglvenv1151/bin/python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" --kernel-prefix mxfp4_sgl_linear_prefill_dword_layout_gfx1151 \
  --input-scope "${scope} dword MXFP4 layout" \
  --out "${out_dir}/candidate-summary.json" >"${out_dir}/candidate-summary.stdout"
echo "gfx1151 measured dense-prefill counter reports: ${out_dir}"
