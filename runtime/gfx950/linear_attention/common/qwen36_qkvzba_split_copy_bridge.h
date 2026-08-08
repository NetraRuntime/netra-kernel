// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_qkvzba_split_copy_load(const char* hsaco_path);
int netra_qwen36_qkvzba_split_copy_launch(
    const void* mixed_qkvz,
    const void* mixed_ba,
    void* mixed_qkv,
    void* z,
    void* b,
    void* a,
    unsigned int token_count,
    hipStream_t stream);
int netra_qwen36_qkvzba_split_copy_unload(void);
const char* netra_qwen36_qkvzba_split_copy_last_error(void);

#ifdef __cplusplus
}
#endif
