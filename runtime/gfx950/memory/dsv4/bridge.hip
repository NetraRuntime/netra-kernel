// SPDX-License-Identifier: MIT
// Module ownership and launch only. The 192-byte block is copied by HIP at launch.
#include <hip/hip_runtime.h>
#include <cstdint>
#include <new>
#include <string>
namespace {
constexpr const char* names[] = {
    "get_last_loc",
    "compute_position",
    "assign_cache_locs",
    "expand_prefill",
    "write_req_pool",
    "alloc_extend",
    "vocab_embedding",
    "get_last_loc_w4",
    "compute_position_w4",
    "assign_cache_locs_w4",
    "expand_prefill_w4",
    "write_req_pool_w4",
    "alloc_extend_w4",
    "vocab_embedding_w4"};
constexpr unsigned count = sizeof(names) / sizeof(names[0]);
constexpr unsigned op_count = count / 2;
struct Owner { hipModule_t module; hipFunction_t fn[count]; int device; };
thread_local std::string error;
int fail(const char* s) { error=s; return -1; }
int checked(hipError_t e) { if(e!=hipSuccess) error=hipGetErrorString(e); return int(e); }
}
extern "C" const char* netra_memory_error() { return error.c_str(); }
extern "C" int netra_memory_create(const char* path, void** handle) {
  if(!path || !handle) return fail("path and handle required");
  *handle=nullptr; Owner c{}; hipDeviceProp_t prop{};
  if(int e=checked(hipGetDevice(&c.device))) return e;
  if(int e=checked(hipGetDeviceProperties(&prop,c.device))) return e;
  if(std::string(prop.gcnArchName).substr(0,6)!="gfx950") return fail("requires gfx950");
  if(int e=checked(hipModuleLoad(&c.module,path))) return e;
  for(unsigned i=0;i<count;++i) {
    std::string name="netra_dsv4_"+std::string(names[i]);
    if(int e=checked(hipModuleGetFunction(&c.fn[i],c.module,name.c_str()))) {
      (void)hipModuleUnload(c.module); return e;
    }
  }
  auto* owner=new(std::nothrow) Owner(c);
  if(!owner) { (void)hipModuleUnload(c.module); return fail("allocation failed"); }
  *handle=owner; return 0;
}
extern "C" int netra_memory_launch(void* handle, unsigned mode, void* args,
    unsigned rows, hipStream_t stream) {
  if(!handle || !args || mode>=count || !rows || rows>65535) return fail("invalid launch");
  auto* c=static_cast<Owner*>(handle); int device;
  if(int e=checked(hipGetDevice(&device))) return e;
  if(device!=c->device) return fail("launch on owning device");
  size_t size=192;
  void* extra[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,args,HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &size,HIP_LAUNCH_PARAM_END};
  return checked(hipModuleLaunchKernel(c->fn[mode],mode>=op_count ? (rows+3)/4 : rows,1,1,mode>=op_count ? 256 : 64,1,1,0,stream,nullptr,extra));
}
extern "C" int netra_memory_close(void* handle) {
  if(!handle) return 0;
  auto* c=static_cast<Owner*>(handle); int device;
  if(int e=checked(hipGetDevice(&device))) return e;
  if(device!=c->device) return fail("close on owning device");
  if(int e=checked(hipModuleUnload(c->module))) return e;
  delete c; return 0;
}
