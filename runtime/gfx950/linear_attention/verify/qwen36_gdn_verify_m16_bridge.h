// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_gdn_verify_m16_load(
    const char* precompute_hsaco_path,
    const char* core_hsaco_path);

extern "C" int netra_qwen36_gdn_verify_m16_launch(
    void* output_bf16,
    const void* A_log_f32,
    const void* a_bf16,
    const void* dt_bias_bf16,
    const void* q_bf16,
    const void* k_bf16,
    const void* v_bf16,
    const void* b_bf16,
    const void* initial_state_bf16,
    const void* initial_state_indices_i32,
    void* intermediate_state_bf16,
    const void* intermediate_state_indices_i32,
    void* q_normalized_f32,
    void* k_normalized_f32,
    void* decay_f32,
    void* beta_f32,
    uint32_t stride_q,
    uint32_t stride_k,
    uint32_t stride_v,
    uint32_t stride_a,
    uint32_t stride_b,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_verify_m16_unload(void);

extern "C" const char* netra_qwen36_gdn_verify_m16_last_error(void);
