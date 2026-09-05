// SPDX-License-Identifier: MIT
//
// DeepSeek-V4 unified-KV prefill metadata for gfx950.
//
// One 1024-thread workgroup replaces the per-token lengths kernel and both
// generic device scans.  Each thread owns a contiguous run of at most 8
// tokens, writes temporary counts into the final output buffers, the block
// scans per-thread totals with wave64 shuffles plus four wave carries, and each
// owner overwrites its counts with inclusive indptr values.  Compressed counts
// come from the backend's already-produced graph-safe top-k length tensor,
// which is the authoritative valid width of each front-packed page-index row.

#include <hip/hip_runtime.h>
#include <stdint.h>

namespace {

constexpr uint32_t kThreads = 1024;
constexpr uint32_t kItemsPerThread = 8;
constexpr uint32_t kWaveSize = 64;
constexpr uint32_t kWaves = kThreads / kWaveSize;

}  // namespace

extern "C" __global__ __launch_bounds__(kThreads)
void netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_gfx950(
    const int64_t* positions_i64,
    const int64_t* chunk_start_i64,
    const int32_t* compressed_lengths_i32,
    int32_t* prefix_indptr_i32,
    int32_t* extend_indptr_i32,
    uint32_t tokens,
    uint32_t window,
    uint32_t has_compress) {
  __shared__ int32_t prefix_wave_carries[kWaves];
  __shared__ int32_t extend_wave_carries[kWaves];

  const uint32_t lane = threadIdx.x;
  const uint32_t begin = lane * kItemsPerThread;
  const uint32_t end = min(begin + kItemsPerThread, tokens);
  int32_t prefix_total = 0;
  int32_t extend_total = 0;

  if (lane == 0) {
    prefix_indptr_i32[0] = 0;
    extend_indptr_i32[0] = 0;
  }

  #pragma unroll
  for (uint32_t item = 0; item < kItemsPerThread; ++item) {
    const uint32_t token = begin + item;
    if (token >= end) continue;
    // Triton explicitly truncates both i64 inputs before doing i32 arithmetic.
    const int32_t position = static_cast<int32_t>(positions_i64[token]);
    const int32_t chunk_start = static_cast<int32_t>(chunk_start_i64[token]);
    const int32_t token_in_chunk = position - chunk_start;
    const int32_t swa_low = max(
        position - static_cast<int32_t>(window) + 1, static_cast<int32_t>(0));
    const int32_t extend_count = min(
        token_in_chunk + 1, static_cast<int32_t>(window));
    const int32_t prefix_swa_count = min(
        max(chunk_start - swa_low, static_cast<int32_t>(0)),
        static_cast<int32_t>(window));
    const int32_t compressed_count =
        has_compress != 0 ? compressed_lengths_i32[token] : 0;
    const int32_t prefix_count = prefix_swa_count + compressed_count;
    prefix_indptr_i32[token + 1] = prefix_count;
    extend_indptr_i32[token + 1] = extend_count;
    prefix_total += prefix_count;
    extend_total += extend_count;
  }

  const uint32_t wave_lane = lane & (kWaveSize - 1);
  const uint32_t wave = lane / kWaveSize;
  int32_t prefix_inclusive = prefix_total;
  int32_t extend_inclusive = extend_total;
  for (uint32_t offset = 1; offset < kWaveSize; offset <<= 1) {
    const int32_t prefix_add = __shfl_up(prefix_inclusive, offset, kWaveSize);
    const int32_t extend_add = __shfl_up(extend_inclusive, offset, kWaveSize);
    if (wave_lane >= offset) {
      prefix_inclusive += prefix_add;
      extend_inclusive += extend_add;
    }
  }
  if (wave_lane == kWaveSize - 1) {
    prefix_wave_carries[wave] = prefix_inclusive;
    extend_wave_carries[wave] = extend_inclusive;
  }
  __syncthreads();

  // Sixteen wave totals are small enough for one lane to make exclusive
  // carries.  This avoids a second full-workgroup scan and uses only two block
  // barriers in the entire kernel.
  if (lane == 0) {
    int32_t prefix_carry = 0;
    int32_t extend_carry = 0;
    for (uint32_t wave_id = 0; wave_id < kWaves; ++wave_id) {
      const int32_t next_prefix = prefix_carry + prefix_wave_carries[wave_id];
      const int32_t next_extend = extend_carry + extend_wave_carries[wave_id];
      prefix_wave_carries[wave_id] = prefix_carry;
      extend_wave_carries[wave_id] = extend_carry;
      prefix_carry = next_prefix;
      extend_carry = next_extend;
    }
  }
  __syncthreads();

  int32_t prefix_running =
      prefix_wave_carries[wave] + prefix_inclusive - prefix_total;
  int32_t extend_running =
      extend_wave_carries[wave] + extend_inclusive - extend_total;
  #pragma unroll
  for (uint32_t item = 0; item < kItemsPerThread; ++item) {
    const uint32_t token = begin + item;
    if (token >= end) continue;
    prefix_running += prefix_indptr_i32[token + 1];
    extend_running += extend_indptr_i32[token + 1];
    prefix_indptr_i32[token + 1] = prefix_running;
    extend_indptr_i32[token + 1] = extend_running;
  }
}
