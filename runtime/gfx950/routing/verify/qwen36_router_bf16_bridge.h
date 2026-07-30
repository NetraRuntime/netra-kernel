// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_router_bf16_load(const char* hsaco_path);

int netra_qwen36_router_bf16_launch(
    void* output_logits_bf16,
    const void* hidden_bf16,
    const void* router_weight_bf16,
    uint32_t rows,
    hipStream_t stream);

int netra_qwen36_router_bf16_unload(void);

const char* netra_qwen36_router_bf16_last_error(void);

#ifdef __cplusplus
}
#endif
