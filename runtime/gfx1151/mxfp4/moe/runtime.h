// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::moe {

NETRA_GFX1151_ALWAYS_INLINE int expert_weighted_reduce_fp64(void* expert, void* positions,
                                       void* weights, void* output,
                                       unsigned tokens, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (tokens == 0) return 96901;
  FourPointers args{expert, positions, weights, output};
  hipError_t status =
      launch(registry.expert_reduce_fp64.function, 8, tokens, 256,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96900 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int expert_activation_pack(void* hidden, void* pair_tokens,
                                  void* position, void* output,
                                  unsigned pair_count, unsigned total_rows,
                                  void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (pair_count == 0 || total_rows < pair_count) return 97001;
  ActivationPackArgs args{
      hidden, pair_tokens, position, output, pair_count, total_rows};
  hipError_t status =
      launch(registry.activation_pack.function, pair_count, 1, 256,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 97000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int bf16_shared_gate_up_silu_decode(
    void* weight, void* activation, void* output, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  ThreePointers args{weight, activation, output};
  hipError_t status =
      launch(registry.bf16_shared_gate_up_silu.function, 32, 1, 256,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 97200 + static_cast<int>(status);
}


NETRA_GFX1151_ALWAYS_INLINE int bf16_shared_down_decode(
    void* weight, void* activation, void* output, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  ThreePointers args{weight, activation, output};
  hipError_t status =
      launch(registry.bf16_shared_down.function, 64, 1, 256,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 97300 + static_cast<int>(status);
}
}  // namespace netra::gfx1151::moe
