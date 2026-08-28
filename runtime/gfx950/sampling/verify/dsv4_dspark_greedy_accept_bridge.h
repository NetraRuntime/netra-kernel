// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_dsv4_dspark_greedy_accept_load(const char* hsaco_path);
int netra_dsv4_dspark_greedy_accept_launch(
    int64_t* correct_i64,
    int64_t* bonus_i64,
    int32_t* trim_i32,
    int32_t* commit_i32,
    int64_t* new_seq_i64,
    int64_t* out_tokens_i64,
    int32_t* swa_loc_i32,
    const int64_t* draft_tokens_i64,
    const int64_t* target_predict_i64,
    const int64_t* verify_lens_i64,
    const int64_t* prefix_lens_i64,
    const int64_t* req_slots_i64,
    uint32_t batch,
    hipStream_t stream);
int netra_dsv4_dspark_greedy_accept_unload(void);
const char* netra_dsv4_dspark_greedy_accept_last_error(void);

#ifdef __cplusplus
}
#endif
