// Netra model-independent fixed-contract assembly tactic.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_GATED_RMSNORM_QUANT_D128_RPB2 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_WIDTH, 128
	NETRA_REQUIRE_EQ NETRA_HEADS, 48
	NETRA_REQUIRE_EQ NETRA_QUANT_GROUP_SIZE, 128
	NETRA_REQUIRE_EQ NETRA_SCALE_LAYOUT_ID, 1
	NETRA_REQUIRE_EQ NETRA_ROWS_PER_BLOCK, 2
	.text
	.globl	\symbol ; -- Begin function \symbol
	.p2align	8
	.type	\symbol,@function
\symbol:     ; @\symbol
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
	s_load_dwordx4 s[28:31], s[0:1], 0x38
	s_load_dwordx2 s[18:19], s[0:1], 0x48
	s_load_dword s17, s[0:1], 0x50
	s_mov_b64 s[24:25], s[10:11]
	s_mov_b64 s[36:37], s[6:7]
	s_mov_b64 s[20:21], s[2:3]
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	s_waitcnt lgkmcnt(0)
	s_abs_i32 s7, s31
	v_cvt_f32_u32_e32 v6, s7
	s_lshl_b32 s6, s16, 1
	v_lshrrev_b32_e32 v1, 5, v0
	v_or_b32_e32 v3, s6, v1
	v_rcp_iflag_f32_e32 v6, v6
	s_sub_i32 s3, 0, s7
	v_mul_lo_u32 v4, s14, v3
	s_bfe_i32 s14, s16, 0x1001e
	v_mul_f32_e32 v6, 0x4f7ffffe, v6
	v_cvt_u32_f32_e32 v6, v6
	v_add_u32_e32 v7, s14, v3
	v_xor_b32_e32 v7, s14, v7
	v_and_b32_e32 v8, 31, v0
	v_mul_lo_u32 v10, s3, v6
	v_mul_hi_u32 v10, v6, v10
	v_add_u32_e32 v10, v6, v10
	v_mul_hi_u32 v6, v7, v10
	v_mul_lo_u32 v11, v6, s7
	v_sub_u32_e32 v7, v7, v11
	v_add_u32_e32 v11, 1, v6
	v_cmp_le_u32_e32 vcc, s7, v7
	v_lshlrev_b32_e32 v2, 2, v8
	v_add_lshl_u32 v4, v4, v2, 1
	v_cndmask_b32_e32 v6, v6, v11, vcc
	v_subrev_u32_e32 v11, s7, v7
	v_bfrev_b32_e32 v19, 1
	v_cmp_gt_i32_e64 s[0:1], s30, v3
	v_cndmask_b32_e32 v7, v7, v11, vcc
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_cndmask_b32_e64 v4, v19, v4, s[0:1]
	s_ashr_i32 s2, s31, 31
	v_add_u32_e32 v11, 1, v6
	v_cmp_le_u32_e32 vcc, s7, v7
	buffer_load_dwordx2 v[4:5], v4, s[20:23], 0 offen
	s_xor_b32 s20, s14, s2
	v_cndmask_b32_e32 v6, v6, v11, vcc
	v_xor_b32_e32 v6, s20, v6
	v_subrev_u32_e32 v6, s20, v6
	v_mul_lo_u32 v7, v6, s31
	s_and_b32 s37, s37, 0xffff
	s_mov_b32 s38, s22
	s_mov_b32 s39, s23
	v_lshlrev_b32_e32 v20, 2, v0
	v_sub_u32_e32 v7, v3, v7
	buffer_load_dword v9, v20, s[36:39], 0 offen
	v_mul_lo_u32 v11, v7, s29
	v_mad_u64_u32 v[6:7], s[2:3], v6, s28, v[2:3]
	v_add_lshl_u32 v6, v6, v11, 1
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s22
	s_mov_b32 s11, s23
	v_cndmask_b32_e64 v6, v19, v6, s[0:1]
	buffer_load_dwordx2 v[6:7], v6, s[8:11], 0 offen
	v_and_b32_e32 v11, 32, v0
	v_and_b32_e32 v21, 1, v0
	v_or_b32_e32 v23, s6, v21
	v_lshlrev_b32_e32 v8, 3, v8
	v_lshrrev_b32_e32 v12, 3, v11
	v_or_b32_e32 v13, v8, v12
	v_bitop3_b32 v8, v8, 4, v12 bitop3:0x36
	v_add_u32_e32 v12, s14, v23
	v_xor_b32_e32 v12, s14, v12
	v_mul_hi_u32 v10, v12, v10
	v_mul_lo_u32 v14, v10, s7
	v_sub_u32_e32 v12, v12, v14
	v_add_u32_e32 v15, 1, v10
	v_cmp_le_u32_e32 vcc, s7, v12
	v_subrev_u32_e32 v14, s7, v12
	s_mov_b32 s8, 0x3fb8aa3b
	v_cndmask_b32_e32 v10, v10, v15, vcc
	v_cndmask_b32_e32 v12, v12, v14, vcc
	v_add_u32_e32 v14, 1, v10
	v_cmp_le_u32_e32 vcc, s7, v12
	s_mov_b32 s9, 0xc2fc0000
