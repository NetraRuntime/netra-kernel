#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
out_dir=${1:-$repo_dir/build/gfx950-netra-engine-runtime}
rocm_dir=${ROCM_DIR:-/opt/rocm}
hipcc=$rocm_dir/bin/hipcc
if [[ ! -x "$hipcc" ]]; then
  hipcc=$(command -v hipcc || true)
fi
if [[ -z "$hipcc" || ! -x "$hipcc" ]]; then
  echo "ROCm hipcc not found; set ROCM_DIR to a ROCm installation containing bin/hipcc" >&2
  exit 127
fi
mkdir -p "$out_dir"
"$hipcc" --offload-arch=gfx950 -std=c++17 -O3 -fPIC -shared \
  "$repo_dir/runtime/gfx950/engine/netra_engine.hip" \
  -o "$out_dir/libnetra_engine_gfx950.so"
echo "$out_dir/libnetra_engine_gfx950.so"
