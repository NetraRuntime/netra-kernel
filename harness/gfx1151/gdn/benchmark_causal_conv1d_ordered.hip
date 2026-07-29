// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdlib>
#include <iostream>
namespace {
hipModule_t conv_module,state_module; hipFunction_t conv_kernel,state_kernel;
struct alignas(8) ConvArgs { void* x; void* w; void* state; void* cache; void* has_init; void* out; };
struct alignas(8) StateArgs { void* x; void* state; void* cache; };
}
extern "C" int netra_causal_conv_init(const char* conv_path,const char* state_path) {
  hipError_t e=hipModuleLoad(&conv_module,conv_path); if(e!=hipSuccess) return e;
  e=hipModuleGetFunction(&conv_kernel,conv_module,"causal_conv1d_stream64_ordered_gfx1151"); if(e!=hipSuccess) return e;
  e=hipModuleLoad(&state_module,state_path); if(e!=hipSuccess) return e;
  return hipModuleGetFunction(&state_kernel,state_module,"causal_conv1d_state_update_gfx1151");
}
extern "C" int netra_causal_conv(void* x,void* w,void* state,void* cache,void* has_init,void* out,hipStream_t stream) {
  ConvArgs ca{x,w,state,cache,has_init,out}; size_t cn=sizeof(ca);
  void* cc[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,&ca,HIP_LAUNCH_PARAM_BUFFER_SIZE,&cn,HIP_LAUNCH_PARAM_END};
  hipError_t e=hipModuleLaunchKernel(conv_kernel,64,128,1,128,1,1,0,stream,nullptr,cc); if(e!=hipSuccess) return e;
  StateArgs sa{x,state,cache}; size_t sn=sizeof(sa);
  void* sc[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,&sa,HIP_LAUNCH_PARAM_BUFFER_SIZE,&sn,HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(state_kernel,64,1,1,128,1,1,0,stream,nullptr,sc);
}

int main(int argc, char** argv) {
  if (argc < 3 || argc > 4) {
    std::cerr << "usage: " << argv[0] << " CONV_HSACO STATE_HSACO [ITERATIONS]\n";
    return 2;
  }
  int iterations = argc == 4 ? std::atoi(argv[3]) : 1;
  if (iterations < 1) return 2;
  constexpr size_t x_bytes = 8192ULL * 8192 * 2;
  constexpr size_t weight_bytes = 8192ULL * 4 * 2;
  constexpr size_t state_bytes = 60ULL * 8192 * 3 * 2;
  const size_t sizes[] = {x_bytes, weight_bytes, state_bytes, 4, 1, x_bytes};
  void* buffers[6]{};
  for (int i = 0; i < 6; ++i) {
    hipError_t status = hipMalloc(&buffers[i], sizes[i]);
    if (status != hipSuccess) return 10 + static_cast<int>(status);
    status = hipMemset(buffers[i], 0, sizes[i]);
    if (status != hipSuccess) return 20 + static_cast<int>(status);
  }
  int status = netra_causal_conv_init(argv[1], argv[2]);
  if (status) return 30 + status;
  hipEvent_t begin{}, end{};
  hipEventCreate(&begin);
  hipEventCreate(&end);
  hipEventRecord(begin);
  for (int i = 0; i < iterations; ++i) {
    status = netra_causal_conv(
        buffers[0], buffers[1], buffers[2], buffers[3], buffers[4],
        buffers[5], nullptr);
    if (status) return 40 + status;
  }
  hipEventRecord(end);
  hipEventSynchronize(end);
  float elapsed_ms = 0.0f;
  hipEventElapsedTime(&elapsed_ms, begin, end);
  std::cout << "gfx1151 measured ordered causal conv pair total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";
  for (void* buffer : buffers) hipFree(buffer);
  hipEventDestroy(begin);
  hipEventDestroy(end);
  return 0;
}
