// SPDX-License-Identifier: MIT
// HIP is restricted to gfx950 module management, stable workspace ownership,
// and dispatch.  Both compute stages are raw AMDGCN assembly.
#include "qwen36_moe_grouped_verify_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr int kTopk = 9;
constexpr int kHidden = 2048;
constexpr int kBlockM = 16;
constexpr unsigned int kGroupedGridX = 32;
constexpr unsigned int kReduceGridX = 32;
constexpr unsigned int kGroupedThreads = 256;
constexpr unsigned int kReduceThreads = 64;
constexpr const char* kGroupedKernelName =
    "qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950";
constexpr const char* kReduceKernelName =
    "qwen36_moe_route_reduce_f32_gfx950";

std::mutex module_mutex;
hipModule_t grouped_module = nullptr;
hipModule_t reduce_module = nullptr;
hipFunction_t grouped_function = nullptr;
hipFunction_t reduce_function = nullptr;
float* workspace = nullptr;
size_t workspace_size = 0;
int workspace_rows = 0;
std::string loaded_grouped_path;
std::string loaded_reduce_path;
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

int require_gfx950() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos) {
    return fail_message(
        std::string("raw grouped verification requires gfx950; got ") +
        properties.gcnArchName);
  }
  return 0;
}

void clear_state() {
  grouped_module = nullptr;
  reduce_module = nullptr;
  grouped_function = nullptr;
  reduce_function = nullptr;
  workspace = nullptr;
  workspace_size = 0;
  workspace_rows = 0;
  loaded_grouped_path.clear();
  loaded_reduce_path.clear();
}

}  // namespace

extern "C" int netra_qwen36_moe_grouped_verify_load(
    const char* grouped_hsaco_path,
    const char* reduce_hsaco_path,
    int max_rows) {
  if (grouped_hsaco_path == nullptr || grouped_hsaco_path[0] == '\0' ||
      reduce_hsaco_path == nullptr || reduce_hsaco_path[0] == '\0') {
    return fail_message("both hsaco paths must be nonempty");
  }
  if (max_rows <= 0) return fail_message("max_rows must be positive");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (grouped_module != nullptr || reduce_module != nullptr ||
      workspace != nullptr) {
    if (loaded_grouped_path == grouped_hsaco_path &&
        loaded_reduce_path == reduce_hsaco_path &&
        workspace_rows == max_rows) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different grouped-verification module is loaded");
  }
  int status = require_gfx950();
  if (status != 0) return status;
  hipError_t error = hipModuleLoad(&grouped_module, grouped_hsaco_path);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleLoad(grouped)", error);
  }
  error = hipModuleGetFunction(
      &grouped_function, grouped_module, kGroupedKernelName);
  if (error != hipSuccess) {
    (void)hipModuleUnload(grouped_module);
    clear_state();
    return fail("hipModuleGetFunction(grouped)", error);
  }
  error = hipModuleLoad(&reduce_module, reduce_hsaco_path);
  if (error != hipSuccess) {
    (void)hipModuleUnload(grouped_module);
    clear_state();
    return fail("hipModuleLoad(reduce)", error);
  }
  error = hipModuleGetFunction(
      &reduce_function, reduce_module, kReduceKernelName);
  if (error != hipSuccess) {
    (void)hipModuleUnload(reduce_module);
    (void)hipModuleUnload(grouped_module);
    clear_state();
    return fail("hipModuleGetFunction(reduce)", error);
  }
  workspace_size = static_cast<size_t>(max_rows) * kTopk * kHidden *
                   sizeof(float);
  error = hipMalloc(reinterpret_cast<void**>(&workspace), workspace_size);
  if (error != hipSuccess) {
    (void)hipModuleUnload(reduce_module);
    (void)hipModuleUnload(grouped_module);
    clear_state();
    return fail("hipMalloc(workspace)", error);
  }
  workspace_rows = max_rows;
  loaded_grouped_path = grouped_hsaco_path;
  loaded_reduce_path = reduce_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_grouped_verify_launch(
    const void* inter_fp8,
    const float* inter_scale_f32,
    const void* w2_fp8,
    const float* w2_scale_f32,
    const int32_t* sorted_token_ids_i32,
    const int32_t* sorted_expert_ids_i32,
    const int32_t* num_valid_ids_i32,
    const float* topk_weights_f32,
    void* output_bf16,
    int rows,
    int sorted_blocks,
    hipStream_t stream) {
  if (grouped_function == nullptr || reduce_function == nullptr ||
      workspace == nullptr) {
    return fail_message("raw modules and workspace are not loaded");
  }
  if (inter_fp8 == nullptr || inter_scale_f32 == nullptr ||
      w2_fp8 == nullptr || w2_scale_f32 == nullptr ||
      sorted_token_ids_i32 == nullptr || sorted_expert_ids_i32 == nullptr ||
      num_valid_ids_i32 == nullptr || topk_weights_f32 == nullptr ||
      output_bf16 == nullptr) {
    return fail_message("launch pointers must be nonnull");
  }
  if (rows <= 0 || rows > workspace_rows) {
    return fail_message("rows exceed the preallocated workspace");
  }
  if (sorted_blocks <= 0) return fail_message("sorted_blocks must be positive");

  void* grouped_arguments[] = {
      &inter_fp8,
      &inter_scale_f32,
      &w2_fp8,
      &w2_scale_f32,
      &sorted_token_ids_i32,
      &sorted_expert_ids_i32,
      &num_valid_ids_i32,
      &workspace,
      &rows,
  };
  hipError_t error = hipModuleLaunchKernel(
      grouped_function,
      kGroupedGridX,
      static_cast<unsigned int>(sorted_blocks),
      1,
      kGroupedThreads,
      1,
      1,
      0,
      stream,
      grouped_arguments,
      nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(grouped)", error);

  void* reduce_arguments[] = {
      &workspace, &topk_weights_f32, &output_bf16,
  };
  error = hipModuleLaunchKernel(
      reduce_function,
      kReduceGridX,
      static_cast<unsigned int>(rows),
      1,
      kReduceThreads,
      1,
      1,
      0,
      stream,
      reduce_arguments,
      nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(reduce)", error);
  last_error.clear();
  return 0;
}

extern "C" size_t netra_qwen36_moe_grouped_verify_workspace_bytes(void) {
  return workspace_size;
}

extern "C" int netra_qwen36_moe_grouped_verify_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  hipError_t first_error = hipSuccess;
  if (workspace != nullptr) first_error = hipFree(workspace);
  if (reduce_module != nullptr) {
    hipError_t error = hipModuleUnload(reduce_module);
    if (first_error == hipSuccess) first_error = error;
  }
  if (grouped_module != nullptr) {
    hipError_t error = hipModuleUnload(grouped_module);
    if (first_error == hipSuccess) first_error = error;
  }
  clear_state();
  if (first_error != hipSuccess) return fail("grouped verify unload", first_error);
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_moe_grouped_verify_last_error(void) {
  return last_error.c_str();
}
