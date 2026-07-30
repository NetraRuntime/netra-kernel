// SPDX-License-Identifier: MIT
#pragma once

#include <hip/hip_runtime.h>

#include <cstring>
#include <mutex>
#include <string>

#include "runtime/gfx1151/common/config.h"

namespace netra::gfx1151 {

struct LaunchMetadata {
  unsigned grid_x;
  unsigned grid_y;
  unsigned grid_z;
  unsigned block_x;
};

struct KernelDescriptor {
  const char* hsaco_filename;
  const char* symbol_name;
  LaunchMetadata launch;
};

struct LoadedKernel {
  hipModule_t module{};
  hipFunction_t function{};
  const KernelDescriptor* descriptor;
};

static constexpr KernelDescriptor kDecodeGate{
    "mxfp4_sgl_decode_gate_gfx1151.hsaco", "mxfp4_decode_gate_gfx1151",
    {1, 16, 1, 128}};
static constexpr KernelDescriptor kDecodeDown{
    "mxfp4_sgl_decode_down_gfx1151.hsaco", "mxfp4_decode_down_gfx1151",
    {2, 8, 1, 256}};
static constexpr KernelDescriptor kSiluMul{
    "silu_mul_bf16_gfx1151.hsaco", "silu_mul_bf16_gfx1151",
    {16, 1, 1, 256}};
static constexpr KernelDescriptor kDecodeReduce{
    "mxfp4_sgl_reduce_gfx1151.hsaco", "mxfp4_sgl_reduce_gfx1151",
    {8, 1, 1, 256}};
static constexpr KernelDescriptor kPrefillGate{
    "mxfp4_prefill_gate_wmma_gfx1151.hsaco",
    "mxfp4_prefill_gate_wmma_gfx1151",
    {NETRA_PREFILL_GATE_GRID_X, 0, 1, NETRA_PREFILL_GATE_BLOCK_X}};
static constexpr KernelDescriptor kPrefillUpSilu{
    "mxfp4_prefill_up_silu_wmma_gfx1151.hsaco",
    "mxfp4_prefill_up_silu_wmma_gfx1151",
    {NETRA_PREFILL_GATE_GRID_X, 0, 1, NETRA_PREFILL_GATE_BLOCK_X}};
static constexpr KernelDescriptor kPrefillRepack{
    "mxfp4_prefill_repack_dword_gfx1151.hsaco",
    "mxfp4_prefill_repack_dword_gfx1151", {131072, 1, 1, 256}};
static constexpr KernelDescriptor kPrefillDown{
    "mxfp4_prefill_down_wmma_gfx1151.hsaco",
    "mxfp4_prefill_down_wmma_gfx1151", {128, 0, 1, 32}};
static constexpr KernelDescriptor kLinearDecode{
    "mxfp4_sgl_linear_decode_gfx1151.hsaco",
    "mxfp4_sgl_linear_decode_gfx1151", {0, 1, 1, 0}};
static constexpr KernelDescriptor kM12GateUpSilu{
    "mxfp4_m12_group_gate_up_silu_wmma_gfx1151.hsaco",
    "mxfp4_m12_group_gate_up_silu_wmma_gfx1151", {32, 0, 1, 32}};
static constexpr KernelDescriptor kM12Down{
    "mxfp4_m12_group_down_wmma_gfx1151.hsaco",
    "mxfp4_m12_group_down_wmma_gfx1151", {128, 0, 1, 32}};
static constexpr KernelDescriptor kLinearPrefillRepack{
    "mxfp4_sgl_linear_prefill_repack_dword_gfx1151.hsaco",
    "mxfp4_sgl_linear_prefill_repack_dword_gfx1151", {0, 0, 1, 32}};
static constexpr KernelDescriptor kLinearPrefill{
    "mxfp4_sgl_linear_prefill_wmma_gfx1151.hsaco",
    "mxfp4_sgl_linear_prefill_wmma_gfx1151", {0, 0, 1, 32}};
static constexpr KernelDescriptor kLinearPrefillGroup4{
    "mxfp4_sgl_linear_prefill_group4_a_gfx1151.hsaco",
    "mxfp4_sgl_linear_prefill_group4_a_gfx1151", {0, 0, 1, 128}};
static constexpr KernelDescriptor kQkvzbaSplit{
    "qkvzba_split_copy_gfx1151.hsaco", "qkvzba_split_copy_gfx1151",
    {7, 0, 1, 256}};
static constexpr KernelDescriptor kExtendAttention{
    "extend_attention_wmma_n64_gfx1151.hsaco",
    "extend_attention_wmma_n64_gfx1151",
    {0, NETRA_EXTEND_ATTENTION_GRID_Y, 1, NETRA_EXTEND_ATTENTION_BLOCK_X}};
static constexpr KernelDescriptor kQkNormMropeKv{
    "qk_norm_mrope_gate_kv_store_gfx1151.hsaco",
    "qk_norm_mrope_gate_kv_store_gfx1151", {0, 1, 1, 128}};
static constexpr KernelDescriptor kGdnChunkO{
    "gdn_chunk_o_bv32_gfx1151.hsaco", "gdn_chunk_o_bv32_gfx1151",
    {4, 128, 32, 128}};
static constexpr KernelDescriptor kRecomputeWU{
    "recompute_w_u_ordered_gfx1151.hsaco",
    "recompute_w_u_reuse_a_ordered_gfx1151", {128, 32, 1, 64}};
static constexpr KernelDescriptor kCausalConv{
    "causal_conv1d_stream64_ordered_gfx1151.hsaco",
    "causal_conv1d_stream64_ordered_gfx1151", {64, 128, 1, 128}};
static constexpr KernelDescriptor kCausalState{
    "causal_conv1d_state_update_gfx1151.hsaco",
    "causal_conv1d_state_update_gfx1151", {64, 1, 1, 128}};
static constexpr KernelDescriptor kActivationPack{
    "expert_activation_pack_gfx1151.hsaco", "expert_activation_pack_gfx1151",
    {0, 1, 1, 256}};
static constexpr KernelDescriptor kExpertReduceFp64{
    "expert_weighted_reduce_top8_fp64_gfx1151.hsaco",
    "expert_weighted_reduce_top8_fp64_gfx1151", {8, 0, 1, 256}};

struct ModuleRegistry {
  LoadedKernel gate{{}, {}, &kDecodeGate};
  LoadedKernel down{{}, {}, &kDecodeDown};
  LoadedKernel silu{{}, {}, &kSiluMul};
  LoadedKernel reduce{{}, {}, &kDecodeReduce};
  LoadedKernel prefill_gate{{}, {}, &kPrefillGate};
  LoadedKernel prefill_up_silu{{}, {}, &kPrefillUpSilu};
  LoadedKernel prefill_repack{{}, {}, &kPrefillRepack};
  LoadedKernel prefill_down{{}, {}, &kPrefillDown};
  LoadedKernel linear_decode{{}, {}, &kLinearDecode};
  LoadedKernel m12_group_gate_up_silu{{}, {}, &kM12GateUpSilu};
  LoadedKernel m12_group_down{{}, {}, &kM12Down};
  LoadedKernel linear_prefill_repack{{}, {}, &kLinearPrefillRepack};
  LoadedKernel linear_prefill{{}, {}, &kLinearPrefill};
  LoadedKernel linear_prefill_group4{{}, {}, &kLinearPrefillGroup4};
  LoadedKernel qkvzba_split{{}, {}, &kQkvzbaSplit};
  LoadedKernel extend_attention{{}, {}, &kExtendAttention};
  LoadedKernel qk_norm_mrope_kv{{}, {}, &kQkNormMropeKv};
  LoadedKernel gdn_chunk_o{{}, {}, &kGdnChunkO};
  LoadedKernel recompute_w_u{{}, {}, &kRecomputeWU};
  LoadedKernel causal_conv{{}, {}, &kCausalConv};
  LoadedKernel causal_state{{}, {}, &kCausalState};
  LoadedKernel activation_pack{{}, {}, &kActivationPack};
  LoadedKernel expert_reduce_fp64{{}, {}, &kExpertReduceFp64};

