// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

namespace {
constexpr size_t kExperts = 8, kN = 2048, kK = 512;
constexpr size_t kPackedBytes = kExperts * (kK / 2) * kN;
constexpr size_t kScaleBytes = kExperts * (kK / 32) * kN;
constexpr size_t kActivationBytes = kExperts * kK * 2;
constexpr size_t kIdsBytes = kExperts * 4;
constexpr size_t kOutputBytes = kExperts * kN * 4;

struct alignas(8) Args {
  const void* packed; const void* scales; const void* activation;
  void* output; const void* ids;
};
static_assert(sizeof(Args) == 40);
struct Kernel { hipModule_t module{}; hipFunction_t function{}; };
struct Fixture {
  void *packed{}, *scales{}, *activation{}, *ids{}, *baseline{}, *candidate{};
  Args baseline_args() const { return {packed, scales, activation, baseline, ids}; }
  Args candidate_args() const { return {packed, scales, activation, candidate, ids}; }
};

int fail(hipError_t status, const char* where) {
  if (status == hipSuccess) return 0;
  std::cerr << where << ": " << hipGetErrorString(status) << "\n";
  return static_cast<int>(status);
}
int load(Kernel& k, const char* path, const char* symbol) {
  if (int rc = fail(hipModuleLoad(&k.module, path), "hipModuleLoad")) return rc;
  return fail(hipModuleGetFunction(&k.function, k.module, symbol),
              "hipModuleGetFunction");
}
hipError_t launch(hipFunction_t fn, const Args& args, hipStream_t stream,
                  unsigned grid_x, unsigned block) {
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, const_cast<Args*>(&args),
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(fn, grid_x, 8, 1, block, 1, 1, 0,
                               stream, nullptr, config);
}
bool read_exact(const std::string& path, std::vector<uint8_t>& bytes,
                size_t expected) {
  bytes.resize(expected);
  std::ifstream input(path, std::ios::binary);
  input.read(reinterpret_cast<char*>(bytes.data()), expected);
  return input.good() ||
         (input.eof() && static_cast<size_t>(input.gcount()) == expected);
}
int upload(void** ptr, const std::string& path, size_t bytes) {
  std::vector<uint8_t> host;
  if (!read_exact(path, host, bytes)) {
    std::cerr << "failed fixture read: " << path << "\n";
    return 2;
  }
  if (int rc = fail(hipMalloc(ptr, bytes), "hipMalloc fixture")) return rc;
  return fail(hipMemcpy(*ptr, host.data(), bytes, hipMemcpyHostToDevice),
              "hipMemcpy fixture");
}
}  // namespace

