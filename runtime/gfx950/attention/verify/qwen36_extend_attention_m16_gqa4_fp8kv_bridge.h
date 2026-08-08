// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_extend_attention_m16_gqa4_fp8kv_load(
    const char* hsaco_path);

extern "C" int netra_qwen36_extend_attention_m16_gqa4_fp8kv_launch(
    void* output_bf16,
    const void* query_bf16,
    const void* key_extend_bf16,
    const void* value_extend_bf16,
    const void* key_buffer_bf16,
    const void* value_buffer_bf16,
    const void* query_indptr_i32,
    const void* kv_indptr_i32,
    const void* kv_indices_i64,
    float softmax_scale,
    uint32_t batch_size,
    hipStream_t stream);

extern "C" int netra_qwen36_extend_attention_m16_gqa4_fp8kv_unload(void);

extern "C" const char*
netra_qwen36_extend_attention_m16_gqa4_fp8kv_last_error(void);
