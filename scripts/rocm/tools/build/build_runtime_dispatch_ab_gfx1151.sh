#!/usr/bin/env bash
set -euo pipefail

[[ $(hostname) == Netra ]] || {
  echo "must run inside the Netra LXC" >&2
  exit 1
}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(git -C "$script_dir" rev-parse --show-toplevel)}
out=${2:-${repo_dir}/build/runtime-refactor/benchmark_runtime_dispatch_ab}
hipcc=/opt/rocm-7.2.1/bin/hipcc
[[ -x $hipcc ]] || { echo "missing $hipcc" >&2; exit 1; }
detected=$(/opt/rocm-7.2.1/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }
mkdir -p "$(dirname "$out")"
"$hipcc" --offload-arch=gfx1151 -O3 -std=c++17 \
  "${repo_dir}/scripts/rocm/harness/gfx1151/runtime/benchmark_runtime_dispatch_ab.hip" \
  -ldl -o "$out"
echo "$out"
