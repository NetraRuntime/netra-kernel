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
constexpr size_t kN = 512;
constexpr size_t kK = 2048;
constexpr size_t kSlots = 8;

struct alignas(8) FivePointers {
  const void* packed;
  const void* scales;
  const void* activation;
  void* output;
  const void* expert_ids;
};
static_assert(sizeof(FivePointers) == 40);

int fail(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}

hipError_t launch(hipFunction_t fn, unsigned gx, unsigned gy,
                  unsigned block, const FivePointers& args,
                  hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER,
                    const_cast<FivePointers*>(&args),
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(fn, gx, gy, 1, block, 1, 1, 0,
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

struct Pair {
  hipModule_t compute_module{};
  hipModule_t reduce_module{};
  hipFunction_t compute{};
  hipFunction_t reduce{};
  unsigned compute_gy{};
};

int load_pair(Pair& pair, const char* compute_path, const char* compute_symbol,
              const char* reduce_path, const char* reduce_symbol,
              unsigned compute_gy) {
  if (int rc = fail(hipModuleLoad(&pair.compute_module, compute_path),
                    "hipModuleLoad compute")) return rc;
  if (int rc = fail(hipModuleLoad(&pair.reduce_module, reduce_path),
                    "hipModuleLoad reduce")) return rc;
  if (int rc = fail(hipModuleGetFunction(&pair.compute, pair.compute_module,
                                         compute_symbol),
                    "hipModuleGetFunction compute")) return rc;
  if (int rc = fail(hipModuleGetFunction(&pair.reduce, pair.reduce_module,
                                         reduce_symbol),
                    "hipModuleGetFunction reduce")) return rc;
  pair.compute_gy = compute_gy;
  return 0;
}

hipError_t launch_pair(const Pair& pair, const void* packed, const void* scales,
                       const void* activation, const void* ids, void* partial,
                       void* output, hipStream_t stream) {
  FivePointers compute_args{packed, scales, activation, partial, ids};
  hipError_t status = launch(pair.compute, 1, pair.compute_gy, 128,
                             compute_args, stream);
  if (status != hipSuccess) return status;
  FivePointers reduce_args{partial, scales, output, nullptr, ids};
  return launch(pair.reduce, 2, 8, 128, reduce_args, stream);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc != 5 && argc != 9) {
    std::cerr << "usage: " << argv[0]
              << " BLOCK64_HSACO BLOCK64_REDUCE_HSACO CHUNK4_HSACO CHUNK4_REDUCE_HSACO"
              << " [PACKED SCALE ACTIVATION IDS]\n";
    return 2;
  }

  Pair baseline{}, chunk4{};
  if (int rc = load_pair(baseline, argv[1],
                         "mxfp4_decode_gate_block64_gfx1151", argv[2],
                         "mxfp4_decode_gate_block64_reduce_gfx1151", 512))
    return rc;
  if (int rc = load_pair(chunk4, argv[3],
                         "mxfp4_decode_gate_chunk4_gfx1151", argv[4],
                         "mxfp4_decode_gate_chunk4_reduce_gfx1151", 128))
    return rc;

  std::mt19937 rng(731);
  std::uniform_int_distribution<int> nibble(0, 15);
  std::uniform_int_distribution<int> exponent(121, 127);
  std::uniform_real_distribution<float> activation_dist(-1.0f, 1.0f);

  std::vector<uint8_t> h_packed(kExperts * (kK / 2) * kN);
  for (auto& value : h_packed)
    value = static_cast<uint8_t>(nibble(rng) | (nibble(rng) << 4));
  std::vector<uint8_t> h_scales(kExperts * (kK / 32) * kN);
  for (auto& value : h_scales) value = static_cast<uint8_t>(exponent(rng));
  std::vector<uint16_t> h_activation(kK);
  for (auto& value : h_activation)
    value = float_to_bf16(activation_dist(rng));
  std::vector<int32_t> h_ids(kSlots);
  for (size_t i = 0; i < kSlots; ++i) h_ids[i] = static_cast<int32_t>(i);
  if (argc == 9) {
    auto read_exact = [](const char* path, void* data, size_t bytes) {
      std::ifstream input(path, std::ios::binary);
      input.read(static_cast<char*>(data), bytes);
      return input.good() || (input.eof() && static_cast<size_t>(input.gcount()) == bytes);
    };
    if (!read_exact(argv[5], h_packed.data(), h_packed.size()) ||
        !read_exact(argv[6], h_scales.data(), h_scales.size()) ||
        !read_exact(argv[7], h_activation.data(), h_activation.size() * 2) ||
        !read_exact(argv[8], h_ids.data(), h_ids.size() * 4)) {
      std::cerr << "failed to read exact real-weight fixture\n";
      return 3;
    }
  }

  void *d_packed{}, *d_scales{}, *d_activation{}, *d_ids{};
  void *d_baseline_partial{}, *d_chunk4_partial{};
  void *d_baseline_output{}, *d_chunk4_output{};
  if (int rc = fail(hipMalloc(&d_packed, h_packed.size()), "hipMalloc packed")) return rc;
  if (int rc = fail(hipMalloc(&d_scales, h_scales.size()), "hipMalloc scales")) return rc;
  if (int rc = fail(hipMalloc(&d_activation, h_activation.size() * 2), "hipMalloc activation")) return rc;
  if (int rc = fail(hipMalloc(&d_ids, h_ids.size() * 4), "hipMalloc ids")) return rc;
  if (int rc = fail(hipMalloc(&d_baseline_partial, 64 * kSlots * kN * 4), "hipMalloc baseline partial")) return rc;
  if (int rc = fail(hipMalloc(&d_chunk4_partial, 16 * kSlots * kN * 4), "hipMalloc chunk4 partial")) return rc;
  if (int rc = fail(hipMalloc(&d_baseline_output, kSlots * kN * 4), "hipMalloc baseline output")) return rc;
  if (int rc = fail(hipMalloc(&d_chunk4_output, kSlots * kN * 4), "hipMalloc chunk4 output")) return rc;
  if (int rc = fail(hipMemcpy(d_packed, h_packed.data(), h_packed.size(), hipMemcpyHostToDevice), "copy packed")) return rc;
  if (int rc = fail(hipMemcpy(d_scales, h_scales.data(), h_scales.size(), hipMemcpyHostToDevice), "copy scales")) return rc;
  if (int rc = fail(hipMemcpy(d_activation, h_activation.data(), h_activation.size() * 2, hipMemcpyHostToDevice), "copy activation")) return rc;
  if (int rc = fail(hipMemcpy(d_ids, h_ids.data(), h_ids.size() * 4, hipMemcpyHostToDevice), "copy ids")) return rc;

  hipStream_t stream{};
  if (int rc = fail(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  if (std::getenv("NETRA_COUNTER_MODE")) {
    const bool use_baseline = std::getenv("NETRA_COUNTER_BASELINE") != nullptr;
    const Pair& counter_pair = use_baseline ? baseline : chunk4;
    void* counter_partial = use_baseline ? d_baseline_partial : d_chunk4_partial;
    void* counter_output = use_baseline ? d_baseline_output : d_chunk4_output;
    if (int rc = fail(launch_pair(counter_pair, d_packed, d_scales, d_activation,
                                  d_ids, counter_partial,
                                  counter_output, stream), "counter launch")) return rc;
    if (int rc = fail(hipStreamSynchronize(stream), "counter sync")) return rc;
    std::cout << "gfx1151 measured " << (use_baseline ? "block64" : "chunk4") << " counter dispatch\n";
    return 0;
  }
  for (int i = 0; i < 20; ++i) {
    if (int rc = fail(launch_pair(baseline, d_packed, d_scales, d_activation,
                                  d_ids, d_baseline_partial,
                                  d_baseline_output, stream), "baseline warmup")) return rc;
    if (int rc = fail(launch_pair(chunk4, d_packed, d_scales, d_activation,
                                  d_ids, d_chunk4_partial,
                                  d_chunk4_output, stream), "chunk4 warmup")) return rc;
  }
  if (int rc = fail(hipStreamSynchronize(stream), "warmup sync")) return rc;

  std::vector<float> h_baseline(kSlots * kN), h_chunk4(kSlots * kN);
  if (int rc = fail(hipMemcpy(h_baseline.data(), d_baseline_output,
                              h_baseline.size() * 4, hipMemcpyDeviceToHost),
                    "copy baseline output")) return rc;
  if (int rc = fail(hipMemcpy(h_chunk4.data(), d_chunk4_output,
                              h_chunk4.size() * 4, hipMemcpyDeviceToHost),
                    "copy chunk4 output")) return rc;

  size_t mismatches = 0;
  double max_abs = 0.0;
  double baseline_max_fp64 = 0.0, chunk4_max_fp64 = 0.0;
  double baseline_sum_fp64 = 0.0, chunk4_sum_fp64 = 0.0;
  for (size_t slot = 0; slot < kSlots; ++slot) {
    for (size_t n = 0; n < kN; ++n) {
      const size_t index = slot * kN + n;
      mismatches += std::bit_cast<uint32_t>(h_baseline[index]) !=
                    std::bit_cast<uint32_t>(h_chunk4[index]);
      max_abs = std::max(max_abs, std::abs(static_cast<double>(
                                        h_baseline[index] - h_chunk4[index])));
      double reference = 0.0;
      for (size_t block = 0; block < kK / 32; ++block) {
        double block_sum = 0.0;
        for (size_t kk = 0; kk < 32; ++kk) {
          const size_t k = block * 32 + kk;
          uint8_t byte = h_packed[(slot * (kK / 2) + k / 2) * kN + n];
          uint8_t code = (k & 1) ? byte >> 4 : byte & 15;
          block_sum += static_cast<double>(e2m1(code)) *
                       bf16_to_float(h_activation[k]);
        }
        uint8_t scale = h_scales[(slot * (kK / 32) + block) * kN + n];
        reference += block_sum * static_cast<double>(e8m0(scale));
      }
      double baseline_error = std::abs(static_cast<double>(h_baseline[index]) - reference);
      double chunk4_error = std::abs(static_cast<double>(h_chunk4[index]) - reference);
      baseline_max_fp64 = std::max(baseline_max_fp64, baseline_error);
      chunk4_max_fp64 = std::max(chunk4_max_fp64, chunk4_error);
      baseline_sum_fp64 += baseline_error;
      chunk4_sum_fp64 += chunk4_error;
    }
  }

  hipEvent_t begin{}, end{};
  if (int rc = fail(hipEventCreate(&begin), "hipEventCreate begin")) return rc;
  if (int rc = fail(hipEventCreate(&end), "hipEventCreate end")) return rc;
  constexpr int iterations = 1000;
  auto time_pair = [&](const Pair& pair, void* partial, void* output) {
    fail(hipEventRecord(begin, stream), "record begin");
    for (int i = 0; i < iterations; ++i)
      fail(launch_pair(pair, d_packed, d_scales, d_activation, d_ids,
                       partial, output, stream), "timed pair");
    fail(hipEventRecord(end, stream), "record end");
    fail(hipEventSynchronize(end), "sync end");
    float ms = 0.0f;
    fail(hipEventElapsedTime(&ms, begin, end), "elapsed");
    return ms * 1000.0 / iterations;
  };

  std::vector<double> baseline_us, chunk4_us;
  for (int pass = 0; pass < 11; ++pass) {
    if (pass & 1) {
      chunk4_us.push_back(time_pair(chunk4, d_chunk4_partial, d_chunk4_output));
      baseline_us.push_back(time_pair(baseline, d_baseline_partial, d_baseline_output));
    } else {
      baseline_us.push_back(time_pair(baseline, d_baseline_partial, d_baseline_output));
      chunk4_us.push_back(time_pair(chunk4, d_chunk4_partial, d_chunk4_output));
    }
  }
  std::sort(baseline_us.begin(), baseline_us.end());
  std::sort(chunk4_us.begin(), chunk4_us.end());

  std::cout << std::setprecision(10)
            << "gfx1151 measured mismatches=" << mismatches
            << " max_abs=" << max_abs
            << " baseline_max_abs_fp64=" << baseline_max_fp64
            << " chunk4_max_abs_fp64=" << chunk4_max_fp64
            << " baseline_mean_abs_fp64=" << baseline_sum_fp64 / h_baseline.size()
            << " chunk4_mean_abs_fp64=" << chunk4_sum_fp64 / h_chunk4.size()
            << " baseline_pair_median_us=" << baseline_us[5]
            << " chunk4_pair_median_us=" << chunk4_us[5]
            << " speedup=" << baseline_us[5] / chunk4_us[5] << "\n";
  return 0;
}
