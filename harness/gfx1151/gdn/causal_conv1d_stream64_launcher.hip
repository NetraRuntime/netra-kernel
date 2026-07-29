// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
namespace {
hipModule_t conv_module,state_module; hipFunction_t conv_kernel,state_kernel;
struct alignas(8) ConvArgs { void* x; void* w; void* state; void* cache; void* has_init; void* out; };
struct alignas(8) StateArgs { void* x; void* state; void* cache; };
}
extern "C" int netra_causal_conv_init(const char* conv_path,const char* state_path) {
  hipError_t e=hipModuleLoad(&conv_module,conv_path); if(e!=hipSuccess) return e;
  e=hipModuleGetFunction(&conv_kernel,conv_module,"causal_conv1d_stream64_gfx1151"); if(e!=hipSuccess) return e;
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
