// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#define HIP_CHECK(x) do { hipError_t e=(x); if(e!=hipSuccess) throw std::runtime_error(hipGetErrorString(e)); } while(0)

static std::vector<uint8_t> read_file(const std::string& path) {
  std::ifstream f(path, std::ios::binary|std::ios::ate);
  if(!f) throw std::runtime_error("cannot open "+path);
  auto n=f.tellg(); f.seekg(0); std::vector<uint8_t> v(static_cast<size_t>(n));
  f.read(reinterpret_cast<char*>(v.data()),n); return v;
}
struct Buffer { void* p=nullptr; explicit Buffer(size_t n){HIP_CHECK(hipMalloc(&p,n));} ~Buffer(){if(p) hipFree(p);} };
static double pct(std::vector<float> v,double q){std::sort(v.begin(),v.end());double x=q*(v.size()-1);size_t a=x,b=std::min(a+1,v.size()-1);return v[a]+(v[b]-v[a])*(x-a);}

int main(int argc,char** argv){
 try {
  if(argc<3||argc>4){std::cerr<<"usage: "<<argv[0]<<" KERNEL.hsaco CAPTURE_DIR [iterations=100]\n";return 2;}
  const int iterations=argc==4?std::stoi(argv[3]):100;
  hipDeviceProp_t props{}; HIP_CHECK(hipGetDeviceProperties(&props,0));
  if(std::string(props.gcnArchName).rfind("gfx950",0)!=0) throw std::runtime_error("non-gfx950");
  const std::string root=argv[2];
  auto input=read_file(root+"/activation_bf16.bin");
  auto reference=read_file(root+"/activation_fp8.bin");
  auto reference_scales=read_file(root+"/activation_scale_f32.bin");
  constexpr int routes=1024*9;
  if(input.size()!=static_cast<size_t>(routes)*512*2||reference.size()!=static_cast<size_t>(routes)*512) throw std::runtime_error("shape");
  Buffer d_in(input.size()),d_out(reference.size()),d_scale(reference_scales.size());
  HIP_CHECK(hipMemcpy(d_in.p,input.data(),input.size(),hipMemcpyHostToDevice));
  hipModule_t module{}; hipFunction_t fn{}; HIP_CHECK(hipModuleLoad(&module,argv[1]));
  HIP_CHECK(hipModuleGetFunction(&fn,module,"qwen36_moe_quant_bf16_m64_fp8_gfx950"));
  int route_count=routes; void* args[]={&d_in.p,&d_out.p,&d_scale.p,&route_count};
  auto launch=[&]{HIP_CHECK(hipModuleLaunchKernel(fn,(routes+3)/4,1,1,256,1,1,0,nullptr,args,nullptr));};
  for(int i=0;i<5;++i)launch(); HIP_CHECK(hipDeviceSynchronize());
  hipEvent_t start{},stop{};HIP_CHECK(hipEventCreate(&start));HIP_CHECK(hipEventCreate(&stop));
  std::vector<float> samples;
  for(int i=0;i<iterations;++i){HIP_CHECK(hipEventRecord(start));launch();HIP_CHECK(hipEventRecord(stop));HIP_CHECK(hipEventSynchronize(stop));float ms=0;HIP_CHECK(hipEventElapsedTime(&ms,start,stop));samples.push_back(ms*1000);}
  std::vector<uint8_t> output(reference.size());std::vector<uint8_t> scale_bytes(reference_scales.size());
  HIP_CHECK(hipMemcpy(output.data(),d_out.p,output.size(),hipMemcpyDeviceToHost));
  HIP_CHECK(hipMemcpy(scale_bytes.data(),d_scale.p,scale_bytes.size(),hipMemcpyDeviceToHost));
  size_t mismatch=0;for(size_t i=0;i<output.size();++i)mismatch+=output[i]!=reference[i];
  const float* a=reinterpret_cast<const float*>(scale_bytes.data());const float* b=reinterpret_cast<const float*>(reference_scales.data());
  double max_abs=0;for(size_t i=0;i<scale_bytes.size()/4;++i)max_abs=std::max(max_abs,std::abs(double(a[i])-b[i]));
  bool correct=mismatch==0&&max_abs<=1e-12;
  std::cout<<"architecture="<<props.gcnArchName<<"\nroutes="<<routes<<"\nbyte_mismatches="<<mismatch<<"/"<<output.size()<<"\nscale_max_abs="<<max_abs<<"\ncorrectness_gate="<<(correct?"pass":"fail")<<"\nmedian_us="<<pct(samples,.5)<<"\np90_us="<<pct(samples,.9)<<"\n";
  HIP_CHECK(hipEventDestroy(start));HIP_CHECK(hipEventDestroy(stop));HIP_CHECK(hipModuleUnload(module));return correct?0:1;
 } catch(const std::exception& e){std::cerr<<"error: "<<e.what()<<"\n";return 2;}
}
