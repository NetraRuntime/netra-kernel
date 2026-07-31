// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

extern "C" int netra_qwen36_dflash_o_proj_bf16_load(
    const char* hsaco_path);

extern "C" int netra_qwen36_dflash_o_proj_bf16_launch(
    void* output_bf16,
    const void* input_bf16,
    const void* weight_bf16,
    hipStream_t stream);

extern "C" int netra_qwen36_dflash_o_proj_bf16_unload(void);

extern "C" const char* netra_qwen36_dflash_o_proj_bf16_last_error(void);
