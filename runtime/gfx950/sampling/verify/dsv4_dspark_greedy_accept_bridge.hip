// SPDX-License-Identifier: MIT
#include "dsv4_dspark_greedy_accept_bridge.h"

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

extern "C" int netra_dsv4_dspark_greedy_accept_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different greedy-accept code object is already loaded");
  }
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(
        std::string("greedy-accept code object requires gfx950; got ") +
        properties.gcnArchName);
  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &kernel, module, "dsv4_dspark_greedy_accept_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_greedy_accept_launch(
    int64_t* correct_i64,
    int64_t* bonus_i64,
    int32_t* trim_i32,
    int32_t* commit_i32,
    int64_t* new_seq_i64,
    int64_t* out_tokens_i64,
    int32_t* swa_loc_i32,
    const int64_t* draft_tokens_i64,
    const int64_t* target_predict_i64,
    const int64_t* verify_lens_i64,
    const int64_t* prefix_lens_i64,
    const int64_t* req_slots_i64,
    uint32_t batch,
    hipStream_t stream) {
  if (kernel == nullptr) return fail_message("greedy-accept module is not loaded");
  if (correct_i64 == nullptr || bonus_i64 == nullptr || trim_i32 == nullptr ||
      commit_i32 == nullptr || new_seq_i64 == nullptr ||
      out_tokens_i64 == nullptr || swa_loc_i32 == nullptr ||
      draft_tokens_i64 == nullptr ||
      target_predict_i64 == nullptr || verify_lens_i64 == nullptr ||
      prefix_lens_i64 == nullptr || req_slots_i64 == nullptr)
    return fail_message("greedy-accept launch pointers must be nonnull");
  if (batch == 0 || batch > 256)
    return fail_message("greedy-accept batch must be in [1, 256]");

  void* correct = correct_i64;
  void* bonus = bonus_i64;
  void* trim = trim_i32;
  void* commit = commit_i32;
  void* new_seq = new_seq_i64;
  void* out_tokens = out_tokens_i64;
  void* swa_loc = swa_loc_i32;
  void* draft_tokens = const_cast<int64_t*>(draft_tokens_i64);
  void* target_predict = const_cast<int64_t*>(target_predict_i64);
  void* verify_lens = const_cast<int64_t*>(verify_lens_i64);
  void* prefix_lens = const_cast<int64_t*>(prefix_lens_i64);
  void* req_slots = const_cast<int64_t*>(req_slots_i64);
  void* arguments[] = {
      &correct, &bonus, &trim, &commit, &new_seq, &out_tokens,
      &draft_tokens, &target_predict, &verify_lens, &prefix_lens, &batch,
      &req_slots, &swa_loc};
  hipError_t error = hipModuleLaunchKernel(
      kernel, 1, 1, 1, 256, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_greedy_accept_unload(void) {
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

extern "C" const char* netra_dsv4_dspark_greedy_accept_last_error(void) {
  return last_error.c_str();
}
