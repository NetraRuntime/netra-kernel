#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out_dir=${1:-"${repo_dir}/results/profiles/gfx1151/prefill-gate-dword-layout-$(date -u +%Y%m%dT%H%M%SZ)"}
rocm=/opt/rocm-7.2.1
binary=${out_dir}/benchmark_prefill_gate_dword_layout
baseline=${2:-"${repo_dir}/build/experiments/mxfp4_prefill_gate_strided_layout_gfx1151.hsaco"}
candidate=${3:-"${repo_dir}/build/experiments/mxfp4_prefill_gate_dword_layout_gfx1151.hsaco"}
repacker=${4:-"${repo_dir}/build/experiments/mxfp4_prefill_repack_dword_gfx1151.hsaco"}
mkdir -p "${out_dir}"
build_asm() {
  local source=$1 output=$2 object=${2%.hsaco}.o
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    -I "${repo_dir}/kernels/gfx1151/mxfp4/prefill" -x assembler -c \
    "$source" -o "$object"
  "${rocm}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx1151 \
    "$object" -o "$output"
}
if (( $# < 2 )); then
  build_asm "${repo_dir}/kernels/gfx1151/mxfp4/prefill/experiments/mxfp4_prefill_gate_strided_layout_gfx1151.s" "$baseline"
fi
if (( $# < 3 )); then
  build_asm "${repo_dir}/kernels/gfx1151/mxfp4/prefill/experiments/mxfp4_prefill_gate_dword_layout_gfx1151.s" "$candidate"
fi
if (( $# < 4 )); then
  build_asm "${repo_dir}/kernels/gfx1151/mxfp4/prefill/mxfp4_prefill_repack_dword_gfx1151.s" "$repacker"
fi
env -u LD_LIBRARY_PATH "${rocm}/bin/hipcc" --offload-arch=gfx1151 -O3 \
  "${repo_dir}/harness/gfx1151/mxfp4/prefill/benchmark_prefill_gate_dword_layout.hip" \
  -o "${binary}"
counters=(
  OccupancyPercent MeanOccupancyPerActiveCU MeanOccupancyPerCU Wavefronts
  SQ_WAVES SQ_WAVE_CYCLES SQ_BUSY_CYCLES FETCH_SIZE WRITE_SIZE L2CacheHit
  GL2C_HIT_sum GL2C_MISS_sum MemUnitBusy LDSBankConflict VALUInsts SALUInsts
  WriteUnitStalled SQ_INSTS_FLAT SQ_INSTS_LDS SQ_INSTS_SALU SQ_INSTS_SMEM
  SQ_INSTS_TEX_LOAD SQ_INSTS_TEX_STORE SQ_INSTS_VALU
)
for counter in "${counters[@]}"; do
  pass_dir=${out_dir}/${counter}; mkdir -p "${pass_dir}"
  timeout -k 5 90 env -u LD_LIBRARY_PATH "${rocm}/bin/rocprofv3" \
    --disable-signal-handlers true -d "${pass_dir}" -o trace \
    --pmc "${counter}" -f csv -- "${binary}" \
    "${baseline}" "${candidate}" "${repacker}" 1276 1 >"${pass_dir}/run.log" 2>&1
  echo "gfx1151 measured prefill-gate counter ${counter}: PASS"
done
/root/sglvenv1151/bin/python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" --kernel-prefix mxfp4_prefill_gate_wmma_gfx1151 \
  --input-scope "synthetic nonzero exact Qwen3.6 G1276 M64 N512 K2048 E256 baseline layout" \
  --out "${out_dir}/baseline-summary.json" >"${out_dir}/baseline-summary.stdout"
/root/sglvenv1151/bin/python "${repo_dir}/tools/profiling/summarize_rocprof_counters.py" \
  "${out_dir}" --kernel-prefix mxfp4_prefill_gate_dword_layout_gfx1151 \
  --input-scope "synthetic nonzero exact Qwen3.6 G1276 M64 N512 K2048 E256 dword layout" \
  --out "${out_dir}/candidate-summary.json" >"${out_dir}/candidate-summary.stdout"
echo "gfx1151 measured prefill-gate counter reports: ${out_dir}"
