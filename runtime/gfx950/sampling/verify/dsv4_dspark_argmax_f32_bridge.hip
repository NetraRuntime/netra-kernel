// SPDX-License-Identifier: MIT
//
// Module management and caller-stream dispatch only. Both compute stages are
// raw gfx950 AMDGCN under kernels/gfx950/sampling/verify/.
#include "dsv4_dspark_argmax_f32_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr uint32_t kChunks = 16;
constexpr uint32_t kValidWidth = 129280;
constexpr uint32_t kPaddedWidth = 131072;
std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t stage1 = nullptr;
hipFunction_t stage1_two_input = nullptr;
hipFunction_t stage2 = nullptr;
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

extern "C" int netra_dsv4_dspark_argmax_f32_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different argmax code object is already loaded");
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
        std::string("argmax code object requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &stage1, module, "dsv4_dspark_argmax_f32_stage1_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail("hipModuleGetFunction(stage1)", error);
  }
  error = hipModuleGetFunction(
      &stage2, module, "dsv4_dspark_argmax_f32_stage2_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    stage1 = nullptr;
    return fail("hipModuleGetFunction(stage2)", error);
  }
  error = hipModuleGetFunction(
      &stage1_two_input, module,
      "dsv4_dspark_argmax_bf16_base_bias_stage1_gfx950");
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    stage1 = nullptr;
    stage2 = nullptr;
    return fail("hipModuleGetFunction(stage1_two_input)", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_argmax_bf16_base_bias_launch_v1(
    int64_t* output_i64,
    uint32_t* partial_keys_u32,
    const void* base_bf16,
    const void* bias_bf16,
    uint32_t valid_width,
    uint32_t padded_width,
    uint32_t base_row_stride,
    uint32_t rows,
    hipStream_t stream) {
  if (stage1_two_input == nullptr || stage2 == nullptr)
    return fail_message("two-input argmax module is not loaded");
  if (output_i64 == nullptr || partial_keys_u32 == nullptr ||
      base_bf16 == nullptr || bias_bf16 == nullptr)
    return fail_message("two-input argmax launch pointers must be nonnull");
  if ((reinterpret_cast<uintptr_t>(output_i64) & 7u) != 0 ||
      (reinterpret_cast<uintptr_t>(partial_keys_u32) & 7u) != 0 ||
      (reinterpret_cast<uintptr_t>(base_bf16) & 7u) != 0 ||
      (reinterpret_cast<uintptr_t>(bias_bf16) & 7u) != 0)
    return fail_message("two-input argmax pointers must be 8-byte aligned");
  if (valid_width != kValidWidth ||
      (padded_width != kValidWidth && padded_width != kPaddedWidth))
    return fail_message(
        "two-input argmax requires valid_width=129280 and "
        "padded_width in {129280, 131072}");
  if (base_row_stride < padded_width)
    return fail_message(
        "two-input argmax base_row_stride must be at least padded_width");
  if ((base_row_stride & 3u) != 0)
    return fail_message(
        "two-input argmax base_row_stride must preserve 8-byte alignment");
  if (rows == 0 || rows > 4096)
    return fail_message("two-input argmax rows must be in [1, 4096]");
  if (static_cast<uint64_t>(rows - 1) * base_row_stride + kValidWidth >
      0xffffffffull)
    return fail_message("two-input argmax base row addressing overflows uint32");

  void* partial_pointer = partial_keys_u32;
  void* base_pointer = const_cast<void*>(base_bf16);
  void* bias_pointer = const_cast<void*>(bias_bf16);
  void* stage1_arguments[] = {
      &partial_pointer, &base_pointer, &bias_pointer, &base_row_stride};
  hipError_t error = hipModuleLaunchKernel(
      stage1_two_input, kChunks, rows, 1, 64, 1, 1, 0, stream,
      stage1_arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(stage1_two_input)", error);

  void* output_pointer = output_i64;
  void* stage2_arguments[] = {&output_pointer, &partial_pointer};
  error = hipModuleLaunchKernel(
      stage2, 1, rows, 1, 64, 1, 1, 0, stream, stage2_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(stage2)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_argmax_f32_launch(
    int64_t* output_i64,
    uint32_t* partial_keys_u32,
    const float* logits_f32,
    uint32_t rows,
    hipStream_t stream) {
  if (stage1 == nullptr || stage2 == nullptr)
    return fail_message("argmax module is not loaded");
  if (output_i64 == nullptr || partial_keys_u32 == nullptr ||
      logits_f32 == nullptr)
    return fail_message("argmax launch pointers must be nonnull");
  if (rows == 0 || rows > 4096)
    return fail_message("argmax rows must be in [1, 4096]");

  void* partial_pointer = partial_keys_u32;
  void* logits_pointer = const_cast<float*>(logits_f32);
  void* stage1_arguments[] = {&partial_pointer, &logits_pointer};
  hipError_t error = hipModuleLaunchKernel(
      stage1, kChunks, rows, 1, 64, 1, 1, 0, stream, stage1_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(stage1)", error);

  void* output_pointer = output_i64;
  void* stage2_arguments[] = {&output_pointer, &partial_pointer};
  error = hipModuleLaunchKernel(
      stage2, 1, rows, 1, 64, 1, 1, 0, stream, stage2_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel(stage2)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_dsv4_dspark_argmax_f32_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  module = nullptr;
  stage1 = nullptr;
  stage1_two_input = nullptr;
  stage2 = nullptr;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_dsv4_dspark_argmax_f32_last_error(void) {
  return last_error.c_str();
}
