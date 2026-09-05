// SPDX-License-Identifier: MIT
#include "unified_kv_prefill_indptr_i64_i32_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr uint32_t kThreads = 1024;
constexpr uint32_t kMaxTokens = 8192;
constexpr uint32_t kMaxWindow = 65536;
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

extern "C" int netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different unified-KV code object is already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("unified-KV code object requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &kernel, module,
      "netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_launch(
    const int64_t* positions_i64,
    const int64_t* chunk_start_i64,
    const int32_t* compressed_lengths_i32,
    int32_t* prefix_indptr_i32,
    int32_t* extend_indptr_i32,
    uint32_t tokens,
    uint32_t window,
    uint32_t has_compress,
    hipStream_t stream) {
  if (kernel == nullptr) return fail_message("unified-KV module is not loaded");
  if (prefix_indptr_i32 == nullptr || extend_indptr_i32 == nullptr)
    return fail_message("unified-KV output pointers must be nonnull");
  if (tokens > kMaxTokens)
    return fail_message("unified-KV tokens must be in [0, 8192]");
  if (tokens != 0 &&
      (positions_i64 == nullptr || chunk_start_i64 == nullptr))
    return fail_message("nonempty unified-KV input pointers must be nonnull");
  if (window == 0 || window > kMaxWindow)
    return fail_message("unified-KV window must be in [1, 65536]");
  if (has_compress > 1)
    return fail_message("unified-KV has_compress must be 0 or 1");
  if (has_compress != 0) {
    if (tokens != 0 && compressed_lengths_i32 == nullptr)
      return fail_message("compressed lengths pointer must be nonnull");
  }

  void* positions_pointer = const_cast<int64_t*>(positions_i64);
  void* chunk_start_pointer = const_cast<int64_t*>(chunk_start_i64);
  void* compressed_lengths_pointer =
      const_cast<int32_t*>(compressed_lengths_i32);
  void* prefix_pointer = prefix_indptr_i32;
  void* extend_pointer = extend_indptr_i32;
  void* arguments[] = {
      &positions_pointer, &chunk_start_pointer, &compressed_lengths_pointer,
      &prefix_pointer, &extend_pointer, &tokens, &window, &has_compress};
  hipError_t error = hipModuleLaunchKernel(
      kernel, 1, 1, 1, kThreads, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_unload(void) {
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

extern "C" const char*
netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_last_error(void) {
  return last_error.c_str();
}
