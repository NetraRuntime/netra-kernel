// SPDX-License-Identifier: MIT
// Exact-capture benchmark for the token-major raw gfx950 MoE down+reduce path.

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
      throw std::runtime_error(std::string(#expr) + ": " +                    \
                               hipGetErrorString(status));                      \
  } while (0)

static std::vector<uint8_t> read_file(const std::string& path) {
  std::ifstream stream(path, std::ios::binary | std::ios::ate);
  if (!stream) throw std::runtime_error("cannot open " + path);
  const auto size = stream.tellg();
  stream.seekg(0);
  std::vector<uint8_t> result(static_cast<size_t>(size));
  stream.read(reinterpret_cast<char*>(result.data()), size);
  if (!stream) throw std::runtime_error("cannot read " + path);
  return result;
}

static float bf16_to_float(uint16_t value) {
  uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

struct Buffer {
  void* ptr = nullptr;
  explicit Buffer(size_t bytes) { HIP_CHECK(hipMalloc(&ptr, bytes)); }
  ~Buffer() {
    if (ptr) static_cast<void>(hipFree(ptr));
  }
};

static void upload(Buffer& destination, const std::vector<uint8_t>& source) {
  HIP_CHECK(hipMemcpy(destination.ptr, source.data(), source.size(),
                      hipMemcpyHostToDevice));
}

static double percentile(std::vector<float> values, double quantile) {
  std::sort(values.begin(), values.end());
  const double index = quantile * (values.size() - 1);
  const size_t low = static_cast<size_t>(index);
  const size_t high = std::min(low + 1, values.size() - 1);
  return values[low] + (values[high] - values[low]) * (index - low);
}

int main(int argc, char** argv) {
  try {
    if (argc != 4) {
      std::cerr << "usage: " << argv[0]
                << " DOWN.hsaco FULL_EXPORT_DIR iterations\n";
      return 2;
    }
    const std::string code_object = argv[1];
    const std::string capture = argv[2];
    const int iterations = std::stoi(argv[3]);
    if (iterations < 2) throw std::runtime_error("iterations must be >= 2");

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device");

    constexpr int kTopk = 9;
    constexpr int kInter = 512;
    constexpr int kHidden = 2048;
    auto activation = read_file(capture + "/activation_fp8.bin");
    auto activation_scale = read_file(capture + "/activation_scale_f32.bin");
    auto weights = read_file(capture + "/active_w2_fp8.bin");
    auto weight_scale = read_file(capture + "/active_w2_scale_f32.bin");
    auto topk_weights = read_file(capture + "/topk_weights_f32.bin");
    auto sorted = read_file(capture + "/sorted_token_ids_m64_i32.bin");
    auto experts =
        read_file(capture + "/compact_sorted_expert_ids_m64_i32.bin");
    auto valid_bytes = read_file(capture + "/num_valid_ids_m64_i32.bin");
    auto reference_f32 = read_file(capture + "/reference_output_f32.bin");
    auto aiter_bf16 = read_file(capture + "/aiter_output_bf16.bin");

    if (activation.empty() || activation.size() % (kTopk * kInter) != 0)
      throw std::runtime_error("activation shape mismatch");
    const int rows = static_cast<int>(activation.size() / (kTopk * kInter));
    const size_t routes = static_cast<size_t>(rows) * kTopk;
    if (activation_scale.size() != routes * 4 * sizeof(float) ||
        topk_weights.size() != routes * sizeof(float) ||
        reference_f32.size() != static_cast<size_t>(rows) * kHidden * sizeof(float) ||
        aiter_bf16.size() != static_cast<size_t>(rows) * kHidden * sizeof(uint16_t) ||
        valid_bytes.size() < sizeof(int32_t))
      throw std::runtime_error("capture tensor size mismatch");

    int32_t valid = 0;
    std::memcpy(&valid, valid_bytes.data(), sizeof(valid));
    if (valid <= 0 || valid % 64 != 0 ||
        sorted.size() < static_cast<size_t>(valid) * sizeof(int32_t) ||
        experts.size() < static_cast<size_t>(valid / 64) * sizeof(int32_t))
      throw std::runtime_error("M64 sort metadata mismatch");

    const auto* sorted_ids = reinterpret_cast<const int32_t*>(sorted.data());
    const auto* block_experts = reinterpret_cast<const int32_t*>(experts.data());
    std::vector<int32_t> topk_ids(routes, -1);
    size_t duplicate_routes = 0;
    for (int index = 0; index < valid; ++index) {
      const uint32_t packed = static_cast<uint32_t>(sorted_ids[index]);
      const uint32_t slot = packed >> 24;
      const uint32_t row = packed & 0x00ffffffu;
      if (slot >= kTopk || row >= static_cast<uint32_t>(rows)) continue;
      const size_t route = static_cast<size_t>(row) * kTopk + slot;
      duplicate_routes += topk_ids[route] != -1;
      topk_ids[route] = block_experts[index / 64];
    }
    const size_t missing_routes = static_cast<size_t>(std::count(
        topk_ids.begin(), topk_ids.end(), -1));
    if (duplicate_routes != 0 || missing_routes != 0)
      throw std::runtime_error("could not reconstruct compact top-k IDs");

    std::vector<uint8_t> topk_id_bytes(topk_ids.size() * sizeof(int32_t));
    std::memcpy(topk_id_bytes.data(), topk_ids.data(), topk_id_bytes.size());
    Buffer d_activation(activation.size());
    Buffer d_activation_scale(activation_scale.size());
    Buffer d_weights(weights.size());
    Buffer d_weight_scale(weight_scale.size());
    Buffer d_topk_weights(topk_weights.size());
    Buffer d_topk_ids(topk_id_bytes.size());
    Buffer d_output(static_cast<size_t>(rows) * kHidden * sizeof(uint16_t));
    upload(d_activation, activation);
    upload(d_activation_scale, activation_scale);
    upload(d_weights, weights);
    upload(d_weight_scale, weight_scale);
    upload(d_topk_weights, topk_weights);
    upload(d_topk_ids, topk_id_bytes);

    hipModule_t module = nullptr;
    hipFunction_t function = nullptr;
    HIP_CHECK(hipModuleLoad(&module, code_object.c_str()));
    HIP_CHECK(hipModuleGetFunction(
        &function, module,
        "qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950"));
    void* output = d_output.ptr;
    void* arguments[] = {
        &d_activation.ptr, &d_activation_scale.ptr, &d_weights.ptr,
        &d_weight_scale.ptr, &d_topk_weights.ptr, &d_topk_ids.ptr, &output};
    auto launch = [&] {
      HIP_CHECK(hipModuleLaunchKernel(function, 128, rows, 1, 128, 1, 1,
                                      0, nullptr, arguments, nullptr));
    };
    for (int index = 0; index < 5; ++index) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start = nullptr, stop = nullptr;
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> samples;
    samples.reserve(iterations);
    for (int index = 0; index < iterations; ++index) {
      HIP_CHECK(hipEventRecord(start));
      launch();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0.0f;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      samples.push_back(milliseconds * 1000.0f);
    }

    std::vector<uint16_t> actual(static_cast<size_t>(rows) * kHidden);
    HIP_CHECK(hipMemcpy(actual.data(), d_output.ptr,
                        actual.size() * sizeof(uint16_t),
                        hipMemcpyDeviceToHost));
    const auto* expected = reinterpret_cast<const float*>(reference_f32.data());
    const auto* aiter = reinterpret_cast<const uint16_t*>(aiter_bf16.data());
    double dot = 0.0, actual_norm = 0.0, expected_norm = 0.0;
    double absolute_sum = 0.0;
    float max_abs = 0.0f;
    size_t aiter_mismatches = 0;
    bool finite = true;
    for (size_t index = 0; index < actual.size(); ++index) {
      const float value = bf16_to_float(actual[index]);
      const float reference = expected[index];
      const float error = std::abs(value - reference);
      finite = finite && std::isfinite(value);
      max_abs = std::max(max_abs, error);
      absolute_sum += error;
      dot += static_cast<double>(value) * reference;
      actual_norm += static_cast<double>(value) * value;
      expected_norm += static_cast<double>(reference) * reference;
      aiter_mismatches += actual[index] != aiter[index];
    }
    const double cosine = dot / std::sqrt(actual_norm * expected_norm);
    const double mean = std::accumulate(samples.begin(), samples.end(), 0.0) /
                        samples.size();
    std::cout << "architecture=" << properties.gcnArchName << "\n"
              << "rows=" << rows << "\n"
              << "valid_sorted_ids=" << valid << "\n"
              << "reconstructed_routes=" << routes << "\n"
              << "duplicate_routes=" << duplicate_routes << "\n"
              << "missing_routes=" << missing_routes << "\n"
              << "finite=" << finite << "\n"
              << "max_abs=" << max_abs << "\n"
              << "mean_abs=" << absolute_sum / actual.size() << "\n"
              << "cosine=" << cosine << "\n"
              << "aiter_bf16_mismatches=" << aiter_mismatches << "/"
              << actual.size() << "\n"
              << "mean_us=" << mean << "\n"
              << "median_us=" << percentile(samples, 0.5) << "\n"
              << "p90_us=" << percentile(samples, 0.9) << "\n";

    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(module));
    return finite && max_abs <= 0.001f && cosine >= 0.9999 ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << "\n";
    return 2;
  }
}
