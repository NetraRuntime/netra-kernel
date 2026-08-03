// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

// Exact-shape launch-only bridge for Qwen3.6 GDN prefill chunk output:
// B=1, T=8192, H=32, Hg=16, K=V=128, BT=64, BK=BV=128.
extern "C" int netra_qwen36_gdn_chunk_o_m8192_load(
    const char* hsaco_path,
    const char* kernel_name);

extern "C" int netra_qwen36_gdn_chunk_o_m8192_launch(
    const void* q_bf16,
    const void* k_bf16,
    const void* v_new_bf16,
    const void* h_bf16,
    const void* g_f32,
    void* output_bf16,
    const void* cu_seqlens_i32,
    const void* chunk_indices_i32,
    float scale,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_chunk_o_m8192_unload(void);

extern "C" const char* netra_qwen36_gdn_chunk_o_m8192_last_error(void);
