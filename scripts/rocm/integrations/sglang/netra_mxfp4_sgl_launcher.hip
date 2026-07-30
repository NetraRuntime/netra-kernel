// SPDX-License-Identifier: MIT
// Launch-only bridge from SGLang/PyTorch to raw gfx1151 AMDGCN code objects.

#include <hip/hip_runtime.h>

#include <array>
#include <cstdio>
#include <mutex>
#include <string>

#ifndef NETRA_HSACO_DIR
#define NETRA_HSACO_DIR "/root/netra-mxfp4-gfx1151/build/sglang"
#endif

#ifndef NETRA_EXTEND_ATTENTION_GRID_Y
#define NETRA_EXTEND_ATTENTION_GRID_Y 4
#endif
#ifndef NETRA_EXTEND_ATTENTION_BLOCK_X
#define NETRA_EXTEND_ATTENTION_BLOCK_X 512
#endif
#ifndef NETRA_PREFILL_GATE_GRID_X
#define NETRA_PREFILL_GATE_GRID_X 8
#endif
#ifndef NETRA_PREFILL_GATE_BLOCK_X
#define NETRA_PREFILL_GATE_BLOCK_X 128
#endif

namespace {

struct Kernel {
  hipModule_t module{};
  hipFunction_t function{};
};

std::once_flag init_once;
Kernel gate;
Kernel down;
Kernel silu;
Kernel reduce;
Kernel prefill_gate;
Kernel prefill_up_silu;
Kernel prefill_repack;
Kernel prefill_down;
Kernel m12_group_gate_up_silu;
Kernel m12_group_down;
Kernel linear_decode;
Kernel linear_prefill;
Kernel linear_prefill_group4;
Kernel linear_prefill_repack;
Kernel qkvzba_split;
Kernel extend_attention;
Kernel qk_norm_mrope_kv;
Kernel gdn_chunk_o;
Kernel recompute_w_u;
Kernel causal_conv;
Kernel causal_state;
Kernel activation_pack;
Kernel expert_reduce_fp64;
hipError_t init_status = hipSuccess;
std::string init_error;

void load(Kernel& kernel, const char* file, const char* symbol) {
  if (init_status != hipSuccess) return;
  std::string path = std::string(NETRA_HSACO_DIR) + "/" + file;
  init_status = hipModuleLoad(&kernel.module, path.c_str());
  if (init_status != hipSuccess) {
    init_error = "hipModuleLoad(" + path + "): " + hipGetErrorString(init_status);
    return;
  }
  init_status = hipModuleGetFunction(&kernel.function, kernel.module, symbol);
  if (init_status != hipSuccess) {
    init_error =
        "hipModuleGetFunction(" + std::string(symbol) + "): " +
        hipGetErrorString(init_status);
  }
}

void initialize() {
  load(gate, "mxfp4_sgl_decode_gate_gfx1151.hsaco",
       "mxfp4_decode_gate_gfx1151");
  load(down, "mxfp4_sgl_decode_down_gfx1151.hsaco",
       "mxfp4_decode_down_gfx1151");
  load(silu, "silu_mul_bf16_gfx1151.hsaco", "silu_mul_bf16_gfx1151");
  load(reduce, "mxfp4_sgl_reduce_gfx1151.hsaco",
       "mxfp4_sgl_reduce_gfx1151");
  load(prefill_gate, "mxfp4_prefill_gate_wmma_gfx1151.hsaco",
       "mxfp4_prefill_gate_wmma_gfx1151");
  load(prefill_up_silu, "mxfp4_prefill_up_silu_wmma_gfx1151.hsaco",
       "mxfp4_prefill_up_silu_wmma_gfx1151");
  load(prefill_repack, "mxfp4_prefill_repack_dword_gfx1151.hsaco",
       "mxfp4_prefill_repack_dword_gfx1151");
  load(prefill_down, "mxfp4_prefill_down_wmma_gfx1151.hsaco",
       "mxfp4_prefill_down_wmma_gfx1151");
  load(linear_decode, "mxfp4_sgl_linear_decode_gfx1151.hsaco",
       "mxfp4_sgl_linear_decode_gfx1151");
  load(m12_group_gate_up_silu,
       "mxfp4_m12_group_gate_up_silu_wmma_gfx1151.hsaco",
       "mxfp4_m12_group_gate_up_silu_wmma_gfx1151");
  load(m12_group_down, "mxfp4_m12_group_down_wmma_gfx1151.hsaco",
       "mxfp4_m12_group_down_wmma_gfx1151");
  load(linear_prefill_repack,
       "mxfp4_sgl_linear_prefill_repack_dword_gfx1151.hsaco",
       "mxfp4_sgl_linear_prefill_repack_dword_gfx1151");
  load(linear_prefill, "mxfp4_sgl_linear_prefill_wmma_gfx1151.hsaco",
       "mxfp4_sgl_linear_prefill_wmma_gfx1151");
  load(linear_prefill_group4,
       "mxfp4_sgl_linear_prefill_group4_a_gfx1151.hsaco",
       "mxfp4_sgl_linear_prefill_group4_a_gfx1151");
  load(qkvzba_split, "qkvzba_split_copy_gfx1151.hsaco",
       "qkvzba_split_copy_gfx1151");
  load(extend_attention, "extend_attention_wmma_n64_gfx1151.hsaco",
       "extend_attention_wmma_n64_gfx1151");
  load(qk_norm_mrope_kv, "qk_norm_mrope_gate_kv_store_gfx1151.hsaco",
       "qk_norm_mrope_gate_kv_store_gfx1151");
  load(gdn_chunk_o, "gdn_chunk_o_bv32_gfx1151.hsaco",
       "gdn_chunk_o_bv32_gfx1151");
  load(recompute_w_u, "recompute_w_u_ordered_gfx1151.hsaco",
       "recompute_w_u_reuse_a_ordered_gfx1151");
  load(causal_conv, "causal_conv1d_stream64_ordered_gfx1151.hsaco",
       "causal_conv1d_stream64_ordered_gfx1151");
  load(causal_state, "causal_conv1d_state_update_gfx1151.hsaco",
       "causal_conv1d_state_update_gfx1151");
  load(activation_pack, "expert_activation_pack_gfx1151.hsaco",
       "expert_activation_pack_gfx1151");
  load(expert_reduce_fp64, "expert_weighted_reduce_top8_fp64_gfx1151.hsaco",
       "expert_weighted_reduce_top8_fp64_gfx1151");
}

template <typename Args>
hipError_t launch(hipFunction_t function, unsigned gx, unsigned gy, unsigned bx,
                  hipStream_t stream, Args& args) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER,
      &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE,
      &size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(function, gx, gy, 1, bx, 1, 1, 0, stream, nullptr,
                               config);
}

