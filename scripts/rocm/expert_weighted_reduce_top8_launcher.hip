#include <hip/hip_runtime.h>
namespace { hipModule_t m; hipFunction_t k; struct alignas(8) Args{void* e;void* p;void* w;void* o;}; }
extern "C" int netra_reduce_init(const char* path){auto s=hipModuleLoad(&m,path);if(s)return s;return hipModuleGetFunction(&k,m,"expert_weighted_reduce_top8_gfx1151");}
extern "C" int netra_reduce(void* e,void* p,void* w,void* o,unsigned tokens,hipStream_t stream){Args a{e,p,w,o};size_t n=sizeof(a);void* c[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,&a,HIP_LAUNCH_PARAM_BUFFER_SIZE,&n,HIP_LAUNCH_PARAM_END};return hipModuleLaunchKernel(k,8,tokens,1,256,1,1,0,stream,nullptr,c);}
