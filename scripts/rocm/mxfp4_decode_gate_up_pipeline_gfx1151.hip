// Launch/timing harness comparing the selected standalone raw-ASM pipeline
// against the fused raw-ASM experiment. No GPU kernel is defined here.
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
  if(!f.read((char*)d,n)||size_t(f.gcount())!=n) std::exit(4);
}
static float bf16_to_float(unsigned short bits) {
  __hip_bfloat16 b; std::memcpy(&b,&bits,2); return __bfloat162float(b);
}

int main(int ac,char** av) {
  constexpr int E=8,N=512,K=2048,NBUF=16;
  if(ac<9) return 4;
  int iters=std::atoi(av[1]);
  size_t np=size_t(E)*(K/2)*N,ns=size_t(E)*(K/32)*N;
  std::vector<unsigned char> hgp(np),hgs(ns),hup(np),hus(ns);
  read_exact(av[5],hgp.data(),np);read_exact(av[6],hgs.data(),ns);
  read_exact(av[7],hup.data(),np);read_exact(av[8],hus.data(),ns);
  std::vector<unsigned short> hab(K);
  std::mt19937 g(23);std::uniform_real_distribution<float>af(-1,1);
  for(int k=0;k<K;++k){__hip_bfloat16 b=__float2bfloat16(af(g));std::memcpy(&hab[k],&b,2);}
  unsigned char *dgp[NBUF]{},*dgs[NBUF]{},*dup[NBUF]{},*dus[NBUF]{};
  __hip_bfloat16 *da{},*dpipe{},*dfused{};float *dg{},*du{};
  for(int b=0;b<NBUF;++b){
    CHK(hipMalloc(&dgp[b],np));CHK(hipMalloc(&dgs[b],ns));
    CHK(hipMalloc(&dup[b],np));CHK(hipMalloc(&dus[b],ns));
    CHK(hipMemcpy(dgp[b],hgp.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(dgs[b],hgs.data(),ns,hipMemcpyHostToDevice));
    CHK(hipMemcpy(dup[b],hup.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(dus[b],hus.data(),ns,hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da,K*2));CHK(hipMalloc(&dg,E*N*4));CHK(hipMalloc(&du,E*N*4));
  CHK(hipMalloc(&dpipe,E*N*2));CHK(hipMalloc(&dfused,E*N*2));
  CHK(hipMemcpy(da,hab.data(),K*2,hipMemcpyHostToDevice));
  hipModule_t gm{},em{},fm{};hipFunction_t gf{},ef{},ff{};
  CHK(hipModuleLoad(&gm,av[2]));CHK(hipModuleLoad(&em,av[3]));CHK(hipModuleLoad(&fm,av[4]));
  CHK(hipModuleGetFunction(&gf,gm,"mxfp4_decode_gate_gfx1151"));
  CHK(hipModuleGetFunction(&ef,em,"silu_mul_bf16_gfx1151"));
  CHK(hipModuleGetFunction(&ff,fm,"mxfp4_decode_gate_up_fused_gfx1151"));
  auto pipeline=[&](int b){
    CHK(hipMemsetAsync(dg,0,E*N*4));CHK(hipMemsetAsync(du,0,E*N*4));
    void* ga[]={&dgp[b],&dgs[b],&da,&dg};
    void* ua[]={&dup[b],&dus[b],&da,&du};
    CHK(hipModuleLaunchKernel(gf,1,E*2,1,128,1,1,0,nullptr,ga,nullptr));
    CHK(hipModuleLaunchKernel(gf,1,E*2,1,128,1,1,0,nullptr,ua,nullptr));
    void* ea[]={&dg,&du,&dpipe};
    CHK(hipModuleLaunchKernel(ef,(E*N)/256,1,1,256,1,1,0,nullptr,ea,nullptr));
  };
  auto fused=[&](int b){
    void* fa[]={&dgp[b],&dgs[b],&dup[b],&dus[b],&da,&dfused};
    CHK(hipModuleLaunchKernel(ff,N/128,E,1,32,1,1,0,nullptr,fa,nullptr));
  };
  pipeline(0);fused(0);CHK(hipDeviceSynchronize());
  std::vector<unsigned short> p(E*N),f(E*N);
  CHK(hipMemcpy(p.data(),dpipe,E*N*2,hipMemcpyDeviceToHost));
  CHK(hipMemcpy(f.data(),dfused,E*N*2,hipMemcpyDeviceToHost));
  double ma=0;size_t mismatches=0;
  for(int i=0;i<E*N;++i){
    ma=std::max(ma,std::abs(double(bf16_to_float(p[i]))-bf16_to_float(f[i])));
    mismatches+=p[i]!=f[i];
  }
  std::printf("gfx1151 standalone pipeline vs fused BF16: max_abs=%.6e "
              "bit_mismatch=%zu/%d\n",ma,mismatches,E*N);
  for(int i=0;i<10;++i)pipeline(i%NBUF);CHK(hipDeviceSynchronize());
  hipEvent_t a{},z{};CHK(hipEventCreate(&a));CHK(hipEventCreate(&z));
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)pipeline(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float pms=0;
  CHK(hipEventElapsedTime(&pms,a,z));
  for(int i=0;i<10;++i)fused(i%NBUF);CHK(hipDeviceSynchronize());
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)fused(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float fms=0;
  CHK(hipEventElapsedTime(&fms,a,z));
  std::printf("gfx1151 standalone gate+up+SiLU pipeline: %.3f us; fused: %.3f us; "
              "standalone speedup %.3fx (measured)\n",
              pms*1000/iters,fms*1000/iters,fms/pms);
  return 0;
}
