// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <iostream>

namespace {
constexpr uint32_t kN = 12288;
constexpr uint32_t kK = 2048;
constexpr uint32_t kGroups = 128;
constexpr uint32_t kMPerGroup = 64;

struct alignas(8) Args {
  const void* packed;
  const void* scales;
  const void* activation;
  void* output;
  uint32_t n;
  uint32_t k;
};
static_assert(sizeof(Args) == 40);
static_assert(alignof(Args) == 8);

int fail(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}

hipError_t launch(hipFunction_t function, const Args& args, hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, const_cast<Args*>(&args),
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
      HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(function, kN / 16, kGroups, 1, 32, 1, 1, 0,
                               stream, nullptr, config);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc < 3 || argc > 4) {
    std::cerr << "usage: " << argv[0] << " HSACO SYMBOL [ITERATIONS]\n";
    return 2;
  }
  const int iterations = argc == 4 ? std::atoi(argv[3]) : 1;
  if (iterations < 1) return 2;

  hipDeviceProp_t properties{};
  if (int rc = fail(hipGetDeviceProperties(&properties, 0),
                    "hipGetDeviceProperties")) return rc;
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos)
    return 3;

  hipModule_t module{};
  hipFunction_t function{};
  if (int rc = fail(hipModuleLoad(&module, argv[1]), "hipModuleLoad")) return rc;
  if (int rc = fail(hipModuleGetFunction(&function, module, argv[2]),
                    "hipModuleGetFunction")) return rc;

  const size_t packed_bytes = size_t(kK / 2) * kN;
  const size_t scale_bytes = size_t(kK / 32) * kN;
  const size_t activation_bytes = size_t(kGroups) * kMPerGroup * kK * 2;
  const size_t output_bytes = size_t(kGroups) * kMPerGroup * kN * 4;
  void* packed{};
  void* scales{};
  void* activation{};
  void* output{};
  if (int rc = fail(hipMalloc(&packed, packed_bytes), "hipMalloc packed")) return rc;
  if (int rc = fail(hipMalloc(&scales, scale_bytes), "hipMalloc scales")) return rc;
  if (int rc = fail(hipMalloc(&activation, activation_bytes),
                    "hipMalloc activation")) return rc;
  if (int rc = fail(hipMalloc(&output, output_bytes), "hipMalloc output")) return rc;
  if (int rc = fail(hipMemset(packed, 0, packed_bytes), "hipMemset packed")) return rc;
  if (int rc = fail(hipMemset(scales, 0, scale_bytes), "hipMemset scales")) return rc;
  if (int rc = fail(hipMemset(activation, 0, activation_bytes),
                    "hipMemset activation")) return rc;

  hipStream_t stream{};
  if (int rc = fail(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  const Args args{packed, scales, activation, output, kN, kK};
  if (int rc = fail(launch(function, args, stream), "warmup launch")) return rc;
  if (int rc = fail(hipStreamSynchronize(stream), "warmup sync")) return rc;

  hipEvent_t begin{}, end{};
  if (int rc = fail(hipEventCreate(&begin), "hipEventCreate begin")) return rc;
  if (int rc = fail(hipEventCreate(&end), "hipEventCreate end")) return rc;
  if (int rc = fail(hipEventRecord(begin, stream), "hipEventRecord begin")) return rc;
  for (int i = 0; i < iterations; ++i) {
    if (int rc = fail(launch(function, args, stream), "measured launch")) return rc;
  }
  if (int rc = fail(hipEventRecord(end, stream), "hipEventRecord end")) return rc;
  if (int rc = fail(hipEventSynchronize(end), "hipEventSynchronize")) return rc;
  float elapsed_ms = 0.0f;
  if (int rc = fail(hipEventElapsedTime(&elapsed_ms, begin, end),
                    "hipEventElapsedTime")) return rc;
  std::cout << "gfx1151 measured raw MXFP4 N=12288 K=2048 G=128 total_ms="
            << elapsed_ms << " mean_ms=" << elapsed_ms / iterations << "\n";

  (void)hipEventDestroy(begin);
  (void)hipEventDestroy(end);
  (void)hipStreamDestroy(stream);
  (void)hipFree(output);
  (void)hipFree(activation);
  (void)hipFree(scales);
  (void)hipFree(packed);
  (void)hipModuleUnload(module);
  return 0;
}
