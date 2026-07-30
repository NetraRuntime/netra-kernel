// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>
#include <mutex>

#ifndef NETRA_EXTEND_ATTENTION_KERNEL
#define NETRA_EXTEND_ATTENTION_KERNEL extend_attention_wmma_n64_gfx1151
#endif
#ifndef NETRA_EXTEND_ATTENTION_GRID_Y
#define NETRA_EXTEND_ATTENTION_GRID_Y 4
#endif
#ifndef NETRA_EXTEND_ATTENTION_BLOCK_X
#define NETRA_EXTEND_ATTENTION_BLOCK_X 512
#endif
#define NETRA_STRINGIFY_IMPL(value) #value
#define NETRA_STRINGIFY(value) NETRA_STRINGIFY_IMPL(value)

namespace {
hipModule_t module = nullptr;
hipFunction_t kernel = nullptr;
std::mutex load_mutex;

struct Args {
  void* q;
  void* k_extend;
  void* v_extend;
  void* o;
  void* k_buffer;
  void* v_buffer;
  void* kv_indices;
  void* kv_indptr;
  uint32_t tokens;
  float sm_scale;
};
static_assert(sizeof(Args) == 72);
}

extern "C" int netra_extend_attention_wmma_init(const char* hsaco_path) {
  std::lock_guard<std::mutex> lock(load_mutex);
  if (kernel != nullptr) return hipSuccess;
  hipError_t status = hipModuleLoad(&module, hsaco_path);
  if (status != hipSuccess) return status;
  status = hipModuleGetFunction(&kernel, module, NETRA_STRINGIFY(NETRA_EXTEND_ATTENTION_KERNEL));
  return status;
}

extern "C" int netra_extend_attention_wmma(
    void* q, void* k_extend, void* v_extend, void* o,
    void* k_buffer, void* v_buffer, void* kv_indices, void* kv_indptr,
    uint32_t tokens, float sm_scale,
    hipStream_t stream) {
  if (kernel == nullptr || tokens == 0 || (tokens & 63) != 0)
    return hipErrorInvalidValue;
  Args args{q, k_extend, v_extend, o, k_buffer, v_buffer, kv_indices,
            kv_indptr, tokens, sm_scale};
  size_t arg_size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &arg_size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(kernel, tokens / 64, NETRA_EXTEND_ATTENTION_GRID_Y, 1,
                               NETRA_EXTEND_ATTENTION_BLOCK_X, 1, 1,
                               0, stream, nullptr, config);
}