.Ltmp2:
	v_mov_b32_e32 v18, 0x42800000
.Ltmp3:
	v_cndmask_b32_e32 v10, v10, v14, vcc
	v_xor_b32_e32 v10, s20, v10
	v_subrev_u32_e32 v24, s20, v10
	v_cmp_eq_u32_e32 vcc, 0, v11
.Ltmp4:
	v_not_b32_e32 v22, 63
.Ltmp5:
	v_mul_lo_u32 v3, s15, v3
	v_add_lshl_u32 v2, v3, v2, 1
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	v_cndmask_b32_e64 v2, v19, v2, s[0:1]
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s26, s22
	s_mov_b32 s27, s23
	v_mul_lo_u32 v25, v24, s31
	s_and_b32 s13, s13, 0xffff
	s_mov_b32 s14, s22
	s_mov_b32 s15, s23
	s_waitcnt vmcnt(1)
	ds_bpermute_b32 v10, v13, v9
	ds_bpermute_b32 v12, v8, v9
	v_and_b32_e32 v9, 0xffff0000, v5
	v_lshlrev_b32_e32 v8, 16, v5
	v_cndmask_b32_e64 v26, 0, v8, s[0:1]
	v_cndmask_b32_e64 v27, 0, v9, s[0:1]
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e32 v5, v12, v10, vcc
	v_cndmask_b32_e32 v12, v10, v12, vcc
	v_and_b32_e32 v11, 0xffff0000, v5
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v15, 0xffff0000, v7
	v_lshlrev_b32_e32 v14, 16, v7
.Ltmp6:
	v_mul_f32_e64 v16, -v14, s8
	v_mul_f32_e64 v17, -v15, s8
	v_cmp_gt_f32_e32 vcc, s9, v16
	v_cmp_gt_f32_e64 s[2:3], s9, v17
.Ltmp7:
	v_lshlrev_b32_e32 v10, 16, v5
.Ltmp8:
	v_sub_f32_e32 v5, 0, v14
	v_sub_f32_e32 v7, 0, v15
	v_cndmask_b32_e32 v16, 0, v18, vcc
	v_cndmask_b32_e64 v17, 0, v18, s[2:3]
	v_fmac_f32_e32 v16, 0x3fb8aa3b, v5
	v_fmac_f32_e32 v17, 0x3fb8aa3b, v7
	v_exp_f32_e32 v5, v16
	v_exp_f32_e32 v7, v17
	v_cndmask_b32_e32 v16, 0, v22, vcc
	v_cndmask_b32_e64 v17, 0, v22, s[2:3]
	v_ldexp_f32 v16, v5, v16
	v_ldexp_f32 v17, v7, v17
	v_pk_add_f32 v[16:17], v[16:17], 1.0 op_sel_hi:[1,0]
