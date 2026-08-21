#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd -- "$script_dir/../.." && pwd)}
out_dir=${2:-$repo_dir/build/gfx950-moe-prefill-m768}
rocm_dir=${ROCM_DIR:-/opt/rocm}

python3 "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.py" \
  --repo-root "$repo_dir" \
  --deployment manifests/gfx950/deployments/qwen36-35b-c64-current-best.json \
  --output "$out_dir" \
  --rocm-dir "$rocm_dir"

"$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 -fPIC -shared \
  -I"$repo_dir/runtime/gfx950/fp8/moe" \
  "$repo_dir/runtime/gfx950/fp8/moe/moe_prefill_m768_bridge.hip" \
  -o "$out_dir/libnetra_moe_prefill_m768_bridge.so"

(
  cd "$out_dir"
  sha256sum ./*.hsaco ./libnetra_moe_prefill_m768_bridge.so > SHA256SUMS
)
