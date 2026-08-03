// SPDX-License-Identifier: MIT
//
// gfx950 module loading and caller-stream dispatch only.  Compute remains in
// the raw AMDGCN module selected by qwen36_gdn_h_m8192_bv16_load().
#include "qwen36_gdn_h_m8192_bv16_bridge.h"

#include <hip/hip_runtime.h>

#include <array>
#include <mutex>
#include <string>

namespace {

constexpr uint32_t kGridX = 8;
constexpr uint32_t kGridY = 32;
constexpr uint32_t kBlockX = 256;
constexpr uint32_t kDynamicLdsBytes = 103296;
constexpr uint32_t kTokens = 8192;

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
    return fail_message(std::string("Qwen GDN M8192 requires gfx950; got ") +
                        properties.gcnArchName);
  return 0;
}

}  // namespace

extern "C" int netra_qwen36_gdn_h_m8192_bv16_load(
    const char* hsaco_path,
    const char* kernel_name) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0' ||
      kernel_name == nullptr || kernel_name[0] == '\0')
    return fail_message("hsaco path and kernel name must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path && loaded_name == kernel_name) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different GDN M8192 module is already loaded");
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

extern "C" int netra_qwen36_gdn_h_m8192_bv16_launch(
    const void* k_bf16,
    const void* v_bf16,
    const void* w_bf16,
    void* v_new_bf16,
    const void* g_f32,
    void* h_bf16,
    void* state_bf16,
    const void* initial_state_indices_i32,
    const void* cu_seqlens_i32,
    const void* chunk_offsets_i64,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("GDN M8192 module is not loaded");
  const std::array<const void*, 10> pointers = {
      k_bf16, v_bf16, w_bf16, v_new_bf16, g_f32, h_bf16, state_bf16,
      initial_state_indices_i32, cu_seqlens_i32, chunk_offsets_i64};
  for (const void* pointer : pointers) {
    if (pointer == nullptr)
      return fail_message("GDN M8192 launch pointers must be nonnull");
  }

  void* k_pointer = const_cast<void*>(k_bf16);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* w_pointer = const_cast<void*>(w_bf16);
  void* g_pointer = const_cast<void*>(g_f32);
  void* initial_indices_pointer =
      const_cast<void*>(initial_state_indices_i32);
  void* cu_pointer = const_cast<void*>(cu_seqlens_i32);
  void* chunk_offsets_pointer = const_cast<void*>(chunk_offsets_i64);
  uint32_t tokens = kTokens;
  // Triton's gfx950 ABI appends global/profile scratch pointers.  The captured
  // object reports zero scratch for both, so stable null values are sufficient.
  void* global_scratch = nullptr;
  void* profile_scratch = nullptr;
  void* arguments[] = {
      &k_pointer,
      &v_pointer,
      &w_pointer,
      &v_new_bf16,
      &g_pointer,
      &h_bf16,
      &state_bf16,
      &initial_indices_pointer,
      &cu_pointer,
      &chunk_offsets_pointer,
      &tokens,
      &global_scratch,
      &profile_scratch,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, kGridX, kGridY, 1, kBlockX, 1, 1, kDynamicLdsBytes, stream,
      arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_h_m8192_bv16_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_module();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_h_m8192_bv16_last_error(void) {
  return last_error.c_str();
}
