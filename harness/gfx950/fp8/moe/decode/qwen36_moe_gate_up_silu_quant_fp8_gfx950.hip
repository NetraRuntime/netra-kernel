// SPDX-License-Identifier: MIT
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
    if (status != hipSuccess) {                                                 \
      throw std::runtime_error(std::string(#expr) + ": " +                    \
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

static uint64_t fnv1a64(const void* pointer, size_t bytes) {
  const auto* data = static_cast<const uint8_t*>(pointer);
  uint64_t hash = UINT64_C(1469598103934665603);
  for (size_t i = 0; i < bytes; ++i) {
    hash ^= data[i];
    hash *= UINT64_C(1099511628211);
  }
  return hash;
}

struct DeviceBuffer {
  void* pointer = nullptr;
  explicit DeviceBuffer(size_t bytes) { HIP_CHECK(hipMalloc(&pointer, bytes)); }
  ~DeviceBuffer() {
    if (pointer) static_cast<void>(hipFree(pointer));
  }
  DeviceBuffer(const DeviceBuffer&) = delete;
  DeviceBuffer& operator=(const DeviceBuffer&) = delete;
};

struct ModuleFunction {
  hipModule_t module = nullptr;
  hipFunction_t function = nullptr;
  ModuleFunction(const char* path, const char* symbol) {
    HIP_CHECK(hipModuleLoad(&module, path));
    HIP_CHECK(hipModuleGetFunction(&function, module, symbol));
  }
  ~ModuleFunction() {
    if (module) static_cast<void>(hipModuleUnload(module));
  }
};

static size_t byte_mismatches(
    const std::vector<uint8_t>& a, const std::vector<uint8_t>& b) {
  if (a.size() != b.size()) throw std::runtime_error("size mismatch");
  size_t result = 0;
  for (size_t i = 0; i < a.size(); ++i) result += a[i] != b[i];
  return result;
}

int main(int argc, char** argv) {
  try {
    if (argc != 7) {
      std::cerr << "usage: " << argv[0]
                << " CONTROL_GATEUP.hsaco CONTROL_SILU.hsaco"
                   " FUSED_GATEUP_SILU.hsaco QUANT.hsaco CAPTURE_DIR"
                   " ITERATIONS\n";
      return 2;
    }
    const int iterations = std::stoi(argv[6]);
    if (iterations <= 0) throw std::runtime_error("iterations must be positive");

    hipDeviceProp_t properties{};
    HIP_CHECK(hipGetDeviceProperties(&properties, 0));
    if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0)
      throw std::runtime_error("refusing non-gfx950 device");

    const std::string capture = argv[5];
    auto hidden = read_binary(capture + "/hidden_states_fp8.bin");
    auto hidden_scale = read_binary(capture + "/hidden_states_scale_f32.bin");
    auto weights = read_binary(capture + "/selected_w1_fp8.bin");
    auto weight_scale = read_binary(capture + "/selected_w1_scale_f32.bin");
    auto topk_ids = read_binary(capture + "/compact_topk_ids_i32.bin");
    if (hidden.size() != 2048 || hidden_scale.size() != 16 * sizeof(float) ||
        weights.size() != 9 * 1024 * 2048 ||
        weight_scale.size() != 9 * 8 * 16 * sizeof(float) ||
        topk_ids.size() != 9 * sizeof(int32_t))
      throw std::runtime_error("capture binary size mismatch");

    constexpr int kRows = 9;
    int rows = kRows;
    constexpr size_t workspace_bytes = kRows * 1024 * sizeof(float);
    constexpr size_t fp8_bytes = kRows * 512;
    constexpr size_t scale_bytes = kRows * 4 * sizeof(float);
    DeviceBuffer d_hidden(hidden.size()), d_hidden_scale(hidden_scale.size());
    DeviceBuffer d_weights(weights.size()), d_weight_scale(weight_scale.size());
    DeviceBuffer d_topk_ids(topk_ids.size());
    DeviceBuffer d_control_workspace(workspace_bytes);
    DeviceBuffer d_candidate_workspace(workspace_bytes);
    DeviceBuffer d_control_fp8(fp8_bytes), d_candidate_fp8(fp8_bytes);
    DeviceBuffer d_control_scale(scale_bytes), d_candidate_scale(scale_bytes);
    HIP_CHECK(hipMemcpy(d_hidden.pointer, hidden.data(), hidden.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_hidden_scale.pointer, hidden_scale.data(), hidden_scale.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_weights.pointer, weights.data(), weights.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_weight_scale.pointer, weight_scale.data(), weight_scale.size(), hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_topk_ids.pointer, topk_ids.data(), topk_ids.size(), hipMemcpyHostToDevice));

    ModuleFunction control_gateup(argv[1], "qwen36_moe_gate_up_fp8_mfma_gfx950");
    ModuleFunction control_silu(argv[2], "qwen36_moe_silu_mul_quant_fp8_gfx950");
    ModuleFunction fused_gateup_silu(argv[3], "qwen36_moe_gate_up_silu_bf16_m1_gfx950");
    ModuleFunction quant(argv[4], "qwen36_moe_quant_bf16_fp8_m1_gfx950");

    auto launch_control = [&]() {
      void* workspace = d_control_workspace.pointer;
      void* gateup_args[] = {&d_hidden.pointer, &d_hidden_scale.pointer,
                             &d_weights.pointer, &d_weight_scale.pointer,
                             &d_topk_ids.pointer, &workspace};
      HIP_CHECK(hipModuleLaunchKernel(control_gateup.function, 576, 1, 1, 64, 1, 1,
                                      0, nullptr, gateup_args, nullptr));
      void* fp8 = d_control_fp8.pointer;
      void* scale = d_control_scale.pointer;
      void* silu_args[] = {&workspace, &fp8, &scale, &rows};
      HIP_CHECK(hipModuleLaunchKernel(control_silu.function, rows, 1, 1, 64, 1, 1,
                                      0, nullptr, silu_args, nullptr));
    };
    auto launch_candidate = [&]() {
      void* workspace = d_candidate_workspace.pointer;
      void* gateup_args[] = {&d_hidden.pointer, &d_hidden_scale.pointer,
                             &d_weights.pointer, &d_weight_scale.pointer,
                             &d_topk_ids.pointer, &workspace};
      HIP_CHECK(hipModuleLaunchKernel(fused_gateup_silu.function, 288, 1, 1, 128, 1, 1,
                                      0, nullptr, gateup_args, nullptr));
      void* fp8 = d_candidate_fp8.pointer;
      void* scale = d_candidate_scale.pointer;
      void* quant_args[] = {&workspace, &fp8, &scale, &rows};
      HIP_CHECK(hipModuleLaunchKernel(quant.function, rows, 1, 1, 64, 1, 1,
                                      0, nullptr, quant_args, nullptr));
    };

    for (int i = 0; i < 10; ++i) {
      launch_control();
      launch_candidate();
    }
    HIP_CHECK(hipDeviceSynchronize());
    launch_control();
    launch_candidate();
    HIP_CHECK(hipDeviceSynchronize());
    std::vector<uint8_t> control_fp8(fp8_bytes), candidate_fp8(fp8_bytes);
    std::vector<uint8_t> control_scale(scale_bytes), candidate_scale(scale_bytes);
    HIP_CHECK(hipMemcpy(control_fp8.data(), d_control_fp8.pointer, fp8_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(candidate_fp8.data(), d_candidate_fp8.pointer, fp8_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(control_scale.data(), d_control_scale.pointer, scale_bytes,
                        hipMemcpyDeviceToHost));
    HIP_CHECK(hipMemcpy(candidate_scale.data(), d_candidate_scale.pointer, scale_bytes,
                        hipMemcpyDeviceToHost));

    auto measure = [&](auto&& launch) {
      hipEvent_t start{}, stop{};
      HIP_CHECK(hipEventCreate(&start));
      HIP_CHECK(hipEventCreate(&stop));
      std::vector<float> timings;
      timings.reserve(iterations);
      for (int i = 0; i < iterations; ++i) {
        HIP_CHECK(hipEventRecord(start));
        launch();
        HIP_CHECK(hipEventRecord(stop));
        HIP_CHECK(hipEventSynchronize(stop));
        float milliseconds = 0;
        HIP_CHECK(hipEventElapsedTime(&milliseconds, start, stop));
        timings.push_back(milliseconds * 1000.0f);
      }
      HIP_CHECK(hipEventDestroy(start));
      HIP_CHECK(hipEventDestroy(stop));
      std::sort(timings.begin(), timings.end());
      return timings[timings.size() / 2];
    };

    const float candidate_a_us = measure(launch_candidate);
    const float control_us = measure(launch_control);
    const float candidate_b_us = measure(launch_candidate);
    std::cout << "architecture=" << properties.gcnArchName << "\n"
              << "fp8_byte_mismatches="
              << byte_mismatches(control_fp8, candidate_fp8) << "/"
              << fp8_bytes << "\n"
              << "scale_byte_mismatches="
              << byte_mismatches(control_scale, candidate_scale) << "/"
              << scale_bytes << "\n"
              << "control_fp8_fnv1a64=" << std::hex
              << fnv1a64(control_fp8.data(), control_fp8.size()) << "\n"
              << "candidate_fp8_fnv1a64="
              << fnv1a64(candidate_fp8.data(), candidate_fp8.size()) << std::dec
              << "\n"
              << "candidate_a_median_us=" << candidate_a_us << "\n"
              << "control_median_us=" << control_us << "\n"
              << "candidate_b_median_us=" << candidate_b_us << "\n";
    return control_fp8 == candidate_fp8 && control_scale == candidate_scale ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 2;
  }
}
