// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_gemma_add_rmsnorm_load(const char* hsaco_path);

int netra_qwen36_gemma_add_rmsnorm_launch(
    void* output_bf16,
    const void* input_bf16,
    const void* residual_bf16,
    void* residual_out_bf16,
    const void* gemma_weight_bf16,
    double epsilon,
    hipStream_t stream);

int netra_qwen36_gemma_add_rmsnorm_unload(void);

const char* netra_qwen36_gemma_add_rmsnorm_last_error(void);

#ifdef __cplusplus
}
#endif
