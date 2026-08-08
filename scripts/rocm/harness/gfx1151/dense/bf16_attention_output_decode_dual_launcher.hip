// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstddef>

namespace {
struct Kernel {
  hipModule_t module{};
  hipFunction_t function{};
};
Kernel kernels[2];

struct alignas(8) Args {
  const void* weights;
  const void* activation;
  void* output;
};
static_assert(sizeof(Args) == 24);

hipError_t load(Kernel& kernel, const char* hsaco, const char* symbol) {
  hipError_t status = hipModuleLoad(&kernel.module, hsaco);
  if (status != hipSuccess) return status;
  return hipModuleGetFunction(&kernel.function, kernel.module, symbol);
}

hipError_t launch(const Kernel& kernel, const Args& args, hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, const_cast<Args*>(&args),
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
      HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(kernel.function, 256, 1, 1, 256, 1, 1, 0,
                               stream, nullptr, config);
}
}  // namespace

extern "C" int netra_bf16_attention_output_dual_load(
    const char* baseline_hsaco, const char* candidate_hsaco) {
  if (kernels[0].function || kernels[1].function)
    return static_cast<int>(hipErrorAlreadyAcquired);
  hipError_t status = load(kernels[0], baseline_hsaco,
                           "bf16_attn_oproj_decode_wave1_gfx1151");
  if (status != hipSuccess) return static_cast<int>(status);
  status = load(kernels[1], candidate_hsaco,
                "bf16_attn_oproj_decode_wave1_wide128_gfx1151");
  return static_cast<int>(status);
}

extern "C" int netra_bf16_attention_output_dual_launch(
    int variant, const void* weights, const void* activation, void* output,
    hipStream_t stream) {
  if (variant < 0 || variant > 1) return static_cast<int>(hipErrorInvalidValue);
  if (!kernels[variant].function)
    return static_cast<int>(hipErrorNotInitialized);
  const Args args{weights, activation, output};
  return static_cast<int>(launch(kernels[variant], args, stream));
}
