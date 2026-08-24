// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
// SPDX-License-Identifier: MIT
//
// Qwen3.6 router projection for deterministic decode/verification:
//   BF16 hidden [rows,2048], BF16 weight [256,2048]
//     -> BF16 router logits [rows,256].
//
// Grid X selects an expert and grid Y selects a token row. Every output uses
// one wave64 with the deployed AITER M=1 skinny-GEMV arithmetic order:
// four eight-element v_pk_mul_f32/v_pk_fma_f32 groups per lane followed by
// its six-step DPP wave reduction. This preserves M=1 arithmetic while
// batching M16 verification into one launch.

	NETRA_GFX950_MODULE_HEADER 6
	.macro NETRA_ROUTER_BF16_GEMV symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M, 16
	NETRA_REQUIRE_EQ NETRA_K, 2048
	NETRA_REQUIRE_EQ NETRA_N, 256
	NETRA_KERNEL_ENTRY \symbol, 1
	// User SGPRs s[0:1] hold the kernarg pointer. System SGPRs s2 and s3
	// hold workgroup IDs X (expert) and Y (row).
	s_mov_b32 s16, s2
	s_mov_b32 s17, s3
	NETRA_LOAD_KERNARG_PTR s[2:3], 0
	NETRA_LOAD_KERNARG_PTR s[4:5], 8
	NETRA_LOAD_KERNARG_PTR s[6:7], 16
	NETRA_WAIT_LGKM0

	// output += row*512 + expert*2
	s_lshl_b32 s18, s17, 9
	s_lshl_b32 s19, s16, 1
	s_add_u32 s18, s18, s19
	NETRA_ADD_U64_INPLACE s2, s3, s18

	// hidden += row*4096
	s_lshl_b32 s18, s17, 12
	NETRA_ADD_U64_INPLACE s4, s5, s18

	// weight += expert*4096
	s_lshl_b32 s18, s16, 12
	NETRA_ADD_U64_INPLACE s6, s7, s18

	// Match the deployed M=1 lane-to-K mapping. Each lane loads four
	// contiguous eight-BF16 chunks at K offsets 0, 512, 1024, and 1536.
	// A wave therefore issues four coalesced 1024-byte vector transactions.
	v_lshlrev_b32_e32 v1, 4, v0
	global_load_dwordx4 v[2:5], v1, s[4:5] offset:0
	global_load_dwordx4 v[18:21], v1, s[6:7] offset:0
	global_load_dwordx4 v[6:9], v1, s[4:5] offset:1024
	global_load_dwordx4 v[22:25], v1, s[6:7] offset:1024
	global_load_dwordx4 v[10:13], v1, s[4:5] offset:2048
	global_load_dwordx4 v[26:29], v1, s[6:7] offset:2048
	global_load_dwordx4 v[14:17], v1, s[4:5] offset:3072
	global_load_dwordx4 v[30:33], v1, s[6:7] offset:3072
	NETRA_WAIT_VM0

	// Match the deployed M=1 skinny-GEMV's BF16 arithmetic exactly. Each
	// dword holds two BF16 values. Shifting/extracting them into the high
	// half of an FP32 register performs the exact BF16->FP32 expansion used
	// by the compiler-generated reference.
	v_mov_b32_e32 v34, 0

	// K lane group 0: packed dwords 0..3.
	NETRA_BF16_DOT4_ACCUM v34, v2, v3, v4, v5, v18, v19, v20, v21, v[40:41], v40, v41, v[42:43], v42, v43, v[44:45], v44, v45, v46

	// K lane group 1: packed dwords 4..7.
	NETRA_BF16_DOT4_ACCUM v34, v6, v7, v8, v9, v22, v23, v24, v25, v[40:41], v40, v41, v[42:43], v42, v43, v[44:45], v44, v45, v46

	// K lane group 2: packed dwords 8..11.
	NETRA_BF16_DOT4_ACCUM v34, v10, v11, v12, v13, v26, v27, v28, v29, v[40:41], v40, v41, v[42:43], v42, v43, v[44:45], v44, v45, v46

	// K lane group 3: packed dwords 12..15.
	NETRA_BF16_DOT4_ACCUM v34, v14, v15, v16, v17, v30, v31, v32, v33, v[40:41], v40, v41, v[42:43], v42, v43, v[44:45], v44, v45, v46

	// Match the deployed six-step DPP reduction and its explicit scheduling
	// nops. Lane 63 receives the final wave sum.
	NETRA_WAVE64_SUM_F32_ROUTER v34

	// Lane 63 rounds the linear result to BF16 and stores one router logit.
	v_and_b32_e32 v36, 63, v0
	v_cmp_eq_u32_e32 vcc, 63, v36
	s_and_saveexec_b64 s[14:15], vcc
	v_cvt_pk_bf16_f32 v37, v34, v34
	v_mov_b32_e32 v38, 0
	global_store_short v38, v37, s[2:3]
	NETRA_WAIT_VM0
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 47
		.amdhsa_accum_offset 48
		.amdhsa_next_free_sgpr 20
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
      - { .name: output_logits_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: hidden_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: router_weight_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 47
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm
