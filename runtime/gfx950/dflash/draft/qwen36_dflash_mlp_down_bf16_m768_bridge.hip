// SPDX-License-Identifier: MIT
// Module management and graph-safe caller-stream dispatch only. Compute is raw
// gfx950 AMDGCN under kernels/gfx950/dflash/draft/.
#include "qwen36_dflash_mlp_down_bf16_m768_bridge.h"

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

extern "C" int netra_qwen36_dflash_mlp_down_bf16_m768_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different M768 MLP down code object is loaded");
  }
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("M768 MLP down requires gfx950; got ") +
                        properties.gcnArchName);
  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module,
      "qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950");
  if (error != hipSuccess) {
    error = hipModuleGetFunction(
        &function, module,
        "qwen36_dflash_mlp_down_bf16_m768_m64n64_global_gfx950");
  }
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

extern "C" int netra_qwen36_dflash_mlp_down_bf16_m768_launch(
    void* output_bf16,
    const void* input_bf16,
    const void* weight_bf16,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("M768 MLP down is not loaded");
  if (output_bf16 == nullptr || input_bf16 == nullptr || weight_bf16 == nullptr)
    return fail_message("M768 MLP down pointers must be nonnull");
  void* input_pointer = const_cast<void*>(input_bf16);
  void* weight_pointer = const_cast<void*>(weight_bf16);
  void* arguments[] = {&output_bf16, &input_pointer, &weight_pointer};
  hipError_t error = hipModuleLaunchKernel(
      function, 32, 12, 1, 256, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_dflash_mlp_down_bf16_m768_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) return 0;
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char*
netra_qwen36_dflash_mlp_down_bf16_m768_last_error(void) {
  return last_error.c_str();
}
