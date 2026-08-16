#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/lib/gfx950_assembly.sh"
source "${script_dir}/lib/gdn_variants.sh"
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-gdn-verify-b64-t12-h16-hv32-k128-v128-k0"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
kernel_dir=${repo_dir}/kernels/gfx950/linear_attention/verify
precompute_stem=qwen36_gdn_verify_m12_batched_precompute_gfx950
core_stem=qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
precompute=${kernel_dir}/${precompute_stem}.s
core=${kernel_dir}/${core_stem}.s
bridge=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_verify_m12_batched_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_verify_m12_batched_bridge.h
# M=12 general target verification keeps FP32 live state across positions and
# uses the ordinary FP32 sigmoid boundary. Variant 17 is the production serving
# default after the 2026-08-16 five-run 1K/1K DFlash gate. Select
# NETRA_GDN_CORE_VARIANT=fused-packed-exact for the bit-exact rollback.
core_variant=${NETRA_GDN_CORE_VARIANT:-packed-pair-interleaved}
precompute_variant=${NETRA_GDN_PRECOMPUTE_VARIANT:-triton-exact}
k0_no_intermediate=${NETRA_GDN_K0_NO_INTERMEDIATE:-0}
waves_per_workgroup=${NETRA_GDN_WAVES_PER_WORKGROUP:-1}
share_qk=${NETRA_GDN_SHARE_QK:-1}
dynamic_wavegroups=${NETRA_GDN_DYNAMIC_WAVEGROUPS:-0}

core_variant_id=$(netra_gdn_core_variant_id "$core_variant" m12)

case "$k0_no_intermediate" in
  0 | 1) ;;
  *)
    echo "NETRA_GDN_K0_NO_INTERMEDIATE must be 0 or 1" >&2
    exit 2
    ;;
esac

if [[ "$k0_no_intermediate" == 1 && "$core_variant_id" != 13 && "$core_variant_id" != 16 && "$core_variant_id" != 17 && "$core_variant_id" != 18 ]]; then
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

precompute_variant_id=$(netra_gdn_precompute_variant_id "$precompute_variant")

mkdir -p "$out_dir"
netra_gfx950_require_device

netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" \
  "$precompute" "$precompute_stem" \
  -Wa,-defsym,NETRA_GDN_PRECOMPUTE_VARIANT="$precompute_variant_id"
build_core() {
  local stem=$1
  local waves=$2
  netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" "$core" "$stem" \
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
