// SPDX-License-Identifier: MIT
//
// Correctness and HIP-event timing harness only. The measured replacement is
// raw AMDGCN in qwen36_moe_silu_mul_quant_fp8_gfx950.s.
#include <hip/hip_bf16.h>
#include <hip/hip_fp8.h>
#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <random>
#include <string>
#include <vector>

#define CHK(expr)                                                            \
  do {                                                                       \
    hipError_t error_ = (expr);                                              \
    if (error_ != hipSuccess) {                                              \
      std::fprintf(stderr, "HIP error %s at %s:%d\n",                       \
                   hipGetErrorString(error_), __FILE__, __LINE__);           \
      std::exit(1);                                                          \
    }                                                                        \
  } while (0)

namespace {

constexpr int kRows = 9;
constexpr int kWidth = 512;
constexpr int kGroup = 128;
constexpr int kThreads = 64;
constexpr float kInvFp8Max = 0x1.24924ap-9f;  // 0x3b124925

__device__ __forceinline__ float silu(float value) {
  return value * __builtin_amdgcn_rcpf(1.0f + __ocml_exp_f32(-value));
}

__global__ void baseline_act(
    __hip_bfloat16* output, const float* input, int rows) {
  const int row = blockIdx.x;
  if (row >= rows) {
    return;
  }
  const int offset = threadIdx.x * 8;
  const float* gate = input + row * 2 * kWidth;
  const float* up = gate + kWidth;
#pragma unroll
  for (int index = 0; index < 8; ++index) {
    output[row * kWidth + offset + index] =
        __float2bfloat16(silu(gate[offset + index]) * up[offset + index]);
  }
}

__global__ void baseline_quant(
    __hip_fp8_e4m3* output,
    float* scales,
    const __hip_bfloat16* input,
    int rows) {
  const int row = blockIdx.x;
  if (row >= rows) {
    return;
  }
  const int lane = threadIdx.x;
  const int subgroup_lane = lane & 15;
  const int group = lane >> 4;
  const int offset = group * kGroup + subgroup_lane * 8;
  float values[8];
  float maximum = 1.0e-10f;
#pragma unroll
  for (int index = 0; index < 8; ++index) {
    values[index] = __bfloat162float(input[row * kWidth + offset + index]);
    maximum = fmaxf(maximum, fabsf(values[index]));
  }
#pragma unroll
  for (int delta = 8; delta > 0; delta >>= 1) {
    maximum = fmaxf(maximum, __shfl_down(maximum, delta, 16));
  }
  maximum = __shfl(maximum, 0, 16);
  // Match the deployed AITER gfx950 instruction stream: v_mul_f32 by the
  // rounded 1/448 constant, rather than a generic IEEE division sequence.
  const float scale = maximum * kInvFp8Max;
  if (subgroup_lane == 0) {
    scales[row * (kWidth / kGroup) + group] = scale;
  }
  const float inverse_scale = 1.0f / scale;
#pragma unroll
  for (int index = 0; index < 8; ++index) {
    output[row * kWidth + offset + index] =
        __hip_fp8_e4m3(values[index] * inverse_scale);
  }
}

void launch_raw(
    hipFunction_t function,
    const float* input,
    uint8_t* output,
    float* scales,
    int rows,
    hipStream_t stream = nullptr) {
  void* arguments[] = {&input, &output, &scales, &rows};
  CHK(hipModuleLaunchKernel(
      function, rows, 1, 1, kThreads, 1, 1, 0, stream, arguments, nullptr));
}

}  // namespace

