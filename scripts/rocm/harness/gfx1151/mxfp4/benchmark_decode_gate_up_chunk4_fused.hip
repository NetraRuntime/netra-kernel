// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <bit>
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
constexpr size_t kSlots = 8;
constexpr size_t kN = 512;
constexpr size_t kK = 2048;
constexpr size_t kPackedBytes = kExperts * (kK / 2) * kN;
constexpr size_t kScaleBytes = kExperts * (kK / 32) * kN;
constexpr size_t kPartialBytes = 16 * kSlots * kN * sizeof(float);

struct ModuleFunction { hipModule_t module{}; hipFunction_t function{}; };
struct alignas(8) FivePointers {
  const void* packed; const void* scales; const void* activation;
  void* output; const void* expert_ids;
};
struct alignas(8) ThreePointers { const void* a; const void* b; void* output; };
struct alignas(8) SevenPointers {
  const void* gate_packed; const void* gate_scales;
  const void* up_packed; const void* up_scales;
  const void* activation; void* partials; const void* expert_ids;
};
struct alignas(8) TwoPointers { const void* partials; void* output; };
static_assert(sizeof(FivePointers) == 40);
static_assert(sizeof(ThreePointers) == 24);
static_assert(sizeof(SevenPointers) == 56);
static_assert(sizeof(TwoPointers) == 16);

int fail(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}

int load(ModuleFunction& kernel, const char* path, const char* symbol) {
  if (int rc = fail(hipModuleLoad(&kernel.module, path), "hipModuleLoad")) return rc;
  return fail(hipModuleGetFunction(&kernel.function, kernel.module, symbol),
              "hipModuleGetFunction");
}

template <typename Args>
hipError_t launch(hipFunction_t function, unsigned gx, unsigned gy,
                  unsigned block, const Args& args, hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER,
                    const_cast<Args*>(&args),
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(function, gx, gy, 1, block, 1, 1, 0,
                               stream, nullptr, config);
}

struct Pipeline {
  ModuleFunction compute, reduce, silu, fused_compute, fused_reduce;
};

hipError_t launch_baseline(const Pipeline& p,
                           const void* gate_packed, const void* gate_scales,
                           const void* up_packed, const void* up_scales,
                           const void* activation, const void* ids,
                           void* gate_partial, void* up_partial,
                           void* gate_output, void* up_output,
                           void* output, hipStream_t stream) {
  FivePointers gate_compute{gate_packed, gate_scales, activation,
                            gate_partial, ids};
  FivePointers gate_reduce{gate_partial, gate_scales, gate_output, nullptr, ids};
  FivePointers up_compute{up_packed, up_scales, activation, up_partial, ids};
  FivePointers up_reduce{up_partial, up_scales, up_output, nullptr, ids};
  ThreePointers silu{gate_output, up_output, output};
  hipError_t status = launch(p.compute.function, 1, 128, 128,
                             gate_compute, stream);
  if (status != hipSuccess) return status;
  status = launch(p.reduce.function, 2, 8, 128, gate_reduce, stream);
  if (status != hipSuccess) return status;
  status = launch(p.compute.function, 1, 128, 128, up_compute, stream);
  if (status != hipSuccess) return status;
  status = launch(p.reduce.function, 2, 8, 128, up_reduce, stream);
  if (status != hipSuccess) return status;
  return launch(p.silu.function, 16, 1, 256, silu, stream);
}

hipError_t launch_candidate(const Pipeline& p,
                            const void* gate_packed, const void* gate_scales,
                            const void* up_packed, const void* up_scales,
                            const void* activation, const void* ids,
                            void* partials, void* output, hipStream_t stream) {
  SevenPointers compute{gate_packed, gate_scales, up_packed, up_scales,
                        activation, partials, ids};
  TwoPointers reduce{partials, output};
  hipError_t status = launch(p.fused_compute.function, 1, 128, 128,
                             compute, stream);
  if (status != hipSuccess) return status;
  return launch(p.fused_reduce.function, 2, 8, 128, reduce, stream);
}

double median(std::vector<double> values) {
  std::sort(values.begin(), values.end());
  return values[values.size() / 2];
}
}  // namespace

