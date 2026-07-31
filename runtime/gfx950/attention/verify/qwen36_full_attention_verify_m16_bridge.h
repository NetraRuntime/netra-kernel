// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_full_attention_verify_m16_load(
    const char* stage1_hsaco_path,
    const char* stage2_hsaco_path);

// Fixed real-checkpoint specialization:
//   M=16, Q heads=16, KV heads=2, head dim=256, FP8 E4M3 K/V,
//   max KV splits=129 for deterministic 32,775-token serving, gfx950 wave64.
//
// sequence_lengths_i32 contains sixteen prefix-inclusive lengths.  All
// queries share kv_indices_i64 and start at its first element.
extern "C" int netra_qwen36_full_attention_verify_m16_launch(
    void* output_bf16,
    const void* query_bf16,
    const void* key_cache_fp8_e4m3,
    const void* value_cache_fp8_e4m3,
    const void* sequence_lengths_i32,
    const void* kv_indices_i64,
    const void* num_kv_splits_i32,
    void* intermediate_output_f32,
    void* intermediate_lse_f32,
    float softmax_scale_times_k_scale,
    float value_scale,
    uint32_t stride_q_batch,
    uint32_t stride_q_head,
    uint32_t stride_kv_batch,
    uint32_t stride_k_head,
    uint32_t stride_v_batch,
    uint32_t stride_v_head,
    uint32_t stride_mid_batch,
    uint32_t stride_mid_head,
    uint32_t stride_mid_split,
    uint32_t stride_output_batch,
    uint32_t stride_output_head,
    hipStream_t stream);

extern "C" int netra_qwen36_full_attention_verify_m16_unload(void);

extern "C" const char*
netra_qwen36_full_attention_verify_m16_last_error(void);
