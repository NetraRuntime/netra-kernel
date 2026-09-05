// SPDX-License-Identifier: MIT
// Caller-stream module dispatch only. The GPU computation is in Netra-kernel.
#include "dsv4_router_shared_topk_bf16_v1_bridge.h"

#include <hip/hip_runtime.h>

#include <cstdint>
#include <mutex>
#include <string>

namespace {

constexpr uint32_t kAbiVersion = 1;
constexpr uint32_t kMaxRows = 8192;
constexpr uintptr_t kInputAlignment = 2;
constexpr uintptr_t kOutputAlignment = 4;

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

bool aligned(const void* pointer, uintptr_t alignment) {
  return reinterpret_cast<uintptr_t>(pointer) % alignment == 0;
}

}  // namespace

extern "C" uint32_t netra_dsv4_router_shared_topk_bf16_v1_abi_version(void) {
  return kAbiVersion;
}

extern "C" int netra_dsv4_router_shared_topk_bf16_v1_load(
    const char* hsaco_path) {
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
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("router code object requires gfx950; got ") +
                        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module, "netra_dsv4_router_shared_topk_bf16_v1_gfx950");
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

extern "C" int netra_dsv4_router_shared_topk_bf16_v1_launch(
    const void* scores_bf16,
    const void* correction_bias_bf16,
    void* output_weights_f32,
    void* output_indices_i32,
    uint32_t rows,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("router module is not loaded");
  if (scores_bf16 == nullptr || correction_bias_bf16 == nullptr ||
      output_weights_f32 == nullptr || output_indices_i32 == nullptr)
    return fail_message("router launch pointers must be nonnull");
  if (rows == 0 || rows > kMaxRows)
    return fail_message("router rows must be in [1, 8192]");
  if (!aligned(scores_bf16, kInputAlignment) ||
      !aligned(correction_bias_bf16, kInputAlignment) ||
      !aligned(output_weights_f32, kOutputAlignment) ||
      !aligned(output_indices_i32, kOutputAlignment))
    return fail_message("router pointers do not satisfy ABI alignment");

  void* scores_pointer = const_cast<void*>(scores_bf16);
  void* bias_pointer = const_cast<void*>(correction_bias_bf16);
  void* arguments[] = {
      &scores_pointer,
      &bias_pointer,
      &output_weights_f32,
      &output_indices_i32,
      &rows,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, rows, 1, 1, 64, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_router_shared_topk_bf16_v1_unload(void) {
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

extern "C" const char*
netra_dsv4_router_shared_topk_bf16_v1_last_error(void) {
  return last_error.c_str();
}
