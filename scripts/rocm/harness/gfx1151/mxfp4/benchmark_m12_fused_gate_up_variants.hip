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

__global__ void fill_bf16(uint16_t* data, size_t count) {
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;
  if (i < count) data[i] = (i & 1) ? 0xbf80 : 0x3f80;
}

__global__ void compare_valid(
    const uint32_t* baseline, const uint32_t* candidate, unsigned groups,
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
struct FusedArgs {
  void* gate_packed; void* gate_scales; void* up_packed; void* up_scales;
  void* activation; void* ids; void* gate_output; void* up_output;
};

static Kernel load(const char* path, const char* symbol) {
  Kernel result;
  CHK(hipModuleLoad(&result.module, path));
  CHK(hipModuleGetFunction(&result.function, result.module, symbol));
  return result;
}


static void launch_fused(const Kernel& kernel, FusedArgs& args, unsigned groups) {
  void* params[] = {&args.gate_packed, &args.gate_scales, &args.up_packed,
                    &args.up_scales, &args.activation, &args.ids,
                    &args.gate_output, &args.up_output};
  CHK(hipModuleLaunchKernel(kernel.function, 32, groups, 1, 32, 1, 1, 0, nullptr, params, nullptr));
}


static float time_fused(const Kernel& kernel, FusedArgs& args, unsigned groups) {
  constexpr unsigned repeats = 8;
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin));
  for (unsigned repeat = 0; repeat < repeats; ++repeat)
    launch_fused(kernel, args, groups);
  CHK(hipEventRecord(end)); CHK(hipEventSynchronize(end));
  float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return ms / repeats;
}

static double median(std::vector<float> values) {
  std::sort(values.begin(), values.end());
  return values[values.size() / 2];
}