  hipError_t status{hipSuccess};
  std::string error;
  int owner_device{-1};
  hipCtx_t owner_context{};

  void load(LoadedKernel& kernel) {
    if (status != hipSuccess) return;
    const KernelDescriptor& descriptor = *kernel.descriptor;
    std::string path{NETRA_HSACO_DIR};
    path.push_back('/');
    path.append(descriptor.hsaco_filename);
    status = hipModuleLoad(&kernel.module, path.c_str());
    if (status != hipSuccess) {
      error.assign("hipModuleLoad(");
      error.append(path);
      error.append("): ");
      error.append(hipGetErrorString(status));
      return;
    }
    status = hipModuleGetFunction(&kernel.function, kernel.module,
                                  descriptor.symbol_name);
    if (status != hipSuccess) {
      error.assign("hipModuleGetFunction(");
      error.append(descriptor.symbol_name);
      error.append("): ");
      error.append(hipGetErrorString(status));
    }
  }

  void record_device_context() {
    if (status != hipSuccess) return;
    status = hipGetDevice(&owner_device);
    if (status != hipSuccess) {
      error.assign("hipGetDevice: ");
      error.append(hipGetErrorString(status));
      return;
    }
    hipDeviceProp_t properties{};
    status = hipGetDeviceProperties(&properties, owner_device);
    if (status != hipSuccess) {
      error.assign("hipGetDeviceProperties: ");
      error.append(hipGetErrorString(status));
      return;
    }
    if (std::strncmp(properties.gcnArchName, "gfx1151", 7) != 0) {
      status = hipErrorInvalidDevice;
      error.assign("Netra gfx1151 runtime initialized on ");
      error.append(properties.gcnArchName);
      return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    status = hipCtxGetCurrent(&owner_context);
#pragma clang diagnostic pop
    if (status != hipSuccess) {
      error.assign("hipCtxGetCurrent: ");
      error.append(hipGetErrorString(status));
    }
  }

  void initialize() {
    load(gate);
    load(down);
    load(silu);
    load(reduce);
    load(prefill_gate);
    load(prefill_up_silu);
    load(prefill_repack);
    load(prefill_down);
    load(linear_decode);
    load(m12_group_gate_up_silu);
    load(m12_group_down);
    load(linear_prefill_repack);
    load(linear_prefill);
    load(linear_prefill_group4);
    load(qkvzba_split);
    load(extend_attention);
    load(qk_norm_mrope_kv);
    load(gdn_chunk_o);
    load(recompute_w_u);
    load(causal_conv);
    load(causal_state);
    load(activation_pack);
    load(expert_reduce_fp64);
    record_device_context();
  }
};

static ModuleRegistry module_registry;
static std::once_flag module_registry_once;

NETRA_GFX1151_ALWAYS_INLINE ModuleRegistry& runtime() { return module_registry; }

NETRA_GFX1151_ALWAYS_INLINE void ensure_initialized() {
  std::call_once(module_registry_once, [] { module_registry.initialize(); });
}

NETRA_GFX1151_ALWAYS_INLINE const char* runtime_error() {
  if (!module_registry.error.empty()) return module_registry.error.c_str();
  return hipGetErrorString(module_registry.status);
}

}  // namespace netra::gfx1151
