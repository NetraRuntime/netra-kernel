// SPDX-License-Identifier: MIT
//
// Rejected arithmetic experiment for the Qwen3.6 linear-attention BA
// projection at M16 verification:
//   BF16 hidden [rows,2048], BF16 weight [64,2048]
//     -> BF16 BA [rows,64].
//
// Grid X selects one output channel and grid Y selects one token row. Every
// output uses one wave64. Each lane consumes four contiguous eight-BF16
// chunks, then the wave performs the same packed-FP32 arithmetic and six-step
// DPP reduction used by the exact Qwen router kernel. The four K chunks are
// loaded in a scalar loop to reduce the live VGPR set for this smaller-N path.
// It is retained because it measured about 6.2 us, but a layer-4 real capture
// differed from the deployed MFMA result by one BF16 ULP and changed DFlash
// verification behavior. It must not be selected as the accepted replacement.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_gdn_ba_bf16_gemv_gfx950
	.globl qwen36_gdn_ba_bf16_gemv_gfx950
	.p2align 8
	.type qwen36_gdn_ba_bf16_gemv_gfx950,@function
qwen36_gdn_ba_bf16_gemv_gfx950:
	// User SGPRs s[0:1] hold the kernarg pointer. System SGPRs s2 and s3
	// hold workgroup IDs X (output channel) and Y (row).
	s_mov_b32 s16, s2
	s_mov_b32 s17, s3
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// output += row*128 + channel*2
	s_lshl_b32 s18, s17, 7
	s_lshl_b32 s19, s16, 1
	s_add_u32 s18, s18, s19
	s_add_u32 s2, s2, s18
	s_addc_u32 s3, s3, 0

	// hidden += row*4096
	s_lshl_b32 s18, s17, 12
	s_add_u32 s4, s4, s18
	s_addc_u32 s5, s5, 0

	// weight += channel*4096
	s_lshl_b32 s18, s16, 12
	s_add_u32 s6, s6, s18
	s_addc_u32 s7, s7, 0

	// Every lane owns eight adjacent K values. Advancing the scalar bases by
	// 1024 bytes visits K groups 0, 512, 1024, and 1536.
	v_lshlrev_b32_e32 v1, 4, v0
	v_mov_b32_e32 v34, 0
	s_mov_b32 s18, 0

.Lgdn_ba_k_loop:
	global_load_dwordx4 v[2:5], v1, s[4:5]
	global_load_dwordx4 v[18:21], v1, s[6:7]
	s_waitcnt vmcnt(0)

	// Expand packed BF16 operands into the upper halves of FP32 registers,
	// preserving the established four-pair multiply/FMA accumulation order.
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

	s_add_u32 s4, s4, 1024
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, 1024
	s_addc_u32 s7, s7, 0
	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 4
	s_cbranch_scc1 .Lgdn_ba_k_loop

	// Lane 63 receives the final wave sum.
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
	.amdhsa_kernel qwen36_gdn_ba_bf16_gemv_gfx950
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
	.size qwen36_gdn_ba_bf16_gemv_gfx950, .Lfunc_end0-qwen36_gdn_ba_bf16_gemv_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_ba_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: hidden_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: ba_weight_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_gdn_ba_bf16_gemv_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_ba_bf16_gemv_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 47
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
