// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/config.h"
#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::attention {

NETRA_GFX1151_ALWAYS_INLINE int bf16_qkv_decode(
    void* weight, void* activation, void* output, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  ThreePointers args{weight, activation, output};
  hipError_t status = launch(
      registry.bf16_qkv.function, 288, 1, 256,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 92100 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int extend(void* q, void* k_extend, void* v_extend, void* output,
                  void* k_buffer, void* v_buffer, void* kv_indices,
                  void* kv_indptr, unsigned tokens, float sm_scale,
                  void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (tokens == 0 || (tokens & 63U)) return 95001;
  ExtendAttentionArgs args{q,          k_extend, v_extend,  output, k_buffer,
                           v_buffer,   kv_indices, kv_indptr, tokens, sm_scale};
  hipError_t status = launch(
      registry.extend_attention.function, tokens / 64,
      NETRA_EXTEND_ATTENTION_GRID_Y, NETRA_EXTEND_ATTENTION_BLOCK_X,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int qk_norm_mrope_gate_kv_store(
    void* qkv, void* q_out, void* k_out, void* gate_out, void* q_weight,
    void* k_weight, void* cos_sin, void* positions, void* k_cache,
    void* v_cache, void* cache_loc, unsigned tokens,
    unsigned position_stride_bytes, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (tokens == 0) return 95501;
  QkNormMropeKvArgs args{
      qkv, q_out, k_out, gate_out, q_weight, k_weight, cos_sin,
      positions, k_cache, v_cache, cache_loc, tokens, position_stride_bytes};
  hipError_t status = launch(
      registry.qk_norm_mrope_kv.function, tokens, 1, 128,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95500 + static_cast<int>(status);
}

}  // namespace netra::gfx1151::attention
