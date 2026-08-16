#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/lib/gfx950_assembly.sh"
repo_dir=${1:-$(cd "${script_dir}/../.." && pwd)}
out_dir=${2:-"${repo_dir}/build/gfx950-gdn-replay-b64-t12-h16-hv32-k128-v128"}
rocm_dir=${ROCM_DIR:-/opt/rocm}
kernel_dir=${repo_dir}/kernels/gfx950/linear_attention/verify
precompute_stem=qwen36_gdn_verify_m12_batched_precompute_gfx950
core_source=${kernel_dir}/qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950.s
precompute=${kernel_dir}/${precompute_stem}.s
bridge=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_state_replay_m12_bridge.hip
bridge_header=${repo_dir}/runtime/gfx950/linear_attention/verify/qwen36_gdn_state_replay_m12_bridge.h

mkdir -p "$out_dir"
netra_gfx950_require_device

netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" \
  "$precompute" "$precompute_stem" \
  -Wa,-defsym,NETRA_GDN_PRECOMPUTE_VARIANT=7

core_stems=()
for waves in 1 4 8; do
  stem=qwen36_gdn_state_replay_m12_waves${waves}_gfx950
  core_stems+=("$stem")
  netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" \
    "$core_source" "$stem" \
    -Wa,-defsym,NETRA_GDN_CORE_VARIANT=13 \
    -Wa,-defsym,NETRA_GDN_K0_NO_INTERMEDIATE=1 \
    -Wa,-defsym,NETRA_GDN_STATE_REPLAY=1 \
    -Wa,-defsym,NETRA_GDN_WAVES_PER_WORKGROUP="$waves" \
    -Wa,-defsym,NETRA_GDN_SHARE_QK=1
  grep -q 'v_pk_fma_f32' "${out_dir}/${stem}.disassembly.txt"
  ! grep -q 'global_store_short' "${out_dir}/${stem}.disassembly.txt"
done

dual_core_stems=()
for waves in 1 4 8; do
  stem=qwen36_gdn_state_replay_m12_dual_waves${waves}_gfx950
  dual_core_stems+=("$stem")
  netra_gfx950_build_wave64_kernel "$rocm_dir" "$out_dir" \
    "$core_source" "$stem" \
    -Wa,-defsym,NETRA_GDN_CORE_VARIANT=13 \
    -Wa,-defsym,NETRA_GDN_K0_NO_INTERMEDIATE=1 \
    -Wa,-defsym,NETRA_GDN_STATE_REPLAY=1 \
    -Wa,-defsym,NETRA_GDN_STATE_REPLAY_DUAL=1 \
    -Wa,-defsym,NETRA_GDN_WAVES_PER_WORKGROUP="$waves" \
    -Wa,-defsym,NETRA_GDN_SHARE_QK=1
  grep -q 'qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950' \
    "${out_dir}/${stem}.disassembly.txt"
  grep -q 'v_pk_fma_f32' "${out_dir}/${stem}.disassembly.txt"
  ! grep -q 'global_store_short' "${out_dir}/${stem}.disassembly.txt"
done

bridge_library=${out_dir}/libqwen36_gdn_state_replay_m12_bridge.so
"${rocm_dir}/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC \
  -shared "$bridge" -o "$bridge_library"

hash_inputs=(
  "$precompute"
  "$core_source"
  "$bridge"
  "$bridge_header"
  "${out_dir}/${precompute_stem}.hsaco"
)
for stem in "${core_stems[@]}"; do
  hash_inputs+=("${out_dir}/${stem}.hsaco")
done
for stem in "${dual_core_stems[@]}"; do
  hash_inputs+=("${out_dir}/${stem}.hsaco")
done
hash_inputs+=("$bridge_library")
sha256sum "${hash_inputs[@]}" > "${out_dir}/sha256sums.txt"

{
  printf 'target=gfx950\nwavefront_size=64\n'
  printf 'precompute_variant=triton-exact\nprecompute_variant_id=7\n'
  printf 'core_variant=fused-exact\ncore_variant_id=13\n'
  printf 'state_replay=1\nk0_no_intermediate=1\n'
  printf 'waves_per_workgroup=1 4 8\nshare_k=1\n'
  printf 'dual_destination_state_replay=1\n'
} > "${out_dir}/build-variant.txt"

echo "gfx950 Qwen GDN M12 state-replay build complete: ${out_dir}"
