#!/usr/bin/env bash
set -euo pipefail

# Compatibility harness builder. The HSACO is generated from the tactic catalog.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=${1:-$(cd -- "$script_dir/../.." && pwd)}
out_dir=${2:-$repo_dir/build/gfx950-qwen36-moe-gate-up-mfma}
rocm_dir=${ROCM_DIR:-/opt/rocm}
stem=qwen36_moe_gate_up_fp8_mfma_gfx950
harness=$repo_dir/harness/gfx950/fp8/moe/decode/${stem}.hip

if [[ -n ${KERNEL_SOURCE:-} ]]; then
  echo "KERNEL_SOURCE is no longer supported; add a catalog tactic/build recipe" >&2
  exit 2
fi
bash "$repo_dir/tools/compiler/build_gfx950_tactic_catalog.sh" "$out_dir"
binary=$out_dir/${stem}_harness
if [[ ! -x $binary || $harness -nt $binary ]]; then
  "$rocm_dir/bin/hipcc" --offload-arch=gfx950 -O3 "$harness" -o "$binary"
fi
echo "gfx950 catalog gate/up harness build complete: $out_dir"
