// SPDX-License-Identifier: MIT
//
// DeepSeek-V4 Flash routing for the qualified gfx950 configuration:
//   scores:       contiguous BF16 [rows, 256]
//   correction:   contiguous BF16 [256]
//   output:       contiguous FP32/I32 [rows, 7]
//   semantics:    sqrt(softplus(score)), bias used only for ranking,
//                 six routed experts followed by shared expert 256.
#include <hip/hip_bfloat16.h>
#include <hip/hip_runtime.h>

#include <cstdint>

namespace {

constexpr int kExperts = 256;
constexpr int kRouted = 6;
constexpr int kOutput = 7;
constexpr float kRoutedScale = 1.5f;
constexpr float kNanRankingFloor = -1.0e30f;

__device__ __forceinline__ float sqrt_softplus(float value) {
  // Match the stable operation order used by SGLang's qualified Triton path.
  const float z = __expf(-fabsf(value));
  const float u = 1.0f + z;
  const bool rounded_to_one = u == 1.0f;
  const float denominator = rounded_to_one ? 1.0f : u - 1.0f;
  const float log1p_z = rounded_to_one ? z : z * __logf(u) / denominator;
  return sqrtf(fmaxf(value, 0.0f) + log1p_z);
}

__device__ __forceinline__ bool better(float lhs_value,
                                       int lhs_index,
                                       float rhs_value,
                                       int rhs_index) {
  return lhs_value > rhs_value ||
         (lhs_value == rhs_value && lhs_index < rhs_index);
}

}  // namespace

extern "C" __global__ __launch_bounds__(64)
void netra_dsv4_router_shared_topk_bf16_v1_gfx950(
    const hip_bfloat16* __restrict__ scores,
    const hip_bfloat16* __restrict__ correction_bias,
    float* __restrict__ output_weights,
    int32_t* __restrict__ output_indices,
    uint32_t rows) {
  const uint32_t row = blockIdx.x;
  const int lane = static_cast<int>(threadIdx.x);
  if (row >= rows || lane >= 64) return;

  float activated[4];
  float ranked[4];
#pragma unroll
  for (int item = 0; item < 4; ++item) {
    const int expert = lane + item * 64;
    const float score = static_cast<float>(scores[row * kExperts + expert]);
    const float value = sqrt_softplus(score);
    float rank = value + static_cast<float>(correction_bias[expert]);
    if (isnan(rank)) rank = kNanRankingFloor;
    activated[item] = value;
    ranked[item] = rank;
  }

  float selected[kRouted];
  int selected_indices[kRouted];
#pragma unroll
  for (int slot = 0; slot < kRouted; ++slot) {
    float lane_value = ranked[0];
    int lane_index = lane;
#pragma unroll
    for (int item = 1; item < 4; ++item) {
      const int expert = lane + item * 64;
      if (better(ranked[item], expert, lane_value, lane_index)) {
        lane_value = ranked[item];
        lane_index = expert;
      }
    }

#pragma unroll
    for (int delta = 32; delta > 0; delta >>= 1) {
      const float other_value = __shfl_down(lane_value, delta, 64);
      const int other_index = __shfl_down(lane_index, delta, 64);
      if (lane + delta < 64 &&
          better(other_value, other_index, lane_value, lane_index)) {
        lane_value = other_value;
        lane_index = other_index;
      }
    }

    const int winner = __shfl(lane_index, 0, 64);
    const int owner_lane = winner & 63;
    const int owner_item = winner >> 6;
    float winner_value = 0.0f;
    if (lane == owner_lane) winner_value = activated[owner_item];
    winner_value = __shfl(winner_value, owner_lane, 64);
    if (lane == 0) {
      selected[slot] = winner_value;
      selected_indices[slot] = winner;
    }
    if (lane == owner_lane) ranked[owner_item] = -INFINITY;
  }

  if (lane != 0) return;
  float routed_sum = 0.0f;
#pragma unroll
  for (int slot = 0; slot < kRouted; ++slot) routed_sum += selected[slot];
  const float norm = routed_sum > 0.0f ? routed_sum : 1.0f;
  const uint32_t output_base = row * kOutput;
#pragma unroll
  for (int slot = 0; slot < kRouted; ++slot) {
    output_weights[output_base + slot] = selected[slot] / norm * kRoutedScale;
    output_indices[output_base + slot] = selected_indices[slot];
  }
  output_weights[output_base + kRouted] =
      (routed_sum / kRoutedScale) / norm * kRoutedScale;
  output_indices[output_base + kRouted] = kExperts;
}
