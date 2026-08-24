#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 ENGINE_DIR" >&2
  exit 2
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
engine_dir=$(realpath "$1")
build_dir="$repo_dir/build/gfx950-netra-engine-runtime"
mkdir -p "$build_dir"
hipcc -std=c++17 -O2 -fPIC -shared \
  "$repo_dir/runtime/gfx950/engine/netra_engine.hip" \
  -Wl,-soname,libnetra_engine.so.1 -o "$build_dir/libnetra_engine.so.1.0.0"
ln -sfn libnetra_engine.so.1.0.0 "$build_dir/libnetra_engine.so.1"
ln -sfn libnetra_engine.so.1 "$build_dir/libnetra_engine.so"
hipcc -std=c++17 -O2 \
  "$repo_dir/harness/gfx950/engine/netra_engine_qwen36_moe_m1_smoke.hip" \
  -L"$build_dir" -lnetra_engine \
  -Wl,-rpath,"$build_dir" \
  -o "$build_dir/netra_engine_qwen36_moe_m1_smoke"
"$build_dir/netra_engine_qwen36_moe_m1_smoke" "$engine_dir"
