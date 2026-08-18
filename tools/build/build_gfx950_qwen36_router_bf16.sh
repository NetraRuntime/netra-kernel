#!/usr/bin/env bash
set -euo pipefail

# Compatibility harness/bridge builder for the cataloged router tactic.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd -- "$script_dir/../.." && pwd)}
out_dir=${2:-$repo_dir/build/gfx950-qwen36-router-bf16}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_router_bf16_gemv_gfx950
harness=$repo_dir/harness/gfx950/routing/verify/${stem}.hip
bridge=$repo_dir/runtime/gfx950/routing/verify/qwen36_router_bf16_bridge.hip
header_dir=$repo_dir/runtime/gfx950/routing/verify

bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" "$out_dir"
harness_binary=$out_dir/${stem}_harness
bridge_library=$out_dir/libqwen36_router_bf16_bridge.so
if [[ ! -x $harness_binary || $harness -nt $harness_binary ]]; then
  "$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 "$harness" -o "$harness_binary"
fi
if [[ ! -e $bridge_library || $bridge -nt $bridge_library ]]; then
  "$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 -std=c++17 -fPIC -shared \
    -I"$header_dir" "$bridge" -o "$bridge_library"
fi
echo "gfx950 catalog router harness build complete: $out_dir"
