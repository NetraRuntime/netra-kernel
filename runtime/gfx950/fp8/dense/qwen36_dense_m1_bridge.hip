// SPDX-License-Identifier: MIT
//
// Module management and caller-stream dispatch only. Compute is implemented
// by the raw gfx950 AMDGCN code object under kernels/gfx950/.
#include "qwen36_dense_m1_bridge.h"

#include <hip/hip_runtime.h>

#include <cstdlib>
#include <mutex>
#include <string>

namespace {

constexpr const char* kVariantEnvironment =
    "SGLANG_NETRA_QWEN36_GFX950_DENSE_M1_VARIANT";

std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
std::string loaded_path;
unsigned int selected_grid = 0;
unsigned int selected_threads = 0;
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

extern "C" int netra_qwen36_dense_m1_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different dense M=1 code object is already loaded");
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
        std::string("dense M=1 code object requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  const char* raw_variant = std::getenv(kVariantEnvironment);
  const std::string variant =
      raw_variant == nullptr ? "four_wave_lds" : raw_variant;
  const char* kernel_name = nullptr;
  if (variant == "one_wave") {
    kernel_name = "qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950";
    selected_grid = 128;
    selected_threads = 64;
  } else if (variant == "four_wave_lds") {
    kernel_name =
        "qwen36_dense_m1_n2048_k4096_fp8_mfma_4wave_lds_gfx950";
    selected_grid = 32;
    selected_threads = 256;
  } else {
    (void)hipModuleUnload(module);
    module = nullptr;
    return fail_message(
        std::string(kVariantEnvironment) +
        " must be one_wave or four_wave_lds");
  }
  error = hipModuleGetFunction(&function, module, kernel_name);
  if (error != hipSuccess) {
    (void)hipModuleUnload(module);
    module = nullptr;
    function = nullptr;
    return fail("hipModuleGetFunction", error);
  }
  loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_dense_m1_launch(
    const void* activation_fp8,
    const float* activation_scale_f32,
    const void* shuffled_weight_fp8,
    const float* weight_scale_f32,
    void* output_bf16,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("dense M=1 module is not loaded");
  if (activation_fp8 == nullptr || activation_scale_f32 == nullptr ||
      shuffled_weight_fp8 == nullptr || weight_scale_f32 == nullptr ||
      output_bf16 == nullptr)
    return fail_message("dense M=1 launch pointers must be nonnull");

  void* arguments[] = {
      &activation_fp8,
      &activation_scale_f32,
      &shuffled_weight_fp8,
      &weight_scale_f32,
      &output_bf16,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, selected_grid, 1, 1, selected_threads, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_dense_m1_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  module = nullptr;
  function = nullptr;
  selected_grid = 0;
  selected_threads = 0;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_dense_m1_last_error(void) {
  return last_error.c_str();
}
