// SPDX-License-Identifier: MIT

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
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
    if (status != hipSuccess) {                                                 \
      throw std::runtime_error(std::string(#expr) + ": " +                     \
                               hipGetErrorString(status));                      \
    }                                                                          \
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

static void write_binary(const std::string& path, const void* data,
                         size_t bytes) {
  std::ofstream output(path, std::ios::binary);
  if (!output) throw std::runtime_error("cannot create " + path);
  output.write(reinterpret_cast<const char*>(data), bytes);
  if (!output) throw std::runtime_error("cannot write " + path);
}

static float bf16_to_float(uint16_t value) {
  uint32_t bits = static_cast<uint32_t>(value) << 16;
  float result = 0.0f;
  std::memcpy(&result, &bits, sizeof(result));
  return result;
}

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer != nullptr) static_cast<void>(hipFree(pointer));
  }
};

struct Comparison {
  size_t bf16_mismatches = 0;
  float max_abs = 0.0f;
  double mean_abs = 0.0;
  double cosine = 0.0;
  bool finite = true;
};

static Comparison compare(const std::vector<uint16_t>& actual,
                          const std::vector<uint16_t>& expected_bf16,
                          const std::vector<float>& expected_f32) {
  if (actual.size() != expected_bf16.size() ||
      actual.size() != expected_f32.size()) {
    throw std::runtime_error("comparison size mismatch");
  }
  Comparison result;
  double dot = 0.0, actual_norm = 0.0, expected_norm = 0.0;
  for (size_t index = 0; index < actual.size(); ++index) {
    result.bf16_mismatches += actual[index] != expected_bf16[index];
    const float a = bf16_to_float(actual[index]);
    const float e = expected_f32[index];
    result.finite &= std::isfinite(a);
    const float error = std::abs(a - e);
    result.max_abs = std::max(result.max_abs, error);
    result.mean_abs += error;
    dot += static_cast<double>(a) * e;
    actual_norm += static_cast<double>(a) * a;
    expected_norm += static_cast<double>(e) * e;
  }
  result.mean_abs /= actual.size();
  result.cosine = dot / std::sqrt(actual_norm * expected_norm);
  return result;
}

static float median(std::vector<float> values) {
  std::sort(values.begin(), values.end());
  return values[values.size() / 2];
}

