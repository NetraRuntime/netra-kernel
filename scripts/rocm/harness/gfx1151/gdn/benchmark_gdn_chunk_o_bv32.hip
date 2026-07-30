// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <array>
#include <cstdint>
#include <cstdlib>
#include <iostream>

#include "runtime/gfx1151/common/kernargs.h"
#include "runtime/gfx1151/common/launch.h"

namespace {
constexpr uint32_t kTokens = 8192;
constexpr uint32_t kChunks = kTokens / 64;

int check(hipError_t status, int base) {
  return status == hipSuccess ? 0 : base + static_cast<int>(status);
}
}  // namespace

int main(int argc, char** argv) {
  if (argc < 2 || argc > 3) {
    std::cerr << "usage: " << argv[0] << " HSACO [ITERATIONS]\n";
    return 2;
  }
  const int iterations = argc == 3 ? std::atoi(argv[2]) : 1;
  if (iterations < 1) return 2;

  hipModule_t module{};
  hipFunction_t function{};
  int status = check(hipModuleLoad(&module, argv[1]), 10);
  if (status) return status;
  status = check(hipModuleGetFunction(
      &function, module, "gdn_chunk_o_bv32_gfx1151"), 20);
  if (status) return status;

  constexpr std::array<size_t, 8> sizes{
      1ULL * kTokens * 16 * 128 * 2,
      1ULL * kTokens * 16 * 128 * 2,
      1ULL * kTokens * 32 * 128 * 2,
      1ULL * kChunks * 32 * 128 * 128 * 2,
      1ULL * kTokens * 32 * 4,
      1ULL * kTokens * 32 * 128 * 2,
      2 * sizeof(int32_t),
      2ULL * kChunks * sizeof(int32_t),
  };
  std::array<void*, sizes.size()> buffers{};
  for (size_t i = 0; i < buffers.size(); ++i) {
    status = check(hipMalloc(&buffers[i], sizes[i]), 30);
    if (status) return status;
    status = check(hipMemset(buffers[i], 0, sizes[i]), 40);
    if (status) return status;
  }
  const int32_t cu_seqlens[2]{0, static_cast<int32_t>(kTokens)};
  std::array<int32_t, 2 * kChunks> chunk_indices{};
  for (uint32_t chunk = 0; chunk < kChunks; ++chunk) {
    chunk_indices[2 * chunk] = 0;
    chunk_indices[2 * chunk + 1] = static_cast<int32_t>(chunk);
  }
  status = check(hipMemcpy(
      buffers[6], cu_seqlens, sizeof(cu_seqlens), hipMemcpyHostToDevice), 50);
  if (status) return status;
  status = check(hipMemcpy(
      buffers[7], chunk_indices.data(), sizeof(chunk_indices),
      hipMemcpyHostToDevice), 60);
  if (status) return status;

  hipStream_t stream{};
  status = check(hipStreamCreate(&stream), 70);
  if (status) return status;
  hipEvent_t begin{}, end{};
  hipEventCreate(&begin);
  hipEventCreate(&end);
  netra::gfx1151::GdnChunkOArgs args{
      buffers[0], buffers[1], buffers[2], buffers[3], buffers[4],
      buffers[5], buffers[6], buffers[7], 0.08838834764831845f, kTokens};
  hipEventRecord(begin, stream);
  for (int i = 0; i < iterations; ++i) {
    status = check(netra::gfx1151::launch_3d(
        function, 4, 256, 32, 64, stream, args), 80);
    if (status) return status;
  }
  hipEventRecord(end, stream);
  hipEventSynchronize(end);
  float elapsed_ms = 0.0f;
  hipEventElapsedTime(&elapsed_ms, begin, end);
  std::cout << "gfx1151 measured raw GDN chunk-o total_ms=" << elapsed_ms
            << " mean_ms=" << elapsed_ms / iterations << "\n";

  hipEventDestroy(begin);
  hipEventDestroy(end);
  hipStreamDestroy(stream);
  for (void* buffer : buffers) hipFree(buffer);
  hipModuleUnload(module);
  return 0;
}
