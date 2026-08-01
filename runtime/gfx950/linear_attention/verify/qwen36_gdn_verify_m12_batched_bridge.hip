// SPDX-License-Identifier: MIT
//
// Module loading and caller-stream dispatch only. Both compute stages are raw
// gfx950 AMDGCN under kernels/gfx950/linear_attention/verify/.
#include "qwen36_gdn_verify_m12_batched_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <array>
#include <mutex>
#include <string>

namespace {

std::mutex module_mutex;
hipModule_t precompute_module = nullptr;
hipModule_t core_module = nullptr;
hipFunction_t precompute_function = nullptr;
hipFunction_t core_function = nullptr;
std::string loaded_precompute_path;
std::string loaded_core_path;
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

void clear_modules() {
  if (core_module != nullptr) (void)hipModuleUnload(core_module);
  if (precompute_module != nullptr) (void)hipModuleUnload(precompute_module);
  precompute_module = nullptr;
  core_module = nullptr;
  precompute_function = nullptr;
  core_function = nullptr;
  loaded_precompute_path.clear();
  loaded_core_path.clear();
}

}  // namespace

extern "C" int netra_qwen36_gdn_verify_m12_batched_load(
    const char* precompute_hsaco_path,
    const char* core_hsaco_path) {
  if (precompute_hsaco_path == nullptr ||
      precompute_hsaco_path[0] == '\0' ||
      core_hsaco_path == nullptr || core_hsaco_path[0] == '\0')
    return fail_message("both hsaco paths must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (precompute_module != nullptr || core_module != nullptr) {
    if (loaded_precompute_path == precompute_hsaco_path &&
        loaded_core_path == core_hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("different GDN verify modules are already loaded");
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
        std::string("Qwen GDN verify modules require gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&precompute_module, precompute_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(precompute)", error);
  }
  error = hipModuleGetFunction(
      &precompute_function, precompute_module,
      "qwen36_gdn_verify_m12_batched_precompute_gfx950");
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(precompute)", error);
  }
  error = hipModuleLoad(&core_module, core_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(core)", error);
  }
  error = hipModuleGetFunction(
      &core_function, core_module,
      "qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950");
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(core)", error);
  }
  loaded_precompute_path = precompute_hsaco_path;
  loaded_core_path = core_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_launch(
    void* output_bf16,
    const void* A_log_f32,
    const void* a_bf16,
    const void* dt_bias_bf16,
    const void* q_bf16,
    const void* k_bf16,
    const void* v_bf16,
    const void* b_bf16,
    const void* initial_state_bf16,
    const void* initial_state_indices_i32,
    void* intermediate_state_bf16,
    const void* intermediate_state_indices_i32,
    void* q_normalized_f32,
    void* k_normalized_f32,
    void* decay_f32,
    void* beta_f32,
    uint32_t stride_q,
    uint32_t stride_k,
    uint32_t stride_v,
    uint32_t stride_a,
    uint32_t stride_b,
    uint32_t batch_size,
    hipStream_t stream) {
  if (precompute_function == nullptr || core_function == nullptr)
    return fail_message("GDN verify modules are not loaded");
  const std::array<const void*, 16> pointers = {
      output_bf16,
      A_log_f32,
      a_bf16,
      dt_bias_bf16,
      q_bf16,
      k_bf16,
      v_bf16,
      b_bf16,
      initial_state_bf16,
      initial_state_indices_i32,
      intermediate_state_bf16,
      intermediate_state_indices_i32,
      q_normalized_f32,
      k_normalized_f32,
      decay_f32,
      beta_f32,
  };
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("GDN verify launch pointers must be nonnull");
  if (stride_q < 2048 || stride_k < 2048 || stride_v < 4096 ||
      stride_a < 32 || stride_b < 32)
    return fail_message("GDN verify tensor stride is smaller than its row");
  if (batch_size == 0 || batch_size > 64)
    return fail_message("GDN M=12 verify batch size must be in [1,64]");

  void* A_log_pointer = const_cast<void*>(A_log_f32);
  void* a_pointer = const_cast<void*>(a_bf16);
  void* dt_bias_pointer = const_cast<void*>(dt_bias_bf16);
  void* q_pointer = const_cast<void*>(q_bf16);
  void* k_pointer = const_cast<void*>(k_bf16);
  void* v_pointer = const_cast<void*>(v_bf16);
  void* b_pointer = const_cast<void*>(b_bf16);
  void* initial_pointer = const_cast<void*>(initial_state_bf16);
  void* initial_indices_pointer =
      const_cast<void*>(initial_state_indices_i32);
  void* intermediate_indices_pointer =
      const_cast<void*>(intermediate_state_indices_i32);

  void* precompute_arguments[] = {
      &A_log_pointer,
      &a_pointer,
      &dt_bias_pointer,
      &q_pointer,
      &k_pointer,
      &b_pointer,
      &q_normalized_f32,
      &k_normalized_f32,
      &decay_f32,
      &beta_f32,
      &stride_q,
      &stride_k,
      &stride_a,
      &stride_b,
  };
  hipError_t error = hipModuleLaunchKernel(
      precompute_function, batch_size * 192, 1, 1, 64, 1, 1, 0, stream,
      precompute_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(precompute)", error);

  void* core_arguments[] = {
      &q_normalized_f32,
      &k_normalized_f32,
      &v_pointer,
      &decay_f32,
      &beta_f32,
      &output_bf16,
      &initial_pointer,
      &intermediate_state_bf16,
      &initial_indices_pointer,
      &intermediate_indices_pointer,
      &stride_v,
  };
  error = hipModuleLaunchKernel(
      core_function, batch_size * 256, 1, 1, 64, 1, 1, 0, stream,
      core_arguments,
      nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(core)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_verify_m12_batched_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (precompute_module == nullptr && core_module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t first_error = hipSuccess;
  if (core_module != nullptr) first_error = hipModuleUnload(core_module);
  if (precompute_module != nullptr) {
    const hipError_t error = hipModuleUnload(precompute_module);
    if (first_error == hipSuccess) first_error = error;
  }
  precompute_module = nullptr;
  core_module = nullptr;
  precompute_function = nullptr;
  core_function = nullptr;
  loaded_precompute_path.clear();
  loaded_core_path.clear();
  if (first_error != hipSuccess) return fail("hipModuleUnload", first_error);
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_verify_m12_batched_last_error(void) {
  return last_error.c_str();
}
