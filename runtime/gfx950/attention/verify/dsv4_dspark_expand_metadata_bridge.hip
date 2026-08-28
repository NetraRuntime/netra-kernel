// SPDX-License-Identifier: MIT
// Module management and allocation-free caller-stream dispatch only.
#include "dsv4_dspark_expand_metadata_bridge.h"

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

extern "C" int netra_dsv4_dspark_expand_metadata_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different metadata code object is already loaded");
  }
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("metadata code object requires gfx950; got ") +
        properties.gcnArchName);
  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &kernel, module, "dsv4_dspark_expand_metadata_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_expand_metadata_launch(
    int32_t* seq_lens_causal_i32,
    int64_t* req_pool_repeated_i64,
    const int64_t* req_pool_i64,
    const int64_t* seq_lens_i64,
    const int32_t* extend_lens_i32,
    const int32_t* extend_starts_i32,
    uint32_t batch,
    uint32_t real_tokens,
    uint32_t total_tokens,
    hipStream_t stream) {
  if (kernel == nullptr) return fail_message("metadata module is not loaded");
  if (seq_lens_causal_i32 == nullptr || req_pool_repeated_i64 == nullptr ||
      req_pool_i64 == nullptr || seq_lens_i64 == nullptr ||
      extend_lens_i32 == nullptr)
    return fail_message("required metadata launch pointers must be nonnull");
  if (batch == 0 || batch > 256)
    return fail_message("metadata batch must be in [1, 256]");
  if (real_tokens == 0 || real_tokens > total_tokens || total_tokens > 1536)
    return fail_message("metadata token counts must satisfy 0 < real <= total <= 1536");
  uint32_t uniform_width = 0;
  if (extend_starts_i32 == nullptr) {
    if (real_tokens % batch != 0)
      return fail_message("uniform metadata token count must be divisible by batch");
    uniform_width = real_tokens / batch;
    if (uniform_width != 5 && uniform_width != 6)
      return fail_message("uniform metadata width must be five or six tokens per request");
  }

  void* causal = seq_lens_causal_i32;
  void* repeated = req_pool_repeated_i64;
  void* req = const_cast<int64_t*>(req_pool_i64);
  void* seq = const_cast<int64_t*>(seq_lens_i64);
  void* ext = const_cast<int32_t*>(extend_lens_i32);
  void* starts = const_cast<int32_t*>(extend_starts_i32);
  void* arguments[] = {
      &causal, &repeated, &req, &seq, &ext, &starts,
      &batch, &real_tokens, &total_tokens, &uniform_width};
  hipError_t error = hipModuleLaunchKernel(
      kernel, (total_tokens + 255) / 256, 1, 1, 256, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_expand_metadata_unload(void) {
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

extern "C" const char* netra_dsv4_dspark_expand_metadata_last_error(void) {
  return last_error.c_str();
}