int main(int argc, char** argv) {
  const int iterations = argc > 1 ? std::atoi(argv[1]) : 2000;
  const char* hsaco =
      argc > 2 ? argv[2] : "./qwen36_moe_silu_mul_quant_fp8_gfx950.hsaco";

  hipDeviceProp_t properties{};
  CHK(hipGetDeviceProperties(&properties, 0));
  if (std::string(properties.gcnArchName).find("gfx950") == std::string::npos) {
    std::fprintf(
        stderr,
        "This raw code object requires gfx950; got %s\n",
        properties.gcnArchName);
    return 2;
  }

  std::mt19937 generator(20260729);
  std::normal_distribution<float> gate_distribution(0.0f, 2.0f);
  std::normal_distribution<float> up_distribution(0.0f, 1.0f);
  std::vector<float> host_input(kRows * 2 * kWidth);
  for (int row = 0; row < kRows; ++row) {
    for (int index = 0; index < kWidth; ++index) {
      host_input[row * 2 * kWidth + index] =
          gate_distribution(generator);
      host_input[row * 2 * kWidth + kWidth + index] =
          up_distribution(generator);
    }
  }

  float* device_input{};
  __hip_bfloat16* device_bf16{};
  __hip_fp8_e4m3* device_reference{};
  uint8_t* device_raw{};
  float* device_reference_scales{};
  float* device_raw_scales{};
  CHK(hipMalloc(&device_input, host_input.size() * sizeof(float)));
  CHK(hipMalloc(&device_bf16, kRows * kWidth * sizeof(__hip_bfloat16)));
  CHK(hipMalloc(&device_reference, kRows * kWidth * sizeof(__hip_fp8_e4m3)));
  CHK(hipMalloc(&device_raw, kRows * kWidth));
  CHK(hipMalloc(
      &device_reference_scales,
      kRows * (kWidth / kGroup) * sizeof(float)));
  CHK(hipMalloc(
      &device_raw_scales,
      kRows * (kWidth / kGroup) * sizeof(float)));
  CHK(hipMemcpy(
      device_input,
      host_input.data(),
      host_input.size() * sizeof(float),
      hipMemcpyHostToDevice));

  hipModule_t module{};
  hipFunction_t function{};
  CHK(hipModuleLoad(&module, hsaco));
  CHK(hipModuleGetFunction(
      &function, module, "qwen36_moe_silu_mul_quant_fp8_gfx950"));

  baseline_act<<<kRows, kThreads>>>(
      device_bf16, device_input, kRows);
  baseline_quant<<<kRows, kThreads>>>(
      device_reference, device_reference_scales, device_bf16, kRows);
  launch_raw(
      function, device_input, device_raw, device_raw_scales, kRows);
  CHK(hipDeviceSynchronize());

  std::vector<uint8_t> reference(kRows * kWidth);
  std::vector<uint8_t> result(reference.size());
  std::vector<float> reference_scales(kRows * (kWidth / kGroup));
  std::vector<float> result_scales(reference_scales.size());
  CHK(hipMemcpy(
      reference.data(),
      device_reference,
      reference.size(),
      hipMemcpyDeviceToHost));
  CHK(hipMemcpy(
      result.data(), device_raw, result.size(), hipMemcpyDeviceToHost));
  CHK(hipMemcpy(
      reference_scales.data(),
      device_reference_scales,
      reference_scales.size() * sizeof(float),
      hipMemcpyDeviceToHost));
  CHK(hipMemcpy(
      result_scales.data(),
      device_raw_scales,
      result_scales.size() * sizeof(float),
      hipMemcpyDeviceToHost));

  size_t byte_mismatches = 0;
  int maximum_byte_delta = 0;
  for (size_t index = 0; index < result.size(); ++index) {
    if (reference[index] != result[index]) {
      ++byte_mismatches;
      maximum_byte_delta = std::max(
          maximum_byte_delta,
          std::abs(int(reference[index]) - int(result[index])));
    }
  }
  double maximum_scale_absolute = 0.0;
  double maximum_scale_relative = 0.0;
  for (size_t index = 0; index < result_scales.size(); ++index) {
    const double absolute =
        std::abs(double(reference_scales[index]) - result_scales[index]);
    const double relative =
        absolute / std::max(std::abs(double(reference_scales[index])), 1e-30);
    maximum_scale_absolute = std::max(maximum_scale_absolute, absolute);
    maximum_scale_relative = std::max(maximum_scale_relative, relative);
  }
  std::printf(
      "gfx950 raw fused FP32->BF16 SiLU*up->FP8: "
      "byte_mismatches=%zu/%zu max_byte_delta=%d "
      "scale_max_abs=%.9e scale_max_rel=%.9e %s\n",
      byte_mismatches,
      result.size(),
      maximum_byte_delta,
      maximum_scale_absolute,
      maximum_scale_relative,
      byte_mismatches == 0 && maximum_scale_relative <= 1e-6
          ? "PASS"
          : "FAIL");
  if (byte_mismatches != 0 || maximum_scale_relative > 1e-6) {
    std::fprintf(stderr, "first-row scales (reference/raw):");
    for (int group = 0; group < kWidth / kGroup; ++group) {
      std::fprintf(
          stderr,
          " %.9e/%.9e",
          reference_scales[group],
          result_scales[group]);
    }
    std::fprintf(stderr, "\nfirst byte mismatches:");
    int printed = 0;
    for (size_t index = 0; index < result.size() && printed < 16; ++index) {
      if (reference[index] != result[index]) {
        std::fprintf(
            stderr,
            " [%zu]=0x%02x/0x%02x",
            index,
            unsigned(reference[index]),
            unsigned(result[index]));
        ++printed;
      }
    }
    std::fprintf(stderr, "\n");
    return 3;
  }

  for (int iteration = 0; iteration < 50; ++iteration) {
    baseline_act<<<kRows, kThreads>>>(
        device_bf16, device_input, kRows);
    baseline_quant<<<kRows, kThreads>>>(
        device_reference, device_reference_scales, device_bf16, kRows);
    launch_raw(
        function, device_input, device_raw, device_raw_scales, kRows);
  }
  CHK(hipDeviceSynchronize());

  auto measure = [&](auto launch) {
    hipEvent_t begin{};
    hipEvent_t end{};
    CHK(hipEventCreate(&begin));
    CHK(hipEventCreate(&end));
    CHK(hipEventRecord(begin));
    for (int iteration = 0; iteration < iterations; ++iteration) {
      launch();
    }
    CHK(hipEventRecord(end));
    CHK(hipEventSynchronize(end));
    float milliseconds = 0.0f;
    CHK(hipEventElapsedTime(&milliseconds, begin, end));
    CHK(hipEventDestroy(begin));
    CHK(hipEventDestroy(end));
    return milliseconds * 1000.0 / iterations;
  };
  const double baseline_microseconds = measure([&] {
    baseline_act<<<kRows, kThreads>>>(
        device_bf16, device_input, kRows);
    baseline_quant<<<kRows, kThreads>>>(
        device_reference, device_reference_scales, device_bf16, kRows);
  });
  const double raw_microseconds = measure([&] {
    launch_raw(
        function, device_input, device_raw, device_raw_scales, kRows);
  });
  std::printf(
      "HIP events, rows=9 width=512 group=128: "
      "two-kernel=%.3f us raw-fused=%.3f us speedup=%.3fx\n",
      baseline_microseconds,
      raw_microseconds,
      baseline_microseconds / raw_microseconds);

  CHK(hipModuleUnload(module));
  CHK(hipFree(device_raw_scales));
  CHK(hipFree(device_reference_scales));
  CHK(hipFree(device_raw));
  CHK(hipFree(device_reference));
  CHK(hipFree(device_bf16));
  CHK(hipFree(device_input));
  return 0;
}
