#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 ENGINE_DIR" >&2
  exit 2
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
engine_dir=$1
test -f "$engine_dir/engine.json"
PYTHONPATH="$repo_dir/compiler" python3 -m netra_compiler.cli validate \
  --engine "$engine_dir" --static --build
