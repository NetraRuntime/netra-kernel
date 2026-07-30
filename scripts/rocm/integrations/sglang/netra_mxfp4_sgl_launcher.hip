// SPDX-License-Identifier: MIT
// Compatibility C ABI from SGLang/PyTorch to the gfx1151 runtime layer.

#include "runtime/gfx1151/compatibility.h"
#include "runtime/gfx1151/common/module_registry.h"
#include "runtime/gfx1151/mxfp4/attention/runtime.h"
#include "runtime/gfx1151/mxfp4/decode/runtime.h"
#include "runtime/gfx1151/mxfp4/gdn/runtime.h"
#include "runtime/gfx1151/mxfp4/moe/runtime.h"
#include "runtime/gfx1151/mxfp4/prefill/runtime.h"
#include "runtime/gfx1151/mxfp4/verify/runtime.h"

extern "C" int netra_mxfp4_sgl_init() {
  netra::gfx1151::ensure_initialized();
  return static_cast<int>(netra::gfx1151::runtime().status);
}

extern "C" const char* netra_mxfp4_sgl_error() {
  return netra::gfx1151::runtime_error();
}

extern "C" int netra_mxfp4_sgl_decode(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* down_weight, void* down_scale, void* activation, void* expert_ids,
    void* topk_weights, void* gate_tmp, void* up_tmp, void* intermediate_tmp,
    void* expert_output_tmp, void* output, void* stream_ptr) {
  return netra::gfx1151::decode::moe(
      gate_weight, gate_scale, up_weight, up_scale, down_weight, down_scale,
      activation, expert_ids, topk_weights, gate_tmp, up_tmp, intermediate_tmp,
      expert_output_tmp, output, stream_ptr);
}

extern "C" int netra_mxfp4_sgl_prefill_repack(
    void* source, void* destination, void* stream_ptr) {
  return netra::gfx1151::prefill::repack(source, destination, stream_ptr);
}

extern "C" int netra_mxfp4_sgl_prefill_gate_up(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* activation_groups, void* expert_ids, void* gate_output,
    void* up_output, void* intermediate_output, unsigned group_count,
    void* stream_ptr) {
  return netra::gfx1151::prefill::gate_up(
      gate_weight, gate_scale, up_weight, up_scale, activation_groups,
      expert_ids, gate_output, up_output, intermediate_output, group_count,
      stream_ptr);
}

extern "C" int netra_mxfp4_sgl_prefill_down(
    void* down_weight, void* down_scale, void* activation_groups,
    void* expert_output, void* expert_ids, unsigned group_count,
    void* stream_ptr) {
  return netra::gfx1151::prefill::down(
      down_weight, down_scale, activation_groups, expert_output, expert_ids,
      group_count, stream_ptr);
}

extern "C" int netra_mxfp4_sgl_m12_gate_up(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* activation_groups, void* expert_ids, void* gate_output,
    void* up_output, void* intermediate_output, unsigned group_count,
    void* stream_ptr) {
  return netra::gfx1151::verify::gate_up(
      gate_weight, gate_scale, up_weight, up_scale, activation_groups,
      expert_ids, gate_output, up_output, intermediate_output, group_count,
      stream_ptr);
}

extern "C" int netra_mxfp4_sgl_m12_down(
    void* down_weight, void* down_scale, void* activation_groups,
    void* expert_output, void* expert_ids, unsigned group_count,
    void* stream_ptr) {
  return netra::gfx1151::verify::down(
      down_weight, down_scale, activation_groups, expert_output, expert_ids,
      group_count, stream_ptr);
}

extern "C" int netra_mxfp4_sgl_linear(
    void* packed, void* scale, void* activation, void* output, unsigned m,
    unsigned n, unsigned k, void* stream_ptr) {
  return netra::gfx1151::decode::linear(
      packed, scale, activation, output, m, n, k, stream_ptr);
}

extern "C" int netra_mxfp4_sgl_linear_prefill(
    void* packed, void* scale, void* activation_groups, void* output_groups,
    unsigned group_count, unsigned n, unsigned k, void* stream_ptr) {
  return netra::gfx1151::prefill::linear(
      packed, scale, activation_groups, output_groups, group_count, n, k,
      stream_ptr);
}

extern "C" int netra_mxfp4_sgl_linear_prefill_repack(
    void* source, void* destination, unsigned n, unsigned k,
    void* stream_ptr) {
  return netra::gfx1151::prefill::linear_repack(
      source, destination, n, k, stream_ptr);
}

extern "C" int netra_qkvzba_split_copy(
    void* mixed_qkvz, void* mixed_ba, void* mixed_qkv, void* z, void* b,
    void* a, unsigned token_count, void* stream_ptr) {
  return netra::gfx1151::gdn::qkvzba_split_copy(
      mixed_qkvz, mixed_ba, mixed_qkv, z, b, a, token_count, stream_ptr);
}

extern "C" int netra_extend_attention(
    void* q, void* k_extend, void* v_extend, void* output, void* k_buffer,
    void* v_buffer, void* kv_indices, void* kv_indptr, unsigned tokens,
    float sm_scale, void* stream_ptr) {
  return netra::gfx1151::attention::extend(
      q, k_extend, v_extend, output, k_buffer, v_buffer, kv_indices, kv_indptr,
      tokens, sm_scale, stream_ptr);
}

extern "C" int netra_qk_norm_mrope_gate_kv_store(
    void* qkv, void* q_out, void* k_out, void* gate_out, void* q_weight,
    void* k_weight, void* cos_sin, void* positions, void* k_cache,
    void* v_cache, void* cache_loc, unsigned tokens,
    unsigned position_stride_bytes, void* stream_ptr) {
  return netra::gfx1151::attention::qk_norm_mrope_gate_kv_store(
      qkv, q_out, k_out, gate_out, q_weight, k_weight, cos_sin, positions,
      k_cache, v_cache, cache_loc, tokens, position_stride_bytes, stream_ptr);
}

extern "C" int netra_gdn_chunk_o(
    void* q, void* k, void* v, void* h, void* g, void* output,
    void* cu_seqlens, void* chunk_indices, float scale, unsigned tokens,
    void* stream_ptr) {
  return netra::gfx1151::gdn::chunk_o(
      q, k, v, h, g, output, cu_seqlens, chunk_indices, scale, tokens,
      stream_ptr);
}

extern "C" int netra_gdn_recompute_w_u(
    void* k, void* v, void* beta, void* w, void* u, void* A, void* g,
    unsigned tokens, void* stream_ptr) {
  return netra::gfx1151::gdn::recompute_w_u(
      k, v, beta, w, u, A, g, tokens, stream_ptr);
}

extern "C" int netra_causal_conv1d(
    void* x, void* weight, void* state, void* cache_index,
    void* has_initial, void* output, void* stream_ptr) {
  return netra::gfx1151::gdn::causal_conv1d(
      x, weight, state, cache_index, has_initial, output, stream_ptr);
}

extern "C" int netra_expert_weighted_reduce_fp64(
    void* expert, void* positions, void* weights, void* output,
    unsigned tokens, void* stream_ptr) {
  return netra::gfx1151::moe::expert_weighted_reduce_fp64(
      expert, positions, weights, output, tokens, stream_ptr);
}

extern "C" int netra_expert_activation_pack(
    void* hidden, void* pair_tokens, void* position, void* output,
    unsigned pair_count, unsigned total_rows, void* stream_ptr) {
  return netra::gfx1151::moe::expert_activation_pack(
      hidden, pair_tokens, position, output, pair_count, total_rows,
      stream_ptr);
}
