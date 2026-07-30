// SPDX-License-Identifier: MIT
// HIP is used only for launch, data setup, correctness comparison, and timing.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#define CHK(x) do { hipError_t e_=(x); if(e_!=hipSuccess) { \
  std::fprintf(stderr,"HIP error %s at %d\n",hipGetErrorString(e_),__LINE__); \
  std::exit(2); } } while(0)

__global__ void fill_bf16(uint16_t* data, size_t count) {
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;
  if (i < count) data[i] = (i & 1) ? 0xbf80 : 0x3f80;
}

__global__ void compare_valid_rows(
    const uint32_t* baseline, const uint32_t* candidate, unsigned groups,
    unsigned n, unsigned* mismatches) {
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;
  size_t count = size_t(groups) * 12 * n;
  if (i >= count) return;
  size_t group = i / (12 * n);
  size_t within = i % (12 * n);
  size_t offset = group * 64 * n + within;
  if (baseline[offset] != candidate[offset]) atomicAdd(mismatches, 1u);
}

struct Kernel { hipModule_t module{}; hipFunction_t function{}; };
struct Args { void* packed; void* scales; void* activation; void* output; void* ids; };

static Kernel load(const char* path, const char* symbol) {
  Kernel result;
  CHK(hipModuleLoad(&result.module, path));
  CHK(hipModuleGetFunction(&result.function, result.module, symbol));
  return result;
}

static void launch(
    const Kernel& kernel, Args& args, unsigned gx, unsigned gy, unsigned bx) {
  void* params[] = {&args.packed, &args.scales, &args.activation,
                    &args.output, &args.ids};
  CHK(hipModuleLaunchKernel(
      kernel.function, gx, gy, 1, bx, 1, 1, 0, nullptr, params, nullptr));
}

