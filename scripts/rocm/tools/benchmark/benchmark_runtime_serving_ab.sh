#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 LABEL INPUT_LEN OUTPUT_LEN SAMPLES_PER_SERVER [ROUNDS] [CONTEXT_LEN]" >&2
  exit 2
}
[[ $# -ge 4 && $# -le 6 ]] || usage
label=$1
input_len=$2
output_len=$3
samples=$4
rounds=${5:-2}
context_len=${6:-49152}
repo=/root/netra-mxfp4-gfx1151
old_lib=${NETRA_RUNTIME_OLD_LIB:-${repo}/results/runtime/gfx1151/runtime-refactor-c421a85-old/libnetra_mxfp4_sgl.old.so}
new_lib=${NETRA_RUNTIME_NEW_LIB:-${repo}/build/runtime-refactor/full-new/libnetra_mxfp4_sgl.so}
live_lib=${repo}/build/sglang/libnetra_mxfp4_sgl.so
old_hsaco=${NETRA_KERNEL_OLD_HSACO:-}
new_hsaco=${NETRA_KERNEL_NEW_HSACO:-}
live_hsaco=${NETRA_KERNEL_LIVE_HSACO:-}
kernel_ab=0
if [[ -n $old_hsaco || -n $new_hsaco || -n $live_hsaco ]]; then
  [[ -n $old_hsaco && -n $new_hsaco && -n $live_hsaco ]] || {
    echo "NETRA_KERNEL_OLD_HSACO, NETRA_KERNEL_NEW_HSACO, and NETRA_KERNEL_LIVE_HSACO must be set together" >&2
    exit 2
  }
  kernel_ab=1
fi
out_dir=${repo}/results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/${label}
port=${SGLANG_PORT:-30000}
python=/root/sglvenv1151/bin/python
request=${repo}/scripts/rocm/tools/profiling/request_scenario.py
graph_mode=${NETRA_RUNTIME_GRAPH_MODE:-disabled}
launch_args=()
case "$graph_mode" in
  disabled) ;;
  full-decode-tiers-1-2-4-8-12-16)
    graph_config='{"decode":{"backend":"full","max_bs":16,"bs":[1,2,4,8,12,16]},"prefill":{"backend":"disabled"}}'
    launch_args=(
      --max-running-requests 16
      --mamba-radix-cache-strategy extra_buffer_lazy
      --mamba-full-memory-ratio 1.5
      --cuda-graph-config "$graph_config"
    )
    ;;
  *) echo "unsupported NETRA_RUNTIME_GRAPH_MODE=$graph_mode" >&2; exit 2 ;;
esac

[[ $(hostname) == Netra ]] || { echo "must run in Netra" >&2; exit 1; }
[[ $label =~ ^[a-zA-Z0-9._-]+$ ]] || usage
for value in "$input_len" "$output_len" "$samples" "$rounds" "$context_len" "$port"; do
  [[ $value =~ ^[0-9]+$ && $value -gt 0 ]] || usage
done
[[ -f $old_lib && -f $new_lib && -f $live_lib ]] || {
  echo "missing old, new, or live runtime library" >&2
  exit 1
}
if (( kernel_ab )); then
  [[ -f $old_hsaco && -f $new_hsaco && -f $live_hsaco ]] || {
    echo "missing old, new, or live kernel HSACO" >&2; exit 1; }
fi
[[ ! -e $out_dir ]] || { echo "refusing to overwrite $out_dir" >&2; exit 1; }
if pgrep -f '^sglang::scheduler$' >/dev/null || pgrep -f 'sglang.launch_server' >/dev/null; then
  echo "refusing A/B benchmark while SGLang is already active" >&2
  exit 1
fi
detected=$(/opt/rocm-7.2.1/bin/amd-smi static --asic 2>/dev/null \
  | awk '/TARGET_GRAPHICS_VERSION/ {print $2; exit}')
[[ $detected == gfx1151 ]] || { echo "expected gfx1151, got $detected" >&2; exit 1; }

