// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

namespace {
constexpr size_t kExperts = 8;
constexpr size_t kN = 2048;
constexpr size_t kK = 512;
constexpr size_t kPackedBytes = kExperts * (kK / 2) * kN;
constexpr size_t kScaleBytes = kExperts * (kK / 32) * kN;

struct alignas(8) FivePointers {
  const void* packed;
  const void* scales;
  const void* activation;
  void* output;
  const void* expert_ids;
};
static_assert(sizeof(FivePointers) == 40);

struct Kernel {
  hipModule_t module{};
  hipFunction_t function{};
};

int fail(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}

int load(Kernel& kernel, const char* path, const char* symbol) {
  if (int rc = fail(hipModuleLoad(&kernel.module, path), "hipModuleLoad")) return rc;
  return fail(hipModuleGetFunction(&kernel.function, kernel.module, symbol),
              "hipModuleGetFunction");
}

hipError_t launch(hipFunction_t function, const FivePointers& args,
                  hipStream_t stream, unsigned grid_x, unsigned block) {
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER,
                    const_cast<FivePointers*>(&args),
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(function, grid_x, 8, 1, block, 1, 1, 0,
                               stream, nullptr, config);
}

uint16_t float_to_bf16(float value) {
  uint32_t bits = std::bit_cast<uint32_t>(value);
  bits += 0x7fffu + ((bits >> 16) & 1u);
  return static_cast<uint16_t>(bits >> 16);
}

float bf16_to_float(uint16_t value) {
  return std::bit_cast<float>(static_cast<uint32_t>(value) << 16);
}

float e2m1(uint8_t nibble) {
  static constexpr float mag[8] = {0.0f, 0.5f, 1.0f, 1.5f,
                                    2.0f, 3.0f, 4.0f, 6.0f};
  float value = mag[nibble & 7u];
  return (nibble & 8u) ? -value : value;
}

float e8m0(uint8_t exponent) {
  return std::bit_cast<float>(static_cast<uint32_t>(exponent) << 23);
}

bool read_exact(const char* path, void* data, size_t bytes) {
  std::ifstream input(path, std::ios::binary);
  input.read(static_cast<char*>(data), bytes);
  return input.good() ||
         (input.eof() && static_cast<size_t>(input.gcount()) == bytes);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc != 3 && argc != 7) {
    std::cerr << "usage: " << argv[0]
              << " BASELINE_HSACO CANDIDATE_HSACO [PACKED SCALES ACTIVATION IDS]\n";
    return 2;
  }

  Kernel baseline{}, candidate{};
  if (int rc = load(baseline, argv[1], "mxfp4_decode_down_gfx1151")) return rc;
  if (int rc = load(candidate, argv[2], "mxfp4_decode_down_pipeline_gfx1151")) return rc;

  std::mt19937 rng(1151);
  std::uniform_int_distribution<int> byte_dist(0, 255);
  std::uniform_int_distribution<int> scale_dist(121, 127);
  std::uniform_real_distribution<float> activation_dist(-1.0f, 1.0f);
  std::vector<uint8_t> h_packed(kPackedBytes), h_scales(kScaleBytes);
  std::vector<uint16_t> h_activation(kExperts * kK);
  std::vector<int32_t> h_ids(kExperts);
  for (auto& x : h_packed) x = static_cast<uint8_t>(byte_dist(rng));
  for (auto& x : h_scales) x = static_cast<uint8_t>(scale_dist(rng));
  for (auto& x : h_activation) x = float_to_bf16(activation_dist(rng));
  for (size_t i = 0; i < kExperts; ++i) h_ids[i] = static_cast<int32_t>(i);
  if (argc == 7 &&
      (!read_exact(argv[3], h_packed.data(), h_packed.size()) ||
       !read_exact(argv[4], h_scales.data(), h_scales.size()) ||
       !read_exact(argv[5], h_activation.data(), h_activation.size() * 2) ||
       !read_exact(argv[6], h_ids.data(), h_ids.size() * 4))) {
    std::cerr << "failed to read exact real-weight fixture\n";
    return 3;
  }

  void *d_packed{}, *d_scales{}, *d_activation{}, *d_ids{};
  void *d_baseline_output{}, *d_candidate_output{};
#define ALLOC(ptr, bytes) if (int rc = fail(hipMalloc(&(ptr), (bytes)), "hipMalloc")) return rc
  ALLOC(d_packed, h_packed.size());
  ALLOC(d_scales, h_scales.size());
  ALLOC(d_activation, h_activation.size() * 2);
  ALLOC(d_ids, h_ids.size() * 4);
  ALLOC(d_baseline_output, kExperts * kN * 4);
  ALLOC(d_candidate_output, kExperts * kN * 4);
#undef ALLOC
#define COPY(dst, src, bytes) if (int rc = fail(hipMemcpy((dst), (src), (bytes), hipMemcpyHostToDevice), "hipMemcpy")) return rc
  COPY(d_packed, h_packed.data(), h_packed.size());
  COPY(d_scales, h_scales.data(), h_scales.size());
  COPY(d_activation, h_activation.data(), h_activation.size() * 2);
  COPY(d_ids, h_ids.data(), h_ids.size() * 4);
#undef COPY

