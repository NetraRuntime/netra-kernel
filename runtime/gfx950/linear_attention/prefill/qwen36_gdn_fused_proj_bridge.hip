// SPDX-License-Identifier: MIT
#include "qwen36_gdn_fused_proj_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t kernel = nullptr;
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

extern "C" int netra_qwen36_gdn_fused_proj_bf16_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different GDN fused-projection object is already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("GDN fused projection requires gfx950; got ") + properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(&kernel, module, "qwen36_gdn_fused_proj_bf16_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_fused_proj_bf16_launch(
    uint16_t* mixed_qkv_bf16,
    uint16_t* z_bf16,
    uint16_t* b_bf16,
    uint16_t* a_bf16,
    const uint16_t* mixed_qkvz_bf16,
    const uint16_t* mixed_ba_bf16,
    uint32_t rows,
    hipStream_t stream) {
  if (kernel == nullptr) return fail_message("GDN fused-projection module is not loaded");
  if (mixed_qkv_bf16 == nullptr || z_bf16 == nullptr || b_bf16 == nullptr ||
      a_bf16 == nullptr || mixed_qkvz_bf16 == nullptr || mixed_ba_bf16 == nullptr)
    return fail_message("GDN fused-projection pointers must be nonnull");
  if (rows == 0) return fail_message("GDN fused-projection rows must be nonzero");

  void* qkv_pointer = mixed_qkv_bf16;
  void* z_pointer = z_bf16;
  void* b_pointer = b_bf16;
  void* a_pointer = a_bf16;
  void* qkvz_pointer = const_cast<uint16_t*>(mixed_qkvz_bf16);
  void* ba_pointer = const_cast<uint16_t*>(mixed_ba_bf16);
  void* arguments[] = {
      &qkv_pointer, &z_pointer, &b_pointer, &a_pointer, &qkvz_pointer, &ba_pointer};
  hipError_t error = hipModuleLaunchKernel(
      kernel, rows, 1, 1, 256, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_fused_proj_bf16_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  module = nullptr;
  kernel = nullptr;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_fused_proj_bf16_last_error(void) {
  return last_error.c_str();
}
