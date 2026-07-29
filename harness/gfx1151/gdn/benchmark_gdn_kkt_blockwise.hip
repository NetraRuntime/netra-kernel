// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstdint>
#include <cstdlib>
#include <iostream>

#define HIP_CHECK(call, base)                                                \
  do {                                                                       \
    const hipError_t hip_check_status = (call);                              \
    if (hip_check_status != hipSuccess) {                                    \
      std::cerr << #call << ": " << hipGetErrorString(hip_check_status)      \
                << " (" << static_cast<int>(hip_check_status) << ")\n";       \
      return (base) + static_cast<int>(hip_check_status);                    \
    }                                                                        \
  } while (false)

namespace {
hipModule_t module{};
hipFunction_t kernel{};
struct alignas(8) Args {
  void* k;
  void* g;
  void* beta;
  void* output;
};
static_assert(sizeof(Args) == 32);

int launch(void* k, void* g, void* beta, void* output) {
  Args args{k, g, beta, output};
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return static_cast<int>(hipModuleLaunchKernel(
      kernel, 128, 32, 1, 32, 1, 1, 0, nullptr, nullptr, config));
}
}  // namespace

int main(int argc, char** argv) {
  if (argc < 2 || argc > 3) {
    std::cerr << "usage: " << argv[0] << " BLOCKWISE_HSACO [ITERATIONS]\n";
    return 2;
  }
  const int iterations = argc == 3 ? std::atoi(argv[2]) : 5;
  if (iterations < 1) return 2;
  HIP_CHECK(hipModuleLoad(&module, argv[1]), 10);
  HIP_CHECK(hipModuleGetFunction(
                &kernel, module, "gdn_kkt_solve_blockwise_gfx1151"), 20);

  constexpr size_t k_bytes = 1ULL * 8192 * 16 * 128 * 2;
  constexpr size_t scalar_bytes = 1ULL * 8192 * 32 * 4;
  constexpr size_t output_bytes = 1ULL * 8192 * 32 * 64 * 2;
  void* k{};
  void* g{};
  void* beta{};
  void* output{};
  HIP_CHECK(hipMalloc(&k, k_bytes), 30);
  HIP_CHECK(hipMalloc(&g, scalar_bytes), 30);
  HIP_CHECK(hipMalloc(&beta, scalar_bytes), 30);
  HIP_CHECK(hipMalloc(&output, output_bytes), 30);
  HIP_CHECK(hipMemset(k, 0, k_bytes), 40);
  HIP_CHECK(hipMemset(g, 0, scalar_bytes), 40);
  HIP_CHECK(hipMemset(beta, 0, scalar_bytes), 40);
  HIP_CHECK(hipMemset(output, 0, output_bytes), 40);

  for (int i = 0; i < 2; ++i) {
    const int rc = launch(k, g, beta, output);
    if (rc) return 40 + rc;
  }
  HIP_CHECK(hipDeviceSynchronize(), 50);
  hipEvent_t begin{}, end{};
  HIP_CHECK(hipEventCreate(&begin), 60);
  HIP_CHECK(hipEventCreate(&end), 60);
  HIP_CHECK(hipEventRecord(begin), 70);
  for (int i = 0; i < iterations; ++i) {
    const int rc = launch(k, g, beta, output);
    if (rc) return 50 + rc;
  }
  HIP_CHECK(hipEventRecord(end), 70);
  HIP_CHECK(hipEventSynchronize(end), 80);
  float elapsed_ms{};
  HIP_CHECK(hipEventElapsedTime(&elapsed_ms, begin, end), 90);
  std::cout << "gfx1151 measured GDN KKT blockwise total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";
  HIP_CHECK(hipEventDestroy(begin), 100);
  HIP_CHECK(hipEventDestroy(end), 100);
  HIP_CHECK(hipFree(k), 110);
  HIP_CHECK(hipFree(g), 110);
  HIP_CHECK(hipFree(beta), 110);
  HIP_CHECK(hipFree(output), 110);
  HIP_CHECK(hipModuleUnload(module), 120);
  return 0;
}
