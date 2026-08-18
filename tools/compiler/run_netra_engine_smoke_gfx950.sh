#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 ENGINE_DIR" >&2
  exit 2
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
runtime_dir="$repo_dir/build/gfx950-netra-engine-runtime"
runtime_library=$(bash "$script_dir/build_netra_engine_runtime_gfx950.sh" "$runtime_dir")
"${ROCM_DIR:-/opt/rocm}/bin/hipcc" --offload-arch=gfx950 -std=c++17 -O2 \
  "$repo_dir/harness/gfx950/engine/netra_engine_smoke.hip" \
  -L"$runtime_dir" -lnetra_engine_gfx950 -Wl,-rpath,"$runtime_dir" \
  -o "$runtime_dir/netra_engine_smoke"
"$runtime_dir/netra_engine_smoke" "$1"
