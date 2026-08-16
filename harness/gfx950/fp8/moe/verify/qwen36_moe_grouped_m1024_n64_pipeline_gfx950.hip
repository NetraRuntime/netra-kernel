// SPDX-License-Identifier: MIT

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#define HIP_CHECK(expr)                                                        \
  do {                                                                         \
    hipError_t status = (expr);                                                 \
    if (status != hipSuccess) {                                                 \
      throw std::runtime_error(std::string(#expr) + ": " +                     \
                               hipGetErrorString(status));                      \
    }                                                                          \
  } while (0)

static std::vector<uint8_t> read_binary(const std::string& path) {
  std::ifstream input(path, std::ios::binary | std::ios::ate);
  if (!input) throw std::runtime_error("cannot open " + path);
  const auto size = input.tellg();
  input.seekg(0);
  std::vector<uint8_t> data(static_cast<size_t>(size));
  input.read(reinterpret_cast<char*>(data.data()), size);
  if (!input) throw std::runtime_error("cannot read " + path);
  return data;
}

static float bf16_to_float(uint16_t value) {
  uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result = 0.0f;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer != nullptr) static_cast<void>(hipFree(pointer));
  }
};

struct Comparison {
  size_t bf16_mismatches = 0;
  float max_abs = 0.0f;
  double mean_abs = 0.0;
  double cosine = 0.0;
};

static Comparison compare(const std::vector<uint16_t>& actual,
                          const std::vector<uint16_t>& expected_bf16,
                          const std::vector<float>& expected_f32) {
  if (actual.size() != expected_bf16.size() ||
      actual.size() != expected_f32.size()) {
    throw std::runtime_error("comparison size mismatch");
  }
  Comparison result;
  double dot = 0.0, actual_norm = 0.0, expected_norm = 0.0;
  for (size_t index = 0; index < actual.size(); ++index) {
    result.bf16_mismatches += actual[index] != expected_bf16[index];
    const float a = bf16_to_float(actual[index]);
    const float e = expected_f32[index];
    const float error = std::abs(a - e);
    result.max_abs = std::max(result.max_abs, error);
    result.mean_abs += error;
    dot += static_cast<double>(a) * e;
    actual_norm += static_cast<double>(a) * a;
    expected_norm += static_cast<double>(e) * e;
  }
  result.mean_abs /= actual.size();
  result.cosine = dot / std::sqrt(actual_norm * expected_norm);
  return result;
}

