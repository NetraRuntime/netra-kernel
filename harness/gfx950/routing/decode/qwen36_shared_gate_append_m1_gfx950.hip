// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
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

static void print_weight_mismatches(
    const std::vector<uint8_t>& actual,
    const std::vector<uint8_t>& expected) {
  for (size_t i = 0; i < actual.size() / sizeof(float); ++i) {
    uint32_t actual_bits = 0;
    uint32_t expected_bits = 0;
    std::memcpy(&actual_bits, actual.data() + i * 4, 4);
    std::memcpy(&expected_bits, expected.data() + i * 4, 4);
    if (actual_bits == expected_bits) continue;
    float actual_value = 0;
    float expected_value = 0;
    std::memcpy(&actual_value, &actual_bits, 4);
    std::memcpy(&expected_value, &expected_bits, 4);
    std::cout << "weight_mismatch[" << i << "]=" << std::setprecision(9)
              << actual_value << "(0x" << std::hex << actual_bits
              << "),expected=" << std::dec << expected_value << "(0x"
              << std::hex << expected_bits << std::dec << ")\n";
  }
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
    const int iterations = argc == 4 ? std::stoi(argv[3]) : 5000;
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    auto hidden = read_binary(capture + "/hidden_bf16.bin");
    auto weight =
        read_binary(capture + "/shared_gate_weight_bf16.bin");
    auto routed_ids = read_binary(capture + "/routed_ids_i32.bin");
    auto routed_weights = read_binary(capture + "/routed_weights_f32.bin");
    auto expected_ids = read_binary(capture + "/expected_ids_i32.bin");
    auto expected_weights =
        read_binary(capture + "/expected_weights_f32.bin");
    if (hidden.size() != 4096 || weight.size() != 4096 ||
        routed_ids.size() != 32 || routed_weights.size() != 32 ||
        expected_ids.size() != 36 || expected_weights.size() != 36)
      throw std::runtime_error("capture binary size mismatch");

    DeviceBuffer d_hidden(hidden.size());
    DeviceBuffer d_weight(weight.size());
    DeviceBuffer d_routed_ids(routed_ids.size());
    DeviceBuffer d_routed_weights(routed_weights.size());
    DeviceBuffer d_output_ids(expected_ids.size());
    DeviceBuffer d_output_weights(expected_weights.size());
#define COPY(name)                                                             \
  HIP_CHECK(hipMemcpy(d_##name.pointer, name.data(), name.size(),               \
                      hipMemcpyHostToDevice))
    COPY(hidden);
    COPY(weight);
    COPY(routed_ids);
    COPY(routed_weights);
#undef COPY

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module, "qwen36_shared_gate_append_m1_gfx950"));
    void* output_ids_pointer = d_output_ids.pointer;
    void* output_weights_pointer = d_output_weights.pointer;
    void* kernel_args[] = {
        &output_ids_pointer,
        &output_weights_pointer,
        &d_hidden.pointer,
        &d_weight.pointer,
        &d_routed_ids.pointer,
        &d_routed_weights.pointer,
    };
    auto launch = [&](hipStream_t stream = nullptr) {
      HIP_CHECK(hipModuleLaunchKernel(
          function, 1, 1, 1, 64, 1, 1, 0, stream, kernel_args, nullptr));
    };
    for (int i = 0; i < 20; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    std::vector<uint8_t> output_ids(expected_ids.size());
    std::vector<uint8_t> output_weights(expected_weights.size());
    std::vector<uint8_t> first_ids, first_weights;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      timings.push_back(milliseconds * 1000.0f);
      HIP_CHECK(hipMemcpy(
          output_ids.data(), d_output_ids.pointer, output_ids.size(),
          hipMemcpyDeviceToHost));
      HIP_CHECK(hipMemcpy(
          output_weights.data(), d_output_weights.pointer,
          output_weights.size(), hipMemcpyDeviceToHost));
      if (i == 0) {
        first_ids = output_ids;
        first_weights = output_weights;
      } else if (
          output_ids != first_ids || output_weights != first_weights) {
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
    std::vector<uint8_t> graph_ids(output_ids.size());
    std::vector<uint8_t> graph_weights(output_weights.size());
    HIP_CHECK(hipMemcpy(
        graph_ids.data(), d_output_ids.pointer, graph_ids.size(),
        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(
        graph_weights.data(), d_output_weights.pointer, graph_weights.size(),
        hipMemcpyDeviceToHost));
    const bool graph_exact =
        graph_ids == first_ids && graph_weights == first_weights;

    const size_t id_mismatches = mismatches(output_ids, expected_ids);
    const size_t weight_mismatches =
        mismatches(output_weights, expected_weights);
    if (weight_mismatches != 0)
      print_weight_mismatches(output_weights, expected_weights);
    std::sort(timings.begin(), timings.end());
    std::cout << "architecture=" << architecture << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact=" << (graph_exact ? "true" : "false")
              << "\n"
              << "id_byte_mismatches=" << id_mismatches << "/"
              << expected_ids.size() << "\n"
              << "weight_byte_mismatches=" << weight_mismatches << "/"
              << expected_weights.size() << "\n"
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
                   id_mismatches == 0 && weight_mismatches == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
