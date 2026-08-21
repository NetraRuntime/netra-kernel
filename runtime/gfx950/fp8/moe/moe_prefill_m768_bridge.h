// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_moe_prefill_m768_load(
    const char* producer_hsaco, const char* reducer_hsaco);

int netra_moe_prefill_m768_launch(
    const void* hidden_fp8, const float* hidden_scale_f32,
    const void* w13_fp8, const float* w13_scale_f32,
    const void* w2_fp8, const float* w2_scale_f32,
    const int32_t* sorted_token_ids_i32, const float* sorted_weights_f32,
    const int32_t* sorted_expert_ids_i32, const int32_t* num_valid_ids_i32,
    const float* topk_weights_f32, float* route_scale_workspace_f32,
    void* partials_f16, void* output_bf16, hipStream_t stream);

int netra_moe_prefill_m768_unload(void);
const char* netra_moe_prefill_m768_last_error(void);

#ifdef __cplusplus
}
#endif
