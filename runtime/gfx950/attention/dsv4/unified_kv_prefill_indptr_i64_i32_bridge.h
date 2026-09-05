// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_load(
    const char* hsaco_path);
int netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_launch(
    const int64_t* positions_i64,
    const int64_t* chunk_start_i64,
    const int32_t* compressed_lengths_i32,
    int32_t* prefix_indptr_i32,
    int32_t* extend_indptr_i32,
    uint32_t tokens,
    uint32_t window,
    uint32_t has_compress,
    hipStream_t stream);
int netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_unload(void);
const char* netra_dsv4_unified_kv_prefill_indptr_i64_i32_v1_last_error(void);

#ifdef __cplusplus
}
#endif
