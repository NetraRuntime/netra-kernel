#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
output_dir=${1:-"$repo_root/build/gfx950-tactic-catalog"}
deployment=${2:-"$repo_root/manifests/gfx950/deployments/qwen36-35b-current-best.json"}

PYTHONPATH="$repo_root/compiler${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$repo_root/tools/compiler/build_gfx950_tactic_catalog.py" \
  --repo-root "$repo_root" \
  --deployment "$deployment" \
  --output "$output_dir"
