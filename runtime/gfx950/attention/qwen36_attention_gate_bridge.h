// SPDX-License-Identifier: MIT
#pragma once
#include <hip/hip_runtime.h>
#include <stdint.h>

extern "C" int netra_qwen36_attention_gate_load(const char* hsaco_path);
extern "C" int netra_qwen36_attention_gate_launch(
    void* output_bf16, const void* input_bf16, const void* gate_bf16,
    uint32_t token_count, uint32_t gate_token_stride_elements,
    hipStream_t stream);
extern "C" int netra_qwen36_attention_gate_unload(void);
extern "C" const char* netra_qwen36_attention_gate_last_error(void);
