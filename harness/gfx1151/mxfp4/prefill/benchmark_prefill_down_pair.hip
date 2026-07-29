// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>
#define CHK(x) do { hipError_t e=(x); if(e!=hipSuccess){std::fprintf(stderr,"%s: %s\n",#x,hipGetErrorString(e));return 2;} } while(0)
__global__ void fill_u8(uint8_t* p,size_t n,uint32_t salt,int scales){size_t i=size_t(blockIdx.x)*blockDim.x+threadIdx.x;if(i<n){uint32_t x=uint32_t(i)^salt;x^=x<<13;x^=x>>17;x^=x<<5;p[i]=scales?uint8_t(120+x%15):uint8_t(x);}}
__global__ void fill_bf16(uint16_t* p,size_t n){size_t i=size_t(blockIdx.x)*blockDim.x+threadIdx.x;if(i<n)p[i]=(i&1)?0xbf80:0x3f80;}
__global__ void compare_u32(const uint32_t*a,const uint32_t*b,size_t n,unsigned*bad){size_t i=size_t(blockIdx.x)*blockDim.x+threadIdx.x;if(i<n&&a[i]!=b[i])atomicExch(bad,1u);}
struct Mod{hipModule_t m{};hipFunction_t f{};};
int main(int ac,char**av){if(ac<3){std::fprintf(stderr,"usage: %s baseline.hsaco pair.hsaco [groups]\n",av[0]);return 2;}const int G=ac>3?std::atoi(av[3]):1280,E=128,N=2048,M=64,K=512,reps=9;
  if(G&1){std::fprintf(stderr,"groups must be even\n");return 2;}
  Mod m[2];const char* names[2]={"mxfp4_prefill_down_wmma_gfx1151","mxfp4_prefill_down_pair_wmma_gfx1151"};for(int i=0;i<2;i++){CHK(hipModuleLoad(&m[i].m,av[i+1]));CHK(hipModuleGetFunction(&m[i].f,m[i].m,names[i]));}
  size_t np=size_t(E)*(K/2)*N,ns=size_t(E)*(K/32)*N,na=size_t(G)*M*K,no=size_t(G)*M*N;uint8_t *p,*s;uint16_t*a;float*o[2];unsigned*ids,*bad;CHK(hipMalloc(&p,np));CHK(hipMalloc(&s,ns));CHK(hipMalloc(&a,na*2));CHK(hipMalloc(&o[0],no*4));CHK(hipMalloc(&o[1],no*4));CHK(hipMalloc(&ids,G*4));CHK(hipMalloc(&bad,4));
  fill_u8<<<(np+255)/256,256>>>(p,np,1151,0);fill_u8<<<(ns+255)/256,256>>>(s,ns,395,1);fill_bf16<<<(na+255)/256,256>>>(a,na);std::vector<unsigned> hi(G);int per=(G+E-1)/E;for(int g=0;g<G;g++)hi[g]=std::min(g/per,E-1);CHK(hipMemcpy(ids,hi.data(),G*4,hipMemcpyHostToDevice));
  auto launch=[&](int i){void*args[]={&p,&s,&a,&o[i],&ids};return hipModuleLaunchKernel(m[i].f,N/16,i?G/2:G,1,32,1,1,0,nullptr,args,nullptr);};for(int i=0;i<3;i++){CHK(launch(0));CHK(launch(1));}CHK(hipDeviceSynchronize());CHK(hipMemset(bad,0,4));compare_u32<<<(no+255)/256,256>>>((uint32_t*)o[0],(uint32_t*)o[1],no,bad);unsigned hbad=1;CHK(hipMemcpy(&hbad,bad,4,hipMemcpyDeviceToHost));
  std::vector<float> ts[2];for(int r=0;r<reps;r++){int first=r&1;for(int q=0;q<2;q++){int i=q?1-first:first;hipEvent_t x,y;CHK(hipEventCreate(&x));CHK(hipEventCreate(&y));CHK(hipEventRecord(x));CHK(launch(i));CHK(hipEventRecord(y));CHK(hipEventSynchronize(y));float v;CHK(hipEventElapsedTime(&v,x,y));ts[i].push_back(v);CHK(hipEventDestroy(x));CHK(hipEventDestroy(y));}}for(int i=0;i<2;i++)std::sort(ts[i].begin(),ts[i].end());std::printf("gfx1151 measured G=%d byte_equal=%s default_median_ms=%.6f pair_median_ms=%.6f speedup=%.6f\n",G,hbad?"false":"true",ts[0][reps/2],ts[1][reps/2],ts[0][reps/2]/ts[1][reps/2]);for(int i=0;i<2;i++){std::printf("%s_samples_ms=",i?"pair":"default");for(float v:ts[i])std::printf("%.6f,",v);std::printf("\n");}return hbad?3:0;}
