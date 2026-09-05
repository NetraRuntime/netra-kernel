// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
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
  const uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result = 0.0f;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

int main(int argc, char** argv) {
  try {
    if (argc < 3 || argc > 8) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco CAPTURE_DIR [iterations] [rows]"
                   " [kernel_name] [launch_kind] [output.bin]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const int iterations = argc >= 4 ? std::stoi(argv[3]) : 1000;
    const int rows = argc >= 5 ? std::stoi(argv[4]) : 16;
    const std::string kernel_name =
        argc >= 6 ? argv[5] : "qwen36_gdn_ba_bf16_gemv_gfx950";
    const std::string launch_kind = argc >= 7 ? argv[6] : "gemv";
    const std::string output_path = argc >= 8 ? argv[7] : "";
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");
    if (rows != 1 && rows != 16)
      throw std::runtime_error("rows must be 1 or 16");
    if (launch_kind != "gemv" && launch_kind != "mfma_m16")
      throw std::runtime_error("launch_kind must be gemv or mfma_m16");
    if (launch_kind == "mfma_m16" && rows != 16)
      throw std::runtime_error("mfma_m16 requires rows=16");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    auto hidden = read_binary(capture + "/hidden_bf16.bin");
    auto weight = read_binary(capture + "/ba_weight_bf16.bin");
    auto expected = read_binary(capture + "/expected_ba_bf16.bin");
    if (hidden.size() != 16 * 2048 * 2 || weight.size() != 64 * 2048 * 2 ||
        expected.size() != 16 * 64 * 2)
      throw std::runtime_error("capture binary size mismatch");
    hidden.resize(static_cast<size_t>(rows) * 2048 * 2);
    expected.resize(static_cast<size_t>(rows) * 64 * 2);

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
    HIP_CHECK(hipModuleGetFunction(&function, module, kernel_name.c_str()));
    void* output_pointer = d_output.pointer;
    void* kernel_args[] = {
        &output_pointer,
        &d_hidden.pointer,
        &d_weight.pointer,
    };
    auto launch = [&](hipStream_t stream = nullptr) {
      const unsigned int grid_x = launch_kind == "mfma_m16" ? 4 : 64;
      const unsigned int grid_y =
          launch_kind == "mfma_m16" ? 1 : static_cast<unsigned int>(rows);
      HIP_CHECK(hipModuleLaunchKernel(
          function, grid_x, grid_y, 1, 64, 1, 1, 0, stream, kernel_args,
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
    size_t element_mismatches = 0;
    size_t first_mismatch = output.size() / 2;
    for (size_t i = 0; i < output.size(); ++i)
      byte_mismatches += output[i] != expected[i];
    for (size_t i = 0; i < output.size(); i += 2) {
      const bool mismatch =
          output[i] != expected[i] || output[i + 1] != expected[i + 1];
      if (mismatch && first_mismatch == output.size() / 2)
        first_mismatch = i / 2;
      element_mismatches += mismatch;
    }
    std::sort(timings.begin(), timings.end());
    if (!output_path.empty()) {
      std::ofstream output_file(output_path, std::ios::binary);
      if (!output_file)
        throw std::runtime_error("cannot open output path " + output_path);
      output_file.write(
          reinterpret_cast<const char*>(output.data()), output.size());
      if (!output_file)
        throw std::runtime_error("cannot write output path " + output_path);
    }
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
              << "element_mismatches=" << element_mismatches << "/"
              << expected.size() / 2 << "\n";
    if (first_mismatch != output.size() / 2) {
      uint16_t actual_bits = 0;
      uint16_t expected_bits = 0;
      std::memcpy(
          &actual_bits, output.data() + first_mismatch * 2,
          sizeof(actual_bits));
      std::memcpy(
          &expected_bits, expected.data() + first_mismatch * 2,
          sizeof(expected_bits));
      std::cout << "first_mismatch_index=" << first_mismatch << "\n"
                << "first_mismatch_row=" << first_mismatch / 64 << "\n"
                << "first_mismatch_column=" << first_mismatch % 64 << "\n"
                << "first_actual_bits=" << actual_bits << "\n"
                << "first_expected_bits=" << expected_bits << "\n"
                << "first_actual=" << bf16_to_float(actual_bits) << "\n"
                << "first_expected=" << bf16_to_float(expected_bits) << "\n";
    }
    std::cout
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
