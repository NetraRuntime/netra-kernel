// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

int netra_attention_gqa6_fp8kv_m8_load(
    const char* qo32_kv64_hsaco_path, const char* qo64_kv64_hsaco_path,
    const char* qo32_kv32_hsaco_path);

int netra_attention_gqa6_fp8kv_m8_unload(void);

int netra_attention_gqa6_fp8kv_m8_launch(
    void* output_bf16, const void* query_bf16, const void* key_extend_bf16,
    const void* value_extend_bf16, const void* key_buffer_fp8_e4m3,
    const void* value_buffer_fp8_e4m3, const void* query_indptr,
    const void* kv_indptr_i32, const void* kv_indices,
    uint32_t query_indptr_stride_bytes, uint32_t kv_indices_stride_bytes,
    float softmax_scale, uint32_t batch_size, hipStream_t stream);

const char* netra_attention_gqa6_fp8kv_m8_last_error(void);

#ifdef __cplusplus
}
#endif
