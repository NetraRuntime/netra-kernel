// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_moe_route_reduce_load(const char* hsaco_path);

int netra_qwen36_moe_route_reduce_launch(
    const float* partial_f32,
    const float* topk_weights_f32,
    void* output_bf16,
    int rows,
    hipStream_t stream);

int netra_qwen36_moe_route_reduce_unload(void);

const char* netra_qwen36_moe_route_reduce_last_error(void);

#ifdef __cplusplus
}
#endif
