// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_dense_m1_load(const char* hsaco_path);

int netra_qwen36_dense_m1_launch(
    const void* activation_fp8,
    const float* activation_scale_f32,
    const void* shuffled_weight_fp8,
    const float* weight_scale_f32,
    void* output_bf16,
    hipStream_t stream);

int netra_qwen36_dense_m1_unload(void);

const char* netra_qwen36_dense_m1_last_error(void);

#ifdef __cplusplus
}
#endif
