// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::lm_head {

NETRA_GFX1151_ALWAYS_INLINE int bf16_decode(
    void* weight, void* activation, void* output, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  ThreePointers args{weight, activation, output};
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  hipError_t status = launch(
      registry.bf16_lm_head.function, 7760, 1, 256, stream, args);
  return status == hipSuccess ? 0 : 92000 + static_cast<int>(status);
}

}  // namespace netra::gfx1151::lm_head
