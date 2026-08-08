// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

extern "C" int netra_qwen36_gdn_causal_conv_m8192_load(
    const char* hsaco_path);

extern "C" int netra_qwen36_gdn_causal_conv_m8192_launch(
    const void* x_bf16,
    const void* weight_bf16,
    void* state_bf16,
    const void* cache_index_i32,
    const void* has_initial_state_i8,
    void* output_bf16,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_causal_conv_m8192_unload(void);

extern "C" const char*
netra_qwen36_gdn_causal_conv_m8192_last_error(void);
