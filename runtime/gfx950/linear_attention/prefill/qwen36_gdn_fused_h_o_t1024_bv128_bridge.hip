// SPDX-License-Identifier: MIT
// Runtime loader for the accepted gfx950 fused GDN recurrence/output.
#include <hip/hip_runtime.h>

#include <mutex>
#include <string>

namespace {
std::mutex module_mutex;
hipModule_t module = nullptr;
hipFunction_t function = nullptr;
unsigned int launch_grid_x = 8;
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
  launch_grid_x = 8;
}
int validate_device() {
  int device = 0;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return fail("hipGetDevice", error);
  hipDeviceProp_t properties{};
  error = hipGetDeviceProperties(&properties, device);
  if (error != hipSuccess) return fail("hipGetDeviceProperties", error);
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos)
    return fail_message(std::string("fused GDN requires gfx950; got ") +
                        properties.gcnArchName);
  return 0;
}
}  // namespace

extern "C" int netra_qwen36_gdn_fused_h_o_m8192_load(
    const char* hsaco_path, const char* kernel_name) {
  if (hsaco_path == nullptr || hsaco_path[0] == '\0' ||
      kernel_name == nullptr || kernel_name[0] == '\0')
    return fail_message("hsaco path and kernel name must be nonempty");
  std::lock_guard<std::mutex> guard(module_mutex);
  if (module != nullptr) return fail_message("fused GDN module already loaded");
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
  const std::string name(kernel_name);
  launch_grid_x = name.find("_bv128_") != std::string::npos
                      ? 1
                      : (name.find("_bv64_") != std::string::npos
                             ? 2
                             : (name.find("_bv32_") != std::string::npos ? 4
                                                                           : 8));
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_fused_h_o_m8192_launch(
    const void* q_bf16,
    const void* k_bf16,
    const void* u_bf16,
    const void* w_bf16,
    const void* g_f32,
    void* state_bf16,
    void* output_bf16,
    const void* state_indices_i32,
    float scale,
    unsigned int num_chunks,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("fused GDN module is not loaded");
  if (q_bf16 == nullptr || k_bf16 == nullptr || u_bf16 == nullptr ||
      w_bf16 == nullptr || g_f32 == nullptr || state_bf16 == nullptr ||
      output_bf16 == nullptr || state_indices_i32 == nullptr)
    return fail_message("fused GDN launch pointers must be nonnull");
  if (num_chunks == 0 || num_chunks > 128)
    return fail_message("fused GDN num_chunks must be in [1, 128]");
  void* q = const_cast<void*>(q_bf16);
  void* k = const_cast<void*>(k_bf16);
  void* u = const_cast<void*>(u_bf16);
  void* w = const_cast<void*>(w_bf16);
  void* g = const_cast<void*>(g_f32);
  void* state_indices = const_cast<void*>(state_indices_i32);
  void* arguments[] = {
      &q, &k, &u, &w, &g, &state_bf16, &output_bf16, &scale, &num_chunks,
      &state_indices};
  hipError_t error = hipModuleLaunchKernel(
      function, launch_grid_x, 32, 1, 256, 1, 1, 0, stream, arguments,
      nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_fused_h_o_m8192_launch_varlen(
    const void* q_bf16,
    const void* k_bf16,
    const void* u_bf16,
    const void* w_bf16,
    const void* g_f32,
    void* state_bf16,
    void* output_bf16,
    const void* state_indices_i32,
    float scale,
    unsigned int num_chunks_per_sequence,
    unsigned int num_sequences,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("fused GDN module is not loaded");
  if (q_bf16 == nullptr || k_bf16 == nullptr || u_bf16 == nullptr ||
      w_bf16 == nullptr || g_f32 == nullptr || state_bf16 == nullptr ||
      output_bf16 == nullptr || state_indices_i32 == nullptr)
    return fail_message("fused GDN launch pointers must be nonnull");
  if (num_chunks_per_sequence == 0 || num_chunks_per_sequence > 128)
    return fail_message("fused GDN chunks per sequence must be in [1, 128]");
  if (num_sequences == 0 || num_sequences > 64)
    return fail_message("fused GDN sequence count must be in [1, 64]");
  void* q = const_cast<void*>(q_bf16);
  void* k = const_cast<void*>(k_bf16);
  void* u = const_cast<void*>(u_bf16);
  void* w = const_cast<void*>(w_bf16);
  void* g = const_cast<void*>(g_f32);
  void* state_indices = const_cast<void*>(state_indices_i32);
  void* arguments[] = {&q, &k, &u, &w, &g, &state_bf16, &output_bf16,
                       &scale, &num_chunks_per_sequence, &state_indices};
  hipError_t error = hipModuleLaunchKernel(
      function, launch_grid_x, num_sequences * 32, 1, 256, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_fused_h_o_m8192_launch_packed_t1024(
    const void* q_bf16,
    const void* k_bf16,
    const void* u_bf16,
    const void* w_bf16,
    const void* g_f32,
    void* state_bf16,
    void* output_bf16,
    const void* state_indices_i32,
    const void* cu_seqlens_i32,
    float scale,
    unsigned int num_sequences,
    unsigned int state_pool_size,
    hipStream_t stream) {
  if (function == nullptr) return fail_message("fused GDN module is not loaded");
  if (q_bf16 == nullptr || k_bf16 == nullptr || u_bf16 == nullptr ||
      w_bf16 == nullptr || g_f32 == nullptr || state_bf16 == nullptr ||
      output_bf16 == nullptr || state_indices_i32 == nullptr ||
      cu_seqlens_i32 == nullptr)
    return fail_message("packed T1024 fused GDN launch pointers must be nonnull");
  if (num_sequences == 0 || num_sequences > 64)
    return fail_message("packed T1024 fused GDN sequence count must be in [1,64]");
  if (state_pool_size == 0 || state_pool_size > 4096)
    return fail_message("packed T1024 fused GDN state pool must be in [1,4096]");

  void* q = const_cast<void*>(q_bf16);
  void* k = const_cast<void*>(k_bf16);
  void* u = const_cast<void*>(u_bf16);
  void* w = const_cast<void*>(w_bf16);
  void* g = const_cast<void*>(g_f32);
  void* state_indices = const_cast<void*>(state_indices_i32);
  void* cu_seqlens = const_cast<void*>(cu_seqlens_i32);
  unsigned int num_chunks = 16;
  void* arguments[] = {
      &q, &k, &u, &w, &g, &state_bf16, &output_bf16, &scale, &num_chunks,
      &state_indices, &cu_seqlens, &state_pool_size};
  hipError_t error = hipModuleLaunchKernel(
      function, launch_grid_x, num_sequences * 32, 1, 256, 1, 1, 0, stream,
      arguments, nullptr);
  if (error != hipSuccess) return fail("hipModuleLaunchKernel", error);
  last_error.clear();
  return 0;
}

extern "C" int netra_qwen36_gdn_fused_h_o_m8192_unload() {
  std::lock_guard<std::mutex> guard(module_mutex);
  clear_module();
  last_error.clear();
  return 0;
}
extern "C" const char* netra_qwen36_gdn_fused_h_o_m8192_last_error() {
  return last_error.c_str();
}
