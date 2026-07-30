// SPDX-License-Identifier: MIT
// HIP is used only for launch, setup, comparison, graph replay, and timing; compute is raw ASM.
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

__global__ void compare_bf16(const uint16_t* baseline, const uint16_t* candidate,
                             size_t count, unsigned* mismatches) {
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;
  if (i < count && baseline[i] != candidate[i]) atomicAdd(mismatches, 1u);
}

struct Kernel { hipModule_t module{}; hipFunction_t function{}; };
struct ProjectionArgs {
  void* packed; void* scales; void* activation; void* output; void* ids;
};
struct SiluArgs { void* gate; void* up; void* output; };
struct UpSiluArgs {
  void* packed; void* scales; void* activation; void* gate; void* output; void* ids;
};

static Kernel load(const char* path, const char* symbol) {
  Kernel result;
  CHK(hipModuleLoad(&result.module, path));
  CHK(hipModuleGetFunction(&result.function, result.module, symbol));
  return result;
}

static void launch_projection(const Kernel& kernel, ProjectionArgs& args,
                              unsigned groups, hipStream_t stream = nullptr) {
  void* params[] = {&args.packed, &args.scales, &args.activation,
                    &args.output, &args.ids};
  CHK(hipModuleLaunchKernel(kernel.function, 8, groups, 1, 128, 1, 1,
                            0, stream, params, nullptr));
}

static void launch_silu(const Kernel& kernel, SiluArgs& args, unsigned groups,
                        hipStream_t stream = nullptr) {
  void* params[] = {&args.gate, &args.up, &args.output};
  CHK(hipModuleLaunchKernel(kernel.function, groups * 128, 1, 1, 256, 1, 1,
                            0, stream, params, nullptr));
}

static void launch_up_silu(const Kernel& kernel, UpSiluArgs& args,
                           unsigned groups, hipStream_t stream = nullptr) {
  void* params[] = {&args.packed, &args.scales, &args.activation,
                    &args.gate, &args.output, &args.ids};
  CHK(hipModuleLaunchKernel(kernel.function, 8, groups, 1, 128, 1, 1,
                            0, stream, params, nullptr));
}

static float time_baseline(const Kernel& projection, ProjectionArgs& gate_args,
                           ProjectionArgs& up_args, const Kernel& silu,
                           SiluArgs& silu_args, unsigned groups) {
  constexpr unsigned repeats = 2;
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end)); CHK(hipEventRecord(begin));
  for (unsigned repeat = 0; repeat < repeats; ++repeat) {
    launch_projection(projection, gate_args, groups);
    launch_projection(projection, up_args, groups);
    launch_silu(silu, silu_args, groups);
  }
  CHK(hipEventRecord(end)); CHK(hipEventSynchronize(end));
  float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end)); return ms / repeats;
}

static float time_candidate(const Kernel& projection, ProjectionArgs& gate_args,
                            const Kernel& up_silu, UpSiluArgs& up_silu_args,
                            unsigned groups) {
  constexpr unsigned repeats = 2;
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin)); CHK(hipEventCreate(&end)); CHK(hipEventRecord(begin));
  for (unsigned repeat = 0; repeat < repeats; ++repeat) {
    launch_projection(projection, gate_args, groups);
    launch_up_silu(up_silu, up_silu_args, groups);
  }
  CHK(hipEventRecord(end)); CHK(hipEventSynchronize(end));
  float ms = 0; CHK(hipEventElapsedTime(&ms, begin, end));
  CHK(hipEventDestroy(begin)); CHK(hipEventDestroy(end)); return ms / repeats;
}

static double median(std::vector<float> values) {
  std::sort(values.begin(), values.end()); return values[values.size() / 2];
}

