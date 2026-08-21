// SPDX-License-Identifier: MIT
// Graph-safe bridge for the exact GQA6/D256/M=8 native-FP8-KV contract.
#include "runtime/gfx950/attention/verify/attention_gqa6_fp8kv_m8_bridge.h"

#include <array>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <string>

namespace {

constexpr unsigned kKvHeads = 4;
constexpr unsigned kQueryHeadGroups = 3;
constexpr unsigned kThreads = 64;
constexpr unsigned kDynamicLdsBytes = 0;
constexpr std::array<uint32_t, 13> kSupportedBatches = {
    1, 2, 4, 8, 16, 32, 64, 80, 96, 112, 128, 160, 192};
constexpr const char* kQo32Kv64Symbol =
    "netra_attention_gqa6_fp8kv_m8_qo32_kv64_gfx950";
constexpr const char* kQo64Kv64Symbol =
    "netra_attention_gqa6_fp8kv_m8_qo64_kv64_gfx950";
constexpr const char* kQo32Kv32Symbol =
    "netra_attention_gqa6_fp8kv_m8_qo32_kv32_gfx950";

std::mutex module_mutex;
hipModule_t module_qo32_kv64 = nullptr;
hipModule_t module_qo64_kv64 = nullptr;
hipModule_t module_qo32_kv32 = nullptr;
hipFunction_t function_qo32_kv64 = nullptr;
hipFunction_t function_qo64_kv64 = nullptr;
hipFunction_t function_qo32_kv32 = nullptr;
std::string loaded_qo32_kv64_path;
std::string loaded_qo64_kv64_path;
std::string loaded_qo32_kv32_path;
thread_local char last_error[512] = {};

bool supported_batch(uint32_t batch_size) {
  for (const uint32_t value : kSupportedBatches) {
    if (value == batch_size) return true;
  }
  return false;
}

int fail(const char* operation, hipError_t error) {
  std::snprintf(last_error, sizeof(last_error), "%s: %s", operation,
                hipGetErrorString(error));
  return static_cast<int>(error);
}

int fail_message(const char* message) {
  std::snprintf(last_error, sizeof(last_error), "%s", message);
  return -1;
}

void clear_modules() {
  if (module_qo32_kv64 != nullptr) (void)hipModuleUnload(module_qo32_kv64);
  if (module_qo64_kv64 != nullptr) (void)hipModuleUnload(module_qo64_kv64);
  if (module_qo32_kv32 != nullptr) (void)hipModuleUnload(module_qo32_kv32);
  module_qo32_kv64 = nullptr;
  module_qo64_kv64 = nullptr;
  module_qo32_kv32 = nullptr;
  function_qo32_kv64 = nullptr;
  function_qo64_kv64 = nullptr;
  function_qo32_kv32 = nullptr;
  loaded_qo32_kv64_path.clear();
  loaded_qo64_kv64_path.clear();
  loaded_qo32_kv32_path.clear();
}

hipError_t load_function(hipModule_t* module, hipFunction_t* function,
                         const char* path, const char* symbol) {
  hipError_t error = hipModuleLoad(module, path);
  if (error != hipSuccess) return error;
  return hipModuleGetFunction(function, *module, symbol);
}

}  // namespace

