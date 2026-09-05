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

static std::vector<uint8_t> repeat_rows(
    const std::vector<uint8_t>& row, int rows) {
  std::vector<uint8_t> result(row.size() * rows);
  for (int i = 0; i < rows; ++i) {
    std::memcpy(result.data() + i * row.size(), row.data(), row.size());
  }
  return result;
}

static float bf16_to_float(uint16_t value) {
  uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer) static_cast<void>(hipFree(pointer));
  }
  DeviceBuffer(const DeviceBuffer&) = delete;
  DeviceBuffer& operator=(const DeviceBuffer&) = delete;
};

int main(int argc, char** argv) {
  try {
    if (argc < 3 || argc > 8) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations] [symbol] [grid_x]"
                   " [block_x] [rows]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 100;
    const std::string symbol =
        argc >= 5 ? argv[4] : "qwen36_moe_down_reduce_fp8_gfx950";
    const bool two_wave = symbol.find("_2wave_") != std::string::npos;
    const bool nine_wave = symbol.find("_9wave_") != std::string::npos;
    const unsigned grid_x = argc >= 6 ? std::stoul(argv[5]) : 128;
    const unsigned block_x =
        argc >= 7 ? std::stoul(argv[6]) : (nine_wave ? 576 : (two_wave ? 128 : 64));
    const int rows = argc >= 8 ? std::stoi(argv[7]) : 1;
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");
    if (rows <= 0) throw std::runtime_error("rows must be positive");
    if (block_x < 64 || block_x > 576 || block_x % 64 != 0) {
      throw std::runtime_error(
          "block_x must be a wave64 multiple between 64 and 576");
    }

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0) {
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);
    }

    auto activation = read_binary(capture + "/activation_fp8.bin");
    auto activation_scale =
        read_binary(capture + "/activation_scale_f32.bin");
    auto weights = read_binary(capture + "/selected_w2_fp8.bin");
    auto weight_scale =
        read_binary(capture + "/selected_w2_scale_f32.bin");
    auto topk_weights = read_binary(capture + "/stage2_weights_f32.bin");
    auto topk_ids = read_binary(capture + "/stage2_expert_ids_i32.bin");
    auto reference_f32 =
        read_binary(capture + "/reference_output_f32.bin");
    auto reference_bf16 =
        read_binary(capture + "/reference_output_bf16.bin");
    auto aiter_bf16 = read_binary(capture + "/aiter_output_bf16.bin");

    if (activation.size() != 9 * 512 ||
        activation_scale.size() != 9 * 4 * sizeof(float) ||
        weights.size() != 9 * 2048 * 512 ||
        weight_scale.size() != 9 * 16 * 4 * sizeof(float) ||
        topk_weights.size() != 9 * sizeof(float) ||
        topk_ids.size() != 9 * sizeof(int32_t) ||
        reference_f32.size() != 2048 * sizeof(float) ||
        reference_bf16.size() != 2048 * sizeof(uint16_t) ||
        aiter_bf16.size() != 2048 * sizeof(uint16_t)) {
      throw std::runtime_error("capture binary size mismatch");
    }

    activation = repeat_rows(activation, rows);
    activation_scale = repeat_rows(activation_scale, rows);
    topk_weights = repeat_rows(topk_weights, rows);
    topk_ids = repeat_rows(topk_ids, rows);
    reference_f32 = repeat_rows(reference_f32, rows);
    reference_bf16 = repeat_rows(reference_bf16, rows);
    aiter_bf16 = repeat_rows(aiter_bf16, rows);

    DeviceBuffer d_activation(activation.size());
    DeviceBuffer d_activation_scale(activation_scale.size());
    DeviceBuffer d_weights(weights.size());
    DeviceBuffer d_weight_scale(weight_scale.size());
    DeviceBuffer d_topk_weights(topk_weights.size());
    DeviceBuffer d_topk_ids(topk_ids.size());
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
    HIP_CHECK(hipMemcpy(d_topk_ids.pointer, topk_ids.data(), topk_ids.size(),
                        hipMemcpyHostToDevice));

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(&function, module, symbol.c_str()));
    void* output_pointer = d_output.pointer;
    void* kernel_args[] = {
        &d_activation.pointer,       &d_activation_scale.pointer,
        &d_weights.pointer,          &d_weight_scale.pointer,
        &d_topk_weights.pointer,      &d_topk_ids.pointer,
        &output_pointer,
    };
    auto launch = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(
          function, grid_x, static_cast<unsigned>(rows), 1, block_x, 1, 1,
          0, nullptr, kernel_args, nullptr));
    };
    for (int i = 0; i < 10; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    timings.reserve(iterations);
    std::vector<uint16_t> iteration_output(rows * 2048);
    std::vector<uint16_t> first_iteration_output;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(iteration_output.data(), d_output.pointer,
                          reference_bf16.size(), hipMemcpyDeviceToHost));
      if (i == 0) {
        first_iteration_output = iteration_output;
      } else if (iteration_output != first_iteration_output) {
        ++nondeterministic_iterations;
      }
    }
    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));

    std::vector<uint16_t> output(rows * 2048);
    HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, reference_bf16.size(),
                        hipMemcpyDeviceToHost));
    const auto* reference_values =
        reinterpret_cast<const float*>(reference_f32.data());
    const auto* reference_bits =
        reinterpret_cast<const uint16_t*>(reference_bf16.data());
    const auto* aiter_bits =
        reinterpret_cast<const uint16_t*>(aiter_bf16.data());
    size_t reference_mismatches = 0;
    size_t aiter_mismatches = 0;
    double absolute_sum = 0;
    double dot = 0;
    double output_norm = 0;
    double reference_norm = 0;
    float max_absolute = 0;
    for (size_t i = 0; i < output.size(); ++i) {
      reference_mismatches += output[i] != reference_bits[i];
      aiter_mismatches += output[i] != aiter_bits[i];
      const float actual = bf16_to_float(output[i]);
      const float expected = reference_values[i];
      const float error = std::abs(actual - expected);
      absolute_sum += error;
      max_absolute = std::max(max_absolute, error);
      dot += static_cast<double>(actual) * expected;
      output_norm += static_cast<double>(actual) * actual;
      reference_norm += static_cast<double>(expected) * expected;
    }
    std::sort(timings.begin(), timings.end());
    const float median = timings[timings.size() / 2];
    const double cosine =
        dot / (std::sqrt(output_norm) * std::sqrt(reference_norm));
    std::cout << "architecture=" << architecture << "\n"
              << "rows=" << rows << "\n"
              << "reference_bf16_mismatches=" << reference_mismatches << "/"
              << output.size() << "\n"
              << "aiter_bf16_mismatches=" << aiter_mismatches << "/"
              << output.size() << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "max_abs_error_f32=" << max_absolute << "\n"
              << "mean_abs_error_f32=" << absolute_sum / output.size() << "\n"
              << "cosine_f32=" << cosine << "\n"
              << "median_us=" << median << "\n";

    HIP_CHECK(hipModuleUnload(module));
    return std::isfinite(cosine) && cosine > 0.999 &&
                   nondeterministic_iterations == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
