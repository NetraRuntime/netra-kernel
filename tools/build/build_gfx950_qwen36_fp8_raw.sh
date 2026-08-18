#!/usr/bin/env bash
set -euo pipefail

# Compatibility entry point for older MoE harnesses. Assembly instances are no
# longer checked in or compiled directly: the model-independent tactic catalog
# generates the complete locked deployment artifact set into the build tree.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
default_repo=$(cd -- "$script_dir/../.." && pwd)
repo_dir=${1:-$default_repo}
out_dir=${2:-$repo_dir/build/gfx950-qwen36-fp8}
rocm_dir=${ROCM_DIR:-/opt/rocm}
hipcc_bin=${HIPCC_BIN:-$rocm_dir/bin/hipcc}
stem=qwen36_moe_silu_mul_quant_fp8_gfx950
harness=$repo_dir/harness/gfx950/fp8/moe/decode/${stem}.hip
bridge=$repo_dir/runtime/gfx950/fp8/moe/qwen36_moe_silu_mul_quant_bridge.hip
bridge_header=$repo_dir/runtime/gfx950/fp8/moe/qwen36_moe_silu_mul_quant_bridge.h

bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" "$out_dir"

if [[ ! -x $hipcc_bin ]]; then
  echo "required HIP compiler is unavailable: $hipcc_bin" >&2
  exit 2
fi
harness_binary=$out_dir/${stem}_harness
bridge_library=$out_dir/lib${stem}_bridge.so
if [[ ! -x $harness_binary || $harness -nt $harness_binary ]]; then
  "$hipcc_bin" --offload-arch=gfx950 -O3 "$harness" -o "$harness_binary"
fi
if [[ ! -e $bridge_library || $bridge -nt $bridge_library ||
      $bridge_header -nt $bridge_library ]]; then
  "$hipcc_bin" --offload-arch=gfx950 -O3 -fPIC -shared \
    "$bridge" -o "$bridge_library"
fi
(
  cd "$out_dir"
  sha256sum ./*.hsaco "$stem"_harness "lib${stem}_bridge.so" > SHA256SUMS
)
echo "gfx950 tactic-catalog compatibility build complete: $out_dir"
