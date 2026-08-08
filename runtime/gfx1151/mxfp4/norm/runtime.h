// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::norm {

NETRA_GFX1151_ALWAYS_INLINE int qwen36_decode(
    void* input, void* weight, void* output, float epsilon, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  Qwen36NormArgs args{input, weight, output, epsilon, 0};
  hipError_t status = launch(registry.qwen36_norm.function, 1, 1, 256,
                             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95600 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int qwen36_fused_add_decode(
    void* input, void* residual, void* weight, float epsilon,
    void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  Qwen36NormArgs args{input, residual, weight, epsilon, 0};
  hipError_t status = launch(registry.qwen36_fused_add_norm.function, 1, 1, 256,
                             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95700 + static_cast<int>(status);
}

}  // namespace netra::gfx1151::norm
