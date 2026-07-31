// SPDX-License-Identifier: MIT
//
// Module loading, caller-stream dispatch, and graph-safe stable-pointer
// launching only.  Both compute stages are raw gfx950 AMDGCN under
// kernels/gfx950/attention/verify/.
#include "qwen36_full_attention_verify_m16_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <mutex>
#include <string>

namespace {

constexpr unsigned kVerifyTokens = 16;
constexpr unsigned kQueryHeadGroups = 2;
constexpr unsigned kQueryHeads = 16;
constexpr unsigned kMaxKvSplits = 129;
constexpr unsigned kThreads = 256;
constexpr unsigned kStage1DynamicLdsBytes = 8192;

std::mutex module_mutex;
hipModule_t stage1_module = nullptr;
hipModule_t stage2_module = nullptr;
hipFunction_t stage1_function = nullptr;
hipFunction_t stage2_function = nullptr;
std::string loaded_stage1_path;
std::string loaded_stage2_path;
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
  if (stage2_module != nullptr) (void)hipModuleUnload(stage2_module);
  if (stage1_module != nullptr) (void)hipModuleUnload(stage1_module);
  stage1_module = nullptr;
  stage2_module = nullptr;
  stage1_function = nullptr;
  stage2_function = nullptr;
  loaded_stage1_path.clear();
  loaded_stage2_path.clear();
}

}  // namespace

extern "C" int netra_qwen36_full_attention_verify_m16_load(
    const char* stage1_hsaco_path,
    const char* stage2_hsaco_path) {
  if (stage1_hsaco_path == nullptr || stage1_hsaco_path[0] == '\0' ||
      stage2_hsaco_path == nullptr || stage2_hsaco_path[0] == '\0')
    return fail_message("both attention HSACO paths must be nonempty");

  std::lock_guard<std::mutex> guard(module_mutex);
  if (stage1_module != nullptr || stage2_module != nullptr) {
    if (loaded_stage1_path == stage1_hsaco_path &&
        loaded_stage2_path == stage2_hsaco_path) {
      last_error.clear();
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
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos)
    return fail_message(
        std::string("Qwen full-attention verify modules require gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&stage1_module, stage1_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(stage1)", error);
  }
  error = hipModuleGetFunction(
      &stage1_function, stage1_module,
      "qwen36_full_attention_verify_m16_stage1_gfx950");
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(stage1)", error);
  }

  error = hipModuleLoad(&stage2_module, stage2_hsaco_path);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(stage2)", error);
  }
  error = hipModuleGetFunction(
      &stage2_function, stage2_module,
      "qwen36_full_attention_verify_m16_stage2_gfx950");
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(stage2)", error);
  }

  loaded_stage1_path = stage1_hsaco_path;
  loaded_stage2_path = stage2_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_full_attention_verify_m16_launch(
    void* output_bf16,
    const void* query_bf16,
    const void* key_cache_fp8_e4m3,
    const void* value_cache_fp8_e4m3,
    const void* sequence_lengths_i32,
    const void* kv_indices_i64,
    const void* num_kv_splits_i32,
    void* intermediate_output_f32,
    void* intermediate_lse_f32,
    float softmax_scale_times_k_scale,
    float value_scale,
    uint32_t stride_q_batch,
    uint32_t stride_q_head,
    uint32_t stride_kv_batch,
    uint32_t stride_k_head,
    uint32_t stride_v_batch,
    uint32_t stride_v_head,
    uint32_t stride_mid_batch,
    uint32_t stride_mid_head,
    uint32_t stride_mid_split,
    uint32_t stride_output_batch,
    uint32_t stride_output_head,
    hipStream_t stream) {
  if (stage1_function == nullptr || stage2_function == nullptr)
    return fail_message("attention verify modules are not loaded");

  const std::array<const void*, 9> pointers = {
      output_bf16,
      query_bf16,
      key_cache_fp8_e4m3,
      value_cache_fp8_e4m3,
      sequence_lengths_i32,
      kv_indices_i64,
      num_kv_splits_i32,
      intermediate_output_f32,
      intermediate_lse_f32,
  };
  if (std::any_of(pointers.begin(), pointers.end(),
                  [](const void* pointer) { return pointer == nullptr; }))
    return fail_message("attention verify launch pointers must be nonnull");

  if (stride_q_batch < kQueryHeads * 256 || stride_q_head < 256 ||
      stride_kv_batch < 2 * 256 || stride_k_head < 256 ||
      stride_v_batch < 2 * 256 || stride_v_head < 256 ||
      stride_mid_batch < kQueryHeads * kMaxKvSplits * 256 ||
      stride_mid_head < kMaxKvSplits * 256 ||
      stride_mid_split < 256 ||
      stride_output_batch < kQueryHeads * 256 ||
      stride_output_head < 256)
    return fail_message("attention verify tensor stride is smaller than its row");

  void* query_pointer = const_cast<void*>(query_bf16);
  void* key_pointer = const_cast<void*>(key_cache_fp8_e4m3);
  void* value_pointer = const_cast<void*>(value_cache_fp8_e4m3);
  void* lengths_pointer = const_cast<void*>(sequence_lengths_i32);
  void* indices_pointer = const_cast<void*>(kv_indices_i64);
  void* splits_pointer = const_cast<void*>(num_kv_splits_i32);
  void* hidden_scratch = nullptr;
  void* hidden_profile = nullptr;

  void* stage1_arguments[] = {
      &query_pointer,
      &key_pointer,
      &value_pointer,
      &softmax_scale_times_k_scale,
      &lengths_pointer,
      &indices_pointer,
      &intermediate_output_f32,
      &intermediate_lse_f32,
      &splits_pointer,
      &stride_q_batch,
      &stride_q_head,
      &stride_kv_batch,
      &stride_k_head,
      &stride_v_batch,
      &stride_v_head,
      &stride_mid_batch,
      &stride_mid_head,
      &stride_mid_split,
      &hidden_scratch,
      &hidden_profile,
  };
  hipError_t error = hipModuleLaunchKernel(
      stage1_function, kVerifyTokens, kQueryHeadGroups, kMaxKvSplits,
      kThreads, 1, 1, kStage1DynamicLdsBytes, stream, stage1_arguments,
      nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(stage1)", error);

  void* stage2_arguments[] = {
      &intermediate_output_f32,
      &intermediate_lse_f32,
      &output_bf16,
      &value_scale,
      &lengths_pointer,
      &splits_pointer,
      &stride_mid_batch,
      &stride_mid_head,
      &stride_mid_split,
      &stride_output_batch,
      &stride_output_head,
      &hidden_scratch,
      &hidden_profile,
  };
  error = hipModuleLaunchKernel(
      stage2_function, kVerifyTokens, kQueryHeads, 1, kThreads, 1, 1, 0,
      stream, stage2_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(stage2)", error);

  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_full_attention_verify_m16_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (stage1_module == nullptr && stage2_module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t first_error = hipSuccess;
  if (stage2_module != nullptr) first_error = hipModuleUnload(stage2_module);
  if (stage1_module != nullptr) {
    const hipError_t error = hipModuleUnload(stage1_module);
    if (first_error == hipSuccess) first_error = error;
  }
  stage1_module = nullptr;
  stage2_module = nullptr;
  stage1_function = nullptr;
  stage2_function = nullptr;
  loaded_stage1_path.clear();
  loaded_stage2_path.clear();
  if (first_error != hipSuccess) return fail("hipModuleUnload", first_error);
  last_error.clear();
  return 0;
}

extern "C" const char*
netra_qwen36_full_attention_verify_m16_last_error(void) {
  return last_error.c_str();
}
