// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_dsv4_dspark_expand_metadata_load(const char* hsaco_path);
int netra_dsv4_dspark_expand_metadata_launch(
    int32_t* seq_lens_causal_i32,
    int64_t* req_pool_repeated_i64,
    const int64_t* req_pool_i64,
    const int64_t* seq_lens_i64,
    const int32_t* extend_lens_i32,
    const int32_t* extend_starts_i32,
    uint32_t batch,
    uint32_t real_tokens,
    uint32_t total_tokens,
    hipStream_t stream);
int netra_dsv4_dspark_expand_metadata_unload(void);
const char* netra_dsv4_dspark_expand_metadata_last_error(void);

#ifdef __cplusplus
}
#endif