int main(int argc, char** argv) {
  if (argc < 4) {
    std::fprintf(stderr, "usage: %s PROJECTION.hsaco SILU.hsaco UP_SILU.hsaco [groups] [samples]\n", argv[0]);
    return 2;
  }
  constexpr unsigned E = 256, M = 64, N = 512, K = 2048;
  const unsigned groups = argc > 4 ? std::strtoul(argv[4], nullptr, 10) : 1276;
  const unsigned samples = argc > 5 ? std::strtoul(argv[5], nullptr, 10) : 11;
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
  uint16_t *d_activation{}, *d_output_base{}, *d_output_candidate{};
  float *d_gate{}, *d_up{};
  uint32_t *d_ids{}, *d_mismatches{};
  CHK(hipMalloc(&d_gate_packed, packed_bytes)); CHK(hipMalloc(&d_up_packed, packed_bytes));
  CHK(hipMalloc(&d_gate_scales, scale_bytes)); CHK(hipMalloc(&d_up_scales, scale_bytes));
  CHK(hipMalloc(&d_activation, activation_elements * 2));
  CHK(hipMalloc(&d_gate, output_elements * 4)); CHK(hipMalloc(&d_up, output_elements * 4));
  CHK(hipMalloc(&d_output_base, output_elements * 2)); CHK(hipMalloc(&d_output_candidate, output_elements * 2));
  CHK(hipMalloc(&d_ids, groups * 4)); CHK(hipMalloc(&d_mismatches, 4));
  CHK(hipMemcpy(d_gate_packed, gate_packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_up_packed, up_packed.data(), packed_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_gate_scales, gate_scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_up_scales, up_scales.data(), scale_bytes, hipMemcpyHostToDevice));
  CHK(hipMemcpy(d_ids, ids.data(), groups * 4, hipMemcpyHostToDevice));
  fill_bf16<<<(activation_elements + 255) / 256, 256>>>(d_activation, activation_elements);

  Kernel projection = load(argv[1], "mxfp4_prefill_gate_wmma_gfx1151");
  Kernel silu = load(argv[2], "silu_mul_bf16_gfx1151");
  Kernel up_silu = load(argv[3], "mxfp4_prefill_up_silu_wmma_gfx1151");
  ProjectionArgs gate_args{d_gate_packed, d_gate_scales, d_activation, d_gate, d_ids};
  ProjectionArgs up_args{d_up_packed, d_up_scales, d_activation, d_up, d_ids};
  SiluArgs silu_args{d_gate, d_up, d_output_base};
  UpSiluArgs up_silu_args{d_up_packed, d_up_scales, d_activation, d_gate,
                          d_output_candidate, d_ids};
  for (int i = 0; i < 3; ++i) {
    launch_projection(projection, gate_args, groups);
    launch_projection(projection, up_args, groups);
    launch_silu(silu, silu_args, groups);
    launch_projection(projection, gate_args, groups);
    launch_up_silu(up_silu, up_silu_args, groups);
  }
  CHK(hipDeviceSynchronize()); CHK(hipMemset(d_mismatches, 0, 4));
  compare_bf16<<<(output_elements + 255) / 256, 256>>>(
      d_output_base, d_output_candidate, output_elements, d_mismatches);
  uint32_t mismatches = 0;
  CHK(hipMemcpy(&mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));

  hipStream_t graph_stream{}; hipGraph_t graph{}; hipGraphExec_t graph_exec{};
  CHK(hipStreamCreate(&graph_stream));
  CHK(hipStreamBeginCapture(graph_stream, hipStreamCaptureModeGlobal));
  CHK(hipMemsetAsync(d_output_candidate, 0xff, output_elements * 2, graph_stream));
  launch_projection(projection, gate_args, groups, graph_stream);
  launch_up_silu(up_silu, up_silu_args, groups, graph_stream);
  CHK(hipStreamEndCapture(graph_stream, &graph));
  CHK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));

  unsigned eager_failures = 0;
  unsigned graph_failures = 0;
  uint32_t max_mismatches = 0;
  for (unsigned replay = 0; replay < 20; ++replay) {
    CHK(hipMemset(d_output_candidate, 0xff, output_elements * 2));
    launch_projection(projection, gate_args, groups);
    launch_up_silu(up_silu, up_silu_args, groups);
    CHK(hipMemset(d_mismatches, 0, 4));
    compare_bf16<<<(output_elements + 255) / 256, 256>>>(
        d_output_base, d_output_candidate, output_elements, d_mismatches);
    uint32_t replay_mismatches = 0;
    CHK(hipMemcpy(&replay_mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));
    if (replay_mismatches) ++eager_failures;
    max_mismatches = std::max(max_mismatches, replay_mismatches);

    CHK(hipGraphLaunch(graph_exec, graph_stream));
    CHK(hipStreamSynchronize(graph_stream));
    CHK(hipMemset(d_mismatches, 0, 4));
    compare_bf16<<<(output_elements + 255) / 256, 256>>>(
        d_output_base, d_output_candidate, output_elements, d_mismatches);
    replay_mismatches = 0;
    CHK(hipMemcpy(&replay_mismatches, d_mismatches, 4, hipMemcpyDeviceToHost));
    if (replay_mismatches) ++graph_failures;
    max_mismatches = std::max(max_mismatches, replay_mismatches);
  }
  mismatches = max_mismatches;

  std::vector<float> baseline_ms, candidate_ms;
  for (unsigned sample = 0; sample < samples; ++sample) {
    if (sample & 1) {
      candidate_ms.push_back(time_candidate(projection, gate_args, up_silu, up_silu_args, groups));
      baseline_ms.push_back(time_baseline(projection, gate_args, up_args, silu, silu_args, groups));
    } else {
      baseline_ms.push_back(time_baseline(projection, gate_args, up_args, silu, silu_args, groups));
      candidate_ms.push_back(time_candidate(projection, gate_args, up_silu, up_silu_args, groups));
    }
  }
  const double baseline_med = median(baseline_ms), candidate_med = median(candidate_ms);
  std::printf("gfx1151 measured groups=%u bit_equal=%s mismatches=%u baseline_gate_up_silu_median_ms=%.6f fused_up_epilogue_median_ms=%.6f speedup=%.6f eager_repeated_exact=%s graph_replay_exact=%s eager_correctness_failures=%u graph_correctness_failures=%u\n", groups, mismatches ? "false" : "true", mismatches, baseline_med, candidate_med, baseline_med / candidate_med, eager_failures ? "false" : "true", graph_failures ? "false" : "true", eager_failures, graph_failures);
  std::printf("baseline_samples_ms="); for (float v : baseline_ms) std::printf(" %.6f", v);
  std::printf("\ncandidate_samples_ms="); for (float v : candidate_ms) std::printf(" %.6f", v);
  std::printf("\n");
  return mismatches ? 4 : 0;
}