template <typename Args>
hipError_t launch_3d(hipFunction_t function, unsigned gx, unsigned gy,
                     unsigned gz, unsigned bx, hipStream_t stream, Args& args) {
  size_t size = sizeof(args);
  void* config[] = {
      HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
      HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
      HIP_LAUNCH_PARAM_END,
  };
  return hipModuleLaunchKernel(function, gx, gy, gz, bx, 1, 1, 0, stream,
                               nullptr, config);
}

struct alignas(8) FourPointers {
  void* a;
  void* b;
  void* c;
  void* d;
};

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
struct alignas(8) SevenPointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
  void* f;
  void* g;
};


struct alignas(8) FivePointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
};

struct alignas(8) TwoPointers {
  void* a;
  void* b;
};

struct alignas(8) ThreePointers {
  void* a;
  void* b;
  void* c;
};

struct alignas(8) SixPointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
  void* f;
};

struct alignas(8) LinearArgs {
  void* packed;
  void* scale;
  void* activation;
  void* output;
  unsigned n;
  unsigned k;
};

struct alignas(8) LinearRepackArgs {
  void* source;
  void* destination;
  unsigned n;
};
static_assert(sizeof(LinearRepackArgs) == 24);

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

struct alignas(8) ActivationPackArgs {
  void* hidden;
  void* pair_tokens;
  void* position;
  void* output;
  unsigned pair_count;
  unsigned total_rows;
};
static_assert(sizeof(ActivationPackArgs) == 40);

