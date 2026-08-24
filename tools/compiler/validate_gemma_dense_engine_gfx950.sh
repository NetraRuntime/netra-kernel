#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 ENGINE_DIR" >&2
  exit 2
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../.." && pwd)
PYTHONPATH="$repo_dir/compiler" python3 -m netra_compiler.cli validate --engine "$1" --static
echo "Gemma fixture is synthetic: real-checkpoint correctness and performance were not run."
