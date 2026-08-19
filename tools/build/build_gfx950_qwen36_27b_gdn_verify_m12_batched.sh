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
bridge=$repo_dir/runtime/gfx950/linear_attention/verify/qwen36_27b_gdn_verify_m12_batched_bridge.hip
header_dir=$repo_dir/runtime/gfx950/linear_attention/verify

bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" "$out_dir" "$deployment"
cp -f "$out_dir/qwen36_27b_gdn_verify_m12_batched_precompute_gfx950.hsaco" \
  "$out_dir/precompute.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_verify_m12_batched_precomputed_bv16_gfx950.hsaco" \
  "$out_dir/core.hsaco"
cp -f "$out_dir/qwen36_27b_gdn_verify_m12_batched_precompute_gates_gfx950.hsaco" \
  "$out_dir/precompute-gates.hsaco"
bridge_library=$out_dir/libqwen36_27b_gdn_verify_m12_batched_bridge.so
if [[ ! -e $bridge_library || $bridge -nt $bridge_library ]]; then
  "$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC -shared \
    -I"$header_dir" "$bridge" -o "$bridge_library"
fi
(cd "$out_dir" && sha256sum precompute.hsaco precompute-gates.hsaco core.hsaco \
  libqwen36_27b_gdn_verify_m12_batched_bridge.so > SHA256SUMS)
echo "gfx950 HV48 M=12 GDN verification build complete: $out_dir"