struct alignas(8) CausalConvArgs {
  void* x;
  void* weight;
  void* state;
  void* cache_index;
  void* has_initial;
  void* output;
};
static_assert(sizeof(CausalConvArgs) == 48);

struct alignas(8) CausalStateArgs {
  void* x;
  void* state;
  void* cache_index;
};
static_assert(sizeof(CausalStateArgs) == 24);

}  // namespace


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
extern "C" int netra_mxfp4_sgl_init() {
  std::call_once(init_once, initialize);
  return static_cast<int>(init_status);
}

extern "C" const char* netra_mxfp4_sgl_error() {
  if (!init_error.empty()) return init_error.c_str();
  return hipGetErrorString(init_status);
}

extern "C" int netra_mxfp4_sgl_decode(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* down_weight, void* down_scale, void* activation, void* expert_ids,
    void* topk_weights, void* gate_tmp, void* up_tmp, void* intermediate_tmp,
    void* expert_output_tmp, void* output, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);

  constexpr size_t gate_bytes = 8 * 512 * sizeof(float);
  hipError_t status = hipMemsetAsync(gate_tmp, 0, gate_bytes, stream);
  if (status != hipSuccess) return 10000 + static_cast<int>(status);
  status = hipMemsetAsync(up_tmp, 0, gate_bytes, stream);
  if (status != hipSuccess) return 20000 + static_cast<int>(status);

  FivePointers gate_args{
      gate_weight, gate_scale, activation, gate_tmp, expert_ids};
  status = launch(gate.function, 1, 16, 128, stream, gate_args);
  if (status != hipSuccess) return 30000 + static_cast<int>(status);

  FivePointers up_args{up_weight, up_scale, activation, up_tmp, expert_ids};
  status = launch(gate.function, 1, 16, 128, stream, up_args);
  if (status != hipSuccess) return 40000 + static_cast<int>(status);

  ThreePointers silu_args{gate_tmp, up_tmp, intermediate_tmp};
  status = launch(silu.function, 16, 1, 256, stream, silu_args);
  if (status != hipSuccess) return 50000 + static_cast<int>(status);

  FivePointers down_args{
      down_weight, down_scale, intermediate_tmp, expert_output_tmp, expert_ids};
  status = launch(down.function, 2, 8, 256, stream, down_args);
  if (status != hipSuccess) return 60000 + static_cast<int>(status);

  ThreePointers reduce_args{expert_output_tmp, topk_weights, output};
  status = launch(reduce.function, 8, 1, 256, stream, reduce_args);
  return status == hipSuccess ? 0 : 70000 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_prefill_repack(
    void* source, void* destination, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  TwoPointers args{source, destination};
  hipError_t status =
      launch(prefill_repack.function, 131072, 1, 256, stream, args);
  return status == hipSuccess ? 0 : 80000 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_prefill_gate_up(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* activation_groups, void* expert_ids, void* gate_output,
    void* up_output, void* intermediate_output, unsigned group_count,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);

  FivePointers gate_args{
      gate_weight, gate_scale, activation_groups, gate_output, expert_ids};
  hipError_t status =
      launch(prefill_gate.function, NETRA_PREFILL_GATE_GRID_X, group_count,
             NETRA_PREFILL_GATE_BLOCK_X, stream, gate_args);
  if (status != hipSuccess) return 81000 + static_cast<int>(status);

  (void)up_output;
  SixPointers up_silu_args{up_weight, up_scale, activation_groups, gate_output,
                           intermediate_output, expert_ids};
  status = launch(prefill_up_silu.function, NETRA_PREFILL_GATE_GRID_X,
                  group_count, NETRA_PREFILL_GATE_BLOCK_X, stream,
                  up_silu_args);
  return status == hipSuccess ? 0 : 82000 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_m12_gate_up(
    void* gate_weight, void* gate_scale, void* up_weight, void* up_scale,
    void* activation_groups, void* expert_ids, void* gate_output,
    void* up_output, void* intermediate_output, unsigned group_count,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (group_count == 0) return 83501;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);

  SevenPointers gate_up_silu_args{
      gate_weight, gate_scale, up_weight, up_scale, activation_groups,
      expert_ids, intermediate_output};
  hipError_t status = launch(m12_group_gate_up_silu.function, 32, group_count,
                             32, stream, gate_up_silu_args);
  return status == hipSuccess ? 0 : 83510 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_m12_down(
    void* down_weight, void* down_scale, void* activation_groups,
    void* expert_output, void* expert_ids, unsigned group_count,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (group_count == 0) return 83701;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  FivePointers down_args{
      down_weight, down_scale, activation_groups, expert_output, expert_ids};
  hipError_t status =
      launch(m12_group_down.function, 128, group_count, 32, stream, down_args);
  return status == hipSuccess ? 0 : 83710 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_prefill_down(
    void* down_weight, void* down_scale, void* activation_groups,
    void* expert_output, void* expert_ids, unsigned group_count,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  FivePointers down_args{
      down_weight, down_scale, activation_groups, expert_output, expert_ids};
  hipError_t status =
      launch(prefill_down.function, 128, group_count, 32, stream, down_args);
  return status == hipSuccess ? 0 : 84000 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_linear(
    void* packed, void* scale, void* activation, void* output,
    unsigned m, unsigned n, unsigned k, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if ((n & 3U) || (k & 31U) || (n > 512 && (n & 511U))) return 90001;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  auto* x = static_cast<unsigned char*>(activation);
  auto* y = static_cast<unsigned char*>(output);
  for (unsigned row = 0; row < m; ++row) {
    LinearArgs args{
        packed, scale, x + static_cast<size_t>(row) * k * 2,
        y + static_cast<size_t>(row) * n * 2, n, k};
    unsigned block_size = n < 512 ? n / 4 : 128;
    hipError_t status = launch(
        linear_decode.function, (n + 511) / 512, 1, block_size, stream, args);
    if (status != hipSuccess) return 91000 + static_cast<int>(status);
  }
  return 0;
}

extern "C" int netra_mxfp4_sgl_linear_prefill(
    void* packed, void* scale, void* activation_groups, void* output_groups,
    unsigned group_count, unsigned n, unsigned k, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if ((n & 15U) || (k & 31U) || group_count == 0) return 92001;
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  LinearArgs args{
      packed, scale, activation_groups, output_groups, n, k};
  hipFunction_t function = linear_prefill.function;
  unsigned grid_x = n / 16;
  unsigned block_x = 32;
  if (n == 64 || n == 2048) {
    function = linear_prefill_group4.function;
    grid_x = n / 64;
    block_x = 128;
  }
  hipError_t status = launch(
      function, grid_x, group_count, block_x, stream, args);
  return status == hipSuccess ? 0 : 93000 + static_cast<int>(status);
}

extern "C" int netra_mxfp4_sgl_linear_prefill_repack(
    void* source, void* destination, unsigned n, unsigned k,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if ((n & 7U) || (k & 31U) || n == 0 || k == 0) return 92501;
  LinearRepackArgs args{source, destination, n};
  hipError_t status = launch(
      linear_prefill_repack.function, n / 8, k / 32, 32,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 92500 + static_cast<int>(status);
}

extern "C" int netra_qkvzba_split_copy(
    void* mixed_qkvz, void* mixed_ba, void* mixed_qkv, void* z, void* b,
    void* a, unsigned token_count, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (token_count == 0) return 0;
  SixPointers args{mixed_qkvz, mixed_ba, mixed_qkv, z, b, a};
  hipError_t status = launch(
      qkvzba_split.function, 7, token_count, 256,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 94000 + static_cast<int>(status);
}

extern "C" int netra_extend_attention(
    void* q, void* k_extend, void* v_extend, void* output,
    void* k_buffer, void* v_buffer, void* kv_indices, void* kv_indptr,
    unsigned tokens, float sm_scale, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (tokens == 0 || (tokens & 63U)) return 95001;
  ExtendAttentionArgs args{
      q, k_extend, v_extend, output, k_buffer, v_buffer, kv_indices,
      kv_indptr, tokens, sm_scale};
  hipError_t status = launch(
      extend_attention.function, tokens / 64, NETRA_EXTEND_ATTENTION_GRID_Y,
      NETRA_EXTEND_ATTENTION_BLOCK_X,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95000 + static_cast<int>(status);
}

extern "C" int netra_qk_norm_mrope_gate_kv_store(
    void* qkv, void* q_out, void* k_out, void* gate_out,
    void* q_weight, void* k_weight, void* cos_sin, void* positions,
    void* k_cache, void* v_cache, void* cache_loc, unsigned tokens,
    unsigned position_stride_bytes,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (tokens == 0) return 95501;
  QkNormMropeKvArgs args{
      qkv, q_out, k_out, gate_out, q_weight, k_weight, cos_sin,
      positions, k_cache, v_cache, cache_loc, tokens, position_stride_bytes};
  hipError_t status = launch(
      qk_norm_mrope_kv.function, tokens, 1, 128,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95500 + static_cast<int>(status);
}

extern "C" int netra_gdn_chunk_o(
    void* q, void* k, void* v, void* h, void* g, void* output,
    void* cu_seqlens, void* chunk_indices, float scale, unsigned tokens,
    void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (tokens != 8192) return 96001;
  GdnChunkOArgs args{
      q, k, v, h, g, output, cu_seqlens, chunk_indices, scale, tokens};
  hipError_t status = launch_3d(
      gdn_chunk_o.function, 4, 128, 32, 128,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96000 + static_cast<int>(status);
}

extern "C" int netra_gdn_recompute_w_u(
    void* k, void* v, void* beta, void* w, void* u, void* A, void* g,
    unsigned tokens, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (tokens != 8192) return 96501;
  RecomputeWUArgs args{
      k, v, beta, w, u, A, g, nullptr, nullptr, tokens};
  hipError_t status = launch(
      recompute_w_u.function, 128, 32, 64,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96500 + static_cast<int>(status);
}

extern "C" int netra_causal_conv1d(
    void* x, void* weight, void* state, void* cache_index,
    void* has_initial, void* output, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  auto stream = reinterpret_cast<hipStream_t>(stream_ptr);
  CausalConvArgs conv_args{x, weight, state, cache_index, has_initial, output};
  hipError_t status = launch(
      causal_conv.function, 64, 128, 128, stream, conv_args);
  if (status != hipSuccess) return 96700 + static_cast<int>(status);
  CausalStateArgs state_args{x, state, cache_index};
  status = launch(causal_state.function, 64, 1, 128, stream, state_args);
  return status == hipSuccess ? 0 : 96800 + static_cast<int>(status);
}

extern "C" int netra_expert_weighted_reduce_fp64(
    void* expert, void* positions, void* weights, void* output,
    unsigned tokens, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (tokens == 0) return 96901;
  FourPointers args{expert, positions, weights, output};
  hipError_t status = launch(
      expert_reduce_fp64.function, 8, tokens, 256,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 96900 + static_cast<int>(status);
}

extern "C" int netra_expert_activation_pack(
    void* hidden, void* pair_tokens, void* position, void* output,
    unsigned pair_count, unsigned total_rows, void* stream_ptr) {
  std::call_once(init_once, initialize);
  if (init_status != hipSuccess) return static_cast<int>(init_status);
  if (pair_count == 0 || total_rows < pair_count) return 97001;
  ActivationPackArgs args{
      hidden, pair_tokens, position, output, pair_count, total_rows};
  hipError_t status = launch(
      activation_pack.function, pair_count, 1, 256,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 97000 + static_cast<int>(status);
}
