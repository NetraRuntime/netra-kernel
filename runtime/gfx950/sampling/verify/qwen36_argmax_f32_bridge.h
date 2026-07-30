// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_argmax_f32_load(const char* hsaco_path);
int netra_qwen36_argmax_f32_launch(
    int64_t* output_i64,
    uint32_t* partial_keys_u32,
    const float* logits_f32,
    uint32_t rows,
    hipStream_t stream);
int netra_qwen36_argmax_f32_unload(void);
const char* netra_qwen36_argmax_f32_last_error(void);

#ifdef __cplusplus
}
#endif
