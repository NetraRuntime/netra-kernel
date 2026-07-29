#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 LABEL INPUT_LEN OUTPUT_LEN ATTACH_MSEC [SCHEDULER_PID]" >&2
  exit 2
}
[[ $# -ge 4 && $# -le 5 ]] || usage
label=$1
input_len=$2
output_len=$3
attach_msec=$4
scheduler_pid=${5:-}
repo=/root/netra-mxfp4-gfx1151
out_dir=${repo}/results/profiles/gfx1151/${label}

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ $label =~ ^[a-zA-Z0-9._-]+$ ]] || usage
for value in "$input_len" "$output_len" "$attach_msec"; do
  [[ $value =~ ^[0-9]+$ ]] || usage
done
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
if [[ -z $scheduler_pid ]]; then
  scheduler_pid=$(pgrep -f '^sglang::scheduler$' | head -1 || true)
fi
[[ -n $scheduler_pid && -r /proc/${scheduler_pid}/maps ]] || {
  echo "no live SGLang scheduler" >&2
  exit 1
}

detected=$(/opt/rocm-7.2.1/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

# Match the profiler SDK to the registration library mapped by the target.
# The system 7.2.1 profiler can attach to a wheel ROCm 7.13 process but emits
# no records, which is explicitly treated as failure.
if grep -q '/_rocm_sdk_core/' /proc/${scheduler_pid}/maps; then
  profiler=/root/venv1151/bin/rocprofv3
  profiler_reason=pytorch_rocm_sdk_abi_match
  sdk_lib=/root/venv1151/lib/python3.12/site-packages/_rocm_sdk_core/lib
  export LD_LIBRARY_PATH="${sdk_lib}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
else
  profiler=/opt/rocm-7.2.1/bin/rocprofv3
  profiler_reason=system_rocm_7_2_1
fi
[[ -x $profiler ]] || { echo "missing profiler $profiler" >&2; exit 1; }

mkdir -p "$out_dir"
{
  echo target=gfx1151
  echo measurement_status=measured
  echo scheduler_pid="$scheduler_pid"
  echo profiler="$profiler"
  echo profiler_reason="$profiler_reason"
  echo input_len="$input_len"
  echo output_len="$output_len"
  echo attach_msec="$attach_msec"
  "$profiler" --version
} > "${out_dir}/manifest.txt"

/root/sglvenv1151/bin/python "${repo}/scripts/rocm/request_scenario.py" \
  --input-len "$input_len" \
  --output-len "$output_len" \
  --label "$label" \
  --graph-mode "${NETRA_GRAPH_MODE:-disabled}" \
  --dflash-mode "${NETRA_DFLASH_MODE:-disabled}" \
  --delay-ms "${NETRA_PROFILE_REQUEST_DELAY_MS:-3000}" \
  --timeout "${NETRA_REQUEST_TIMEOUT_S:-7200}" \
  --output "${out_dir}/request.json" \
  > "${out_dir}/request.stdout" 2> "${out_dir}/request.stderr" &
request_pid=$!

set +e
"$profiler" \
  --attach "$scheduler_pid" \
  --attach-children false \
  --attach-sync-output true \
  --attach-duration-msec "$attach_msec" \
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
  > "${out_dir}/rocprof.stdout" 2> "${out_dir}/rocprof.stderr"
profiler_status=$?
if (( profiler_status != 0 )); then
  kill "$request_pid" 2>/dev/null
fi
wait "$request_pid"
request_status=$?
set -e
printf 'profiler_status=%s\nrequest_status=%s\n' \
  "$profiler_status" "$request_status" >> "${out_dir}/manifest.txt"
if (( profiler_status != 0 || request_status != 0 )); then
  echo "profile failed: profiler=$profiler_status request=$request_status" >&2
  exit 1
fi

kernel_csv=$(find "$out_dir" -type f -name '*kernel*trace*.csv' -print -quit)
[[ -n $kernel_csv && -s $kernel_csv ]] || {
  echo "profiler emitted no non-empty kernel trace" >&2
  exit 1
}
/root/sglvenv1151/bin/python "${repo}/scripts/rocm/summarize_fullstack.py" \
  "$out_dir" --out "${out_dir}/summary.json"
echo "$out_dir"
