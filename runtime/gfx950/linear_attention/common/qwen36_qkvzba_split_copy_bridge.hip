// SPDX-License-Identifier: MIT
// HIP is used only for module management and caller-stream dispatch. Compute
// is the raw gfx950 AMDGCN kernel in kernels/gfx950/linear_attention/common/.
#include "qwen36_qkvzba_split_copy_bridge.h"

#include <hip/hip_runtime.h>

#include <cstdint>
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

extern "C" int netra_qwen36_qkvzba_split_copy_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different QKVZ/BA split-copy object is loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("QKVZ/BA split-copy requires gfx950; got ") +
                        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module, "qwen36_qkvzba_split_copy_bf16_x64_gfx950");
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

extern "C" int netra_qwen36_qkvzba_split_copy_launch(
    const void* mixed_qkvz,
    const void* mixed_ba,
    void* mixed_qkv,
    void* z,
    void* b,
    void* a,
    unsigned int token_count,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("QKVZ/BA split-copy module is not loaded");
  if (mixed_qkvz == nullptr || mixed_ba == nullptr || mixed_qkv == nullptr ||
      z == nullptr || b == nullptr || a == nullptr)
    return fail_message("QKVZ/BA split-copy pointers must be nonnull");
  if (token_count == 0)
    return fail_message("QKVZ/BA split-copy token_count must be positive");

  void* qkvz_pointer = const_cast<void*>(mixed_qkvz);
  void* ba_pointer = const_cast<void*>(mixed_ba);
  void* arguments[] = {
      &qkvz_pointer, &ba_pointer, &mixed_qkv, &z, &b, &a,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, 2, token_count, 1, 256, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_qkvzba_split_copy_unload(void) {
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

extern "C" const char* netra_qwen36_qkvzba_split_copy_last_error(void) {
  return last_error.c_str();
}
