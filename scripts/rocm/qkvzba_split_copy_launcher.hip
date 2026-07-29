// SPDX-License-Identifier: MIT
// Launch-only bridge for the hand-written gfx1151 QKVZ/BA split-copy kernel.
#include <hip/hip_runtime.h>

#include <mutex>
#include <string>
#include <cstdio>
#include <cstdlib>
#include <vector>

#ifndef NETRA_QKVZBA_HSACO
#define NETRA_QKVZBA_HSACO "/root/netra-mxfp4-gfx1151/build/experiments/qkvzba_split_copy_gfx1151.hsaco"
#endif

namespace {
std::once_flag init_once;
hipModule_t module{};
hipFunction_t function{};
hipError_t init_status = hipSuccess;
std::string init_error;

void initialize() {
  init_status = hipModuleLoad(&module, NETRA_QKVZBA_HSACO);
  if (init_status != hipSuccess) {
    init_error = std::string("hipModuleLoad: ") + hipGetErrorString(init_status);
    return;
  }
  init_status = hipModuleGetFunction(
      &function, module, "qkvzba_split_copy_gfx1151");
  if (init_status != hipSuccess) {
    init_error = std::string("hipModuleGetFunction: ") +
                 hipGetErrorString(init_status);
  }
}

struct alignas(8) Args {
  void* mixed_qkvz;
  void* mixed_ba;
  void* mixed_qkv;
  void* z;
  void* b;
  void* a;
};
}  // namespace

extern "C" int netra_qkvzba_split_init() {
  std::call_once(init_once, initialize);
  return static_cast<int>(init_status);
}

extern "C" const char* netra_qkvzba_split_error() {
  return init_error.empty() ? hipGetErrorString(init_status) : init_error.c_str();
}

extern "C" int netra_qkvzba_split_launch(
    void* mixed_qkvz, void* mixed_ba, void* mixed_qkv, void* z, void* b,
    void* a, unsigned token_count, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  Args args{mixed_qkvz, mixed_ba, mixed_qkv, z, b, a};
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
      HIP_LAUNCH_PARAM_END,
  };
  hipError_t status = hipModuleLaunchKernel(
      function, 7, token_count, 1, 256, 1, 1, 0,
      reinterpret_cast<hipStream_t>(stream_ptr), nullptr, config);
  return static_cast<int>(status);
}

#ifdef NETRA_COUNTER_MAIN
namespace {
void check_hip(hipError_t status, const char* operation) {
  if (status != hipSuccess) {
    std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(status));
    std::exit(2);
  }
}
}  // namespace

int main(int argc, char** argv) {
  const unsigned token_count = argc > 1 ? std::atoi(argv[1]) : 8192;
  const int iterations = argc > 2 ? std::atoi(argv[2]) : 1;
  hipDeviceProp_t properties{};
  check_hip(hipGetDeviceProperties(&properties, 0), "hipGetDeviceProperties");
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos) {
    std::fprintf(stderr, "expected gfx1151, got %s\n", properties.gcnArchName);
    return 3;
  }
  const std::vector<size_t> sizes = {
      static_cast<size_t>(token_count) * 12288 * 2,
      static_cast<size_t>(token_count) * 64 * 2,
      static_cast<size_t>(token_count) * 8192 * 2,
      static_cast<size_t>(token_count) * 4096 * 2,
      static_cast<size_t>(token_count) * 32 * 2,
      static_cast<size_t>(token_count) * 32 * 2,
  };
  std::vector<void*> pointers(sizes.size(), nullptr);
  for (size_t index = 0; index < sizes.size(); ++index) {
    check_hip(hipMalloc(&pointers[index], sizes[index]), "hipMalloc");
  }
  if (netra_qkvzba_split_init() != 0) {
    std::fprintf(stderr, "init: %s\n", netra_qkvzba_split_error());
    return 4;
  }
  hipEvent_t begin{}, end{};
  check_hip(hipEventCreate(&begin), "hipEventCreate");
  check_hip(hipEventCreate(&end), "hipEventCreate");
  check_hip(hipEventRecord(begin), "hipEventRecord");
  for (int iteration = 0; iteration < iterations; ++iteration) {
    const int status = netra_qkvzba_split_launch(
        pointers[0], pointers[1], pointers[2], pointers[3], pointers[4],
        pointers[5], token_count, nullptr);
    if (status != 0) {
      std::fprintf(stderr, "launch status=%d\n", status);
      return 5;
    }
  }
  check_hip(hipEventRecord(end), "hipEventRecord");
  check_hip(hipEventSynchronize(end), "hipEventSynchronize");
  float elapsed_ms = 0.0f;
  check_hip(hipEventElapsedTime(&elapsed_ms, begin, end), "hipEventElapsedTime");
  std::printf(
      "target=gfx1151 measurement=measured tokens=%u iterations=%d "
      "total_gpu_ms=%.6f mean_gpu_ms=%.6f\n",
      token_count, iterations, elapsed_ms, elapsed_ms / iterations);
  for (void* pointer_value : pointers) check_hip(hipFree(pointer_value), "hipFree");
  check_hip(hipEventDestroy(begin), "hipEventDestroy");
  check_hip(hipEventDestroy(end), "hipEventDestroy");
  return 0;
}
#endif
