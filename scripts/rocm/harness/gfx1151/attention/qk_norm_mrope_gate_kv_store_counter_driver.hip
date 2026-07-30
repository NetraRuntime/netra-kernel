// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
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

int main(int argc, char** argv) {
  const uint32_t m = argc > 2 ? std::strtoul(argv[2], nullptr, 10) : 8192;
  const char* path = argc > 1 ? argv[1] : "build/experiments/qk-norm-mrope-kv-fusion/qk_norm_mrope_gate_kv_store_gfx1151.hsaco";
  auto ck = [](hipError_t e) { if (e != hipSuccess) std::exit(1); };
  auto az = [&](size_t n) { void* p = nullptr; ck(hipMalloc(&p, n)); ck(hipMemset(p, 0, n)); return p; };
  ck(static_cast<hipError_t>(netra_qk_mrope_kv_init(path)));
  void* qkv=az(size_t(m)*18432); void* q=az(size_t(m)*8192);
  void* k=az(size_t(m)*1024); void* gate=az(size_t(m)*8192);
  void* qw=az(512); void* kw=az(512); void* cs=az(128);
  void* pos=az(size_t(m)*24); void* kc=az(1024); void* vc=az(1024);
  void* loc=az(size_t(m)*8); hipStream_t stream=nullptr; ck(hipStreamCreate(&stream));
  ck(static_cast<hipError_t>(netra_qk_mrope_kv(qkv,q,k,gate,qw,kw,cs,pos,kc,vc,loc,m,stream)));
  ck(hipStreamSynchronize(stream));
  ck(static_cast<hipError_t>(netra_qk_mrope_kv(qkv,q,k,gate,qw,kw,cs,pos,kc,vc,loc,m,stream)));
  ck(hipStreamSynchronize(stream));
  std::printf("gfx1151 measured driver M=%u\n", m);
  return 0;
}
