// SPDX-License-Identifier: MIT
// Module loading and caller-stream dispatch only. Compute is raw gfx950 AMDGCN.
#include "qwen36_gdn_qkvz_conv_m12_bridge.h"

#include <hip/hip_runtime.h>

#include <array>
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

int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("Qwen GDN causal convolution requires gfx950; got ") +
        properties.gcnArchName);
  return 0;
}

}  // namespace

extern "C" int netra_qwen36_gdn_qkvz_conv_m12_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different GDN causal-convolution module is loaded");
  }
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) return fail("hipModuleLoad", error);
  error = hipModuleGetFunction(
      &function, module, "qwen36_gdn_qkvz_conv_m12_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" uint32_t netra_qwen36_gdn_qkvz_conv_m12_batch_capacity(void) {
  return UINT32_MAX;
}

extern "C" int netra_qwen36_gdn_qkvz_conv_m12_launch(
    const void* x_bf16,
    const void* weight_bf16,
    void* state_bf16,
    const void* state_indices_i32,
    void* intermediate_window_bf16,
    const void* intermediate_indices_i32,
    void* output_bf16,
    uint32_t batch_size,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("GDN causal-convolution module is not loaded");
  const std::array<const void*, 7> pointers = {
      x_bf16, weight_bf16, state_bf16, state_indices_i32,
      intermediate_window_bf16, intermediate_indices_i32, output_bf16};
  for (const void* pointer : pointers) {
    if (pointer == nullptr)
      return fail_message("GDN causal-convolution pointers must be nonnull");
  }
  if (batch_size == 0)
    return fail_message("GDN M=12 batch size must be positive");

  void* x_pointer = const_cast<void*>(x_bf16);
  void* weight_pointer = const_cast<void*>(weight_bf16);
  void* state_indices_pointer = const_cast<void*>(state_indices_i32);
  void* intermediate_indices_pointer =
      const_cast<void*>(intermediate_indices_i32);
  void* arguments[] = {
      &x_pointer,
      &weight_pointer,
      &state_bf16,
      &state_indices_pointer,
      &intermediate_window_bf16,
      &intermediate_indices_pointer,
      &output_bf16,
      &batch_size,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, batch_size * 32, 1, 1, 256, 1, 1, 0, stream, arguments,
      nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_qkvz_conv_m12_last_error(void) {
  return last_error.c_str();
}
