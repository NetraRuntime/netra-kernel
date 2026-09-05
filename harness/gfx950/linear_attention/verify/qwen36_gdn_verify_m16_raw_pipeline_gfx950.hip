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

constexpr float kBf16Atol = 0.03125f;
constexpr float kBf16Rtol = 0.010f;
constexpr double kBf16MinimumCosine = 0.9995;

// Pre-registered before the first raw-precompute result was inspected.
constexpr float kQkAtol = 2.0e-6f;
constexpr float kQkRtol = 5.0e-5f;
constexpr double kQkMinimumCosine = 0.9999999;
constexpr float kGateAtol = 2.0e-5f;
constexpr float kGateRtol = 5.0e-4f;
constexpr float kGateRelativeFloor = 1.0e-6f;
constexpr double kGateMinimumCosine = 0.999999;

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

static void write_binary(const std::string& path,
                         const std::vector<uint8_t>& data) {
  std::ofstream output(path, std::ios::binary);
  if (!output) throw std::runtime_error("cannot open output " + path);
  output.write(reinterpret_cast<const char*>(data.data()),
               static_cast<std::streamsize>(data.size()));
  if (!output) throw std::runtime_error("cannot write " + path);
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

template <typename ReadValue>
static Comparison compare_values(const std::vector<uint8_t>& actual,
                                 const std::vector<uint8_t>& expected,
                                 size_t element_bytes, float atol, float rtol,
                                 float relative_floor, double minimum_cosine,
                                 ReadValue read_value) {
  if (actual.size() != expected.size() ||
      actual.size() % element_bytes != 0)
    throw std::runtime_error("comparison size mismatch");
  Comparison result;
  result.elements = actual.size() / element_bytes;
  result.bit_exact = actual == expected;
  double absolute_sum = 0.0;
  double squared_sum = 0.0;
  double dot = 0.0;
  double actual_squared = 0.0;
  double expected_squared = 0.0;
  for (size_t i = 0; i < result.elements; ++i) {
    const float a = read_value(actual.data() + i * element_bytes);
    const float e = read_value(expected.data() + i * element_bytes);
    result.actual_nonfinite += !std::isfinite(a);
    result.expected_nonfinite += !std::isfinite(e);
    result.mismatches +=
        std::memcmp(actual.data() + i * element_bytes,
                    expected.data() + i * element_bytes, element_bytes) != 0;
    const double delta = std::abs(static_cast<double>(a) - e);
    if (delta > result.max_abs) {
      result.max_abs = delta;
      result.worst_index = i;
    }
    if (!(std::abs(a) < relative_floor && std::abs(e) < relative_floor)) {
      result.max_relative = std::max(
          result.max_relative,
          delta / std::max(std::abs(static_cast<double>(e)), 1e-20));
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
      result.max_abs <= atol && result.max_relative <= rtol &&
      result.cosine >= minimum_cosine;
  return result;
}

static Comparison compare_bf16(const std::vector<uint8_t>& actual,
                               const std::vector<uint8_t>& expected) {
  return compare_values(actual, expected, 2, kBf16Atol, kBf16Rtol,
                        kBf16Atol, kBf16MinimumCosine, bf16_to_float);
}

static float read_float(const uint8_t* bytes) {
  float value = 0.0f;
  std::memcpy(&value, bytes, sizeof(value));
  return value;
}

static Comparison compare_qk(const std::vector<uint8_t>& actual,
                             const std::vector<uint8_t>& expected) {
  return compare_values(actual, expected, 4, kQkAtol, kQkRtol, kQkAtol,
                        kQkMinimumCosine, read_float);
}

static Comparison compare_gate(const std::vector<uint8_t>& actual,
                               const std::vector<uint8_t>& expected) {
  return compare_values(actual, expected, 4, kGateAtol, kGateRtol,
                        kGateRelativeFloor, kGateMinimumCosine, read_float);
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

struct Distribution {
  float minimum = 0.0f;
  float median = 0.0f;
  double mean = 0.0;
  float p90 = 0.0f;
  float maximum = 0.0f;
};

template <typename Launch>
static Distribution measure(int iterations, Launch launch) {
  std::vector<hipEvent_t> starts(iterations);
  std::vector<hipEvent_t> stops(iterations);
  for (int i = 0; i < iterations; ++i) {
    HIP_CHECK(hipEventCreate(&starts[i]));
    HIP_CHECK(hipEventCreate(&stops[i]));
    HIP_CHECK(hipEventRecord(starts[i]));
    launch(nullptr);
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
  std::sort(timings.begin(), timings.end());
  const size_t p90_index =
      std::min(timings.size() - 1,
               static_cast<size_t>(std::ceil(0.9 * timings.size()) - 1));
  return {
      timings.front(),
      timings[timings.size() / 2],
      std::accumulate(timings.begin(), timings.end(), 0.0) / timings.size(),
      timings[p90_index],
      timings.back(),
  };
}

static void print_distribution(const std::string& name,
                               const Distribution& distribution) {
  std::cout << name << "_minimum_us=" << distribution.minimum << "\n"
            << name << "_median_us=" << distribution.median << "\n"
            << name << "_mean_us=" << distribution.mean << "\n"
            << name << "_p90_us=" << distribution.p90 << "\n"
            << name << "_maximum_us=" << distribution.maximum << "\n";
}

int main(int argc, char** argv) {
  try {
    if (argc < 5 || argc > 7) {
      std::cerr
          << "usage: " << argv[0]
          << " PRECOMPUTE.hsaco CORE.hsaco CAPTURE_DIR PRECOMPUTED_DIR"
             " [iterations] [output_prefix]\n";
      return 2;
    }
    const std::string precompute_hsaco = argv[1];
    const std::string core_hsaco = argv[2];
    const std::string capture = argv[3];
    const std::string precomputed = argv[4];
    const int iterations = argc >= 6 ? std::stoi(argv[5]) : 1000;
    const std::string output_prefix = argc >= 7 ? argv[6] : "";
    if (iterations <= 0)
      throw std::runtime_error("iterations must be positive");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    const std::string architecture = properties.gcnArchName;
    if (architecture.rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device: " + architecture);

    constexpr size_t A_log_bytes = 32 * sizeof(float);
    constexpr size_t gate_input_bytes = 16 * 32 * sizeof(uint16_t);
    constexpr size_t dt_bias_bytes = 32 * sizeof(uint16_t);
    constexpr size_t qk_bf16_bytes = 16 * 16 * 128 * sizeof(uint16_t);
    constexpr size_t qk_f32_bytes = 16 * 16 * 128 * sizeof(float);
    constexpr size_t gate_f32_bytes = 16 * 32 * sizeof(float);
    constexpr size_t v_bytes = 16 * 32 * 128 * sizeof(uint16_t);
    constexpr size_t state_bytes = 32 * 128 * 128 * sizeof(uint16_t);
    constexpr size_t intermediate_bytes = 16 * state_bytes;
    constexpr size_t output_bytes = v_bytes;
    constexpr uint32_t stride_q = 8192;
    constexpr uint32_t stride_k = 8192;
    constexpr uint32_t stride_a = 64;
    constexpr uint32_t stride_b = 64;
    constexpr uint32_t stride_v = 8192;

    auto A_log = read_binary(capture + "/A_log_f32.bin", A_log_bytes);
    auto a = read_binary(capture + "/a_bf16.bin", gate_input_bytes);
    auto dt_bias =
        read_binary(capture + "/dt_bias_bf16.bin", dt_bias_bytes);
    auto q = read_binary(capture + "/q_bf16.bin", qk_bf16_bytes);
    auto k = read_binary(capture + "/k_bf16.bin", qk_bf16_bytes);
    auto b = read_binary(capture + "/b_bf16.bin", gate_input_bytes);
    auto v = read_binary(capture + "/v_bf16.bin", v_bytes);
    auto q_storage =
        pad_token_stride(q, 16, 16 * 128, stride_q, sizeof(uint16_t));
    auto k_storage =
        pad_token_stride(k, 16, 16 * 128, stride_k, sizeof(uint16_t));
    auto a_storage =
        pad_token_stride(a, 16, 32, stride_a, sizeof(uint16_t));
    auto b_storage =
        pad_token_stride(b, 16, 32, stride_b, sizeof(uint16_t));
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
    auto expected_q =
        read_binary(precomputed + "/q_normalized_f32.bin", qk_f32_bytes);
    auto expected_k =
        read_binary(precomputed + "/k_normalized_f32.bin", qk_f32_bytes);
    auto expected_decay =
        read_binary(precomputed + "/decay_f32.bin", gate_f32_bytes);
    auto expected_beta =
        read_binary(precomputed + "/beta_f32.bin", gate_f32_bytes);
    auto expected_output =
        read_binary(capture + "/expected_output_bf16.bin", output_bytes);
    auto expected_final =
        read_binary(capture + "/expected_final_ssm_bf16.bin", state_bytes);

    DeviceBuffer d_A_log(A_log_bytes);
    DeviceBuffer d_a(a_storage.size());
    DeviceBuffer d_dt_bias(dt_bias_bytes);
    DeviceBuffer d_q(q_storage.size());
    DeviceBuffer d_k(k_storage.size());
    DeviceBuffer d_b(b_storage.size());
    DeviceBuffer d_q_normalized(qk_f32_bytes);
    DeviceBuffer d_k_normalized(qk_f32_bytes);
    DeviceBuffer d_decay(gate_f32_bytes);
    DeviceBuffer d_beta(gate_f32_bytes);
    DeviceBuffer d_v(v_storage.size());
    DeviceBuffer d_output(output_bytes);
    DeviceBuffer d_initial(initial_pool_bytes);
    DeviceBuffer d_intermediate(intermediate_pool_bytes);
    DeviceBuffer d_initial_index(sizeof(int32_t));
    DeviceBuffer d_intermediate_index(sizeof(int32_t));

    HIP_CHECK(hipMemcpy(d_A_log.pointer, A_log.data(), A_log_bytes,
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_a.pointer, a_storage.data(), a_storage.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_dt_bias.pointer, dt_bias.data(), dt_bias_bytes,
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_q.pointer, q_storage.data(), q_storage.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_k.pointer, k_storage.data(), k_storage.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_b.pointer, b_storage.data(), b_storage.size(),
                        hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_v.pointer, v_storage.data(), v_storage.size(),
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

    hipModule_t precompute_module{};
    hipModule_t core_module{};
    hipFunction_t precompute_function{};
    hipFunction_t core_function{};
    HIP_CHECK(hipModuleLoad(&precompute_module, precompute_hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &precompute_function, precompute_module,
        "qwen36_gdn_verify_m16_precompute_gfx950"));
    HIP_CHECK(hipModuleLoad(&core_module, core_hsaco.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &core_function, core_module,
        "qwen36_gdn_verify_m16_precomputed_bv16_gfx950"));

    void* precompute_args[] = {
        &d_A_log.pointer,       &d_a.pointer,
        &d_dt_bias.pointer,     &d_q.pointer,
        &d_k.pointer,           &d_b.pointer,
        &d_q_normalized.pointer, &d_k_normalized.pointer,
        &d_decay.pointer,       &d_beta.pointer,
        const_cast<uint32_t*>(&stride_q),
        const_cast<uint32_t*>(&stride_k),
        const_cast<uint32_t*>(&stride_a),
        const_cast<uint32_t*>(&stride_b),
    };
    void* core_args[] = {
        &d_q_normalized.pointer, &d_k_normalized.pointer, &d_v.pointer,
        &d_decay.pointer,        &d_beta.pointer,          &d_output.pointer,
        &d_initial.pointer,      &d_intermediate.pointer,
        &d_initial_index.pointer, &d_intermediate_index.pointer,
        const_cast<uint32_t*>(&stride_v),
    };
    auto launch_precompute = [&](hipStream_t stream = nullptr) {
      HIP_CHECK(hipModuleLaunchKernel(precompute_function, 256, 1, 1, 64, 1,
                                      1, 0, stream, precompute_args, nullptr));
    };
    auto launch_core = [&](hipStream_t stream = nullptr) {
      HIP_CHECK(hipModuleLaunchKernel(core_function, 256, 1, 1, 64, 1, 1, 0,
                                      stream, core_args, nullptr));
    };
    auto launch_combined = [&](hipStream_t stream = nullptr) {
      launch_precompute(stream);
      launch_core(stream);
    };

    for (int i = 0; i < 20; ++i) launch_combined();
    HIP_CHECK(hipDeviceSynchronize());

    launch_precompute();
    HIP_CHECK(hipDeviceSynchronize());
    std::vector<uint8_t> actual_q(qk_f32_bytes);
    std::vector<uint8_t> actual_k(qk_f32_bytes);
    std::vector<uint8_t> actual_decay(gate_f32_bytes);
    std::vector<uint8_t> actual_beta(gate_f32_bytes);
    HIP_CHECK(hipMemcpy(actual_q.data(), d_q_normalized.pointer, qk_f32_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(actual_k.data(), d_k_normalized.pointer, qk_f32_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(actual_decay.data(), d_decay.pointer, gate_f32_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(actual_beta.data(), d_beta.pointer, gate_f32_bytes,
                        hipMemcpyDeviceToHost));

    const Comparison q_comparison = compare_qk(actual_q, expected_q);
    const Comparison k_comparison = compare_qk(actual_k, expected_k);
    const Comparison decay_comparison =
        compare_gate(actual_decay, expected_decay);
    const Comparison beta_comparison =
        compare_gate(actual_beta, expected_beta);

    std::vector<uint8_t> output(output_bytes);
    std::vector<uint8_t> final_state(state_bytes);
    std::vector<uint8_t> first_output;
    std::vector<uint8_t> first_final;
    size_t nondeterministic_iterations = 0;
    for (int i = 0; i < 20; ++i) {
      launch_combined();
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
              << "precompute_grid_workgroups=256\n"
              << "core_grid_workgroups=256\n"
              << "workgroup_size=64\n"
              << "correctness_iterations=20\n"
              << "nondeterministic_iterations="
              << nondeterministic_iterations << "\n"
              << "qk_tolerance_atol=" << kQkAtol << "\n"
              << "qk_tolerance_rtol=" << kQkRtol << "\n"
              << "gate_tolerance_atol=" << kGateAtol << "\n"
              << "gate_tolerance_rtol=" << kGateRtol << "\n";
    print_comparison("q_normalized", q_comparison);
    print_comparison("k_normalized", k_comparison);
    print_comparison("decay", decay_comparison);
    print_comparison("beta", beta_comparison);
    print_comparison("output", output_comparison);
    print_comparison("final_state", final_comparison);

    const bool correctness_pass =
        nondeterministic_iterations == 0 &&
        q_comparison.preregistered_pass &&
        k_comparison.preregistered_pass &&
        decay_comparison.preregistered_pass &&
        beta_comparison.preregistered_pass &&
        output_comparison.preregistered_pass &&
        final_comparison.preregistered_pass;
    if (!correctness_pass) {
      std::cout << "measurement_status=correctness_failed_before_timing\n";
      if (!output_prefix.empty()) {
        write_binary(output_prefix + ".q-normalized.bin", actual_q);
        write_binary(output_prefix + ".k-normalized.bin", actual_k);
        write_binary(output_prefix + ".decay.bin", actual_decay);
        write_binary(output_prefix + ".beta.bin", actual_beta);
        write_binary(output_prefix + ".output.bin", output);
        write_binary(output_prefix + ".final-state.bin", final_state);
      }
      HIP_CHECK(hipModuleUnload(core_module));
      HIP_CHECK(hipModuleUnload(precompute_module));
      return 1;
    }

    const Distribution precompute_distribution =
        measure(iterations, launch_precompute);
    const Distribution core_distribution = measure(iterations, launch_core);
    const Distribution combined_distribution =
        measure(iterations, launch_combined);

    hipStream_t stream{};
    hipGraph_t graph{};
    hipGraphExec_t graph_exec{};
    HIP_CHECK(hipStreamCreate(&stream));
    HIP_CHECK(hipStreamBeginCapture(stream, hipStreamCaptureModeGlobal));
    launch_combined(stream);
    HIP_CHECK(hipStreamEndCapture(stream, &graph));
    HIP_CHECK(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));
    for (int i = 0; i < 20; ++i)
      HIP_CHECK(hipGraphLaunch(graph_exec, stream));
    HIP_CHECK(hipStreamSynchronize(stream));
    std::vector<uint8_t> graph_output(output_bytes);
    std::vector<uint8_t> graph_final(state_bytes);
    HIP_CHECK(hipMemcpy(graph_output.data(), d_output.pointer, output_bytes,
                        hipMemcpyDeviceToHost));
    auto* graph_final_pointer =
        static_cast<uint8_t*>(d_intermediate.pointer) +
        static_cast<size_t>(intermediate_index) * intermediate_bytes +
        15 * state_bytes;
    HIP_CHECK(hipMemcpy(graph_final.data(), graph_final_pointer, state_bytes,
                        hipMemcpyDeviceToHost));
    const bool graph_output_exact = graph_output == first_output;
    const bool graph_state_exact = graph_final == first_final;

    std::cout << "measurement_status=measured\n"
              << "timing=HIP events continuously queued by phase\n"
              << "iterations=" << iterations << "\n";
    print_distribution("precompute", precompute_distribution);
    print_distribution("core", core_distribution);
    print_distribution("combined", combined_distribution);
    std::cout << "graph_replays=20\n"
              << "graph_output_exact="
              << (graph_output_exact ? "true" : "false") << "\n"
              << "graph_state_exact="
              << (graph_state_exact ? "true" : "false") << "\n";

    if (!output_prefix.empty()) {
      write_binary(output_prefix + ".q-normalized.bin", actual_q);
      write_binary(output_prefix + ".k-normalized.bin", actual_k);
      write_binary(output_prefix + ".decay.bin", actual_decay);
      write_binary(output_prefix + ".beta.bin", actual_beta);
      write_binary(output_prefix + ".output.bin", output);
      write_binary(output_prefix + ".final-state.bin", final_state);
    }

    HIP_CHECK(hipGraphExecDestroy(graph_exec));
    HIP_CHECK(hipGraphDestroy(graph));
    HIP_CHECK(hipStreamDestroy(stream));
    HIP_CHECK(hipModuleUnload(core_module));
    HIP_CHECK(hipModuleUnload(precompute_module));
    return graph_output_exact && graph_state_exact ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
