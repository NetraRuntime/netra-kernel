// SPDX-License-Identifier: MIT
#include "../../../../runtime/gfx950/attention/verify/dsv4_dspark_expand_metadata_bridge.h"

#include <hip/hip_runtime.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <numeric>
#include <random>
#include <vector>

namespace {

void check(hipError_t error, const char* operation) {
  if (error == hipSuccess) return;
  std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(error));
  std::exit(2);
}

bool run_case(
    uint32_t batch,
    const std::vector<int32_t>& extensions,
    uint32_t padded_tokens,
    bool pass_starts,
    hipStream_t stream) {
  const uint32_t real_tokens = static_cast<uint32_t>(
      std::accumulate(extensions.begin(), extensions.end(), int64_t{0}));
  std::vector<int64_t> req(batch);
  std::vector<int64_t> seq(batch);
  std::vector<int32_t> starts(batch);
  uint32_t cursor = 0;
  for (uint32_t i = 0; i < batch; ++i) {
    req[i] = (int64_t{1} << 40) + 1000 + static_cast<int64_t>(i * 7);
    seq[i] = 128 + static_cast<int32_t>(i * 13 + extensions[i]);
    starts[i] = static_cast<int32_t>(cursor);
    cursor += static_cast<uint32_t>(extensions[i]);
  }
  std::vector<int32_t> causal_ref(padded_tokens);
  std::vector<int64_t> repeated_ref(padded_tokens);
  for (uint32_t r = 0; r < batch; ++r) {
    for (int32_t j = 0; j < extensions[r]; ++j) {
      uint32_t t = static_cast<uint32_t>(starts[r] + j);
      causal_ref[t] = seq[r] - extensions[r] + 1 + j;
      repeated_ref[t] = req[r];
    }
  }
  for (uint32_t t = real_tokens; t < padded_tokens; ++t) {
    causal_ref[t] = 1;
    repeated_ref[t] = req.back();
  }

  int64_t *d_req = nullptr, *d_repeated = nullptr;
  int64_t *d_seq = nullptr;
  int32_t *d_ext = nullptr, *d_starts = nullptr;
  int32_t *d_causal = nullptr;
  check(hipMalloc(&d_req, batch * sizeof(int64_t)), "hipMalloc(req)");
  check(hipMalloc(&d_seq, batch * sizeof(int64_t)), "hipMalloc(seq)");
  check(hipMalloc(&d_ext, batch * sizeof(int32_t)), "hipMalloc(ext)");
  check(hipMalloc(&d_starts, batch * sizeof(int32_t)), "hipMalloc(starts)");
  check(hipMalloc(&d_causal, padded_tokens * sizeof(int32_t)), "hipMalloc(causal)");
  check(hipMalloc(&d_repeated, padded_tokens * sizeof(int64_t)), "hipMalloc(repeated)");
  check(hipMemcpy(d_req, req.data(), batch * sizeof(int64_t), hipMemcpyHostToDevice), "copy(req)");
  check(hipMemcpy(d_seq, seq.data(), batch * sizeof(int64_t), hipMemcpyHostToDevice), "copy(seq)");
  check(hipMemcpy(d_ext, extensions.data(), batch * sizeof(int32_t), hipMemcpyHostToDevice), "copy(ext)");
  check(hipMemcpy(d_starts, starts.data(), batch * sizeof(int32_t), hipMemcpyHostToDevice), "copy(starts)");

  int status = netra_dsv4_dspark_expand_metadata_launch(
      d_causal, d_repeated, d_req, d_seq, d_ext,
      pass_starts ? d_starts : nullptr, batch, real_tokens, padded_tokens, stream);
  if (status != 0) {
    std::fprintf(stderr, "launch failed: %s\n", netra_dsv4_dspark_expand_metadata_last_error());
    return false;
  }
  check(hipStreamSynchronize(stream), "sync(case)");
  std::vector<int32_t> causal(padded_tokens);
  std::vector<int64_t> repeated(padded_tokens);
  check(hipMemcpy(causal.data(), d_causal, padded_tokens * sizeof(int32_t), hipMemcpyDeviceToHost), "copy(causal)");
  check(hipMemcpy(repeated.data(), d_repeated, padded_tokens * sizeof(int64_t), hipMemcpyDeviceToHost), "copy(repeated)");
  bool exact = causal == causal_ref && repeated == repeated_ref;
  if (!exact) {
    for (uint32_t t = 0; t < padded_tokens; ++t) {
      if (causal[t] != causal_ref[t] || repeated[t] != repeated_ref[t]) {
        std::fprintf(stderr, "case batch=%u token=%u got=(%d,%lld) ref=(%d,%lld)\n",
            batch, t, causal[t], static_cast<long long>(repeated[t]), causal_ref[t],
            static_cast<long long>(repeated_ref[t]));
        break;
      }
    }
  }
  check(hipFree(d_repeated), "hipFree(repeated)");
  check(hipFree(d_causal), "hipFree(causal)");
  check(hipFree(d_starts), "hipFree(starts)");
  check(hipFree(d_ext), "hipFree(ext)");
  check(hipFree(d_seq), "hipFree(seq)");
  check(hipFree(d_req), "hipFree(req)");
  return exact;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) {
    std::fprintf(stderr, "usage: %s CODE_OBJECT\n", argv[0]);
    return 2;
  }
  int status = netra_dsv4_dspark_expand_metadata_load(argv[1]);
  if (status != 0) {
    std::fprintf(stderr, "load failed: %s\n", netra_dsv4_dspark_expand_metadata_last_error());
    return 2;
  }
  hipStream_t stream = nullptr;
  check(hipStreamCreate(&stream), "hipStreamCreate");
  bool exact = true;
  for (uint32_t batch : {1u, 2u, 16u, 32u, 64u, 128u, 256u}) {
    exact &= run_case(batch, std::vector<int32_t>(batch, 5), batch * 5, false, stream);
    exact &= run_case(
        batch,
        std::vector<int32_t>(batch, 5),
        std::min<uint32_t>(1536, batch * 5 + 13),
        false,
        stream);
    exact &= run_case(batch, std::vector<int32_t>(batch, 6), batch * 6, false, stream);
    exact &= run_case(
        batch,
        std::vector<int32_t>(batch, 6),
        std::min<uint32_t>(1536, batch * 6 + 13),
        false,
        stream);
    std::vector<int32_t> ragged(batch);
    for (uint32_t i = 0; i < batch; ++i) ragged[i] = 1 + static_cast<int32_t>((i * 5 + 3) % 6);
    uint32_t real = static_cast<uint32_t>(std::accumulate(ragged.begin(), ragged.end(), int64_t{0}));
    exact &= run_case(batch, ragged, real, true, stream);
    exact &= run_case(batch, ragged, std::min<uint32_t>(1536, real + 17), true, stream);
  }

  constexpr uint32_t batch = 64;
  constexpr uint32_t tokens = batch * 6;
  std::vector<int64_t> req(batch);
  std::vector<int64_t> seq(batch);
  std::vector<int32_t> ext(batch, 6);
  for (uint32_t i = 0; i < batch; ++i) { req[i] = i; seq[i] = 4096 + i; }
  int64_t *d_req = nullptr, *d_repeated = nullptr;
  int64_t *d_seq = nullptr;
  int32_t *d_ext = nullptr;
  int32_t *d_causal = nullptr;
  check(hipMalloc(&d_req, batch * sizeof(int64_t)), "hipMalloc(bench req)");
  check(hipMalloc(&d_seq, batch * sizeof(int64_t)), "hipMalloc(bench seq)");
  check(hipMalloc(&d_ext, batch * 4), "hipMalloc(bench ext)");
  check(hipMalloc(&d_causal, tokens * 4), "hipMalloc(bench causal)");
  check(hipMalloc(&d_repeated, tokens * sizeof(int64_t)), "hipMalloc(bench repeated)");
  check(hipMemcpy(d_req, req.data(), batch * sizeof(int64_t), hipMemcpyHostToDevice), "copy(bench req)");
  check(hipMemcpy(d_seq, seq.data(), batch * sizeof(int64_t), hipMemcpyHostToDevice), "copy(bench seq)");
  check(hipMemcpy(d_ext, ext.data(), batch * 4, hipMemcpyHostToDevice), "copy(bench ext)");
  for (int i = 0; i < 20; ++i)
    netra_dsv4_dspark_expand_metadata_launch(d_causal, d_repeated, d_req, d_seq, d_ext, nullptr, batch, tokens, tokens, stream);
  check(hipStreamSynchronize(stream), "sync(warmup)");
  hipEvent_t begin = nullptr, end = nullptr;
  check(hipEventCreate(&begin), "event(begin)");
  check(hipEventCreate(&end), "event(end)");
  constexpr int iterations = 2000;
  check(hipEventRecord(begin, stream), "record(begin)");
  for (int i = 0; i < iterations; ++i)
    netra_dsv4_dspark_expand_metadata_launch(d_causal, d_repeated, d_req, d_seq, d_ext, nullptr, batch, tokens, tokens, stream);
  check(hipEventRecord(end, stream), "record(end)");
  check(hipEventSynchronize(end), "sync(end)");
  float elapsed_ms = 0;
  check(hipEventElapsedTime(&elapsed_ms, begin, end), "elapsed");
  std::printf("{\"target\":\"gfx950\",\"batch\":%u,\"tokens\":%u,\"iterations\":%d,\"mean_us\":%.6f,\"exact\":%s}\n",
      batch, tokens, iterations, elapsed_ms * 1000.0f / iterations, exact ? "true" : "false");
  check(hipEventDestroy(end), "destroy(end)");
  check(hipEventDestroy(begin), "destroy(begin)");
  check(hipFree(d_repeated), "hipFree(bench repeated)");
  check(hipFree(d_causal), "hipFree(bench causal)");
  check(hipFree(d_ext), "hipFree(bench ext)");
  check(hipFree(d_seq), "hipFree(bench seq)");
  check(hipFree(d_req), "hipFree(bench req)");
  check(hipStreamDestroy(stream), "hipStreamDestroy");
  (void)netra_dsv4_dspark_expand_metadata_unload();
  return exact ? 0 : 1;
}
