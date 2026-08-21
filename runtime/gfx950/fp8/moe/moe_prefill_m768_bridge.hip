// SPDX-License-Identifier: MIT
// Allocation-free adapter for the exact M768 split-K2 producer/reducer pair.
#include "moe_prefill_m768_bridge.h"

#include <array>
#include <cstdint>
#include <mutex>
#include <string>

namespace {
constexpr int kRows = 768;
constexpr int kTopk = 9;
constexpr int kHidden = 2048;
constexpr int kSortedBlockCapacity = 365;
constexpr const char* kProducerSymbol =
    "qwen36_moe_fused_m64n256_partial_fp8_gfx950";
constexpr const char* kReducerSymbol =
    "qwen36_moe_route_reduce_f16_2h_x2_gfx950";

std::mutex module_mutex;
hipModule_t producer_module = nullptr;
hipModule_t reducer_module = nullptr;
hipFunction_t producer_function = nullptr;
hipFunction_t reducer_function = nullptr;
std::array<std::string, 2> loaded_paths{};
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const char* message) {
  last_error = message;
  return -1;
}

void clear_modules() {
  if (reducer_module != nullptr) (void)hipModuleUnload(reducer_module);
  if (producer_module != nullptr) (void)hipModuleUnload(producer_module);
  reducer_module = nullptr;
  producer_module = nullptr;
  reducer_function = nullptr;
  producer_function = nullptr;
  loaded_paths.fill(std::string{});
}
}  // namespace

extern "C" int netra_moe_prefill_m768_load(
    const char* producer_hsaco, const char* reducer_hsaco) {
  if (producer_hsaco == nullptr || producer_hsaco[0] == '\0' ||
      reducer_hsaco == nullptr || reducer_hsaco[0] == '\0')
    return fail_message("both code-object paths must be nonempty");

  const std::array<const char*, 2> paths = {producer_hsaco, reducer_hsaco};
  std::lock_guard<std::mutex> guard(module_mutex);
  if (producer_module != nullptr) {
    for (size_t index = 0; index < paths.size(); ++index)
      if (loaded_paths[index] != paths[index])
        return fail_message("different M768 code objects are already loaded");
    last_error.clear();
    return 0;
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0)
    return fail_message("M768 code objects require gfx950");

  error = hipModuleLoad(&producer_module, producer_hsaco);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(producer)", error);
  }
  error = hipModuleGetFunction(
      &producer_function, producer_module, kProducerSymbol);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(producer)", error);
  }
  error = hipModuleLoad(&reducer_module, reducer_hsaco);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleLoad(reducer)", error);
  }
  error = hipModuleGetFunction(
      &reducer_function, reducer_module, kReducerSymbol);
  if (error != hipSuccess) {
    clear_modules();
    return fail("hipModuleGetFunction(reducer)", error);
  }
  for (size_t index = 0; index < paths.size(); ++index)
    loaded_paths[index] = paths[index];
  last_error.clear();
  return 0;
}

extern "C" int netra_moe_prefill_m768_launch(
    const void* hidden_fp8, const float* hidden_scale_f32,
    const void* w13_fp8, const float* w13_scale_f32,
    const void* w2_fp8, const float* w2_scale_f32,
    const int32_t* sorted_token_ids_i32, const float* sorted_weights_f32,
    const int32_t* sorted_expert_ids_i32, const int32_t* num_valid_ids_i32,
    const float* topk_weights_f32, float* route_scale_workspace_f32,
    void* partials_f16, void* output_bf16, hipStream_t stream) {
  if (producer_function == nullptr || reducer_function == nullptr)
    return fail_message("M768 modules are not loaded");
  const std::array<const void*, 14> pointers = {
      hidden_fp8, hidden_scale_f32, w13_fp8, w13_scale_f32, w2_fp8,
      w2_scale_f32, sorted_token_ids_i32, sorted_weights_f32,
      sorted_expert_ids_i32, num_valid_ids_i32, topk_weights_f32,
      route_scale_workspace_f32, partials_f16, output_bf16};
  for (const void* pointer : pointers)
    if (pointer == nullptr) return fail_message("launch pointers must be nonnull");

  void* hidden = const_cast<void*>(hidden_fp8);
  void* hidden_scale = const_cast<float*>(hidden_scale_f32);
  void* w13 = const_cast<void*>(w13_fp8);
  void* w13_scale = const_cast<float*>(w13_scale_f32);
  void* w2 = const_cast<void*>(w2_fp8);
  void* w2_scale = const_cast<float*>(w2_scale_f32);
  void* sorted_ids = const_cast<int32_t*>(sorted_token_ids_i32);
  void* sorted_weights = const_cast<float*>(sorted_weights_f32);
  void* expert_ids = const_cast<int32_t*>(sorted_expert_ids_i32);
  void* num_valid = const_cast<int32_t*>(num_valid_ids_i32);
  void* topk_weights = const_cast<float*>(topk_weights_f32);
  int rows = kRows;
  int workspace_stride_blocks = kSortedBlockCapacity;

  void* producer_args[] = {
      &hidden, &hidden_scale, &w13, &w13_scale, &w2, &w2_scale,
      &sorted_ids, &sorted_weights, &expert_ids, &num_valid, &partials_f16,
      &rows, &route_scale_workspace_f32, &workspace_stride_blocks};
  hipError_t error = hipModuleLaunchKernel(
      producer_function, 2, kSortedBlockCapacity, 1, 256, 1, 1, 0, stream,
      producer_args, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(producer)", error);

  constexpr size_t kHalfElements =
      static_cast<size_t>(kRows * kTopk + kSortedBlockCapacity) * kHidden;
  void* partial1 = static_cast<char*>(partials_f16) +
                   kHalfElements * sizeof(uint16_t);
  void* reducer_args[] = {
      &partials_f16, &topk_weights, &output_bf16, &partial1};
  error = hipModuleLaunchKernel(
      reducer_function, 16, kRows, 1, 64, 1, 1, 0, stream,
      reducer_args, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(reducer)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_moe_prefill_m768_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_modules();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_moe_prefill_m768_last_error(void) {
  return last_error.c_str();
}
