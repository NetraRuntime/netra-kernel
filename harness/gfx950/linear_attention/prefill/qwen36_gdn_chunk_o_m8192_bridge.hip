// SPDX-License-Identifier: MIT
// Isolated loader/launcher for the experimental raw gfx950 chunk-o kernel.
#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {
std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
bool fixed_shape_abi = false;
bool bv128_geometry = false;
thread_local std::string last_error;

int fail(const char* operation, hipError_t error) {
  last_error = std::string(operation) + ": " + hipGetErrorString(error);
  return static_cast<int>(error);
}

int fail_message(const std::string& message) {
  last_error = message;
  return -1;
}

void clear_module() {
  if (module != nullptr) (void)hipModuleUnload(module);
  module = nullptr;
  function = nullptr;
  fixed_shape_abi = false;
  bv128_geometry = false;
}

int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("chunk-o experiment requires gfx950; got ") +
                        properties.gcnArchName);
  return 0;
}
}  // namespace

extern "C" int netra_qwen36_gdn_chunk_o_m8192_load(
    const char* hsaco_path, const char* kernel_name) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0' ||
      kernel_name == nullptr || kernel_name[0] == '\0')
    return fail_message("hsaco path and kernel name must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) return fail_message("chunk-o module is already loaded");
  if (validate_device() != 0) return -1;
  hipError_t error = hipModuleLoad(&module, hsaco_path);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleLoad", error);
  }
  error = hipModuleGetFunction(&function, module, kernel_name);
  if (error != hipSuccess) {
    clear_module();
    return fail("hipModuleGetFunction", error);
  }
  fixed_shape_abi = std::string(kernel_name).find("_fixed_") != std::string::npos;
  bv128_geometry = std::string(kernel_name).find("_bv128_") != std::string::npos;
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_chunk_o_m8192_launch(
    const void* q_bf16,
    const void* k_bf16,
    const void* v_new_bf16,
    const void* h_bf16,
    const void* g_f32,
    void* output_bf16,
    const void* cu_seqlens_i32,
    const void* chunk_indices_i32,
    float scale,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("chunk-o module is not loaded");
  if (q_bf16 == nullptr || k_bf16 == nullptr || v_new_bf16 == nullptr ||
      h_bf16 == nullptr || g_f32 == nullptr || output_bf16 == nullptr ||
      cu_seqlens_i32 == nullptr || chunk_indices_i32 == nullptr)
    return fail_message("chunk-o launch pointers must be nonnull");
  void* q = const_cast<void*>(q_bf16);
  void* k = const_cast<void*>(k_bf16);
  void* v = const_cast<void*>(v_new_bf16);
  void* h = const_cast<void*>(h_bf16);
  void* g = const_cast<void*>(g_f32);
  void* cu = const_cast<void*>(cu_seqlens_i32);
  void* chunks = const_cast<void*>(chunk_indices_i32);
  int token_count = 8192;
  void* global_scratch = nullptr;
  void* profile_scratch = nullptr;
  void* variable_arguments[] = {
      &q, &k, &v, &h, &g, &output_bf16, &cu, &chunks, &scale,
      &token_count, &global_scratch, &profile_scratch};
  void* fixed_arguments[] = {
      &q, &k, &v, &h, &g, &output_bf16, &scale, &token_count,
      &global_scratch, &profile_scratch};
  hipError_t error = hipModuleLaunchKernel(
      function, bv128_geometry ? 1 : 2, 128, 32, 256, 1, 1,
      bv128_geometry ? 32768 : 16384, stream,
      fixed_shape_abi ? fixed_arguments : variable_arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_chunk_o_m8192_unload() {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_module();
  last_error.clear();
  return 0;
}

extern "C" const char* netra_qwen36_gdn_chunk_o_m8192_last_error() {
  return last_error.c_str();
}
