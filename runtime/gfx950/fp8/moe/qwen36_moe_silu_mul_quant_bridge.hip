// SPDX-License-Identifier: MIT
//
// HIP is used only for gfx950 module management and dispatch. The compute
// implementation is the raw AMDGCN .s code object in kernels/gfx950/.
#include "qwen36_moe_silu_mul_quant_bridge.h"

#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {

constexpr int kThreads = 64;
constexpr const char* kKernelName =
    "qwen36_moe_silu_mul_quant_fp8_gfx950";
constexpr unsigned int kDownGrid = 128;
constexpr unsigned int kDownThreadsOneWave = 64;
constexpr unsigned int kDownThreadsTwoWave = 128;
constexpr const char* kDownKernelNameOneWave =
    "qwen36_moe_down_reduce_fp8_mfma_gfx950";
constexpr const char* kDownKernelNameTwoWave =
    "qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950";
constexpr unsigned int kGateUpGrid = 576;
constexpr const char* kGateUpKernelName =
    "qwen36_moe_gate_up_fp8_mfma_gfx950";

std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
std::string loaded_path;
thread_local std::string last_error;
std::mutex down_module_mutex;
hipModule_t down_module = nullptr;
hipFunction_t down_function = nullptr;
unsigned int down_threads = kDownThreadsOneWave;
std::string down_loaded_path;
std::mutex gate_up_module_mutex;
hipModule_t gate_up_module = nullptr;
hipFunction_t gate_up_function = nullptr;
std::string gate_up_loaded_path;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

}  // namespace

extern "C" int netra_qwen36_moe_silu_mul_quant_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0') {
    return fail_message("hsaco_path must be nonempty");
  }

  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) {
    if (loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message(
        "a different code object is already loaded; unload it first");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) {
    return fail("hipGetDevice", error);
  }
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) {
    return fail("hipGetDeviceProperties", error);
  }
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos) {
    return fail_message(
        std::string("raw code object requires gfx950; got ") +
        properties.gcnArchName);
  }

  error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    module = nullptr;
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(&function, module, kKernelName);
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

