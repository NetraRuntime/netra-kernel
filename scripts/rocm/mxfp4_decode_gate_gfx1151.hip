// Launch/correctness/timing harness only. The measured kernel is raw AMDGCN
// assembly in mxfp4_decode_gate_gfx1151.s.
#include <hip/hip_runtime.h>
#include <hip/hip_bf16.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <random>
#include <string>
#include <vector>

#define CHK(x) do { hipError_t e_ = (x); if (e_ != hipSuccess) { \
  std::fprintf(stderr, "HIP error %s at line %d\n", hipGetErrorString(e_), \
               __LINE__); std::exit(1); } } while (0)

static double e2m1(uint8_t x) {
  static constexpr double lut[8] = {0, .5, 1, 1.5, 2, 3, 4, 6};
  return (x & 8) ? -lut[x & 7] : lut[x & 7];
}

static void read_exact(const char* path, void* dst, size_t bytes) {
  std::ifstream f(path, std::ios::binary);
  if (!f.read(reinterpret_cast<char*>(dst), bytes) ||
      size_t(f.gcount()) != bytes) {
    std::fprintf(stderr, "Could not read %zu bytes from %s\n", bytes, path);
    std::exit(4);
  }
}

int main(int argc, char** argv) {
  constexpr int E = 8, N = 512, K = 2048;
  constexpr int NBUF = 9;  // 9 * 4.25 MiB > the 32 MiB Infinity Cache.
  const int iters = argc > 1 ? std::atoi(argv[1]) : 200;
  const char* hsaco = argc > 2 ? argv[2] : "./mxfp4_decode_gate_gfx1151.hsaco";

  hipDeviceProp_t prop{};
  CHK(hipGetDeviceProperties(&prop, 0));
  if (std::string(prop.gcnArchName).find("gfx1151") == std::string::npos) {
    std::fprintf(stderr, "This raw code object requires gfx1151; got %s\n",
                 prop.gcnArchName);
    return 2;
  }

  const size_t packed_elems = size_t(E) * (K / 2) * N;
  const size_t scale_elems = size_t(E) * (K / 32) * N;
  const size_t out_elems = size_t(E) * N;
  std::mt19937 rng(1);
  std::uniform_int_distribution<int> nib(0, 15);
  std::uniform_int_distribution<int> exp(121, 130);
  std::uniform_real_distribution<float> act(-1.0f, 1.0f);

  std::vector<uint8_t> hp(packed_elems), hs(scale_elems);
  std::vector<uint16_t> ha_bits(K);
  std::vector<float> ha(K);
  if (argc > 4) {
    read_exact(argv[3], hp.data(), hp.size());
    read_exact(argv[4], hs.data(), hs.size());
    std::printf("using real checkpoint MXFP4 weights: %s and %s\n",
                argv[3], argv[4]);
  } else {
    for (auto& x : hp) x = uint8_t(nib(rng) | (nib(rng) << 4));
    for (auto& x : hs) x = uint8_t(exp(rng));
  }
  for (int k = 0; k < K; ++k) {
    __hip_bfloat16 b = __float2bfloat16(act(rng));
    std::memcpy(&ha_bits[k], &b, 2);
    ha[k] = __bfloat162float(b);
  }

  uint8_t *dp[NBUF]{}, *ds[NBUF]{};
  __hip_bfloat16* da{};
  float* dy{};
  for (int b = 0; b < NBUF; ++b) {
    CHK(hipMalloc(&dp[b], packed_elems));
    CHK(hipMalloc(&ds[b], scale_elems));
    CHK(hipMemcpy(dp[b], hp.data(), packed_elems, hipMemcpyHostToDevice));
    CHK(hipMemcpy(ds[b], hs.data(), scale_elems, hipMemcpyHostToDevice));
  }
  CHK(hipMalloc(&da, K * 2));
  CHK(hipMalloc(&dy, out_elems * sizeof(float)));
  CHK(hipMemcpy(da, ha_bits.data(), K * 2, hipMemcpyHostToDevice));

  hipModule_t mod{};
  hipFunction_t fn{};
  CHK(hipModuleLoad(&mod, hsaco));
  CHK(hipModuleGetFunction(&fn, mod, "mxfp4_decode_gate_gfx1151"));

  auto launch = [&](int b) {
    void* args[] = {&dp[b], &ds[b], &da, &dy};
    CHK(hipMemsetAsync(dy, 0, out_elems * sizeof(float)));
    CHK(hipModuleLaunchKernel(fn, 1, E * 2, 1, 128, 1, 1, 0, nullptr,
                              args, nullptr));
  };

  launch(0);
  CHK(hipDeviceSynchronize());
  std::vector<float> got(out_elems);
  CHK(hipMemcpy(got.data(), dy, got.size() * sizeof(float),
                hipMemcpyDeviceToHost));

  double max_abs = 0, max_rel = 0;
  int worst_e = -1, worst_n = -1;
  for (int e = 0; e < E; ++e) {
    for (int n = 0; n < N; ++n) {
      double ref = 0;
      for (int k = 0; k < K; ++k) {
        const uint8_t byte = hp[(size_t(e) * (K / 2) + k / 2) * N + n];
        const uint8_t code = (k & 1) ? byte >> 4 : byte & 15;
        const int se = hs[(size_t(e) * (K / 32) + k / 32) * N + n];
        ref += e2m1(code) * std::ldexp(double(ha[k]), se - 127);
      }
      const double ae = std::abs(double(got[e * N + n]) - ref);
      const double re = ae / std::max(std::abs(ref), 1e-12);
      if (ae > max_abs) { max_abs = ae; worst_e = e; worst_n = n; }
      max_rel = std::max(max_rel, re);
    }
  }
  std::printf("gfx1151 raw ASM correctness vs fp64: max_abs=%.6e "
              "max_rel=%.6e worst=(expert=%d,n=%d) %s\n",
              max_abs, max_rel, worst_e, worst_n,
              max_rel < 1e-3 ? "PASS" : "FAIL");
  if (max_rel >= 1e-3) return 3;

  for (int i = 0; i < 30; ++i) launch(i % NBUF);
  CHK(hipDeviceSynchronize());
  hipEvent_t begin{}, end{};
  CHK(hipEventCreate(&begin));
  CHK(hipEventCreate(&end));
  CHK(hipEventRecord(begin));
  for (int i = 0; i < iters; ++i) launch(i % NBUF);
  CHK(hipEventRecord(end));
  CHK(hipEventSynchronize(end));
  float total_ms = 0;
  CHK(hipEventElapsedTime(&total_ms, begin, end));
  const double us = total_ms * 1000.0 / iters;
  const double bytes = double(packed_elems + scale_elems + K * 2 +
                              out_elems * sizeof(float));
  std::printf("gfx1151 raw ASM MXFP4 decode gate/up E=8 N=512 K=2048: "
              "%.3f us, %.1f GB/s (measured, rotating %.2f MiB)\n",
              us, bytes / (us * 1e-6) / 1e9,
              NBUF * (packed_elems + scale_elems) / double(1 << 20));
  return 0;
}
