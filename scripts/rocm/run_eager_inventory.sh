#!/usr/bin/env bash
set -euo pipefail

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
repo=/root/netra-mxfp4-gfx1151
run_tag=${RUN_TAG:-$(date -u +%Y%m%dT%H%M%SZ)}
scheduler_pid=${SCHEDULER_PID:-$(pgrep -f '^sglang::scheduler$' | head -1)}

run_case() {
  local name=$1 input_len=$2 output_len=$3 attach_msec=$4
  "$repo/scripts/rocm/profile_sglang_request.sh" \
    "eager-${name}-${run_tag}" "$input_len" "$output_len" "$attach_msec" \
    "$scheduler_pid"
}

# Independent request windows. Each request uses unique token IDs and rejects
# any nonzero SGLang cached-token count.
run_case short-prefill 16 1 15000
run_case prefill-210 210 1 20000
run_case prefill-chunk-8192 8192 1 90000
run_case prefill-32768 32768 1 120000
run_case decode-m1 1 32 30000
run_case serving-210-in-128-out 210 128 45000
