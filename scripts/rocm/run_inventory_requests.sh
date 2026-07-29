#!/usr/bin/env bash
set -euo pipefail
[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
repo=/root/netra-mxfp4-gfx1151
run_tag=${RUN_TAG:?set RUN_TAG to the combined trace run tag}
out_dir=${repo}/results/profiles/gfx1151/${run_tag}/requests
mkdir -p "$out_dir"

until curl -fsS --max-time 5 http://127.0.0.1:30000/health >/dev/null; do
  sleep 5
done
# The first health call may perform lazy warmup with --skip-server-warmup.
curl -fsS --max-time 60 http://127.0.0.1:30000/health >/dev/null
sleep 5

run_case() {
  local name=$1 input_len=$2 output_len=$3
  local label=${name}-${run_tag}
  local extra_args=()
  if [[ -n ${NETRA_SEED_PREFIX:-} ]]; then
    extra_args+=(--seed "${NETRA_SEED_PREFIX}-${name}")
  fi
  if [[ ${NETRA_STREAM:-0} == 1 ]]; then
    extra_args+=(--stream)
  fi
  printf '%s start_epoch_ns=%s\n' "$name" "$(date +%s%N)" >> "$out_dir/timeline.txt"
  /root/sglvenv1151/bin/python "$repo/scripts/rocm/request_scenario.py" \
    --input-len "$input_len" \
    --output-len "$output_len" \
    --label "$label" \
    --graph-mode "${NETRA_GRAPH_MODE:-disabled}" \
    --dflash-mode "${NETRA_DFLASH_MODE:-disabled}" \
    "${extra_args[@]}" \
    --output "$out_dir/${name}.json" \
    > "$out_dir/${name}.stdout" 2> "$out_dir/${name}.stderr"
  printf '%s end_epoch_ns=%s\n' "$name" "$(date +%s%N)" >> "$out_dir/timeline.txt"
  sleep 5
}

run_case short-prefill 16 1
run_case prefill-210 210 1
run_case prefill-chunk-8192 8192 1
run_case prefill-32768 32768 1
run_case decode-m1 1 32
run_case serving-210-in-128-out 210 128
printf 'complete_epoch_ns=%s\n' "$(date +%s%N)" >> "$out_dir/timeline.txt"
