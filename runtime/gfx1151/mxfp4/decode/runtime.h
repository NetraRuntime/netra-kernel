// SPDX-License-Identifier: MIT
#pragma once

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"
#include "runtime/gfx1151/common/module_registry.h"

namespace netra::gfx1151::decode {

NETRA_GFX1151_ALWAYS_INLINE int moe(void* gate_weight, void* gate_scale, void* up_weight,
               void* up_scale, void* down_weight, void* down_scale,
               void* activation, void* expert_ids, void* topk_weights,
               void* gate_tmp, void* up_tmp, void* intermediate_tmp,
               void* expert_output_tmp, void* output, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);

  constexpr size_t gate_bytes = 8 * 512 * sizeof(float);
  hipError_t status = hipMemsetAsync(gate_tmp, 0, gate_bytes, stream);
  if (status != hipSuccess) return 10000 + static_cast<int>(status);
  status = hipMemsetAsync(up_tmp, 0, gate_bytes, stream);
  if (status != hipSuccess) return 20000 + static_cast<int>(status);

  FivePointers gate_args{
      gate_weight, gate_scale, activation, gate_tmp, expert_ids};
  status = launch(registry.gate.function, 1, 16, 128, stream, gate_args);
  if (status != hipSuccess) return 30000 + static_cast<int>(status);

  FivePointers up_args{up_weight, up_scale, activation, up_tmp, expert_ids};
  status = launch(registry.gate.function, 1, 16, 128, stream, up_args);
  if (status != hipSuccess) return 40000 + static_cast<int>(status);

  ThreePointers silu_args{gate_tmp, up_tmp, intermediate_tmp};
  status = launch(registry.silu.function, 16, 1, 256, stream, silu_args);
  if (status != hipSuccess) return 50000 + static_cast<int>(status);

  FivePointers down_args{
      down_weight, down_scale, intermediate_tmp, expert_output_tmp, expert_ids};
  status = launch(registry.down.function, 2, 8, 256, stream, down_args);
  if (status != hipSuccess) return 60000 + static_cast<int>(status);

  ThreePointers reduce_args{expert_output_tmp, topk_weights, output};
  status = launch(registry.reduce.function, 8, 1, 256, stream, reduce_args);
  return status == hipSuccess ? 0 : 70000 + static_cast<int>(status);
}

NETRA_GFX1151_ALWAYS_INLINE int linear(void* packed, void* scale, void* activation, void* output,
                  unsigned m, unsigned n, unsigned k, void* stream_ptr) {
  ensure_initialized();
  ModuleRegistry& registry = runtime();
  if (registry.status != hipSuccess) return static_cast<int>(registry.status);
  if ((n & 3U) || (k & 31U) || (n > 512 && (n & 511U))) return 90001;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  auto* x = static_cast<unsigned char*>(activation);
  auto* y = static_cast<unsigned char*>(output);
  for (unsigned row = 0; row < m; ++row) {
    LinearArgs args{
        packed, scale, x + static_cast<size_t>(row) * k * 2,
        y + static_cast<size_t>(row) * n * 2, n, k};
    unsigned block_size = n < 512 ? n / 4 : 128;
    hipError_t status = launch(registry.linear_decode.function,
                               (n + 511) / 512, 1, block_size, stream, args);
    if (status != hipSuccess) return 91000 + static_cast<int>(status);
  }
  return 0;
}

}  // namespace netra::gfx1151::decode
