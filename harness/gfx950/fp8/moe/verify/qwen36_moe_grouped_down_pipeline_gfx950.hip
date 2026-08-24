// SPDX-License-Identifier: MIT

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <numeric>
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

int main(int argc, char** argv) {
  try {
    if (argc < 4 || argc > 5) {
      std::cerr << "usage: " << argv[0]
                << " GROUPED.hsaco REDUCE.hsaco CAPTURE_DIR [iterations=200]\n";
      return 2;
    }
    const int iterations = argc == 5 ? std::stoi(argv[4]) : 200;
    constexpr int kRows = 1;
    constexpr int kTopk = 9;
    constexpr int kHidden = 2048;
    constexpr int kInter = 512;
    constexpr int kBlockM = 16;

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
    auto weights = read_binary(capture + "/selected_w2_fp8.bin");
    auto weight_scale =
        read_binary(capture + "/selected_w2_scale_f32.bin");
    auto topk_weights = read_binary(capture + "/stage2_weights_f32.bin");
    auto compact_topk_ids =
        read_binary(capture + "/compact_topk_ids_i32.bin");
    auto reference_f32 = read_binary(capture + "/reference_output_f32.bin");
    auto reference_bf16 = read_binary(capture + "/reference_output_bf16.bin");
    if (activation.size() != kTopk * kInter ||
        activation_scale.size() != kTopk * 4 * sizeof(float) ||
        weights.size() != kTopk * kHidden * kInter ||
        weight_scale.size() != kTopk * 16 * 4 * sizeof(float) ||
        topk_weights.size() != kTopk * sizeof(float) ||
        compact_topk_ids.size() != kTopk * sizeof(int32_t) ||
        reference_f32.size() != kHidden * sizeof(float) ||
        reference_bf16.size() != kHidden * sizeof(uint16_t)) {
      throw std::runtime_error("capture binary size mismatch");
    }

    std::vector<int32_t> sorted_ids(kTopk * kBlockM, kTopk);
    std::vector<int32_t> sorted_experts(kTopk);
    std::memcpy(sorted_experts.data(), compact_topk_ids.data(),
                compact_topk_ids.size());
    for (int slot = 0; slot < kTopk; ++slot) {
      sorted_ids[slot * kBlockM] = slot;
    }
    const int32_t valid_ids = kTopk * kBlockM;
    std::vector<float> zero_partials(kTopk * kHidden, 0.0f);

    DeviceBuffer d_activation(activation.size());
    DeviceBuffer d_activation_scale(activation_scale.size());
    DeviceBuffer d_weights(weights.size());
    DeviceBuffer d_weight_scale(weight_scale.size());
    DeviceBuffer d_topk_weights(topk_weights.size());
    DeviceBuffer d_sorted_ids(sorted_ids.size() * sizeof(int32_t));
    DeviceBuffer d_sorted_experts(sorted_experts.size() * sizeof(int32_t));
    DeviceBuffer d_valid_ids(sizeof(int32_t));
    DeviceBuffer d_partials(zero_partials.size() * sizeof(float));
    DeviceBuffer d_output(reference_bf16.size());
    HIP_CHECK(hipMemcpy(d_activation.pointer, activation.data(), activation.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_activation_scale.pointer, activation_scale.data(),
                        activation_scale.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_weights.pointer, weights.data(), weights.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_weight_scale.pointer, weight_scale.data(),
                        weight_scale.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_topk_weights.pointer, topk_weights.data(),
                        topk_weights.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_sorted_ids.pointer, sorted_ids.data(),
                        sorted_ids.size() * sizeof(int32_t),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_sorted_experts.pointer, sorted_experts.data(),
                        sorted_experts.size() * sizeof(int32_t),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_valid_ids.pointer, &valid_ids, sizeof(valid_ids),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_partials.pointer, zero_partials.data(),
                        zero_partials.size() * sizeof(float),
                        hipMemcpyHostToDevice));

    hipModule_t grouped_module{}, reduce_module{};
    hipFunction_t grouped_function{}, reduce_function{};
    HIP_CHECK(hipModuleLoad(&grouped_module, argv[1]));
    HIP_CHECK(hipModuleLoad(&reduce_module, argv[2]));
    HIP_CHECK(hipModuleGetFunction(
        &grouped_function, grouped_module,
        "qwen36_moe_grouped_down_m16n16_fp8_gfx950"));
    HIP_CHECK(hipModuleGetFunction(
        &reduce_function, reduce_module,
        "qwen36_moe_route_reduce_f32_gfx950"));
    void* partial_pointer = d_partials.pointer;
    void* output_pointer = d_output.pointer;
    int rows = kRows;
    void* grouped_arguments[] = {
        &d_activation.pointer, &d_activation_scale.pointer,
        &d_weights.pointer, &d_weight_scale.pointer,
        &d_sorted_ids.pointer, &d_sorted_experts.pointer,
        &d_valid_ids.pointer, &partial_pointer, &rows,
    };
    void* reduce_arguments[] = {
        &partial_pointer, &d_topk_weights.pointer, &output_pointer,
    };
    auto launch = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(grouped_function, 128, kTopk, 1,
                                      64, 1, 1, 0, nullptr,
                                      grouped_arguments, nullptr));
      HIP_CHECK(hipModuleLaunchKernel(reduce_function, 32, kRows, 1,
                                      64, 1, 1, 0, nullptr,
                                      reduce_arguments, nullptr));
    };
    for (int index = 0; index < 10; ++index) launch();
    HIP_CHECK(hipDeviceSynchronize());

    std::vector<uint16_t> output(kHidden);
    HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, reference_bf16.size(),
                        hipMemcpyDeviceToHost));
    const auto* reference_bits =
        reinterpret_cast<const uint16_t*>(reference_bf16.data());
    const auto* reference_values =
        reinterpret_cast<const float*>(reference_f32.data());
    size_t bf16_mismatches = 0;
    float max_abs = 0.0f;
    double mean_abs = 0.0;
    double dot = 0.0, norm_actual = 0.0, norm_reference = 0.0;
    for (int index = 0; index < kHidden; ++index) {
      bf16_mismatches += output[index] != reference_bits[index];
      const float actual = bf16_to_float(output[index]);
      const float expected = reference_values[index];
      const float error = std::abs(actual - expected);
      max_abs = std::max(max_abs, error);
      mean_abs += error;
      dot += static_cast<double>(actual) * expected;
      norm_actual += static_cast<double>(actual) * actual;
      norm_reference += static_cast<double>(expected) * expected;
    }

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    timings.reserve(iterations);
    std::vector<uint16_t> first = output;
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
                          reference_bf16.size(), hipMemcpyDeviceToHost));
      nondeterministic_iterations += output != first;
    }
    std::sort(timings.begin(), timings.end());
    const double cosine = dot / std::sqrt(norm_actual * norm_reference);
    std::cout << "architecture=" << properties.gcnArchName << "\n"
              << "bf16_mismatches=" << bf16_mismatches << "/" << kHidden << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "max_abs_error_f32=" << max_abs << "\n"
              << "mean_abs_error_f32=" << mean_abs / kHidden << "\n"
              << "cosine_f32=" << cosine << "\n"
              << "pipeline_median_us=" << timings[timings.size() / 2] << "\n";
    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(grouped_module));
    HIP_CHECK(hipModuleUnload(reduce_module));
    return std::isfinite(cosine) && cosine > 0.999 &&
                   nondeterministic_iterations == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
