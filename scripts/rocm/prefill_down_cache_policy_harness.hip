#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <algorithm>
#define CHK(x) do{hipError_t e=(x);if(e!=hipSuccess){std::fprintf(stderr,"%s:%s\n",#x,hipGetErrorString(e));return 2;}}while(0)
struct K { hipModule_t m{}; hipFunction_t f{}; };
int main(int ac,char**av){if(ac<3)return 2;const int G=ac>3?atoi(av[3]):1280,E=128,N=2048,M=64,D=512,iters=9;K ks[2];for(int i=0;i<2;i++){CHK(hipModuleLoad(&ks[i].m,av[1+i]));CHK(hipModuleGetFunction(&ks[i].f,ks[i].m,"mxfp4_prefill_down_wmma_gfx1151"));}
size_t np=size_t(E)*(D/2)*N,ns=size_t(E)*(D/32)*N,na=size_t(G)*M*D,no=size_t(G)*M*N;void *p,*s,*a,*o[2],*ids;CHK(hipMalloc(&p,np));CHK(hipMalloc(&s,ns));CHK(hipMalloc(&a,na*2));CHK(hipMalloc(&o[0],no*4));CHK(hipMalloc(&o[1],no*4));CHK(hipMalloc(&ids,G*4));CHK(hipMemset(p,0,np));CHK(hipMemset(s,127,ns));CHK(hipMemset(a,0,na*2));std::vector<unsigned> hi(G);int per=(G+E-1)/E;for(int g=0;g<G;g++)hi[g]=std::min(g/per,E-1);CHK(hipMemcpy(ids,hi.data(),G*4,hipMemcpyHostToDevice));
auto launch=[&](int i){void*args[]={&p,&s,&a,&o[i],&ids};CHK(hipModuleLaunchKernel(ks[i].f,N/16,G,1,32,1,1,0,nullptr,args,nullptr));return 0;};
for(int w=0;w<2;w++){launch(0);launch(1);}CHK(hipDeviceSynchronize());
for(int which=0;which<2;which++){std::vector<float>ms;for(int r=0;r<iters;r++){hipEvent_t x,y;CHK(hipEventCreate(&x));CHK(hipEventCreate(&y));CHK(hipEventRecord(x));launch(which);CHK(hipEventRecord(y));CHK(hipEventSynchronize(y));float t;CHK(hipEventElapsedTime(&t,x,y));ms.push_back(t);hipEventDestroy(x);hipEventDestroy(y);}std::sort(ms.begin(),ms.end());std::printf("%s median_ms=%.6f samples=",which?"glc":"default",ms[iters/2]);for(float x:ms)std::printf("%.6f,",x);std::printf("\n");}
std::vector<unsigned char>x(no*4),y(no*4);CHK(hipMemcpy(x.data(),o[0],x.size(),hipMemcpyDeviceToHost));CHK(hipMemcpy(y.data(),o[1],y.size(),hipMemcpyDeviceToHost));std::printf("gfx1151 measured G=%d byte_equal=%s\n",G,x==y?"true":"false");return x==y?0:3;}
