// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#define HIP_CHECK(call) do { hipError_t e=(call); if(e!=hipSuccess){std::fprintf(stderr,"%s:%d %s\n",__FILE__,__LINE__,hipGetErrorString(e)); return 1;} } while(0)

static uint16_t to_bf16(float x) {
  uint32_t bits;
  std::memcpy(&bits, &x, sizeof(bits));
  bits += 0x7fffU + ((bits >> 16U) & 1U);
  return static_cast<uint16_t>(bits >> 16U);
}

static float from_bf16(uint16_t x) {
  uint32_t bits = static_cast<uint32_t>(x) << 16U;
  float value;
  std::memcpy(&value, &bits, sizeof(value));
  return value;
}

struct alignas(8) StandaloneArgs {
  void* input;
  void* weight;
  void* output;
  float epsilon;
  uint32_t padding;
};
struct alignas(8) FusedArgs {
  void* input;
  void* residual;
  void* weight;
  float epsilon;
  uint32_t padding;
};
static_assert(sizeof(StandaloneArgs) == 32);
static_assert(sizeof(FusedArgs) == 32);

template <typename Args>
static hipError_t launch(hipFunction_t fn, Args& args, hipStream_t stream) {
  size_t size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
                    HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
                    HIP_LAUNCH_PARAM_END};
  return hipModuleLaunchKernel(fn, 1, 1, 1, 256, 1, 1, 0, stream, nullptr, config);
}

int main(int argc, char** argv) {
  if (argc != 2) {
    std::fprintf(stderr, "usage: %s qwen36.hsaco\n", argv[0]);
    return 2;
  }
  constexpr int n = 2048;
  constexpr float eps = 1.0e-6f;
  std::vector<uint16_t> hx(n), hr(n), standalone(n), fused(n), residual(n);
  std::vector<uint16_t> hw(n);
  for (int i = 0; i < n; ++i) {
    hx[i] = to_bf16(0.75f * std::sin(0.031f * i) + 0.01f * (i % 13));
    hr[i] = to_bf16(0.5f * std::cos(0.017f * i) - 0.007f * (i % 17));
    hw[i] = to_bf16(0.15f * std::sin(0.013f * i));
  }

  uint16_t *dx = nullptr, *dr = nullptr, *dout = nullptr;
  uint16_t* dw = nullptr;
  HIP_CHECK(hipMalloc(&dx, n * sizeof(uint16_t)));
  HIP_CHECK(hipMalloc(&dr, n * sizeof(uint16_t)));
  HIP_CHECK(hipMalloc(&dout, n * sizeof(uint16_t)));
  HIP_CHECK(hipMalloc(&dw, n * sizeof(uint16_t)));
  HIP_CHECK(hipMemcpy(dx, hx.data(), n * sizeof(uint16_t), hipMemcpyHostToDevice));
  HIP_CHECK(hipMemcpy(dr, hr.data(), n * sizeof(uint16_t), hipMemcpyHostToDevice));
  HIP_CHECK(hipMemcpy(dw, hw.data(), n * sizeof(uint16_t), hipMemcpyHostToDevice));

  hipModule_t module{};
  hipFunction_t standalone_fn{}, fused_fn{};
  HIP_CHECK(hipModuleLoad(&module, argv[1]));
  HIP_CHECK(hipModuleGetFunction(&standalone_fn, module, "qwen36_rmsnorm_decode_gfx1151"));
  HIP_CHECK(hipModuleGetFunction(&fused_fn, module, "qwen36_fused_add_rmsnorm_decode_gfx1151"));

  StandaloneArgs sa{dx, dw, dout, eps, 0};
  HIP_CHECK(launch(standalone_fn, sa, nullptr));
  HIP_CHECK(hipDeviceSynchronize());
  HIP_CHECK(hipMemcpy(standalone.data(), dout, n * sizeof(uint16_t), hipMemcpyDeviceToHost));

  HIP_CHECK(hipMemcpy(dx, hx.data(), n * sizeof(uint16_t), hipMemcpyHostToDevice));
  HIP_CHECK(hipMemcpy(dr, hr.data(), n * sizeof(uint16_t), hipMemcpyHostToDevice));
  FusedArgs fa{dx, dr, dw, eps, 0};
  HIP_CHECK(launch(fused_fn, fa, nullptr));
  HIP_CHECK(hipDeviceSynchronize());
  HIP_CHECK(hipMemcpy(fused.data(), dx, n * sizeof(uint16_t), hipMemcpyDeviceToHost));
  HIP_CHECK(hipMemcpy(residual.data(), dr, n * sizeof(uint16_t), hipMemcpyDeviceToHost));

  double ss_standalone = 0.0, ss_fused = 0.0;
  std::vector<double> rounded_sum(n);
  for (int i = 0; i < n; ++i) {
    const double x = from_bf16(hx[i]);
    const uint16_t sum_bits = to_bf16(from_bf16(hx[i]) + from_bf16(hr[i]));
    rounded_sum[i] = from_bf16(sum_bits);
    ss_standalone += x * x;
    ss_fused += rounded_sum[i] * rounded_sum[i];
    if (residual[i] != sum_bits) {
      std::fprintf(stderr, "residual mismatch at %d got=%04x expected=%04x\n", i, residual[i], sum_bits);
      return 3;
    }
  }
  const double inv_standalone = 1.0 / std::sqrt(ss_standalone / n + eps);
  const double inv_fused = 1.0 / std::sqrt(ss_fused / n + eps);
  double max_standalone = 0.0, max_fused = 0.0;
  int exact_standalone = 0, exact_fused = 0;
  for (int i = 0; i < n; ++i) {
    const uint16_t ref_s = to_bf16(static_cast<float>(from_bf16(hx[i]) * inv_standalone * (1.0 + from_bf16(hw[i]))));
    const uint16_t ref_f = to_bf16(static_cast<float>(rounded_sum[i] * inv_fused * (1.0 + from_bf16(hw[i]))));
    exact_standalone += standalone[i] == ref_s;
    exact_fused += fused[i] == ref_f;
    max_standalone = std::max(max_standalone, std::abs(static_cast<double>(from_bf16(standalone[i]) - from_bf16(ref_s))));
    max_fused = std::max(max_fused, std::abs(static_cast<double>(from_bf16(fused[i]) - from_bf16(ref_f))));
  }

  hipEvent_t start{}, stop{};
  HIP_CHECK(hipEventCreate(&start));
  HIP_CHECK(hipEventCreate(&stop));
  for (int i = 0; i < 100; ++i) HIP_CHECK(launch(fused_fn, fa, nullptr));
  HIP_CHECK(hipEventRecord(start));
  for (int i = 0; i < 10000; ++i) HIP_CHECK(launch(fused_fn, fa, nullptr));
  HIP_CHECK(hipEventRecord(stop));
  HIP_CHECK(hipEventSynchronize(stop));
  float elapsed_ms = 0.0f;
  HIP_CHECK(hipEventElapsedTime(&elapsed_ms, start, stop));
  std::printf("gfx1151 measured standalone_exact=%d/%d standalone_max_abs=%.9g fused_exact=%d/%d fused_max_abs=%.9g residual_exact=%d/%d fused_hip_event_us=%.6f\n",
              exact_standalone, n, max_standalone, exact_fused, n, max_fused, n, n, elapsed_ms * 1000.0f / 10000.0f);
  const bool pass = max_standalone <= 0.015625 && max_fused <= 0.015625;
  hipEventDestroy(start); hipEventDestroy(stop); hipModuleUnload(module);
  hipFree(dx); hipFree(dr); hipFree(dout); hipFree(dw);
  return pass ? 0 : 4;
}
