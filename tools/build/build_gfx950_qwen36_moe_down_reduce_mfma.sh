#!/usr/bin/env bash
set -euo pipefail

# Compatibility harness builder for the accepted two-wave down/reduce tactic.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd -- "$script_dir/../.." && pwd)}
out_dir=${2:-$repo_dir/build/gfx950-qwen36-moe-down-reduce-mfma}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=${STEM:-qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950}
expected=qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
harness=$repo_dir/harness/gfx950/fp8/moe/decode/qwen36_moe_down_reduce_fp8_gfx950.hip

if [[ $stem != "$expected" || -n ${KERNEL_SOURCE:-} ]]; then
  echo "only the cataloged accepted tactic $expected is supported" >&2
  exit 2
fi
bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" "$out_dir"
harness_binary=$out_dir/${stem}_harness
if [[ ! -x $harness_binary || $harness -nt $harness_binary ]]; then
  "$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 "$harness" -o "$harness_binary"
fi
echo "gfx950 catalog down/reduce harness build complete: $out_dir"