  hipStream_t stream{};
  if (int rc = fail(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  FivePointers baseline_args{d_packed, d_scales, d_activation, d_baseline_output, d_ids};
  FivePointers candidate_args{d_packed, d_scales, d_activation, d_candidate_output, d_ids};

  if (std::getenv("NETRA_COUNTER_MODE")) {
    bool use_baseline = std::getenv("NETRA_COUNTER_BASELINE") != nullptr;
    if (int rc = fail(launch(use_baseline ? baseline.function : candidate.function,
                             use_baseline ? baseline_args : candidate_args,
                             stream, use_baseline ? 2 : 16,
                             use_baseline ? 256 : 32), "counter launch")) return rc;
    if (int rc = fail(hipStreamSynchronize(stream), "counter sync")) return rc;
    std::cout << "target=gfx1151\nmeasurement_status=measured\nvariant="
              << (use_baseline ? "baseline" : "candidate") << "\n";
    return 0;
  }

  for (int i = 0; i < 30; ++i) {
    if (int rc = fail(launch(baseline.function, baseline_args, stream, 2, 256),
                      "baseline warmup")) return rc;
    if (int rc = fail(launch(candidate.function, candidate_args, stream, 16, 32),
                      "candidate warmup")) return rc;
  }
  if (int rc = fail(hipStreamSynchronize(stream), "warmup sync")) return rc;

  std::vector<float> h_baseline(kExperts * kN), h_candidate(kExperts * kN);
  if (int rc = fail(hipMemcpy(h_baseline.data(), d_baseline_output,
                              h_baseline.size() * 4, hipMemcpyDeviceToHost),
                    "copy baseline output")) return rc;
  if (int rc = fail(hipMemcpy(h_candidate.data(), d_candidate_output,
                              h_candidate.size() * 4, hipMemcpyDeviceToHost),
                    "copy candidate output")) return rc;
  size_t mismatches = 0;
  double max_abs = 0.0;
  for (size_t i = 0; i < h_baseline.size(); ++i) {
    mismatches += std::bit_cast<uint32_t>(h_baseline[i]) !=
                  std::bit_cast<uint32_t>(h_candidate[i]);
    max_abs = std::max(max_abs,
                       std::abs(static_cast<double>(h_baseline[i]) -
                                static_cast<double>(h_candidate[i])));
  }

  // FP64 spot-check every 257th output, including all experts.
  double baseline_max_fp64 = 0.0, candidate_max_fp64 = 0.0;
  for (size_t slot = 0; slot < kExperts; ++slot) {
    const size_t expert = static_cast<size_t>(h_ids[slot]);
    for (size_t n = slot; n < kN; n += 257) {
      double reference = 0.0;
      for (size_t block = 0; block < kK / 32; ++block) {
        double block_sum = 0.0;
        for (size_t kk = 0; kk < 32; ++kk) {
          size_t k = block * 32 + kk;
          uint8_t byte = h_packed[(expert * (kK / 2) + k / 2) * kN + n];
          uint8_t code = (k & 1) ? byte >> 4 : byte & 15;
          block_sum += static_cast<double>(e2m1(code)) *
                       static_cast<double>(bf16_to_float(h_activation[slot * kK + k]));
        }
        uint8_t scale = h_scales[(expert * (kK / 32) + block) * kN + n];
        reference += block_sum * static_cast<double>(e8m0(scale));
      }
      size_t index = slot * kN + n;
      baseline_max_fp64 = std::max(baseline_max_fp64,
          std::abs(static_cast<double>(h_baseline[index]) - reference));
      candidate_max_fp64 = std::max(candidate_max_fp64,
          std::abs(static_cast<double>(h_candidate[index]) - reference));
    }
  }

  hipEvent_t begin{}, end{};
  if (int rc = fail(hipEventCreate(&begin), "hipEventCreate begin")) return rc;
  if (int rc = fail(hipEventCreate(&end), "hipEventCreate end")) return rc;
  constexpr int iterations = 1000;
  auto time = [&](hipFunction_t function, const FivePointers& args,
                  unsigned grid_x, unsigned block) {
    fail(hipEventRecord(begin, stream), "record begin");
    for (int i = 0; i < iterations; ++i)
      fail(launch(function, args, stream, grid_x, block), "timed launch");
    fail(hipEventRecord(end, stream), "record end");
    fail(hipEventSynchronize(end), "sync end");
    float ms = 0.0f;
    fail(hipEventElapsedTime(&ms, begin, end), "elapsed");
    return static_cast<double>(ms) * 1000.0 / iterations;
  };
  std::vector<double> baseline_us, candidate_us;
  for (int pass = 0; pass < 11; ++pass) {
    if (pass & 1) {
      candidate_us.push_back(time(candidate.function, candidate_args, 16, 32));
      baseline_us.push_back(time(baseline.function, baseline_args, 2, 256));
    } else {
      baseline_us.push_back(time(baseline.function, baseline_args, 2, 256));
      candidate_us.push_back(time(candidate.function, candidate_args, 16, 32));
    }
  }
  std::sort(baseline_us.begin(), baseline_us.end());
  std::sort(candidate_us.begin(), candidate_us.end());
  std::cout << std::setprecision(10)
            << "target=gfx1151\nmeasurement_status=measured\n"
            << "fp32_bit_mismatches=" << mismatches << "\n"
            << "max_abs=" << max_abs << "\n"
            << "baseline_max_abs_fp64_spot=" << baseline_max_fp64 << "\n"
            << "candidate_max_abs_fp64_spot=" << candidate_max_fp64 << "\n"
            << "baseline_median_us=" << baseline_us[5] << "\n"
            << "candidate_median_us=" << candidate_us[5] << "\n"
            << "speedup=" << baseline_us[5] / candidate_us[5] << "\n";
  return mismatches ? 4 : 0;
}
