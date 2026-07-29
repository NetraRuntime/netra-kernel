// Exact-shape correctness and HIP-event harness; all compute/repack kernels are raw gfx1151 ASM.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#define CHK(x) do { hipError_t e_=(x); if(e_!=hipSuccess) { \
  std::fprintf(stderr,"HIP error %s at %d\n",hipGetErrorString(e_),__LINE__); \
  std::exit(1); } } while(0)

struct Kernel { hipModule_t module{}; hipFunction_t function{}; };
struct ComputeArgs { void* packed; void* scales; void* activation; void* output; unsigned n; unsigned k; };
struct RepackArgs { void* source; void* destination; unsigned n; };

static Kernel load(const char* path, const char* symbol) {
  Kernel result;
  CHK(hipModuleLoad(&result.module, path));
  CHK(hipModuleGetFunction(&result.function, result.module, symbol));
  return result;
}

static void launch(const Kernel& kernel, ComputeArgs& args, unsigned groups,
                   hipStream_t stream = nullptr) {
  void* params[] = {&args.packed, &args.scales, &args.activation,
                    &args.output, &args.n, &args.k};
  CHK(hipModuleLaunchKernel(kernel.function, args.n / 16, groups, 1,
                            32, 1, 1, 0, stream, params, nullptr));
}

static void launch_repack(const Kernel& kernel, RepackArgs& args, unsigned k,
                          hipStream_t stream = nullptr) {
  void* params[] = {&args.source, &args.destination, &args.n};
  CHK(hipModuleLaunchKernel(kernel.function, args.n / 8, k / 32, 1,
                            32, 1, 1, 0, stream, params, nullptr));
}

static float time_compute(const Kernel& kernel, ComputeArgs& args, unsigned groups) {
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin)); launch(kernel, args, groups); CHK(hipEventRecord(end));
  CHK(hipEventSynchronize(end));
  float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return ms;
}

static float time_repack(const Kernel& kernel, RepackArgs& args, unsigned k) {
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin)); launch_repack(kernel, args, k); CHK(hipEventRecord(end));
  CHK(hipEventSynchronize(end));
  float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return ms;
}

static double median(std::vector<float> values) {
  std::sort(values.begin(), values.end()); return values[values.size() / 2];
}

