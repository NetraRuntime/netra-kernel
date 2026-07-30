// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstdint>
#include <string>

namespace {
hipModule_t module{};
hipFunction_t kernel{};
std::string error;
}

extern "C" int gdn_kkt_blockwise_init(const char* path) {
  hipError_t status = hipModuleLoad(&module, path);
  if (status != hipSuccess) {
    error = hipGetErrorString(status);
    return static_cast<int>(status);
  }
  status = hipModuleGetFunction(
      &kernel, module, "gdn_kkt_solve_blockwise_gfx1151");
  if (status != hipSuccess) error = hipGetErrorString(status);
  return static_cast<int>(status);
}

extern "C" int gdn_kkt_blockwise_launch(
    void* k, void* g, void* beta, void* output, void* stream) {
  struct alignas(8) Args {
    void* k;
    void* g;
    void* beta;
    void* output;
  } args{k, g, beta, output};
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  hipError_t status = hipModuleLaunchKernel(
      kernel, 128, 32, 1, 32, 1, 1, 0,
      reinterpret_cast<hipStream_t>(stream), nullptr, config);
  if (status != hipSuccess) error = hipGetErrorString(status);
  return static_cast<int>(status);
}

extern "C" const char* gdn_kkt_blockwise_error() {
  return error.c_str();
}
