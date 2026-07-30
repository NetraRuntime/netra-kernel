// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <mutex>

namespace {
hipModule_t module = nullptr;
hipFunction_t kernel = nullptr;
std::mutex load_mutex;

struct alignas(8) Args {
  void* k;
  void* v;
  void* beta;
  void* w;
  void* u;
  void* A;
  void* g;
  void* cu_seqlens;
  void* chunk_indices;
  uint32_t tokens;
};
static_assert(sizeof(Args) == 80);
}  // namespace

extern "C" int netra_recompute_w_u_init(const char* hsaco_path, const char* kernel_symbol) {
  std::lock_guard<std::mutex> lock(load_mutex);
  if (kernel != nullptr) return hipSuccess;
  hipError_t status = hipModuleLoad(&module, hsaco_path);
  if (status != hipSuccess) return status;
  return hipModuleGetFunction(
      &kernel, module, kernel_symbol);
}

extern "C" int netra_recompute_w_u(
    void* k, void* v, void* beta, void* w, void* u, void* A, void* g,
    void* cu_seqlens, void* chunk_indices, uint32_t tokens,
    hipStream_t stream) {
  if (kernel == nullptr || tokens != 8192) return hipErrorInvalidValue;
  Args args{k, v, beta, w, u, A, g, cu_seqlens, chunk_indices, tokens};
  size_t arg_size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER,
      &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &arg_size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(
      kernel, 128, 32, 1, 64, 1, 1, 0, stream, nullptr, config);
}

int main(int argc, char** argv) {
  if (argc < 3 || argc > 4) {
    std::cerr << "usage: " << argv[0] << " HSACO SYMBOL [ITERATIONS]\n";
    return 2;
  }
  int iterations = argc == 4 ? std::atoi(argv[3]) : 1;
  if (iterations < 1) return 2;
  constexpr size_t KiB = 1024;
  const size_t sizes[] = {
      32768 * KiB, 65536 * KiB, 1024 * KiB, 65536 * KiB,
      65536 * KiB, 32768 * KiB, 1024 * KiB};
  void* buffers[7]{};
  for (int i = 0; i < 7; ++i) {
    hipError_t status = hipMalloc(&buffers[i], sizes[i]);
    if (status != hipSuccess) return 10 + static_cast<int>(status);
    status = hipMemset(buffers[i], 0, sizes[i]);
    if (status != hipSuccess) return 20 + static_cast<int>(status);
  }
  int status = netra_recompute_w_u_init(argv[1], argv[2]);
  if (status) return 30 + status;
  hipEvent_t begin{}, end{};
  hipEventCreate(&begin);
  hipEventCreate(&end);
  hipEventRecord(begin);
  for (int i = 0; i < iterations; ++i) {
    status = netra_recompute_w_u(
        buffers[0], buffers[1], buffers[2], buffers[3], buffers[4],
        buffers[5], buffers[6], nullptr, nullptr, 8192, nullptr);
    if (status) return 40 + status;
  }
  hipEventRecord(end);
  hipEventSynchronize(end);
  float elapsed_ms = 0.0f;
  hipEventElapsedTime(&elapsed_ms, begin, end);
  std::cout << "gfx1151 measured ordered recompute total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";
  for (void* buffer : buffers) hipFree(buffer);
  hipEventDestroy(begin);
  hipEventDestroy(end);
  return 0;
}
