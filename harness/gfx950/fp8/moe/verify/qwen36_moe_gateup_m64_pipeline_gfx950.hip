// SPDX-License-Identifier: MIT
// Real-checkpoint M64 W13 correctness and HIP-event timing harness.

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <cstdlib>
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
  ~Buffer() { if (ptr) static_cast<void>(hipFree(ptr)); }
};

static void upload(Buffer& dst, const std::vector<uint8_t>& src) {
  HIP_CHECK(hipMemcpy(dst.ptr, src.data(), src.size(), hipMemcpyHostToDevice));
}

static double percentile(std::vector<float> values, double quantile) {
  std::sort(values.begin(), values.end());
  const double index = quantile * (values.size() - 1);
  const size_t lo = static_cast<size_t>(index);
  const size_t hi = std::min(lo + 1, values.size() - 1);
  return values[lo] + (values[hi] - values[lo]) * (index - lo);
}

int main(int argc, char** argv) {
  try {
    if (argc < 4 || argc > 5) {
      std::cerr << "usage: " << argv[0]
                << " KERNEL.hsaco FULL_EXPORT_DIR M64_SORT_DIR [iterations=50]\n";
      return 2;
    }
    const std::string co_path = argv[1];
    const std::string base = argv[2];
    const std::string sort = argv[3];
    const int iterations = argc == 5 ? std::stoi(argv[4]) : 50;
    if (iterations < 2) throw std::runtime_error("iterations must be >= 2");

    hipDeviceProp_t props{};
    HIP_CHECK(hipGetDeviceProperties(&props, 0));
    if (std::string(props.gcnArchName).rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device");

    const auto hidden = read_file(base + "/hidden_fp8.bin");
    const auto hidden_scale = read_file(base + "/hidden_scale_f32.bin");
    const auto w13 = read_file(base + "/active_w13_fp8.bin");
    const auto w13_scale = read_file(base + "/active_w13_scale_f32.bin");
    const auto reference = read_file(base + "/reference_stage1_bf16.bin");
    const auto sorted = read_file(sort + "/sorted_token_ids_m64_i32.bin");
    const auto experts =
        read_file(sort + "/compact_sorted_expert_ids_m64_i32.bin");
    const auto valid_bytes = read_file(sort + "/num_valid_ids_m64_i32.bin");
    int32_t valid = 0;
    std::memcpy(&valid, valid_bytes.data(), sizeof(valid));
    if (valid <= 0 || valid % 64) throw std::runtime_error("invalid M64 span");
    constexpr int rows = 1024, topk = 9, n = 1024;
    const size_t sorted_capacity = sorted.size() / sizeof(int32_t);
    if (reference.size() != static_cast<size_t>(rows) * topk * n * 2)
      throw std::runtime_error("reference shape mismatch");
    if (experts.size() / sizeof(int32_t) < static_cast<size_t>(valid / 64))
      throw std::runtime_error("expert block array too small");

    Buffer d_hidden(hidden.size()), d_hidden_scale(hidden_scale.size());
    Buffer d_w13(w13.size()), d_w13_scale(w13_scale.size());
    Buffer d_sorted(sorted.size()), d_experts(experts.size());
    Buffer d_valid(valid_bytes.size());
    Buffer d_output(sorted_capacity * n * sizeof(uint16_t));
    upload(d_hidden, hidden); upload(d_hidden_scale, hidden_scale);
    upload(d_w13, w13); upload(d_w13_scale, w13_scale);
    upload(d_sorted, sorted); upload(d_experts, experts); upload(d_valid, valid_bytes);
    HIP_CHECK(hipMemset(d_output.ptr, 0, sorted_capacity * n * sizeof(uint16_t)));

    hipModule_t module = nullptr;
    hipFunction_t function = nullptr;
    HIP_CHECK(hipModuleLoad(&module, co_path.c_str()));
    const char* symbol = std::getenv("NETRA_KERNEL_SYMBOL");
    if (!symbol) symbol = "qwen36_moe_gateup_m64n16_fp8_gfx950";
    HIP_CHECK(hipModuleGetFunction(&function, module, symbol));
    int token_rows = rows;
    int debug_stage = 0;
    if (const char* value = std::getenv("NETRA_DEBUG_STAGE"))
      debug_stage = std::stoi(value);
    void* output_pointer = d_output.ptr;
    if (std::getenv("NETRA_OUTPUT_HIDDEN")) output_pointer = d_hidden.ptr;
    void* args[] = {&d_hidden.ptr, &d_hidden_scale.ptr, &d_w13.ptr,
                    &d_w13_scale.ptr, &d_sorted.ptr, &d_experts.ptr,
                    &d_valid.ptr, &output_pointer, &token_rows, &debug_stage};
    unsigned grid_x = 64, grid_y = static_cast<unsigned>(valid / 64);
    if (const char* value = std::getenv("NETRA_GRID_X")) grid_x = std::stoul(value);
    if (const char* value = std::getenv("NETRA_GRID_Y")) grid_y = std::stoul(value);
    if (grid_x < 1 || grid_x > 64 || grid_y < 1 || grid_y > static_cast<unsigned>(valid / 64))
      throw std::runtime_error("debug grid is out of range");
    auto launch = [&] {
      HIP_CHECK(hipModuleLaunchKernel(function, grid_x, grid_y, 1,
                                      256, 1, 1, 0, nullptr, args, nullptr));
    };
    for (int i = 0; i < 5; ++i) launch();
    HIP_CHECK(hipDeviceSynchronize());

    hipEvent_t start = nullptr, stop = nullptr;
    HIP_CHECK(hipEventCreate(&start)); HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> samples;
    for (int i = 0; i < iterations; ++i) {
      HIP_CHECK(hipEventRecord(start)); launch(); HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float milliseconds = 0;
      HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
      samples.push_back(milliseconds * 1000.0f);
    }

    std::vector<uint16_t> output(sorted_capacity * n);
    HIP_CHECK(hipMemcpy(output.data(), d_output.ptr, output.size() * 2,
                        hipMemcpyDeviceToHost));
    const auto* ids = reinterpret_cast<const int32_t*>(sorted.data());
    const auto* expected = reinterpret_cast<const uint16_t*>(reference.data());
    size_t compared = 0, mismatches = 0;
    double sum_abs = 0.0, dot = 0.0, actual_norm = 0.0, expected_norm = 0.0;
    float max_abs = 0.0f;
    bool finite = true;
    for (int sorted_row = 0; sorted_row < valid; ++sorted_row) {
      const uint32_t packed = static_cast<uint32_t>(ids[sorted_row]);
      const uint32_t slot = packed >> 24;
      const uint32_t token = packed & 0x00ffffffu;
      if (slot >= topk || token >= rows) continue;
      for (int col = 0; col < n; ++col) {
        const uint16_t a_bits = output[static_cast<size_t>(sorted_row) * n + col];
        const uint16_t e_bits = expected[(static_cast<size_t>(token) * topk + slot) * n + col];
        mismatches += a_bits != e_bits;
        const float a = bf16_to_float(a_bits), e = bf16_to_float(e_bits);
        const float error = std::abs(a - e);
        finite = finite && std::isfinite(a);
        max_abs = std::max(max_abs, error); sum_abs += error;
        dot += static_cast<double>(a) * e;
        actual_norm += static_cast<double>(a) * a;
        expected_norm += static_cast<double>(e) * e;
        ++compared;
      }
    }
    double mean = 0.0;
    for (float value : samples) mean += value;
    mean /= samples.size();
    const double cosine = dot / std::sqrt(actual_norm * expected_norm);
    // This gate was fixed by the retained, previously validated raw M16 W13
    // boundary: 62,794 BF16 differences, 0.03125 max error, cosine 1.0.
    const bool correct = finite && mismatches <= 62794 &&
                         max_abs <= 0.03125f && cosine >= 0.999999;
    std::cout << "architecture=" << props.gcnArchName << "\n"
              << "block_m=64\nvalid_sorted_ids=" << valid << "\n"
              << "valid_blocks=" << valid / 64 << "\n"
              << "launched_grid=" << grid_x << "x" << grid_y << "\n"
              << "compared_elements=" << compared << "\n"
              << "bf16_mismatches=" << mismatches << "/" << compared << "\n"
              << "max_abs=" << max_abs << "\n"
              << "mean_abs=" << sum_abs / compared << "\n"
              << "cosine=" << cosine << "\n"
              << "finite=" << finite << "\n"
              << "correctness_gate=" << (correct ? "pass" : "fail") << "\n"
              << "reference_gate=validated_raw_m16_w13_boundary\n"
              << "mean_us=" << mean << "\n"
              << "median_us=" << percentile(samples, 0.5) << "\n"
              << "p90_us=" << percentile(samples, 0.9) << "\n"
              << "min_us=" << *std::min_element(samples.begin(), samples.end()) << "\n"
              << "max_us=" << *std::max_element(samples.begin(), samples.end()) << "\n";
    HIP_CHECK(hipEventDestroy(start)); HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(module));
    return correct ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << "\n";
    return 2;
  }
}
