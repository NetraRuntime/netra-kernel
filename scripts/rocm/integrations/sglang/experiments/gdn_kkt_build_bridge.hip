#include <hip/hip_runtime.h>
#include <cstdint>
#include <string>
namespace { hipModule_t mod{}; hipFunction_t fn{}; std::string err; }
extern "C" int gdn_kkt_init(const char* path) {
  hipError_t st=hipModuleLoad(&mod,path); if(st!=hipSuccess){err=hipGetErrorString(st);return int(st);}
  st=hipModuleGetFunction(&fn,mod,"gdn_kkt_build_fp32_gfx1151"); if(st!=hipSuccess){err=hipGetErrorString(st);return int(st);} return 0;
}
extern "C" int gdn_kkt_launch(void* k,void* g,void* beta,void* out,void* stream) {
  struct alignas(8) Args { void* k; void* g; void* beta; void* out; } args{k,g,beta,out};
  size_t size=sizeof(args); void* config[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,&args,HIP_LAUNCH_PARAM_BUFFER_SIZE,&size,HIP_LAUNCH_PARAM_END};
  hipError_t st=hipModuleLaunchKernel(fn,10,128,32,32,1,1,0,reinterpret_cast<hipStream_t>(stream),nullptr,config);
  if(st!=hipSuccess) err=hipGetErrorString(st); return int(st);
}
extern "C" const char* gdn_kkt_error(){return err.c_str();}