mkdir -p "$out_dir"
server_pid=
restore_new() {
  if [[ -n ${server_pid:-} ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill -TERM "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  install -m 755 "$new_lib" "$live_lib"
  if (( kernel_ab )); then
    install -m 644 "$new_hsaco" "$live_hsaco"
  fi
}
trap restore_new EXIT INT TERM

old_sha=$(sha256sum "$old_lib" | awk '{print $1}')
new_sha=$(sha256sum "$new_lib" | awk '{print $1}')
{
  echo target=gfx1151
  echo measurement_status=measured
  echo graph_mode="$graph_mode"
  echo dflash_mode=disabled
  echo old_sha256="$old_sha"
  echo new_sha256="$new_sha"
  echo input_len="$input_len"
  echo output_len="$output_len"
  echo samples_per_server="$samples"
  echo rounds="$rounds"
  echo context_len="$context_len"
  if (( kernel_ab )); then
    echo kernel_live_hsaco="$live_hsaco"
    echo kernel_old_sha256="$(sha256sum "$old_hsaco" | awk '{print $1}')"
    echo kernel_new_sha256="$(sha256sum "$new_hsaco" | awk '{print $1}')"
  fi
} > "$out_dir/manifest.txt"

run_variant() {
  local round=$1
  local variant=$2
  local source_lib=$3
  local run_dir=${out_dir}/round-${round}-${variant}
  mkdir -p "$run_dir"
  install -m 755 "$source_lib" "$live_lib"
  local active_hsaco_sha=disabled
  if (( kernel_ab )); then
    local source_hsaco
    if [[ $variant == old ]]; then
      source_hsaco=$old_hsaco
    else
      source_hsaco=$new_hsaco
    fi
    install -m 644 "$source_hsaco" "$live_hsaco"
    active_hsaco_sha=$(sha256sum "$live_hsaco" | awk '{print $1}')
  fi
  local active_sha
  active_sha=$(sha256sum "$live_lib" | awk '{print $1}')
  [[ $active_sha == $(sha256sum "$source_lib" | awk '{print $1}') ]] || {
    echo "live library hash mismatch" >&2
    return 1
  }

  local start_ns ready_ns
  start_ns=$(date +%s%N)
  SGLANG_PORT="$port" SGLANG_CONTEXT_LENGTH="$context_len" \
    SGLANG_WEIGHT_LOADER_THREADS=2 \
    bash "${repo}/scripts/rocm/integrations/sglang/launch.sh" \
      "${launch_args[@]}" \
      >"${run_dir}/server.stdout" 2>"${run_dir}/server.stderr" &
  server_pid=$!
  local ready=0
  for _ in $(seq 1 180); do
    if curl -fsS --max-time 2 "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
      ready=1
      break
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then break; fi
    sleep 1
  done
  if (( ! ready )); then
    echo "${variant} server failed to become healthy" >&2
    tail -120 "${run_dir}/server.stderr" >&2 || true
    return 1
  fi
  ready_ns=$(date +%s%N)

  "$python" "$request" \
    --url "http://127.0.0.1:${port}/generate" \
    --input-len 64 --output-len 4 \
    --seed "${label}-round-${round}-warmup" \
    --label "${label}-round-${round}-${variant}-warmup" \
    --graph-mode "$graph_mode" --dflash-mode disabled \
    --timeout 600 --output "${run_dir}/warmup.json" \
    >"${run_dir}/warmup.stdout" 2>"${run_dir}/warmup.stderr"

  for sample in $(seq 0 $((samples - 1))); do
    local sample_id
    sample_id=$(printf '%03d' "$sample")
    "$python" "$request" \
      --url "http://127.0.0.1:${port}/generate" \
      --input-len "$input_len" --output-len "$output_len" --stream \
      --seed "${label}-round-${round}-sample-${sample_id}" \
      --label "${label}-round-${round}-${variant}-sample-${sample_id}" \
      --graph-mode "$graph_mode" --dflash-mode disabled \
      --timeout "${NETRA_REQUEST_TIMEOUT_S:-1800}" \
      --output "${run_dir}/request-${sample_id}.json" \
      >"${run_dir}/request-${sample_id}.stdout" \
      2>"${run_dir}/request-${sample_id}.stderr"
  done

  kill -TERM "$server_pid" 2>/dev/null || true
  set +e
  wait "$server_pid"
  local server_status=$?
  set -e
  server_pid=
  {
    echo target=gfx1151
    echo measurement_status=measured
    echo variant="$variant"
    echo round="$round"
    echo library_sha256="$active_sha"
    echo kernel_hsaco_sha256="$active_hsaco_sha"
    echo launch_to_health_ms=$(( (ready_ns - start_ns) / 1000000 ))
    echo server_status="$server_status"
  } > "${run_dir}/manifest.txt"
}

for round in $(seq 0 $((rounds - 1))); do
  if (( round % 2 == 0 )); then
    run_variant "$round" old "$old_lib"
    run_variant "$round" new "$new_lib"
  else
    run_variant "$round" new "$new_lib"
    run_variant "$round" old "$old_lib"
  fi
done

"$python" "${repo}/scripts/rocm/tools/benchmark/summarize_runtime_serving_ab.py" \
  "$out_dir" --output "$out_dir/summary.json"
restore_new
trap - EXIT INT TERM
echo "$out_dir"
