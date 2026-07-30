// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstddef>

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
  return hipModuleLaunchKernel(function_handle, 32, 1, 1, 256, 1, 1, 0,
                               stream, nullptr, config);
}
}  // namespace

extern "C" int netra_bf16_shared_gate_up_silu_load(const char* hsaco) {
  if (function_handle) return 0;
  hipError_t status = hipModuleLoad(&module_handle, hsaco);
  if (status != hipSuccess) return static_cast<int>(status);
  status = hipModuleGetFunction(&function_handle, module_handle,
                                "bf16_shared_gate_up_silu_decode_wave2_gfx1151");
  return static_cast<int>(status);
}

extern "C" int netra_bf16_shared_gate_up_silu_launch(
    const void* weights, const void* activation, void* output,
    hipStream_t stream) {
  if (!function_handle) return static_cast<int>(hipErrorNotInitialized);
  return static_cast<int>(launch(weights, activation, output, stream));
}

extern "C" int netra_bf16_shared_gate_up_silu_time(
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
