// SPDX-License-Identifier: MIT
#include "qwen36_attention_gate_bridge.h"

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
}

extern "C" int netra_qwen36_attention_gate_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) return 0;
    return fail_message("a different attention-gate module is already loaded");
  }
  int device = 0;
  hipDeviceProp_t properties{};
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("requires gfx950; got ") + properties.gcnArchName);
  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) return fail("hipModuleLoad", error);
  error = hipModuleGetFunction(
      &function, module, "qwen36_attention_gate_bf16_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_attention_gate_launch(
    void* output_bf16, const void* input_bf16, const void* gate_bf16,
    uint32_t token_count, uint32_t gate_token_stride_elements,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("module is not loaded");
  if (output_bf16 == nullptr || input_bf16 == nullptr || gate_bf16 == nullptr)
    return fail_message("attention-gate pointers must be nonnull");
  if (token_count == 0 || gate_token_stride_elements < 8192)
    return fail_message("invalid Qwen attention-gate shape or stride");
  void* input = const_cast<void*>(input_bf16);
  void* gate = const_cast<void*>(gate_bf16);
  void* arguments[] = {&output_bf16, &input, &gate, &token_count,
                       &gate_token_stride_elements};
  hipError_t error = hipModuleLaunchKernel(
      function, token_count * 16, 1, 1, 64, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_attention_gate_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) return 0;
  hipError_t error = hipModuleUnload(module);
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
  return error == hipSuccess ? 0 : fail("hipModuleUnload", error);
}

extern "C" const char* netra_qwen36_attention_gate_last_error(void) {
  return last_error.c_str();
}
