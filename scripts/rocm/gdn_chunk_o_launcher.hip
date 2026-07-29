// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>
#include <mutex>

namespace {
hipModule_t module = nullptr;
hipFunction_t kernel = nullptr;
std::mutex load_mutex;

struct alignas(8) Args {
  void* q;
  void* k;
  void* v;
  void* h;
  void* g;
  void* o;
  void* cu_seqlens;
  void* chunk_indices;
  float scale;
  uint32_t tokens;
};
static_assert(sizeof(Args) == 72);
}

extern "C" int netra_gdn_chunk_o_init(const char* hsaco_path) {
  std::lock_guard<std::mutex> lock(load_mutex);
  if (kernel != nullptr) return hipSuccess;
  hipError_t status = hipModuleLoad(&module, hsaco_path);
  if (status != hipSuccess) return status;
  return hipModuleGetFunction(
      &kernel, module, "gdn_chunk_o_bv32_gfx1151");
}

extern "C" int netra_gdn_chunk_o(
    void* q, void* k, void* v, void* h, void* g, void* o,
    void* cu_seqlens, void* chunk_indices, float scale, uint32_t tokens,
    hipStream_t stream) {
  if (kernel == nullptr || tokens != 8192) return hipErrorInvalidValue;
  Args args{q, k, v, h, g, o, cu_seqlens, chunk_indices, scale, tokens};
  size_t arg_size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER,
      &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &arg_size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(
      kernel,
      4, 128, 32,
      128, 1, 1,
      0, stream, nullptr, config);
}
