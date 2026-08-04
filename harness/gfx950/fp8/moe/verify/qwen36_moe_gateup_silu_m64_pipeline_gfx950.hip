// SPDX-License-Identifier: MIT
// Real-checkpoint paired M64 gate/up+SiLU+quant+W2 correctness/timing harness.

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

static void write_file(const std::string& path, const void* data, size_t bytes) {
  std::ofstream stream(path, std::ios::binary);
  if (!stream) throw std::runtime_error("cannot create " + path);
  stream.write(reinterpret_cast<const char*>(data), bytes);
  if (!stream) throw std::runtime_error("cannot write " + path);
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
    if (argc != 8) {
      std::cerr << "usage: " << argv[0]
                << " PAIRED.hsaco FULL_EXPORT_DIR M64_SORT_DIR iterations"
                   " QUANT.hsaco DOWN.hsaco REDUCE.hsaco\n";
      return 2;
    }
    const std::string co_path = argv[1];
    const std::string base = argv[2];
    const std::string sort = argv[3];
    const int iterations = argc >= 5 ? std::stoi(argv[4]) : 50;
    const bool fused_quant = std::getenv("NETRA_KERNEL_FUSED_QUANT") != nullptr;
    const bool run_quant = !fused_quant;
    const bool run_down = true;
    const bool down_atomic = std::getenv("NETRA_DOWN_ATOMIC") != nullptr;
    const std::string quant_co_path = argv[5];
    if (iterations < 2) throw std::runtime_error("iterations must be >= 2");

    hipDeviceProp_t props{};
    HIP_CHECK(hipGetDeviceProperties(&props, 0));
    if (std::string(props.gcnArchName).rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device");

    const auto hidden = read_file(base + "/hidden_fp8.bin");
    const auto hidden_scale = read_file(base + "/hidden_scale_f32.bin");
    const auto w13 = read_file(base + "/active_w13_fp8.bin");
    const auto w13_scale = read_file(base + "/active_w13_scale_f32.bin");
    const auto reference_activation_bf16 =
        read_file(base + "/activation_bf16.bin");
    const auto reference_activation = read_file(base + "/activation_fp8.bin");
    const auto reference_activation_scale =
        read_file(base + "/activation_scale_f32.bin");
    const auto w2 = read_file(base + "/active_w2_fp8.bin");
    const auto w2_scale = read_file(base + "/active_w2_scale_f32.bin");
    const auto topk_weights = read_file(base + "/topk_weights_f32.bin");
    const auto reference_output_f32 = read_file(base + "/reference_output_f32.bin");
    const auto reference_output_bf16 = read_file(base + "/reference_output_bf16.bin");
    const auto aiter_output_bf16 = read_file(base + "/aiter_output_bf16.bin");
    const auto sorted = read_file(sort + "/sorted_token_ids_m64_i32.bin");
    const auto experts =
        read_file(sort + "/compact_sorted_expert_ids_m64_i32.bin");
    const auto valid_bytes = read_file(sort + "/num_valid_ids_m64_i32.bin");
    const auto sorted_weights = read_file(sort + "/sorted_weights_m64_f32.bin");
    int32_t valid = 0;
    std::memcpy(&valid, valid_bytes.data(), sizeof(valid));
    if (valid <= 0 || valid % 64) throw std::runtime_error("invalid M64 span");
    constexpr int hidden_columns = 2048, topk = 9, n = 512;
    if (hidden.empty() || hidden.size() % hidden_columns != 0)
      throw std::runtime_error("hidden FP8 capture shape mismatch");
    const int rows = static_cast<int>(hidden.size() / hidden_columns);
    if (rows < 1 || rows > 1024)
      throw std::runtime_error("captured row count is outside 1..1024");
    const int routes = rows * topk;
    const size_t sorted_capacity = sorted.size() / sizeof(int32_t);
    if (reference_activation_bf16.size() !=
        static_cast<size_t>(routes) * n * sizeof(uint16_t))
      throw std::runtime_error("activation BF16 reference shape mismatch");
    if (experts.size() / sizeof(int32_t) < static_cast<size_t>(valid / 64))
      throw std::runtime_error("expert block array too small");

    Buffer d_hidden(hidden.size()), d_hidden_scale(hidden_scale.size());
    Buffer d_w13(w13.size()), d_w13_scale(w13_scale.size());
    Buffer d_sorted(sorted.size()), d_experts(experts.size());
    Buffer d_valid(valid_bytes.size());
    Buffer d_activation_bf16(
        (static_cast<size_t>(routes) + valid) * n * sizeof(uint16_t));
    Buffer d_activation(static_cast<size_t>(routes) * n);
    Buffer d_activation_scale(
        static_cast<size_t>(rows) * topk * 4 * sizeof(float));
    Buffer d_w2(w2.size()), d_w2_scale(w2_scale.size());
    Buffer d_sorted_weights(sorted_weights.size());
    Buffer d_topk_weights(topk_weights.size());
    Buffer d_partials(
        (static_cast<size_t>(rows) * topk + valid) * 2048 * sizeof(float));
    Buffer d_final(static_cast<size_t>(rows) * 2048 * sizeof(uint16_t));
    upload(d_hidden, hidden); upload(d_hidden_scale, hidden_scale);
    upload(d_w13, w13); upload(d_w13_scale, w13_scale);
    upload(d_sorted, sorted); upload(d_experts, experts); upload(d_valid, valid_bytes);
    upload(d_w2, w2); upload(d_w2_scale, w2_scale);
    upload(d_sorted_weights, sorted_weights); upload(d_topk_weights, topk_weights);
    HIP_CHECK(hipMemset(
        d_activation_bf16.ptr, 0,
        (static_cast<size_t>(routes) + valid) * n * sizeof(uint16_t)));
    HIP_CHECK(hipMemset(d_activation.ptr, 0, rows * topk * 512));
    HIP_CHECK(hipMemset(
        d_activation_scale.ptr, 0, rows * topk * 4 * sizeof(float)));

    hipModule_t module = nullptr;
    hipFunction_t function = nullptr;
    HIP_CHECK(hipModuleLoad(&module, co_path.c_str()));
    const char* symbol = std::getenv("NETRA_KERNEL_SYMBOL");
    if (!symbol) symbol = "qwen36_moe_gateup_silu_m64n64_fp8_gfx950";
    HIP_CHECK(hipModuleGetFunction(&function, module, symbol));
    hipModule_t quant_module = nullptr;
    hipFunction_t quant_function = nullptr;
    if (run_quant) {
      HIP_CHECK(hipModuleLoad(&quant_module, quant_co_path.c_str()));
      HIP_CHECK(hipModuleGetFunction(
          &quant_function, quant_module,
          "qwen36_moe_quant_bf16_m64_fp8_gfx950"));
    }
    hipModule_t down_module = nullptr, reduce_module = nullptr;
    hipFunction_t down_function = nullptr, reduce_function = nullptr;
    if (run_down) {
      HIP_CHECK(hipModuleLoad(&down_module, argv[6]));
      HIP_CHECK(hipModuleLoad(&reduce_module, argv[7]));
      const char* down_symbol = std::getenv("NETRA_DOWN_KERNEL_SYMBOL");
      if (!down_symbol)
        down_symbol = "qwen36_moe_down_m64n64_partial_masked_fp8_gfx950";
      const char* reduce_symbol = std::getenv("NETRA_REDUCE_KERNEL_SYMBOL");
      if (!reduce_symbol)
        reduce_symbol = "qwen36_moe_route_reduce_f32_gfx950";
      HIP_CHECK(hipModuleGetFunction(
          &down_function, down_module, down_symbol));
      HIP_CHECK(hipModuleGetFunction(
          &reduce_function, reduce_module, reduce_symbol));
    }
    int token_rows = rows;
    void* output_pointer = d_activation_bf16.ptr;
    void* args[] = {&d_hidden.ptr, &d_hidden_scale.ptr, &d_w13.ptr,
                    &d_w13_scale.ptr, &d_sorted.ptr, &d_experts.ptr,
                    &d_valid.ptr, &output_pointer, &token_rows};
    void* fused_args[] = {
        &d_hidden.ptr, &d_hidden_scale.ptr, &d_w13.ptr, &d_w13_scale.ptr,
        &d_sorted.ptr, &d_experts.ptr, &d_valid.ptr, &d_activation.ptr,
        &d_activation_scale.ptr, &token_rows};
    unsigned grid_x = fused_quant ? 4 : 8;
    unsigned grid_y = static_cast<unsigned>(valid / 64);
    if (const char* value = std::getenv("NETRA_GRID_X")) grid_x = std::stoul(value);
    if (const char* value = std::getenv("NETRA_GRID_Y")) grid_y = std::stoul(value);
    if (grid_x < 1 || grid_x > 64 || grid_y < 1 || grid_y > static_cast<unsigned>(valid / 64))
      throw std::runtime_error("debug grid is out of range");
    auto launch = [&] {
      HIP_CHECK(hipModuleLaunchKernel(function, grid_x, grid_y, 1,
                                      256, 1, 1, 0, nullptr,
                                      fused_quant ? fused_args : args, nullptr));
    };
    int route_count = routes;
    void* quant_args[] = {&d_activation_bf16.ptr, &d_activation.ptr,
                          &d_activation_scale.ptr, &route_count};
    auto launch_quant = [&] {
      HIP_CHECK(hipModuleLaunchKernel(
          quant_function, (routes + 3) / 4, 1, 1, 256, 1, 1, 0, nullptr,
          quant_args, nullptr));
    };
    void* down_output = down_atomic ? d_final.ptr : d_partials.ptr;
    void* down_args[] = {
        &d_activation.ptr, &d_activation_scale.ptr, &d_w2.ptr, &d_w2_scale.ptr,
        &d_sorted.ptr, &d_sorted_weights.ptr, &d_experts.ptr, &d_valid.ptr,
        &down_output, &token_rows};
    unsigned down_grid_x = 32;
    if (const char* value = std::getenv("NETRA_DOWN_GRID_X"))
      down_grid_x = std::stoul(value);
    if (down_grid_x != 16 && down_grid_x != 32)
      throw std::runtime_error("NETRA_DOWN_GRID_X must be 16 or 32");
    void* reduce_args[] = {
        &d_partials.ptr, &d_topk_weights.ptr, &d_final.ptr};
    unsigned reduce_grid_x = 32;
    unsigned reduce_wg_size = 64;
    if (const char* value = std::getenv("NETRA_REDUCE_GRID_X"))
      reduce_grid_x = std::stoul(value);
    if (const char* value = std::getenv("NETRA_REDUCE_WG_SIZE"))
      reduce_wg_size = std::stoul(value);
    if (reduce_grid_x < 1 || reduce_grid_x > 32 ||
        (reduce_wg_size != 64 && reduce_wg_size != 128 &&
         reduce_wg_size != 256))
      throw std::runtime_error("invalid reduction launch geometry");
    auto launch_down_kernel = [&] {
      if (down_atomic) {
        HIP_CHECK(hipMemsetAsync(
            d_final.ptr, 0,
            static_cast<size_t>(rows) * 2048 * sizeof(uint16_t), nullptr));
      }
      HIP_CHECK(hipModuleLaunchKernel(
          down_function, down_grid_x, valid / 64, 1, 256, 1, 1, 0, nullptr,
          down_args, nullptr));
    };
    auto launch_reduce = [&] {
      if (down_atomic) return;
      HIP_CHECK(hipModuleLaunchKernel(
          reduce_function, reduce_grid_x, rows, 1, reduce_wg_size, 1, 1, 0,
          nullptr,
          reduce_args, nullptr));
    };
    auto launch_down = [&] {
      launch_down_kernel();
      launch_reduce();
    };
    for (int i = 0; i < 5; ++i) {
      launch();
      if (run_quant) launch_quant();
      if (run_down) launch_down();
    }
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
    std::vector<float> quant_samples;
    std::vector<float> pipeline_samples;
    std::vector<float> down_kernel_samples;
    std::vector<float> reduce_samples;
    std::vector<float> complete_samples;
    if (run_quant || fused_quant) {
      launch();
      if (run_quant) {
        HIP_CHECK(hipDeviceSynchronize());
        for (int i = 0; i < iterations; ++i) {
          HIP_CHECK(hipEventRecord(start));
          launch_quant();
          HIP_CHECK(hipEventRecord(stop));
          HIP_CHECK(hipEventSynchronize(stop));
          float milliseconds = 0;
          HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
          quant_samples.push_back(milliseconds * 1000.0f);
        }
      }
      for (int i = 0; i < iterations; ++i) {
        HIP_CHECK(hipEventRecord(start));
        launch();
        if (run_quant) launch_quant();
        HIP_CHECK(hipEventRecord(stop));
        HIP_CHECK(hipEventSynchronize(stop));
        float milliseconds = 0;
        HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
        pipeline_samples.push_back(milliseconds * 1000.0f);
      }
      if (run_down) {
        launch();
        if (run_quant) launch_quant();
        HIP_CHECK(hipDeviceSynchronize());
        for (int i = 0; i < iterations; ++i) {
          HIP_CHECK(hipEventRecord(start));
          launch_down_kernel();
          HIP_CHECK(hipEventRecord(stop));
          HIP_CHECK(hipEventSynchronize(stop));
          float milliseconds = 0;
          HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
          down_kernel_samples.push_back(milliseconds * 1000.0f);
        }
        if (!down_atomic) {
          launch_down_kernel();
          HIP_CHECK(hipDeviceSynchronize());
          for (int i = 0; i < iterations; ++i) {
            HIP_CHECK(hipEventRecord(start));
            launch_reduce();
            HIP_CHECK(hipEventRecord(stop));
            HIP_CHECK(hipEventSynchronize(stop));
            float milliseconds = 0;
            HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
            reduce_samples.push_back(milliseconds * 1000.0f);
          }
        }
        for (int i = 0; i < iterations; ++i) {
          HIP_CHECK(hipEventRecord(start));
          launch();
          if (run_quant) launch_quant();
          launch_down();
          HIP_CHECK(hipEventRecord(stop));
          HIP_CHECK(hipEventSynchronize(stop));
          float milliseconds = 0;
          HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
          complete_samples.push_back(milliseconds * 1000.0f);
        }
      }
    }

    std::vector<uint16_t> activation_bf16(static_cast<size_t>(routes) * n);
    const auto* expected =
        reinterpret_cast<const uint16_t*>(reference_activation_bf16.data());
    size_t compared = 0, mismatches = 0;
    double sum_abs = 0.0, dot = 0.0, actual_norm = 0.0, expected_norm = 0.0;
    float max_abs = 0.0f;
    bool finite = true;
    double cosine = 1.0;
    bool correct = true;
    if (!fused_quant) {
      HIP_CHECK(hipMemcpy(
          activation_bf16.data(), d_activation_bf16.ptr,
          activation_bf16.size() * sizeof(uint16_t), hipMemcpyDeviceToHost));
      for (int route = 0; route < routes; ++route) {
        for (int col = 0; col < n; ++col) {
          const size_t index = static_cast<size_t>(route) * n + col;
          const uint16_t a_bits = activation_bf16[index];
          const uint16_t e_bits = expected[index];
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
      cosine = dot / std::sqrt(actual_norm * expected_norm);
      correct = finite && max_abs <= 0.03125f && cosine >= 0.99999;
    }
    double mean = 0.0;
    for (float value : samples) mean += value;
    mean /= samples.size();
    // Predeclared before running the paired candidate. Downstream FP8 and full
    // output gates remain the stronger inherited raw-M16 acceptance checks.
    size_t activation_byte_mismatches = 0;
    double scale_max_abs = 0.0;
    bool quant_correct = true;
    if (run_quant || fused_quant) {
      std::vector<uint8_t> activation(reference_activation.size());
      std::vector<float> activation_scale(
          reference_activation_scale.size() / sizeof(float));
      HIP_CHECK(hipMemcpy(
          activation.data(), d_activation.ptr, activation.size(),
          hipMemcpyDeviceToHost));
      HIP_CHECK(hipMemcpy(
          activation_scale.data(), d_activation_scale.ptr,
          reference_activation_scale.size(), hipMemcpyDeviceToHost));
      if (const char* export_dir = std::getenv("NETRA_EXPORT_ACTIVATION_DIR")) {
        write_file(
            std::string(export_dir) + "/activation_fp8.bin",
            activation.data(), activation.size());
        write_file(
            std::string(export_dir) + "/activation_scale_f32.bin",
            activation_scale.data(),
            activation_scale.size() * sizeof(float));
      }
      for (size_t index = 0; index < activation.size(); ++index)
        activation_byte_mismatches +=
            activation[index] != reference_activation[index];
      const float* expected_scales =
          reinterpret_cast<const float*>(reference_activation_scale.data());
      for (size_t index = 0; index < activation_scale.size(); ++index)
        scale_max_abs = std::max(
            scale_max_abs,
            std::abs(static_cast<double>(activation_scale[index]) -
                     expected_scales[index]));
      // Fixed before this candidate from the validated raw M16 stage-6 gate.
      quant_correct = activation_byte_mismatches <= 101627 &&
                      scale_max_abs <= 3.48776e-05;
    }
    size_t full_mismatches = 0;
    float full_structural_max_abs = 0.0f, full_aiter_max_abs = 0.0f;
    double full_structural_cosine = 1.0, full_aiter_cosine = 1.0;
    bool full_correct = true;
    if (run_down) {
      const size_t elements = static_cast<size_t>(rows) * 2048;
      std::vector<uint16_t> final_output(elements);
      HIP_CHECK(hipMemcpy(
          final_output.data(), d_final.ptr, elements * sizeof(uint16_t),
          hipMemcpyDeviceToHost));
      if (const char* dump_path = std::getenv("NETRA_DUMP_FINAL")) {
        std::ofstream dump(dump_path, std::ios::binary | std::ios::trunc);
        if (!dump) throw std::runtime_error("cannot open final-output dump");
        dump.write(reinterpret_cast<const char*>(final_output.data()),
                   final_output.size() * sizeof(uint16_t));
        if (!dump) throw std::runtime_error("cannot write final-output dump");
      }
      const float* structural_f32 =
          reinterpret_cast<const float*>(reference_output_f32.data());
      const uint16_t* structural_bf16 =
          reinterpret_cast<const uint16_t*>(reference_output_bf16.data());
      const uint16_t* aiter_bf16 =
          reinterpret_cast<const uint16_t*>(aiter_output_bf16.data());
      double sdot = 0.0, sanorm = 0.0, senorm = 0.0;
      double adot = 0.0, aanorm = 0.0, aenorm = 0.0;
      for (size_t i = 0; i < elements; ++i) {
        full_mismatches += final_output[i] != structural_bf16[i];
        const float value = bf16_to_float(final_output[i]);
        const float structural_value = structural_f32[i];
        const float aiter_value = bf16_to_float(aiter_bf16[i]);
        full_structural_max_abs = std::max(
            full_structural_max_abs, std::abs(value - structural_value));
        full_aiter_max_abs = std::max(
            full_aiter_max_abs, std::abs(value - aiter_value));
        sdot += static_cast<double>(value) * structural_value;
        sanorm += static_cast<double>(value) * value;
        senorm += static_cast<double>(structural_value) * structural_value;
        adot += static_cast<double>(value) * aiter_value;
        aanorm += static_cast<double>(value) * value;
        aenorm += static_cast<double>(aiter_value) * aiter_value;
      }
      full_structural_cosine = sdot / std::sqrt(sanorm * senorm);
      full_aiter_cosine = adot / std::sqrt(aanorm * aenorm);
      full_correct = full_structural_max_abs <= 0.000849762f &&
                     full_structural_cosine >= 0.9999725 &&
                     full_aiter_max_abs <= 0.000976563f &&
                     full_aiter_cosine >= 0.9999645;
    }
    std::cout << "architecture=" << props.gcnArchName << "\n"
              << "block_m=64\nfused_quant=" << fused_quant
              << "\nvalid_sorted_ids=" << valid << "\n"
              << "valid_blocks=" << valid / 64 << "\n"
              << "launched_grid=" << grid_x << "x" << grid_y << "\n"
              << "compared_elements=" << compared << "\n"
              << "activation_bf16_mismatches=" << mismatches << "/" << compared << "\n"
              << "max_abs=" << max_abs << "\n"
              << "mean_abs=" << (compared ? sum_abs / compared : 0.0) << "\n"
              << "cosine=" << cosine << "\n"
              << "finite=" << finite << "\n"
              << "correctness_gate=" << (correct ? "pass" : "fail") << "\n"
              << "reference_gate=predeclared_paired_activation_boundary\n"
              << "mean_us=" << mean << "\n"
              << "median_us=" << percentile(samples, 0.5) << "\n"
              << "p90_us=" << percentile(samples, 0.9) << "\n"
              << "min_us=" << *std::min_element(samples.begin(), samples.end()) << "\n"
              << "max_us=" << *std::max_element(samples.begin(), samples.end()) << "\n";
    if (run_quant || fused_quant) {
      std::cout << "activation_fp8_byte_mismatches="
                << activation_byte_mismatches << "/"
                << reference_activation.size() << "\n"
                << "activation_scale_max_abs=" << scale_max_abs << "\n"
                << "activation_correctness_gate="
                << (quant_correct ? "pass" : "fail") << "\n"
                << "activation_reference_gate=validated_raw_m16_stage6\n";
      if (run_quant) {
        std::cout << "quant_median_us=" << percentile(quant_samples, 0.5) << "\n"
                  << "quant_p90_us=" << percentile(quant_samples, 0.9) << "\n";
      }
      std::cout << "paired_quant_median_us="
                << percentile(pipeline_samples, 0.5) << "\n"
                << "paired_quant_p90_us="
                << percentile(pipeline_samples, 0.9) << "\n";
    }
    if (run_down) {
      std::cout << "full_structural_bf16_mismatches=" << full_mismatches
                << "/" << static_cast<size_t>(rows) * 2048 << "\n"
                << "full_structural_max_abs=" << full_structural_max_abs << "\n"
                << "full_structural_cosine=" << full_structural_cosine << "\n"
                << "full_aiter_max_abs=" << full_aiter_max_abs << "\n"
                << "full_aiter_cosine=" << full_aiter_cosine << "\n"
                << "full_correctness_gate="
                << (full_correct ? "pass" : "fail") << "\n"
                << "down_kernel_median_us="
                << percentile(down_kernel_samples, 0.5) << "\n"
                << "down_kernel_p90_us="
                << percentile(down_kernel_samples, 0.9) << "\n"
                << "down_atomic=" << (down_atomic ? 1 : 0) << "\n";
      if (!down_atomic) {
        std::cout << "reduce_median_us="
                  << percentile(reduce_samples, 0.5) << "\n"
                  << "reduce_p90_us="
                  << percentile(reduce_samples, 0.9) << "\n";
      }
      std::cout
                << "complete_pipeline_median_us="
                << percentile(complete_samples, 0.5) << "\n"
                << "complete_pipeline_p90_us="
                << percentile(complete_samples, 0.9) << "\n";
    }
    HIP_CHECK(hipEventDestroy(start)); HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(module));
    if (quant_module) HIP_CHECK(hipModuleUnload(quant_module));
    if (down_module) HIP_CHECK(hipModuleUnload(down_module));
    if (reduce_module) HIP_CHECK(hipModuleUnload(reduce_module));
    return correct && quant_correct && full_correct ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << "\n";
    return 2;
  }
}
