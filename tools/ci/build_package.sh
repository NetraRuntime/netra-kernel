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
  "$python_bin" -m pip wheel --no-deps "$repo_root" \
    --wheel-dir "$output_dir"
elif command -v uv >/dev/null 2>&1; then
  uv build --wheel "$repo_root/compiler" --out-dir "$output_dir"
  uv build --wheel "$repo_root" --out-dir "$output_dir"
else
  echo "package build requires pip for $python_bin or the uv executable" >&2
  exit 127
fi

deployment_wheel=$(find "$output_dir" -maxdepth 1 -type f \
  -name 'netra_kernel-*.whl' -print -quit)
if [[ -z "$deployment_wheel" ]]; then
  echo "package build did not produce a netra-kernel wheel" >&2
  exit 1
fi
compiler_wheel=$(find "$output_dir" -maxdepth 1 -type f \
  -name 'netra_compiler-*.whl' -print -quit)
if [[ -z "$compiler_wheel" ]]; then
  echo "package build did not produce a netra-compiler wheel" >&2
  exit 1
fi
"$python_bin" "$repo_root/tools/ci/smoke_compiler_package.py" "$compiler_wheel"
"$python_bin" "$repo_root/tools/ci/smoke_package.py" "$deployment_wheel"