.Ltmp9:
	v_and_b32_e32 v13, 0xffff0000, v12
.Ltmp10:
	v_div_scale_f32 v5, s[2:3], v17, v17, 1.0
	v_rcp_f32_e32 v28, v5
	v_div_scale_f32 v7, vcc, 1.0, v17, 1.0
	v_div_scale_f32 v29, s[2:3], v16, v16, 1.0
	v_fma_f32 v31, -v5, v28, 1.0
	v_fmac_f32_e32 v28, v31, v28
	v_mul_f32_e32 v31, v7, v28
	v_rcp_f32_e32 v30, v29
	v_fma_f32 v32, -v5, v31, v7
	v_fmac_f32_e32 v31, v32, v28
	v_fma_f32 v5, -v5, v31, v7
	v_div_fmas_f32 v5, v5, v28, v31
	v_div_fixup_f32 v17, v5, v17, 1.0
	v_fma_f32 v5, -v29, v30, 1.0
	v_fmac_f32_e32 v30, v5, v30
	v_div_scale_f32 v5, vcc, 1.0, v16, 1.0
	v_mul_f32_e32 v7, v5, v30
	v_fma_f32 v28, -v29, v7, v5
	v_fmac_f32_e32 v7, v28, v30
	v_fma_f32 v5, -v29, v7, v5
	v_div_fmas_f32 v5, v5, v30, v7
.Ltmp11:
	v_and_b32_e32 v7, 0xffff0000, v6
	v_lshlrev_b32_e32 v6, 16, v6
.Ltmp12:
	v_mul_f32_e64 v29, -v6, s8
	v_div_fixup_f32 v16, v5, v16, 1.0
	v_cmp_gt_f32_e32 vcc, s9, v29
.Ltmp13:
	v_pk_mul_f32 v[14:15], v[16:17], v[14:15]
.Ltmp14:
	v_sub_f32_e32 v16, 0, v6
	v_cndmask_b32_e32 v29, 0, v18, vcc
	v_fmac_f32_e32 v29, 0x3fb8aa3b, v16
	v_exp_f32_e32 v16, v29
	v_mul_f32_e64 v29, -v7, s8
	v_cmp_gt_f32_e64 s[2:3], s9, v29
	v_sub_f32_e32 v17, 0, v7
.Ltmp15:
	v_and_b32_e32 v5, 0xffff0000, v4
.Ltmp16:
	v_cndmask_b32_e64 v18, 0, v18, s[2:3]
	v_fmac_f32_e32 v18, 0x3fb8aa3b, v17
	v_exp_f32_e32 v17, v18
	v_cndmask_b32_e32 v18, 0, v22, vcc
	v_ldexp_f32 v16, v16, v18
	v_cndmask_b32_e64 v18, 0, v22, s[2:3]
	v_ldexp_f32 v17, v17, v18
	v_pk_add_f32 v[16:17], v[16:17], 1.0 op_sel_hi:[1,0]
.Ltmp17:
	v_lshlrev_b32_e32 v4, 16, v4
.Ltmp18:
	v_div_scale_f32 v18, s[2:3], v17, v17, 1.0
	v_rcp_f32_e32 v22, v18
.Ltmp19:
	v_cndmask_b32_e64 v29, 0, v5, s[0:1]
	v_cndmask_b32_e64 v28, 0, v4, s[0:1]
	v_mul_f32_e32 v29, v29, v29
.Ltmp20:
	v_fmac_f32_e32 v29, v28, v28
.Ltmp21:
	v_fma_f32 v28, -v18, v22, 1.0
	v_fmac_f32_e32 v22, v28, v22
	v_div_scale_f32 v28, vcc, 1.0, v17, 1.0
	v_mul_f32_e32 v30, v28, v22
	v_fma_f32 v31, -v18, v30, v28
	v_fmac_f32_e32 v30, v31, v22
	v_fma_f32 v18, -v18, v30, v28
	v_div_scale_f32 v28, s[2:3], v16, v16, 1.0
	v_rcp_f32_e32 v31, v28
