#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
python_bin=${PYTHON:-python3}
output_dir=$repo_root/build/wheels

mkdir -p "$output_dir"
if "$python_bin" -m pip --version >/dev/null 2>&1; then
  "$python_bin" -m pip wheel --no-deps "$repo_root/compiler" \
    --wheel-dir "$output_dir"
elif command -v uv >/dev/null 2>&1; then
  uv build --wheel "$repo_root/compiler" --out-dir "$output_dir"
else
  echo "package build requires pip for $python_bin or the uv executable" >&2
  exit 127
fi
