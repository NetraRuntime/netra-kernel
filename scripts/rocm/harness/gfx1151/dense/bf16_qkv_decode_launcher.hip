// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstddef>

#ifndef NETRA_BF16_QKV_KERNEL
#define NETRA_BF16_QKV_KERNEL bf16_qkv_decode_wave4_gfx1151
#endif

#ifndef NETRA_BF16_QKV_GRID_X
#define NETRA_BF16_QKV_GRID_X 288
#endif

#define NETRA_STRINGIFY_IMPL(x) #x
#define NETRA_STRINGIFY(x) NETRA_STRINGIFY_IMPL(x)

namespace {
hipModule_t module_handle{};
hipFunction_t function_handle{};

struct alignas(8) Args {
  const void* weights;
  const void* activation;
  void* output;
};
static_assert(sizeof(Args) == 24);

hipError_t launch(const void* weights, const void* activation, void* output,
                  hipStream_t stream) {
  Args args{weights, activation, output};
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
      HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(function_handle, NETRA_BF16_QKV_GRID_X,
                               1, 1, 256, 1, 1, 0,
                               stream, nullptr, config);
}
}  // namespace

extern "C" int netra_bf16_qkv_load(const char* hsaco) {
  if (function_handle) return 0;
  hipError_t status = hipModuleLoad(&module_handle, hsaco);
  if (status != hipSuccess) return static_cast<int>(status);
  status = hipModuleGetFunction(
      &function_handle, module_handle,
      NETRA_STRINGIFY(NETRA_BF16_QKV_KERNEL));
  return static_cast<int>(status);
}

extern "C" int netra_bf16_qkv_launch(
    const void* weights, const void* activation, void* output,
    hipStream_t stream) {
  if (!function_handle) return static_cast<int>(hipErrorNotInitialized);
  return static_cast<int>(launch(weights, activation, output, stream));
}

extern "C" int netra_bf16_qkv_time(
    const void* weights, const void* activation, void* output,
    hipStream_t stream, int warmups, int iterations, float* mean_ms) {
  if (!function_handle || !mean_ms || warmups < 0 || iterations < 1)
    return static_cast<int>(hipErrorInvalidValue);
  for (int i = 0; i < warmups; ++i) {
    hipError_t status = launch(weights, activation, output, stream);
    if (status != hipSuccess) return static_cast<int>(status);
  }
  hipEvent_t begin{}, end{};
  hipError_t status = hipEventCreate(&begin);
  if (status != hipSuccess) return static_cast<int>(status);
  status = hipEventCreate(&end);
  if (status != hipSuccess) return static_cast<int>(status);
  hipEventRecord(begin, stream);
  for (int i = 0; i < iterations; ++i) {
    status = launch(weights, activation, output, stream);
    if (status != hipSuccess) return static_cast<int>(status);
  }
  hipEventRecord(end, stream);
  status = hipEventSynchronize(end);
  float elapsed = 0.0f;
  if (status == hipSuccess) status = hipEventElapsedTime(&elapsed, begin, end);
  hipEventDestroy(begin);
  hipEventDestroy(end);
  if (status == hipSuccess) *mean_ms = elapsed / iterations;
  return static_cast<int>(status);
}
