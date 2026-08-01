// SPDX-License-Identifier: MIT
// Real-checkpoint correctness and HIP-event timing for raw M64 W2 + reducer.

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
      throw std::runtime_error(std::string(#expr) + ": " +                    \
                               hipGetErrorString(status));                      \
  } while (0)

static std::vector<uint8_t> read_file(const std::string& path) {
  std::ifstream stream(path, std::ios::binary | std::ios::ate);
  if (!stream) throw std::runtime_error("cannot open " + path);
  const auto size = stream.tellg();
  stream.seekg(0);
  std::vector<uint8_t> value(static_cast<size_t>(size));
  stream.read(reinterpret_cast<char*>(value.data()), size);
  if (!stream) throw std::runtime_error("cannot read " + path);
  return value;
}

static float bf16_to_float(uint16_t value) {
  uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

static uint16_t float_to_bf16(float value) {
  uint32_t bits = 0;
  std::memcpy(&bits, &value, sizeof(bits));
  bits += 0x7fffu + ((bits >> 16) & 1u);
  return static_cast<uint16_t>(bits >> 16);
}

struct Buffer {
  void* ptr = nullptr;
  explicit Buffer(size_t bytes) { HIP_CHECK(hipMalloc(&ptr, bytes)); }
  ~Buffer() { if (ptr) static_cast<void>(hipFree(ptr)); }
};

static void upload(Buffer& output, const std::vector<uint8_t>& input) {
  HIP_CHECK(hipMemcpy(output.ptr, input.data(), input.size(), hipMemcpyHostToDevice));
}

static double percentile(std::vector<float> values, double q) {
  std::sort(values.begin(), values.end());
  const double index = q * (values.size() - 1);
  const size_t lo = static_cast<size_t>(index);
  const size_t hi = std::min(lo + 1, values.size() - 1);
  return values[lo] + (values[hi] - values[lo]) * (index - lo);
}

struct Comparison {
  size_t mismatches = 0;
  float max_abs = 0.0f;
  double mean_abs = 0.0;
  double cosine = 0.0;
};

static Comparison compare(
    const std::vector<uint16_t>& actual,
    const std::vector<uint16_t>& expected_bf16,
    const std::vector<float>& expected_f32) {
  Comparison result;
  double dot = 0.0, anorm = 0.0, enorm = 0.0;
  for (size_t i = 0; i < actual.size(); ++i) {
    result.mismatches += actual[i] != expected_bf16[i];
    const float a = bf16_to_float(actual[i]);
    const float e = expected_f32[i];
    const float error = std::abs(a - e);
    result.max_abs = std::max(result.max_abs, error);
    result.mean_abs += error;
    dot += static_cast<double>(a) * e;
    anorm += static_cast<double>(a) * a;
    enorm += static_cast<double>(e) * e;
  }
  result.mean_abs /= actual.size();
  result.cosine = dot / std::sqrt(anorm * enorm);
  return result;
}

int main(int argc, char** argv) {
  try {
    if (argc < 6 || argc > 7) {
      std::cerr << "usage: " << argv[0]
                << " DOWN.hsaco REDUCE.hsaco FULL_EXPORT_DIR M64_SORT_DIR ACTIVATION_DIR"
                   " [iterations=50]\n";
      return 2;
    }
    const std::string co_path = argv[1], reduce_co_path = argv[2];
    const std::string base = argv[3], sort = argv[4];
    const std::string activation_dir = argv[5];
    const int iterations = argc == 7 ? std::stoi(argv[6]) : 50;
    constexpr int rows = 1024, hidden = 2048, topk = 9;
    const size_t output_elements = static_cast<size_t>(rows) * hidden;

    hipDeviceProp_t props{};
    HIP_CHECK(hipGetDeviceProperties(&props, 0));
    if (std::string(props.gcnArchName).rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device");

    const auto activation = read_file(activation_dir + "/activation_fp8.bin");
    const auto activation_scale =
        read_file(activation_dir + "/activation_scale_f32.bin");
    const auto w2 = read_file(base + "/active_w2_fp8.bin");
    const auto w2_scale = read_file(base + "/active_w2_scale_f32.bin");
    const auto sorted = read_file(sort + "/sorted_token_ids_m64_i32.bin");
    const auto sorted_weights = read_file(sort + "/sorted_weights_m64_f32.bin");
    const auto experts =
        read_file(sort + "/compact_sorted_expert_ids_m64_i32.bin");
    const auto valid_bytes = read_file(sort + "/num_valid_ids_m64_i32.bin");
    const auto reference_f32_bytes = read_file(base + "/reference_output_f32.bin");
    const auto reference_bf16_bytes = read_file(base + "/reference_output_bf16.bin");
    const auto aiter_bf16_bytes = read_file(base + "/aiter_output_bf16.bin");
    const auto topk_weights = read_file(base + "/topk_weights_f32.bin");
    int32_t valid = 0;
    std::memcpy(&valid, valid_bytes.data(), sizeof(valid));
    if (valid <= 0 || valid % 64) throw std::runtime_error("invalid M64 span");
    if (activation.size() != static_cast<size_t>(rows) * topk * 512 ||
        activation_scale.size() != static_cast<size_t>(rows) * topk * 4 * 4 ||
        reference_f32_bytes.size() != output_elements * 4 ||
        reference_bf16_bytes.size() != output_elements * 2 ||
        aiter_bf16_bytes.size() != output_elements * 2)
      throw std::runtime_error("capture size mismatch");

    Buffer d_activation(activation.size()), d_activation_scale(activation_scale.size());
    Buffer d_w2(w2.size()), d_w2_scale(w2_scale.size());
    Buffer d_sorted(sorted.size()), d_sorted_weights(sorted_weights.size());
    Buffer d_experts(experts.size()), d_valid(valid_bytes.size());
    Buffer d_partials(
        (static_cast<size_t>(rows) * topk + valid) * hidden * sizeof(float));
    Buffer d_topk_weights(topk_weights.size());
    Buffer d_output(output_elements * sizeof(uint16_t));
    upload(d_activation, activation); upload(d_activation_scale, activation_scale);
    upload(d_w2, w2); upload(d_w2_scale, w2_scale); upload(d_sorted, sorted);
    upload(d_sorted_weights, sorted_weights); upload(d_experts, experts);
    upload(d_valid, valid_bytes);
    upload(d_topk_weights, topk_weights);

    hipModule_t module = nullptr, reduce_module = nullptr;
    hipFunction_t function = nullptr, reduce_function = nullptr;
    HIP_CHECK(hipModuleLoad(&module, co_path.c_str()));
    HIP_CHECK(hipModuleLoad(&reduce_module, reduce_co_path.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module, "qwen36_moe_down_m64n64_partial_fp8_gfx950"));
    HIP_CHECK(hipModuleGetFunction(
        &reduce_function, reduce_module, "qwen36_moe_route_reduce_f32_gfx950"));
    int token_rows = rows;
    void* args[] = {
        &d_activation.ptr, &d_activation_scale.ptr, &d_w2.ptr, &d_w2_scale.ptr,
        &d_sorted.ptr, &d_sorted_weights.ptr, &d_experts.ptr, &d_valid.ptr,
        &d_partials.ptr, &token_rows};
    void* reduce_args[] = {
        &d_partials.ptr, &d_topk_weights.ptr, &d_output.ptr};
    auto launch = [&] {
      HIP_CHECK(hipModuleLaunchKernel(
          function, 32, valid / 64, 1, 256, 1, 1, 0, nullptr, args, nullptr));
      HIP_CHECK(hipModuleLaunchKernel(
          reduce_function, 32, rows, 1, 64, 1, 1, 0, nullptr,
          reduce_args, nullptr));
    };
    for (int i = 0; i < 5; ++i) {
      HIP_CHECK(hipMemset(d_output.ptr, 0, output_elements * sizeof(uint16_t)));
      launch();
    }
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start = nullptr, stop = nullptr;
    HIP_CHECK(hipEventCreate(&start)); HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> samples;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipMemset(d_output.ptr, 0, output_elements * sizeof(uint16_t)));
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      samples.push_back(milliseconds * 1000.0f);
    }

    std::vector<uint16_t> output_bf16(output_elements);
    HIP_CHECK(hipMemcpy(
        output_bf16.data(), d_output.ptr,
        output_bf16.size() * sizeof(uint16_t),
        hipMemcpyDeviceToHost));
    bool finite = true;
    for (uint16_t value : output_bf16)
      finite = finite && std::isfinite(bf16_to_float(value));
    std::vector<float> reference_f32(output_elements);
    std::vector<uint16_t> reference_bf16(output_elements), aiter_bf16(output_elements);
    std::memcpy(reference_f32.data(), reference_f32_bytes.data(), reference_f32_bytes.size());
    std::memcpy(reference_bf16.data(), reference_bf16_bytes.data(), reference_bf16_bytes.size());
    std::memcpy(aiter_bf16.data(), aiter_bf16_bytes.data(), aiter_bf16_bytes.size());
    const Comparison structural = compare(output_bf16, reference_bf16, reference_f32);
    std::vector<float> aiter_f32(output_elements);
    for (size_t i = 0; i < output_elements; ++i)
      aiter_f32[i] = bf16_to_float(aiter_bf16[i]);
    const Comparison aiter = compare(output_bf16, aiter_bf16, aiter_f32);
    // The retained raw M16 report printed six significant decimal digits.
    // These bounds conservatively include that report's final printed ULP.
    const bool correct = finite && structural.max_abs <= 0.000849762f &&
                         structural.cosine >= 0.9999725 &&
                         aiter.max_abs <= 0.000976563f &&
                         aiter.cosine >= 0.9999645;

    std::cout << "architecture=" << props.gcnArchName << "\n"
              << "valid_sorted_ids=" << valid << "\n"
              << "grid=32x" << valid / 64 << "\n"
              << "structural_bf16_mismatches=" << structural.mismatches << "/"
              << output_elements << "\n"
              << "structural_max_abs=" << structural.max_abs << "\n"
              << "structural_mean_abs=" << structural.mean_abs << "\n"
              << "structural_cosine=" << structural.cosine << "\n"
              << "aiter_bf16_mismatches=" << aiter.mismatches << "/"
              << output_elements << "\n"
              << "aiter_max_abs=" << aiter.max_abs << "\n"
              << "aiter_mean_abs=" << aiter.mean_abs << "\n"
              << "aiter_cosine=" << aiter.cosine << "\n"
              << "finite=" << finite << "\n"
              << "correctness_gate=" << (correct ? "pass" : "fail") << "\n"
              << "reference_gate=validated_raw_m16_complete_output\n"
              << "median_us=" << percentile(samples, 0.5) << "\n"
              << "p90_us=" << percentile(samples, 0.9) << "\n"
              << "min_us=" << *std::min_element(samples.begin(), samples.end()) << "\n"
              << "max_us=" << *std::max_element(samples.begin(), samples.end()) << "\n";
    HIP_CHECK(hipEventDestroy(start)); HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(module));
    HIP_CHECK(hipModuleUnload(reduce_module));
    return correct ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << "\n";
    return 2;
  }
}
