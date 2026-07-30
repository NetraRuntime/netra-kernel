// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::gdn {

NETRA_GFX1151_ALWAYS_INLINE int qkvzba_split_copy(void* mixed_qkvz, void* mixed_ba,
                             void* mixed_qkv, void* z, void* b, void* a,
                             unsigned token_count, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (token_count == 0) return 0;
  SixPointers args{mixed_qkvz, mixed_ba, mixed_qkv, z, b, a};
  hipError_t status =
      launch(registry.qkvzba_split.function, 7, token_count, 256,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 94000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int chunk_o(void* q, void* k, void* v, void* h, void* g, void* output,
                   void* cu_seqlens, void* chunk_indices, float scale,
                   unsigned tokens, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (tokens != 8192) return 96001;
  GdnChunkOArgs args{
      q, k, v, h, g, output, cu_seqlens, chunk_indices, scale, tokens};
  hipError_t status = launch_3d(
      registry.gdn_chunk_o.function, 4, 256, 32, 64,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int recompute_w_u(void* k, void* v, void* beta, void* w, void* u,
                         void* A, void* g, unsigned tokens,
                         void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (tokens != 8192) return 96501;
  RecomputeWUArgs args{k, v, beta, w, u, A, g, nullptr, nullptr, tokens};
  hipError_t status =
      launch(registry.recompute_w_u.function, 128, 32, 64,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96500 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int causal_conv1d(void* x, void* weight, void* state,
                         void* cache_index, void* has_initial, void* output,
                         void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  CausalConvArgs conv_args{x, weight, state, cache_index, has_initial, output};
  hipError_t status =
      launch(registry.causal_conv.function, 64, 128, 128, stream, conv_args);
  if (status != hipSuccess) return 96700 + static_cast<int>(status);
  CausalStateArgs state_args{x, state, cache_index};
  status =
      launch(registry.causal_state.function, 64, 1, 128, stream, state_args);
  return status == hipSuccess ? 0 : 96800 + static_cast<int>(status);
}

}  // namespace netra::gfx1151::gdn
