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

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_router_bf16_gemv_gfx950
	.globl qwen36_router_bf16_gemv_gfx950
	.p2align 8
	.type qwen36_router_bf16_gemv_gfx950,@function
qwen36_router_bf16_gemv_gfx950:
	// User SGPRs s[0:1] hold the kernarg pointer. System SGPRs s2 and s3
	// hold workgroup IDs X (expert) and Y (row).
	s_mov_b32 s16, s2
	s_mov_b32 s17, s3
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// output += row*512 + expert*2
	s_lshl_b32 s18, s17, 9
	s_lshl_b32 s19, s16, 1
	s_add_u32 s18, s18, s19
	s_add_u32 s2, s2, s18
	s_addc_u32 s3, s3, 0

	// hidden += row*4096
	s_lshl_b32 s18, s17, 12
	s_add_u32 s4, s4, s18
	s_addc_u32 s5, s5, 0

	// weight += expert*4096
	s_lshl_b32 s18, s16, 12
	s_add_u32 s6, s6, s18
	s_addc_u32 s7, s7, 0

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
	s_waitcnt vmcnt(0)

	// Match the deployed M=1 skinny-GEMV's BF16 arithmetic exactly. Each
	// dword holds two BF16 values. Shifting/extracting them into the high
	// half of an FP32 register performs the exact BF16->FP32 expansion used
	// by the compiler-generated reference.
	v_mov_b32_e32 v34, 0

	// K lane group 0: packed dwords 0..3.
	v_lshlrev_b32_e32 v40, 16, v2
	v_and_b32_e32 v41, 0xffff0000, v2
	v_lshlrev_b32_e32 v42, 16, v18
	v_and_b32_e32 v43, 0xffff0000, v18
	v_pk_mul_f32 v[44:45], v[40:41], v[42:43]
	v_lshlrev_b32_e32 v40, 16, v3
	v_and_b32_e32 v41, 0xffff0000, v3
	v_lshlrev_b32_e32 v42, 16, v19
	v_and_b32_e32 v43, 0xffff0000, v19
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v4
	v_and_b32_e32 v41, 0xffff0000, v4
	v_lshlrev_b32_e32 v42, 16, v20
	v_and_b32_e32 v43, 0xffff0000, v20
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v5
	v_and_b32_e32 v41, 0xffff0000, v5
	v_lshlrev_b32_e32 v42, 16, v21
	v_and_b32_e32 v43, 0xffff0000, v21
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	s_nop 0
	v_add_f32_e32 v46, v44, v45
	v_add_f32_e32 v34, v46, v34

	// K lane group 1: packed dwords 4..7.
	v_lshlrev_b32_e32 v40, 16, v6
	v_and_b32_e32 v41, 0xffff0000, v6
	v_lshlrev_b32_e32 v42, 16, v22
	v_and_b32_e32 v43, 0xffff0000, v22
	v_pk_mul_f32 v[44:45], v[40:41], v[42:43]
	v_lshlrev_b32_e32 v40, 16, v7
	v_and_b32_e32 v41, 0xffff0000, v7
	v_lshlrev_b32_e32 v42, 16, v23
	v_and_b32_e32 v43, 0xffff0000, v23
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v8
	v_and_b32_e32 v41, 0xffff0000, v8
	v_lshlrev_b32_e32 v42, 16, v24
	v_and_b32_e32 v43, 0xffff0000, v24
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v9
	v_and_b32_e32 v41, 0xffff0000, v9
	v_lshlrev_b32_e32 v42, 16, v25
	v_and_b32_e32 v43, 0xffff0000, v25
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	s_nop 0
	v_add_f32_e32 v46, v44, v45
	v_add_f32_e32 v34, v46, v34

	// K lane group 2: packed dwords 8..11.
	v_lshlrev_b32_e32 v40, 16, v10
	v_and_b32_e32 v41, 0xffff0000, v10
	v_lshlrev_b32_e32 v42, 16, v26
	v_and_b32_e32 v43, 0xffff0000, v26
	v_pk_mul_f32 v[44:45], v[40:41], v[42:43]
	v_lshlrev_b32_e32 v40, 16, v11
	v_and_b32_e32 v41, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v27
	v_and_b32_e32 v43, 0xffff0000, v27
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v12
	v_and_b32_e32 v41, 0xffff0000, v12
	v_lshlrev_b32_e32 v42, 16, v28
	v_and_b32_e32 v43, 0xffff0000, v28
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v13
	v_and_b32_e32 v41, 0xffff0000, v13
	v_lshlrev_b32_e32 v42, 16, v29
	v_and_b32_e32 v43, 0xffff0000, v29
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	s_nop 0
	v_add_f32_e32 v46, v44, v45
	v_add_f32_e32 v34, v46, v34

	// K lane group 3: packed dwords 12..15.
	v_lshlrev_b32_e32 v40, 16, v14
	v_and_b32_e32 v41, 0xffff0000, v14
	v_lshlrev_b32_e32 v42, 16, v30
	v_and_b32_e32 v43, 0xffff0000, v30
	v_pk_mul_f32 v[44:45], v[40:41], v[42:43]
	v_lshlrev_b32_e32 v40, 16, v15
	v_and_b32_e32 v41, 0xffff0000, v15
	v_lshlrev_b32_e32 v42, 16, v31
	v_and_b32_e32 v43, 0xffff0000, v31
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v16
	v_and_b32_e32 v41, 0xffff0000, v16
	v_lshlrev_b32_e32 v42, 16, v32
	v_and_b32_e32 v43, 0xffff0000, v32
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	v_lshlrev_b32_e32 v40, 16, v17
	v_and_b32_e32 v41, 0xffff0000, v17
	v_lshlrev_b32_e32 v42, 16, v33
	v_and_b32_e32 v43, 0xffff0000, v33
	v_pk_fma_f32 v[44:45], v[40:41], v[42:43], v[44:45]
	s_nop 0
	v_add_f32_e32 v46, v44, v45
	v_add_f32_e32 v34, v46, v34

	// Match the deployed six-step DPP reduction and its explicit scheduling
	// nops. Lane 63 receives the final wave sum.
	s_nop 0
	v_add_f32_dpp v34, v34, v34 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp v34, v34, v34 wave_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp v34, v34, v34 row_bcast:15 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1

	// Lane 63 rounds the linear result to BF16 and stores one router logit.
	v_and_b32_e32 v36, 63, v0
	v_cmp_eq_u32_e32 vcc, 63, v36
	s_and_saveexec_b64 s[14:15], vcc
	v_cvt_pk_bf16_f32 v37, v34, v34
	v_mov_b32_e32 v38, 0
	global_store_short v38, v37, s[2:3]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_router_bf16_gemv_gfx950
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
	.size qwen36_router_bf16_gemv_gfx950, .Lfunc_end0-qwen36_router_bf16_gemv_gfx950

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
    .name: qwen36_router_bf16_gemv_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: qwen36_router_bf16_gemv_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 47
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
