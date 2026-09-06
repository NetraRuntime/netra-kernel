// SPDX-License-Identifier: MIT
// Module ownership and launch only. The 192-byte block is copied by HIP at launch.
#include <hip/hip_runtime.h>
#include <cstdint>
#include <new>
#include <string>
namespace {
constexpr const char* names[] = {
    "rope_flat",
    "hash_topk",
    "online_combine",
    "rms_fp8_4096",
    "router_256",
    "online_partial_1024",
    "hc_head_4096",
    "softmax_tile_stats",
    "softmax_combine",
    "softmax_apply",
    "classic_accept",
    "classic_tile_sum",
    "classic_sample",
    "rope_flat_w4",
    "hash_topk_w4",
    "online_combine_w4",
    "rms_fp8_4096_w4",
    "router_256_w4",
    "online_partial_1024_w4",
    "hc_head_4096_w4",
    "softmax_tile_stats_w4",
    "softmax_combine_w4",
    "softmax_apply_w4",
    "classic_accept_w4",
    "classic_tile_sum_w4",
    "classic_sample_w4"};
constexpr unsigned count = sizeof(names) / sizeof(names[0]);
constexpr unsigned op_count = count / 2;
struct Owner { hipModule_t module; hipFunction_t fn[count]; int device; };
thread_local std::string error;
int fail(const char* s) { error=s; return -1; }
int checked(hipError_t e) { if(e!=hipSuccess) error=hipGetErrorString(e); return int(e); }
}
extern "C" const char* netra_numeric_error() { return error.c_str(); }
extern "C" int netra_numeric_create(const char* path, void** handle) {
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
extern "C" int netra_numeric_launch(void* handle, unsigned mode, void* args,
    unsigned rows, hipStream_t stream) {
  if(!handle || !args || mode>=count || !rows || rows>0x7fffffff) return fail("invalid launch");
  auto* c=static_cast<Owner*>(handle); int device;
  if(int e=checked(hipGetDevice(&device))) return e;
  if(device!=c->device) return fail("launch on owning device");
  size_t size=192;
  void* extra[]={HIP_LAUNCH_PARAM_BUFFER_POINTER,args,HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &size,HIP_LAUNCH_PARAM_END};
  const unsigned op=mode % op_count;
  const bool cooperative=op==3 || op==5 || op==6 || op==7 || op==11 || op==12;
  const unsigned grid=cooperative ? rows : (mode>=op_count ? (rows+3)/4 : rows);
  const unsigned threads=(cooperative || mode>=op_count) ? 256 : 64;
  return checked(hipModuleLaunchKernel(c->fn[mode],grid,1,1,threads,1,1,0,stream,nullptr,extra));
}
extern "C" int netra_numeric_close(void* handle) {
  if(!handle) return 0;
  auto* c=static_cast<Owner*>(handle); int device;
  if(int e=checked(hipGetDevice(&device))) return e;
  if(device!=c->device) return fail("close on owning device");
  if(int e=checked(hipModuleUnload(c->module))) return e;
  delete c; return 0;
}
