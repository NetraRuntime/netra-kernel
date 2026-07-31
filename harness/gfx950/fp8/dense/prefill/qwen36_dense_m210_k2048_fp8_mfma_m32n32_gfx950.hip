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
    if (status != hipSuccess)                                                   \
      throw std::runtime_error(std::string(#expr) + ": " +                     \
                               hipGetErrorString(status));                      \
  } while (0)

constexpr size_t M = 210;
constexpr size_t K = 2048;
constexpr size_t GUARD_BYTES = 4096;

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

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer) static_cast<void>(hipFree(pointer));
  }
};

static float bf16_to_float(uint16_t value) {
  uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

static double percentile(const std::vector<float>& sorted, double fraction) {
  const double index = fraction * static_cast<double>(sorted.size() - 1);
  const size_t lower = static_cast<size_t>(std::floor(index));
  const size_t upper = static_cast<size_t>(std::ceil(index));
  const double weight = index - static_cast<double>(lower);
  return sorted[lower] * (1.0 - weight) + sorted[upper] * weight;
}

int main(int argc, char** argv) {
  try {
    if (argc < 3 || argc > 9) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations [symbol"
                   " [grid_x [grid_y [threads [n]]]]]]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 100;
    const std::string symbol =
        argc >= 5
            ? argv[4]
            : "qwen36_dense_m210_k2048_fp8_mfma_m32n32_gfx950";
    const size_t n =
        argc >= 9 ? static_cast<size_t>(std::stoull(argv[8])) : 12288;
    const unsigned int grid_x =
        argc >= 6 ? static_cast<unsigned int>(std::stoul(argv[5]))
                  : static_cast<unsigned int>(n / 32);
    const unsigned int grid_y =
        argc >= 7 ? static_cast<unsigned int>(std::stoul(argv[6]))
                  : static_cast<unsigned int>((M + 15) / 16);
    const unsigned int threads =
        argc >= 8 ? static_cast<unsigned int>(std::stoul(argv[7])) : 64;
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");
    if (grid_x == 0 || grid_y == 0 || threads == 0)
      throw std::runtime_error("launch dimensions must be positive");
    if (n != 9216 && n != 12288)
      throw std::runtime_error("n must be 9216 or 12288");
    const size_t output_elements = M * n;
    const size_t output_bytes = output_elements * sizeof(uint16_t);

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    auto activation = read_binary(capture + "/q_input.bin");
    auto activation_scale = read_binary(capture + "/x_scale.bin");
    auto weight = read_binary(capture + "/weight.bin");
    auto weight_scale = read_binary(capture + "/weight_scale.bin");
    auto cktile = read_binary(capture + "/cktile_output_bf16.bin");
    auto reference = read_binary(capture + "/reference_output_f32.bin");
    if (activation.size() != M * K ||
        activation_scale.size() != M * (K / 128) * sizeof(float) ||
        weight.size() != n * K ||
        weight_scale.size() != (n / 128) * (K / 128) * sizeof(float) ||
        cktile.size() != output_bytes ||
        reference.size() != output_elements * sizeof(float))
      throw std::runtime_error("capture binary size mismatch");

    DeviceBuffer d_activation(activation.size());
    DeviceBuffer d_activation_scale(activation_scale.size());
    DeviceBuffer d_weight(weight.size());
    DeviceBuffer d_weight_scale(weight_scale.size());
    DeviceBuffer d_output(output_bytes + GUARD_BYTES);
#define COPY(name)                                                             \
  HIP_CHECK(hipMemcpy(d_##name.pointer, name.data(), name.size(),               \
                      hipMemcpyHostToDevice))
    COPY(activation);
    COPY(activation_scale);
    COPY(weight);
    COPY(weight_scale);
#undef COPY
    HIP_CHECK(hipMemset(d_output.pointer, 0xa5, output_bytes + GUARD_BYTES));

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module, symbol.c_str()));
    void* output_pointer = d_output.pointer;
    uint64_t output_stride_bytes =
        static_cast<uint64_t>(n * sizeof(uint16_t));
    void* kernel_args[] = {
        &d_activation.pointer, &d_activation_scale.pointer,
        &d_weight.pointer, &d_weight_scale.pointer, &output_pointer,
        &output_stride_bytes,
    };
    auto launch = [&](hipStream_t stream) {
      HIP_CHECK(hipModuleLaunchKernel(function, grid_x, grid_y, 1,
                                      threads, 1, 1, 0, stream, kernel_args,
                                      nullptr));
    };
    for (int i = 0; i < 10; ++i) launch(nullptr);
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    std::vector<uint16_t> output(output_elements), first_output;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch(nullptr);
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, output_bytes,
                          hipMemcpyDeviceToHost));
      if (i == 0)
        first_output = output;
      else if (output != first_output)
        ++nondeterministic_iterations;
    }

    std::vector<uint8_t> guard(GUARD_BYTES);
    HIP_CHECK(hipMemcpy(
        guard.data(),
        static_cast<uint8_t*>(d_output.pointer) + output_bytes,
        GUARD_BYTES, hipMemcpyDeviceToHost));
    const size_t guard_mismatches =
        std::count_if(guard.begin(), guard.end(),
                      [](uint8_t value) { return value != 0xa5; });

    hipStream_t stream{};
    hipGraph_t graph{};
    hipGraphExec_t graph_exec{};
    HIP_CHECK(hipStreamCreate(&stream));
    HIP_CHECK(hipStreamBeginCapture(stream, hipStreamCaptureModeGlobal));
    launch(stream);
    HIP_CHECK(hipStreamEndCapture(stream, &graph));
    HIP_CHECK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));
    for (int i = 0; i < 20; ++i)
      HIP_CHECK(hipGraphLaunch(graph_exec, stream));
    HIP_CHECK(hipStreamSynchronize(stream));
    std::vector<uint16_t> graph_output(output_elements);
    HIP_CHECK(hipMemcpy(graph_output.data(), d_output.pointer, output_bytes,
                        hipMemcpyDeviceToHost));
    const bool graph_exact = graph_output == first_output;

    const auto* cktile_values =
        reinterpret_cast<const uint16_t*>(cktile.data());
    const auto* reference_values =
        reinterpret_cast<const float*>(reference.data());
    size_t cktile_mismatches = 0;
    float maximum_abs_cktile = 0;
    float maximum_abs_reference = 0;
    double mean_abs_reference = 0;
    double dot = 0, output_norm = 0, reference_norm = 0;
    for (size_t i = 0; i < output_elements; ++i) {
      cktile_mismatches += output[i] != cktile_values[i];
      const float value = bf16_to_float(output[i]);
      const float cktile_value = bf16_to_float(cktile_values[i]);
      const float reference_value = reference_values[i];
      maximum_abs_cktile =
          std::max(maximum_abs_cktile, std::abs(value - cktile_value));
      const float reference_error = std::abs(value - reference_value);
      maximum_abs_reference =
          std::max(maximum_abs_reference, reference_error);
      mean_abs_reference += reference_error;
      dot += static_cast<double>(value) * reference_value;
      output_norm += static_cast<double>(value) * value;
      reference_norm +=
          static_cast<double>(reference_value) * reference_value;
    }
    std::sort(timings.begin(), timings.end());
    const double cosine =
        dot / (std::sqrt(output_norm) * std::sqrt(reference_norm));

    std::cout << "architecture=" << architecture << "\n"
              << "shape_m=" << M << "\n"
              << "shape_n=" << n << "\n"
              << "shape_k=" << K << "\n"
              << "grid_x=" << grid_x << "\n"
              << "grid_y=" << grid_y << "\n"
              << "threads=" << threads << "\n"
              << "nondeterministic_iterations="
              << nondeterministic_iterations << "/" << iterations << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact=" << (graph_exact ? "true" : "false")
              << "\n"
              << "guard_mismatches=" << guard_mismatches << "/"
              << GUARD_BYTES << "\n"
              << "cktile_bf16_mismatches=" << cktile_mismatches << "/"
              << output_elements << "\n"
              << "maximum_abs_error_cktile=" << maximum_abs_cktile << "\n"
              << "maximum_abs_error_reference_f32="
              << maximum_abs_reference << "\n"
              << "mean_abs_error_reference_f32="
              << mean_abs_reference / output_elements << "\n"
              << "cosine_reference_f32=" << cosine << "\n"
              << "minimum_us=" << timings.front() << "\n"
              << "median_us=" << percentile(timings, 0.5) << "\n"
              << "p90_us=" << percentile(timings, 0.9) << "\n"
              << "maximum_us=" << timings.back() << "\n";

    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipGraphExecDestroy(graph_exec));
    HIP_CHECK(hipGraphDestroy(graph));
    HIP_CHECK(hipStreamDestroy(stream));
    HIP_CHECK(hipModuleUnload(module));
    return nondeterministic_iterations == 0 && graph_exact &&
                   guard_mismatches == 0 && std::isfinite(cosine) &&
                   cosine > 0.999
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