int main(int argc, char** argv) {
  if (argc != 6 && argc != 12) {
    std::cerr << "usage: " << argv[0]
              << " CHUNK4 CHUNK4_REDUCE SILU FUSED_COMPUTE FUSED_REDUCE [GATE_PACKED GATE_SCALES UP_PACKED UP_SCALES ACTIVATION IDS]\n";
    return 2;
  }
  Pipeline p{};
  if (int rc = load(p.compute, argv[1], "mxfp4_decode_gate_chunk4_gfx1151")) return rc;
  if (int rc = load(p.reduce, argv[2], "mxfp4_decode_gate_chunk4_reduce_gfx1151")) return rc;
  if (int rc = load(p.silu, argv[3], "silu_mul_bf16_gfx1151")) return rc;
  if (int rc = load(p.fused_compute, argv[4], "mxfp4_decode_gate_up_chunk4_fused_gfx1151")) return rc;
  if (int rc = load(p.fused_reduce, argv[5], "mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151")) return rc;

  std::mt19937 rng(1151);
  std::uniform_int_distribution<int> byte_dist(0, 255);
  std::uniform_int_distribution<int> scale_dist(121, 127);
  std::uniform_real_distribution<float> activation_dist(-1.0f, 1.0f);
  std::vector<uint8_t> h_gate_packed(kPackedBytes), h_up_packed(kPackedBytes);
  std::vector<uint8_t> h_gate_scales(kScaleBytes), h_up_scales(kScaleBytes);
  for (auto& x : h_gate_packed) x = static_cast<uint8_t>(byte_dist(rng));
  for (auto& x : h_up_packed) x = static_cast<uint8_t>(byte_dist(rng));
  for (auto& x : h_gate_scales) x = static_cast<uint8_t>(scale_dist(rng));
  for (auto& x : h_up_scales) x = static_cast<uint8_t>(scale_dist(rng));
  std::vector<uint16_t> h_activation(kK);
  for (auto& x : h_activation) {
    uint32_t bits = std::bit_cast<uint32_t>(activation_dist(rng));
    bits += 0x7fffu + ((bits >> 16) & 1u);
    x = static_cast<uint16_t>(bits >> 16);
  }
  std::vector<int32_t> h_ids(kSlots);
  for (size_t i = 0; i < kSlots; ++i) h_ids[i] = static_cast<int32_t>(i);

  if (argc == 12) {
    auto read_exact = [](const char* path, void* data, size_t bytes) {
      std::ifstream input(path, std::ios::binary);
      input.read(static_cast<char*>(data), bytes);
      return input.good() || (input.eof() && static_cast<size_t>(input.gcount()) == bytes);
    };
    if (!read_exact(argv[6], h_gate_packed.data(), kPackedBytes) ||
        !read_exact(argv[7], h_gate_scales.data(), kScaleBytes) ||
        !read_exact(argv[8], h_up_packed.data(), kPackedBytes) ||
        !read_exact(argv[9], h_up_scales.data(), kScaleBytes) ||
        !read_exact(argv[10], h_activation.data(), kK * 2) ||
        !read_exact(argv[11], h_ids.data(), kSlots * 4)) {
      std::cerr << "failed to read exact real-weight fixture\n";
      return 3;
    }
  }

  void *d_gate_packed{}, *d_up_packed{}, *d_gate_scales{}, *d_up_scales{};
  void *d_activation{}, *d_ids{}, *d_gate_partial{}, *d_up_partial{};
  void *d_gate_output{}, *d_up_output{}, *d_baseline_output{};
  void *d_fused_partial{}, *d_candidate_output{};
#define ALLOC(ptr, bytes) if (int rc = fail(hipMalloc(&(ptr), (bytes)), "hipMalloc")) return rc
  ALLOC(d_gate_packed, kPackedBytes); ALLOC(d_up_packed, kPackedBytes);
  ALLOC(d_gate_scales, kScaleBytes); ALLOC(d_up_scales, kScaleBytes);
  ALLOC(d_activation, kK * 2); ALLOC(d_ids, kSlots * 4);
  ALLOC(d_gate_partial, kPartialBytes); ALLOC(d_up_partial, kPartialBytes);
  ALLOC(d_gate_output, kSlots * kN * 4); ALLOC(d_up_output, kSlots * kN * 4);
  ALLOC(d_baseline_output, kSlots * kN * 2);
  ALLOC(d_fused_partial, 2 * kPartialBytes);
  ALLOC(d_candidate_output, kSlots * kN * 2);
#undef ALLOC
#define COPY(dst, src, bytes) if (int rc = fail(hipMemcpy((dst), (src), (bytes), hipMemcpyHostToDevice), "hipMemcpy")) return rc
  COPY(d_gate_packed, h_gate_packed.data(), kPackedBytes);
  COPY(d_up_packed, h_up_packed.data(), kPackedBytes);
  COPY(d_gate_scales, h_gate_scales.data(), kScaleBytes);
  COPY(d_up_scales, h_up_scales.data(), kScaleBytes);
  COPY(d_activation, h_activation.data(), kK * 2);
  COPY(d_ids, h_ids.data(), kSlots * 4);
#undef COPY

  hipStream_t stream{};
  if (int rc = fail(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  for (int i = 0; i < 20; ++i) {
    if (int rc = fail(launch_baseline(p, d_gate_packed, d_gate_scales,
                                      d_up_packed, d_up_scales, d_activation,
                                      d_ids, d_gate_partial, d_up_partial,
                                      d_gate_output, d_up_output,
                                      d_baseline_output, stream), "baseline warmup")) return rc;
    if (int rc = fail(launch_candidate(p, d_gate_packed, d_gate_scales,
                                       d_up_packed, d_up_scales, d_activation,
                                       d_ids, d_fused_partial,
                                       d_candidate_output, stream), "candidate warmup")) return rc;
  }
  if (int rc = fail(hipStreamSynchronize(stream), "warmup sync")) return rc;

  std::vector<uint8_t> h_gate_partial(kPartialBytes), h_up_partial(kPartialBytes);
  std::vector<uint8_t> h_fused_partial(2 * kPartialBytes);
  std::vector<uint16_t> h_baseline(kSlots * kN), h_candidate(kSlots * kN);
  if (int rc = fail(hipMemcpy(h_gate_partial.data(), d_gate_partial, kPartialBytes, hipMemcpyDeviceToHost), "copy gate partial")) return rc;
  if (int rc = fail(hipMemcpy(h_up_partial.data(), d_up_partial, kPartialBytes, hipMemcpyDeviceToHost), "copy up partial")) return rc;
  if (int rc = fail(hipMemcpy(h_fused_partial.data(), d_fused_partial, 2 * kPartialBytes, hipMemcpyDeviceToHost), "copy fused partial")) return rc;
  if (int rc = fail(hipMemcpy(h_baseline.data(), d_baseline_output, h_baseline.size() * 2, hipMemcpyDeviceToHost), "copy baseline")) return rc;
  if (int rc = fail(hipMemcpy(h_candidate.data(), d_candidate_output, h_candidate.size() * 2, hipMemcpyDeviceToHost), "copy candidate")) return rc;
  size_t gate_partial_mismatches = 0, up_partial_mismatches = 0, output_mismatches = 0;
  for (size_t i = 0; i < kPartialBytes; ++i) {
    gate_partial_mismatches += h_gate_partial[i] != h_fused_partial[i];
    up_partial_mismatches += h_up_partial[i] != h_fused_partial[kPartialBytes + i];
  }
  for (size_t i = 0; i < h_baseline.size(); ++i)
    output_mismatches += h_baseline[i] != h_candidate[i];

  hipEvent_t begin{}, end{};
  if (int rc = fail(hipEventCreate(&begin), "event begin")) return rc;
  if (int rc = fail(hipEventCreate(&end), "event end")) return rc;
  constexpr int iterations = 500;
  auto time = [&](bool candidate) {
    fail(hipEventRecord(begin, stream), "record begin");
    for (int i = 0; i < iterations; ++i) {
      if (candidate)
        fail(launch_candidate(p, d_gate_packed, d_gate_scales, d_up_packed,
                              d_up_scales, d_activation, d_ids,
                              d_fused_partial, d_candidate_output, stream), "timed candidate");
      else
        fail(launch_baseline(p, d_gate_packed, d_gate_scales, d_up_packed,
                             d_up_scales, d_activation, d_ids,
                             d_gate_partial, d_up_partial, d_gate_output,
                             d_up_output, d_baseline_output, stream), "timed baseline");
    }
    fail(hipEventRecord(end, stream), "record end");
    fail(hipEventSynchronize(end), "sync end");
    float ms = 0;
    fail(hipEventElapsedTime(&ms, begin, end), "elapsed");
    return static_cast<double>(ms) * 1000.0 / iterations;
  };
  std::vector<double> baseline_us, candidate_us;
  for (int pass = 0; pass < 11; ++pass) {
    if (pass & 1) { candidate_us.push_back(time(true)); baseline_us.push_back(time(false)); }
    else { baseline_us.push_back(time(false)); candidate_us.push_back(time(true)); }
  }
  const double baseline_median = median(baseline_us);
  const double candidate_median = median(candidate_us);
  std::cout << std::fixed << std::setprecision(6)
            << "target=gfx1151\nmeasurement_status=measured\n"
            << "gate_partial_byte_mismatches=" << gate_partial_mismatches << "\n"
            << "up_partial_byte_mismatches=" << up_partial_mismatches << "\n"
            << "output_bf16_mismatches=" << output_mismatches << "\n"
            << "baseline_five_launch_median_us=" << baseline_median << "\n"
            << "candidate_two_launch_median_us=" << candidate_median << "\n"
            << "speedup=" << baseline_median / candidate_median << "\n";
  return (gate_partial_mismatches || up_partial_mismatches || output_mismatches) ? 4 : 0;
}
