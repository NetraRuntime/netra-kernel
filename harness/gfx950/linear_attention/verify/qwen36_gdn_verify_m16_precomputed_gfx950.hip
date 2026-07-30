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
    const hipError_t status = (expr);                                           \
    if (status != hipSuccess)                                                   \
      throw std::runtime_error(std::string(#expr) + ": " +                     \
                               hipGetErrorString(status));                      \
  } while (0)

constexpr float kAtol = 0.03125f;
constexpr float kRtol = 0.010f;
constexpr double kMinimumCosine = 0.9995;

static std::vector<uint8_t> read_binary(const std::string& path,
                                        size_t expected_bytes) {
  std::ifstream input(path, std::ios::binary | std::ios::ate);
  if (!input) throw std::runtime_error("cannot open " + path);
  const auto size = static_cast<size_t>(input.tellg());
  if (size != expected_bytes)
    throw std::runtime_error(path + ": got " + std::to_string(size) +
                             " bytes, expected " +
                             std::to_string(expected_bytes));
  input.seekg(0);
  std::vector<uint8_t> data(size);
  input.read(reinterpret_cast<char*>(data.data()),
             static_cast<std::streamsize>(size));
  if (!input) throw std::runtime_error("cannot read " + path);
  return data;
}

static std::vector<uint8_t> pad_token_stride(
    const std::vector<uint8_t>& compact, size_t tokens,
    size_t compact_elements_per_token, size_t stride_elements,
    size_t element_bytes) {
  if (stride_elements < compact_elements_per_token ||
      compact.size() !=
          tokens * compact_elements_per_token * element_bytes)
    throw std::runtime_error("invalid padded token-stride request");
  std::vector<uint8_t> padded(tokens * stride_elements * element_bytes);
  const size_t compact_token_bytes =
      compact_elements_per_token * element_bytes;
  const size_t stride_bytes = stride_elements * element_bytes;
  for (size_t token = 0; token < tokens; ++token)
    std::memcpy(padded.data() + token * stride_bytes,
                compact.data() + token * compact_token_bytes,
                compact_token_bytes);
  return padded;
}

static void write_binary(const std::string& path,
                         const std::vector<uint8_t>& data) {
  std::ofstream output(path, std::ios::binary);
  if (!output) throw std::runtime_error("cannot open output " + path);
  output.write(reinterpret_cast<const char*>(data.data()),
               static_cast<std::streamsize>(data.size()));
  if (!output) throw std::runtime_error("cannot write " + path);
}

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer) static_cast<void>(hipFree(pointer));
  }
};

