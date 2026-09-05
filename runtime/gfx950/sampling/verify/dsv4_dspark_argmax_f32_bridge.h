// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_dsv4_dspark_argmax_f32_load(const char* hsaco_path);
int netra_dsv4_dspark_argmax_f32_launch(
    int64_t* output_i64,
    uint32_t* partial_keys_u32,
    const float* logits_f32,
    uint32_t rows,
    hipStream_t stream);
int netra_dsv4_dspark_argmax_bf16_base_bias_launch_v1(
    int64_t* output_i64,
    uint32_t* partial_keys_u32,
    const void* base_bf16,
    const void* bias_bf16,
    uint32_t valid_width,
    uint32_t padded_width,
    uint32_t base_row_stride,
    uint32_t rows,
    hipStream_t stream);
int netra_dsv4_dspark_argmax_f32_unload(void);
const char* netra_dsv4_dspark_argmax_f32_last_error(void);

#ifdef __cplusplus
}
#endif
