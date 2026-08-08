// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_gdn_qkvz_conv_m12_load(const char* hsaco_path);

// UINT32_MAX denotes that launch capacity is limited only by the caller's
// validated buffers and the HIP grid, not by an implementation batch ceiling.
uint32_t netra_qwen36_gdn_qkvz_conv_m12_batch_capacity(void);

int netra_qwen36_gdn_qkvz_conv_m12_launch(
    const void* x_bf16,
    const void* weight_bf16,
    void* state_bf16,
    const void* state_indices_i32,
    void* intermediate_window_bf16,
    const void* intermediate_indices_i32,
    void* output_bf16,
    uint32_t batch_size,
    hipStream_t stream);

const char* netra_qwen36_gdn_qkvz_conv_m12_last_error(void);

#ifdef __cplusplus
}
#endif
