// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstdint>
#include <mutex>

namespace {
hipModule_t module = nullptr;
hipFunction_t kernel = nullptr;
std::mutex load_mutex;

struct alignas(8) Args {
  void* k;
  void* v;
  void* beta;
  void* w;
  void* u;
  void* A;
  void* g;
  void* cu_seqlens;
  void* chunk_indices;
  uint32_t tokens;
};
static_assert(sizeof(Args) == 80);
}  // namespace

extern "C" int netra_recompute_w_u_init(const char* hsaco_path) {
  std::lock_guard<std::mutex> lock(load_mutex);
  if (kernel != nullptr) return hipSuccess;
  hipError_t status = hipModuleLoad(&module, hsaco_path);
  if (status != hipSuccess) return status;
  return hipModuleGetFunction(
      &kernel, module, "recompute_w_u_reuse_a_gfx1151");
}

extern "C" int netra_recompute_w_u(
    void* k, void* v, void* beta, void* w, void* u, void* A, void* g,
    void* cu_seqlens, void* chunk_indices, uint32_t tokens,
    hipStream_t stream) {
  if (kernel == nullptr || tokens != 8192) return hipErrorInvalidValue;
  Args args{k, v, beta, w, u, A, g, cu_seqlens, chunk_indices, tokens};
  size_t arg_size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER,
      &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &arg_size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(
      kernel, 128, 32, 1, 64, 1, 1, 0, stream, nullptr, config);
}
