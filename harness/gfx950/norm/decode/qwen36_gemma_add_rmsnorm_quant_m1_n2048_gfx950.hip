// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <cstring>
#include <cstdint>
#include <fstream>
#include <iomanip>
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

static size_t mismatches(
    const std::vector<uint8_t>& actual,
    const std::vector<uint8_t>& expected) {
  if (actual.size() != expected.size())
    throw std::runtime_error("comparison size mismatch");
  size_t count = 0;
  for (size_t i = 0; i < actual.size(); ++i) count += actual[i] != expected[i];
  return count;
}

static void print_byte_mismatches(
    const char* label,
    const std::vector<uint8_t>& actual,
    const std::vector<uint8_t>& expected,
    size_t limit = 32) {
  size_t printed = 0;
  for (size_t i = 0; i < actual.size() && printed < limit; ++i) {
    if (actual[i] == expected[i]) continue;
    std::cout << label << "_mismatch[" << i << "]=0x" << std::hex
              << static_cast<unsigned>(actual[i]) << ",expected=0x"
              << static_cast<unsigned>(expected[i]) << std::dec << "\n";
    ++printed;
  }
}

static void print_scale_mismatches(
    const std::vector<uint8_t>& actual,
    const std::vector<uint8_t>& expected) {
  for (size_t i = 0; i < actual.size() / sizeof(float); ++i) {
    uint32_t actual_bits = 0;
    uint32_t expected_bits = 0;
    std::memcpy(&actual_bits, actual.data() + i * sizeof(float), sizeof(float));
    std::memcpy(
        &expected_bits, expected.data() + i * sizeof(float), sizeof(float));
    if (actual_bits == expected_bits) continue;
    float actual_value = 0;
    float expected_value = 0;
    std::memcpy(&actual_value, &actual_bits, sizeof(float));
    std::memcpy(&expected_value, &expected_bits, sizeof(float));
    std::cout << "scale_mismatch[" << i << "]=" << std::setprecision(9)
              << actual_value << "(0x" << std::hex << actual_bits
              << "),expected=" << std::dec << expected_value << "(0x"
              << std::hex << expected_bits << std::dec << ")\n";
  }
}

int main(int argc, char** argv) {
  try {
    if (argc < 4 || argc > 5) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR QUANT_REFERENCE_DIR"
                   " [iterations]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const std::string quant_reference = argv[3];
    const int iterations = argc == 5 ? std::stoi(argv[4]) : 500;
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
    auto expected_output = read_binary(capture + "/output_bf16.bin");
    auto expected_residual = read_binary(capture + "/residual_out_bf16.bin");
    auto expected_fp8 = read_binary(quant_reference + "/output_fp8.bin");
    auto expected_scale =
        read_binary(quant_reference + "/output_scale_f32.bin");
    if (input.size() != 4096 || residual.size() != 4096 ||
        weight.size() != 4096 || expected_output.size() != 4096 ||
        expected_residual.size() != 4096 || expected_fp8.size() != 2048 ||
        expected_scale.size() != 64)
      throw std::runtime_error("capture binary size mismatch");

    DeviceBuffer d_input(input.size());
    DeviceBuffer d_residual(residual.size());
    DeviceBuffer d_weight(weight.size());
    DeviceBuffer d_output(expected_output.size());
    DeviceBuffer d_residual_out(expected_residual.size());
    DeviceBuffer d_fp8(expected_fp8.size());
    DeviceBuffer d_scale(expected_scale.size());
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
        "qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950"));
    void* output_pointer = d_output.pointer;
    void* residual_out_pointer = d_residual_out.pointer;
    void* fp8_pointer = d_fp8.pointer;
    void* scale_pointer = d_scale.pointer;
    const double epsilon = 1.0e-6;
    void* kernel_args[] = {
        &output_pointer,
        &d_input.pointer,
        &d_residual.pointer,
        &residual_out_pointer,
        &d_weight.pointer,
        &fp8_pointer,
        &scale_pointer,
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
    std::vector<uint8_t> output(expected_output.size());
    std::vector<uint8_t> residual_out(expected_residual.size());
    std::vector<uint8_t> fp8(expected_fp8.size());
    std::vector<uint8_t> scale(expected_scale.size());
    std::vector<uint8_t> first_output, first_residual, first_fp8, first_scale;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
#define READ(name)                                                             \
  HIP_CHECK(hipMemcpy(name.data(), d_##name.pointer, name.size(),               \
                      hipMemcpyDeviceToHost))
      READ(output);
      READ(residual_out);
      READ(fp8);
      READ(scale);
#undef READ
      if (i == 0) {
        first_output = output;
        first_residual = residual_out;
        first_fp8 = fp8;
        first_scale = scale;
      } else if (
          output != first_output || residual_out != first_residual ||
          fp8 != first_fp8 || scale != first_scale) {
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
    std::vector<uint8_t> graph_output(output.size());
    std::vector<uint8_t> graph_residual(residual_out.size());
    std::vector<uint8_t> graph_fp8(fp8.size());
    std::vector<uint8_t> graph_scale(scale.size());
#define READ_GRAPH(name)                                                       \
  HIP_CHECK(hipMemcpy(graph_##name.data(), d_##name.pointer, name.size(),       \
                      hipMemcpyDeviceToHost))
    READ_GRAPH(output);
    READ_GRAPH(fp8);
    READ_GRAPH(scale);
#undef READ_GRAPH
    HIP_CHECK(hipMemcpy(
        graph_residual.data(), d_residual_out.pointer, graph_residual.size(),
        hipMemcpyDeviceToHost));
    const bool graph_exact =
        graph_output == first_output && graph_residual == first_residual &&
        graph_fp8 == first_fp8 && graph_scale == first_scale;

    const size_t output_mismatches = mismatches(output, expected_output);
    const size_t residual_mismatches =
        mismatches(residual_out, expected_residual);
    const size_t fp8_mismatches = mismatches(fp8, expected_fp8);
    const size_t scale_byte_mismatches = mismatches(scale, expected_scale);
    if (fp8_mismatches != 0)
      print_byte_mismatches("fp8", fp8, expected_fp8);
    if (scale_byte_mismatches != 0)
      print_scale_mismatches(scale, expected_scale);
    std::sort(timings.begin(), timings.end());
    std::cout << "architecture=" << architecture << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact=" << (graph_exact ? "true" : "false")
              << "\n"
              << "output_bf16_byte_mismatches=" << output_mismatches
              << "/" << expected_output.size() << "\n"
              << "residual_bf16_byte_mismatches=" << residual_mismatches
              << "/" << expected_residual.size() << "\n"
              << "output_fp8_byte_mismatches=" << fp8_mismatches
              << "/" << expected_fp8.size() << "\n"
              << "scale_f32_byte_mismatches=" << scale_byte_mismatches
              << "/" << expected_scale.size() << "\n"
              << "minimum_us=" << timings.front() << "\n"
              << "median_us=" << timings[timings.size() / 2] << "\n"
              << "maximum_us=" << timings.back() << "\n";

    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipGraphExecDestroy(graph_exec));
    HIP_CHECK(hipGraphDestroy(graph));
    HIP_CHECK(hipStreamDestroy(stream));
    HIP_CHECK(hipModuleUnload(module));
    return nondeterministic_iterations == 0 && graph_exact &&
                   output_mismatches == 0 && residual_mismatches == 0 &&
                   fp8_mismatches == 0 && scale_byte_mismatches == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
