// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <rocblas/rocblas.h>

#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <iostream>

namespace {
constexpr rocblas_int kN = 2048;
constexpr rocblas_int kK = 4096;

int fail_hip(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}

int fail_rocblas(rocblas_status status, const char* where) {
  if (status == rocblas_status_success) return 0;
  std::cerr << where << ": rocBLAS status " << static_cast<int>(status) << "\n";
  return 1000 + static_cast<int>(status);
}

rocblas_status launch(rocblas_handle handle, const void* weights,
                      const void* activation, void* output) {
  const float alpha = 1.0f;
  const float beta = 0.0f;
  return rocblas_gemm_ex(
      handle, rocblas_operation_transpose, rocblas_operation_none,
      kN, 1, kK, &alpha,
      weights, rocblas_datatype_bf16_r, kK,
      activation, rocblas_datatype_bf16_r, kK,
      &beta, output, rocblas_datatype_bf16_r, kN,
      output, rocblas_datatype_bf16_r, kN,
      rocblas_datatype_f32_r, rocblas_gemm_algo_standard, 0, 0);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc > 2) {
    std::cerr << "usage: " << argv[0] << " [ITERATIONS]\n";
    return 2;
  }
  const int iterations = argc == 2 ? std::atoi(argv[1]) : 1;
  if (iterations < 1) return 2;

  void* weights{};
  void* activation{};
  void* output{};
  if (int rc = fail_hip(hipMalloc(&weights,
                                  static_cast<size_t>(kN) * kK * sizeof(uint16_t)),
                        "hipMalloc weights")) return rc;
  if (int rc = fail_hip(hipMalloc(&activation,
                                  static_cast<size_t>(kK) * sizeof(uint16_t)),
                        "hipMalloc activation")) return rc;
  if (int rc = fail_hip(hipMalloc(&output,
                                  static_cast<size_t>(kN) * sizeof(uint16_t)),
                        "hipMalloc output")) return rc;
  if (int rc = fail_hip(hipMemset(weights, 0,
                                  static_cast<size_t>(kN) * kK * sizeof(uint16_t)),
                        "hipMemset weights")) return rc;
  if (int rc = fail_hip(hipMemset(activation, 0,
                                  static_cast<size_t>(kK) * sizeof(uint16_t)),
                        "hipMemset activation")) return rc;

  hipStream_t stream{};
  if (int rc = fail_hip(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  rocblas_handle handle{};
  if (int rc = fail_rocblas(rocblas_create_handle(&handle),
                            "rocblas_create_handle")) return rc;
  if (int rc = fail_rocblas(rocblas_set_stream(handle, stream),
                            "rocblas_set_stream")) return rc;
  if (int rc = fail_rocblas(launch(handle, weights, activation, output),
                            "warmup rocblas_gemm_ex")) return rc;
  if (int rc = fail_hip(hipStreamSynchronize(stream), "warmup sync")) return rc;

  hipEvent_t begin{}, end{};
  if (int rc = fail_hip(hipEventCreate(&begin), "hipEventCreate begin")) return rc;
  if (int rc = fail_hip(hipEventCreate(&end), "hipEventCreate end")) return rc;
  if (int rc = fail_hip(hipEventRecord(begin, stream), "hipEventRecord begin"))
    return rc;
  for (int i = 0; i < iterations; ++i) {
    if (int rc = fail_rocblas(launch(handle, weights, activation, output),
                              "measured rocblas_gemm_ex")) return rc;
  }
  if (int rc = fail_hip(hipEventRecord(end, stream), "hipEventRecord end"))
    return rc;
  if (int rc = fail_hip(hipEventSynchronize(end), "hipEventSynchronize")) return rc;
  float elapsed_ms = 0.0f;
  if (int rc = fail_hip(hipEventElapsedTime(&elapsed_ms, begin, end),
                        "hipEventElapsedTime")) return rc;
  std::cout << "gfx1151 measured rocBLAS BF16 attention output total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";

  hipEventDestroy(begin);
  hipEventDestroy(end);
  rocblas_destroy_handle(handle);
  hipStreamDestroy(stream);
  hipFree(output);
  hipFree(activation);
  hipFree(weights);
  return 0;
}
