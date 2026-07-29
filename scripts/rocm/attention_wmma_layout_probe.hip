// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

#define HIP_CHECK(expr) do { hipError_t status = (expr); if (status != hipSuccess) { std::fprintf(stderr, "%s failed: %s\n", #expr, hipGetErrorString(status)); std::exit(1); } } while (0)

struct Args { void* a; void* b; void* raw_c; };

static uint16_t float_to_bf16(float value) {
  union { float f; uint32_t u; } bits{value};
  const uint32_t lsb = (bits.u >> 16) & 1;
  bits.u += 0x7fff + lsb;
  return static_cast<uint16_t>(bits.u >> 16);
}

int main(int argc, char** argv) {
  const char* hsaco = argc > 1 ? argv[1] : "build/sglang/attention_wmma_layout_probe_gfx1151.hsaco";
  std::vector<uint16_t> a(256, float_to_bf16(0.0f));
  std::vector<uint16_t> b_col(256);
  for (int row = 0; row < 16; ++row) a[row * 16 + row] = float_to_bf16(1.0f);
  for (int col = 0; col < 16; ++col)
    for (int k = 0; k < 16; ++k)
      b_col[col * 16 + k] = float_to_bf16(float(10 * k + col));

  void *da = nullptr, *db = nullptr, *dc = nullptr;
  HIP_CHECK(hipMalloc(&da, 512));
  HIP_CHECK(hipMalloc(&db, 512));
  HIP_CHECK(hipMalloc(&dc, 32 * 8 * sizeof(float)));
  HIP_CHECK(hipMemcpy(da, a.data(), 512, hipMemcpyHostToDevice));
  HIP_CHECK(hipMemcpy(db, b_col.data(), 512, hipMemcpyHostToDevice));
  HIP_CHECK(hipMemset(dc, 0, 32 * 8 * sizeof(float)));

  hipModule_t module;
  hipFunction_t kernel;
  HIP_CHECK(hipModuleLoad(&module, hsaco));
  HIP_CHECK(hipModuleGetFunction(&kernel, module, "attention_wmma_layout_probe_gfx1151"));
  Args args{da, db, dc};
  size_t arg_size = sizeof(args);
  void* config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args, HIP_LAUNCH_PARAM_BUFFER_SIZE, &arg_size, HIP_LAUNCH_PARAM_END};
  HIP_CHECK(hipModuleLaunchKernel(kernel, 1, 1, 1, 32, 1, 1, 0, nullptr, nullptr, config));
  HIP_CHECK(hipDeviceSynchronize());

  std::vector<float> raw(32 * 8);
  HIP_CHECK(hipMemcpy(raw.data(), dc, raw.size() * sizeof(float), hipMemcpyDeviceToHost));
  for (int lane = 0; lane < 32; ++lane) {
    std::printf("lane %02d:", lane);
    for (int reg = 0; reg < 8; ++reg) std::printf(" %7.0f", raw[lane * 8 + reg]);
    std::printf("\n");
  }
  HIP_CHECK(hipModuleUnload(module));
  HIP_CHECK(hipFree(da)); HIP_CHECK(hipFree(db)); HIP_CHECK(hipFree(dc));
  return 0;
}
