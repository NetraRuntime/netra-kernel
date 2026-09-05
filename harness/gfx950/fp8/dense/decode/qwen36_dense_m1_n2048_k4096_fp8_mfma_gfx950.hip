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

int main(int argc, char** argv) {
  try {
    if (argc < 3 || argc > 7) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations [symbol"
                   " [grid [threads]]]]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 200;
    const std::string symbol =
        argc >= 5 ? argv[4]
                  : "qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950";
    const unsigned int grid = argc >= 6 ? std::stoul(argv[5]) : 128;
    const unsigned int threads = argc >= 7 ? std::stoul(argv[6]) : 64;
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");
    if (grid == 0 || threads == 0)
      throw std::runtime_error("launch dimensions must be positive");

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
    auto deployed = read_binary(capture + "/output_bf16.bin");
    auto reference = read_binary(capture + "/reference_output_f32.bin");
    if (activation.size() != 4096 ||
        activation_scale.size() != 32 * sizeof(float) ||
        weight.size() != 2048ull * 4096 ||
        weight_scale.size() != 16 * 32 * sizeof(float) ||
        deployed.size() != 2048 * sizeof(uint16_t) ||
        reference.size() != 2048 * sizeof(float))
      throw std::runtime_error("capture binary size mismatch");

    DeviceBuffer d_activation(activation.size());
    DeviceBuffer d_activation_scale(activation_scale.size());
    DeviceBuffer d_weight(weight.size());
    DeviceBuffer d_weight_scale(weight_scale.size());
    DeviceBuffer d_output(deployed.size());
#define COPY(name)                                                             \
  HIP_CHECK(hipMemcpy(d_##name.pointer, name.data(), name.size(),               \
                      hipMemcpyHostToDevice))
    COPY(activation);
    COPY(activation_scale);
    COPY(weight);
    COPY(weight_scale);
#undef COPY

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(&function, module, symbol.c_str()));
    void* output_pointer = d_output.pointer;
    void* kernel_args[] = {
        &d_activation.pointer, &d_activation_scale.pointer,
        &d_weight.pointer, &d_weight_scale.pointer, &output_pointer,
    };
    auto launch = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(
          function, grid, 1, 1, threads, 1, 1, 0, nullptr, kernel_args,
          nullptr));
    };
    for (int i = 0; i < 10; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    std::vector<uint16_t> output(2048), first_output;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, deployed.size(),
                          hipMemcpyDeviceToHost));
      if (i == 0)
        first_output = output;
      else if (output != first_output)
        ++nondeterministic_iterations;
    }

    // Capture and replay the identical launch once to establish module-launch
    // compatibility with native HIP graphs.
    hipStream_t stream{};
    hipGraph_t graph{};
    hipGraphExec_t graph_exec{};
    HIP_CHECK(hipStreamCreate(&stream));
    HIP_CHECK(hipStreamBeginCapture(stream, hipStreamCaptureModeGlobal));
    HIP_CHECK(hipModuleLaunchKernel(
        function, grid, 1, 1, threads, 1, 1, 0, stream, kernel_args, nullptr));
    HIP_CHECK(hipStreamEndCapture(stream, &graph));
    HIP_CHECK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));
    for (int i = 0; i < 20; ++i)
      HIP_CHECK(hipGraphLaunch(graph_exec, stream));
    HIP_CHECK(hipStreamSynchronize(stream));
    std::vector<uint16_t> graph_output(2048);
    HIP_CHECK(hipMemcpy(graph_output.data(), d_output.pointer, deployed.size(),
                        hipMemcpyDeviceToHost));
    const bool graph_exact = graph_output == first_output;

    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipGraphExecDestroy(graph_exec));
    HIP_CHECK(hipGraphDestroy(graph));
    HIP_CHECK(hipStreamDestroy(stream));

    const auto* deployed_values =
        reinterpret_cast<const uint16_t*>(deployed.data());
    const auto* reference_values =
        reinterpret_cast<const float*>(reference.data());
    size_t deployed_bf16_mismatches = 0;
    float max_absolute_reference = 0;
    double mean_absolute_reference = 0;
    double dot = 0, out_norm = 0, ref_norm = 0;
    for (size_t i = 0; i < output.size(); ++i) {
      deployed_bf16_mismatches += output[i] != deployed_values[i];
      const float value = bf16_to_float(output[i]);
      const float error = std::abs(value - reference_values[i]);
      max_absolute_reference = std::max(max_absolute_reference, error);
      mean_absolute_reference += error;
      dot += static_cast<double>(value) * reference_values[i];
      out_norm += static_cast<double>(value) * value;
      ref_norm +=
          static_cast<double>(reference_values[i]) * reference_values[i];
    }
    std::sort(timings.begin(), timings.end());
    const double cosine = dot / (std::sqrt(out_norm) * std::sqrt(ref_norm));
    std::cout << "architecture=" << architecture << "\n"
              << "symbol=" << symbol << "\n"
              << "grid=" << grid << "\n"
              << "threads=" << threads << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact=" << (graph_exact ? "true" : "false")
              << "\n"
              << "deployed_bf16_mismatches=" << deployed_bf16_mismatches
              << "/2048\n"
              << "max_abs_error_reference_f32=" << max_absolute_reference
              << "\n"
              << "mean_abs_error_reference_f32="
              << mean_absolute_reference / output.size() << "\n"
              << "cosine_reference_f32=" << cosine << "\n"
              << "minimum_us=" << timings.front() << "\n"
              << "median_us=" << timings[timings.size() / 2] << "\n"
              << "maximum_us=" << timings.back() << "\n";
    HIP_CHECK(hipModuleUnload(module));
    return nondeterministic_iterations == 0 && graph_exact &&
                   std::isfinite(cosine) && cosine > 0.999
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
