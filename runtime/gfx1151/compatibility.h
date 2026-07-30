// SPDX-License-Identifier: MIT
#pragma once

#define NETRA_GFX1151_EXPORT __attribute__((visibility("default")))

extern "C" {

NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_init();
NETRA_GFX1151_EXPORT const char* netra_mxfp4_sgl_error();
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_decode(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* down_weight, void* down_scale, void* activation, void* expert_ids,
    void* topk_weights, void* gate_tmp, void* up_tmp, void* intermediate_tmp,
    void* expert_output_tmp, void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_decode_block64(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* down_weight, void* down_scale, void* activation, void* expert_ids,
    void* topk_weights, void* block_tmp, void* gate_tmp, void* up_tmp,
    void* intermediate_tmp, void* expert_output_tmp, void* output,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_prefill_repack(
    void* source, void* destination, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_prefill_gate_up(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* activation_groups, void* expert_ids, void* gate_output,
    void* up_output, void* intermediate_output, unsigned group_count,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_prefill_down(
    void* down_weight, void* down_scale, void* activation_groups,
    void* expert_output, void* expert_ids, unsigned group_count,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_m12_gate_up(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* activation_groups, void* expert_ids, void* gate_output,
    void* up_output, void* intermediate_output, unsigned group_count,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_m12_down(
    void* down_weight, void* down_scale, void* activation_groups,
    void* expert_output, void* expert_ids, unsigned group_count,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_linear(
    void* packed, void* scale, void* activation, void* output, unsigned m,
    unsigned n, unsigned k, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_linear_n2048_k4096_block128(
    void* packed, void* scale, void* activation, void* workspace,
    void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_linear_n12800_k2048_block64(
    void* packed, void* scale, void* activation, void* workspace,
    void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_bf16_qkv_decode(
    void* weight, void* activation, void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_bf16_shared_gate_up_silu_decode(
    void* weight, void* activation, void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_bf16_shared_down_decode(
    void* weight, void* activation, void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_bf16_lm_head_decode(
    void* weight, void* activation, void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_linear_prefill(
    void* packed, void* scale, void* activation_groups, void* output_groups,
    unsigned group_count, unsigned n, unsigned k, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_mxfp4_sgl_linear_prefill_repack(
    void* source, void* destination, unsigned n, unsigned k,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_qkvzba_split_copy(
    void* mixed_qkvz, void* mixed_ba, void* mixed_qkv, void* z, void* b,
    void* a, unsigned token_count, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_extend_attention(
    void* q, void* k_extend, void* v_extend, void* output, void* k_buffer,
    void* v_buffer, void* kv_indices, void* kv_indptr, unsigned tokens,
    float sm_scale, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_qk_norm_mrope_gate_kv_store(
    void* qkv, void* q_out, void* k_out, void* gate_out, void* q_weight,
    void* k_weight, void* cos_sin, void* positions, void* k_cache,
    void* v_cache, void* cache_loc, unsigned tokens,
    unsigned position_stride_bytes, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_gdn_chunk_o(
    void* q, void* k, void* v, void* h, void* g, void* output,
    void* cu_seqlens, void* chunk_indices, float scale, unsigned tokens,
    void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_gdn_recompute_w_u(
    void* k, void* v, void* beta, void* w, void* u, void* A, void* g,
    unsigned tokens, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_causal_conv1d(
    void* x, void* weight, void* state, void* cache_index,
    void* has_initial, void* output, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_expert_weighted_reduce_fp64(
    void* expert, void* positions, void* weights, void* output,
    unsigned tokens, void* stream_ptr);
NETRA_GFX1151_EXPORT int netra_expert_activation_pack(
    void* hidden, void* pair_tokens, void* position, void* output,
    unsigned pair_count, unsigned total_rows, void* stream_ptr);

}  // extern "C"
