// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"

namespace {
hipModule_t module{};
hipFunction_t function{};
}

extern "C" int netra_gdn_chunk_o_two_wave_nowait_init(const char* hsaco_path) {
  hipError_t status = hipModuleLoad(&module, hsaco_path);
  if (status != hipSuccess) return static_cast<int>(status);
  status = hipModuleGetFunction(
      &function, module, "gdn_chunk_o_bv32_two_wave_nowait_gfx1151");
  return static_cast<int>(status);
}

extern "C" int netra_gdn_chunk_o_two_wave_nowait(
    void* q, void* k, void* v, void* h, void* g, void* output,
    void* cu_seqlens, void* chunk_indices, float scale, unsigned tokens,
    void* stream_ptr) {
  if (tokens != 8192) return 96001;
  netra::gfx1151::GdnChunkOArgs args{
      q, k, v, h, g, output, cu_seqlens, chunk_indices, scale, tokens};
  hipError_t status = netra::gfx1151::launch_3d(
      function, 4, 256, 32, 64,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96000 + static_cast<int>(status);
}
