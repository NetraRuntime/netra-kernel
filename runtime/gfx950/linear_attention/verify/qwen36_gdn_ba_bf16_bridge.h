// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_gdn_ba_bf16_load(const char* hsaco_path);

extern "C" int netra_qwen36_gdn_ba_bf16_launch(
    void* output_ba_bf16,
    const void* hidden_bf16,
    const void* ba_weight_bf16,
    uint32_t rows,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_ba_bf16_unload(void);

extern "C" const char* netra_qwen36_gdn_ba_bf16_last_error(void);
