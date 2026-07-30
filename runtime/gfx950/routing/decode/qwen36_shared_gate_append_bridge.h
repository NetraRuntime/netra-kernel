// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_qwen36_shared_gate_append_load(const char* hsaco_path);

int netra_qwen36_shared_gate_append_launch(
    void* output_ids_i32,
    void* output_weights_f32,
    const void* hidden_bf16,
    const void* shared_gate_weight_bf16,
    const void* routed_ids_i32,
    const void* routed_weights_f32,
    uint32_t rows,
    hipStream_t stream);

int netra_qwen36_shared_gate_append_unload(void);

const char* netra_qwen36_shared_gate_append_last_error(void);

#ifdef __cplusplus
}
#endif