int main(int argc, char** argv) {
  if (argc != 4 && argc != 6) {
    std::cerr << "usage: " << argv[0]
              << " BASELINE_HSACO CANDIDATE_HSACO MANIFEST [CANDIDATE_GRID_X CANDIDATE_BLOCK]\n";
    return 2;
  }
  Kernel baseline{}, candidate{};
  if (int rc = load(baseline, argv[1], "mxfp4_decode_down_gfx1151")) return rc;
  if (int rc = load(candidate, argv[2], "mxfp4_decode_down_pipeline_gfx1151")) return rc;
  const unsigned candidate_grid_x = argc == 6 ? static_cast<unsigned>(std::stoul(argv[4])) : 16;
  const unsigned candidate_block = argc == 6 ? static_cast<unsigned>(std::stoul(argv[5])) : 32;

  std::ifstream manifest(argv[3]);
  std::vector<Fixture> fixtures;
  std::string packed, scales, activation, ids;
  while (manifest >> packed >> scales >> activation >> ids) {
    Fixture f{};
    if (int rc = upload(&f.packed, packed, kPackedBytes)) return rc;
    if (int rc = upload(&f.scales, scales, kScaleBytes)) return rc;
    if (int rc = upload(&f.activation, activation, kActivationBytes)) return rc;
    if (int rc = upload(&f.ids, ids, kIdsBytes)) return rc;
    if (int rc = fail(hipMalloc(&f.baseline, kOutputBytes), "hipMalloc output")) return rc;
    if (int rc = fail(hipMalloc(&f.candidate, kOutputBytes), "hipMalloc output")) return rc;
    fixtures.push_back(f);
  }
  if (fixtures.empty()) {
    std::cerr << "empty fixture manifest\n";
    return 3;
  }

  hipStream_t stream{};
  if (int rc = fail(hipStreamCreate(&stream), "hipStreamCreate")) return rc;
  for (int warmup = 0; warmup < 5; ++warmup) {
    for (const auto& f : fixtures) {
      Args a = f.baseline_args();
      if (int rc = fail(launch(baseline.function, a, stream, 2, 256), "baseline warmup")) return rc;
    }
    for (const auto& f : fixtures) {
      Args a = f.candidate_args();
      if (int rc = fail(launch(candidate.function, a, stream, candidate_grid_x, candidate_block), "candidate warmup")) return rc;
    }
  }
  if (int rc = fail(hipStreamSynchronize(stream), "warmup sync")) return rc;

  size_t mismatches = 0;
  std::vector<uint32_t> old(kOutputBytes / 4), now(kOutputBytes / 4);
  for (const auto& f : fixtures) {
    if (int rc = fail(hipMemcpy(old.data(), f.baseline, kOutputBytes,
                                hipMemcpyDeviceToHost), "copy baseline")) return rc;
    if (int rc = fail(hipMemcpy(now.data(), f.candidate, kOutputBytes,
                                hipMemcpyDeviceToHost), "copy candidate")) return rc;
    for (size_t i = 0; i < old.size(); ++i) mismatches += old[i] != now[i];
  }

  hipEvent_t begin{}, end{};
  if (int rc = fail(hipEventCreate(&begin), "create event")) return rc;
  if (int rc = fail(hipEventCreate(&end), "create event")) return rc;
  constexpr int cycles = 20;
  auto time = [&](hipFunction_t fn, bool use_candidate) {
    fail(hipEventRecord(begin, stream), "record begin");
    for (int cycle = 0; cycle < cycles; ++cycle) {
      for (const auto& f : fixtures) {
        Args a = use_candidate ? f.candidate_args() : f.baseline_args();
        fail(launch(fn, a, stream, use_candidate ? candidate_grid_x : 2,
                    use_candidate ? candidate_block : 256), "timed launch");
      }
    }
    fail(hipEventRecord(end, stream), "record end");
    fail(hipEventSynchronize(end), "sync event");
    float ms = 0.0f;
    fail(hipEventElapsedTime(&ms, begin, end), "elapsed");
    return static_cast<double>(ms) * 1000.0 /
           static_cast<double>(cycles * fixtures.size());
  };
  std::vector<double> baseline_us, candidate_us;
  for (int pass = 0; pass < 11; ++pass) {
    if (pass & 1) {
      candidate_us.push_back(time(candidate.function, true));
      baseline_us.push_back(time(baseline.function, false));
    } else {
      baseline_us.push_back(time(baseline.function, false));
      candidate_us.push_back(time(candidate.function, true));
    }
  }
  std::sort(baseline_us.begin(), baseline_us.end());
  std::sort(candidate_us.begin(), candidate_us.end());
  std::cout << std::setprecision(10)
            << "target=gfx1151\nmeasurement_status=measured\n"
            << "real_checkpoint_layers=" << fixtures.size() << "\n"
            << "fp32_bit_mismatches=" << mismatches << "\n"
            << "baseline_rotating_median_us=" << baseline_us[5] << "\n"
            << "candidate_rotating_median_us=" << candidate_us[5] << "\n"
            << "speedup=" << baseline_us[5] / candidate_us[5] << "\n";
  return mismatches ? 4 : 0;
}
