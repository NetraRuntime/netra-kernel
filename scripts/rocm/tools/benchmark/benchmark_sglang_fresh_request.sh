#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 LABEL SEED INPUT_LEN OUTPUT_LEN [CONTEXT_LEN]" >&2
  exit 2
}
[[ $# -ge 4 && $# -le 5 ]] || usage
label=$1
seed=$2
input_len=$3
output_len=$4
context_len=${5:-49152}
repo=/root/netra-mxfp4-gfx1151
out_dir=${repo}/results/serving/gfx1151/${label}
port=${SGLANG_PORT:-30000}
page_size=${SGLANG_PAGE_SIZE:-}
page_args=()
if [[ -n $page_size ]]; then
  [[ $page_size =~ ^[0-9]+$ && $page_size -gt 0 ]] || usage
  page_args=(--page-size "$page_size")
fi

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ $label =~ ^[a-zA-Z0-9._/-]+$ && $label != /* && $label != *..* ]] || usage
for value in "$input_len" "$output_len" "$context_len" "$port"; do
  [[ $value =~ ^[0-9]+$ && $value -gt 0 ]] || usage
done
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
if pgrep -f '^sglang::scheduler$' >/dev/null || pgrep -f 'sglang.launch_server' >/dev/null; then
  echo "refusing fresh-server benchmark while SGLang is already active" >&2
  exit 1
fi

detected=$(/opt/rocm-7.2.1/bin/amd-smi static --asic 2>/dev/null | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

mkdir -p "$out_dir"
start_ns=$(date +%s%N)
SGLANG_PORT="$port" SGLANG_CONTEXT_LENGTH="$context_len" SGLANG_WEIGHT_LOADER_THREADS=2 \
  bash "${repo}/scripts/rocm/integrations/sglang/launch.sh" "${page_args[@]}" \
  >"${out_dir}/server.stdout" 2>"${out_dir}/server.stderr" &
server_pid=$!
cleanup() {
  if kill -0 "$server_pid" 2>/dev/null; then
    kill -TERM "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

ready=0
for _ in $(seq 1 180); do
  if curl -fsS --max-time 2 "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then break; fi
  sleep 1
done
if (( ! ready )); then
  echo "SGLang failed to become healthy" >&2
  tail -120 "${out_dir}/server.stderr" >&2 || true
  exit 1
fi
ready_ns=$(date +%s%N)

/root/sglvenv1151/bin/python "${repo}/tools/profiling/request_scenario.py" \
  --url "http://127.0.0.1:${port}/generate" \
  --input-len "$input_len" --output-len "$output_len" \
  --seed "$seed" --label "$label" \
  --graph-mode disabled --dflash-mode disabled \
  --timeout "${NETRA_REQUEST_TIMEOUT_S:-1800}" \
  --output "${out_dir}/request.json" \
  >"${out_dir}/request.stdout" 2>"${out_dir}/request.stderr"

kill -TERM "$server_pid" 2>/dev/null || true
set +e
wait "$server_pid"
server_status=$?
set -e
trap - EXIT INT TERM
{
  echo target=gfx1151
  echo measurement_status=measured
  echo label="$label"
  echo seed="$seed"
  echo input_len="$input_len"
  echo output_len="$output_len"
  echo context_len="$context_len"
  echo page_size="${page_size:-default}"
  echo launch_to_health_ms=$(( (ready_ns - start_ns) / 1000000 ))
  echo server_status="$server_status"
  git -C "$repo" rev-parse HEAD | sed 's/^/repository_head=/'
} >"${out_dir}/manifest.txt"
echo "$out_dir"
