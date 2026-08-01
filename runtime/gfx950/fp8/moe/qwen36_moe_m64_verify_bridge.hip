// SPDX-License-Identifier: MIT
// HIP is restricted to gfx950 module loading, stable workspace ownership,
// and caller-stream dispatch. All four compute stages are raw AMDGCN.
#include "qwen36_moe_m64_verify_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr int kTopk = 9;
constexpr int kHidden = 2048;
constexpr unsigned int kGateUpGridX = 8;
constexpr unsigned int kDownGridX = 16;
constexpr unsigned int kReduceGridX = 32;
constexpr unsigned int kComputeThreads = 256;
constexpr unsigned int kReduceThreads = 64;
constexpr const char* kGateUpKernelName =
    "qwen36_moe_gateup_silu_m64n64_fp8_gfx950";
constexpr const char* kDownKernelName =
    "qwen36_moe_down_m64n128_partial_masked_fp8_gfx950";
constexpr const char* kReduceKernelName =
    "qwen36_moe_route_reduce_f32_gfx950";

std::mutex module_mutex;
hipModule_t gate_up_module = nullptr;
hipModule_t down_module = nullptr;
hipModule_t reduce_module = nullptr;
hipFunction_t gate_up_function = nullptr;
hipFunction_t down_function = nullptr;
hipFunction_t reduce_function = nullptr;
float* partial_workspace = nullptr;
size_t workspace_size = 0;
int workspace_rows = 0;
std::string loaded_gate_up_path;
std::string loaded_down_path;
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
        std::string("raw M64 verification requires gfx950; got ") +
        properties.gcnArchName);
  }
  return 0;
}

void unload_modules() {
  if (reduce_module != nullptr) (void)hipModuleUnload(reduce_module);
  if (down_module != nullptr) (void)hipModuleUnload(down_module);
  if (gate_up_module != nullptr) (void)hipModuleUnload(gate_up_module);
  reduce_module = nullptr;
  down_module = nullptr;
  gate_up_module = nullptr;
  reduce_function = nullptr;
  down_function = nullptr;
  gate_up_function = nullptr;
}

void clear_state() {
  unload_modules();
  partial_workspace = nullptr;
  workspace_size = 0;
  workspace_rows = 0;
  loaded_gate_up_path.clear();
  loaded_down_path.clear();
  loaded_reduce_path.clear();
}

bool valid_path(const char* path) {
  return path != nullptr && path[0] != '\0';
}

}  // namespace

