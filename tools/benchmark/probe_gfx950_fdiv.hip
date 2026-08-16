// SPDX-License-Identifier: MIT
//
// Compiler probe only: recover the installed ROCm gfx950 IEEE f32 division
// sequence for transcription into hand-written AMDGCN kernels.
#include <hip/hip_runtime.h>

extern "C" __global__ void probe_gfx950_fdiv(float* output,
                                              const float* numerator,
                                              const float* denominator) {
  const unsigned index = blockIdx.x * blockDim.x + threadIdx.x;
  output[index] = numerator[index] / denominator[index];
}
