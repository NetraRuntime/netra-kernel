// Harness only; the measured LM-head verify kernel is raw AMDGCN assembly.
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
#include <thread>
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

struct Error {
  double ma=0,mr=0,se2=0,sr2=0;
};

int main(int ac,char** av) {
  constexpr int M=12,MPAD=16,N=248320,K=2048,NBUF=4;
  if(ac<5) {
    std::fprintf(stderr,"usage: %s iters code.hsaco packed.bin scales.bin\n",av[0]);
    return 4;
  }
  int iters=std::atoi(av[1]); const char* co=av[2];
  hipDeviceProp_t prop{}; CHK(hipGetDeviceProperties(&prop,0));
  if(std::string(prop.gcnArchName).find("gfx1151")==std::string::npos) return 2;
  size_t np=size_t(K/2)*N, ns=size_t(K/32)*N, nap=size_t(MPAD)*K, ny=size_t(M)*N;
  std::vector<unsigned char> hp(np),hs(ns);
  read_exact(av[3],hp.data(),np); read_exact(av[4],hs.data(),ns);
  std::printf("using real MXFP4 LM head: %s and %s\n",av[3],av[4]);

  std::mt19937 g(19); std::uniform_real_distribution<float> af(-1,1);
  std::vector<unsigned short> hab(nap,0); std::vector<float> ha(size_t(M)*K);
  for(int m=0;m<M;++m)for(int k=0;k<K;++k) {
    __hip_bfloat16 b=__float2bfloat16(af(g));
    std::memcpy(&hab[size_t(m)*K+k],&b,2); ha[size_t(m)*K+k]=__bfloat162float(b);
  }
  unsigned char *dp[NBUF]{},*ds[NBUF]{}; __hip_bfloat16*da{}; float*dy{};
  for(int b=0;b<NBUF;++b) {
    CHK(hipMalloc(&dp[b],np)); CHK(hipMalloc(&ds[b],ns));
    CHK(hipMemcpy(dp[b],hp.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(ds[b],hs.data(),ns,hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da,nap*2)); CHK(hipMalloc(&dy,ny*4));
  CHK(hipMemcpy(da,hab.data(),nap*2,hipMemcpyHostToDevice));
  hipModule_t mod{}; hipFunction_t fn{};
  CHK(hipModuleLoad(&mod,co));
  CHK(hipModuleGetFunction(&fn,mod,"mxfp4_lm_head_verify_wmma_gfx1151"));
  auto launch=[&](int b){void* args[]={&dp[b],&ds[b],&da,&dy};
    CHK(hipModuleLaunchKernel(fn,N/16,1,1,32,1,1,0,nullptr,args,nullptr));};
  launch(0); CHK(hipDeviceSynchronize());
  std::vector<float> got(ny); CHK(hipMemcpy(got.data(),dy,ny*4,hipMemcpyDeviceToHost));

  unsigned nt=std::max(1u,std::min(32u,std::thread::hardware_concurrency()));
  std::vector<Error> errors(nt); std::vector<std::thread> workers;
  for(unsigned tid=0;tid<nt;++tid) workers.emplace_back([&,tid] {
    int begin=int((uint64_t(N)*tid)/nt),end=int((uint64_t(N)*(tid+1))/nt);
    Error er{};
    for(int n=begin;n<end;++n) {
      double acc[M]{};
      for(int kb=0;kb<K/32;++kb) {
        double block[M]{};
        for(int p=0;p<16;++p) {
          unsigned char b=hp[(size_t(kb)*16+p)*N+n];
          double w0=e2m1(b&15),w1=e2m1(b>>4);
          int k=kb*32+p*2;
          for(int m=0;m<M;++m)
            block[m]+=w0*double(ha[size_t(m)*K+k])+w1*double(ha[size_t(m)*K+k+1]);
        }
        double scale=std::ldexp(1.0,int(hs[size_t(kb)*N+n])-127);
        for(int m=0;m<M;++m) acc[m]+=block[m]*scale;
      }
      for(int m=0;m<M;++m) {
        double d=double(got[size_t(m)*N+n])-acc[m];
        er.ma=std::max(er.ma,std::abs(d));
        er.mr=std::max(er.mr,std::abs(d)/std::max(std::abs(acc[m]),1e-12));
        er.se2+=d*d; er.sr2+=acc[m]*acc[m];
      }
    }
    errors[tid]=er;
  });
  for(auto&t:workers)t.join();
  Error er{};
  for(auto x:errors) {
    er.ma=std::max(er.ma,x.ma); er.mr=std::max(er.mr,x.mr);
    er.se2+=x.se2; er.sr2+=x.sr2;
  }
  double nl2=std::sqrt(er.se2/er.sr2); bool ok=er.ma<2e-5&&nl2<2e-5;
  std::printf("gfx1151 raw ASM MXFP4 LM-head M=12 correctness vs fp64: "
              "max_abs=%.6e max_rel=%.6e nl2=%.6e %s\n",er.ma,er.mr,nl2,ok?"PASS":"FAIL");
  if(!ok)return 3;

  for(int i=0;i<5;++i)launch(i%NBUF); CHK(hipDeviceSynchronize());
  hipEvent_t a{},z{}; CHK(hipEventCreate(&a));CHK(hipEventCreate(&z));
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)launch(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float ms=0;
  CHK(hipEventElapsedTime(&ms,a,z));double us=ms*1000/iters;
  double bytes=np+ns+nap*2+ny*4;
  std::printf("gfx1151 raw ASM WMMA MXFP4 LM-head verify M=12 N=248320 K=2048: "
              "%.3f us %.1f GB/s %.3f TFLOP/s (measured)\n",us,
              bytes/(us*1e-6)/1e9,2.0*M*N*K/(us*1e-6)/1e12);
  return 0;
}
