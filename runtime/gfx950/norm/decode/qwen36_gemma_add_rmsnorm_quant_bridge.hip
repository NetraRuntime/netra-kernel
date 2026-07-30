// SPDX-License-Identifier: MIT
//
// Module management and caller-stream dispatch only. Compute is implemented
// by the raw gfx950 AMDGCN code object under kernels/gfx950/.
#include "qwen36_gemma_add_rmsnorm_quant_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
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

extern "C" int netra_qwen36_gemma_add_rmsnorm_quant_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0')
    return fail_message("hsaco_path must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message(
        "a different Gemma add+RMSNorm+quant code object is already loaded");
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
        std::string("Gemma add+RMSNorm+quant code object requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module,
      "qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950");
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

extern "C" int netra_qwen36_gemma_add_rmsnorm_quant_launch(
    void* output_bf16,
    const void* input_bf16,
    const void* residual_bf16,
    void* residual_out_bf16,
    const void* gemma_weight_bf16,
    void* output_fp8,
    void* output_scale_f32,
    double epsilon,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("Gemma add+RMSNorm+quant module is not loaded");
  if (output_bf16 == nullptr || input_bf16 == nullptr ||
      residual_bf16 == nullptr || residual_out_bf16 == nullptr ||
      gemma_weight_bf16 == nullptr || output_fp8 == nullptr ||
      output_scale_f32 == nullptr)
    return fail_message(
        "Gemma add+RMSNorm+quant launch pointers must be nonnull");

  void* arguments[] = {
      &output_bf16,
      &input_bf16,
      &residual_bf16,
      &residual_out_bf16,
      &gemma_weight_bf16,
      &output_fp8,
      &output_scale_f32,
      &epsilon,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, 1, 1, 1, 256, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gemma_add_rmsnorm_quant_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) return fail("hipModuleUnload", error);
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char*
netra_qwen36_gemma_add_rmsnorm_quant_last_error(void) {
  return last_error.c_str();
}
