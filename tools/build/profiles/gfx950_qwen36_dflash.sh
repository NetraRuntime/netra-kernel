#!/usr/bin/env bash

# MI350X Qwen3.6 DFlash production composition. This file is data-only: it
# selects reusable operation contracts and owns the model artifact namespace.

NETRA_PROFILE_COMPONENT_REGISTRY=gfx950
NETRA_PROFILE_OUTPUT_NAMESPACE=gfx950-qwen36
NETRA_PROFILE_COMPONENTS=(
  moe-decode-fp8-e4m3-h2048-i512-top9-block128-aiter
  router-bf16-k2048-n256
  attention-verify-gqa8-d256-fp8kv-m16
  gdn-verify-b64-t12-h16-hv32-k128-v128-k0
  gdn-replay-b64-t12-h16-hv32-k128-v128
)
