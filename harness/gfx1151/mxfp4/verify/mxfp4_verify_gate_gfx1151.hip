// Harness only; the measured kernel is raw AMDGCN assembly.
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

static double e2m1(unsigned x) {
  static constexpr double t[8]={0,.5,1,1.5,2,3,4,6};
  return (x&8)?-t[x&7]:t[x&7];
}
static void read_exact(const char* p,void* d,size_t n) {
  std::ifstream f(p,std::ios::binary);
  if(!f.read((char*)d,n)||size_t(f.gcount())!=n) {
    std::fprintf(stderr,"cannot read %zu bytes from %s\n",n,p); std::exit(4);
  }
}

int main(int ac,char** av) {
  constexpr int E=8,M=12,N=512,K=2048,NBUF=9;
  int iters=ac>1?std::atoi(av[1]):100;
  const char* co=ac>2?av[2]:"./mxfp4_verify_gate_gfx1151.hsaco";
  hipDeviceProp_t prop{}; CHK(hipGetDeviceProperties(&prop,0));
  if(std::string(prop.gcnArchName).find("gfx1151")==std::string::npos) return 2;
  size_t np=size_t(E)*(K/2)*N, ns=size_t(E)*(K/32)*N;
  size_t na=size_t(M)*K, ny=size_t(E)*M*N;
  std::vector<unsigned char> hp(np),hs(ns);
  std::vector<unsigned short> hab(na);
  std::vector<float> ha(na);
  std::mt19937 g(3); std::uniform_int_distribution<int> q(0,15),ex(121,130);
  std::uniform_real_distribution<float> af(-1,1);
  if(ac>4) {
    read_exact(av[3],hp.data(),hp.size()); read_exact(av[4],hs.data(),hs.size());
    std::printf("using real checkpoint MXFP4 weights: %s and %s\n",av[3],av[4]);
  } else {
    for(auto&x:hp)x=unsigned(q(g)|(q(g)<<4));
    for(auto&x:hs)x=unsigned(ex(g));
  }
  for(size_t i=0;i<na;++i) {
    __hip_bfloat16 b=__float2bfloat16(af(g));
    std::memcpy(&hab[i],&b,2); ha[i]=__bfloat162float(b);
  }
  unsigned char *dp[NBUF]{},*ds[NBUF]{}; __hip_bfloat16* da{}; float*dy{};
  for(int b=0;b<NBUF;++b) {
    CHK(hipMalloc(&dp[b],np)); CHK(hipMalloc(&ds[b],ns));
    CHK(hipMemcpy(dp[b],hp.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(ds[b],hs.data(),ns,hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da,na*2)); CHK(hipMalloc(&dy,ny*4));
  CHK(hipMemcpy(da,hab.data(),na*2,hipMemcpyHostToDevice));
  hipModule_t mod{}; hipFunction_t fn{};
  CHK(hipModuleLoad(&mod,co));
  CHK(hipModuleGetFunction(&fn,mod,"mxfp4_verify_gate_gfx1151"));
  auto launch=[&](int b){void* args[]={&dp[b],&ds[b],&da,&dy};
    CHK(hipModuleLaunchKernel(fn,4,E,1,32,1,1,0,nullptr,args,nullptr));};
  launch(0); CHK(hipDeviceSynchronize());
  std::vector<float> got(ny); CHK(hipMemcpy(got.data(),dy,ny*4,hipMemcpyDeviceToHost));
  double ma=0,mr=0,se2=0,sr2=0;
  for(int e=0;e<E;++e)for(int m=0;m<M;++m)for(int n=0;n<N;++n) {
    double r=0;
    for(int k=0;k<K;++k) {
      unsigned char b=hp[(size_t(e)*(K/2)+k/2)*N+n];
      unsigned c=(k&1)?b>>4:b&15;
      int sx=hs[(size_t(e)*(K/32)+k/32)*N+n];
      r+=e2m1(c)*std::ldexp(double(ha[size_t(m)*K+k]),sx-127);
    }
    double er=double(got[(size_t(e)*M+m)*N+n])-r;
    ma=std::max(ma,std::abs(er)); mr=std::max(mr,std::abs(er)/std::max(std::abs(r),1e-12));
    se2+=er*er; sr2+=r*r;
  }
  double nl2=std::sqrt(se2/sr2);
  bool ok=ma<5e-4&&nl2<2e-5;
  std::printf("gfx1151 raw ASM M=12 correctness vs fp64: max_abs=%.6e "
              "max_rel=%.6e nl2=%.6e %s\n",ma,mr,nl2,ok?"PASS":"FAIL");
  if(!ok)return 3;
  for(int i=0;i<20;++i)launch(i%NBUF); CHK(hipDeviceSynchronize());
  hipEvent_t a{},z{}; CHK(hipEventCreate(&a));CHK(hipEventCreate(&z));
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)launch(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float ms=0;
  CHK(hipEventElapsedTime(&ms,a,z));double us=ms*1000/iters;
  double bytes=np+ns+na*2+ny*4;
  std::printf("gfx1151 raw ASM MXFP4 verify E=8 M=12 N=512 K=2048: "
              "%.3f us %.1f GB/s %.3f TFLOP/s (measured)\n",us,
              bytes/(us*1e-6)/1e9,2.0*E*M*N*K/(us*1e-6)/1e12);
  return 0;
}
