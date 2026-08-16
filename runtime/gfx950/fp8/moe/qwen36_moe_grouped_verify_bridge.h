// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_moe_grouped_verify_load(
    const char* grouped_hsaco_path,
    const char* reduce_hsaco_path,
    int max_rows);

int netra_qwen36_moe_grouped_verify_launch(
    const void* inter_fp8,
    const float* inter_scale_f32,
    const void* w2_fp8,
    const float* w2_scale_f32,
    const int32_t* sorted_token_ids_i32,
    const int32_t* sorted_expert_ids_i32,
    const int32_t* num_valid_ids_i32,
    const float* topk_weights_f32,
    void* output_bf16,
    int rows,
    int sorted_blocks,
    hipStream_t stream);

size_t netra_qwen36_moe_grouped_verify_workspace_bytes(void);

int netra_qwen36_moe_grouped_verify_unload(void);

const char* netra_qwen36_moe_grouped_verify_last_error(void);

#ifdef __cplusplus
}
#endif
