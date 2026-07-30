// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>
#include <mutex>

namespace {
hipModule_t module = nullptr;
hipFunction_t kernel = nullptr;
std::mutex load_mutex;
struct Args {
  void* qkv;
  void* q_out;
  void* k_out;
  void* gate_out;
  void* q_weight;
  void* k_weight;
  void* cos_sin;
  void* positions;
  void* k_cache;
  void* v_cache;
  void* cache_loc;
  uint32_t tokens;
  uint32_t position_stride_bytes;
};
static_assert(sizeof(Args) == 96);
}

extern "C" int netra_qk_mrope_kv_init(const char* hsaco_path) {
  std::lock_guard<std::mutex> lock(load_mutex);
  if (kernel != nullptr) return hipSuccess;
  hipError_t status = hipModuleLoad(&module, hsaco_path);
  if (status != hipSuccess) return status;
  return hipModuleGetFunction(&kernel, module,
      "qk_norm_mrope_gate_kv_store_gfx1151");
}

extern "C" int netra_qk_mrope_kv(
    void* qkv, void* q_out, void* k_out, void* gate_out,
    void* q_weight, void* k_weight, void* cos_sin, void* positions,
    void* k_cache, void* v_cache, void* cache_loc, uint32_t tokens,
    hipStream_t stream) {
  if (kernel == nullptr || tokens == 0) return hipErrorInvalidValue;
  Args args{qkv, q_out, k_out, gate_out, q_weight, k_weight, cos_sin,
            positions, k_cache, v_cache, cache_loc, tokens, tokens * 8};
  size_t arg_size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &arg_size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(kernel, tokens, 1, 1, 128, 1, 1,
                               128, stream, nullptr, config);
}