extern "C" int netra_attention_gqa6_fp8kv_m8_load(
    const char* qo32_kv64_hsaco_path, const char* qo64_kv64_hsaco_path,
    const char* qo32_kv32_hsaco_path) {
  if (qo32_kv64_hsaco_path == nullptr || qo32_kv64_hsaco_path[0] == '\0' ||
      qo64_kv64_hsaco_path == nullptr || qo64_kv64_hsaco_path[0] == '\0' ||
      qo32_kv32_hsaco_path == nullptr || qo32_kv32_hsaco_path[0] == '\0')
    return fail_message("all attention HSACO paths must be nonempty");

  std::lock_guard<std::mutex> guard(module_mutex);
  if (module_qo32_kv64 != nullptr || module_qo64_kv64 != nullptr ||
      module_qo32_kv32 != nullptr) {
    if (loaded_qo32_kv64_path == qo32_kv64_hsaco_path &&
        loaded_qo64_kv64_path == qo64_kv64_hsaco_path &&
        loaded_qo32_kv32_path == qo32_kv32_hsaco_path) {
      last_error[0] = '\0';
      return 0;
    }
    return fail_message("different attention modules are already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::strstr(properties.gcnArchName, "gfx950") == nullptr)
    return fail_message("grouped attention requires gfx950");

  error = load_function(&module_qo32_kv64, &function_qo32_kv64,
                        qo32_kv64_hsaco_path, kQo32Kv64Symbol);
  if (error != hipSuccess) {
    clear_modules();
    return fail("load(qo32_kv64)", error);
  }
  error = load_function(&module_qo64_kv64, &function_qo64_kv64,
                        qo64_kv64_hsaco_path, kQo64Kv64Symbol);
  if (error != hipSuccess) {
    clear_modules();
    return fail("load(qo64_kv64)", error);
  }
  error = load_function(&module_qo32_kv32, &function_qo32_kv32,
                        qo32_kv32_hsaco_path, kQo32Kv32Symbol);
  if (error != hipSuccess) {
    clear_modules();
    return fail("load(qo32_kv32)", error);
  }

  loaded_qo32_kv64_path = qo32_kv64_hsaco_path;
  loaded_qo64_kv64_path = qo64_kv64_hsaco_path;
  loaded_qo32_kv32_path = qo32_kv32_hsaco_path;
  last_error[0] = '\0';
  return 0;
}

extern "C" int netra_attention_gqa6_fp8kv_m8_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_modules();
  last_error[0] = '\0';
  return 0;
}

extern "C" int netra_attention_gqa6_fp8kv_m8_launch(
    void* output_bf16, const void* query_bf16, const void* key_extend_bf16,
    const void* value_extend_bf16, const void* key_buffer_fp8_e4m3,
    const void* value_buffer_fp8_e4m3, const void* query_indptr,
    const void* kv_indptr_i32, const void* kv_indices,
    uint32_t query_indptr_stride_bytes, uint32_t kv_indices_stride_bytes,
    float softmax_scale, uint32_t batch_size, hipStream_t stream) {
  if (function_qo32_kv64 == nullptr || function_qo64_kv64 == nullptr ||
      function_qo32_kv32 == nullptr)
    return fail_message("grouped attention modules are not loaded");
  const std::array<const void*, 9> pointers = {
      output_bf16, query_bf16, key_extend_bf16, value_extend_bf16,
      key_buffer_fp8_e4m3, value_buffer_fp8_e4m3, query_indptr,
      kv_indptr_i32, kv_indices};
  for (const void* pointer : pointers) {
    if (pointer == nullptr)
      return fail_message("grouped attention pointers must be nonnull");
  }
  if (!supported_batch(batch_size))
    return fail_message("grouped attention batch is not a captured profile");

  hipFunction_t function = nullptr;
  if (query_indptr_stride_bytes == 4 && kv_indices_stride_bytes == 4) {
    function = function_qo32_kv32;
  } else if (query_indptr_stride_bytes == 4 && kv_indices_stride_bytes == 8) {
    function = function_qo32_kv64;
  } else if (query_indptr_stride_bytes == 8 && kv_indices_stride_bytes == 8) {
    function = function_qo64_kv64;
  } else {
    return fail_message("unsupported query-indptr/KV-index width pair");
  }

  void* query_pointer = const_cast<void*>(query_bf16);
  void* key_extend_pointer = const_cast<void*>(key_extend_bf16);
  void* value_extend_pointer = const_cast<void*>(value_extend_bf16);
  void* key_buffer_pointer = const_cast<void*>(key_buffer_fp8_e4m3);
  void* value_buffer_pointer = const_cast<void*>(value_buffer_fp8_e4m3);
  void* query_indptr_pointer = const_cast<void*>(query_indptr);
  void* kv_indptr_pointer = const_cast<void*>(kv_indptr_i32);
  void* kv_indices_pointer = const_cast<void*>(kv_indices);
  void* hidden_scratch = nullptr;
  void* hidden_profile = nullptr;
  void* arguments[] = {
      &query_pointer, &key_extend_pointer, &value_extend_pointer, &output_bf16,
      &key_buffer_pointer, &value_buffer_pointer, &query_indptr_pointer,
      &kv_indptr_pointer, &kv_indices_pointer, &softmax_scale,
      &hidden_scratch, &hidden_profile};
  const hipError_t error = hipModuleLaunchKernel(
      function, batch_size, kKvHeads, kQueryHeadGroups, kThreads, 1, 1,
      kDynamicLdsBytes, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error[0] = '\0';
  return 0;
}

extern "C" const char* netra_attention_gqa6_fp8kv_m8_last_error(void) {
  return last_error;
}