extern "C" int netra_qwen36_moe_m64_verify_load(
    const char* gate_up_hsaco_path,
    const char* down_hsaco_path,
    const char* reduce_hsaco_path,
    int max_rows) {
  if (!valid_path(gate_up_hsaco_path) || !valid_path(down_hsaco_path) ||
      !valid_path(reduce_hsaco_path)) {
    return fail_message("all three hsaco paths must be nonempty");
  }
  if (max_rows <= 64) return fail_message("max_rows must exceed 64");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (gate_up_module != nullptr || down_module != nullptr ||
      reduce_module != nullptr || partial_workspace != nullptr) {
    if (loaded_gate_up_path == gate_up_hsaco_path &&
        loaded_down_path == down_hsaco_path &&
        loaded_reduce_path == reduce_hsaco_path &&
        workspace_rows == max_rows) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different M64 verification module is loaded");
  }
  int status = require_gfx950();
  if (status != 0) return status;

  hipError_t error = hipModuleLoad(&gate_up_module, gate_up_hsaco_path);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleLoad(gate_up)", error);
  }
  error = hipModuleGetFunction(
      &gate_up_function, gate_up_module, kGateUpKernelName);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleGetFunction(gate_up)", error);
  }
  error = hipModuleLoad(&down_module, down_hsaco_path);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleLoad(down)", error);
  }
  error = hipModuleGetFunction(&down_function, down_module, kDownKernelName);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleGetFunction(down)", error);
  }
  error = hipModuleLoad(&reduce_module, reduce_hsaco_path);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleLoad(reduce)", error);
  }
  error = hipModuleGetFunction(
      &reduce_function, reduce_module, kReduceKernelName);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipModuleGetFunction(reduce)", error);
  }

  workspace_size = static_cast<size_t>(max_rows) * kTopk * kHidden *
                   sizeof(float);
  error = hipMalloc(
      reinterpret_cast<void**>(&partial_workspace), workspace_size);
  if (error != hipSuccess) {
    clear_state();
    return fail("hipMalloc(partial_workspace)", error);
  }
  workspace_rows = max_rows;
  loaded_gate_up_path = gate_up_hsaco_path;
  loaded_down_path = down_hsaco_path;
  loaded_reduce_path = reduce_hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_m64_verify_launch_gate_up(
    const void* hidden_fp8,
    const float* hidden_scale_f32,
    const void* w13_fp8,
    const float* w13_scale_f32,
    const int32_t* sorted_token_ids_i32,
    const int32_t* sorted_expert_ids_i32,
    const int32_t* num_valid_ids_i32,
    void* activation_bf16,
    int rows,
    int sorted_blocks,
    hipStream_t stream) {
  if (gate_up_function == nullptr)
    return fail_message("raw M64 modules are not loaded");
  if (hidden_fp8 == nullptr || hidden_scale_f32 == nullptr ||
      w13_fp8 == nullptr || w13_scale_f32 == nullptr ||
      sorted_token_ids_i32 == nullptr || sorted_expert_ids_i32 == nullptr ||
      num_valid_ids_i32 == nullptr || activation_bf16 == nullptr) {
    return fail_message("gate/up launch pointers must be nonnull");
  }
  if (rows <= 64 || rows > workspace_rows || sorted_blocks <= 0)
    return fail_message("gate/up launch shape is out of range");
  void* arguments[] = {
      &hidden_fp8,
      &hidden_scale_f32,
      &w13_fp8,
      &w13_scale_f32,
      &sorted_token_ids_i32,
      &sorted_expert_ids_i32,
      &num_valid_ids_i32,
      &activation_bf16,
      &rows,
  };
  hipError_t error = hipModuleLaunchKernel(
      gate_up_function,
      kGateUpGridX,
      static_cast<unsigned int>(sorted_blocks),
      1,
      kComputeThreads,
      1,
      1,
      0,
      stream,
      arguments,
      nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(gate_up)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_m64_verify_launch_down(
    const void* activation_fp8,
    const float* activation_scale_f32,
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
  if (down_function == nullptr || reduce_function == nullptr ||
      partial_workspace == nullptr)
    return fail_message("raw M64 modules and workspace are not loaded");
  if (activation_fp8 == nullptr || activation_scale_f32 == nullptr ||
      w2_fp8 == nullptr || w2_scale_f32 == nullptr ||
      sorted_token_ids_i32 == nullptr || sorted_expert_ids_i32 == nullptr ||
      num_valid_ids_i32 == nullptr || topk_weights_f32 == nullptr ||
      output_bf16 == nullptr) {
    return fail_message("down launch pointers must be nonnull");
  }
  if (rows <= 64 || rows > workspace_rows || sorted_blocks <= 0)
    return fail_message("down launch shape is out of range");

  void* down_arguments[] = {
      &activation_fp8,
      &activation_scale_f32,
      &w2_fp8,
      &w2_scale_f32,
      &sorted_token_ids_i32,
      &topk_weights_f32,
      &sorted_expert_ids_i32,
      &num_valid_ids_i32,
      &partial_workspace,
      &rows,
  };
  hipError_t error = hipModuleLaunchKernel(
      down_function,
      kDownGridX,
      static_cast<unsigned int>(sorted_blocks),
      1,
      kComputeThreads,
      1,
      1,
      0,
      stream,
      down_arguments,
      nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(down)", error);

  void* reduce_arguments[] = {
      &partial_workspace, &topk_weights_f32, &output_bf16,
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
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(reduce)", error);
  last_error.clear();
  return 0;
}

extern "C" size_t netra_qwen36_moe_m64_verify_workspace_bytes(void) {
  return workspace_size;
}

extern "C" int netra_qwen36_moe_m64_verify_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  hipError_t first_error = hipSuccess;
  if (partial_workspace != nullptr) first_error = hipFree(partial_workspace);
  partial_workspace = nullptr;
  unload_modules();
  workspace_size = 0;
  workspace_rows = 0;
  loaded_gate_up_path.clear();
  loaded_down_path.clear();
  loaded_reduce_path.clear();
  if (first_error != hipSuccess) return fail("M64 verify unload", first_error);
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_moe_m64_verify_last_error(void) {
  return last_error.c_str();
}