.Ltmp22:
	v_fmac_f32_e32 v29, v26, v26
.Ltmp23:
	v_div_fmas_f32 v18, v18, v22, v30
.Ltmp24:
	v_fmac_f32_e32 v29, v27, v27
.Ltmp25:
	v_div_fixup_f32 v17, v18, v17, 1.0
	v_fma_f32 v18, -v28, v31, 1.0
.Ltmp26:
	ds_swizzle_b32 v22, v29 offset:swizzle(SWAP,16)
.Ltmp27:
	v_fmac_f32_e32 v31, v18, v31
	v_div_scale_f32 v18, vcc, 1.0, v16, 1.0
	v_mul_f32_e32 v26, v18, v31
	v_fma_f32 v27, -v28, v26, v18
	v_fmac_f32_e32 v26, v27, v31
	v_fma_f32 v27, -v28, v26, v18
.Ltmp28:
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v18, v29, v22
.Ltmp29:
	v_mov_b32_e32 v22, v18
.Ltmp30:
	v_lshlrev_b32_e32 v12, 16, v12
	s_mov_b32 s2, 0x2edbe6ff
.Ltmp31:
	v_mov_b32_dpp v22, v22 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v22, v18 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp32:
	v_add_f32_e32 v18, v18, v22
.Ltmp33:
	v_mov_b32_e32 v22, v18
	s_nop 1
	v_mov_b32_dpp v22, v22 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v22, v18 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp34:
	v_add_f32_e32 v18, v18, v22
.Ltmp35:
	v_mov_b32_e32 v22, v18
	s_nop 1
	v_mov_b32_dpp v22, v22 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp36:
	v_add_f32_e32 v18, v18, v22
.Ltmp37:
	v_mov_b32_e32 v22, v18
	s_nop 1
	v_mov_b32_dpp v22, v22 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp38:
	v_add_f32_e32 v18, v18, v22
.Ltmp39:
	v_mov_b32_e32 v22, s19
	v_fmamk_f32 v18, v18, 0x3c000000, v22
	v_rsq_f32_e32 v18, v18
.Ltmp40:
	v_div_fmas_f32 v22, v27, v31, v26
	v_div_fixup_f32 v16, v22, v16, 1.0
.Ltmp41:
	v_pk_mul_f32 v[6:7], v[16:17], v[6:7]
	v_pk_mul_f32 v[4:5], v[18:19], v[4:5] op_sel_hi:[0,1]
	v_pk_mul_f32 v[8:9], v[18:19], v[8:9] op_sel_hi:[0,1]
	v_pk_mul_f32 v[4:5], v[4:5], v[10:11]
	v_pk_mul_f32 v[8:9], v[8:9], v[12:13]
	v_pk_mul_f32 v[4:5], v[4:5], v[6:7]
	v_pk_mul_f32 v[6:7], v[8:9], v[14:15]
	v_cvt_pk_bf16_f32 v4, v4, v5
	v_cvt_pk_bf16_f32 v5, v6, v7
	v_lshlrev_b32_e32 v6, 16, v4
	v_and_b32_e32 v7, 0xffff0000, v4
	v_cndmask_b32_e64 v6, 0, v6, s[0:1]
	v_cndmask_b32_e64 v7, 0, v7, s[0:1]
	v_lshlrev_b32_e32 v8, 16, v5
	v_and_b32_e32 v9, 0xffff0000, v5
.Ltmp42:
	v_max_f32_e64 v10, |v7|, |v7|
	v_max_f32_e64 v11, |v6|, |v6|
.Ltmp43:
	v_cndmask_b32_e64 v8, 0, v8, s[0:1]
	v_cndmask_b32_e64 v9, 0, v9, s[0:1]
