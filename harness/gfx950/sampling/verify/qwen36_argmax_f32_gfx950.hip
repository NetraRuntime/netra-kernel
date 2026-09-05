// SPDX-License-Identifier: MIT
#include "../../../../runtime/gfx950/sampling/verify/qwen36_argmax_f32_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>
#include <vector>

namespace {

constexpr uint32_t kRows = 16;
constexpr uint32_t kCols = 248320;
constexpr uint32_t kChunks = 128;

void check(hipError_t error, const char* operation) {
  if (error == hipSuccess) return;
  std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(error));
  std::exit(2);
}

bool greater_or_nan(float a, float b, uint32_t ia, uint32_t ib) {
  if (std::isnan(a)) {
    if (std::isnan(b)) return ia < ib;
    return true;
  }
  return a == b ? ia < ib : a > b;
}

uint32_t reference_argmax(const float* row) {
  float best = -std::numeric_limits<float>::infinity();
  uint32_t best_index = 0;
  for (uint32_t i = 0; i < kCols; ++i) {
    if (!greater_or_nan(best, row[i], best_index, i)) {
      best = row[i];
      best_index = i;
    }
  }
  return best_index;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) {
    std::fprintf(stderr, "usage: %s CODE_OBJECT\n", argv[0]);
    return 2;
  }

  std::vector<float> host_logits(static_cast<size_t>(kRows) * kCols);
  std::mt19937 generator(20260730);
  std::uniform_real_distribution<float> distribution(-40.0f, 40.0f);
  for (float& value : host_logits) value = distribution(generator);

  // Exact ordering probes: early/late ties, signed zero, infinities, and NaNs.
  host_logits[0 * kCols + 3] = 1000.0f;
  host_logits[0 * kCols + 200000] = 1000.0f;
  std::fill(
      host_logits.begin() + 1 * kCols,
      host_logits.begin() + 2 * kCols,
      -0.0f);
  host_logits[1 * kCols + 1] = 0.0f;
  host_logits[2 * kCols + 17] = std::numeric_limits<float>::infinity();
  host_logits[2 * kCols + 100000] = std::numeric_limits<float>::infinity();
  host_logits[3 * kCols + 12345] = std::numeric_limits<float>::quiet_NaN();
  host_logits[3 * kCols + 12000] = std::numeric_limits<float>::quiet_NaN();
  host_logits[4 * kCols + 0] = -std::numeric_limits<float>::infinity();

  std::vector<int64_t> reference(kRows);
  for (uint32_t row = 0; row < kRows; ++row)
    reference[row] =
        static_cast<int64_t>(reference_argmax(host_logits.data() + row * kCols));

  float* device_logits = nullptr;
  uint32_t* device_partials = nullptr;
  int64_t* device_output = nullptr;
  check(
      hipMalloc(&device_logits, host_logits.size() * sizeof(float)),
      "hipMalloc(logits)");
  check(
      hipMalloc(&device_partials, kRows * kChunks * 2 * sizeof(uint32_t)),
      "hipMalloc(partials)");
  check(hipMalloc(&device_output, kRows * sizeof(int64_t)), "hipMalloc(output)");
  check(
      hipMemcpy(
          device_logits,
          host_logits.data(),
          host_logits.size() * sizeof(float),
          hipMemcpyHostToDevice),
      "hipMemcpy(logits)");

  int status = netra_qwen36_argmax_f32_load(argv[1]);
  if (status != 0) {
    std::fprintf(
        stderr, "load failed: %s\n", netra_qwen36_argmax_f32_last_error());
    return 2;
  }
  hipStream_t stream = nullptr;
  check(hipStreamCreate(&stream), "hipStreamCreate");

  for (int i = 0; i < 20; ++i) {
    status = netra_qwen36_argmax_f32_launch(
        device_output, device_partials, device_logits, kRows, stream);
    if (status != 0) {
      std::fprintf(
          stderr, "launch failed: %s\n", netra_qwen36_argmax_f32_last_error());
      return 2;
    }
  }
  check(hipStreamSynchronize(stream), "hipStreamSynchronize(warmup)");

  hipEvent_t begin = nullptr;
  hipEvent_t end = nullptr;
  check(hipEventCreate(&begin), "hipEventCreate(begin)");
  check(hipEventCreate(&end), "hipEventCreate(end)");
  constexpr int kIterations = 1000;
  check(hipEventRecord(begin, stream), "hipEventRecord(begin)");
  for (int i = 0; i < kIterations; ++i) {
    status = netra_qwen36_argmax_f32_launch(
        device_output, device_partials, device_logits, kRows, stream);
    if (status != 0) {
      std::fprintf(
          stderr, "timed launch failed: %s\n",
          netra_qwen36_argmax_f32_last_error());
      return 2;
    }
  }
  check(hipEventRecord(end, stream), "hipEventRecord(end)");
  check(hipEventSynchronize(end), "hipEventSynchronize(end)");
  float elapsed_ms = 0.0f;
  check(hipEventElapsedTime(&elapsed_ms, begin, end), "hipEventElapsedTime");

  std::vector<int64_t> output(kRows);
  check(
      hipMemcpy(
          output.data(),
          device_output,
          output.size() * sizeof(int64_t),
          hipMemcpyDeviceToHost),
      "hipMemcpy(output)");
  bool passed = output == reference;
  if (!passed) {
    for (uint32_t row = 0; row < kRows; ++row) {
      if (output[row] != reference[row])
        std::fprintf(
            stderr,
            "row %u: output=%lld reference=%lld\n",
            row,
            static_cast<long long>(output[row]),
            static_cast<long long>(reference[row]));
    }
  }

  std::printf(
      "{\"target\":\"gfx950\",\"rows\":%u,\"cols\":%u,"
      "\"iterations\":%d,\"mean_us\":%.6f,\"exact\":%s}\n",
      kRows,
      kCols,
      kIterations,
      elapsed_ms * 1000.0f / kIterations,
      passed ? "true" : "false");

  check(hipEventDestroy(begin), "hipEventDestroy(begin)");
  check(hipEventDestroy(end), "hipEventDestroy(end)");
  check(hipStreamDestroy(stream), "hipStreamDestroy");
  check(hipFree(device_output), "hipFree(output)");
  check(hipFree(device_partials), "hipFree(partials)");
  check(hipFree(device_logits), "hipFree(logits)");
  (void)netra_qwen36_argmax_f32_unload();
  return passed ? 0 : 1;
}
