// SPDX-License-Identifier: MIT
//
// Module loading and caller-stream dispatch only. Compute remains in raw
// gfx950 AMDGCN assembly.
#include "qwen36_gdn_causal_conv_m8192_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr uint32_t kGridX = 8192;
constexpr uint32_t kBlockX = 256;
constexpr char kKernelName[] =
    "qwen36_gdn_causal_conv_m8192_bm32_gfx950";

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

void clear_module() {
  if (module != nullptr) (void)hipModuleUnload(module);
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
}

int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos) {
    return fail_message(std::string("Qwen GDN M8192 requires gfx950; got ") +
                        properties.gcnArchName);
  }
  return 0;
}

}  // namespace

extern "C" int netra_qwen36_gdn_causal_conv_m8192_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different GDN M8192 causal-conv module is loaded");
  }
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(&function, module, kKernelName);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_causal_conv_m8192_launch(
    const void* x_bf16,
    const void* weight_bf16,
    void* state_bf16,
    const void* cache_index_i32,
    const void* has_initial_state_i8,
    void* output_bf16,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("GDN M8192 causal-conv module is not loaded");
  if (x_bf16 == nullptr || weight_bf16 == nullptr ||
      state_bf16 == nullptr || cache_index_i32 == nullptr ||
      has_initial_state_i8 == nullptr || output_bf16 == nullptr)
    return fail_message("GDN M8192 causal-conv pointers must be nonnull");

  void* x_pointer = const_cast<void*>(x_bf16);
  void* weight_pointer = const_cast<void*>(weight_bf16);
  void* cache_index_pointer = const_cast<void*>(cache_index_i32);
  void* has_initial_pointer = const_cast<void*>(has_initial_state_i8);
  void* arguments[] = {
      &x_pointer,
      &weight_pointer,
      &state_bf16,
      &cache_index_pointer,
      &has_initial_pointer,
      &output_bf16,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, kGridX, 1, 1, kBlockX, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_causal_conv_m8192_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_module();
  last_error.clear();
  return 0;
}

extern "C" const char*
netra_qwen36_gdn_causal_conv_m8192_last_error(void) {
  return last_error.c_str();
}
