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
    if (status != hipSuccess)                                                   \
      throw std::runtime_error(std::string(#expr) + ": " +                     \
                               hipGetErrorString(status));                      \
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

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer) static_cast<void>(hipFree(pointer));
  }
};

int main(int argc, char** argv) {
  try {
    if (argc < 3 || argc > 6) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations] [rows] [symbol]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 100;
    const int rows = argc >= 5 ? std::stoi(argv[4]) : 1;
    const std::string symbol =
        argc >= 6 ? argv[5] : "qwen36_moe_gate_up_fp8_mfma_gfx950";
    if (iterations <= 0 || rows <= 0)
      throw std::runtime_error("iterations and rows must be positive");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    auto hidden = read_binary(capture + "/hidden_states_fp8.bin");
    auto hidden_scale =
        read_binary(capture + "/hidden_states_scale_f32.bin");
    auto weights = read_binary(capture + "/selected_w1_fp8.bin");
    auto weight_scale =
        read_binary(capture + "/selected_w1_scale_f32.bin");
    auto topk_ids = read_binary(capture + "/compact_topk_ids_i32.bin");
    auto reference = read_binary(capture + "/reference_stage1_f32.bin");
    auto aiter = read_binary(capture + "/aiter_stage1_f32.bin");
    if (hidden.size() != 2048 ||
        hidden_scale.size() != 16 * sizeof(float) ||
        weights.size() != 9 * 1024 * 2048 ||
        weight_scale.size() != 9 * 8 * 16 * sizeof(float) ||
        topk_ids.size() != 9 * sizeof(int32_t) ||
        reference.size() != 9 * 1024 * sizeof(float) ||
        aiter.size() != reference.size())
      throw std::runtime_error("capture binary size mismatch");

    hidden = repeat_rows(hidden, rows);
    hidden_scale = repeat_rows(hidden_scale, rows);
    topk_ids = repeat_rows(topk_ids, rows);
    reference = repeat_rows(reference, rows);
    aiter = repeat_rows(aiter, rows);

    DeviceBuffer d_hidden(hidden.size()), d_hidden_scale(hidden_scale.size());
    DeviceBuffer d_weights(weights.size()), d_weight_scale(weight_scale.size());
    DeviceBuffer d_topk_ids(topk_ids.size()), d_output(reference.size());
#define COPY(name)                                                             \
  HIP_CHECK(hipMemcpy(d_##name.pointer, name.data(), name.size(),               \
                      hipMemcpyHostToDevice))
    COPY(hidden);
    COPY(hidden_scale);
    COPY(weights);
    COPY(weight_scale);
    COPY(topk_ids);
#undef COPY

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(&function, module, symbol.c_str()));
    void* output_pointer = d_output.pointer;
    void* kernel_args[] = {
        &d_hidden.pointer,       &d_hidden_scale.pointer,
        &d_weights.pointer,      &d_weight_scale.pointer,
        &d_topk_ids.pointer,     &output_pointer,
    };
    auto launch = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(
          function, 576, static_cast<unsigned>(rows), 1, 64, 1, 1, 0,
          nullptr, kernel_args, nullptr));
    };
    for (int i = 0; i < 10; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    std::vector<float> output(rows * 9 * 1024), first_output;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, reference.size(),
                          hipMemcpyDeviceToHost));
      if (i == 0)
        first_output = output;
      else if (output != first_output)
        ++nondeterministic_iterations;
    }
    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));

    const auto* expected = reinterpret_cast<const float*>(reference.data());
    const auto* aiter_values = reinterpret_cast<const float*>(aiter.data());
    double absolute_sum = 0, dot = 0, out_norm = 0, ref_norm = 0;
    double aiter_dot = 0, aiter_norm = 0;
    float max_absolute = 0;
    for (size_t i = 0; i < output.size(); ++i) {
      const float error = std::abs(output[i] - expected[i]);
      absolute_sum += error;
      max_absolute = std::max(max_absolute, error);
      dot += static_cast<double>(output[i]) * expected[i];
      out_norm += static_cast<double>(output[i]) * output[i];
      ref_norm += static_cast<double>(expected[i]) * expected[i];
      aiter_dot += static_cast<double>(output[i]) * aiter_values[i];
      aiter_norm += static_cast<double>(aiter_values[i]) * aiter_values[i];
    }
    std::sort(timings.begin(), timings.end());
    const double cosine = dot / (std::sqrt(out_norm) * std::sqrt(ref_norm));
    const double aiter_cosine =
        aiter_dot / (std::sqrt(out_norm) * std::sqrt(aiter_norm));
    std::cout << "architecture=" << architecture << "\n"
              << "rows=" << rows << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "max_abs_error_f32=" << max_absolute << "\n"
              << "mean_abs_error_f32=" << absolute_sum / output.size() << "\n"
              << "cosine_f32=" << cosine << "\n"
              << "aiter_cosine_f32=" << aiter_cosine << "\n"
              << "median_us=" << timings[timings.size() / 2] << "\n";
    HIP_CHECK(hipModuleUnload(module));
    return nondeterministic_iterations == 0 && std::isfinite(cosine) &&
                   cosine > 0.999
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
