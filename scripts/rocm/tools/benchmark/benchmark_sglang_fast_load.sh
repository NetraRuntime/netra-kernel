#!/usr/bin/env bash
set -euo pipefail

# Execute inside the Netra LXC. This benchmark evicts only the selected
# checkpoint files from page cache, starts the validated fast loader, waits for
# health, and stops the exact server process it launched.
repo_dir=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
model_dir=${MODEL_DIR:-/root/models/qwen36-sgl-mxfp4}
out_dir=${1:-"${repo_dir}/results/loading/gfx1151/fast-load-$(date -u +%Y%m%dT%H%M%SZ)"}
port=${SGLANG_PORT:-30000}
drop_cache=${NETRA_DROP_CHECKPOINT_CACHE:-1}

if pgrep -f 'python.*sglang\.launch_server' >/dev/null; then
  echo "an SGLang server is already active; refusing to disturb it" >&2
  exit 1
fi

mkdir -p "${out_dir}"
if [[ "${drop_cache}" == 1 ]]; then
  MODEL_DIR="${model_dir}" /root/sglvenv1151/bin/python - <<'PY'
import glob
import os

paths = glob.glob(os.path.join(os.environ["MODEL_DIR"], "*.safetensors"))
for path in paths:
    fd = os.open(path, os.O_RDONLY)
    try:
        os.posix_fadvise(fd, 0, 0, os.POSIX_FADV_DONTNEED)
    finally:
        os.close(fd)
print(f"gfx1151 cold-cache preparation: evicted {len(paths)} checkpoint files")
PY
fi

start_ns=$(date +%s%N)
SGLANG_PORT="${port}" MODEL_DIR="${model_dir}" \
  bash "${repo_dir}/scripts/rocm/integrations/sglang/launch.sh" \
  >"${out_dir}/server.log" 2>&1 &
server_pid=$!

cleanup() {
  if kill -0 "${server_pid}" 2>/dev/null; then
    kill -INT "${server_pid}" 2>/dev/null || true
    wait "${server_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

ready=0
for _ in $(seq 1 900); do
  if ! kill -0 "${server_pid}" 2>/dev/null; then
    echo "server exited before health; see ${out_dir}/server.log" >&2
    exit 1
  fi
  if curl -fsS "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [[ "${ready}" != 1 ]]; then
  echo "server health timeout; see ${out_dir}/server.log" >&2
  exit 1
fi

end_ns=$(date +%s%N)
host_ready_ms=$(( (end_ns - start_ns) / 1000000 ))
grep -E 'Load weight begin|Netra loaded|Load weight end|The server is fired up' \
  "${out_dir}/server.log"
printf 'gfx1151 measured host launch-to-health: %s ms\n' "${host_ready_ms}"
