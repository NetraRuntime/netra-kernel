// SPDX-License-Identifier: MIT
//
// Module management and caller-stream dispatch only. Compute is implemented
// by the raw gfx950 AMDGCN code object under kernels/gfx950/.
#include "qwen36_shared_gate_append_bridge.h"

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

extern "C" int netra_qwen36_shared_gate_append_load(
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
        "a different shared-gate/append code object is already loaded");
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
        std::string("shared-gate/append code object requires gfx950; got ") +
        properties.gcnArchName);

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(
      &function, module, "qwen36_shared_gate_append_m1_gfx950");
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

extern "C" int netra_qwen36_shared_gate_append_launch(
    void* output_ids_i32,
    void* output_weights_f32,
    const void* hidden_bf16,
    const void* shared_gate_weight_bf16,
    const void* routed_ids_i32,
    const void* routed_weights_f32,
    uint32_t rows,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("shared-gate/append module is not loaded");
  if (output_ids_i32 == nullptr || output_weights_f32 == nullptr ||
      hidden_bf16 == nullptr || shared_gate_weight_bf16 == nullptr ||
      routed_ids_i32 == nullptr || routed_weights_f32 == nullptr)
    return fail_message("shared-gate/append launch pointers must be nonnull");
  if (rows != 1 && rows != 16)
    return fail_message("shared-gate/append rows must be 1 or 16");

  void* hidden_pointer = const_cast<void*>(hidden_bf16);
  void* shared_gate_weight_pointer =
      const_cast<void*>(shared_gate_weight_bf16);
  void* routed_ids_pointer = const_cast<void*>(routed_ids_i32);
  void* routed_weights_pointer = const_cast<void*>(routed_weights_f32);
  void* arguments[] = {
      &output_ids_i32,
      &output_weights_f32,
      &hidden_pointer,
      &shared_gate_weight_pointer,
      &routed_ids_pointer,
      &routed_weights_pointer,
  };
  hipError_t error = hipModuleLaunchKernel(
      function, 1, rows, 1, 64, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_shared_gate_append_unload(void) {
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

extern "C" const char* netra_qwen36_shared_gate_append_last_error(void) {
  return last_error.c_str();
}
