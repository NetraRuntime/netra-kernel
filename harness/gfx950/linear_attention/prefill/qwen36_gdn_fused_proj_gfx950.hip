// SPDX-License-Identifier: MIT
#include "../../../../runtime/gfx950/linear_attention/prefill/qwen36_gdn_fused_proj_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

namespace {

constexpr size_t kQkvz = 12288;
constexpr size_t kQkv = 8192;
constexpr size_t kZ = 4096;
constexpr size_t kBa = 64;
constexpr size_t kB = 32;

void check(hipError_t error, const char* operation) {
  if (error == hipSuccess) return;
  std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(error));
  std::exit(2);
}

std::vector<uint32_t> check_rows(uint32_t rows) {
  std::vector<uint32_t> values = {0, 174761, 174762, 174763, rows - 1};
  values.erase(
      std::remove_if(values.begin(), values.end(), [rows](uint32_t row) { return row >= rows; }),
      values.end());
  std::sort(values.begin(), values.end());
  values.erase(std::unique(values.begin(), values.end()), values.end());
  return values;
}

void make_patterns(
    uint32_t row, std::vector<uint16_t>& qkvz, std::vector<uint16_t>& ba) {
  for (size_t i = 0; i < qkvz.size(); ++i)
    qkvz[i] = static_cast<uint16_t>((i * 17 + static_cast<size_t>(row) * 13 + 1) & 0xffff);
  for (size_t i = 0; i < ba.size(); ++i)
    ba[i] = static_cast<uint16_t>((i * 29 + static_cast<size_t>(row) * 7 + 3) & 0xffff);
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 2 || argc > 4) {
    std::fprintf(stderr, "usage: %s CODE_OBJECT [ROWS] [ITERATIONS]\n", argv[0]);
    return 2;
  }
  const uint32_t rows = argc >= 3 ? static_cast<uint32_t>(std::strtoul(argv[2], nullptr, 10)) : 32768;
  const int iterations = argc >= 4 ? std::atoi(argv[3]) : 50;
  if (rows == 0 || iterations <= 0) return 2;

  uint16_t* qkvz = nullptr;
  uint16_t* ba = nullptr;
  uint16_t* qkv = nullptr;
  uint16_t* z = nullptr;
  uint16_t* b = nullptr;
  uint16_t* a = nullptr;
  check(hipMalloc(&qkvz, static_cast<size_t>(rows) * kQkvz * sizeof(uint16_t)), "hipMalloc(qkvz)");
  check(hipMalloc(&ba, static_cast<size_t>(rows) * kBa * sizeof(uint16_t)), "hipMalloc(ba)");
  check(hipMalloc(&qkv, static_cast<size_t>(rows) * kQkv * sizeof(uint16_t)), "hipMalloc(qkv)");
  check(hipMalloc(&z, static_cast<size_t>(rows) * kZ * sizeof(uint16_t)), "hipMalloc(z)");
  check(hipMalloc(&b, static_cast<size_t>(rows) * kB * sizeof(uint16_t)), "hipMalloc(b)");
  check(hipMalloc(&a, static_cast<size_t>(rows) * kB * sizeof(uint16_t)), "hipMalloc(a)");

  hipStream_t stream = nullptr;
  check(hipStreamCreate(&stream), "hipStreamCreate");
  check(hipMemsetAsync(qkvz, 0, static_cast<size_t>(rows) * kQkvz * sizeof(uint16_t), stream), "hipMemset(qkvz)");
  check(hipMemsetAsync(ba, 0, static_cast<size_t>(rows) * kBa * sizeof(uint16_t), stream), "hipMemset(ba)");
  check(hipMemsetAsync(qkv, 0xcd, static_cast<size_t>(rows) * kQkv * sizeof(uint16_t), stream), "hipMemset(qkv)");
  check(hipMemsetAsync(z, 0xcd, static_cast<size_t>(rows) * kZ * sizeof(uint16_t), stream), "hipMemset(z)");
  check(hipMemsetAsync(b, 0xcd, static_cast<size_t>(rows) * kB * sizeof(uint16_t), stream), "hipMemset(b)");
  check(hipMemsetAsync(a, 0xcd, static_cast<size_t>(rows) * kB * sizeof(uint16_t), stream), "hipMemset(a)");

  std::vector<uint16_t> host_qkvz(kQkvz);
  std::vector<uint16_t> host_ba(kBa);
  const auto selected_rows = check_rows(rows);
  for (uint32_t row : selected_rows) {
    make_patterns(row, host_qkvz, host_ba);
    check(hipMemcpyAsync(qkvz + static_cast<size_t>(row) * kQkvz, host_qkvz.data(),
                         host_qkvz.size() * sizeof(uint16_t), hipMemcpyHostToDevice, stream),
          "hipMemcpyAsync(qkvz row)");
    check(hipMemcpyAsync(ba + static_cast<size_t>(row) * kBa, host_ba.data(),
                         host_ba.size() * sizeof(uint16_t), hipMemcpyHostToDevice, stream),
          "hipMemcpyAsync(ba row)");
  }

  int status = netra_qwen36_gdn_fused_proj_bf16_load(argv[1]);
  if (status != 0) {
    std::fprintf(stderr, "load failed: %s\n", netra_qwen36_gdn_fused_proj_bf16_last_error());
    return 2;
  }
  status = netra_qwen36_gdn_fused_proj_bf16_launch(qkv, z, b, a, qkvz, ba, rows, stream);
  if (status != 0) {
    std::fprintf(stderr, "launch failed: %s\n", netra_qwen36_gdn_fused_proj_bf16_last_error());
    return 2;
  }
  check(hipStreamSynchronize(stream), "hipStreamSynchronize(correctness)");

  bool exact = true;
  std::vector<uint16_t> got_qkv(kQkv);
  std::vector<uint16_t> got_z(kZ);
  std::vector<uint16_t> got_b(kB);
  std::vector<uint16_t> got_a(kB);
  for (uint32_t row : selected_rows) {
    make_patterns(row, host_qkvz, host_ba);
    check(hipMemcpy(got_qkv.data(), qkv + static_cast<size_t>(row) * kQkv,
                    got_qkv.size() * sizeof(uint16_t), hipMemcpyDeviceToHost), "hipMemcpy(qkv)");
    check(hipMemcpy(got_z.data(), z + static_cast<size_t>(row) * kZ,
                    got_z.size() * sizeof(uint16_t), hipMemcpyDeviceToHost), "hipMemcpy(z)");
    check(hipMemcpy(got_b.data(), b + static_cast<size_t>(row) * kB,
                    got_b.size() * sizeof(uint16_t), hipMemcpyDeviceToHost), "hipMemcpy(b)");
    check(hipMemcpy(got_a.data(), a + static_cast<size_t>(row) * kB,
                    got_a.size() * sizeof(uint16_t), hipMemcpyDeviceToHost), "hipMemcpy(a)");
    exact = exact && std::equal(got_qkv.begin(), got_qkv.end(), host_qkvz.begin());
    exact = exact && std::equal(got_z.begin(), got_z.end(), host_qkvz.begin() + kQkv);
    exact = exact && std::equal(got_b.begin(), got_b.end(), host_ba.begin());
    exact = exact && std::equal(got_a.begin(), got_a.end(), host_ba.begin() + kB);
  }

  for (int i = 0; i < 5; ++i) {
    status = netra_qwen36_gdn_fused_proj_bf16_launch(qkv, z, b, a, qkvz, ba, rows, stream);
    if (status != 0) return 2;
  }
  check(hipStreamSynchronize(stream), "hipStreamSynchronize(warmup)");
  hipEvent_t begin = nullptr;
  hipEvent_t end = nullptr;
  check(hipEventCreate(&begin), "hipEventCreate(begin)");
  check(hipEventCreate(&end), "hipEventCreate(end)");
  check(hipEventRecord(begin, stream), "hipEventRecord(begin)");
  for (int i = 0; i < iterations; ++i) {
    status = netra_qwen36_gdn_fused_proj_bf16_launch(qkv, z, b, a, qkvz, ba, rows, stream);
    if (status != 0) return 2;
  }
  check(hipEventRecord(end, stream), "hipEventRecord(end)");
  check(hipEventSynchronize(end), "hipEventSynchronize(end)");
  float elapsed_ms = 0.0f;
  check(hipEventElapsedTime(&elapsed_ms, begin, end), "hipEventElapsedTime");

  std::printf(
      "{\"target\":\"gfx950\",\"rows\":%u,\"workgroup_size\":256,"
      "\"iterations\":%d,\"mean_us\":%.6f,\"exact\":%s}\n",
      rows, iterations, elapsed_ms * 1000.0f / iterations, exact ? "true" : "false");

  check(hipEventDestroy(begin), "hipEventDestroy(begin)");
  check(hipEventDestroy(end), "hipEventDestroy(end)");
  check(hipStreamDestroy(stream), "hipStreamDestroy");
  check(hipFree(a), "hipFree(a)");
  check(hipFree(b), "hipFree(b)");
  check(hipFree(z), "hipFree(z)");
  check(hipFree(qkv), "hipFree(qkv)");
  check(hipFree(ba), "hipFree(ba)");
  check(hipFree(qkvz), "hipFree(qkvz)");
  (void)netra_qwen36_gdn_fused_proj_bf16_unload();
  return exact ? 0 : 1;
}