static float bf16_to_float(const uint8_t* bytes) {
  uint16_t value = 0;
  std::memcpy(&value, bytes, sizeof(value));
  const uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result = 0.0f;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

struct Comparison {
  size_t elements = 0;
  size_t mismatches = 0;
  size_t actual_nonfinite = 0;
  size_t expected_nonfinite = 0;
  size_t worst_index = 0;
  double max_abs = 0.0;
  double max_relative = 0.0;
  double mean_abs = 0.0;
  double rmse = 0.0;
  double cosine = 0.0;
  bool bit_exact = false;
  bool preregistered_pass = false;
};

static Comparison compare_bf16(const std::vector<uint8_t>& actual,
                               const std::vector<uint8_t>& expected) {
  if (actual.size() != expected.size() || actual.size() % 2 != 0)
    throw std::runtime_error("BF16 comparison size mismatch");
  Comparison result;
  result.elements = actual.size() / 2;
  result.bit_exact = actual == expected;
  double absolute_sum = 0.0;
  double squared_sum = 0.0;
  double dot = 0.0;
  double actual_squared = 0.0;
  double expected_squared = 0.0;
  for (size_t i = 0; i < result.elements; ++i) {
    const float a = bf16_to_float(actual.data() + i * 2);
    const float e = bf16_to_float(expected.data() + i * 2);
    result.actual_nonfinite += !std::isfinite(a);
    result.expected_nonfinite += !std::isfinite(e);
    result.mismatches +=
        actual[i * 2] != expected[i * 2] ||
        actual[i * 2 + 1] != expected[i * 2 + 1];
    const double delta = std::abs(static_cast<double>(a) - e);
    if (delta > result.max_abs) {
      result.max_abs = delta;
      result.worst_index = i;
    }
    if (!(std::abs(a) < kAtol && std::abs(e) < kAtol)) {
      result.max_relative = std::max(
          result.max_relative,
          delta / std::max(std::abs(static_cast<double>(e)), 1e-6));
    }
    absolute_sum += delta;
    squared_sum += delta * delta;
    dot += static_cast<double>(a) * e;
    actual_squared += static_cast<double>(a) * a;
    expected_squared += static_cast<double>(e) * e;
  }
  result.mean_abs = absolute_sum / result.elements;
  result.rmse = std::sqrt(squared_sum / result.elements);
  const double denominator = std::sqrt(actual_squared * expected_squared);
  result.cosine =
      denominator == 0.0 ? (result.bit_exact ? 1.0 : 0.0) : dot / denominator;
  result.cosine = std::clamp(result.cosine, -1.0, 1.0);
  result.preregistered_pass =
      result.actual_nonfinite == 0 && result.expected_nonfinite == 0 &&
      result.max_abs <= kAtol && result.max_relative <= kRtol &&
      result.cosine >= kMinimumCosine;
  return result;
}

static void print_comparison(const std::string& name,
                             const Comparison& comparison) {
  std::cout << name << "_bit_exact="
            << (comparison.bit_exact ? "true" : "false") << "\n"
            << name << "_preregistered_pass="
            << (comparison.preregistered_pass ? "true" : "false") << "\n"
            << name << "_mismatches=" << comparison.mismatches << "/"
            << comparison.elements << "\n"
            << name << "_max_abs=" << comparison.max_abs << "\n"
            << name << "_max_relative=" << comparison.max_relative << "\n"
            << name << "_mean_abs=" << comparison.mean_abs << "\n"
            << name << "_rmse=" << comparison.rmse << "\n"
            << name << "_cosine=" << comparison.cosine << "\n"
            << name << "_worst_index=" << comparison.worst_index << "\n"
            << name << "_actual_nonfinite="
            << comparison.actual_nonfinite << "\n"
            << name << "_expected_nonfinite="
            << comparison.expected_nonfinite << "\n";
}

int main(int argc, char** argv) {
  try {
    if (argc < 4 || argc > 6) {
      std::cerr
          << "usage: " << argv[0]
          << " KERNEL.hsaco CAPTURE_DIR PRECOMPUTED_DIR [iterations]"
             " [output_prefix]\n";
      return 2;
    }
    const std::string hsaco = argv[1];
    const std::string capture = argv[2];
    const std::string precomputed = argv[3];
    const int iterations = argc >= 5 ? std::stoi(argv[4]) : 1000;
    const std::string output_prefix = argc >= 6 ? argv[5] : "";
    if (iterations <= 0)
      throw std::runtime_error("iterations must be positive");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    constexpr size_t qk_bytes = 16 * 16 * 128 * sizeof(float);
    constexpr size_t gate_bytes = 16 * 32 * sizeof(float);
    constexpr size_t v_bytes = 16 * 32 * 128 * sizeof(uint16_t);
    constexpr size_t state_bytes = 32 * 128 * 128 * sizeof(uint16_t);
    constexpr size_t intermediate_bytes = 16 * state_bytes;
    constexpr size_t output_bytes = v_bytes;
    constexpr uint32_t stride_v = 8192;

    auto q_normalized =
        read_binary(precomputed + "/q_normalized_f32.bin", qk_bytes);
    auto k_normalized =
        read_binary(precomputed + "/k_normalized_f32.bin", qk_bytes);
    auto decay = read_binary(precomputed + "/decay_f32.bin", gate_bytes);
    auto beta = read_binary(precomputed + "/beta_f32.bin", gate_bytes);
    auto v = read_binary(capture + "/v_bf16.bin", v_bytes);
    auto v_storage =
        pad_token_stride(v, 16, 32 * 128, stride_v, sizeof(uint16_t));
    auto initial =
        read_binary(capture + "/initial_ssm_bf16.bin", state_bytes);
    auto initial_index_bytes =
        read_binary(capture + "/cache_indices_i32.bin", sizeof(int32_t));
    auto intermediate_index_bytes = read_binary(
        capture + "/intermediate_state_indices_i32.bin", sizeof(int32_t));
    int32_t initial_index = 0;
    int32_t intermediate_index = 0;
    std::memcpy(&initial_index, initial_index_bytes.data(),
                sizeof(initial_index));
    std::memcpy(&intermediate_index, intermediate_index_bytes.data(),
                sizeof(intermediate_index));
    if (initial_index < 0 || intermediate_index < 0)
      throw std::runtime_error("captured pool indices must be nonnegative");
    const size_t initial_pool_bytes =
        (static_cast<size_t>(initial_index) + 1) * state_bytes;
    const size_t intermediate_pool_bytes =
        (static_cast<size_t>(intermediate_index) + 1) * intermediate_bytes;
    auto expected_output =
        read_binary(capture + "/expected_output_bf16.bin", output_bytes);
    auto expected_final =
        read_binary(capture + "/expected_final_ssm_bf16.bin", state_bytes);

    DeviceBuffer d_q(qk_bytes);
    DeviceBuffer d_k(qk_bytes);
    DeviceBuffer d_v(v_storage.size());
    DeviceBuffer d_decay(gate_bytes);
    DeviceBuffer d_beta(gate_bytes);
    DeviceBuffer d_output(output_bytes);
    DeviceBuffer d_initial(initial_pool_bytes);
    DeviceBuffer d_intermediate(intermediate_pool_bytes);
    DeviceBuffer d_initial_index(sizeof(int32_t));
    DeviceBuffer d_intermediate_index(sizeof(int32_t));
    HIP_CHECK(hipMemcpy(d_q.pointer, q_normalized.data(), qk_bytes,
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_k.pointer, k_normalized.data(), qk_bytes,
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_v.pointer, v_storage.data(), v_storage.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_decay.pointer, decay.data(), gate_bytes,
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_beta.pointer, beta.data(), gate_bytes,
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemset(d_initial.pointer, 0, initial_pool_bytes));
    HIP_CHECK(hipMemcpy(
        static_cast<uint8_t*>(d_initial.pointer) +
            static_cast<size_t>(initial_index) * state_bytes,
        initial.data(), state_bytes, hipMemcpyHostToDevice));
    HIP_CHECK(hipMemset(d_intermediate.pointer, 0, intermediate_pool_bytes));
    HIP_CHECK(hipMemcpy(d_initial_index.pointer, initial_index_bytes.data(),
                        sizeof(int32_t), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_intermediate_index.pointer,
                        intermediate_index_bytes.data(), sizeof(int32_t),
                        hipMemcpyHostToDevice));

    hipModule_t module{};
    hipFunction_t function{};
    HIP_CHECK(hipModuleLoad(&module, hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module,
        "qwen36_gdn_verify_m16_precomputed_bv16_gfx950"));
    void* kernel_args[] = {
        &d_q.pointer,
        &d_k.pointer,
        &d_v.pointer,
        &d_decay.pointer,
        &d_beta.pointer,
        &d_output.pointer,
        &d_initial.pointer,
        &d_intermediate.pointer,
        &d_initial_index.pointer,
        &d_intermediate_index.pointer,
        const_cast<uint32_t*>(&stride_v),
    };
    auto launch = [&](hipStream_t stream = nullptr) {
      HIP_CHECK(hipModuleLaunchKernel(function, 256, 1, 1, 64, 1, 1, 0,
                                      stream, kernel_args, nullptr));
    };

    for (int i = 0; i < 20; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    std::vector<uint8_t> output(output_bytes);
    std::vector<uint8_t> final_state(state_bytes);
    std::vector<uint8_t> first_output;
    std::vector<uint8_t> first_final;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < 20; ++i) {
      launch();
      HIP_CHECK(hipDeviceSynchronize());
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer, output_bytes,
                          hipMemcpyDeviceToHost));
      auto* final_pointer =
          static_cast<uint8_t*>(d_intermediate.pointer) +
          static_cast<size_t>(intermediate_index) * intermediate_bytes +
          15 * state_bytes;
      HIP_CHECK(hipMemcpy(final_state.data(), final_pointer, state_bytes,
                          hipMemcpyDeviceToHost));
      if (i == 0) {
        first_output = output;
        first_final = final_state;
      } else if (output != first_output || final_state != first_final) {
        ++nondeterministic_iterations;
      }
    }

    const Comparison output_comparison =
        compare_bf16(output, expected_output);
    const Comparison final_comparison =
        compare_bf16(final_state, expected_final);
    std::cout << "architecture=" << architecture << "\n"
              << "grid_workgroups=256\n"
              << "workgroup_size=64\n"
              << "correctness_iterations=20\n"
              << "nondeterministic_iterations="
              << nondeterministic_iterations << "\n";
    print_comparison("output", output_comparison);
    print_comparison("final_state", final_comparison);
    if (nondeterministic_iterations != 0 ||
        !output_comparison.preregistered_pass ||
        !final_comparison.preregistered_pass) {
      std::cout << "measurement_status=correctness_failed_before_timing\n";
      if (!output_prefix.empty()) {
        write_binary(output_prefix + ".output.bin", output);
        write_binary(output_prefix + ".final-state.bin", final_state);
        std::vector<uint8_t> all_intermediate(intermediate_bytes);
        HIP_CHECK(hipMemcpy(
            all_intermediate.data(),
            static_cast<uint8_t*>(d_intermediate.pointer) +
                static_cast<size_t>(intermediate_index) * intermediate_bytes,
            intermediate_bytes, hipMemcpyDeviceToHost));
        write_binary(output_prefix + ".intermediate.bin", all_intermediate);
      }
      HIP_CHECK(hipModuleUnload(module));
      return 1;
    }

    std::vector<hipEvent_t> starts(iterations);
    std::vector<hipEvent_t> stops(iterations);
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventCreate(&starts[i]));
      HIP_CHECK(hipEventCreate(&stops[i]));
      HIP_CHECK(hipEventRecord(starts[i]));
      launch();
      HIP_CHECK(hipEventRecord(stops[i]));
    }
    HIP_CHECK(hipEventSynchronize(stops.back()));
    std::vector<float> timings(iterations);
    for (int i = 0; i < iterations; ++i) {
      float milliseconds = 0.0f;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, starts[i], stops[i]));
      timings[i] = milliseconds * 1000.0f;
      HIP_CHECK(hipEventDestroy(starts[i]));
      HIP_CHECK(hipEventDestroy(stops[i]));
    }

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
    std::vector<uint8_t> graph_output(output_bytes);
    HIP_CHECK(hipMemcpy(graph_output.data(), d_output.pointer, output_bytes,
                        hipMemcpyDeviceToHost));
    const bool graph_exact = graph_output == first_output;

    std::sort(timings.begin(), timings.end());
    const size_t p90_index =
        std::min(timings.size() - 1,
                 static_cast<size_t>(std::ceil(0.9 * timings.size()) - 1));
    const double mean =
        std::accumulate(timings.begin(), timings.end(), 0.0) /
        timings.size();
    std::cout << "measurement_status=measured\n"
              << "timing=HIP events continuously queued\n"
              << "iterations=" << iterations << "\n"
              << "minimum_us=" << timings.front() << "\n"
              << "median_us=" << timings[timings.size() / 2] << "\n"
              << "mean_us=" << mean << "\n"
              << "p90_us=" << timings[p90_index] << "\n"
              << "maximum_us=" << timings.back() << "\n"
              << "graph_replays=20\n"
              << "graph_output_exact="
              << (graph_exact ? "true" : "false") << "\n";
    if (!output_prefix.empty()) {
      write_binary(output_prefix + ".output.bin", output);
      write_binary(output_prefix + ".final-state.bin", final_state);
    }

    HIP_CHECK(hipGraphExecDestroy(graph_exec));
    HIP_CHECK(hipGraphDestroy(graph));
    HIP_CHECK(hipStreamDestroy(stream));
    HIP_CHECK(hipModuleUnload(module));
    return graph_exact ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
