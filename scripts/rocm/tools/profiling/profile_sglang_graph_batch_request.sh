#!/usr/bin/env bash
set -euo pipefail
usage() {
  echo "usage: $0 LABEL BATCH_SIZE INPUT_LEN OUTPUT_LEN [CONTEXT_LEN]" >&2
  exit 2
}
[[ $# -ge 4 && $# -le 5 ]] || usage
label=$1
batch_size=$2
input_len=$3
output_len=$4
context_len=${5:-2048}
repo=/root/netra-mxfp4-gfx1151
out_dir=${repo}/results/profiles/gfx1151/${label}
profiler=/root/venv1151/bin/rocprofv3

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ $label =~ ^[a-zA-Z0-9._-]+$ ]] || usage
for value in "$batch_size" "$input_len" "$output_len" "$context_len"; do
  [[ $value =~ ^[0-9]+$ && $value -gt 0 ]] || usage
done
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
{
  echo target=gfx1151
  echo measurement_status=measured
  echo profiler="$profiler"
  echo profiler_reason=pytorch_rocm_sdk_abi_matched_process_start
  echo signal_handlers=disabled
  echo counter_collection=disabled_to_avoid_known_aqlprofile_signal6
  echo graph_mode=full_decode_tiers_1_2_4_8_12_16
  echo dflash_mode=disabled
  echo batch_size="$batch_size"
  echo input_len="$input_len"
  echo output_len="$output_len"
  echo context_len="$context_len"
  "$profiler" --version
} > "${out_dir}/manifest.txt"

graph_config='{"decode":{"backend":"full","max_bs":16,"bs":[1,2,4,8,12,16]},"prefill":{"backend":"disabled"}}'
SGLANG_CONTEXT_LENGTH="$context_len" SGLANG_WEIGHT_LOADER_THREADS=2 \
  "$profiler" \
    --disable-signal-handlers true \
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
      --max-running-requests 16 \
      --mamba-radix-cache-strategy extra_buffer_lazy \
      --mamba-full-memory-ratio 1.5 \
      --cuda-graph-config "$graph_config" \
    > "${out_dir}/server.stdout" 2> "${out_dir}/server.stderr" &
profile_pid=$!
echo profile_pid="$profile_pid" >> "${out_dir}/manifest.txt"
cleanup() {
  if kill -0 "$profile_pid" 2>/dev/null; then
    kill -TERM "$profile_pid" 2>/dev/null || true
    wait "$profile_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

ready=0
for _ in $(seq 1 180); do
  if grep -q 'ready to roll' "${out_dir}/server.stderr"; then
    ready=1
    break
  fi
  if ! kill -0 "$profile_pid" 2>/dev/null; then break; fi
  sleep 1
done
if (( ! ready )); then
  echo "profiled graph SGLang failed to become healthy" >&2
  tail -120 "${out_dir}/server.stderr" >&2 || true
  exit 1
fi

request_seed=${NETRA_PROFILE_SEED:-${label}-seed}
set +e
/root/sglvenv1151/bin/python \
  "${repo}/scripts/rocm/tools/benchmark/benchmark_sglang_batch_request.py" \
  --batch-size "$batch_size" \
  --input-len "$input_len" \
  --output-len "$output_len" \
  --seed-prefix "$request_seed" \
  --label "$label" \
  --graph-mode full-decode-tiers-1-2-4-8-12-16 \
  --dflash-mode disabled \
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
  sed -n '1,160p' "${out_dir}/request.stderr" >&2
  exit 1
fi
kernel_csv=$(find "$out_dir" -type f -name '*kernel*trace*.csv' -print -quit)
[[ -n $kernel_csv && -s $kernel_csv ]] || {
  echo "profiler emitted no non-empty kernel trace (status $profiler_status)" >&2
  exit 1
}
/root/sglvenv1151/bin/python "${repo}/tools/profiling/summarize_fullstack.py" \
  "$out_dir" --out "${out_dir}/summary.json"
echo "$out_dir"