extern "C" int netra_qwen36_moe_silu_mul_quant_launch(
    const float* input_f32,
    void* output_fp8,
    float* output_scale_f32,
    int rows,
    hipStream_t stream) {
  if (function == nullptr) {
    return fail_message("raw module is not loaded");
  }
  if (input_f32 == nullptr || output_fp8 == nullptr ||
      output_scale_f32 == nullptr) {
    return fail_message("launch pointers must be nonnull");
  }
  if (rows <= 0) {
    return fail_message("rows must be positive");
  }

  void* arguments[] = {
      &input_f32,
      &output_fp8,
      &output_scale_f32,
      &rows,
  };
  hipError_t error = hipModuleLaunchKernel(
      function,
      static_cast<unsigned int>(rows),
      1,
      1,
      kThreads,
      1,
      1,
      0,
      stream,
      arguments,
      nullptr);
  if (error != hipSuccess) {
    return fail("hipModuleLaunchKernel", error);
  }
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_silu_mul_quant_unload(void) {
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(module);
  if (error != hipSuccess) {
    return fail("hipModuleUnload", error);
  }
  module = nullptr;
  function = nullptr;
  loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_moe_silu_mul_quant_last_error(void) {
  return last_error.c_str();
}

extern "C" int netra_qwen36_moe_down_reduce_load(
    const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0') {
    return fail_message("down-reduce hsaco_path must be nonempty");
  }

  std::lock_guard<std::mutex> guard(down_module_mutex);
  if (down_module != nullptr) {
    if (down_loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message(
        "a different down-reduce code object is already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) {
    return fail("hipGetDevice", error);
  }
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) {
    return fail("hipGetDeviceProperties", error);
  }
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos) {
    return fail_message(
        std::string("raw down-reduce code object requires gfx950; got ") +
        properties.gcnArchName);
  }

  error = hipModuleLoad(&down_module, hsaco_path);
  if (error != hipSuccess) {
    down_module = nullptr;
    return fail("hipModuleLoad(down-reduce)", error);
  }
  const bool two_wave =
      std::string(hsaco_path).find("_2wave_") != std::string::npos;
  const char* down_kernel_name =
      two_wave ? kDownKernelNameTwoWave : kDownKernelNameOneWave;
  down_threads =
      two_wave ? kDownThreadsTwoWave : kDownThreadsOneWave;
  error = hipModuleGetFunction(
      &down_function, down_module, down_kernel_name);
  if (error != hipSuccess) {
    (void)hipModuleUnload(down_module);
    down_module = nullptr;
    down_function = nullptr;
    return fail("hipModuleGetFunction(down-reduce)", error);
  }
  down_loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_down_reduce_launch(
    const void* activation_fp8,
    const float* activation_scale_f32,
    const void* w2_fp8,
    const float* w2_scale_f32,
    const float* topk_weights_f32,
    const int32_t* topk_ids_i32,
    void* output_bf16,
    hipStream_t stream) {
  if (down_function == nullptr) {
    return fail_message("raw down-reduce module is not loaded");
  }
  if (activation_fp8 == nullptr || activation_scale_f32 == nullptr ||
      w2_fp8 == nullptr || w2_scale_f32 == nullptr ||
      topk_weights_f32 == nullptr || topk_ids_i32 == nullptr ||
      output_bf16 == nullptr) {
    return fail_message("down-reduce launch pointers must be nonnull");
  }

  void* arguments[] = {
      &activation_fp8,
      &activation_scale_f32,
      &w2_fp8,
      &w2_scale_f32,
      &topk_weights_f32,
      &topk_ids_i32,
      &output_bf16,
  };
  hipError_t error = hipModuleLaunchKernel(
      down_function,
      kDownGrid,
      1,
      1,
      down_threads,
      1,
      1,
      0,
      stream,
      arguments,
      nullptr);
  if (error != hipSuccess) {
    return fail("hipModuleLaunchKernel(down-reduce)", error);
  }
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_down_reduce_unload(void) {
  std::lock_guard<std::mutex> guard(down_module_mutex);
  if (down_module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(down_module);
  if (error != hipSuccess) {
    return fail("hipModuleUnload(down-reduce)", error);
  }
  down_module = nullptr;
  down_function = nullptr;
  down_threads = kDownThreadsOneWave;
  down_loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_moe_down_reduce_last_error(void) {
  return last_error.c_str();
}

extern "C" int netra_qwen36_moe_gate_up_load(const char* hsaco_path) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0') {
    return fail_message("gate/up hsaco_path must be nonempty");
  }
  std::lock_guard<std::mutex> guard(gate_up_module_mutex);
  if (gate_up_module != nullptr) {
    if (gate_up_loaded_path == hsaco_path) {
      last_error.clear();
      return 0;
    }
    return fail_message("a different gate/up code object is already loaded");
  }

  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") ==
      std::string::npos) {
    return fail_message(
        std::string("raw gate/up code object requires gfx950; got ") +
        properties.gcnArchName);
  }

  error = hipModuleLoad(&gate_up_module, hsaco_path);
  if (error != hipSuccess) {
    gate_up_module = nullptr;
    return fail("hipModuleLoad(gate/up)", error);
  }
  error = hipModuleGetFunction(
      &gate_up_function, gate_up_module, kGateUpKernelName);
  if (error != hipSuccess) {
    (void)hipModuleUnload(gate_up_module);
    gate_up_module = nullptr;
    gate_up_function = nullptr;
    return fail("hipModuleGetFunction(gate/up)", error);
  }
  gate_up_loaded_path = hsaco_path;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_gate_up_launch(
    const void* hidden_fp8,
    const float* hidden_scale_f32,
    const void* w13_fp8,
    const float* w13_scale_f32,
    const int32_t* topk_ids_i32,
    float* output_f32,
    hipStream_t stream) {
  if (gate_up_function == nullptr)
    return fail_message("raw gate/up module is not loaded");
  if (hidden_fp8 == nullptr || hidden_scale_f32 == nullptr ||
      w13_fp8 == nullptr || w13_scale_f32 == nullptr ||
      topk_ids_i32 == nullptr || output_f32 == nullptr)
    return fail_message("gate/up launch pointers must be nonnull");
  void* arguments[] = {
      &hidden_fp8,       &hidden_scale_f32, &w13_fp8,
      &w13_scale_f32,    &topk_ids_i32,     &output_f32,
  };
  hipError_t error = hipModuleLaunchKernel(
      gate_up_function, kGateUpGrid, 1, 1, kThreads, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess)
    return fail("hipModuleLaunchKernel(gate/up)", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_moe_gate_up_unload(void) {
  std::lock_guard<std::mutex> guard(gate_up_module_mutex);
  if (gate_up_module == nullptr) {
    last_error.clear();
    return 0;
  }
  hipError_t error = hipModuleUnload(gate_up_module);
  if (error != hipSuccess) return fail("hipModuleUnload(gate/up)", error);
  gate_up_module = nullptr;
  gate_up_function = nullptr;
  gate_up_loaded_path.clear();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_moe_gate_up_last_error(void) {
  return last_error.c_str();
}
