#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-qwen36-gdn-verify-m12-batched"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
kernel_dir=${repo_dir}/kernels/gfx950/linear_attention/verify
precompute_stem=qwen36_gdn_verify_m12_batched_precompute_gfx950
core_stem=qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
precompute=${kernel_dir}/${precompute_stem}.s
core=${kernel_dir}/${core_stem}.s
bridge=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_verify_m12_batched_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_verify_m12_batched_bridge.h
# M=12 general target verification keeps FP32 live state across positions,
# uses the ordinary FP32 sigmoid boundary, and retains the packed per-V Q dot
# order emitted by the deployed gfx950 Triton kernel.
core_variant=${NETRA_GDN_CORE_VARIANT:-fused-packed-exact}
precompute_variant=${NETRA_GDN_PRECOMPUTE_VARIANT:-triton-exact}
k0_no_intermediate=${NETRA_GDN_K0_NO_INTERMEDIATE:-0}
waves_per_workgroup=${NETRA_GDN_WAVES_PER_WORKGROUP:-1}
share_qk=${NETRA_GDN_SHARE_QK:-1}
dynamic_wavegroups=${NETRA_GDN_DYNAMIC_WAVEGROUPS:-0}

case "$core_variant" in
  original) core_variant_id=0 ;;
  triton) core_variant_id=1 ;;
  forward-xor) core_variant_id=2 ;;
  reverse-scan) core_variant_id=3 ;;
  balanced-xor) core_variant_id=4 ;;
  forward-k-forward-q-fma) core_variant_id=5 ;;
  forward-k-reverse-q-fma) core_variant_id=6 ;;
  forward-k-reverse-q-add) core_variant_id=7 ;;
  forward-k-balanced-q-add) core_variant_id=8 ;;
  fused-exact) core_variant_id=13 ;;
  forward-k-q-fma-10234567) core_variant_id=9 ;;
  forward-k-q-fma-10325476) core_variant_id=10 ;;
  forward-k-q-fma-76452301) core_variant_id=11 ;;
  forward-k-q-fma-76543210) core_variant_id=12 ;;
  fused-packed-exact) core_variant_id=13 ;;
  fused-packed-decode-state) core_variant_id=14 ;;
  fused-packed-decode-sequence) core_variant_id=15 ;;
  packed-pair-chains) core_variant_id=16 ;;
  packed-pair-interleaved) core_variant_id=17 ;;
  *)
    echo "Unsupported NETRA_GDN_CORE_VARIANT: $core_variant" >&2
    exit 2
    ;;
esac

case "$k0_no_intermediate" in
  0 | 1) ;;
  *)
    echo "NETRA_GDN_K0_NO_INTERMEDIATE must be 0 or 1" >&2
    exit 2
    ;;
esac

if [[ "$k0_no_intermediate" == 1 && "$core_variant_id" != 13 && "$core_variant_id" != 16 && "$core_variant_id" != 17 ]]; then
  echo "K0 no-intermediate verification requires fused-exact or packed-pair arithmetic" >&2
  exit 2
fi

case "$waves_per_workgroup" in
  1 | 2 | 4 | 8) ;;
  *)
    echo "NETRA_GDN_WAVES_PER_WORKGROUP must be 1, 2, 4, or 8" >&2
    exit 2
    ;;
esac
case "$share_qk" in
  0 | 1) ;;
  *)
    echo "NETRA_GDN_SHARE_QK must be 0 or 1" >&2
    exit 2
    ;;
esac
case "$dynamic_wavegroups" in
  0 | 1) ;;
  *)
    echo "NETRA_GDN_DYNAMIC_WAVEGROUPS must be 0 or 1" >&2
    exit 2
    ;;
esac
if [[ "$dynamic_wavegroups" == 1 && "$k0_no_intermediate" != 1 ]]; then
  echo "Dynamic wavegroup selection is validated only for K0 verification" >&2
  exit 2
fi

case "$precompute_variant" in
  original) precompute_variant_id=0 ;;
  triton-reduce-rcp) precompute_variant_id=1 ;;
  triton-div) precompute_variant_id=2 ;;
  original-reduce-div) precompute_variant_id=3 ;;
  triton-div-no-fixup) precompute_variant_id=4 ;;
  triton-contiguous-exact) precompute_variant_id=5 ;;
  triton-contiguous-exact-gates) precompute_variant_id=6 ;;
  triton-exact) precompute_variant_id=7 ;;
  packed-decode-beta) precompute_variant_id=8 ;;
  *)
    echo "Unsupported NETRA_GDN_PRECOMPUTE_VARIANT: $precompute_variant" >&2
    exit 2
    ;;
esac

mkdir -p "$out_dir"
rocminfo_text=$(rocminfo 2>/dev/null)
grep -q 'Name:[[:space:]]*gfx950' <<<"$rocminfo_text"

