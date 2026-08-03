// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_gdn_verify_m12_batched_load(
    const char* precompute_hsaco_path,
    const char* core_hsaco_path);

// Load the batch-selected K0 core family.  The three code objects contain the
// same raw gfx950 kernel assembled for 1, 4, and 8 waves per workgroup.
extern "C" int netra_qwen36_gdn_verify_m12_batched_load_wavegroup_variants(
    const char* precompute_hsaco_path,
    const char* core_waves1_hsaco_path,
    const char* core_waves4_hsaco_path,
    const char* core_waves8_hsaco_path);

extern "C" int netra_qwen36_gdn_verify_m12_batched_launch(
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
    uint32_t batch_size,
    uint32_t state_capacity,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_verify_m12_batched_unload(void);

extern "C" const char* netra_qwen36_gdn_verify_m12_batched_last_error(void);
