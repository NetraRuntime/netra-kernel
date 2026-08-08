// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

extern "C" int netra_qwen36_dflash_mlp_down_bf16_m768_load(
    const char* hsaco_path);
extern "C" int netra_qwen36_dflash_mlp_down_bf16_m768_launch(
    void* output_bf16,
    const void* input_bf16,
    const void* weight_bf16,
    hipStream_t stream);
extern "C" int netra_qwen36_dflash_mlp_down_bf16_m768_unload(void);
extern "C" const char*
netra_qwen36_dflash_mlp_down_bf16_m768_last_error(void);
