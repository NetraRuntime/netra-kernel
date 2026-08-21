// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/gdn/common/causal_conv.inc"
// SPDX-License-Identifier: MIT
//
// Model-independent GDN target-verification causal convolution consuming the
// QKV prefix directly from contiguous QKVZ rows. The selected fixed contract
// determines T, QKVZ, QKV, state strides, and grid topology at assembly time.
//
// One 256-thread wave64 workgroup owns 256 contiguous features of one
// sequence.  Unlike the Triton oracle, the raw kernel has no masked lanes,
// barrier, buffer descriptors, or generic state-length/tree branches.  It
// preserves the full speculative intermediate-window ABI for commit/rollback.

	NETRA_GFX950_MODULE_HEADER 6
	.ifndef NETRA_GDN_QKVZ_GRID_2D
	.set NETRA_GDN_QKVZ_GRID_2D, 0
	.endif
	.if (NETRA_GDN_QKVZ_GRID_2D != 0) && (NETRA_GDN_QKVZ_GRID_2D != 1)
	.error "NETRA_GDN_QKVZ_GRID_2D must be 0 or 1"
	.endif

	.macro NETRA_GDN_QKVZ_CAUSAL_CONV symbol
	NETRA_REQUIRE_GFX950_WAVE64
	.if NETRA_GDN_QKVZ_GRID_2D == 0
	NETRA_REQUIRE_EQ NETRA_TOKENS, 12
	NETRA_REQUIRE_EQ NETRA_K, 2048
	NETRA_REQUIRE_EQ NETRA_N, 12288
	.else
	NETRA_REQUIRE_EQ NETRA_TOKENS, 8
	NETRA_REQUIRE_EQ NETRA_K, 2048
	NETRA_REQUIRE_EQ NETRA_N, 16384
	.endif
	NETRA_KERNEL_ENTRY \symbol, 1
	.if NETRA_GDN_QKVZ_GRID_2D == 0
	s_mov_b32 s20, s2
	.endif
	// Kernargs: x, weight, state, state_indices, intermediate_window,
	// intermediate_indices, output, batch.
	NETRA_LOAD_KERNARG_PTR s[4:5], 0
	NETRA_LOAD_KERNARG_PTR s[6:7], 8
	NETRA_LOAD_KERNARG_PTR s[8:9], 16
	NETRA_LOAD_KERNARG_PTR s[10:11], 24
	NETRA_LOAD_KERNARG_PTR s[12:13], 32
	NETRA_LOAD_KERNARG_PTR s[14:15], 40
	NETRA_LOAD_KERNARG_PTR s[16:17], 48
	NETRA_LOAD_KERNARG_U32 s18, 56
	NETRA_WAIT_LGKM0

	.if NETRA_GDN_QKVZ_GRID_2D == 0
	// One-dimensional grid: workgroup = sequence*32 + 256-feature block.
	s_lshr_b32 s21, s20, 5
	s_and_b32 s22, s20, 31
	.else
	// Two-dimensional grid: X is one of 40 feature blocks, Y is sequence.
	s_mov_b32 s22, s2
	s_mov_b32 s21, s3
	.endif
	s_cmp_ge_u32 s21, s18
	s_cbranch_scc1 .Lend
	.if NETRA_GDN_QKVZ_GRID_2D == 1
	s_cmp_ge_u32 s22, 40
	s_cbranch_scc1 .Lend
	.endif
	s_lshl_b32 s25, s21, 2
	s_load_dword s23, s[10:11], s25
	s_load_dword s24, s[14:15], s25
	NETRA_WAIT_LGKM0
	// Captured B64 graphs replay smaller live batches with -1 in padded cache
	// slots.  Triton's USE_PAD_SLOT path returns before touching either cache;
	// preserve the same contract in raw assembly.
	s_cmp_eq_u32 s23, 0xffffffff
	s_cbranch_scc1 .Lend
	s_cmp_eq_u32 s24, 0xffffffff
	s_cbranch_scc1 .Lend

	// Sequence-local QKVZ source plus the 256-feature QKV block.
	.if NETRA_GDN_QKVZ_GRID_2D == 0
	s_mul_i32 s25, s21, 0x48000
	.else
	s_lshl_b32 s25, s21, 18
	.endif
	s_lshl_b32 s26, s22, 9
	s_add_u32 s25, s25, s26
	s_add_u32 s4, s4, s25
	s_addc_u32 s5, s5, 0
	// Packed output remains compact for the selected fixed contract.
	.if NETRA_GDN_QKVZ_GRID_2D == 0
	s_mul_i32 s25, s21, 0x30000
	.else
	s_mul_i32 s25, s21, 0x28000
	.endif
	s_add_u32 s25, s25, s26
	s_add_u32 s16, s16, s25
	s_addc_u32 s17, s17, 0

	// Per-feature four-column weight base for this block.
	s_lshl_b32 s25, s22, 11
	s_add_u32 s6, s6, s25
	s_addc_u32 s7, s7, 0

	// Live cache state is contiguous (cache,D,3).  The serving cache has
	// millions of slots, so slot*49152 exceeds 32 bits.  Preserve both halves
	// of the product before adding the small feature-block displacement.
	.if NETRA_GDN_QKVZ_GRID_2D == 0
	s_mul_i32 s25, s23, 0xc000
	s_mul_hi_u32 s26, s23, 0xc000
	.else
	s_mul_i32 s25, s23, 0xf000
	s_mul_hi_u32 s26, s23, 0xf000
	.endif
	s_mul_i32 s27, s22, 0x600
	s_add_u32 s25, s25, s27
	s_addc_u32 s26, s26, 0
	s_add_u32 s8, s8, s25
	s_addc_u32 s9, s9, s26

	// Speculative window is contiguous (cache,12,D,3).  Its 589824-byte slot
	// stride crosses 4 GiB even sooner, so widen this address independently.
	.if NETRA_GDN_QKVZ_GRID_2D == 0
	s_mul_i32 s25, s24, 0x90000
	s_mul_hi_u32 s26, s24, 0x90000
	.else
	s_mul_i32 s25, s24, 0x78000
	s_mul_hi_u32 s26, s24, 0x78000
	.endif
	s_mul_i32 s27, s22, 0x600
	s_add_u32 s25, s25, s27
	s_addc_u32 s26, s26, 0
	s_add_u32 s12, s12, s25
	s_addc_u32 s13, s13, s26

	// Lane byte offsets for BF16 feature, four BF16 weights, and 3-BF16
	// intermediate records.
	v_lshlrev_b32_e32 v1, 1, v0
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshlrev_b32_e32 v3, 2, v0
	v_lshl_add_u32 v3, v0, 1, v3

	global_load_dword v30, v3, s[8:9]
	global_load_ushort v6, v3, s[8:9] offset:4
	global_load_dwordx2 v[16:17], v2, s[6:7]
	NETRA_WAIT_VM0
	v_lshlrev_b32_e32 v4, 16, v30
	v_and_b32_e32 v5, 0xffff0000, v30
	v_lshlrev_b32_e32 v6, 16, v6
	v_lshlrev_b32_e32 v7, 16, v16
	v_and_b32_e32 v8, 0xffff0000, v16
	v_lshlrev_b32_e32 v9, 16, v17
	v_and_b32_e32 v10, 0xffff0000, v17
	v_lshlrev_b32_e32 v2, 1, v0

	s_mov_b32 s26, 0x42800000	// 64.0f
	s_mov_b32 s27, -64		// ldexp compensation
	s_mov_b32 s28, 0x3fb8aa3b	// log2(e)
	s_mov_b32 s29, 0xc2fc0000	// -126.0f
	v_mov_b32_e32 v31, s26
	v_mov_b32_e32 v32, s27

	.rept NETRA_TOKENS
	NETRA_GDN_CONV_TOKEN_EXACT
	.endr

	// Persist the final three BF16 inputs to the contiguous cache.
	v_cvt_pk_bf16_f32 v29, v4, v5
	v_cvt_pk_bf16_f32 v30, v6, v6
	v_lshlrev_b32_e32 v3, 2, v0
	v_lshl_add_u32 v3, v0, 1, v3
	global_store_dword v3, v29, s[8:9]
	global_store_short v3, v30, s[8:9] offset:4
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y NETRA_GDN_QKVZ_GRID_2D
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_accum_offset 36
		.amdhsa_next_free_sgpr 32
		.amdhsa_reserve_vcc 1
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
      - { .name: qkvz_bf16, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: weight_bf16, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: state_bf16, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_write }
      - { .name: state_indices_i32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: intermediate_window_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: intermediate_indices_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: batch, .offset: 56, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 34
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 33
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm
