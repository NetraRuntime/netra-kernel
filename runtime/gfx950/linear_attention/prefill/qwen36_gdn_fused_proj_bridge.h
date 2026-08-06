// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_gdn_fused_proj_bf16_load(const char* hsaco_path);
int netra_qwen36_gdn_fused_proj_bf16_launch(
    uint16_t* mixed_qkv_bf16,
    uint16_t* z_bf16,
    uint16_t* b_bf16,
    uint16_t* a_bf16,
    const uint16_t* mixed_qkvz_bf16,
    const uint16_t* mixed_ba_bf16,
    uint32_t rows,
    hipStream_t stream);
int netra_qwen36_gdn_fused_proj_bf16_unload(void);
const char* netra_qwen36_gdn_fused_proj_bf16_last_error(void);

#ifdef __cplusplus
}
#endif
