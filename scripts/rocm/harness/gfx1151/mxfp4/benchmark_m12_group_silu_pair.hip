// SPDX-License-Identifier: MIT
// HIP is used only for launch, setup, comparison, and timing; compute is raw ASM.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#define CHK(x) do { hipError_t e_=(x); if(e_!=hipSuccess) { std::fprintf(stderr,"HIP error %s at %d\n",hipGetErrorString(e_),__LINE__); std::exit(2); } } while(0)

__global__ void fill_f32(float* gate, float* up, size_t count) {
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;
  if (i < count) {
    gate[i] = float(int(i % 29) - 14) * 0.125f;
    up[i] = float(int(i % 31) - 15) * 0.0625f;
  }
}

__global__ void compare_valid(
    const uint16_t* baseline, const uint16_t* candidate, unsigned groups,
    unsigned* mismatches) {
  constexpr unsigned n = 512;
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;
  size_t count = size_t(groups) * 12 * n;
  if (i >= count) return;
  size_t group = i / (12 * n);
  size_t within = i % (12 * n);
  size_t offset = group * 64 * n + within;
  if (baseline[offset] != candidate[offset]) atomicAdd(mismatches, 1u);
}

struct Kernel { hipModule_t module{}; hipFunction_t function{}; };
struct Args { void* gate; void* up; void* output; };

static Kernel load(const char* path, const char* symbol) {
  Kernel result;
  CHK(hipModuleLoad(&result.module, path));
  CHK(hipModuleGetFunction(&result.function, result.module, symbol));
  return result;
}

static void launch(const Kernel& kernel, Args& args, unsigned gx, unsigned gy) {
  void* params[] = {&args.gate, &args.up, &args.output};
  CHK(hipModuleLaunchKernel(kernel.function, gx, gy, 1, 256, 1, 1, 0, nullptr, params, nullptr));
}

static float time_one(const Kernel& kernel, Args& args, unsigned gx, unsigned gy) {
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin)); launch(kernel, args, gx, gy);
  CHK(hipEventRecord(end)); CHK(hipEventSynchronize(end));
  float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return ms;
}

static double median(std::vector<float> values) {
  std::sort(values.begin(), values.end());
  return values[values.size() / 2];
}

int main(int argc, char** argv) {
  if (argc < 3) {
    std::fprintf(stderr, "usage: %s BASELINE.hsaco CANDIDATE.hsaco [groups] [samples]\n", argv[0]);
    return 2;
  }
  constexpr unsigned M = 64, N = 512;
  const unsigned groups = argc > 3 ? std::strtoul(argv[3], nullptr, 10) : 96;
  const unsigned samples = argc > 4 ? std::strtoul(argv[4], nullptr, 10) : 21;
  hipDeviceProp_t properties{}; CHK(hipGetDeviceProperties(&properties, 0));
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos) return 3;
  const size_t elements = size_t(groups) * M * N;
  float *d_gate{}, *d_up{};
  uint16_t *d_baseline{}, *d_candidate{};
  unsigned* d_mismatches{};
  CHK(hipMalloc(&d_gate, elements * 4)); CHK(hipMalloc(&d_up, elements * 4));
  CHK(hipMalloc(&d_baseline, elements * 2)); CHK(hipMalloc(&d_candidate, elements * 2));
  CHK(hipMalloc(&d_mismatches, 4));
  fill_f32<<<(elements + 255) / 256, 256>>>(d_gate, d_up, elements);
  Kernel baseline = load(argv[1], "silu_mul_bf16_gfx1151");
  Kernel candidate = load(argv[2], "silu_mul_m12_group_bf16_gfx1151");
  Args baseline_args{d_gate, d_up, d_baseline};
  Args candidate_args{d_gate, d_up, d_candidate};
  for (int i = 0; i < 3; ++i) {
    launch(baseline, baseline_args, groups * 128, 1);
    launch(candidate, candidate_args, 24, groups);
  }
  CHK(hipDeviceSynchronize()); CHK(hipMemset(d_mismatches, 0, 4));
  const size_t valid = size_t(groups) * 12 * N;
  compare_valid<<<(valid + 255) / 256, 256>>>(d_baseline, d_candidate, groups, d_mismatches);
  unsigned mismatches = 0; CHK(hipMemcpy(&mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));
  std::vector<float> baseline_ms, candidate_ms;
  for (unsigned sample = 0; sample < samples; ++sample) {
    if (sample & 1) {
      candidate_ms.push_back(time_one(candidate, candidate_args, 24, groups));
      baseline_ms.push_back(time_one(baseline, baseline_args, groups * 128, 1));
    } else {
      baseline_ms.push_back(time_one(baseline, baseline_args, groups * 128, 1));
      candidate_ms.push_back(time_one(candidate, candidate_args, 24, groups));
    }
  }
  double base_med = median(baseline_ms), candidate_med = median(candidate_ms);
  std::printf("gfx1151 measured groups=%u valid_rows=12 bit_equal=%s mismatches=%u baseline_median_ms=%.6f candidate_median_ms=%.6f speedup=%.6f\n", groups, mismatches ? "false" : "true", mismatches, base_med, candidate_med, base_med / candidate_med);
  std::printf("baseline_samples_ms="); for (float v : baseline_ms) std::printf(" %.6f", v);
  std::printf("\ncandidate_samples_ms="); for (float v : candidate_ms) std::printf(" %.6f", v);
  std::printf("\n");
  return mismatches ? 4 : 0;
}