int main(int argc, char** argv) {
  if (argc < 7) {
    std::fprintf(stderr, "usage: %s BASELINE.hsaco CANDIDATE.hsaco REPACK.hsaco N K GROUPS [samples]\n", argv[0]);
    return 2;
  }
  constexpr unsigned M = 64;
  const unsigned n = std::strtoul(argv[4], nullptr, 10);
  const unsigned k = std::strtoul(argv[5], nullptr, 10);
  const unsigned groups = std::strtoul(argv[6], nullptr, 10);
  const unsigned samples = argc > 7 ? std::strtoul(argv[7], nullptr, 10) : 11;
  if ((n % 16) || (k % 32) || !groups || !samples) return 2;
  hipDeviceProp_t properties{}; CHK(hipGetDeviceProperties(&properties, 0));
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos) return 3;

  const size_t packed_bytes = size_t(k / 2) * n;
  const size_t scale_bytes = size_t(k / 32) * n;
  const size_t activation_bytes = size_t(groups) * M * k * 2;
  const size_t output_elements = size_t(groups) * M * n;
  std::vector<uint8_t> packed(packed_bytes), oracle(packed_bytes), scales(scale_bytes);
  for (size_t i = 0; i < packed.size(); ++i)
    packed[i] = uint8_t((i * 37 + (i >> 11) * 13 + 17) & 255);
  for (size_t i = 0; i < scales.size(); ++i)
    scales[i] = uint8_t(118 + ((i * 5 + (i >> 9)) % 6));

  // [K/2,N] -> [K32,fragment,subgroup,N,four packed K bytes].
  for (unsigned block = 0; block < k / 32; ++block)
    for (unsigned fragment = 0; fragment < 2; ++fragment)
      for (unsigned subgroup = 0; subgroup < 2; ++subgroup)
        for (unsigned column = 0; column < n; ++column)
          for (unsigned byte = 0; byte < 4; ++byte) {
            const unsigned packed_k = block * 16 + fragment * 8 + subgroup * 4 + byte;
            const size_t source = size_t(packed_k) * n + column;
            const size_t destination = size_t(block) * n * 16 +
                fragment * n * 8 + subgroup * n * 4 + column * 4 + byte;
            oracle[destination] = packed[source];
          }

  uint8_t *d_packed{}, *d_repacked{}, *d_scales{}, *d_activation{};
  float *d_baseline{}, *d_candidate{};
  CHK(hipMalloc(&d_packed, packed_bytes)); CHK(hipMalloc(&d_repacked, packed_bytes));
  CHK(hipMalloc(&d_scales, scale_bytes)); CHK(hipMalloc(&d_activation, activation_bytes));
  CHK(hipMalloc(&d_baseline, output_elements * sizeof(float)));
  CHK(hipMalloc(&d_candidate, output_elements * sizeof(float)));
  CHK(hipMemcpy(d_packed, packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_scales, scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemset(d_activation, 0x3f, activation_bytes));

  Kernel baseline = load(argv[1], "mxfp4_sgl_linear_prefill_wmma_gfx1151");
  Kernel candidate = load(argv[2], "mxfp4_sgl_linear_prefill_dword_layout_gfx1151");
  Kernel repacker = load(argv[3], "mxfp4_sgl_linear_prefill_repack_dword_gfx1151");
  RepackArgs repack_args{d_packed, d_repacked, n};
  launch_repack(repacker, repack_args, k); CHK(hipDeviceSynchronize());
  std::vector<uint8_t> actual_repacked(packed_bytes);
  CHK(hipMemcpy(actual_repacked.data(), d_repacked, packed_bytes, hipMemcpyDeviceToHost));
  const bool repack_equal = actual_repacked == oracle;

  ComputeArgs baseline_args{d_packed, d_scales, d_activation, d_baseline, n, k};
  ComputeArgs candidate_args{d_repacked, d_scales, d_activation, d_candidate, n, k};
  for (int i = 0; i < 3; ++i) {
    launch(baseline, baseline_args, groups); launch(candidate, candidate_args, groups);
  }
  CHK(hipDeviceSynchronize());

  std::vector<float> baseline_ms, candidate_ms, repack_ms;
  for (unsigned i = 0; i < samples; ++i) {
    repack_ms.push_back(time_repack(repacker, repack_args, k));
    if (i & 1) {
      candidate_ms.push_back(time_compute(candidate, candidate_args, groups));
      baseline_ms.push_back(time_compute(baseline, baseline_args, groups));
    } else {
      baseline_ms.push_back(time_compute(baseline, baseline_args, groups));
      candidate_ms.push_back(time_compute(candidate, candidate_args, groups));
    }
  }

  std::vector<float> eager_snapshot(size_t(M) * n);
  CHK(hipMemcpy(eager_snapshot.data(), d_candidate, eager_snapshot.size() * sizeof(float), hipMemcpyDeviceToHost));
  hipStream_t graph_stream{}; hipGraph_t graph{}; hipGraphExec_t graph_exec{};
  CHK(hipStreamCreate(&graph_stream));
  CHK(hipStreamBeginCapture(graph_stream, hipStreamCaptureModeGlobal));
  launch(candidate, candidate_args, groups, graph_stream);
  CHK(hipStreamEndCapture(graph_stream, &graph));
  CHK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));
  std::vector<float> graph_ms;
  for (unsigned i = 0; i < samples; ++i) {
    hipEvent_t begin{}, end{}; CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
    CHK(hipEventRecord(begin, graph_stream)); CHK(hipGraphLaunch(graph_exec, graph_stream));
    CHK(hipEventRecord(end, graph_stream)); CHK(hipEventSynchronize(end));
    float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end)); graph_ms.push_back(ms);
    CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  }
  std::vector<float> graph_snapshot(eager_snapshot.size());
  CHK(hipMemcpy(graph_snapshot.data(), d_candidate, graph_snapshot.size() * sizeof(float), hipMemcpyDeviceToHost));
  const bool graph_equal = graph_snapshot == eager_snapshot;

  std::vector<float> baseline_output(output_elements), candidate_output(output_elements);
  CHK(hipMemcpy(baseline_output.data(), d_baseline, output_elements * sizeof(float), hipMemcpyDeviceToHost));
  CHK(hipMemcpy(candidate_output.data(), d_candidate, output_elements * sizeof(float), hipMemcpyDeviceToHost));
  size_t mismatches = 0; float max_abs = 0;
  for (size_t i = 0; i < output_elements; ++i) {
    if (std::memcmp(&baseline_output[i], &candidate_output[i], sizeof(float))) ++mismatches;
    max_abs = std::max(max_abs, std::abs(baseline_output[i] - candidate_output[i]));
  }
  const double base_median = median(baseline_ms), candidate_median = median(candidate_ms);
  std::printf("gfx1151 measured N=%u K=%u G=%u baseline_median_ms=%.6f candidate_median_ms=%.6f speedup=%.6f bit_equal=%s mismatches=%zu max_abs=%.9g repack_bit_equal=%s repack_median_ms=%.6f graph_bit_equal=%s graph_replay_median_ms=%.6f\n",
              n, k, groups, base_median, candidate_median, base_median / candidate_median,
              mismatches ? "false" : "true", mismatches, max_abs,
              repack_equal ? "true" : "false", median(repack_ms),
              graph_equal ? "true" : "false", median(graph_ms));
  std::printf("baseline_samples_ms="); for (float x : baseline_ms) std::printf(" %.6f", x);
  std::printf("\ncandidate_samples_ms="); for (float x : candidate_ms) std::printf(" %.6f", x);
  std::printf("\nrepack_samples_ms="); for (float x : repack_ms) std::printf(" %.6f", x);
  std::printf("\ngraph_samples_ms="); for (float x : graph_ms) std::printf(" %.6f", x);
  std::printf("\n");
  return (mismatches || !repack_equal || !graph_equal) ? 4 : 0;
}
