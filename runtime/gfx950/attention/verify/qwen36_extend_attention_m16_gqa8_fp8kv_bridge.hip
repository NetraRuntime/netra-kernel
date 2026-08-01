// SPDX-License-Identifier: MIT
//
// gfx950 module loading and graph-safe dispatch only. The compute kernel is
// raw AMDGCN in kernels/gfx950/attention/verify/.
#include "qwen36_extend_attention_m16_gqa8_fp8kv_bridge.h"

#include <hip/hip_runtime.h>

#include <array>
#include <cstdint>
#include <mutex>
#include <string>

namespace {

constexpr unsigned kKvHeads = 2;
constexpr unsigned kQueryHeadGroups = 2;
constexpr unsigned kThreads = 512;
constexpr unsigned kDynamicLdsBytes = 32768;
constexpr unsigned kMaximumBatch = 64;

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

}  // namespace

extern "C" int netra_qwen36_extend_attention_m16_gqa8_fp8kv_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("attention HSACO path must be nonempty");

  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different attention module is already loaded");
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
        std::string("Qwen target grouped attention requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module, "qwen36_extend_attention_m16_gqa8_fp8kv_gfx950");
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleGetFunction", error);
  }

  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_extend_attention_m16_gqa8_fp8kv_launch(
    void* output_bf16,
    const void* query_bf16,
    const void* key_extend_bf16,
    const void* value_extend_bf16,
    const void* key_buffer_fp8_e4m3,
    const void* value_buffer_fp8_e4m3,
    const void* query_indptr_i64,
    const void* kv_indptr_i32,
    const void* kv_indices_i64,
    float softmax_scale,
    uint32_t batch_size,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("target grouped attention module is not loaded");
  const std::array<const void*, 9> pointers = {
      output_bf16,       query_bf16,       key_extend_bf16,
      value_extend_bf16, key_buffer_fp8_e4m3, value_buffer_fp8_e4m3,
      query_indptr_i64,  kv_indptr_i32,    kv_indices_i64,
  };
  for (const void* pointer : pointers) {
    if (pointer == nullptr)
      return fail_message("target grouped attention pointers must be nonnull");
  }
  if (batch_size == 0 || batch_size > kMaximumBatch)
    return fail_message("target grouped attention batch must be in [1,64]");

  void* query_pointer = const_cast<void*>(query_bf16);
  void* key_extend_pointer = const_cast<void*>(key_extend_bf16);
  void* value_extend_pointer = const_cast<void*>(value_extend_bf16);
  void* key_buffer_pointer = const_cast<void*>(key_buffer_fp8_e4m3);
  void* value_buffer_pointer = const_cast<void*>(value_buffer_fp8_e4m3);
  void* query_indptr_pointer = const_cast<void*>(query_indptr_i64);
  void* kv_indptr_pointer = const_cast<void*>(kv_indptr_i32);
  void* kv_indices_pointer = const_cast<void*>(kv_indices_i64);
  void* hidden_scratch = nullptr;
  void* hidden_profile = nullptr;
  void* arguments[] = {
      &query_pointer,
      &key_extend_pointer,
      &value_extend_pointer,
      &output_bf16,
      &key_buffer_pointer,
      &value_buffer_pointer,
      &query_indptr_pointer,
      &kv_indptr_pointer,
      &kv_indices_pointer,
      &softmax_scale,
      &hidden_scratch,
      &hidden_profile,
  };
  const hipError_t error = hipModuleLaunchKernel(
      function, batch_size, kKvHeads, kQueryHeadGroups, kThreads, 1, 1,
      kDynamicLdsBytes, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_extend_attention_m16_gqa8_fp8kv_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  const hipError_t error = hipModuleUnload(module);
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  last_error.clear();
  return 0;
}

extern "C" const char*
netra_qwen36_extend_attention_m16_gqa8_fp8kv_last_error(void) {
  return last_error.c_str();
}
