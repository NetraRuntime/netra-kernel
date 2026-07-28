#include <hip/hip_runtime.h>

extern "C" __global__ void meta_probe(
    const void* a, const void* b, const void* c, void* d,
    unsigned n, unsigned k) {
  if (threadIdx.x == 0) {
    static_cast<unsigned*>(d)[0] = n;
    static_cast<unsigned*>(d)[1] = k;
  }
}
