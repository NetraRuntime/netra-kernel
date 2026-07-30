// SPDX-License-Identifier: MIT
#pragma once

namespace netra::gfx1151 {

struct alignas(8) TwoPointers {
  void* a;
  void* b;
};
static_assert(sizeof(TwoPointers) == 16);
static_assert(alignof(TwoPointers) == 8);

struct alignas(8) ThreePointers {
  void* a;
  void* b;
  void* c;
};
static_assert(sizeof(ThreePointers) == 24);
static_assert(alignof(ThreePointers) == 8);

struct alignas(8) FourPointers {
  void* a;
  void* b;
  void* c;
  void* d;
};
static_assert(sizeof(FourPointers) == 32);
static_assert(alignof(FourPointers) == 8);

struct alignas(8) FivePointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
};
static_assert(sizeof(FivePointers) == 40);
static_assert(alignof(FivePointers) == 8);

struct alignas(8) SixPointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
  void* f;
};
static_assert(sizeof(SixPointers) == 48);
static_assert(alignof(SixPointers) == 8);

struct alignas(8) SevenPointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
  void* f;
  void* g;
};
static_assert(sizeof(SevenPointers) == 56);
static_assert(alignof(SevenPointers) == 8);

struct alignas(8) EightPointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
  void* f;
  void* g;
  void* h;
};
static_assert(sizeof(EightPointers) == 64);
static_assert(alignof(EightPointers) == 8);

struct alignas(8) LinearArgs {
  void* packed;
  void* scale;
  void* activation;
  void* output;
  unsigned n;
  unsigned k;
};
static_assert(sizeof(LinearArgs) == 40);
static_assert(alignof(LinearArgs) == 8);

struct alignas(8) LinearRepackArgs {
  void* source;
  void* destination;
  unsigned n;
};
static_assert(sizeof(LinearRepackArgs) == 24);
static_assert(alignof(LinearRepackArgs) == 8);

struct alignas(8) ExtendAttentionArgs {
  void* q;
  void* k_extend;
  void* v_extend;
  void* output;
  void* k_buffer;
  void* v_buffer;
  void* kv_indices;
  void* kv_indptr;
  unsigned tokens;
  float sm_scale;
};
static_assert(sizeof(ExtendAttentionArgs) == 72);
static_assert(alignof(ExtendAttentionArgs) == 8);

struct alignas(8) QkNormMropeKvArgs {
  void* qkv;
  void* q_out;
  void* k_out;
  void* gate_out;
  void* q_weight;
  void* k_weight;
  void* cos_sin;
  void* positions;
  void* k_cache;
  void* v_cache;
  void* cache_loc;
  unsigned tokens;
  unsigned position_stride_bytes;
};
static_assert(sizeof(QkNormMropeKvArgs) == 96);
static_assert(alignof(QkNormMropeKvArgs) == 8);

struct alignas(8) ActivationPackArgs {
  void* hidden;
  void* pair_tokens;
  void* position;
  void* output;
  unsigned pair_count;
  unsigned total_rows;
};
static_assert(sizeof(ActivationPackArgs) == 40);
static_assert(alignof(ActivationPackArgs) == 8);

struct alignas(8) CausalConvArgs {
  void* x;
  void* weight;
  void* state;
  void* cache_index;
  void* has_initial;
  void* output;
};
static_assert(sizeof(CausalConvArgs) == 48);
static_assert(alignof(CausalConvArgs) == 8);

struct alignas(8) CausalStateArgs {
  void* x;
  void* state;
  void* cache_index;
};
static_assert(sizeof(CausalStateArgs) == 24);
static_assert(alignof(CausalStateArgs) == 8);

struct alignas(8) GdnChunkOArgs {
  void* q;
  void* k;
  void* v;
  void* h;
  void* g;
  void* output;
  void* cu_seqlens;
  void* chunk_indices;
  float scale;
  unsigned tokens;
};
static_assert(sizeof(GdnChunkOArgs) == 72);
static_assert(alignof(GdnChunkOArgs) == 8);

struct alignas(8) RecomputeWUArgs {
  void* k;
  void* v;
  void* beta;
  void* w;
  void* u;
  void* A;
  void* g;
  void* cu_seqlens;
  void* chunk_indices;
  unsigned tokens;
};
static_assert(sizeof(RecomputeWUArgs) == 80);
static_assert(alignof(RecomputeWUArgs) == 8);

}  // namespace netra::gfx1151
