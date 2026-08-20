// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int netra_group_quant_assembly_load(
    const char* add_rmsnorm_hsaco,
    const char* silu_store_bf16_hsaco,
    const char* silu_prequant_only_hsaco,
    const char* gated_rpb1_hsaco,
    const char* gated_rpb2_hsaco,
    const char* gated_rpb4_hsaco);

int netra_group_quant_assembly_unload(void);

int netra_add_rmsnorm_group_quant_n5120_launch(
    const void* input_bf16,
    const void* residual_bf16,
    const void* weight_f32,
    void* output_bf16,
    void* residual_out_bf16,
    void* output_fp8,
    void* output_scale_f32,
    uint32_t rows,
    float epsilon,
    hipStream_t stream);

int netra_silu_mul_group_quant_n17408_launch(
    const void* gate_up_bf16,
    void* output_bf16,
    void* output_fp8,
    void* output_scale_f32,
    uint32_t rows,
    int store_bf16,
    hipStream_t stream);

int netra_gated_rmsnorm_group_quant_d128_launch(
    const void* input_bf16,
    void* output_bf16,
    const void* weight_f32,
    const void* gate_bf16,
    void* output_fp8,
    void* output_scale_f32,
    uint32_t rows,
    uint32_t gate_token_stride,
    uint32_t gate_head_stride,
    float epsilon,
    hipStream_t stream);

const char* netra_group_quant_assembly_last_error(void);

#ifdef __cplusplus
}
#endif
