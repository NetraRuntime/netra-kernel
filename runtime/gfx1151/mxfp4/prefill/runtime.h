// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/config.h"
#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::prefill {

NETRA_GFX1151_ALWAYS_INLINE int repack(void* source, void* destination, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  TwoPointers args{source, destination};
  hipError_t status =
      launch(registry.prefill_repack.function, 131072, 1, 256, stream, args);
  return status == hipSuccess ? 0 : 80000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int gate_up(void* gate_weight, void* gate_scale, void* up_weight,
                   void* up_scale, void* activation_groups, void* expert_ids,
                   void* gate_output, void* up_output,
                   void* intermediate_output, unsigned group_count,
                   void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);

  FivePointers gate_args{
      gate_weight, gate_scale, activation_groups, gate_output, expert_ids};
  hipError_t status =
      launch(registry.prefill_gate.function, NETRA_PREFILL_GATE_GRID_X,
             group_count, NETRA_PREFILL_GATE_BLOCK_X, stream, gate_args);
  if (status != hipSuccess) return 81000 + static_cast<int>(status);

  (void)up_output;
  SixPointers up_silu_args{up_weight, up_scale, activation_groups, gate_output,
                           intermediate_output, expert_ids};
  status = launch(registry.prefill_up_silu.function,
                  NETRA_PREFILL_GATE_GRID_X, group_count,
                  NETRA_PREFILL_GATE_BLOCK_X, stream, up_silu_args);
  return status == hipSuccess ? 0 : 82000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int down(void* down_weight, void* down_scale, void* activation_groups,
                void* expert_output, void* expert_ids, unsigned group_count,
                void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  FivePointers args{
      down_weight, down_scale, activation_groups, expert_output, expert_ids};
  hipError_t status = launch(registry.prefill_down.function, 128, group_count,
                             32, stream, args);
  return status == hipSuccess ? 0 : 84000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int linear(void* packed, void* scale, void* activation_groups,
                  void* output_groups, unsigned group_count, unsigned n,
                  unsigned k, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if ((n & 15U) || (k & 31U) || group_count == 0) return 92001;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  LinearArgs args{packed, scale, activation_groups, output_groups, n, k};
  hipFunction_t function = registry.linear_prefill.function;
  unsigned grid_x = n / 16;
  unsigned block_x = 32;
  if (n == 64 || n == 2048) {
    function = registry.linear_prefill_group4.function;
    grid_x = n / 64;
    block_x = 128;
  }
  hipError_t status =
      launch(function, grid_x, group_count, block_x, stream, args);
  return status == hipSuccess ? 0 : 93000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int linear_repack(void* source, void* destination, unsigned n,
                         unsigned k, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if ((n & 7U) || (k & 31U) || n == 0 || k == 0) return 92501;
  LinearRepackArgs args{source, destination, n};
  hipError_t status =
      launch(registry.linear_prefill_repack.function, n / 8, k / 32, 32,
             reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 92500 + static_cast<int>(status);
}

}  // namespace netra::gfx1151::prefill
