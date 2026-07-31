// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

extern "C" int netra_qwen36_dense_m210_k4096_load(
    const char* hsaco_path);

extern "C" int netra_qwen36_dense_m210_k4096_launch(
    const void* activation_fp8,
    const void* activation_scale_f32,
    const void* shuffled_weight_fp8,
    const void* weight_scale_f32,
    void* output_bf16,
    unsigned int n,
    hipStream_t stream);

extern "C" int netra_qwen36_dense_m210_k4096_unload(void);

extern "C" const char* netra_qwen36_dense_m210_k4096_last_error(void);
