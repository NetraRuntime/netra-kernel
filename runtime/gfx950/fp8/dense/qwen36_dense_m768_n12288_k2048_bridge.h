// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

extern "C" int netra_qwen36_dense_m768_n12288_k2048_load(
    const char* hsaco_path);

extern "C" int netra_qwen36_dense_m768_n12288_k2048_launch(
    const void* activation_fp8,
    const void* activation_scale_f32,
    const void* shuffled_weight_fp8,
    const void* weight_scale_f32,
    void* output_bf16,
    unsigned int n,
    hipStream_t stream);

extern "C" int netra_qwen36_dense_m768_n12288_k2048_unload(void);

extern "C" const char* netra_qwen36_dense_m768_n12288_k2048_last_error(void);