int main(int argc, char** argv) {
  if (argc < 3) {
    std::fprintf(stderr, "usage: %s BASELINE_FUSED.hsaco CANDIDATE_FUSED.hsaco [groups] [samples]\n", argv[0]);
    return 2;
  }
  constexpr unsigned E = 256, M = 64, N = 512, K = 2048;
  const unsigned groups = argc > 3 ? std::strtoul(argv[3], nullptr, 10) : 96;
  const unsigned samples = argc > 4 ? std::strtoul(argv[4], nullptr, 10) : 21;
  hipDeviceProp_t properties{}; CHK(hipGetDeviceProperties(&properties, 0));
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos) return 3;

  const size_t packed_bytes = size_t(E) * (K / 2) * N;
  const size_t scale_bytes = size_t(E) * (K / 32) * N;
  const size_t activation_elements = size_t(groups) * M * K;
  const size_t output_elements = size_t(groups) * M * N;
  std::vector<uint8_t> gate_packed(packed_bytes), up_packed(packed_bytes);
  std::vector<uint8_t> gate_scales(scale_bytes), up_scales(scale_bytes);
  std::vector<uint32_t> ids(groups);
  for (size_t i = 0; i < packed_bytes; ++i) {
    gate_packed[i] = uint8_t((i * 37 + (i >> 11) * 13 + 17) & 255);
    up_packed[i] = uint8_t((i * 29 + (i >> 9) * 7 + 93) & 255);
  }
  for (size_t i = 0; i < scale_bytes; ++i) {
    gate_scales[i] = uint8_t(118 + ((i * 5 + (i >> 9)) % 6));
    up_scales[i] = uint8_t(117 + ((i * 3 + (i >> 8)) % 7));
  }
  for (unsigned group = 0; group < groups; ++group)
    ids[group] = uint32_t((uint64_t(group) * E) / groups);

  uint8_t *d_gate_packed{}, *d_up_packed{}, *d_gate_scales{}, *d_up_scales{};
  uint16_t* d_activation{};
  float *d_gate_base{}, *d_up_base{}, *d_gate_fused{}, *d_up_fused{};
  uint32_t *d_ids{}, *d_mismatches{};
  CHK(hipMalloc(&d_gate_packed, packed_bytes)); CHK(hipMalloc(&d_up_packed, packed_bytes));
  CHK(hipMalloc(&d_gate_scales, scale_bytes)); CHK(hipMalloc(&d_up_scales, scale_bytes));
  CHK(hipMalloc(&d_activation, activation_elements * 2));
  CHK(hipMalloc(&d_gate_base, output_elements * 4)); CHK(hipMalloc(&d_up_base, output_elements * 4));
  CHK(hipMalloc(&d_gate_fused, output_elements * 4)); CHK(hipMalloc(&d_up_fused, output_elements * 4));
  CHK(hipMalloc(&d_ids, groups * 4)); CHK(hipMalloc(&d_mismatches, 4));
  CHK(hipMemcpy(d_gate_packed, gate_packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_up_packed, up_packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_gate_scales, gate_scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_up_scales, up_scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_ids, ids.data(), groups * 4, hipMemcpyHostToDevice));
  fill_bf16<<<(activation_elements + 255) / 256, 256>>>(d_activation, activation_elements);

  Kernel baseline = load(argv[1], "mxfp4_m12_group_gate_up_wmma_gfx1151");
  Kernel candidate = load(argv[2], "mxfp4_m12_group_gate_up_wmma_gfx1151");
  FusedArgs baseline_args{d_gate_packed, d_gate_scales, d_up_packed, d_up_scales,
                          d_activation, d_ids, d_gate_base, d_up_base};
  FusedArgs candidate_args{d_gate_packed, d_gate_scales, d_up_packed, d_up_scales,
                           d_activation, d_ids, d_gate_fused, d_up_fused};
  for (int i = 0; i < 3; ++i) {
    launch_fused(baseline, baseline_args, groups);
    launch_fused(candidate, candidate_args, groups);
  }
  CHK(hipDeviceSynchronize()); CHK(hipMemset(d_mismatches, 0, 4));
  const size_t valid = size_t(groups) * 12 * N;
  compare_valid<<<(valid + 255) / 256, 256>>>((uint32_t*)d_gate_base, (uint32_t*)d_gate_fused, groups, d_mismatches);
  uint32_t gate_mismatches = 0;
  CHK(hipMemcpy(&gate_mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));
  CHK(hipMemset(d_mismatches, 0, 4));
  compare_valid<<<(valid + 255) / 256, 256>>>((uint32_t*)d_up_base, (uint32_t*)d_up_fused, groups, d_mismatches);
  uint32_t up_mismatches = 0;
  CHK(hipMemcpy(&up_mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));
  uint32_t mismatches = gate_mismatches + up_mismatches;

  std::vector<float> baseline_ms, candidate_ms;
  for (unsigned sample = 0; sample < samples; ++sample) {
    if (sample & 1) {
      candidate_ms.push_back(time_fused(candidate, candidate_args, groups));
      baseline_ms.push_back(time_fused(baseline, baseline_args, groups));
    } else {
      baseline_ms.push_back(time_fused(baseline, baseline_args, groups));
      candidate_ms.push_back(time_fused(candidate, candidate_args, groups));
    }
  }
  double baseline_med = median(baseline_ms);
  double candidate_med = median(candidate_ms);
  std::printf("gfx1151 measured groups=%u valid_rows=12 bit_equal=%s mismatches=%u gate_mismatches=%u up_mismatches=%u baseline_fused_median_ms=%.6f candidate_fused_median_ms=%.6f speedup=%.6f\n", groups, mismatches ? "false" : "true", mismatches, gate_mismatches, up_mismatches, baseline_med, candidate_med, baseline_med / candidate_med);
  std::printf("baseline_samples_ms="); for (float v : baseline_ms) std::printf(" %.6f", v);
  std::printf("\ncandidate_samples_ms="); for (float v : candidate_ms) std::printf(" %.6f", v);
  std::printf("\n");
  return mismatches ? 4 : 0;
}
