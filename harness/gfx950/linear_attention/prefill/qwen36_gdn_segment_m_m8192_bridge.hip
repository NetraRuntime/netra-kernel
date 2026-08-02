// SPDX-License-Identifier: MIT
// Isolated loader for the experimental gfx950 GDN segment transition kernel.
#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {
std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
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
}
int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("segment transition requires gfx950; got ") +
                        properties.gcnArchName);
  return 0;
}
}  // namespace

extern "C" int netra_qwen36_gdn_segment_m_m8192_load(
    const char* hsaco_path, const char* kernel_name) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0' ||
      kernel_name == nullptr || kernel_name[0] == '\0')
    return fail_message("hsaco path and kernel name must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr)
    return fail_message("segment transition module already loaded");
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
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_segment_m_m8192_launch(
    const void* k_bf16,
    const void* w_bf16,
    const void* g_f32,
    void* m_bf16,
    unsigned int chunks_per_segment,
    hipStream_t stream) {
  if (function == nullptr)
    return fail_message("segment transition module is not loaded");
  if (k_bf16 == nullptr || w_bf16 == nullptr || g_f32 == nullptr ||
      m_bf16 == nullptr)
    return fail_message("segment transition launch pointers must be nonnull");
  if (chunks_per_segment != 32)
    return fail_message("segment transition requires exactly 32 chunks");
  void* k = const_cast<void*>(k_bf16);
  void* w = const_cast<void*>(w_bf16);
  void* g = const_cast<void*>(g_f32);
  void* arguments[] = {&k, &w, &g, &m_bf16, &chunks_per_segment};
  hipError_t error = hipModuleLaunchKernel(
      function, 32, 32, 1, 256, 1, 1, 0, stream, arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_segment_m_m8192_unload() {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_module();
  last_error.clear();
  return 0;
}
extern "C" const char* netra_qwen36_gdn_segment_m_m8192_last_error() {
  return last_error.c_str();
}