static float time_one(
    const Kernel& kernel, Args& args, unsigned gx, unsigned gy, unsigned bx) {
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin)); launch(kernel, args, gx, gy, bx);
  CHK(hipEventRecord(end)); CHK(hipEventSynchronize(end));
  float milliseconds = 0;
  CHK(hipEventElapsedTime(&milliseconds, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return milliseconds;
}

static double median(std::vector<float> values) {
  std::sort(values.begin(), values.end());
  return values[values.size() / 2];
}

int main(int argc, char** argv) {
  if (argc < 4) {
    std::fprintf(stderr,
        "usage: %s gate|down BASELINE.hsaco CANDIDATE.hsaco [groups] [samples]\n",
        argv[0]);
    return 2;
  }
  const std::string mode = argv[1];
  if (mode != "gate" && mode != "down") return 2;
  constexpr unsigned E = 256, M = 64;
  const unsigned groups = argc > 4 ? std::strtoul(argv[4], nullptr, 10) : 96;
  const unsigned samples = argc > 5 ? std::strtoul(argv[5], nullptr, 10) : 9;
  const unsigned n = mode == "gate" ? 512 : 2048;
  const unsigned k = mode == "gate" ? 2048 : 512;
  const unsigned baseline_gx = mode == "gate" ? 8 : 128;
  const unsigned baseline_bx = mode == "gate" ? 128 : 32;
  const unsigned candidate_gx = mode == "gate" ? 32 : 128;
  const unsigned candidate_bx = 32;
  const char* baseline_symbol = mode == "gate"
      ? "mxfp4_prefill_gate_wmma_gfx1151"
      : "mxfp4_prefill_down_wmma_gfx1151";
  const char* candidate_symbol = mode == "gate"
      ? "mxfp4_m12_group_gate_wmma_gfx1151"
      : "mxfp4_m12_group_down_wmma_gfx1151";

  hipDeviceProp_t properties{}; CHK(hipGetDeviceProperties(&properties, 0));
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos)
    return 3;

  const size_t packed_bytes = size_t(E) * (k / 2) * n;
  const size_t scale_bytes = size_t(E) * (k / 32) * n;
  const size_t activation_elements = size_t(groups) * M * k;
  const size_t output_elements = size_t(groups) * M * n;
  std::vector<uint8_t> packed(packed_bytes), baseline_packed(packed_bytes);
  std::vector<uint8_t> scales(scale_bytes);
  std::vector<uint32_t> ids(groups);
  for (size_t i = 0; i < packed.size(); ++i)
    packed[i] = uint8_t((i * 37 + (i >> 11) * 13 + 17) & 255);
  for (size_t i = 0; i < scales.size(); ++i)
    scales[i] = uint8_t(118 + ((i * 5 + (i >> 9)) % 6));
  for (unsigned group = 0; group < groups; ++group)
    ids[group] = uint32_t((uint64_t(group) * E) / groups);

  if (mode == "gate") {
    for (unsigned expert = 0; expert < E; ++expert) {
      size_t expert_base = size_t(expert) * (k / 2) * n;
      for (unsigned block = 0; block < k / 32; ++block)
        for (unsigned fragment = 0; fragment < 2; ++fragment)
          for (unsigned subgroup = 0; subgroup < 2; ++subgroup)
            for (unsigned column = 0; column < n; ++column)
              for (unsigned byte = 0; byte < 4; ++byte) {
                unsigned packed_k =
                    block * 16 + fragment * 8 + subgroup * 4 + byte;
                size_t source = expert_base + size_t(packed_k) * n + column;
                size_t destination = expert_base + size_t(block) * 8192 +
                    fragment * 4096 + subgroup * 2048 + column * 4 + byte;
                baseline_packed[destination] = packed[source];
              }
    }
  } else {
    baseline_packed = packed;
  }

  uint8_t *d_packed{}, *d_baseline_packed{}, *d_scales{};
  uint16_t* d_activation{};
  float *d_baseline{}, *d_candidate{};
  uint32_t *d_ids{}, *d_mismatches{};
  CHK(hipMalloc(&d_packed, packed_bytes));
  CHK(hipMalloc(&d_baseline_packed, packed_bytes));
  CHK(hipMalloc(&d_scales, scale_bytes));
  CHK(hipMalloc(&d_activation, activation_elements * 2));
  CHK(hipMalloc(&d_baseline, output_elements * 4));
  CHK(hipMalloc(&d_candidate, output_elements * 4));
  CHK(hipMalloc(&d_ids, groups * 4));
  CHK(hipMalloc(&d_mismatches, 4));
  CHK(hipMemcpy(d_packed, packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(
      d_baseline_packed, baseline_packed.data(), packed_bytes,
      hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_scales, scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_ids, ids.data(), groups * 4, hipMemcpyHostToDevice));
  fill_bf16<<<(activation_elements + 255) / 256, 256>>>(
      d_activation, activation_elements);

  Kernel baseline = load(argv[2], baseline_symbol);
  Kernel candidate = load(argv[3], candidate_symbol);
  Args baseline_args{
      d_baseline_packed, d_scales, d_activation, d_baseline, d_ids};
  Args candidate_args{d_packed, d_scales, d_activation, d_candidate, d_ids};
  for (int i = 0; i < 3; ++i) {
    launch(baseline, baseline_args, baseline_gx, groups, baseline_bx);
    launch(candidate, candidate_args, candidate_gx, groups, candidate_bx);
  }
  CHK(hipDeviceSynchronize());
  CHK(hipMemset(d_mismatches, 0, 4));
  size_t valid_elements = size_t(groups) * 12 * n;
  compare_valid_rows<<<(valid_elements + 255) / 256, 256>>>(
      reinterpret_cast<uint32_t*>(d_baseline),
      reinterpret_cast<uint32_t*>(d_candidate), groups, n, d_mismatches);
  uint32_t mismatches = 0;
  CHK(hipMemcpy(&mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));

  std::vector<float> baseline_ms, candidate_ms;
  for (unsigned sample = 0; sample < samples; ++sample) {
    if (sample & 1) {
      candidate_ms.push_back(time_one(
          candidate, candidate_args, candidate_gx, groups, candidate_bx));
      baseline_ms.push_back(time_one(
          baseline, baseline_args, baseline_gx, groups, baseline_bx));
    } else {
      baseline_ms.push_back(time_one(
          baseline, baseline_args, baseline_gx, groups, baseline_bx));
      candidate_ms.push_back(time_one(
          candidate, candidate_args, candidate_gx, groups, candidate_bx));
    }
  }
  double baseline_median = median(baseline_ms);
  double candidate_median = median(candidate_ms);
  std::printf(
      "gfx1151 measured mode=%s groups=%u valid_rows=12 bit_equal=%s "
      "mismatches=%u baseline_median_ms=%.6f candidate_median_ms=%.6f "
      "speedup=%.6f\n",
      mode.c_str(), groups, mismatches ? "false" : "true", mismatches,
      baseline_median, candidate_median, baseline_median / candidate_median);
  std::printf("baseline_samples_ms=");
  for (float value : baseline_ms) std::printf(" %.6f", value);
  std::printf("\ncandidate_samples_ms=");
  for (float value : candidate_ms) std::printf(" %.6f", value);
  std::printf("\n");
  return mismatches ? 4 : 0;
}
