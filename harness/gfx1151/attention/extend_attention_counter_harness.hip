// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>
#include <cstdio>
#include <vector>

extern "C" int netra_extend_attention_wmma_init(const char*);
extern "C" int netra_extend_attention_wmma(
    void*, void*, void*, void*, void*, void*, void*, void*,
    uint32_t, float, hipStream_t);

#define HIP_CHECK(expr) do { hipError_t e=(expr); if(e!=hipSuccess) { \
  std::fprintf(stderr, "%s: %s\n", #expr, hipGetErrorString(e)); return 2; } } while(0)

int main(int argc, char** argv) {
  if (argc < 2) {
    std::fprintf(stderr, "usage: %s HSACO [tokens] [prefix]\n", argv[0]);
    return 2;
  }
  const uint32_t tokens = argc > 2 ? std::stoul(argv[2]) : 8192;
  const uint32_t prefix = argc > 3 ? std::stoul(argv[3]) : 24576;
  if (!tokens || (tokens & 63)) return 2;
  void *q=nullptr,*k=nullptr,*v=nullptr,*o=nullptr,*kb=nullptr,*vb=nullptr;
  void *indices=nullptr,*indptr=nullptr;
  const size_t bf16 = 2;
  HIP_CHECK(hipMalloc(&q, size_t(tokens)*16*256*bf16));
  HIP_CHECK(hipMalloc(&k, size_t(tokens)*2*256*bf16));
  HIP_CHECK(hipMalloc(&v, size_t(tokens)*2*256*bf16));
  HIP_CHECK(hipMalloc(&o, size_t(tokens)*16*256*bf16));
  HIP_CHECK(hipMalloc(&kb, size_t(prefix ? prefix : 1)*2*256*bf16));
  HIP_CHECK(hipMalloc(&vb, size_t(prefix ? prefix : 1)*2*256*bf16));
  HIP_CHECK(hipMalloc(&indices, size_t(prefix ? prefix : 1)*sizeof(int64_t)));
  HIP_CHECK(hipMalloc(&indptr, 2*sizeof(int32_t)));
  HIP_CHECK(hipMemset(q, 0, size_t(tokens)*16*256*bf16));
  HIP_CHECK(hipMemset(k, 0, size_t(tokens)*2*256*bf16));
  HIP_CHECK(hipMemset(v, 0, size_t(tokens)*2*256*bf16));
  HIP_CHECK(hipMemset(kb, 0, size_t(prefix ? prefix : 1)*2*256*bf16));
  HIP_CHECK(hipMemset(vb, 0, size_t(prefix ? prefix : 1)*2*256*bf16));
  std::vector<int64_t> host_indices(prefix ? prefix : 1);
  for (uint32_t i=0; i<prefix; ++i) host_indices[i]=i;
  const int32_t host_indptr[2] = {0, static_cast<int32_t>(prefix)};
  HIP_CHECK(hipMemcpy(indices, host_indices.data(), host_indices.size()*sizeof(int64_t), hipMemcpyHostToDevice));
  HIP_CHECK(hipMemcpy(indptr, host_indptr, sizeof(host_indptr), hipMemcpyHostToDevice));
  int rc=netra_extend_attention_wmma_init(argv[1]);
  if (rc) { std::fprintf(stderr, "module init: %s\n", hipGetErrorString((hipError_t)rc)); return 2; }
  rc=netra_extend_attention_wmma(q,k,v,o,kb,vb,indices,indptr,tokens,0.0625f,nullptr);
  if (rc) { std::fprintf(stderr, "launch: %s\n", hipGetErrorString((hipError_t)rc)); return 2; }
  HIP_CHECK(hipDeviceSynchronize());
  std::printf("gfx1151 measured dispatch tokens=%u prefix=%u\n",tokens,prefix);
  HIP_CHECK(hipFree(indptr));
  HIP_CHECK(hipFree(indices));
  HIP_CHECK(hipFree(vb));
  HIP_CHECK(hipFree(kb));
  HIP_CHECK(hipFree(o));
  HIP_CHECK(hipFree(v));
  HIP_CHECK(hipFree(k));
  HIP_CHECK(hipFree(q));
  return 0;
}
