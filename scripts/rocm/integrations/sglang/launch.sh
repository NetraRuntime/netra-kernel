#!/usr/bin/env bash
set -euo pipefail

# Execute inside the Netra LXC after applying the SGLang integration patches.
sglang_dir=${SGLANG_DIR:-/root/work/sglang-main}
sglang_venv=${SGLANG_VENV:-/root/sglvenv1151}
model_dir=${MODEL_DIR:-/root/models/qwen36-sgl-mxfp4}
weight_loader_threads=${SGLANG_WEIGHT_LOADER_THREADS:-2}

case "${weight_loader_threads}" in
  ''|*[!0-9]*) echo "SGLANG_WEIGHT_LOADER_THREADS must be a positive integer" >&2; exit 2 ;;
  0) echo "SGLANG_WEIGHT_LOADER_THREADS must be greater than zero" >&2; exit 2 ;;
esac

export SGLANG_USE_NETRA_MXFP4_GFX1151=1
export SGLANG_NETRA_ENABLE_BF16_LM_HEAD=${SGLANG_NETRA_ENABLE_BF16_LM_HEAD:-1}
export PATH="${sglang_venv}/bin:/opt/rocm-7.2.1/bin:${PATH}"
export HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0}
export PYTHONPATH="${sglang_dir}/python${PYTHONPATH:+:${PYTHONPATH}}"

exec "${sglang_venv}/bin/python" -m sglang.launch_server \
  --model-path "${model_dir}" \
  --host "${SGLANG_HOST:-127.0.0.1}" \
  --port "${SGLANG_PORT:-30000}" \
  --attention-backend triton \
  --moe-runner-backend triton \
  --cuda-graph-backend-decode disabled \
  --cuda-graph-backend-prefill disabled \
  --mem-fraction-static "${SGLANG_MEM_FRACTION:-0.80}" \
  --context-length "${SGLANG_CONTEXT_LENGTH:-2048}" \
  --weight-loader-disable-mmap \
  --model-loader-extra-config "{\"num_threads\":${weight_loader_threads}}" \
  --weight-loader-drop-cache-after-load \
  --skip-server-warmup \
  --disable-shared-experts-fusion \
  "$@"
