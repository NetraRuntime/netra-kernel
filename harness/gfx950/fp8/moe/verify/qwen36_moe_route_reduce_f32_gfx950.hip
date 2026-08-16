// SPDX-License-Identifier: MIT

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <random>
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

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer != nullptr) static_cast<void>(hipFree(pointer));
  }
};

static uint16_t float_to_bf16_rne(float value) {
  uint32_t bits = 0;
  std::memcpy(&bits, &value, sizeof(bits));
  bits += 0x7fffu + ((bits >> 16) & 1u);
  return static_cast<uint16_t>(bits >> 16);
}

int main(int argc, char** argv) {
  try {
    if (argc < 2 || argc > 4) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco [rows=768] [iterations=200]\n";
      return 2;
    }
    const int rows = argc >= 3 ? std::stoi(argv[2]) : 768;
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 200;
    if (rows <= 0 || iterations <= 0) {
      throw std::runtime_error("rows and iterations must be positive");
    }

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0) {
      throw std::runtime_error(
          std::string("refusing non-gfx950 device: ") + properties.gcnArchName);
    }

    constexpr int kTopk = 9;
    constexpr int kHidden = 2048;
    const size_t partial_count =
        static_cast<size_t>(rows) * kTopk * kHidden;
    const size_t weight_count = static_cast<size_t>(rows) * kTopk;
    const size_t output_count = static_cast<size_t>(rows) * kHidden;
    std::vector<float> partials(partial_count);
    std::vector<float> weights(weight_count);
    std::mt19937 generator(0x95036u);
    std::uniform_real_distribution<float> partial_distribution(-2.0f, 2.0f);
    std::uniform_real_distribution<float> weight_distribution(0.001f, 1.0f);
    for (float& value : partials) value = partial_distribution(generator);
    for (int row = 0; row < rows; ++row) {
      float sum = 0.0f;
      for (int slot = 0; slot < kTopk; ++slot) {
        float value = weight_distribution(generator);
        weights[static_cast<size_t>(row) * kTopk + slot] = value;
        sum += value;
      }
      for (int slot = 0; slot < kTopk; ++slot) {
        weights[static_cast<size_t>(row) * kTopk + slot] /= sum;
      }
    }
    std::vector<uint16_t> reference(output_count);
    for (int row = 0; row < rows; ++row) {
      for (int column = 0; column < kHidden; ++column) {
        float sum = partials[
                        (static_cast<size_t>(row) * kTopk) * kHidden + column] *
                    weights[static_cast<size_t>(row) * kTopk];
        for (int slot = 1; slot < kTopk; ++slot) {
          sum += partials[(static_cast<size_t>(row) * kTopk + slot) * kHidden +
                          column] *
                 weights[static_cast<size_t>(row) * kTopk + slot];
        }
        reference[static_cast<size_t>(row) * kHidden + column] =
            float_to_bf16_rne(sum);
      }
    }

    DeviceBuffer d_partials(partial_count * sizeof(float));
    DeviceBuffer d_weights(weight_count * sizeof(float));
    DeviceBuffer d_output(output_count * sizeof(uint16_t));
    HIP_CHECK(hipMemcpy(d_partials.pointer, partials.data(),
                        partial_count * sizeof(float), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_weights.pointer, weights.data(),
                        weight_count * sizeof(float), hipMemcpyHostToDevice));

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, argv[1]));
    HIP_CHECK(hipModuleGetFunction(
        &function, module, "qwen36_moe_route_reduce_f32_gfx950"));
    void* output_pointer = d_output.pointer;
    void* arguments[] = {
        &d_partials.pointer, &d_weights.pointer, &output_pointer,
    };
    auto launch = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(function, 32, rows, 1, 64, 1, 1, 0,
                                      nullptr, arguments, nullptr));
    };
    for (int index = 0; index < 10; ++index) launch();
    HIP_CHECK(hipDeviceSynchronize());

    std::vector<uint16_t> actual(output_count);
    HIP_CHECK(hipMemcpy(actual.data(), d_output.pointer,
                        output_count * sizeof(uint16_t), hipMemcpyDeviceToHost));
    size_t mismatches = 0;
    for (size_t index = 0; index < output_count; ++index) {
      mismatches += actual[index] != reference[index];
    }

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    timings.reserve(iterations);
    std::vector<uint16_t> first = actual;
    size_t nondeterministic_iterations = 0;
    for (int index = 0; index < iterations; ++index) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0.0f;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(actual.data(), d_output.pointer,
                          output_count * sizeof(uint16_t), hipMemcpyDeviceToHost));
      nondeterministic_iterations += actual != first;
    }
    std::sort(timings.begin(), timings.end());
    std::cout << "architecture=" << properties.gcnArchName << "\n"
              << "rows=" << rows << "\n"
              << "bf16_mismatches=" << mismatches << "/" << output_count << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "median_us=" << timings[timings.size() / 2] << "\n";
    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(module));
    return mismatches == 0 && nondeterministic_iterations == 0 ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
