// Harness only; the measured fused kernel is hand-written AMDGCN assembly.
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
static float bf16_to_float(unsigned short bits) {
  __hip_bfloat16 b; std::memcpy(&b,&bits,2); return __bfloat162float(b);
}

int main(int ac,char** av) {
  constexpr int E=8,N=512,K=2048,NBUF=16;
  if(ac<7) {
    std::fprintf(stderr,
      "usage: %s iters code.hsaco gate_p gate_s up_p up_s\n",av[0]);
    return 4;
  }
  int iters=std::atoi(av[1]); const char* co=av[2];
  int tile_cols=ac>7?std::atoi(av[7]):128;
  if(tile_cols!=64&&tile_cols!=128) return 4;
  hipDeviceProp_t prop{}; CHK(hipGetDeviceProperties(&prop,0));
  if(std::string(prop.gcnArchName).find("gfx1151")==std::string::npos) return 2;
  size_t np=size_t(E)*(K/2)*N,ns=size_t(E)*(K/32)*N;
  std::vector<unsigned char> hgp(np),hgs(ns),hup(np),hus(ns);
  read_exact(av[3],hgp.data(),np); read_exact(av[4],hgs.data(),ns);
  read_exact(av[5],hup.data(),np); read_exact(av[6],hus.data(),ns);
  std::vector<unsigned short> hab(K); std::vector<float> ha(K);
  std::mt19937 g(23); std::uniform_real_distribution<float> af(-1,1);
  for(int k=0;k<K;++k) {
    __hip_bfloat16 b=__float2bfloat16(af(g));
    std::memcpy(&hab[k],&b,2); ha[k]=__bfloat162float(b);
  }

  unsigned char *dgp[NBUF]{},*dgs[NBUF]{},*dup[NBUF]{},*dus[NBUF]{};
  __hip_bfloat16 *da{},*dy{};
  for(int b=0;b<NBUF;++b) {
    CHK(hipMalloc(&dgp[b],np)); CHK(hipMalloc(&dgs[b],ns));
    CHK(hipMalloc(&dup[b],np)); CHK(hipMalloc(&dus[b],ns));
    CHK(hipMemcpy(dgp[b],hgp.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(dgs[b],hgs.data(),ns,hipMemcpyHostToDevice));
    CHK(hipMemcpy(dup[b],hup.data(),np,hipMemcpyHostToDevice));
    CHK(hipMemcpy(dus[b],hus.data(),ns,hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da,K*2)); CHK(hipMalloc(&dy,E*N*2));
  CHK(hipMemcpy(da,hab.data(),K*2,hipMemcpyHostToDevice));
  hipModule_t mod{}; hipFunction_t fn{};
  CHK(hipModuleLoad(&mod,co));
  const char* symbol=tile_cols==64?"mxfp4_decode_gate_up_fused_n64_gfx1151":
                                   "mxfp4_decode_gate_up_fused_gfx1151";
  CHK(hipModuleGetFunction(&fn,mod,symbol));
  auto launch=[&](int b) {
    void* args[]={&dgp[b],&dgs[b],&dup[b],&dus[b],&da,&dy};
    CHK(hipModuleLaunchKernel(fn,N/tile_cols,E,1,32,1,1,0,nullptr,args,nullptr));
  };
  launch(0); CHK(hipDeviceSynchronize());
  std::vector<unsigned short> got(E*N);
  CHK(hipMemcpy(got.data(),dy,E*N*2,hipMemcpyDeviceToHost));
  double ma=0,mr=0,se2=0,sr2=0; size_t bit_mismatch=0;
  for(int e=0;e<E;++e)for(int n=0;n<N;++n) {
    double gate=0,up=0;
    for(int kb=0;kb<K/32;++kb) {
      double gb=0,ub=0;
      for(int p=0;p<16;++p) {
        int k=kb*32+p*2;
        unsigned char gw=hgp[(size_t(e)*(K/2)+kb*16+p)*N+n];
        unsigned char uw=hup[(size_t(e)*(K/2)+kb*16+p)*N+n];
        gb+=e2m1(gw&15)*ha[k]+e2m1(gw>>4)*ha[k+1];
        ub+=e2m1(uw&15)*ha[k]+e2m1(uw>>4)*ha[k+1];
      }
      gate+=std::ldexp(gb,int(hgs[(size_t(e)*(K/32)+kb)*N+n])-127);
      up+=std::ldexp(ub,int(hus[(size_t(e)*(K/32)+kb)*N+n])-127);
    }
    double ref=(gate/(1.0+std::exp(-gate)))*up;
    float actual=bf16_to_float(got[size_t(e)*N+n]);
    __hip_bfloat16 rb=__float2bfloat16(float(ref)); unsigned short refbits;
    std::memcpy(&refbits,&rb,2); bit_mismatch+=refbits!=got[size_t(e)*N+n];
    double er=double(actual)-ref;
    ma=std::max(ma,std::abs(er));
    mr=std::max(mr,std::abs(er)/std::max(std::abs(ref),1e-12));
    se2+=er*er; sr2+=ref*ref;
  }
  double nl2=std::sqrt(se2/sr2);
  bool ok=bit_mismatch==0&&ma<1e-3&&nl2<2e-3;
  std::printf("gfx1151 fused gate/up+SiLU correctness vs fp64: max_abs=%.6e "
              "max_rel=%.6e nl2=%.6e bf16_bit_mismatch=%zu/%d %s\n",
              ma,mr,nl2,bit_mismatch,E*N,ok?"PASS":"FAIL");
  if(!ok)return 3;

  for(int i=0;i<10;++i)launch(i%NBUF); CHK(hipDeviceSynchronize());
  hipEvent_t a{},z{};CHK(hipEventCreate(&a));CHK(hipEventCreate(&z));
  CHK(hipEventRecord(a));for(int i=0;i<iters;++i)launch(i%NBUF);
  CHK(hipEventRecord(z));CHK(hipEventSynchronize(z));float ms=0;
  CHK(hipEventElapsedTime(&ms,a,z));double us=ms*1000/iters;
  double bytes=2.0*(np+ns)+K*2+E*N*2;
  std::printf("gfx1151 raw ASM fused MXFP4 gate/up decode E=8 M=1 N=512 K=2048: "
              "%.3f us %.1f GB/s (measured)\n",us,bytes/(us*1e-6)/1e9);
  return 0;
}