int main(int argc, char** argv) {
  try {
    if (argc < 4 || argc > 5) {
      std::cerr << "usage: " << argv[0]
                << " FUSED.hsaco REDUCE.hsaco CAPTURE_DIR [iterations=20]\n";
      return 2;
    }
    const int iterations = argc == 5 ? std::stoi(argv[4]) : 20;
    if (iterations < 2) throw std::runtime_error("iterations must be >=2");
    constexpr int kRows = 1024;
    constexpr int kTopk = 9;
    constexpr int kHidden = 2048;
    constexpr int kInter = 512;
    constexpr int kActiveExperts = 197;

    int device = 0;
    HIP_CHECK(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, device));
    if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0) {
      throw std::runtime_error("refusing non-gfx950 device");
    }

    const std::string capture = argv[3];
    auto hidden = read_binary(capture + "/hidden_fp8.bin");
    auto hidden_scale = read_binary(capture + "/hidden_scale_f32.bin");
    auto w13 = read_binary(capture + "/active_w13_fp8.bin");
    auto w13_scale = read_binary(capture + "/active_w13_scale_f32.bin");
    auto w2 = read_binary(capture + "/active_w2_fp8.bin");
    auto w2_scale = read_binary(capture + "/active_w2_scale_f32.bin");
    auto sorted_tokens =
        read_binary(capture + "/sorted_token_ids_i32.bin");
    auto sorted_experts =
        read_binary(capture + "/compact_sorted_expert_ids_i32.bin");
    auto valid_ids = read_binary(capture + "/num_valid_ids_i32.bin");
    auto topk_weights = read_binary(capture + "/topk_weights_f32.bin");
    auto reference_f32_bytes =
        read_binary(capture + "/reference_output_f32.bin");
    auto reference_bf16_bytes =
        read_binary(capture + "/reference_output_bf16.bin");
    auto aiter_bf16_bytes = read_binary(capture + "/aiter_output_bf16.bin");
    auto activation_bf16_bytes =
        read_binary(capture + "/activation_bf16.bin");
    auto activation_fp8_bytes =
        read_binary(capture + "/activation_fp8.bin");
    auto activation_scale_bytes =
        read_binary(capture + "/activation_scale_f32.bin");
    auto reference_stage1_bf16_bytes =
        read_binary(capture + "/reference_stage1_bf16.bin");

    const size_t output_elements = static_cast<size_t>(kRows) * kHidden;
    const size_t sorted_block_capacity =
        sorted_experts.size() / sizeof(int32_t);
    const size_t partial_elements =
        (static_cast<size_t>(kRows) * kTopk + sorted_block_capacity) * kHidden;
    if (hidden.size() != static_cast<size_t>(kRows) * kHidden ||
        hidden_scale.size() !=
            static_cast<size_t>(kRows) * 16 * sizeof(float) ||
        w13.size() !=
            static_cast<size_t>(kActiveExperts) * 1024 * kHidden ||
        w13_scale.size() !=
            static_cast<size_t>(kActiveExperts) * 8 * 16 * sizeof(float) ||
        w2.size() !=
            static_cast<size_t>(kActiveExperts) * kHidden * kInter ||
        w2_scale.size() !=
            static_cast<size_t>(kActiveExperts) * 16 * 4 * sizeof(float) ||
        sorted_tokens.size() % sizeof(int32_t) != 0 ||
        sorted_experts.size() % sizeof(int32_t) != 0 ||
        valid_ids.size() != sizeof(int32_t) ||
        topk_weights.size() !=
            static_cast<size_t>(kRows) * kTopk * sizeof(float) ||
        reference_f32_bytes.size() != output_elements * sizeof(float) ||
        reference_bf16_bytes.size() != output_elements * sizeof(uint16_t) ||
        aiter_bf16_bytes.size() != output_elements * sizeof(uint16_t)) {
      throw std::runtime_error("capture binary size mismatch");
    }
    const size_t route_elements =
        static_cast<size_t>(kRows) * kTopk * kInter;
    const size_t route_scale_elements =
        static_cast<size_t>(kRows) * kTopk * (kInter / 128);
    if (activation_bf16_bytes.size() !=
            route_elements * sizeof(uint16_t) ||
        activation_fp8_bytes.size() != route_elements ||
        activation_scale_bytes.size() !=
            route_scale_elements * sizeof(float) ||
        reference_stage1_bf16_bytes.size() !=
            static_cast<size_t>(kRows) * kTopk * kInter * 2 *
                sizeof(uint16_t)) {
      throw std::runtime_error("activation capture binary size mismatch");
    }

    DeviceBuffer d_hidden(hidden.size());
    DeviceBuffer d_hidden_scale(hidden_scale.size());
    DeviceBuffer d_w13(w13.size());
    DeviceBuffer d_w13_scale(w13_scale.size());
    DeviceBuffer d_w2(w2.size());
    DeviceBuffer d_w2_scale(w2_scale.size());
    DeviceBuffer d_sorted_tokens(sorted_tokens.size());
    DeviceBuffer d_sorted_experts(sorted_experts.size());
    DeviceBuffer d_valid_ids(valid_ids.size());
    DeviceBuffer d_topk_weights(topk_weights.size());
    DeviceBuffer d_partials(partial_elements * sizeof(float));
    DeviceBuffer d_output(output_elements * sizeof(uint16_t));
    DeviceBuffer d_debug_activation_bf16(sorted_block_capacity * 16 * kInter *
                                          2 * sizeof(uint16_t));
    DeviceBuffer d_debug_activation_fp8(sorted_block_capacity * 16 * kInter);
    DeviceBuffer d_debug_activation_scale(sorted_block_capacity * 16 *
                                           (kInter / 128) * sizeof(float));
    auto copy = [](DeviceBuffer& destination,
                   const std::vector<uint8_t>& source) {
      HIP_CHECK(hipMemcpy(destination.pointer, source.data(), source.size(),
                          hipMemcpyHostToDevice));
    };
    copy(d_hidden, hidden);
    copy(d_hidden_scale, hidden_scale);
    copy(d_w13, w13);
    copy(d_w13_scale, w13_scale);
    copy(d_w2, w2);
    copy(d_w2_scale, w2_scale);
    copy(d_sorted_tokens, sorted_tokens);
    copy(d_sorted_experts, sorted_experts);
    copy(d_valid_ids, valid_ids);
    copy(d_topk_weights, topk_weights);
    HIP_CHECK(hipMemset(d_partials.pointer, 0,
                        partial_elements * sizeof(float)));

    auto print_range = [](const char* name, const DeviceBuffer& buffer,
                          size_t bytes) {
      const auto begin = reinterpret_cast<uintptr_t>(buffer.pointer);
      std::cout << name << "=[0x" << std::hex << begin << ",0x"
                << begin + bytes << ")" << std::dec << "\n";
    };
    print_range("hidden", d_hidden, hidden.size());
    print_range("hidden_scale", d_hidden_scale, hidden_scale.size());
    print_range("w13", d_w13, w13.size());
    print_range("w13_scale", d_w13_scale, w13_scale.size());
    print_range("w2", d_w2, w2.size());
    print_range("w2_scale", d_w2_scale, w2_scale.size());
    print_range("sorted_tokens", d_sorted_tokens, sorted_tokens.size());
    print_range("sorted_experts", d_sorted_experts, sorted_experts.size());
    print_range("valid_ids", d_valid_ids, valid_ids.size());
    print_range("partials", d_partials, partial_elements * sizeof(float));
    std::cout.flush();
    if (std::getenv("NETRA_FUSED_DRY_RUN") != nullptr) return 0;

    hipModule_t fused_module{}, reduce_module{};
    hipFunction_t fused_function{}, reduce_function{};
    HIP_CHECK(hipModuleLoad(&fused_module, argv[1]));
    HIP_CHECK(hipModuleLoad(&reduce_module, argv[2]));
    HIP_CHECK(hipModuleGetFunction(&fused_function, fused_module,
                                   "qwen36_moe_fused_m16_fp8_gfx950"));
    HIP_CHECK(hipModuleGetFunction(
        &reduce_function, reduce_module,
        "qwen36_moe_route_reduce_f32_gfx950"));
    void* partial_pointer = d_partials.pointer;
    void* output_pointer = d_output.pointer;
    int rows = kRows;
    int debug_stage = 0;
    if (const char* value = std::getenv("NETRA_FUSED_DEBUG_STAGE")) {
      debug_stage = std::stoi(value);
      if (debug_stage < 0 || debug_stage > 7) {
        throw std::runtime_error("NETRA_FUSED_DEBUG_STAGE is out of range");
      }
    }
    size_t block_offset = 0;
    if (const char* value = std::getenv("NETRA_FUSED_BLOCK_OFFSET")) {
      block_offset = std::stoul(value);
      if (block_offset >= sorted_experts.size() / sizeof(int32_t)) {
        throw std::runtime_error("NETRA_FUSED_BLOCK_OFFSET is out of range");
      }
    }
    void* sorted_token_pointer = static_cast<uint8_t*>(d_sorted_tokens.pointer) +
                                 block_offset * 16 * sizeof(int32_t);
    void* sorted_expert_pointer =
        static_cast<uint8_t*>(d_sorted_experts.pointer) +
        block_offset * sizeof(int32_t);
    void* fused_arguments[] = {
        &d_hidden.pointer,          &d_hidden_scale.pointer,
        &d_w13.pointer,             &d_w13_scale.pointer,
        &d_w2.pointer,              &d_w2_scale.pointer,
        &sorted_token_pointer,      &sorted_expert_pointer,
        &d_valid_ids.pointer,       &partial_pointer,
        &rows,                      &debug_stage,
        &d_debug_activation_bf16.pointer,
        &d_debug_activation_fp8.pointer,
        &d_debug_activation_scale.pointer,
    };
    void* reduce_arguments[] = {
        &partial_pointer, &d_topk_weights.pointer, &output_pointer,
    };
    unsigned sorted_blocks =
        static_cast<unsigned>(sorted_experts.size() / sizeof(int32_t));
    if (const char* value = std::getenv("NETRA_FUSED_GRID_BLOCKS")) {
      sorted_blocks = static_cast<unsigned>(std::stoul(value));
      if (sorted_blocks == 0 ||
          sorted_blocks > sorted_experts.size() / sizeof(int32_t)) {
        throw std::runtime_error("NETRA_FUSED_GRID_BLOCKS is out of range");
      }
    }
    auto launch_fused = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(fused_function, sorted_blocks, 1, 1,
                                      512, 1, 1, 0, nullptr,
                                      fused_arguments, nullptr));
    };
    auto launch_reduce = [&]() {
      HIP_CHECK(hipModuleLaunchKernel(reduce_function, 32, kRows, 1, 64, 1, 1,
                                      0, nullptr, reduce_arguments, nullptr));
    };
    auto launch = [&]() {
      launch_fused();
      launch_reduce();
    };
    for (int index = 0; index < 3; ++index) launch();
    HIP_CHECK(hipDeviceSynchronize());

    if (debug_stage == 4 || debug_stage == 5) {
      std::vector<uint32_t> routes(
          static_cast<size_t>(sorted_blocks) * 8 * 16);
      HIP_CHECK(hipMemcpy(routes.data(), d_partials.pointer,
                          routes.size() * sizeof(uint32_t),
                          hipMemcpyDeviceToHost));
      for (unsigned block = 0; block < sorted_blocks; ++block) {
        for (int wave = 0; wave < 8; ++wave) {
          std::cout << "debug_routes[" << block << "][" << wave << "]=";
          for (int row = 0; row < 16; ++row) {
            if (row != 0) std::cout << ",";
            const size_t index =
                (static_cast<size_t>(block) * 8 + wave) * 16 + row;
            std::cout << routes[index];
          }
          std::cout << "\n";
        }
      }
      return 0;
    }

    if (debug_stage == 7) {
      int32_t num_valid = 0;
      std::memcpy(&num_valid, valid_ids.data(), sizeof(num_valid));
      const size_t first_sorted_row = block_offset * 16;
      const size_t retained_rows_after_offset =
          first_sorted_row < static_cast<size_t>(num_valid)
              ? static_cast<size_t>(num_valid) - first_sorted_row
              : 0;
      const size_t captured_sorted_rows = std::min(
          retained_rows_after_offset, static_cast<size_t>(sorted_blocks) * 16);
      std::vector<int32_t> packed_sorted(sorted_tokens.size() / sizeof(int32_t));
      std::memcpy(packed_sorted.data(), sorted_tokens.data(),
                  sorted_tokens.size());
      std::vector<uint16_t> actual(captured_sorted_rows * kInter * 2);
      HIP_CHECK(hipMemcpy(actual.data(), d_debug_activation_bf16.pointer,
                          actual.size() * sizeof(uint16_t),
                          hipMemcpyDeviceToHost));
      if (const char* prefix = std::getenv("NETRA_FUSED_DEBUG_DUMP_PREFIX")) {
        write_binary(std::string(prefix) + ".stage1_bf16.bin", actual.data(),
                     actual.size() * sizeof(uint16_t));
      }
      const auto* expected = reinterpret_cast<const uint16_t*>(
          reference_stage1_bf16_bytes.data());
      size_t valid_routes = 0, padding_rows = 0, mismatches = 0;
      float max_abs = 0.0f;
      double mean_abs = 0.0, dot = 0.0, actual_norm = 0.0,
             expected_norm = 0.0;
      for (size_t sorted_row = 0; sorted_row < captured_sorted_rows;
           ++sorted_row) {
        const uint32_t packed = static_cast<uint32_t>(
            packed_sorted[first_sorted_row + sorted_row]);
        const uint32_t token = packed & 0x00ffffffu;
        const uint32_t slot = packed >> 24;
        if (token >= kRows || slot >= kTopk) {
          ++padding_rows;
          continue;
        }
        ++valid_routes;
        const size_t route = static_cast<size_t>(token) * kTopk + slot;
        for (int column = 0; column < kInter * 2; ++column) {
          const size_t actual_index = sorted_row * kInter * 2 + column;
          const size_t expected_index = route * kInter * 2 + column;
          mismatches += actual[actual_index] != expected[expected_index];
          const float a = bf16_to_float(actual[actual_index]);
          const float e = bf16_to_float(expected[expected_index]);
          const float error = std::abs(a - e);
          max_abs = std::max(max_abs, error);
          mean_abs += error;
          dot += static_cast<double>(a) * e;
          actual_norm += static_cast<double>(a) * a;
          expected_norm += static_cast<double>(e) * e;
        }
      }
      const size_t compared_elements = valid_routes * kInter * 2;
      if (compared_elements == 0) {
        throw std::runtime_error("stage-7 grid captured no real routes");
      }
      std::cout << "architecture=" << properties.gcnArchName << "\n"
                << "debug_stage=7\n"
                << "retained_sorted_span=" << num_valid << "\n"
                << "captured_sorted_rows=" << captured_sorted_rows << "\n"
                << "valid_routes=" << valid_routes << "\n"
                << "padding_rows=" << padding_rows << "\n"
                << "stage1_bf16_mismatches=" << mismatches << "/"
                << compared_elements << "\n"
                << "stage1_bf16_max_abs=" << max_abs << "\n"
                << "stage1_bf16_mean_abs=" << mean_abs / compared_elements
                << "\n"
                << "stage1_bf16_cosine="
                << dot / std::sqrt(actual_norm * expected_norm) << "\n";
      return 0;
    }

    if (debug_stage == 6) {
      int32_t num_valid = 0;
      std::memcpy(&num_valid, valid_ids.data(), sizeof(num_valid));
      if (num_valid < 0 ||
          static_cast<size_t>(num_valid) > sorted_tokens.size() / sizeof(int32_t)) {
        throw std::runtime_error("invalid retained sorted-route count");
      }
      std::vector<int32_t> packed_sorted(sorted_tokens.size() / sizeof(int32_t));
      std::memcpy(packed_sorted.data(), sorted_tokens.data(),
                  sorted_tokens.size());
      const size_t first_sorted_row = block_offset * 16;
      const size_t retained_rows_after_offset =
          first_sorted_row < static_cast<size_t>(num_valid)
              ? static_cast<size_t>(num_valid) - first_sorted_row
              : 0;
      const size_t captured_sorted_rows = std::min(
          retained_rows_after_offset, static_cast<size_t>(sorted_blocks) * 16);
      std::vector<uint16_t> actual_bf16(captured_sorted_rows * kInter);
      std::vector<uint8_t> actual_fp8(captured_sorted_rows * kInter);
      std::vector<float> actual_scale(captured_sorted_rows * (kInter / 128));
      HIP_CHECK(hipMemcpy(actual_bf16.data(), d_debug_activation_bf16.pointer,
                          actual_bf16.size() * sizeof(uint16_t),
                          hipMemcpyDeviceToHost));
      HIP_CHECK(hipMemcpy(actual_fp8.data(), d_debug_activation_fp8.pointer,
                          actual_fp8.size(), hipMemcpyDeviceToHost));
      HIP_CHECK(hipMemcpy(actual_scale.data(), d_debug_activation_scale.pointer,
                          actual_scale.size() * sizeof(float),
                          hipMemcpyDeviceToHost));
      if (const char* prefix = std::getenv("NETRA_FUSED_DEBUG_DUMP_PREFIX")) {
        write_binary(std::string(prefix) + ".activation_bf16.bin",
                     actual_bf16.data(),
                     actual_bf16.size() * sizeof(uint16_t));
        write_binary(std::string(prefix) + ".activation_fp8.bin",
                     actual_fp8.data(), actual_fp8.size());
        write_binary(std::string(prefix) + ".activation_scale_f32.bin",
                     actual_scale.data(), actual_scale.size() * sizeof(float));
      }

      const auto* expected_bf16 = reinterpret_cast<const uint16_t*>(
          activation_bf16_bytes.data());
      const auto* expected_fp8 = activation_fp8_bytes.data();
      const auto* expected_scale = reinterpret_cast<const float*>(
          activation_scale_bytes.data());
      size_t valid_routes = 0, padding_rows = 0;
      size_t bf16_mismatches = 0, fp8_mismatches = 0, scale_mismatches = 0;
      float bf16_max_abs = 0.0f, scale_max_abs = 0.0f;
      double bf16_mean_abs = 0.0, dot = 0.0, actual_norm = 0.0,
             expected_norm = 0.0;
      for (size_t sorted_row = 0; sorted_row < captured_sorted_rows;
           ++sorted_row) {
        const uint32_t packed = static_cast<uint32_t>(
            packed_sorted[first_sorted_row + sorted_row]);
        const uint32_t token = packed & 0x00ffffffu;
        const uint32_t slot = packed >> 24;
        if (token >= kRows || slot >= kTopk) {
          ++padding_rows;
          continue;
        }
        ++valid_routes;
        const size_t route = static_cast<size_t>(token) * kTopk + slot;
        for (int column = 0; column < kInter; ++column) {
          const size_t actual_index =
              sorted_row * kInter + column;
          const size_t expected_index = route * kInter + column;
          bf16_mismatches +=
              actual_bf16[actual_index] != expected_bf16[expected_index];
          fp8_mismatches +=
              actual_fp8[actual_index] != expected_fp8[expected_index];
          const float actual_value = bf16_to_float(actual_bf16[actual_index]);
          const float expected_value = bf16_to_float(expected_bf16[expected_index]);
          const float error = std::abs(actual_value - expected_value);
          bf16_max_abs = std::max(bf16_max_abs, error);
          bf16_mean_abs += error;
          dot += static_cast<double>(actual_value) * expected_value;
          actual_norm += static_cast<double>(actual_value) * actual_value;
          expected_norm += static_cast<double>(expected_value) * expected_value;
        }
        for (int group = 0; group < kInter / 128; ++group) {
          const size_t actual_index =
              sorted_row * (kInter / 128) + group;
          const size_t expected_index = route * (kInter / 128) + group;
          const float actual_value = actual_scale[actual_index];
          const float expected_value = expected_scale[expected_index];
          scale_mismatches += actual_value != expected_value;
          scale_max_abs = std::max(scale_max_abs,
                                   std::abs(actual_value - expected_value));
        }
      }
      const size_t compared_elements = valid_routes * kInter;
      if (compared_elements == 0) {
        throw std::runtime_error("debug grid captured no real routes");
      }
      std::cout << "architecture=" << properties.gcnArchName << "\n"
                << "debug_stage=6\n"
                << "retained_sorted_span=" << num_valid << "\n"
                << "captured_sorted_rows=" << captured_sorted_rows << "\n"
                << "valid_routes=" << valid_routes << "\n"
                << "padding_rows=" << padding_rows << "\n"
                << "activation_bf16_mismatches=" << bf16_mismatches << "/"
                << compared_elements << "\n"
                << "activation_bf16_max_abs=" << bf16_max_abs << "\n"
                << "activation_bf16_mean_abs="
                << bf16_mean_abs / compared_elements << "\n"
                << "activation_bf16_cosine="
                << dot / std::sqrt(actual_norm * expected_norm) << "\n"
                << "activation_fp8_byte_mismatches=" << fp8_mismatches << "/"
                << compared_elements << "\n"
                << "activation_scale_mismatches=" << scale_mismatches << "/"
                << valid_routes * (kInter / 128) << "\n"
                << "activation_scale_max_abs=" << scale_max_abs << "\n";
      return 0;
    }

    std::vector<uint16_t> output(output_elements);
    HIP_CHECK(hipMemcpy(output.data(), d_output.pointer,
                        output.size() * sizeof(uint16_t),
                        hipMemcpyDeviceToHost));
    std::vector<float> reference_f32(output_elements);
    std::memcpy(reference_f32.data(), reference_f32_bytes.data(),
                reference_f32_bytes.size());
    std::vector<uint16_t> reference_bf16(output_elements);
    std::memcpy(reference_bf16.data(), reference_bf16_bytes.data(),
                reference_bf16_bytes.size());
    std::vector<uint16_t> aiter_bf16(output_elements);
    std::memcpy(aiter_bf16.data(), aiter_bf16_bytes.data(),
                aiter_bf16_bytes.size());
    const Comparison structural =
        compare(output, reference_bf16, reference_f32);
    std::vector<float> aiter_f32(output_elements);
    for (size_t index = 0; index < output_elements; ++index) {
      aiter_f32[index] = bf16_to_float(aiter_bf16[index]);
    }
    const Comparison deployed = compare(output, aiter_bf16, aiter_f32);

    hipEvent_t start{}, middle{}, stop{};
    HIP_CHECK(hipEventCreate(&start));
    HIP_CHECK(hipEventCreate(&middle));
    HIP_CHECK(hipEventCreate(&stop));
    std::vector<float> fused_timings;
    std::vector<float> pipeline_timings;
    fused_timings.reserve(iterations);
    pipeline_timings.reserve(iterations);
    const std::vector<uint16_t> first = output;
    size_t nondeterministic_iterations = 0;
    for (int index = 0; index < iterations; ++index) {
      HIP_CHECK(hipEventRecord(start));
      launch_fused();
      HIP_CHECK(hipEventRecord(middle));
      launch_reduce();
      HIP_CHECK(hipEventRecord(stop));
      HIP_CHECK(hipEventSynchronize(stop));
      float fused_ms = 0.0f, pipeline_ms = 0.0f;
      HIP_CHECK(hipEventElapsedTime(&fused_ms, start, middle));
      HIP_CHECK(hipEventElapsedTime(&pipeline_ms, start, stop));
      fused_timings.push_back(fused_ms * 1000.0f);
      pipeline_timings.push_back(pipeline_ms * 1000.0f);
      HIP_CHECK(hipMemcpy(output.data(), d_output.pointer,
                          output.size() * sizeof(uint16_t),
                          hipMemcpyDeviceToHost));
      nondeterministic_iterations += output != first;
    }

    std::cout << "architecture=" << properties.gcnArchName << "\n"
              << "rows=" << kRows << "\n"
              << "sorted_blocks=" << sorted_blocks << "\n"
              << "structural_bf16_mismatches=" << structural.bf16_mismatches
              << "/" << output_elements << "\n"
              << "structural_max_abs=" << structural.max_abs << "\n"
              << "structural_mean_abs=" << structural.mean_abs << "\n"
              << "structural_cosine=" << structural.cosine << "\n"
              << "aiter_bf16_mismatches=" << deployed.bf16_mismatches << "/"
              << output_elements << "\n"
              << "aiter_max_abs=" << deployed.max_abs << "\n"
              << "aiter_mean_abs=" << deployed.mean_abs << "\n"
              << "aiter_cosine=" << deployed.cosine << "\n"
              << "finite=" << structural.finite << "\n"
              << "nondeterministic_iterations=" << nondeterministic_iterations
              << "/" << iterations << "\n"
              << "fused_median_us=" << median(fused_timings) << "\n"
              << "pipeline_median_us=" << median(pipeline_timings) << "\n";
    HIP_CHECK(hipEventDestroy(start));
    HIP_CHECK(hipEventDestroy(middle));
    HIP_CHECK(hipEventDestroy(stop));
    HIP_CHECK(hipModuleUnload(fused_module));
    HIP_CHECK(hipModuleUnload(reduce_module));
    return structural.finite && std::isfinite(structural.cosine) &&
                   structural.cosine > 0.999 &&
                   nondeterministic_iterations == 0
               ? 0
               : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
