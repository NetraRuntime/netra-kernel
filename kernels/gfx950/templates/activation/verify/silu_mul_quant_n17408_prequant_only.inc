// Netra model-independent fixed-contract assembly tactic.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_SILU_MUL_QUANT_N17408_PREQUANT_ONLY symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_WIDTH, 17408
	NETRA_REQUIRE_EQ NETRA_QUANT_GROUP_SIZE, 128
	NETRA_REQUIRE_EQ NETRA_SCALE_LAYOUT_ID, 1
	NETRA_REQUIRE_EQ NETRA_STORE_BF16, 0
	.text
	.globl	\symbol    ; -- Begin function \symbol
	.p2align	8
	.type	\symbol,@function
\symbol:           ; @\symbol
.Lfunc_begin0:
; %bb.1:
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.2:
.LBB0_0:
	s_mov_b64 s[20:21], s[6:7]
	s_mov_b64 s[4:5], s[2:3]
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshrrev_b32_e32 v1, 4, v0
	v_and_b32_e32 v2, 0x78, v2
	s_lshl_b32 s13, s17, 9
	s_mul_i32 s14, s10, s16
	v_lshl_or_b32 v12, v1, 7, v2
	s_lshl1_add_u32 s0, s14, s13
	v_add_u32_e32 v2, s0, v12
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_lshlrev_b32_e32 v3, 1, v2
	buffer_load_dwordx4 v[6:9], v3, s[4:7], 0 offen
	s_mov_b32 s15, 0x3fb8aa3b
	s_mov_b32 s18, 0xc2fc0000
	v_mov_b32_e32 v13, 0x42800000
	v_add_lshl_u32 v2, v2, s10, 1
	buffer_load_dwordx4 v[2:5], v2, s[4:7], 0 offen
	v_not_b32_e32 v14, 63
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s22, s6
	s_mov_b32 s23, s7
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s6
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v15, 0xffff0000, v6
	v_lshlrev_b32_e32 v16, 16, v6
	v_mul_f32_e64 v10, -v16, s15
	v_mul_f32_e64 v11, -v15, s15
	v_and_b32_e32 v17, 0xffff0000, v7
	v_lshlrev_b32_e32 v18, 16, v7
	v_cmp_gt_f32_e32 vcc, s18, v10
	v_cmp_gt_f32_e64 s[0:1], s18, v11
	v_sub_f32_e32 v6, 0, v16
	v_sub_f32_e32 v7, 0, v15
	v_mul_f32_e64 v21, -v18, s15
	v_mul_f32_e64 v22, -v17, s15
	v_cndmask_b32_e32 v10, 0, v13, vcc
	v_cndmask_b32_e64 v11, 0, v13, s[0:1]
	v_cmp_gt_f32_e64 s[2:3], s18, v21
	v_cmp_gt_f32_e64 s[4:5], s18, v22
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v6
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v7
	v_sub_f32_e32 v19, 0, v18
	v_sub_f32_e32 v20, 0, v17
	v_cndmask_b32_e64 v21, 0, v13, s[2:3]
	v_cndmask_b32_e64 v22, 0, v13, s[4:5]
	v_exp_f32_e32 v10, v10
	v_exp_f32_e32 v11, v11
	v_fmac_f32_e32 v21, 0x3fb8aa3b, v19
	v_fmac_f32_e32 v22, 0x3fb8aa3b, v20
	v_exp_f32_e32 v21, v21
	v_exp_f32_e32 v22, v22
	v_cndmask_b32_e32 v6, 0, v14, vcc
	v_cndmask_b32_e64 v7, 0, v14, s[0:1]
	v_ldexp_f32 v6, v10, v6
	v_ldexp_f32 v7, v11, v7
	v_cndmask_b32_e64 v19, 0, v14, s[2:3]
	v_cndmask_b32_e64 v20, 0, v14, s[4:5]
	v_pk_add_f32 v[6:7], v[6:7], 1.0 op_sel_hi:[1,0]
	v_ldexp_f32 v10, v21, v19
	v_ldexp_f32 v11, v22, v20
	v_div_scale_f32 v19, s[0:1], v7, v7, v15
	v_pk_add_f32 v[10:11], v[10:11], 1.0 op_sel_hi:[1,0]
	v_div_scale_f32 v21, s[0:1], v6, v6, v16
	v_rcp_f32_e32 v27, v19
	v_div_scale_f32 v23, s[2:3], v11, v11, v17
	v_rcp_f32_e32 v28, v21
	v_rcp_f32_e32 v29, v23
	v_fma_f32 v31, -v19, v27, 1.0
	v_div_scale_f32 v20, vcc, v15, v7, v15
	v_fma_f32 v32, -v21, v28, 1.0
	v_fmac_f32_e32 v27, v31, v27
	v_div_scale_f32 v22, s[0:1], v16, v6, v16
	v_fma_f32 v33, -v23, v29, 1.0
	v_fmac_f32_e32 v28, v32, v28
	v_mul_f32_e32 v31, v20, v27
	v_div_scale_f32 v24, s[2:3], v17, v11, v17
	v_fmac_f32_e32 v29, v33, v29
	v_mul_f32_e32 v32, v22, v28
	v_fma_f32 v35, -v19, v31, v20
	v_mul_f32_e32 v33, v24, v29
	v_fma_f32 v36, -v21, v32, v22
	v_fmac_f32_e32 v31, v35, v27
	v_fma_f32 v37, -v23, v33, v24
	v_fmac_f32_e32 v32, v36, v28
	v_fma_f32 v19, -v19, v31, v20
	v_fmac_f32_e32 v33, v37, v29
	v_fma_f32 v20, -v21, v32, v22
	v_div_fmas_f32 v19, v19, v27, v31
	s_mov_b64 vcc, s[0:1]
	v_fma_f32 v21, -v23, v33, v24
	v_div_fixup_f32 v15, v19, v7, v15
	v_div_fmas_f32 v7, v20, v28, v32
	s_mov_b64 vcc, s[2:3]
	v_div_fixup_f32 v16, v7, v6, v16
	v_div_fmas_f32 v6, v21, v29, v33
	v_lshlrev_b32_e32 v19, 16, v8
	v_div_fixup_f32 v11, v6, v11, v17
	v_and_b32_e32 v17, 0xffff0000, v8
	v_mul_f32_e64 v8, -v19, s15
	v_cmp_gt_f32_e32 vcc, s18, v8
	v_sub_f32_e32 v6, 0, v19
	v_sub_f32_e32 v7, 0, v17
	v_cndmask_b32_e32 v8, 0, v13, vcc
	v_fmac_f32_e32 v8, 0x3fb8aa3b, v6
	v_exp_f32_e32 v6, v8
	v_mul_f32_e64 v8, -v17, s15
	v_cmp_gt_f32_e64 s[0:1], s18, v8
	v_div_scale_f32 v25, s[4:5], v10, v10, v18
	s_nop 0
	v_cndmask_b32_e64 v8, 0, v13, s[0:1]
	v_fmac_f32_e32 v8, 0x3fb8aa3b, v7
	v_rcp_f32_e32 v30, v25
	v_exp_f32_e32 v7, v8
	v_cndmask_b32_e32 v8, 0, v14, vcc
	v_ldexp_f32 v6, v6, v8
	v_cndmask_b32_e64 v8, 0, v14, s[0:1]
	v_fma_f32 v34, -v25, v30, 1.0
	v_ldexp_f32 v7, v7, v8
	v_div_scale_f32 v26, s[4:5], v18, v10, v18
	v_fmac_f32_e32 v30, v34, v30
	v_pk_add_f32 v[6:7], v[6:7], 1.0 op_sel_hi:[1,0]
	v_mul_f32_e32 v34, v26, v30
	v_div_scale_f32 v8, s[0:1], v7, v7, v17
	v_fma_f32 v38, -v25, v34, v26
	v_rcp_f32_e32 v20, v8
	v_fmac_f32_e32 v34, v38, v30
	v_fma_f32 v22, -v25, v34, v26
	s_mov_b64 vcc, s[4:5]
	v_div_fmas_f32 v21, v22, v30, v34
	v_div_fixup_f32 v10, v21, v10, v18
	v_fma_f32 v18, -v8, v20, 1.0
	v_fmac_f32_e32 v20, v18, v20
	v_div_scale_f32 v18, vcc, v17, v7, v17
	v_mul_f32_e32 v21, v18, v20
	v_fma_f32 v22, -v8, v21, v18
	v_fmac_f32_e32 v21, v22, v20
	v_fma_f32 v8, -v8, v21, v18
	v_div_scale_f32 v18, s[0:1], v6, v6, v19
	v_rcp_f32_e32 v22, v18
	v_div_fmas_f32 v8, v8, v20, v21
	v_div_fixup_f32 v7, v8, v7, v17
	v_lshlrev_b32_e32 v21, 16, v9
	v_fma_f32 v8, -v18, v22, 1.0
	v_fmac_f32_e32 v22, v8, v22
	v_div_scale_f32 v8, vcc, v19, v6, v19
	v_mul_f32_e32 v17, v8, v22
	v_fma_f32 v20, -v18, v17, v8
	v_mul_f32_e64 v23, -v21, s15
	v_fmac_f32_e32 v17, v20, v22
	v_cmp_gt_f32_e64 s[0:1], s18, v23
	v_fma_f32 v18, -v18, v17, v8
	v_sub_f32_e32 v8, 0, v21
	v_cndmask_b32_e64 v23, 0, v13, s[0:1]
	v_and_b32_e32 v20, 0xffff0000, v9
	v_fmac_f32_e32 v23, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v23
	v_mul_f32_e64 v23, -v20, s15
	v_cmp_gt_f32_e64 s[2:3], s18, v23
	v_sub_f32_e32 v9, 0, v20
	v_div_fmas_f32 v17, v18, v22, v17
	v_cndmask_b32_e64 v13, 0, v13, s[2:3]
	v_fmac_f32_e32 v13, 0x3fb8aa3b, v9
	v_exp_f32_e32 v9, v13
	v_cndmask_b32_e64 v13, 0, v14, s[0:1]
	v_ldexp_f32 v8, v8, v13
	v_cndmask_b32_e64 v13, 0, v14, s[2:3]
	v_ldexp_f32 v9, v9, v13
	v_pk_add_f32 v[8:9], v[8:9], 1.0 op_sel_hi:[1,0]
	v_div_fixup_f32 v6, v17, v6, v19
	v_div_scale_f32 v13, s[0:1], v9, v9, v20
	v_rcp_f32_e32 v14, v13
	v_cvt_pk_bf16_f32 v10, v10, v11
	v_fma_f32 v17, -v13, v14, 1.0
	v_fmac_f32_e32 v14, v17, v14
	v_div_scale_f32 v17, vcc, v20, v9, v20
	v_mul_f32_e32 v18, v17, v14
	v_fma_f32 v19, -v13, v18, v17
	v_fmac_f32_e32 v18, v19, v14
	v_fma_f32 v13, -v13, v18, v17
	v_div_scale_f32 v17, s[0:1], v8, v8, v21
	v_rcp_f32_e32 v19, v17
	v_div_fmas_f32 v13, v13, v14, v18
	v_div_fixup_f32 v9, v13, v9, v20
	s_mov_b32 s0, 0x2edbe6ff
	v_fma_f32 v13, -v17, v19, 1.0
	v_fmac_f32_e32 v19, v13, v19
	v_div_scale_f32 v13, vcc, v21, v8, v21
	v_mul_f32_e32 v14, v13, v19
	v_fma_f32 v18, -v17, v14, v13
	v_fmac_f32_e32 v14, v18, v19
	v_fma_f32 v13, -v17, v14, v13
	v_div_fmas_f32 v13, v13, v19, v14
	v_div_fixup_f32 v8, v13, v8, v21
	v_cvt_pk_bf16_f32 v13, v16, v15
	v_cvt_pk_bf16_f32 v14, v6, v7
	v_cvt_pk_bf16_f32 v15, v8, v9
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v7, 0xffff0000, v2
	v_lshlrev_b32_e32 v6, 16, v2
	v_and_b32_e32 v9, 0xffff0000, v13
	v_lshlrev_b32_e32 v8, 16, v13
	v_pk_mul_f32 v[6:7], v[6:7], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v3
	v_lshlrev_b32_e32 v8, 16, v3
	v_and_b32_e32 v3, 0xffff0000, v10
	v_lshlrev_b32_e32 v2, 16, v10
	v_pk_mul_f32 v[2:3], v[8:9], v[2:3]
	v_and_b32_e32 v9, 0xffff0000, v4
	v_lshlrev_b32_e32 v8, 16, v4
	v_and_b32_e32 v11, 0xffff0000, v14
	v_lshlrev_b32_e32 v10, 16, v14
	v_pk_mul_f32 v[8:9], v[8:9], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v10, 16, v5
	v_and_b32_e32 v5, 0xffff0000, v15
	v_lshlrev_b32_e32 v4, 16, v15
	v_pk_mul_f32 v[4:5], v[10:11], v[4:5]
	v_cvt_pk_bf16_f32 v6, v6, v7
	v_cvt_pk_bf16_f32 v4, v4, v5
	v_lshlrev_b32_e32 v5, 16, v6
	v_and_b32_e32 v6, 0xffff0000, v6
	v_cvt_pk_bf16_f32 v2, v2, v3
