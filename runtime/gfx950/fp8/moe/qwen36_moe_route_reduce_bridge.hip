// SPDX-License-Identifier: MIT
// HIP is used only for gfx950 module management and dispatch.  All reduction
// arithmetic is implemented by the raw AMDGCN code object in kernels/gfx950/.
#include "qwen36_moe_route_reduce_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr unsigned int kGridX = 32;
constexpr unsigned int kThreads = 64;
constexpr const char* kKernelName =
    "qwen36_moe_route_reduce_f32_gfx950";

std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
std::string loaded_path;
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

int require_gfx950() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos) {
    return fail_message(
        std::string("raw route reduction requires gfx950; got ") +
        properties.gcnArchName);
  }
  return 0;
}

}  // namespace

extern "C" int netra_qwen36_moe_route_reduce_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0') {
    return fail_message("hsaco_path must be nonempty");
  }
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different route-reduction module is loaded");
  }
  int status = require_gfx950();
  if (status != 0) return status;
  hipError_t error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(&function, module, kKernelName);
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    function = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_route_reduce_launch(
    const float* partial_f32,
    const float* topk_weights_f32,
    void* output_bf16,
    int rows,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("raw module is not loaded");
  if (partial_f32 == nullptr || topk_weights_f32 == nullptr ||
      output_bf16 == nullptr) {
    return fail_message("launch pointers must be nonnull");
  }
  if (rows <= 0) return fail_message("rows must be positive");
  void* arguments[] = {
      &partial_f32, &topk_weights_f32, &output_bf16,
  };
  hipError_t error = hipModuleLaunchKernel(
      function,
      kGridX,
      static_cast<unsigned int>(rows),
      1,
      kThreads,
      1,
      1,
      0,
      stream,
      arguments,
      nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_route_reduce_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_moe_route_reduce_last_error(void) {
  return last_error.c_str();
}