int main(int argc, char** argv) {
  try {
    if (argc < 4 || argc > 5) {
      std::cerr << "usage: " << argv[0]
                << " GROUPED.hsaco REDUCE.hsaco CAPTURE_DIR [iterations=30]\n";
      return 2;
    }
    const int iterations = argc == 5 ? std::stoi(argv[4]) : 30;
    constexpr int kRows = 1024;
    constexpr int kTopk = 9;
    constexpr int kHidden = 2048;
    constexpr int kInter = 512;

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0) {
      throw std::runtime_error("refusing non-gfx950 device");
    }

    const std::string capture = argv[3];
    auto activation = read_binary(capture + "/activation_fp8.bin");
    auto activation_scale =
        read_binary(capture + "/activation_scale_f32.bin");
    auto weights = read_binary(capture + "/active_w2_fp8.bin");
    auto weight_scale =
        read_binary(capture + "/active_w2_scale_f32.bin");
    auto sorted_tokens =
        read_binary(capture + "/sorted_token_ids_i32.bin");
    auto sorted_experts =
        read_binary(capture + "/compact_sorted_expert_ids_i32.bin");
    auto valid_ids = read_binary(capture + "/num_valid_ids_i32.bin");
    auto topk_weights = read_binary(capture + "/topk_weights_f32.bin");
    auto reference_f32_bytes =
        read_binary(capture + "/reference_output_f32.bin");
    auto reference_bf16_bytes =
        read_binary(capture + "/reference_output_bf16.bin");
    auto aiter_bf16_bytes = read_binary(capture + "/aiter_output_bf16.bin");
    const size_t output_elements = static_cast<size_t>(kRows) * kHidden;
    const size_t partial_elements =
        static_cast<size_t>(kRows) * kTopk * kHidden;
    if (activation.size() != static_cast<size_t>(kRows) * kTopk * kInter ||
        activation_scale.size() !=
            static_cast<size_t>(kRows) * kTopk * 4 * sizeof(float) ||
        weights.size() % (static_cast<size_t>(kHidden) * kInter) != 0 ||
        weight_scale.size() !=
            weights.size() / (kHidden * kInter) * 16 * 4 * sizeof(float) ||
        sorted_tokens.size() % sizeof(int32_t) != 0 ||
        sorted_experts.size() % sizeof(int32_t) != 0 ||
        valid_ids.size() != sizeof(int32_t) ||
        topk_weights.size() !=
            static_cast<size_t>(kRows) * kTopk * sizeof(float) ||
        reference_f32_bytes.size() != output_elements * sizeof(float) ||
        reference_bf16_bytes.size() != output_elements * sizeof(uint16_t) ||
        aiter_bf16_bytes.size() != output_elements * sizeof(uint16_t)) {
      throw std::runtime_error("capture binary size mismatch");
    }

    DeviceBuffer d_activation(activation.size());
    DeviceBuffer d_activation_scale(activation_scale.size());
    DeviceBuffer d_weights(weights.size());
    DeviceBuffer d_weight_scale(weight_scale.size());
    DeviceBuffer d_sorted_tokens(sorted_tokens.size());
    DeviceBuffer d_sorted_experts(sorted_experts.size());
    DeviceBuffer d_valid_ids(valid_ids.size());
    DeviceBuffer d_topk_weights(topk_weights.size());
    DeviceBuffer d_partials(partial_elements * sizeof(float));
    DeviceBuffer d_output(output_elements * sizeof(uint16_t));
    auto copy = [](DeviceBuffer& destination, const std::vector<uint8_t>& source) {
      HIP_CHECK(hipMemcpy(destination.pointer, source.data(), source.size(),
                          hipMemcpyHostToDevice));
    };
    copy(d_activation, activation);
    copy(d_activation_scale, activation_scale);
    copy(d_weights, weights);
    copy(d_weight_scale, weight_scale);
    copy(d_sorted_tokens, sorted_tokens);
    copy(d_sorted_experts, sorted_experts);
    copy(d_valid_ids, valid_ids);
    copy(d_topk_weights, topk_weights);
    HIP_CHECK(hipMemset(d_partials.pointer, 0,
                        partial_elements * sizeof(float)));

    hipModule_t grouped_module{}, reduce_module{};
    hipFunction_t grouped_function{}, reduce_function{};
    HIP_CHECK(hipModuleLoad(&grouped_module, argv[1]));
    HIP_CHECK(hipModuleLoad(&reduce_module, argv[2]));
    HIP_CHECK(hipModuleGetFunction(
        &grouped_function, grouped_module,
        "qwen36_moe_grouped_down_m16n64_fp8_gfx950"));
    HIP_CHECK(hipModuleGetFunction(
        &reduce_function, reduce_module,
        "qwen36_moe_route_reduce_f32_gfx950"));
    void* partial_pointer = d_partials.pointer;
    void* output_pointer = d_output.pointer;
    int rows = kRows;
    void* grouped_arguments[] = {
        &d_activation.pointer,     &d_activation_scale.pointer,
        &d_weights.pointer,        &d_weight_scale.pointer,
        &d_sorted_tokens.pointer,  &d_sorted_experts.pointer,
        &d_valid_ids.pointer,      &partial_pointer,
        &rows,
    };
    void* reduce_arguments[] = {
        &partial_pointer, &d_topk_weights.pointer, &output_pointer,
    };
    const unsigned sorted_blocks =
        static_cast<unsigned>(sorted_experts.size() / sizeof(int32_t));
    auto launch = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(grouped_function, 32, sorted_blocks, 1,
                                      256, 1, 1, 0, nullptr,
                                      grouped_arguments, nullptr));
      HIP_CHECK(hipModuleLaunchKernel(reduce_function, 32, kRows, 1,
                                      64, 1, 1, 0, nullptr,
                                      reduce_arguments, nullptr));
    };
    for (int index = 0; index < 5; ++index) launch();
    HIP_CHECK(hipDeviceSynchronize());

    std::vector<uint16_t> output(output_elements);
    HIP_CHECK(hipMemcpy(output.data(), d_output.pointer,
                        output.size() * sizeof(uint16_t),
                        hipMemcpyDeviceToHost));
    std::vector<float> reference_f32(output_elements);
    std::memcpy(reference_f32.data(), reference_f32_bytes.data(),
                reference_f32_bytes.size());
    std::vector<uint16_t> reference_bf16(output_elements);
    std::memcpy(reference_bf16.data(), reference_bf16_bytes.data(),
                reference_bf16_bytes.size());
    std::vector<uint16_t> aiter_bf16(output_elements);
    std::memcpy(aiter_bf16.data(), aiter_bf16_bytes.data(),
                aiter_bf16_bytes.size());
    const Comparison structural =
        compare(output, reference_bf16, reference_f32);
    std::vector<float> aiter_f32(output_elements);
    for (size_t index = 0; index < output_elements; ++index) {
      aiter_f32[index] = bf16_to_float(aiter_bf16[index]);
    }
    const Comparison deployed = compare(output, aiter_bf16, aiter_f32);

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    timings.reserve(iterations);
    const std::vector<uint16_t> first = output;
    size_t nondeterministic_iterations = 0;
    for (int index = 0; index < iterations; ++index) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0.0f;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer,
                          output.size() * sizeof(uint16_t),
                          hipMemcpyDeviceToHost));
      nondeterministic_iterations += output != first;
    }
    std::sort(timings.begin(), timings.end());
    std::cout << "architecture=" << properties.gcnArchName << "\n"
              << "rows=" << kRows << "\n"
              << "sorted_blocks=" << sorted_blocks << "\n"
              << "structural_bf16_mismatches=" << structural.bf16_mismatches
              << "/" << output_elements << "\n"
              << "structural_max_abs=" << structural.max_abs << "\n"
              << "structural_mean_abs=" << structural.mean_abs << "\n"
              << "structural_cosine=" << structural.cosine << "\n"
              << "aiter_bf16_mismatches=" << deployed.bf16_mismatches << "/"
              << output_elements << "\n"
              << "aiter_max_abs=" << deployed.max_abs << "\n"
              << "aiter_mean_abs=" << deployed.mean_abs << "\n"
              << "aiter_cosine=" << deployed.cosine << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "pipeline_median_us=" << timings[timings.size() / 2] << "\n";
    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(grouped_module));
    HIP_CHECK(hipModuleUnload(reduce_module));
    return std::isfinite(structural.cosine) && structural.cosine > 0.9999 &&
                   nondeterministic_iterations == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
