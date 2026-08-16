// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_moe_m64_verify_load(
    const char* gate_up_hsaco_path,
    const char* quant_hsaco_path,
    const char* down_hsaco_path,
    const char* reduce_hsaco_path,
    int max_rows);

int netra_qwen36_moe_m64_verify_launch_gate_up(
    const void* hidden_fp8,
    const float* hidden_scale_f32,
    const void* w13_fp8,
    const float* w13_scale_f32,
    const int32_t* sorted_token_ids_i32,
    const int32_t* sorted_expert_ids_i32,
    const int32_t* num_valid_ids_i32,
    void* activation_bf16,
    int rows,
    int sorted_blocks,
    hipStream_t stream);

int netra_qwen36_moe_m64_verify_launch_gate_up_quant(
    const void* hidden_fp8,
    const float* hidden_scale_f32,
    const void* w13_fp8,
    const float* w13_scale_f32,
    const int32_t* sorted_token_ids_i32,
    const int32_t* sorted_expert_ids_i32,
    const int32_t* num_valid_ids_i32,
    void* activation_bf16,
    void* activation_fp8,
    float* activation_scale_f32,
    int rows,
    int sorted_blocks,
    hipStream_t stream);

int netra_qwen36_moe_m64_verify_launch_down(
    const void* activation_fp8,
    const float* activation_scale_f32,
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

size_t netra_qwen36_moe_m64_verify_workspace_bytes(void);
int netra_qwen36_moe_m64_verify_unload(void);
const char* netra_qwen36_moe_m64_verify_last_error(void);

#ifdef __cplusplus
}
#endif
