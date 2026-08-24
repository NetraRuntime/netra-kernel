// SPDX-License-Identifier: MIT
//
// Module management and caller-stream dispatch only. Compute is implemented
// by the raw gfx950 AMDGCN code object under kernels/gfx950/.
#include "qwen36_router_bf16_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

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

}  // namespace

extern "C" int netra_qwen36_router_bf16_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different router code object is already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos)
    return fail_message(
        std::string("router code object requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module, "qwen36_router_bf16_gemv_gfx950");
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

extern "C" int netra_qwen36_router_bf16_launch(
    void* output_logits_bf16,
    const void* hidden_bf16,
    const void* router_weight_bf16,
    uint32_t rows,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("router module is not loaded");
  if (output_logits_bf16 == nullptr || hidden_bf16 == nullptr ||
      router_weight_bf16 == nullptr)
    return fail_message("router launch pointers must be nonnull");
  if (rows != 1 && rows != 12 && rows != 16 && rows != 32 && rows != 64)
    return fail_message("router rows must be 1, 12, 16, 32, or 64");

  void* hidden_pointer = const_cast<void*>(hidden_bf16);
  void* weight_pointer = const_cast<void*>(router_weight_bf16);
  void* arguments[] = {
      &output_logits_bf16,
      &hidden_pointer,
      &weight_pointer,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, 256, rows, 1, 64, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_router_bf16_unload(void) {
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

extern "C" const char* netra_qwen36_router_bf16_last_error(void) {
  return last_error.c_str();
}
