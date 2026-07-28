// Harness only; the measured LM-head kernel is hand-written AMDGCN assembly.
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
  constexpr int N=248320,K=2048,NBUF=4;
  if(ac<5) {
    std::fprintf(stderr,"usage: %s iters code.hsaco packed.bin scales.bin\n",av[0]);
    return 4;
  }
  int iters=std::atoi(av[1]); const char* co=av[2];
  hipDeviceProp_t prop{}; CHK(hipGetDeviceProperties(&prop,0));
  if(std::string(prop.gcnArchName).find("gfx1151")==std::string::npos) return 2;
  size_t np=size_t(K/2)*N, ns=size_t(K/32)*N;
  std::vector<unsigned char> hp(np),hs(ns);
  read_exact(av[3],hp.data(),np); read_exact(av[4],hs.data(),ns);
  std::printf("using real MXFP4 LM head: %s and %s\n",av[3],av[4]);

  std::mt19937 g(17); std::uniform_real_distribution<float> af(-1,1);
  std::vector<unsigned short> hab(K); std::vector<float> ha(K);
  for(int k=0;k<K;++k) {
    __hip_bfloat16 b=__float2bfloat16(af(g));
    std::memcpy(&hab[k],&b,2); ha[k]=__bfloat162float(b);
  }
  unsigned char *dp[NBUF]{},*ds[NBUF]{}; __hip_bfloat16*da{}; float*dy{};
  for(int b=0;b<NBUF;++b) {
    CHK(hipMalloc(&dp[b],np)); CHK(hipMalloc(&ds[b],ns));
    CHK(hipMemcpy(dp[b],hp.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(ds[b],hs.data(),ns,hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da,K*2)); CHK(hipMalloc(&dy,N*4));
  CHK(hipMemcpy(da,hab.data(),K*2,hipMemcpyHostToDevice));
  hipModule_t mod{}; hipFunction_t fn{};
  CHK(hipModuleLoad(&mod,co));
  CHK(hipModuleGetFunction(&fn,mod,"mxfp4_lm_head_decode_gfx1151"));
  auto launch=[&](int b){void* args[]={&dp[b],&ds[b],&da,&dy};
    CHK(hipModuleLaunchKernel(fn,N/512,1,1,128,1,1,0,nullptr,args,nullptr));};
  launch(0); CHK(hipDeviceSynchronize());
  std::vector<float> got(N); CHK(hipMemcpy(got.data(),dy,N*4,hipMemcpyDeviceToHost));

  std::vector<double> ref(N,0.0);
  for(int kb=0;kb<K/32;++kb) {
    for(int n=0;n<N;++n) {
      double block=0;
      for(int p=0;p<16;++p) {
        unsigned char b=hp[(size_t(kb)*16+p)*N+n];
        block+=e2m1(b&15)*double(ha[kb*32+p*2]);
        block+=e2m1(b>>4)*double(ha[kb*32+p*2+1]);
      }
      ref[n]+=std::ldexp(block,int(hs[size_t(kb)*N+n])-127);
    }
  }
  double ma=0,mr=0,se2=0,sr2=0;
  for(int n=0;n<N;++n) {
    double er=double(got[n])-ref[n];
    ma=std::max(ma,std::abs(er)); mr=std::max(mr,std::abs(er)/std::max(std::abs(ref[n]),1e-12));
    se2+=er*er; sr2+=ref[n]*ref[n];
  }
  double nl2=std::sqrt(se2/sr2); bool ok=ma<2e-5&&nl2<2e-5;
  std::printf("gfx1151 raw ASM MXFP4 LM-head decode correctness vs fp64: "
              "max_abs=%.6e max_rel=%.6e nl2=%.6e %s\n",ma,mr,nl2,ok?"PASS":"FAIL");
  if(!ok)return 3;

  for(int i=0;i<5;++i)launch(i%NBUF); CHK(hipDeviceSynchronize());
  hipEvent_t a{},z{}; CHK(hipEventCreate(&a));CHK(hipEventCreate(&z));
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)launch(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float ms=0;
  CHK(hipEventElapsedTime(&ms,a,z));double us=ms*1000/iters;
  double bytes=np+ns+K*2+N*4;
  std::printf("gfx1151 raw ASM MXFP4 LM-head decode M=1 N=248320 K=2048: "
              "%.3f us %.1f GB/s %.3f TFLOP/s (measured)\n",us,
              bytes/(us*1e-6)/1e9,2.0*N*K/(us*1e-6)/1e12);
  return 0;
}
