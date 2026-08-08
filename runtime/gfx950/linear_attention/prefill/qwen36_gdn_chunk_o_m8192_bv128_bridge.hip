// SPDX-License-Identifier: MIT
// gfx950 module loading and caller-stream dispatch only. Compute remains in
// the exact-shape raw AMDGCN code object.
#include "qwen36_gdn_chunk_o_m8192_bv128_bridge.h"

#include <mutex>
#include <string>

namespace {
constexpr uint32_t kGridX = 1;
constexpr uint32_t kGridY = 128;
constexpr uint32_t kGridZ = 32;
constexpr uint32_t kBlockX = 256;
constexpr uint32_t kDynamicLdsBytes = 32768;
constexpr int kTokens = 8192;

std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
std::string loaded_path;
std::string loaded_name;
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
  loaded_name.clear();
}

int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("Qwen GDN chunk-o M8192 requires gfx950; got ") +
                        properties.gcnArchName);
  return 0;
}
}  // namespace

extern "C" int netra_qwen36_gdn_chunk_o_m8192_load(
    const char* hsaco_path, const char* kernel_name) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0' ||
      kernel_name == nullptr || kernel_name[0] == '\0')
    return fail_message("hsaco path and kernel name must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path && loaded_name == kernel_name) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different GDN chunk-o M8192 module is already loaded");
  }
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(&function, module, kernel_name);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  loaded_name = kernel_name;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_chunk_o_m8192_launch(
    const void* q_bf16,
    const void* k_bf16,
    const void* v_new_bf16,
    const void* h_bf16,
    const void* g_f32,
    void* output_bf16,
    const void* cu_seqlens_i32,
    const void* chunk_indices_i32,
    float scale,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("chunk-o module is not loaded");
  if (q_bf16 == nullptr || k_bf16 == nullptr || v_new_bf16 == nullptr ||
      h_bf16 == nullptr || g_f32 == nullptr || output_bf16 == nullptr ||
      cu_seqlens_i32 == nullptr || chunk_indices_i32 == nullptr)
    return fail_message("chunk-o launch pointers must be nonnull");
  void* q = const_cast<void*>(q_bf16);
  void* k = const_cast<void*>(k_bf16);
  void* v = const_cast<void*>(v_new_bf16);
  void* h = const_cast<void*>(h_bf16);
  void* g = const_cast<void*>(g_f32);
  void* cu = const_cast<void*>(cu_seqlens_i32);
  void* chunks = const_cast<void*>(chunk_indices_i32);
  int token_count = kTokens;
  void* global_scratch = nullptr;
  void* profile_scratch = nullptr;
  // The fixed-T code object does not consume cu/chunk metadata, but the strict
  // SGLang shape gate supplies both pointers so an ABI mismatch fails early.
  (void)cu;
  (void)chunks;
  void* fixed_arguments[] = {
      &q, &k, &v, &h, &g, &output_bf16, &scale, &token_count,
      &global_scratch, &profile_scratch};
  hipError_t error = hipModuleLaunchKernel(
      function, kGridX, kGridY, kGridZ, kBlockX, 1, 1, kDynamicLdsBytes,
      stream, fixed_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_chunk_o_m8192_unload() {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_module();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_chunk_o_m8192_last_error() {
  return last_error.c_str();
}
