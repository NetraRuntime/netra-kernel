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
Kernel prefill_down;
Kernel linear_decode;
Kernel linear_prefill;
Kernel qkvzba_split;
Kernel extend_attention;
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
  load(prefill_down, "mxfp4_prefill_down_wmma_gfx1151.hsaco",
       "mxfp4_prefill_down_wmma_gfx1151");
  load(linear_decode, "mxfp4_sgl_linear_decode_gfx1151.hsaco",
       "mxfp4_sgl_linear_decode_gfx1151");
  load(linear_prefill, "mxfp4_sgl_linear_prefill_wmma_gfx1151.hsaco",
       "mxfp4_sgl_linear_prefill_wmma_gfx1151");
  load(qkvzba_split, "qkvzba_split_copy_gfx1151.hsaco",
       "qkvzba_split_copy_gfx1151");
  load(extend_attention, "extend_attention_wmma_n64_gfx1151.hsaco",
       "extend_attention_wmma_n64_gfx1151");
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

struct alignas(8) FivePointers {
  void* a;
  void* b;
  void* c;
  void* d;
  void* e;
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

}  // namespace

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
      launch(prefill_gate.function, 32, group_count, 32, stream, gate_args);
  if (status != hipSuccess) return 81000 + static_cast<int>(status);

  FivePointers up_args{
      up_weight, up_scale, activation_groups, up_output, expert_ids};
  status = launch(prefill_gate.function, 32, group_count, 32, stream, up_args);
  if (status != hipSuccess) return 82000 + static_cast<int>(status);

  ThreePointers silu_args{gate_output, up_output, intermediate_output};
  status = launch(silu.function, group_count * 128, 1, 256, stream, silu_args);
  return status == hipSuccess ? 0 : 83000 + static_cast<int>(status);
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
  hipError_t status = launch(
      linear_prefill.function, n / 16, group_count, 32, stream, args);
  return status == hipSuccess ? 0 : 93000 + static_cast<int>(status);
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
      extend_attention.function, tokens / 64, 16, 128,
      reinterpret_cast<hipStream_t>(stream_ptr), args);
  return status == hipSuccess ? 0 : 95000 + static_cast<int>(status);
}
