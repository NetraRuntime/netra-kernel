// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

int netra_gfx950_blockscale_verify_load(
    const char* m1536_n5120_k6144_hsaco_path,
    const char* m1536_n5120_k17408_hsaco_path,
    const char* m1536_n14336_k5120_hsaco_path,
    const char* m1536_n16384_k5120_hsaco_path);

int netra_gfx950_blockscale_verify_unload(void);

int netra_gfx950_blockscale_verify_launch(
    void* output_bf16, const void* activation_fp8_e4m3,
    const void* weight_fp8_e4m3, const void* activation_scale_f32,
    const void* weight_scale_f32, uint32_t m, uint32_t n, uint32_t k,
    uint32_t activation_stride, uint32_t weight_stride,
    uint32_t output_stride, uint32_t activation_scale_stride,
    uint32_t weight_scale_stride, hipStream_t stream);

const char* netra_gfx950_blockscale_verify_last_error(void);

#ifdef __cplusplus
}
#endif