.Ltmp2:
	v_max_f32_e64 v10, |v6|, |v6|
	v_max_f32_e64 v11, |v5|, |v5|
.Ltmp3:
	v_cvt_pk_bf16_f32 v3, v8, v9
	v_lshlrev_b32_e32 v7, 16, v2
	v_and_b32_e32 v2, 0xffff0000, v2
.Ltmp4:
	v_max_f32_e32 v10, v11, v10
.Ltmp5:
	v_lshlrev_b32_e32 v8, 16, v3
	v_and_b32_e32 v3, 0xffff0000, v3
.Ltmp6:
	v_max3_f32 v10, v10, |v7|, |v2|
.Ltmp7:
	v_lshlrev_b32_e32 v9, 16, v4
	v_and_b32_e32 v4, 0xffff0000, v4
.Ltmp8:
	v_max3_f32 v10, v10, |v8|, |v3|
	v_max3_f32 v10, v10, |v9|, |v4|
.Ltmp9:
	v_mov_b32_e32 v11, v10
.Ltmp10:
	v_and_b32_e32 v14, 3, v0
.Ltmp11:
	s_nop 0
	v_mov_b32_dpp v11, v11 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v11, v10 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp12:
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp13:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v11, v10 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp14:
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp15:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp16:
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp17:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp18:
	v_max3_f32 v10, v10, v11, s0
	v_mul_f32_e32 v10, s12, v10
	v_div_scale_f32 v11, s[0:1], v10, v10, 1.0
	v_rcp_f32_e32 v13, v11
	s_nop 0
	v_fma_f32 v15, -v11, v13, 1.0
	v_fmac_f32_e32 v13, v15, v13
	v_div_scale_f32 v15, vcc, 1.0, v10, 1.0
	v_mul_f32_e32 v16, v15, v13
	v_fma_f32 v17, -v11, v16, v15
	v_fmac_f32_e32 v16, v17, v13
	v_fma_f32 v11, -v11, v16, v15
	v_div_fmas_f32 v11, v11, v13, v16
	v_div_fixup_f32 v11, v11, v10, 1.0
	v_mul_f32_e32 v8, v11, v8
	v_mul_f32_e32 v3, v11, v3
	v_mul_f32_e32 v5, v11, v5
	v_mul_f32_e32 v6, v11, v6
	v_mul_f32_e32 v9, v11, v9
	v_mul_f32_e32 v4, v11, v4
	v_cvt_scalef32_pk_fp8_f32 v3, v8, v3, 1.0
	v_mul_f32_e32 v7, v11, v7
	v_mul_f32_e32 v13, v11, v2
	v_cvt_scalef32_pk_fp8_f32 v2, v5, v6, 1.0
	v_cvt_scalef32_pk_fp8_f32 v3, v9, v4, 1.0 op_sel:[0,0,0,1]
	v_or_b32_e32 v4, s13, v12
	v_cvt_scalef32_pk_fp8_f32 v2, v7, v13, 1.0 op_sel:[0,0,0,1]
	v_add_u32_e32 v4, s14, v4
	buffer_store_dwordx2 v[2:3], v4, s[20:23], 0 offen
	v_lshlrev_b32_e32 v3, 4, v14
	v_and_b32_e32 v4, 12, v0
	v_or3_b32 v1, v3, v4, v1
	v_lshlrev_b32_e32 v1, 2, v1
	ds_bpermute_b32 v1, v1, v10
	v_lshl_or_b32 v2, s17, 2, v14
	v_mul_lo_u32 v2, v2, s11
	v_and_b32_e32 v0, 60, v0
	v_add_lshl_u32 v2, v2, s16, 2
	v_bfrev_b32_e32 v3, 1
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_mov_b32 s11, s7
	s_nop 0
	v_cndmask_b32_e32 v0, v3, v2, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dword v1, v0, s[8:11], 0 offen
	s_endpgm
.Ltmp19:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
		.amdhsa_user_sgpr_count 16
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 14
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 39
		.amdhsa_next_free_sgpr 24
		.amdhsa_accum_offset 40
		.amdhsa_reserve_vcc 1
		.amdhsa_reserve_xnack_mask 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size	\symbol, .Lfunc_end0-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 39
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 24
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2192
; TotalNumSgprs: 30
; NumVgprs: 39
; NumAgprs: 0
; TotalNumVgprs: 39
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 30
; NumVGPRsForWavesPerEU: 39
; AccumOffset: 40
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 9
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.text
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .offset:         32
        .size:           4
        .value_kind:     by_value
      - .offset:         36
        .size:           4
        .value_kind:     by_value
      - .offset:         40
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .max_flat_workgroup_size: 64
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     30
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     39
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
.Lline_table_start0:
	.endm
