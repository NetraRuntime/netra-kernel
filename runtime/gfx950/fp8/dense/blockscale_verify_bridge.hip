// SPDX-License-Identifier: MIT
// Fixed-contract bridge for gfx950 FP8 block-scale verification GEMMs.
#include "runtime/gfx950/fp8/dense/blockscale_verify_bridge.h"

#include <cstdio>
#include <cstring>
#include <mutex>
#include <string>

namespace {

constexpr uint32_t kM = 1536;
constexpr uint32_t kThreads = 512;
constexpr uint32_t kQuantBlock = 128;
constexpr const char* kSymbols[] = {
    "netra_dense_fp8_blockscale_bf16_m1536_n5120_k6144_gfx950",
    "netra_dense_fp8_blockscale_bf16_m1536_n5120_k17408_gfx950",
    "netra_dense_fp8_blockscale_bf16_m1536_n14336_k5120_gfx950",
    "netra_dense_fp8_blockscale_bf16_m1536_n16384_k5120_gfx950",
};
constexpr uint32_t kArtifactCount = 4;

struct alignas(8) KernelArgs {
  const void* activation;
  const void* weight;
  const void* activation_scale;
  const void* weight_scale;
  void* output;
  int32_t m;
  int32_t n;
  int32_t k;
  int32_t activation_quant_k;
  int32_t weight_quant_k;
  int32_t activation_stride;
  int32_t weight_stride;
  int32_t output_stride;
  int32_t activation_scale_stride;
  int32_t weight_scale_stride;
  int32_t split_k;
  int32_t padding;
};
static_assert(sizeof(KernelArgs) == 88, "frozen CKTile kernarg ABI changed");

std::mutex module_mutex;
hipModule_t modules[kArtifactCount] = {};
hipFunction_t functions[kArtifactCount] = {};
std::string loaded_paths[kArtifactCount];
thread_local char last_error[512] = {};

int fail(const char* operation, hipError_t error) {
  std::snprintf(last_error, sizeof(last_error), "%s: %s", operation,
                hipGetErrorString(error));
  return static_cast<int>(error);
}

int fail_message(const char* message) {
  std::snprintf(last_error, sizeof(last_error), "%s", message);
  return -1;
}

void clear_modules() {
  for (uint32_t index = 0; index < kArtifactCount; ++index) {
    if (modules[index] != nullptr) (void)hipModuleUnload(modules[index]);
    modules[index] = nullptr;
    functions[index] = nullptr;
    loaded_paths[index].clear();
  }
}

hipError_t load_function(hipModule_t* module, hipFunction_t* function,
                         const char* path, const char* symbol) {
  hipError_t error = hipModuleLoad(module, path);
  if (error != hipSuccess) return error;
  return hipModuleGetFunction(function, *module, symbol);
}

bool valid_path(const char* path) { return path != nullptr && path[0] != '\0'; }

}  // namespace

extern "C" int netra_gfx950_blockscale_verify_load(
    const char* m1536_n5120_k6144_hsaco_path,
    const char* m1536_n5120_k17408_hsaco_path,
    const char* m1536_n14336_k5120_hsaco_path,
    const char* m1536_n16384_k5120_hsaco_path) {
  const char* paths[kArtifactCount] = {
      m1536_n5120_k6144_hsaco_path,
      m1536_n5120_k17408_hsaco_path,
      m1536_n14336_k5120_hsaco_path,
      m1536_n16384_k5120_hsaco_path,
  };
  for (const char* path : paths) {
    if (!valid_path(path))
      return fail_message("all block-scale GEMM HSACO paths must be nonempty");
  }

  std::lock_guard<std::mutex> guard(module_mutex);
  if (modules[0] != nullptr) {
    bool identical = true;
    for (uint32_t index = 0; index < kArtifactCount; ++index)
      identical = identical && loaded_paths[index] == paths[index];
    if (identical) {
      last_error[0] = '\0';
      return 0;
    }
    return fail_message("different block-scale GEMM modules are already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::strstr(properties.gcnArchName, "gfx950") == nullptr)
    return fail_message("block-scale verification GEMMs require gfx950");

  for (uint32_t index = 0; index < kArtifactCount; ++index) {
    error = load_function(&modules[index], &functions[index], paths[index],
                          kSymbols[index]);
    if (error != hipSuccess) {
      clear_modules();
      return fail("load(block-scale GEMM artifact)", error);
    }
    loaded_paths[index] = paths[index];
  }
  last_error[0] = '\0';
  return 0;
}

extern "C" int netra_gfx950_blockscale_verify_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_modules();
  last_error[0] = '\0';
  return 0;
}

extern "C" int netra_gfx950_blockscale_verify_launch(
    void* output_bf16, const void* activation_fp8_e4m3,
    const void* weight_fp8_e4m3, const void* activation_scale_f32,
    const void* weight_scale_f32, uint32_t m, uint32_t n, uint32_t k,
    uint32_t activation_stride, uint32_t weight_stride,
    uint32_t output_stride, uint32_t activation_scale_stride,
    uint32_t weight_scale_stride, hipStream_t stream) {
  if (functions[0] == nullptr || functions[1] == nullptr ||
      functions[2] == nullptr || functions[3] == nullptr)
    return fail_message("block-scale GEMM modules are not loaded");
  if (output_bf16 == nullptr || activation_fp8_e4m3 == nullptr ||
      weight_fp8_e4m3 == nullptr || activation_scale_f32 == nullptr ||
      weight_scale_f32 == nullptr)
    return fail_message("block-scale GEMM pointers must be nonnull");
  if (m != kM || activation_stride != k || weight_stride != k ||
      output_stride != n || activation_scale_stride != kM ||
      weight_scale_stride != k / kQuantBlock)
    return fail_message("block-scale GEMM layout is outside the exact contract");

  hipFunction_t function = nullptr;
  uint32_t tile_m = 0;
  if (n == 5120 && k == 6144) {
    function = functions[0];
    tile_m = 128;
  } else if (n == 5120 && k == 17408) {
    function = functions[1];
    tile_m = 128;
  } else if (n == 14336 && k == 5120) {
    function = functions[2];
    tile_m = 192;
  } else if (n == 16384 && k == 5120) {
    function = functions[3];
    tile_m = 192;
  } else {
    return fail_message("block-scale GEMM shape is outside the exact contract");
  }

  KernelArgs args = {
      activation_fp8_e4m3,
      weight_fp8_e4m3,
      activation_scale_f32,
      weight_scale_f32,
      output_bf16,
      static_cast<int32_t>(m),
      static_cast<int32_t>(n),
      static_cast<int32_t>(k),
      static_cast<int32_t>(k / kQuantBlock),
      static_cast<int32_t>(k / kQuantBlock),
      static_cast<int32_t>(activation_stride),
      static_cast<int32_t>(weight_stride),
      static_cast<int32_t>(output_stride),
      static_cast<int32_t>(activation_scale_stride),
      static_cast<int32_t>(weight_scale_stride),
      1,
      0};
  void* arguments[] = {&args};
  const uint32_t grid_x = ((m + tile_m - 1) / tile_m) * ((n + 255) / 256);
  const hipError_t error = hipModuleLaunchKernel(
      function, grid_x, 1, 1, kThreads, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error[0] = '\0';
  return 0;
}

extern "C" const char* netra_gfx950_blockscale_verify_last_error(void) {
  return last_error;
}
