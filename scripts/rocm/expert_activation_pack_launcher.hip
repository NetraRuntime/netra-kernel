#include <hip/hip_runtime.h>
#include <cstdint>
#include <mutex>
namespace {hipModule_t m{};hipFunction_t f{};std::mutex mu;struct Args{void*hidden;void*pairs;void*pos;void*out;uint32_t count;uint32_t rows;};static_assert(sizeof(Args)==40);}
extern "C" int netra_pack_init(const char*p){std::lock_guard<std::mutex>g(mu);if(f)return hipSuccess;hipError_t e=hipModuleLoad(&m,p);if(e)return e;return hipModuleGetFunction(&f,m,"expert_activation_pack_gfx1151");}
extern "C" int netra_pack(void*h,void*p,void*x,void*o,uint32_t n,uint32_t rows,hipStream_t s){if(!f||!n)return hipErrorInvalidValue;Args a{h,p,x,o,n,rows};size_t z=sizeof(a);void*c[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,&a,HIP_LAUNCH_PARAM_BUFFER_SIZE,&z,HIP_LAUNCH_PARAM_END};return hipModuleLaunchKernel(f,n,1,1,256,1,1,0,s,nullptr,c);}
