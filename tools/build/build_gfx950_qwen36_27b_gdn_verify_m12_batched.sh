#!/usr/bin/env bash
set -euo pipefail

# Bridge builder for the verified HV48 M=12 K0 GDN verification tactics.
# Produces the serving layout expected by the SGLang integration:
#   precompute.hsaco, core.hsaco,
#   libqwen36_27b_gdn_verify_m12_batched_bridge.so
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd -- "$script_dir/../.." && pwd)}
out_dir=${2:-$repo_dir/build/gfx950-qwen36-27b-gdn-verify-m12}
rocm_dir=${ROCM_DIR:-/opt/rocm}
deployment=$repo_dir/manifests/gfx950/deployments/qwen36-27b-gdn-verify-m12-hv48.json
qkvz_t8_deployment=$repo_dir/manifests/gfx950/deployments/qwen36-27b-gdn-qkvz-conv-t8.json
bf16_state_t8_deployment=$repo_dir/manifests/gfx950/deployments/qwen36-27b-gdn-bf16-state-t8.json
bridge=$repo_dir/runtime/gfx950/linear_attention/verify/qwen36_27b_gdn_verify_m12_batched_bridge.hip
header_dir=$repo_dir/runtime/gfx950/linear_attention/verify

bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" "$out_dir" "$deployment"
bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" \
  "$out_dir/qkvz-t8-build" "$qkvz_t8_deployment"
bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" \
  "$out_dir/bf16-state-t8-build" "$bf16_state_t8_deployment"
cp -f "$out_dir/qwen36_27b_gdn_verify_m12_batched_precompute_gfx950.hsaco" \
  "$out_dir/precompute.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_verify_m12_batched_precomputed_bv16_gfx950.hsaco" \
  "$out_dir/core.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_verify_m12_batched_precompute_gates_gfx950.hsaco" \
  "$out_dir/precompute-gates.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_state_replay_m12_fp32_gfx950.hsaco" \
  "$out_dir/replay.hsaco"
mkdir -p "$out_dir/t8"
cp -f "$out_dir/qwen36_27b_gdn_verify_m8_batched_precompute_gfx950.hsaco" \
  "$out_dir/t8/precompute.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_verify_m8_batched_precompute_gates_gfx950.hsaco" \
  "$out_dir/t8/precompute-gates.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_verify_m8_batched_precomputed_bv16_gfx950.hsaco" \
  "$out_dir/t8/core.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_state_replay_m8_fp32_gfx950.hsaco" \
  "$out_dir/t8/replay.hsaco"
cp -f "$out_dir/qkvz-t8-build/netra_gdn_qkvz_conv_t8_d10240_gfx950.hsaco" \
  "$out_dir/t8/qkvz-conv.hsaco"
mkdir -p "$out_dir/t8-bf16"
cp -f "$out_dir/t8/precompute.hsaco" "$out_dir/t8-bf16/precompute.hsaco"
cp -f "$out_dir/t8/precompute-gates.hsaco" \
  "$out_dir/t8-bf16/precompute-gates.hsaco"
cp -f "$out_dir/t8/qkvz-conv.hsaco" "$out_dir/t8-bf16/qkvz-conv.hsaco"
cp -f \
  "$out_dir/bf16-state-t8-build/netra_gdn_verify_t8_bv16_hv48_k0_bf16_state_gfx950.hsaco" \
  "$out_dir/t8-bf16/core.hsaco"
cp -f \
  "$out_dir/bf16-state-t8-build/netra_gdn_state_replay_t8_bv16_hv48_bf16_state_gfx950.hsaco" \
  "$out_dir/t8-bf16/replay.hsaco"
bridge_library=$out_dir/libqwen36_27b_gdn_verify_m12_batched_bridge.so
if [[ ! -e $bridge_library || $bridge -nt $bridge_library ]]; then
  "$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC -shared \
    -I"$header_dir" "$bridge" -o "$bridge_library"
fi
(cd "$out_dir" && sha256sum precompute.hsaco precompute-gates.hsaco core.hsaco replay.hsaco \
  t8/qkvz-conv.hsaco \
  t8-bf16/core.hsaco t8-bf16/replay.hsaco t8-bf16/qkvz-conv.hsaco \
  libqwen36_27b_gdn_verify_m12_batched_bridge.so > SHA256SUMS)
echo "gfx950 HV48 M=12 GDN verification build complete: $out_dir"
