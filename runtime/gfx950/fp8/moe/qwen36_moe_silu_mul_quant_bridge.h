// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Load the raw gfx950 code object before graph capture. Repeated calls with the
// same path are harmless; loading a different object requires an explicit
// unload first.
int netra_qwen36_moe_silu_mul_quant_load(const char* hsaco_path);

// Launches the preloaded raw kernel on the caller's stream. This function does
// not allocate, synchronize, or mutate module state and is graph-capture safe.
int netra_qwen36_moe_silu_mul_quant_launch(
    const float* input_f32,
    void* output_fp8,
    float* output_scale_f32,
    int rows,
    hipStream_t stream);

// Unload outside graph capture after all launches and replays have completed.
int netra_qwen36_moe_silu_mul_quant_unload(void);

// Thread-local diagnostic string for the most recent nonzero return.
const char* netra_qwen36_moe_silu_mul_quant_last_error(void);

// Preload and dispatch the deterministic M=1 FP8 down-projection/reduction
// code object. The launch overwrites one contiguous BF16 [1,2048] output.
int netra_qwen36_moe_down_reduce_load(const char* hsaco_path);

int netra_qwen36_moe_down_reduce_launch(
    const void* activation_fp8,
    const float* activation_scale_f32,
    const void* w2_fp8,
    const float* w2_scale_f32,
    const float* topk_weights_f32,
    const int32_t* topk_ids_i32,
    void* output_bf16,
    int rows,
    hipStream_t stream);

int netra_qwen36_moe_down_reduce_unload(void);

const char* netra_qwen36_moe_down_reduce_last_error(void);

int netra_qwen36_moe_gate_up_load(const char* hsaco_path);

int netra_qwen36_moe_gate_up_launch(
    const void* hidden_fp8,
    const float* hidden_scale_f32,
    const void* w13_fp8,
    const float* w13_scale_f32,
    const int32_t* topk_ids_i32,
    float* output_f32,
    int rows,
    hipStream_t stream);

int netra_qwen36_moe_gate_up_unload(void);

const char* netra_qwen36_moe_gate_up_last_error(void);

#ifdef __cplusplus
}
#endif
