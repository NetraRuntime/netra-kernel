// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
// SPDX-License-Identifier: MIT
//
// Graph-safe metadata preparation for Qwen3.6 full-attention verification.
// The regular SGLang metadata kernel has already materialized the prefix KV
// indices into unified_indices_i64. This raw gfx950 wave64 kernel reads the
// M<=16 extension slots directly from req_to_token, appends them as int64, and
// emits the causal per-query lengths without allocation or host synchronization.

	NETRA_GFX950_MODULE_HEADER 6
	.macro NETRA_ATTENTION_SPLITSEQ_PREPARE symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 16
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 16
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 2
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 256
	NETRA_REQUIRE_EQ NETRA_KV_SPLITS_MAX, 129
	NETRA_KERNEL_ENTRY \symbol, 1
// Kernargs:
//   0  unified KV indices, int64 [capacity]
//   8  per-query sequence lengths, int32 [16]
//   16 prefix length, int32 device scalar
//   24 req_to_token, int32 [rows,row_stride]
//   32 request pool index, int64 device scalar
//   40 req_to_token row stride in int32 elements
//   44 verify_tokens, uint32
	NETRA_LOAD_KERNARG_U32X8 s[8:15], 0
	NETRA_LOAD_KERNARG_PTR s[16:17], 0x20
	NETRA_LOAD_KERNARG_PTR s[18:19], 0x28
	NETRA_WAIT_LGKM0
s_load_dword s20, s[12:13], 0
s_load_dword s21, s[16:17], 0
	NETRA_WAIT_LGKM0
s_mul_i32 s22, s21, s18

// One wave is launched. Only the first M lanes perform traffic.
v_cmp_lt_u32_e64 vcc, v0, s19
s_and_saveexec_b64 s[24:25], vcc
s_cbranch_execz .Lprepare_done

// Read req_to_token[request,prefix+i] and append it as int64.
v_add_u32_e32 v1, s20, v0
v_add_u32_e32 v1, s22, v1
v_lshlrev_b32_e32 v1, 2, v1
global_load_dword v2, v1, s[14:15]
v_add_u32_e32 v4, s20, v0
v_lshlrev_b32_e32 v1, 3, v4
v_mov_b32_e32 v3, 0
	NETRA_WAIT_VM0
global_store_dwordx2 v1, v[2:3], s[8:9]

// Query i may attend prefix+i+1 keys.
v_add_u32_e32 v4, 1, v4
v_lshlrev_b32_e32 v1, 2, v0
global_store_dword v1, v4, s[10:11]
	NETRA_WAIT_VM0

.Lprepare_done:
s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel \symbol
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 48
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 5
.amdhsa_accum_offset 8
.amdhsa_next_free_sgpr 26
.amdhsa_reserve_vcc 1
.amdhsa_float_round_mode_32 0
.amdhsa_float_round_mode_16_64 0
.amdhsa_float_denorm_mode_32 3
.amdhsa_float_denorm_mode_16_64 3
.amdhsa_dx10_clamp 1
.amdhsa_ieee_mode 1
.amdhsa_tg_split 0
.end_amdhsa_kernel
.text
.Lfunc_end0:
.size \symbol, .Lfunc_end0-\symbol

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: unified_indices_i64, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_write }
      - { .name: sequence_lengths_i32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: prefix_length_i32, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: req_to_token_i32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: req_pool_index_i64, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: req_to_token_stride, .offset: 40, .size: 4,
          .value_kind: by_value }
      - { .name: verify_tokens, .offset: 44, .size: 4,
          .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 26
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 5
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
	.endm
