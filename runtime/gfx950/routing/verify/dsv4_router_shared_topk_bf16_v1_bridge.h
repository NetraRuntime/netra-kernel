// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t netra_dsv4_router_shared_topk_bf16_v1_abi_version(void);

int netra_dsv4_router_shared_topk_bf16_v1_load(const char* hsaco_path);

int netra_dsv4_router_shared_topk_bf16_v1_launch(
    const void* scores_bf16,
    const void* correction_bias_bf16,
    void* output_weights_f32,
    void* output_indices_i32,
    uint32_t rows,
    hipStream_t stream);

int netra_dsv4_router_shared_topk_bf16_v1_unload(void);

const char* netra_dsv4_router_shared_topk_bf16_v1_last_error(void);

#ifdef __cplusplus
}
#endif
