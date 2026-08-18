#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
python_bin=${PYTHON:-python3}

export PYTHONPATH="$repo_root/compiler${PYTHONPATH:+:$PYTHONPATH}"
cd "$repo_root"

"$python_bin" -m compileall -q compiler/netra_compiler tools/compiler tools/ci tests/compiler
"$python_bin" -m unittest discover -s tests/compiler -v
"$python_bin" tools/ci/check_repository.py
"$python_bin" tools/compiler/validate_gfx950_tactic_catalog.py
"$python_bin" tools/ci/compile_examples.py

while IFS= read -r -d '' shell_file; do
  bash -n "$shell_file"
done < <(git ls-files -z '*.sh')

git diff --check
