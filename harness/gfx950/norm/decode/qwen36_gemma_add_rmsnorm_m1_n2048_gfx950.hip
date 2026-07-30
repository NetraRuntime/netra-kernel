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
    if (argc < 3 || argc > 4) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc == 4 ? std::stoi(argv[3]) : 500;
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    auto input = read_binary(capture + "/input_bf16.bin");
    auto residual = read_binary(capture + "/residual_bf16.bin");
    auto weight = read_binary(capture + "/weight_bf16.bin");
    auto deployed_output = read_binary(capture + "/output_bf16.bin");
    auto deployed_residual = read_binary(capture + "/residual_out_bf16.bin");
    auto reference = read_binary(capture + "/reference_output_f32.bin");
    const size_t bf16_bytes = 2048 * sizeof(uint16_t);
    if (input.size() != bf16_bytes || residual.size() != bf16_bytes ||
        weight.size() != bf16_bytes ||
        deployed_output.size() != bf16_bytes ||
        deployed_residual.size() != bf16_bytes ||
        reference.size() != 2048 * sizeof(float))
      throw std::runtime_error("capture binary size mismatch");

    DeviceBuffer d_input(input.size());
    DeviceBuffer d_residual(residual.size());
    DeviceBuffer d_weight(weight.size());
    DeviceBuffer d_output(deployed_output.size());
    DeviceBuffer d_residual_out(deployed_residual.size());
#define COPY(name)                                                             \
  HIP_CHECK(hipMemcpy(d_##name.pointer, name.data(), name.size(),               \
                      hipMemcpyHostToDevice))
    COPY(input);
    COPY(residual);
    COPY(weight);
#undef COPY

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module,
        "qwen36_gemma_add_rmsnorm_m1_n2048_gfx950"));
    void* output_pointer = d_output.pointer;
    void* residual_out_pointer = d_residual_out.pointer;
    const double epsilon = 1.0e-6;
    void* kernel_args[] = {
        &output_pointer, &d_input.pointer, &d_residual.pointer,
        &residual_out_pointer, &d_weight.pointer,
        const_cast<double*>(&epsilon),
    };
    auto launch = [&](hipStream_t stream = nullptr) {
      HIP_CHECK(hipModuleLaunchKernel(
          function, 1, 1, 1, 256, 1, 1, 0, stream, kernel_args, nullptr));
    };
    for (int i = 0; i < 20; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    std::vector<uint16_t> output(2048), residual_out(2048);
    std::vector<uint16_t> first_output, first_residual;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, bf16_bytes,
                          hipMemcpyDeviceToHost));
      HIP_CHECK(hipMemcpy(residual_out.data(), d_residual_out.pointer,
                          bf16_bytes, hipMemcpyDeviceToHost));
      if (i == 0) {
        first_output = output;
        first_residual = residual_out;
      } else if (output != first_output || residual_out != first_residual) {
        ++nondeterministic_iterations;
      }
    }

    hipStream_t stream{};
    hipGraph_t graph{};
    hipGraphExec_t graph_exec{};
    HIP_CHECK(hipStreamCreate(&stream));
    HIP_CHECK(hipStreamBeginCapture(stream, hipStreamCaptureModeGlobal));
    launch(stream);
    HIP_CHECK(hipStreamEndCapture(stream, &graph));
    HIP_CHECK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));
    for (int i = 0; i < 20; ++i) HIP_CHECK(hipGraphLaunch(graph_exec, stream));
    HIP_CHECK(hipStreamSynchronize(stream));
    std::vector<uint16_t> graph_output(2048), graph_residual(2048);
    HIP_CHECK(hipMemcpy(graph_output.data(), d_output.pointer, bf16_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(graph_residual.data(), d_residual_out.pointer,
                        bf16_bytes, hipMemcpyDeviceToHost));
    const bool graph_exact =
        graph_output == first_output && graph_residual == first_residual;

    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipGraphExecDestroy(graph_exec));
    HIP_CHECK(hipGraphDestroy(graph));
    HIP_CHECK(hipStreamDestroy(stream));

    const auto* deployed_output_values =
        reinterpret_cast<const uint16_t*>(deployed_output.data());
    const auto* deployed_residual_values =
        reinterpret_cast<const uint16_t*>(deployed_residual.data());
    const auto* reference_values =
        reinterpret_cast<const float*>(reference.data());
    size_t output_mismatches = 0, residual_mismatches = 0;
    float max_absolute_reference = 0;
    double mean_absolute_reference = 0;
    for (size_t i = 0; i < output.size(); ++i) {
      output_mismatches += output[i] != deployed_output_values[i];
      residual_mismatches +=
          residual_out[i] != deployed_residual_values[i];
      const float error =
          std::abs(bf16_to_float(output[i]) - reference_values[i]);
      max_absolute_reference = std::max(max_absolute_reference, error);
      mean_absolute_reference += error;
    }
    std::sort(timings.begin(), timings.end());
    std::cout << "architecture=" << architecture << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact=" << (graph_exact ? "true" : "false")
              << "\n"
              << "deployed_output_bf16_mismatches=" << output_mismatches
              << "/2048\n"
              << "deployed_residual_bf16_mismatches=" << residual_mismatches
              << "/2048\n"
              << "max_abs_error_reference_f32=" << max_absolute_reference
              << "\n"
              << "mean_abs_error_reference_f32="
              << mean_absolute_reference / output.size() << "\n"
              << "minimum_us=" << timings.front() << "\n"
              << "median_us=" << timings[timings.size() / 2] << "\n"
              << "maximum_us=" << timings.back() << "\n";
    HIP_CHECK(hipModuleUnload(module));
    return nondeterministic_iterations == 0 && graph_exact &&
                   output_mismatches == 0 && residual_mismatches == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
