// SPDX-License-Identifier: MIT
//
// Module management and caller-stream dispatch only. Compute is implemented
// by raw gfx950 AMDGCN under kernels/gfx950/fp8/dense/prefill/.
#include "qwen36_dense_m768_n12288_k2048_bridge.h"

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

extern "C" int netra_qwen36_dense_m768_n12288_k2048_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message(
        "a different dense M=768 N=12288 K=2048 code object is already loaded");
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
        std::string("dense M=768 N=12288 K=2048 projection requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module,
      "qwen36_dense_m768_n12288_k2048_fp8_mfma_m32n32_gfx950");
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

extern "C" int netra_qwen36_dense_m768_n12288_k2048_launch(
    const void* activation_fp8,
    const void* activation_scale_f32,
    const void* shuffled_weight_fp8,
    const void* weight_scale_f32,
    void* output_bf16,
    unsigned int n,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("dense M=768 N=12288 K=2048 module is not loaded");
  if (activation_fp8 == nullptr || activation_scale_f32 == nullptr ||
      shuffled_weight_fp8 == nullptr || weight_scale_f32 == nullptr ||
      output_bf16 == nullptr)
    return fail_message("dense M=768 N=12288 K=2048 pointers must be nonnull");
  if (n != 9216 && n != 12288)
    return fail_message("dense M=768 N=12288 K=2048 n must be 9216 or 12288");

  void* activation_pointer = const_cast<void*>(activation_fp8);
  void* activation_scale_pointer =
      const_cast<void*>(activation_scale_f32);
  void* weight_pointer = const_cast<void*>(shuffled_weight_fp8);
  void* weight_scale_pointer = const_cast<void*>(weight_scale_f32);
  std::uint64_t output_stride_bytes =
      static_cast<std::uint64_t>(n) * sizeof(std::uint16_t);
  void* arguments[] = {
      &activation_pointer,
      &activation_scale_pointer,
      &weight_pointer,
      &weight_scale_pointer,
      &output_bf16,
      &output_stride_bytes,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, n / 32, 24, 1, 64, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_dense_m768_n12288_k2048_unload(void) {
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

extern "C" const char* netra_qwen36_dense_m768_n12288_k2048_last_error(void) {
  return last_error.c_str();
}

