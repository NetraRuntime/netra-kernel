#!/usr/bin/env bash
set -euo pipefail
usage() {
  echo "usage: $0 LABEL INPUT_LEN OUTPUT_LEN [CONTEXT_LEN]" >&2
  exit 2
}
[[ $# -ge 3 && $# -le 4 ]] || usage
label=$1
input_len=$2
output_len=$3
context_len=${4:-49152}
repo=/root/netra-mxfp4-gfx1151
out_dir=${repo}/results/profiles/gfx1151/${label}
profiler=/root/venv1151/bin/rocprofv3
collection_delay_s=${NETRA_COLLECTION_DELAY_S:-60}
collection_duration_s=${NETRA_COLLECTION_DURATION_S:-7200}
request_offset_s=${NETRA_REQUEST_AFTER_COLLECTION_START_S:-10}

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ $label =~ ^[a-zA-Z0-9._-]+$ ]] || usage
for value in "$input_len" "$output_len" "$context_len" "$collection_delay_s" \
             "$collection_duration_s" "$request_offset_s"; do
  [[ $value =~ ^[0-9]+$ ]] || usage
done
(( input_len > 0 && output_len > 0 && context_len > 0 )) || usage
(( collection_delay_s > 0 && collection_duration_s > 0 )) || usage
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
[[ -x $profiler ]] || { echo "missing ABI-matched profiler $profiler" >&2; exit 1; }
if pgrep -f '^sglang::scheduler$' >/dev/null || pgrep -f 'sglang.launch_server' >/dev/null; then
  echo "refusing process-start trace while SGLang is already active" >&2
  exit 1
fi

detected=$(/opt/rocm-7.2.1/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

mkdir -p "$out_dir"
profile_start_ms=$(date +%s%3N)
request_target_ms=$(( profile_start_ms + (collection_delay_s + request_offset_s) * 1000 ))
{
  echo target=gfx1151
  echo measurement_status=measured
  echo profiling_scope=timed_request_only_collection_window
  echo profiler="$profiler"
  echo signal_handlers=disabled
  echo collection_delay_s="$collection_delay_s"
  echo collection_duration_s="$collection_duration_s"
  echo request_offset_s="$request_offset_s"
  echo input_len="$input_len"
  echo output_len="$output_len"
  echo context_len="$context_len"
  "$profiler" --version
} > "${out_dir}/manifest.txt"

SGLANG_CONTEXT_LENGTH="$context_len" SGLANG_WEIGHT_LOADER_THREADS=2 \
  "$profiler" \
    --disable-signal-handlers true \
    --collection-period "${collection_delay_s}:${collection_duration_s}:1" \
    --kernel-trace true \
    --hip-runtime-trace true \
    --memory-copy-trace true \
    --memory-allocation-trace true \
    --scratch-memory-trace true \
    --stats true \
    --group-by-queue true \
    --output-format csv \
    --output-directory "$out_dir" \
    --output-file trace \
    -- /usr/bin/env bash "${repo}/scripts/rocm/integrations/sglang/launch.sh" \
    > "${out_dir}/server.stdout" 2> "${out_dir}/server.stderr" &
profile_pid=$!
cleanup() {
  if kill -0 "$profile_pid" 2>/dev/null; then
    kill -TERM "$profile_pid" 2>/dev/null || true
    wait "$profile_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

ready=0
for _ in $(seq 1 1800); do
  if curl -fsS --max-time 2 http://127.0.0.1:30000/health >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$profile_pid" 2>/dev/null; then break; fi
  sleep 1
done
if (( ! ready )); then
  echo "profiled SGLang failed to become healthy" >&2
  tail -120 "${out_dir}/server.stderr" >&2 || true
  exit 1
fi
health_ms=$(date +%s%3N)
if (( health_ms >= request_target_ms )); then
  echo "SGLang became healthy after the configured request-only collection target" >&2
  echo "increase NETRA_COLLECTION_DELAY_S above $collection_delay_s" >&2
  exit 1
fi
wait_ms=$(( request_target_ms - health_ms ))
sleep "$(awk -v ms="$wait_ms" 'BEGIN { printf "%.3f", ms / 1000 }')"
request_actual_ms=$(date +%s%3N)
printf 'profile_pid=%s\nprofile_start_ms=%s\nhealth_ms=%s\nrequest_target_ms=%s\nrequest_actual_ms=%s\n' \
  "$profile_pid" "$profile_start_ms" "$health_ms" "$request_target_ms" \
  "$request_actual_ms" >> "${out_dir}/manifest.txt"

request_seed=${NETRA_PROFILE_SEED:-${label}-seed}
set +e
/root/sglvenv1151/bin/python "${repo}/tools/profiling/request_scenario.py" \
  --input-len "$input_len" --output-len "$output_len" \
  --seed "$request_seed" --label "$label" \
  --graph-mode "${NETRA_GRAPH_MODE:-disabled}" \
  --dflash-mode "${NETRA_DFLASH_MODE:-disabled}" \
  --timeout "${NETRA_REQUEST_TIMEOUT_S:-7200}" \
  --output "${out_dir}/request.json" \
  > "${out_dir}/request.stdout" 2> "${out_dir}/request.stderr"
request_status=$?
set -e

kill -TERM "$profile_pid" 2>/dev/null || true
set +e
wait "$profile_pid"
profiler_status=$?
set -e
trap - EXIT INT TERM
printf 'profiler_status=%s\nrequest_status=%s\n' \
  "$profiler_status" "$request_status" >> "${out_dir}/manifest.txt"
if (( request_status != 0 )); then
  echo "request failed with status $request_status" >&2
  cat "${out_dir}/request.stderr" >&2
  exit 1
fi
kernel_csv=$(find "$out_dir" -type f -name '*kernel*trace*.csv' -print -quit)
[[ -n $kernel_csv && -s $kernel_csv ]] || {
  echo "profiler emitted no non-empty request-window kernel trace (status $profiler_status)" >&2
  exit 1
}
/root/sglvenv1151/bin/python "${repo}/tools/profiling/summarize_fullstack.py" \
  "$out_dir" --out "${out_dir}/summary.json" > "${out_dir}/summary.stdout"
echo "$out_dir"
