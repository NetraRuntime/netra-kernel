// Launch/timing/correctness harness; both compute kernels are raw gfx1151 ASM.
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
struct Args { void* packed; void* scales; void* activation; void* output; void* expert_ids; };
struct RepackArgs { void* source; void* destination; };

static Kernel load(const char* path, const char* symbol) {
  Kernel result;
  CHK(hipModuleLoad(&result.module, path));
  CHK(hipModuleGetFunction(&result.function, result.module, symbol));
  return result;
}

static void launch(const Kernel& kernel, Args& args, unsigned groups, hipStream_t stream = nullptr) {
  void* params[] = {&args.packed, &args.scales, &args.activation,
                    &args.output, &args.expert_ids};
  CHK(hipModuleLaunchKernel(kernel.function, 32, groups, 1, 32, 1, 1,
                            0, stream, params, nullptr));
}

static void launch_repack(const Kernel& kernel, RepackArgs& args) {
  void* params[] = {&args.source, &args.destination};
  CHK(hipModuleLaunchKernel(kernel.function, 131072, 1, 1, 256, 1, 1,
                            0, nullptr, params, nullptr));
}

static float time_one(const Kernel& kernel, Args& args, unsigned groups) {
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin)); launch(kernel, args, groups); CHK(hipEventRecord(end));
  CHK(hipEventSynchronize(end));
  float milliseconds = 0; CHK(hipEventElapsedTime(&milliseconds, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return milliseconds;
}

static float time_repack(const Kernel& kernel, RepackArgs& args) {
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin)); launch_repack(kernel, args); CHK(hipEventRecord(end));
  CHK(hipEventSynchronize(end));
  float milliseconds = 0; CHK(hipEventElapsedTime(&milliseconds, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  return milliseconds;
}

static double median(std::vector<float> values) {
  std::sort(values.begin(), values.end()); return values[values.size() / 2];
}

int main(int argc, char** argv) {
  constexpr unsigned E = 256, M = 64, N = 512, K = 2048;
  if (argc < 4) {
    std::fprintf(stderr, "usage: %s BASELINE.hsaco CANDIDATE.hsaco REPACK.hsaco [groups] [samples]\n", argv[0]);
    return 2;
  }
  const unsigned groups = argc > 4 ? std::strtoul(argv[4], nullptr, 10) : 1276;
  const unsigned samples = argc > 5 ? std::strtoul(argv[5], nullptr, 10) : 11;
  hipDeviceProp_t properties{}; CHK(hipGetDeviceProperties(&properties, 0));
  if (std::string(properties.gcnArchName).find("gfx1151") == std::string::npos) return 3;

  const size_t packed_bytes = size_t(E) * (K / 2) * N;
  const size_t scale_bytes = size_t(E) * (K / 32) * N;
  const size_t activation_bytes = size_t(groups) * M * K * 2;
  const size_t output_elements = size_t(groups) * M * N;
  std::vector<uint8_t> packed(packed_bytes), repacked(packed_bytes), scales(scale_bytes);
  std::vector<uint32_t> expert_ids(groups);
  for (size_t i = 0; i < packed.size(); ++i)
    packed[i] = uint8_t((i * 37 + (i >> 11) * 13 + 17) & 255);
  for (size_t i = 0; i < scales.size(); ++i)
    scales[i] = uint8_t(118 + ((i * 5 + (i >> 9)) % 6));
  for (unsigned group = 0; group < groups; ++group)
    expert_ids[group] = uint32_t((uint64_t(group) * E) / groups);

  // Preserve every MXFP4 byte while changing only its physical layout:
  // [expert][K32][fragment][lane subgroup][N][four packed K bytes].
  for (unsigned expert = 0; expert < E; ++expert) {
    const size_t expert_base = size_t(expert) * (K / 2) * N;
    for (unsigned block = 0; block < K / 32; ++block)
      for (unsigned fragment = 0; fragment < 2; ++fragment)
        for (unsigned subgroup = 0; subgroup < 2; ++subgroup)
          for (unsigned n = 0; n < N; ++n)
            for (unsigned byte = 0; byte < 4; ++byte) {
              const unsigned packed_k = block * 16 + fragment * 8 + subgroup * 4 + byte;
              const size_t source = expert_base + size_t(packed_k) * N + n;
              const size_t destination = expert_base + size_t(block) * 8192 +
                  fragment * 4096 + subgroup * 2048 + n * 4 + byte;
              repacked[destination] = packed[source];
            }
  }

  uint8_t *d_packed{}, *d_repacked{}, *d_scales{}, *d_activation{};
  uint32_t *d_ids{}; float *d_baseline{}, *d_candidate{};
  CHK(hipMalloc(&d_packed, packed_bytes)); CHK(hipMalloc(&d_repacked, packed_bytes));
  CHK(hipMalloc(&d_scales, scale_bytes)); CHK(hipMalloc(&d_activation, activation_bytes));
  CHK(hipMalloc(&d_ids, groups * sizeof(uint32_t)));
  CHK(hipMalloc(&d_baseline, output_elements * sizeof(float)));
  CHK(hipMalloc(&d_candidate, output_elements * sizeof(float)));
  CHK(hipMemcpy(d_packed, packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_scales, scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_ids, expert_ids.data(), groups * sizeof(uint32_t), hipMemcpyHostToDevice));
  CHK(hipMemset(d_activation, 0x3f, activation_bytes));

  Kernel baseline = load(argv[1], "mxfp4_prefill_gate_wmma_gfx1151");
  Kernel candidate = load(argv[2], "mxfp4_prefill_gate_dword_layout_gfx1151");
  Kernel repacker = load(argv[3], "mxfp4_prefill_repack_dword_gfx1151");
  RepackArgs repack_args{d_packed, d_repacked};
  launch_repack(repacker, repack_args); CHK(hipDeviceSynchronize());
  std::vector<uint8_t> device_repacked(packed_bytes);
  CHK(hipMemcpy(device_repacked.data(), d_repacked, packed_bytes, hipMemcpyDeviceToHost));
  const bool repack_equal = device_repacked == repacked;
  std::vector<float> repack_ms;
  for (unsigned i = 0; i < samples; ++i) repack_ms.push_back(time_repack(repacker, repack_args));
  Args baseline_args{d_packed, d_scales, d_activation, d_baseline, d_ids};
  Args candidate_args{d_repacked, d_scales, d_activation, d_candidate, d_ids};
  for (int i = 0; i < 3; ++i) { launch(baseline, baseline_args, groups); launch(candidate, candidate_args, groups); }
  CHK(hipDeviceSynchronize());

  std::vector<float> baseline_ms, candidate_ms;
  for (unsigned i = 0; i < samples; ++i) {
    if (i & 1) {
      candidate_ms.push_back(time_one(candidate, candidate_args, groups));
      baseline_ms.push_back(time_one(baseline, baseline_args, groups));
    } else {
      baseline_ms.push_back(time_one(baseline, baseline_args, groups));
      candidate_ms.push_back(time_one(candidate, candidate_args, groups));
    }
  }

  hipStream_t graph_stream{}; hipGraph_t graph{}; hipGraphExec_t graph_exec{};
  CHK(hipStreamCreate(&graph_stream));
  CHK(hipStreamBeginCapture(graph_stream, hipStreamCaptureModeGlobal));
  launch(candidate, candidate_args, groups, graph_stream);
  CHK(hipStreamEndCapture(graph_stream, &graph));
  CHK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));
  std::vector<float> graph_ms;
  for (unsigned i = 0; i < samples; ++i) {
    hipEvent_t begin{}, end{}; CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end));
    CHK(hipEventRecord(begin, graph_stream));
    CHK(hipGraphLaunch(graph_exec, graph_stream));
    CHK(hipEventRecord(end, graph_stream)); CHK(hipEventSynchronize(end));
    float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end)); graph_ms.push_back(ms);
    CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end));
  }
  CHK(hipStreamSynchronize(graph_stream));
  std::vector<float> baseline_output(output_elements), candidate_output(output_elements);
  CHK(hipMemcpy(baseline_output.data(), d_baseline, output_elements * sizeof(float), hipMemcpyDeviceToHost));
  CHK(hipMemcpy(candidate_output.data(), d_candidate, output_elements * sizeof(float), hipMemcpyDeviceToHost));
  size_t mismatches = 0; float max_abs = 0;
  for (size_t i = 0; i < output_elements; ++i) {
    if (std::memcmp(&baseline_output[i], &candidate_output[i], sizeof(float))) ++mismatches;
    max_abs = std::max(max_abs, std::abs(baseline_output[i] - candidate_output[i]));
  }
  const double base_median = median(baseline_ms), candidate_median = median(candidate_ms);
  std::printf("gfx1151 measured G=%u baseline_median_ms=%.6f candidate_median_ms=%.6f speedup=%.6f bit_equal=%s mismatches=%zu max_abs=%.9g repack_bit_equal=%s repack_median_ms=%.6f\n",
              groups, base_median, candidate_median, base_median / candidate_median,
              mismatches ? "false" : "true", mismatches, max_abs,
              repack_equal ? "true" : "false", median(repack_ms));
  std::printf("baseline_samples_ms="); for (float x : baseline_ms) std::printf(" %.6f", x);
  std::printf("\ngraph_replay_median_ms=%.6f graph_replay_samples_ms=", median(graph_ms)); for (float x : graph_ms) std::printf(" %.6f", x);
  std::printf("\nrepack_samples_ms="); for (float x : repack_ms) std::printf(" %.6f", x);
  std::printf("\ncandidate_samples_ms="); for (float x : candidate_ms) std::printf(" %.6f", x);
  std::printf("\n");
  return (mismatches || !repack_equal) ? 4 : 0;
}
