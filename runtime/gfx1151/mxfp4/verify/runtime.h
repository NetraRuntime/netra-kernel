// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::verify {

NETRA_GFX1151_ALWAYS_INLINE int gate_up(void* gate_weight, void* gate_scale, void* up_weight,
                   void* up_scale, void* activation_groups, void* expert_ids,
                   void* gate_output, void* up_output,
                   void* intermediate_output, unsigned group_count,
                   void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (group_count == 0) return 83501;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  (void)gate_output;
  (void)up_output;

  SevenPointers args{
      gate_weight, gate_scale, up_weight, up_scale, activation_groups,
      expert_ids, intermediate_output};
  hipError_t status = launch(registry.m12_group_gate_up_silu.function, 32,
                             group_count, 32, stream, args);
  return status == hipSuccess ? 0 : 83510 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int down(void* down_weight, void* down_scale, void* activation_groups,
                void* expert_output, void* expert_ids, unsigned group_count,
                void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if (group_count == 0) return 83701;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  FivePointers args{
      down_weight, down_scale, activation_groups, expert_output, expert_ids};
  hipError_t status = launch(registry.m12_group_down.function, 128,
                             group_count, 32, stream, args);
  return status == hipSuccess ? 0 : 83710 + static_cast<int>(status);
}

}  // namespace netra::gfx1151::verify
