// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_gdn_state_replay_m12_load(
    const char* precompute_hsaco_path,
    const char* core_waves1_hsaco_path,
    const char* core_waves4_hsaco_path,
    const char* core_waves8_hsaco_path);

extern "C" int netra_qwen36_gdn_state_replay_m12_launch(
    const void* A_log_f32,
    const void* a_bf16,
    const void* dt_bias_bf16,
    const void* k_bf16,
    const void* v_bf16,
    const void* b_bf16,
    void* states_bf16,
    const void* initial_state_indices_i32,
    const void* output_state_indices_i32,
    const void* accepted_lengths_i32,
    void* q_dummy_f32,
    void* k_normalized_f32,
    void* decay_f32,
    void* beta_f32,
    uint32_t stride_k,
    uint32_t stride_v,
    uint32_t stride_a,
    uint32_t stride_b,
    uint32_t batch_size,
    uint32_t waves_per_workgroup,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_state_replay_m12_launch_precomputed(
    const void* k_normalized_f32,
    const void* v_bf16,
    const void* decay_f32,
    const void* beta_f32,
    void* states_bf16,
    const void* initial_state_indices_i32,
    const void* output_state_indices_i32,
    const void* accepted_lengths_i32,
    uint32_t stride_v,
    uint32_t batch_size,
    uint32_t waves_per_workgroup,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_state_replay_m12_unload(void);

extern "C" const char* netra_qwen36_gdn_state_replay_m12_last_error(void);
