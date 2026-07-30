// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <rocblas/rocblas.h>

#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iostream>

namespace {
constexpr rocblas_int kN = 9216;
constexpr rocblas_int kK = 2048;

struct alignas(8) Args {
  const void* weights;
  const void* activation;
  void* output;
};
static_assert(sizeof(Args) == 24);

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

hipError_t launch_raw(hipFunction_t function, const Args& args,
                      hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, const_cast<Args*>(&args),
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size, HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(function, kN / 32, 1, 1, 256, 1, 1, 0,
                               stream, nullptr, config);
}

rocblas_status launch_rocblas(rocblas_handle handle, const Args& args) {
  const float alpha = 1.0f;
  const float beta = 0.0f;
  return rocblas_gemm_ex(
      handle, rocblas_operation_transpose, rocblas_operation_none,
      kN, 1, kK, &alpha,
      args.weights, rocblas_datatype_bf16_r, kK,
      args.activation, rocblas_datatype_bf16_r, kK,
      &beta, args.output, rocblas_datatype_bf16_r, kN,
      args.output, rocblas_datatype_bf16_r, kN,
      rocblas_datatype_f32_r, rocblas_gemm_algo_standard, 0, 0);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc < 3 || argc > 4) {
    std::cerr << "usage: " << argv[0]
              << " raw|rocblas RAW_HSACO [ITERATIONS]\n";
    return 2;
  }
  const bool use_raw = std::strcmp(argv[1], "raw") == 0;
  const bool use_rocblas = std::strcmp(argv[1], "rocblas") == 0;
  if (!use_raw && !use_rocblas) return 2;
  const int iterations = argc == 4 ? std::atoi(argv[3]) : 30;
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
  hipModule_t module{};
  hipFunction_t function{};
  rocblas_handle handle{};
  if (use_raw) {
    if (int rc = fail_hip(hipModuleLoad(&module, argv[2]), "hipModuleLoad"))
      return rc;
    if (int rc = fail_hip(
            hipModuleGetFunction(&function, module,
                                 "bf16_qkv_decode_wave4_gfx1151"),
            "hipModuleGetFunction")) return rc;
  } else {
    if (int rc = fail_rocblas(rocblas_create_handle(&handle),
                              "rocblas_create_handle")) return rc;
    if (int rc = fail_rocblas(rocblas_set_stream(handle, stream),
                              "rocblas_set_stream")) return rc;
  }

  const Args args{weights, activation, output};
  auto launch_once = [&]() -> int {
    return use_raw
        ? fail_hip(launch_raw(function, args, stream), "raw launch")
        : fail_rocblas(launch_rocblas(handle, args), "rocblas_gemm_ex");
  };
  for (int i = 0; i < 5; ++i) {
    if (int rc = launch_once()) return rc;
  }
  if (int rc = fail_hip(hipStreamSynchronize(stream), "warmup sync")) return rc;

  hipEvent_t begin{}, end{};
  if (int rc = fail_hip(hipEventCreate(&begin), "hipEventCreate begin")) return rc;
  if (int rc = fail_hip(hipEventCreate(&end), "hipEventCreate end")) return rc;
  if (int rc = fail_hip(hipEventRecord(begin, stream), "hipEventRecord begin"))
    return rc;
  for (int i = 0; i < iterations; ++i) {
    if (int rc = launch_once()) return rc;
  }
  if (int rc = fail_hip(hipEventRecord(end, stream), "hipEventRecord end"))
    return rc;
  if (int rc = fail_hip(hipEventSynchronize(end), "hipEventSynchronize")) return rc;
  float elapsed_ms = 0.0f;
  if (int rc = fail_hip(hipEventElapsedTime(&elapsed_ms, begin, end),
                        "hipEventElapsedTime")) return rc;
  std::cout << "gfx1151 measured BF16 QKV M1 N9216 K2048 mode=" << argv[1]
            << " total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";
  return 0;
}
