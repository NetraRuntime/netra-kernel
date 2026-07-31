// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <iostream>

namespace {
constexpr size_t kN = 9216;
constexpr size_t kK = 2048;

struct alignas(8) Args {
  const void* weights;
  const void* activation;
  void* output;
};
static_assert(sizeof(Args) == 24);

int fail(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}

hipError_t launch(hipFunction_t function, const Args& args,
                  unsigned grid, unsigned block, hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, const_cast<Args*>(&args),
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
      HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(function, grid, 1, 1, block, 1, 1, 0,
                               stream, nullptr, config);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc < 5 || argc > 6) {
    std::cerr << "usage: " << argv[0]
              << " HSACO SYMBOL GRID BLOCK [ITERATIONS]\n";
    return 2;
  }
  const unsigned grid = std::strtoul(argv[3], nullptr, 10);
  const unsigned block = std::strtoul(argv[4], nullptr, 10);
  const int iterations = argc == 6 ? std::atoi(argv[5]) : 1;
  if (grid < 1 || block < 1 || iterations < 1) return 2;

  hipModule_t module{};
  hipFunction_t function{};
  if (int rc = fail(hipModuleLoad(&module, argv[1]), "hipModuleLoad")) return rc;
  if (int rc = fail(hipModuleGetFunction(
          &function, module, argv[2]),
          "hipModuleGetFunction")) return rc;

  void* weights{};
  void* activation{};
  void* output{};
  if (int rc = fail(hipMalloc(&weights, kN * kK * sizeof(uint16_t)),
                    "hipMalloc weights")) return rc;
  if (int rc = fail(hipMalloc(&activation, kK * sizeof(uint16_t)),
                    "hipMalloc activation")) return rc;
  if (int rc = fail(hipMalloc(&output, kN * sizeof(uint16_t)),
                    "hipMalloc output")) return rc;
  if (int rc = fail(hipMemset(weights, 0, kN * kK * sizeof(uint16_t)),
                    "hipMemset weights")) return rc;
  if (int rc = fail(hipMemset(activation, 0, kK * sizeof(uint16_t)),
                    "hipMemset activation")) return rc;

  hipStream_t stream{};
  if (int rc = fail(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  const Args args{weights, activation, output};
  if (int rc = fail(launch(function, args, grid, block, stream), "warmup launch")) return rc;
  if (int rc = fail(hipStreamSynchronize(stream), "warmup sync")) return rc;

  hipEvent_t begin{}, end{};
  if (int rc = fail(hipEventCreate(&begin), "hipEventCreate begin")) return rc;
  if (int rc = fail(hipEventCreate(&end), "hipEventCreate end")) return rc;
  if (int rc = fail(hipEventRecord(begin, stream), "hipEventRecord begin"))
    return rc;
  for (int i = 0; i < iterations; ++i) {
    if (int rc = fail(launch(function, args, grid, block, stream), "measured launch"))
      return rc;
  }
  if (int rc = fail(hipEventRecord(end, stream), "hipEventRecord end"))
    return rc;
  if (int rc = fail(hipEventSynchronize(end), "hipEventSynchronize")) return rc;
  float elapsed_ms = 0.0f;
  if (int rc = fail(hipEventElapsedTime(&elapsed_ms, begin, end),
                    "hipEventElapsedTime")) return rc;
  std::cout << "gfx1151 measured raw BF16 QKV total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";

  hipEventDestroy(begin);
  hipEventDestroy(end);
  hipStreamDestroy(stream);
  hipFree(output);
  hipFree(activation);
  hipFree(weights);
  hipModuleUnload(module);
  return 0;
}