.Ltmp44:
	v_max_f32_e32 v10, v11, v10
	v_max3_f32 v10, v10, |v8|, |v9|
.Ltmp45:
	ds_swizzle_b32 v11, v10 offset:swizzle(SWAP,16)
.Ltmp46:
	buffer_store_dwordx2 v[4:5], v2, s[4:7], 0 offen
	v_sub_u32_e32 v12, v23, v25
.Ltmp47:
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp48:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v11, v10 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp49:
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp50:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v11, v10 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp51:
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp52:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp53:
	v_max_f32_e32 v11, v11, v11
	v_max_f32_e32 v10, v10, v11
.Ltmp54:
	v_mov_b32_e32 v11, v10
	s_nop 1
	v_mov_b32_dpp v11, v11 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp55:
	v_max3_f32 v10, v10, v11, s2
	v_mul_f32_e32 v10, s17, v10
	v_div_scale_f32 v11, s[2:3], v10, v10, 1.0
	v_rcp_f32_e32 v13, v11
	s_nop 0
	v_fma_f32 v2, -v11, v13, 1.0
	v_fmac_f32_e32 v13, v2, v13
	v_div_scale_f32 v2, vcc, 1.0, v10, 1.0
	v_mul_f32_e32 v3, v2, v13
	v_fma_f32 v4, -v11, v3, v2
	v_fmac_f32_e32 v3, v4, v13
	v_fma_f32 v2, -v11, v3, v2
	v_div_fmas_f32 v2, v2, v13, v3
	v_div_fixup_f32 v2, v2, v10, 1.0
	v_mul_f32_e32 v3, v6, v2
	v_mul_f32_e32 v4, v7, v2
	v_mul_f32_e32 v5, v8, v2
	v_mul_f32_e32 v2, v9, v2
	v_cvt_scalef32_pk_fp8_f32 v3, v3, v4, 1.0
	v_cvt_scalef32_pk_fp8_f32 v3, v5, v2, 1.0 op_sel:[0,0,0,1]
	v_lshl_or_b32 v2, s16, 8, v20
	v_cndmask_b32_e64 v2, v19, v2, s[0:1]
	buffer_store_dword v3, v2, s[24:27], 0 offen
	v_and_b32_e32 v3, 30, v0
	v_lshlrev_b32_e32 v4, 5, v21
	v_or3_b32 v1, v4, v3, v1
	v_lshlrev_b32_e32 v1, 2, v1
	ds_bpermute_b32 v1, v1, v10
	v_and_b32_e32 v0, 62, v0
	v_cmp_gt_i32_e32 vcc, s30, v23
	v_mul_lo_u32 v2, v12, s18
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	v_add_lshl_u32 v0, v2, v24, 2
	s_and_b64 vcc, s[0:1], vcc
	v_cndmask_b32_e32 v0, v19, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dword v1, v0, s[12:15], 0 offen
	s_endpgm
.Ltmp56:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 104
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
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_next_free_sgpr 40
		.amdhsa_accum_offset 36
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
	.set \symbol\().num_vgpr, 33
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 40
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2168
; TotalNumSgprs: 46
; NumVgprs: 33
; NumAgprs: 0
; TotalNumVgprs: 33
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 46
; NumVGPRsForWavesPerEU: 33
; AccumOffset: 36
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 8
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
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .offset:         48
        .size:           4
        .value_kind:     by_value
      - .offset:         52
        .size:           4
        .value_kind:     by_value
      - .offset:         56
        .size:           4
        .value_kind:     by_value
      - .offset:         60
        .size:           4
        .value_kind:     by_value
      - .offset:         64
        .size:           4
        .value_kind:     by_value
      - .offset:         68
        .size:           4
        .value_kind:     by_value
      - .offset:         72
        .size:           4
        .value_kind:     by_value
      - .offset:         76
        .size:           4
        .value_kind:     by_value
      - .offset:         80
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         96
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 104
    .max_flat_workgroup_size: 64
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     46
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     33
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
