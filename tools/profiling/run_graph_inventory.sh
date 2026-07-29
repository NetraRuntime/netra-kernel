#!/usr/bin/env bash
set -euo pipefail
# Execute inside the Netra LXC against an already-started graph server.
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
url=${NETRA_URL:-http://127.0.0.1:30000}
out_dir=${1:?usage: run_graph_inventory.sh OUTPUT_DIR [GRAPH_MODE]}
graph_mode=${2:-full-decode-bs1}
mkdir -p "${out_dir}"
for attempt in $(seq 1 360); do
  if curl -fsS "${url}/health" >/dev/null 2>&1; then break; fi
  if (( attempt == 360 )); then echo "server health timeout" >&2; exit 1; fi
  sleep 5
done
run_case() {
  local name=$1 input_len=$2 output_len=$3
  python "${repo_dir}/tools/profiling/request_scenario.py" \
    --url "${url}/generate" --input-len "${input_len}" --output-len "${output_len}" \
    --seed "gfx1151-graph-correctness-${name}" --label "${name}-${graph_mode}" \
    --graph-mode "${graph_mode}" --dflash-mode disabled --stream \
    --output "${out_dir}/${name}.json" >"${out_dir}/${name}.stdout" \
    2>"${out_dir}/${name}.stderr"
}
# Unique warmup input prevents any measured request from becoming cached.
python "${repo_dir}/tools/profiling/request_scenario.py" \
  --url "${url}/generate" --input-len 7 --output-len 4 \
  --seed gfx1151-graph-warmup --label graph-warmup \
  --graph-mode "${graph_mode}" --dflash-mode disabled --stream \
  --output "${out_dir}/warmup.json" >"${out_dir}/warmup.stdout" \
  2>"${out_dir}/warmup.stderr"
run_case short-prefill 16 1
run_case prefill-210 210 1
run_case prefill-chunk-8192 8192 1
run_case prefill-32768 32768 1
run_case decode-m1 1 32
run_case serving-210-in-128-out 210 128
echo "gfx1151 measured ${graph_mode} inventory: ${out_dir}"
