// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <cstdint>
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
    const std::vector<uint8_t>& row,
    int rows) {
  std::vector<uint8_t> repeated(row.size() * static_cast<size_t>(rows));
  for (int i = 0; i < rows; ++i)
    std::copy(row.begin(), row.end(), repeated.begin() + i * row.size());
  return repeated;
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
    if (argc < 3 || argc > 5) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations] [rows]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 1000;
    const int rows = argc == 5 ? std::stoi(argv[4]) : 1;
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");
    if (rows != 1 && rows != 16)
      throw std::runtime_error("rows must be 1 or 16");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    auto hidden = read_binary(capture + "/hidden_bf16.bin");
    auto weight = read_binary(capture + "/router_weight_bf16.bin");
    auto expected = read_binary(capture + "/expected_logits_bf16.bin");
    if (hidden.size() != 4096 || weight.size() != 256 * 4096 ||
        expected.size() != 512)
      throw std::runtime_error("capture binary size mismatch");
    hidden = repeat_rows(hidden, rows);
    expected = repeat_rows(expected, rows);

    DeviceBuffer d_hidden(hidden.size());
    DeviceBuffer d_weight(weight.size());
    DeviceBuffer d_output(expected.size());
    HIP_CHECK(hipMemcpy(
        d_hidden.pointer, hidden.data(), hidden.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(
        d_weight.pointer, weight.data(), weight.size(), hipMemcpyHostToDevice));

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module, "qwen36_router_bf16_gemv_gfx950"));
    void* output_pointer = d_output.pointer;
    void* kernel_args[] = {
        &output_pointer,
        &d_hidden.pointer,
        &d_weight.pointer,
    };
    auto launch = [&](hipStream_t stream = nullptr) {
      HIP_CHECK(hipModuleLaunchKernel(
          function, 256, rows, 1, 64, 1, 1, 0, stream, kernel_args,
          nullptr));
    };
    for (int i = 0; i < 20; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> timings;
    std::vector<uint8_t> output(expected.size());
    std::vector<uint8_t> first;
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
          output.data(), d_output.pointer, output.size(), hipMemcpyDeviceToHost));
      if (i == 0)
        first = output;
      else if (output != first)
        ++nondeterministic_iterations;
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
    HIP_CHECK(hipMemcpy(
        graph_output.data(), d_output.pointer, graph_output.size(),
        hipMemcpyDeviceToHost));

    size_t byte_mismatches = 0;
    for (size_t i = 0; i < output.size(); ++i)
      byte_mismatches += output[i] != expected[i];
    std::sort(timings.begin(), timings.end());
    const bool graph_exact = graph_output == first;
    std::cout << "architecture=" << architecture << "\n"
              << "rows=" << rows << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact=" << (graph_exact ? "true" : "false")
              << "\n"
              << "byte_mismatches=" << byte_mismatches << "/"
              << expected.size() << "\n"
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
                   byte_mismatches == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
