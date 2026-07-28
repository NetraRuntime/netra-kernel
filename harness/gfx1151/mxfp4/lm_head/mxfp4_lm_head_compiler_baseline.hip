// Launch/timing harness only. The comparison kernel is the pre-existing
// compiler code object that was already reproduced and disassembled.
#include <hip/hip_bf16.h>
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <random>
#include <string>
#include <vector>

#define CHK(x) do { hipError_t e_=(x); if(e_!=hipSuccess){ \
  std::fprintf(stderr,"HIP error %s at %d\n",hipGetErrorString(e_),__LINE__); \
  std::exit(1); } } while(0)

static void read_exact(const char* p,void* d,size_t n) {
  std::ifstream f(p,std::ios::binary);
  if(!f.read((char*)d,n)||size_t(f.gcount())!=n) {
    std::fprintf(stderr,"cannot read %zu bytes from %s\n",n,p); std::exit(4);
  }
}

int main(int ac,char** av) {
  constexpr int N=248320,K=2048,NBUF=4,KCHUNK=256;
  if(ac<6) {
    std::fprintf(stderr,
      "usage: %s iters compiler.co raw.hsaco packed.bin scales.bin\n",av[0]);
    return 4;
  }
  int iters=std::atoi(av[1]);
  hipDeviceProp_t prop{}; CHK(hipGetDeviceProperties(&prop,0));
  if(std::string(prop.gcnArchName).find("gfx1151")==std::string::npos) return 2;
  size_t np=size_t(K/2)*N,ns=size_t(K/32)*N;
  std::vector<unsigned char> hp(np),hs(ns);
  read_exact(av[4],hp.data(),np); read_exact(av[5],hs.data(),ns);
  std::vector<unsigned short> hab(K);
  std::mt19937 g(17); std::uniform_real_distribution<float> af(-1,1);
  for(int k=0;k<K;++k) {
    __hip_bfloat16 b=__float2bfloat16(af(g)); std::memcpy(&hab[k],&b,2);
  }
  unsigned char *dp[NBUF]{},*ds[NBUF]{};
  __hip_bfloat16*da{}; float *dyc{},*dyr{};
  for(int b=0;b<NBUF;++b) {
    CHK(hipMalloc(&dp[b],np)); CHK(hipMalloc(&ds[b],ns));
    CHK(hipMemcpy(dp[b],hp.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(ds[b],hs.data(),ns,hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da,K*2)); CHK(hipMalloc(&dyc,N*4)); CHK(hipMalloc(&dyr,N*4));
  CHK(hipMemcpy(da,hab.data(),K*2,hipMemcpyHostToDevice));
  hipModule_t cm{},rm{}; hipFunction_t cf{},rf{};
  CHK(hipModuleLoad(&cm,av[2])); CHK(hipModuleLoad(&rm,av[3]));
  CHK(hipModuleGetFunction(
    &cf,cm,"_Z10mxfp4_gemvPKhS0_PK14__hip_bfloat16Pfiii"));
  CHK(hipModuleGetFunction(&rf,rm,"mxfp4_lm_head_decode_gfx1151"));
  auto compiler=[&](int b) {
    CHK(hipMemsetAsync(dyc,0,N*4));
    int n=N,k=K,kchunk=KCHUNK;
    void* args[]={&dp[b],&ds[b],&da,&dyc,&n,&k,&kchunk};
    CHK(hipModuleLaunchKernel(cf,(N+1023)/1024,K/KCHUNK,1,256,1,1,0,nullptr,args,nullptr));
  };
  auto raw=[&](int b) {
    void* args[]={&dp[b],&ds[b],&da,&dyr};
    CHK(hipModuleLaunchKernel(rf,N/512,1,1,128,1,1,0,nullptr,args,nullptr));
  };
  compiler(0); raw(0); CHK(hipDeviceSynchronize());
  std::vector<float> yc(N),yr(N);
  CHK(hipMemcpy(yc.data(),dyc,N*4,hipMemcpyDeviceToHost));
  CHK(hipMemcpy(yr.data(),dyr,N*4,hipMemcpyDeviceToHost));
  double ma=0,mr=0;
  for(int n=0;n<N;++n) {
    double d=double(yc[n])-yr[n];
    ma=std::max(ma,std::abs(d));
    mr=std::max(mr,std::abs(d)/std::max(std::abs(double(yr[n])),1e-12));
  }
  std::printf("gfx1151 compiler baseline vs fp64-validated raw output: "
              "max_abs=%.6e max_rel=%.6e\n",ma,mr);
  for(int i=0;i<5;++i)compiler(i%NBUF); CHK(hipDeviceSynchronize());
  hipEvent_t a{},z{};CHK(hipEventCreate(&a));CHK(hipEventCreate(&z));
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)compiler(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float cms=0;
  CHK(hipEventElapsedTime(&cms,a,z));
  for(int i=0;i<5;++i)raw(i%NBUF); CHK(hipDeviceSynchronize());
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)raw(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float rms=0;
  CHK(hipEventElapsedTime(&rms,a,z));
  std::printf("gfx1151 LM-head M=1 compiler event (includes output clear): %.3f us\n",
              cms*1000/iters);
  std::printf("gfx1151 LM-head M=1 raw ASM event: %.3f us; speedup %.3fx (measured)\n",
              rms*1000/iters,cms/rms);
  return 0;
}