build_kernel() {
  local source_file=$1
  local stem=$2
  shift 2
  "${rocm_dir}/llvm/bin/clang" -target amdgcn-amd-amdhsa -mcpu=gfx950 \
    -mwavefrontsize64 -x assembler "$@" -c "$source_file" \
    -o "${out_dir}/${stem}.o"
  "${rocm_dir}/llvm/bin/ld.lld" -shared "${out_dir}/${stem}.o" \
    -o "${out_dir}/${stem}.hsaco"
  "${rocm_dir}/llvm/bin/llvm-objdump" --disassemble --mcpu=gfx950 \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.disassembly.txt"
  "${rocm_dir}/llvm/bin/llvm-readobj" --notes \
    "${out_dir}/${stem}.hsaco" > "${out_dir}/${stem}.metadata.txt"
  grep -q 'amdgcn-amd-amdhsa--gfx950' "${out_dir}/${stem}.metadata.txt"
  grep -q 'wavefront_size:[[:space:]]*64' "${out_dir}/${stem}.metadata.txt"
  grep -q 'private_segment_fixed_size:[[:space:]]*0' \
    "${out_dir}/${stem}.metadata.txt"
}

build_kernel "$precompute" "$precompute_stem" \
  -Wa,-defsym,NETRA_GDN_PRECOMPUTE_VARIANT="$precompute_variant_id"
build_core() {
  local stem=$1
  local waves=$2
  build_kernel "$core" "$stem" \
    -Wa,-defsym,NETRA_GDN_CORE_VARIANT="$core_variant_id" \
    -Wa,-defsym,NETRA_GDN_K0_NO_INTERMEDIATE="$k0_no_intermediate" \
    -Wa,-defsym,NETRA_GDN_WAVES_PER_WORKGROUP="$waves" \
    -Wa,-defsym,NETRA_GDN_SHARE_QK="$share_qk"
}

if [[ "$dynamic_wavegroups" == 1 ]]; then
  build_core "$core_stem" 1
  build_core "${core_stem}_waves4" 4
  build_core "${core_stem}_waves8" 8
else
  build_core "$core_stem" "$waves_per_workgroup"
fi
grep -q 'v_exp_f32' "${out_dir}/${precompute_stem}.disassembly.txt"
grep -q 'v_log_f32' "${out_dir}/${precompute_stem}.disassembly.txt"
grep -q 'v_sqrt_f32' "${out_dir}/${precompute_stem}.disassembly.txt"
grep -q 'v_pk_fma_f32' "${out_dir}/${core_stem}.disassembly.txt"
validate_core() {
  local stem=$1
  grep -q 'v_pk_fma_f32' "${out_dir}/${stem}.disassembly.txt"
  if [[ "$core_variant_id" == 0 || "$core_variant_id" == 3 ]]; then
    grep -q 'ds_bpermute_b32' "${out_dir}/${stem}.disassembly.txt"
  else
    ! grep -q 'ds_bpermute_b32' "${out_dir}/${stem}.disassembly.txt"
    grep -q 'row_shl:8' "${out_dir}/${stem}.disassembly.txt"
    grep -q 'quad_perm:\[2,3,0,1\]' "${out_dir}/${stem}.disassembly.txt"
  fi
  if [[ "$k0_no_intermediate" == 1 ]]; then
    ! grep -q 'global_store_dwordx4' "${out_dir}/${stem}.disassembly.txt"
  fi
}
validate_core "$core_stem"
if [[ "$dynamic_wavegroups" == 1 ]]; then
  validate_core "${core_stem}_waves4"
  validate_core "${core_stem}_waves8"
fi

bridge_library=${out_dir}/libqwen36_gdn_verify_m12_batched_bridge.so
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -DNETRA_GDN_WAVES_PER_WORKGROUP="$waves_per_workgroup" \
  -shared "$bridge" -o "$bridge_library"

hash_inputs=(
  "$precompute"
  "$core"
  "$bridge"
  "$bridge_header"
  "${out_dir}/${precompute_stem}.hsaco"
  "${out_dir}/${core_stem}.hsaco"
)
if [[ "$dynamic_wavegroups" == 1 ]]; then
  hash_inputs+=(
    "${out_dir}/${core_stem}_waves4.hsaco"
    "${out_dir}/${core_stem}_waves8.hsaco"
  )
fi
hash_inputs+=("$bridge_library")
sha256sum "${hash_inputs[@]}" > "${out_dir}/sha256sums.txt"

{
  printf 'core_variant=%s\n' "$core_variant"
  printf 'core_variant_id=%s\n' "$core_variant_id"
  printf 'precompute_variant=%s\n' "$precompute_variant"
  printf 'precompute_variant_id=%s\n' "$precompute_variant_id"
  printf 'k0_no_intermediate=%s\n' "$k0_no_intermediate"
  printf 'waves_per_workgroup=%s\n' "$waves_per_workgroup"
  printf 'share_qk=%s\n' "$share_qk"
  printf 'dynamic_wavegroups=%s\n' "$dynamic_wavegroups"
  if [[ "$dynamic_wavegroups" == 1 ]]; then
    printf 'wavegroup_selector=batch<4:w1,4<=batch<8:w4,8<=batch<=16:w8,batch>16:w4\n'
  fi
  printf 'target=gfx950\nwavefront_size=64\n'
} > "${out_dir}/build-variant.txt"

echo "gfx950 Qwen GDN M12 batched verify pipeline build complete: ${out_dir}"
