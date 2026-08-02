// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime_api.h>

#include <cstdint>

// Exact-shape development bridge for Qwen3.6 GDN prefill:
// B=1, T=8192, H=32, Hg=16, K=V=128, BT=64, BV=16.
extern "C" int netra_qwen36_gdn_h_m8192_bv16_load(
    const char* hsaco_path,
    const char* kernel_name);

extern "C" int netra_qwen36_gdn_h_m8192_bv16_launch(
    const void* k_bf16,
    const void* v_bf16,
    const void* w_bf16,
    void* v_new_bf16,
    const void* g_f32,
    void* h_bf16,
    void* state_bf16,
    const void* initial_state_indices_i32,
    const void* cu_seqlens_i32,
    const void* chunk_offsets_i64,
    hipStream_t stream);

extern "C" int netra_qwen36_gdn_h_m8192_bv16_unload(void);

extern "C" const char* netra_qwen36_gdn_h_m8192_bv16_last_error(void);
