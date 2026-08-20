	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	_rms_norm_gated_group_quant_kernel ; -- Begin function _rms_norm_gated_group_quant_kernel
	.p2align	8
	.type	_rms_norm_gated_group_quant_kernel,@function
_rms_norm_gated_group_quant_kernel:     ; @_rms_norm_gated_group_quant_kernel
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.1:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/fla" "layernorm_gated.py"
	.loc	1 301 0 prologue_end            ; layernorm_gated.py:301:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
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
	.loc	1 301 0 is_stmt 1               ; layernorm_gated.py:301
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	.loc	1 343 31                        ; layernorm_gated.py:343:31
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s16, s30
	s_cselect_b64 s[0:1], -1, 0
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	s_abs_i32 s2, s31
	v_cvt_f32_u32_e32 v3, s2
	.loc	1 335 24                        ; layernorm_gated.py:335:24
	v_lshlrev_b32_e32 v1, 1, v0
	.loc	1 337 34                        ; layernorm_gated.py:337:34
	s_mul_i32 s14, s14, s16
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	s_sub_i32 s7, 0, s2
	v_rcp_iflag_f32_e32 v3, v3
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	v_add_lshl_u32 v2, s14, v1, 1
	v_bfrev_b32_e32 v8, 1
	s_and_b32 s21, s21, 0xffff
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_mul_f32_e32 v3, 0x4f7ffffe, v3
	v_cvt_u32_f32_e32 v3, v3
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	v_cndmask_b32_e64 v2, v8, v2, s[0:1]
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_readfirstlane_b32 s10, v3
	s_mul_i32 s7, s7, s10
	s_mul_hi_u32 s7, s10, s7
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	buffer_load_dword v2, v2, s[20:23], 0 offen
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	s_abs_i32 s6, s16
	s_add_i32 s10, s10, s7
	s_mul_hi_u32 s7, s6, s10
	s_mul_i32 s10, s7, s2
	s_xor_b32 s3, s16, s31
	s_sub_i32 s6, s6, s10
	.loc	1 355 16                        ; layernorm_gated.py:355:16
	s_and_b32 s37, s37, 0xffff
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	s_ashr_i32 s3, s3, 31
	s_add_i32 s10, s7, 1
	s_sub_i32 s11, s6, s2
	s_cmp_ge_u32 s6, s2
	s_cselect_b32 s7, s10, s7
	s_cselect_b32 s6, s11, s6
	s_add_i32 s10, s7, 1
	s_cmp_ge_u32 s6, s2
	s_cselect_b32 s2, s10, s7
	s_xor_b32 s2, s2, s3
	s_sub_i32 s14, s2, s3
	.loc	1 362 54 is_stmt 0              ; layernorm_gated.py:362:54
	s_mul_i32 s3, s14, s31
	s_sub_i32 s20, s16, s3
	.loc	1 362 29                        ; layernorm_gated.py:362:29
	s_mul_i32 s2, s14, s28
	.loc	1 362 63                        ; layernorm_gated.py:362:63
	s_mul_i32 s3, s20, s29
	.loc	1 363 10 is_stmt 1              ; layernorm_gated.py:363:10
	s_add_i32 s3, s3, s2
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	v_add_lshl_u32 v3, s3, v1, 1
	.loc	1 355 16                        ; layernorm_gated.py:355:16
	s_mov_b32 s38, s22
	s_mov_b32 s39, s23
	v_lshlrev_b32_e32 v4, 2, v0
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s22
	s_mov_b32 s11, s23
	v_cndmask_b32_e64 v3, v8, v3, s[0:1]
	.loc	1 355 16                        ; layernorm_gated.py:355:16
	buffer_load_dword v5, v4, s[36:39], 0 offen
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	buffer_load_dword v9, v3, s[8:11], 0 offen
	.loc	1 341 33                        ; layernorm_gated.py:341:33
	s_mul_i32 s15, s15, s16
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	v_add_lshl_u32 v3, s15, v1, 1
	v_cndmask_b32_e64 v12, v8, v3, s[0:1]
	.loc	1 351 26                        ; layernorm_gated.py:351:26
	v_mov_b32_e32 v4, s19
	v_bfrev_b32_e32 v6, 60
	s_mov_b32 s2, 0x3fb8aa3b
	s_mov_b32 s3, 0xc2fc0000
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mov_b32_e32 v10, 0x42800000
	v_not_b32_e32 v11, 63
.Ltmp3:
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	s_and_b32 s5, s5, 0xffff
	.loc	1 379 37                        ; layernorm_gated.py:379:37
	v_lshl_or_b32 v1, s16, 7, v1
	.loc	1 379 50 is_stmt 0              ; layernorm_gated.py:379:50
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s26, s22
	s_mov_b32 s27, s23
	v_cndmask_b32_e64 v1, v8, v1, s[0:1]
	.loc	1 385 27 is_stmt 1              ; layernorm_gated.py:385:27
	s_and_b32 s13, s13, 0xffff
	s_mov_b32 s15, s23
	.loc	1 347 49                        ; layernorm_gated.py:347:49
	s_waitcnt vmcnt(2)
	v_and_b32_e32 v3, 0xffff0000, v2
	v_lshlrev_b32_e32 v2, 16, v2
	.loc	1 349 29                        ; layernorm_gated.py:349:29
	v_cndmask_b32_e64 v13, 0, v3, s[0:1]
	v_cndmask_b32_e64 v7, 0, v2, s[0:1]
	.loc	1 350 24                        ; layernorm_gated.py:350:24
	v_mul_f32_e32 v13, v13, v13
.Ltmp4:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_fmac_f32_e32 v13, v7, v7
	s_nop 1
	v_add_f32_dpp v7, v13, v13 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_e32 v13, v7
	s_nop 1
	v_mov_b32_dpp v13, v13 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp6:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_add_f32_e32 v7, v13, v7
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	s_nop 0
	v_readlane_b32 s8, v7, 63
.Ltmp8:
	.loc	1 355 58                        ; layernorm_gated.py:355:58
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v7, 0xffff0000, v5
	.loc	1 351 26                        ; layernorm_gated.py:351:26
	v_fma_f32 v4, s8, v6, v4
	.loc	1 351 20 is_stmt 0              ; layernorm_gated.py:351:20
	v_rsq_f32_e32 v4, v4
	.loc	1 355 58 is_stmt 1              ; layernorm_gated.py:355:58
	v_lshlrev_b32_e32 v6, 16, v5
	.loc	1 357 16                        ; layernorm_gated.py:357:16
	v_pk_mul_f32 v[2:3], v[4:5], v[2:3] op_sel_hi:[0,1]
	.loc	1 365 49                        ; layernorm_gated.py:365:49
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v5, 0xffff0000, v9
	v_lshlrev_b32_e32 v4, 16, v9
.Ltmp9:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mul_f32_e64 v9, -v4, s2
	v_mul_f32_e64 v13, -v5, s2
	v_cmp_gt_f32_e32 vcc, s3, v9
	v_cmp_gt_f32_e64 s[2:3], s3, v13
.Ltmp10:
	.loc	1 358 16                        ; layernorm_gated.py:358:16
	v_pk_mul_f32 v[2:3], v[2:3], v[6:7]
.Ltmp11:
	.loc	2 50 30                         ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v6, 0, v4
	v_sub_f32_e32 v7, 0, v5
	.loc	2 50 29 is_stmt 0               ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cndmask_b32_e32 v9, 0, v10, vcc
	v_cndmask_b32_e64 v10, 0, v10, s[2:3]
	v_fmac_f32_e32 v9, 0x3fb8aa3b, v6
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v9
	v_exp_f32_e32 v7, v10
	v_cndmask_b32_e32 v9, 0, v11, vcc
	v_cndmask_b32_e64 v10, 0, v11, s[2:3]
	v_ldexp_f32 v6, v6, v9
	v_ldexp_f32 v7, v7, v10
	.loc	2 50 20                         ; standard.py:50:20 @[ layernorm_gated.py:367:28 ]
	v_pk_add_f32 v[6:7], v[6:7], 1.0 op_sel_hi:[1,0]
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	s_nop 0
	v_div_scale_f32 v9, s[2:3], v7, v7, 1.0
	v_div_scale_f32 v11, s[2:3], v6, v6, 1.0
	v_rcp_f32_e32 v13, v9
	v_rcp_f32_e32 v14, v11
	v_div_scale_f32 v10, vcc, 1.0, v7, 1.0
	v_fma_f32 v16, -v9, v13, 1.0
	v_fma_f32 v17, -v11, v14, 1.0
	v_fmac_f32_e32 v13, v16, v13
	v_div_scale_f32 v15, s[2:3], 1.0, v6, 1.0
	v_fmac_f32_e32 v14, v17, v14
	v_mul_f32_e32 v16, v10, v13
	v_mul_f32_e32 v17, v15, v14
	v_fma_f32 v18, -v9, v16, v10
	v_fma_f32 v19, -v11, v17, v15
	v_fmac_f32_e32 v16, v18, v13
	v_fmac_f32_e32 v17, v19, v14
	v_fma_f32 v9, -v9, v16, v10
	v_fma_f32 v10, -v11, v17, v15
	v_div_fmas_f32 v9, v9, v13, v16
	s_mov_b64 vcc, s[2:3]
	v_div_fixup_f32 v7, v9, v7, 1.0
	v_div_fmas_f32 v9, v10, v14, v17
	v_div_fixup_f32 v6, v9, v6, 1.0
.Ltmp12:
	.loc	1 367 17 is_stmt 1              ; layernorm_gated.py:367:17
	v_pk_mul_f32 v[4:5], v[6:7], v[4:5]
	.loc	1 367 13 is_stmt 0              ; layernorm_gated.py:367:13
	s_nop 0
	v_pk_mul_f32 v[2:3], v[2:3], v[4:5]
	.loc	1 371 15 is_stmt 1              ; layernorm_gated.py:371:15
	s_nop 0
	v_cvt_pk_bf16_f32 v2, v2, v3
	.loc	1 374 31                        ; layernorm_gated.py:374:31
	v_lshlrev_b32_e32 v3, 16, v2
	v_and_b32_e32 v4, 0xffff0000, v2
	.loc	1 374 44 is_stmt 0              ; layernorm_gated.py:374:44
	v_cndmask_b32_e64 v3, 0, v3, s[0:1]
	v_cndmask_b32_e64 v4, 0, v4, s[0:1]
.Ltmp13:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e64 v5, |v4|, |v4|
	v_max_f32_e64 v6, |v3|, |v3|
	v_max_f32_e32 v5, v6, v5
.Ltmp14:
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	buffer_store_dword v2, v12, s[4:7], 0 offen
.Ltmp15:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 0
	v_mov_b32_dpp v6, v5 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp17:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 1
	v_mov_b32_dpp v6, v5 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp19:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 1
	v_mov_b32_dpp v6, v5 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp21:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 1
	v_mov_b32_dpp v6, v5 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp23:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	v_mov_b32_e32 v6, v5
	s_nop 1
	v_mov_b32_dpp v6, v6 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp24:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp25:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 1
	v_mov_b32_dpp v6, v5 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp26:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp27:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 0
	v_readlane_b32 s2, v5, 63
.Ltmp28:
	.loc	1 375 52                        ; layernorm_gated.py:375:52
	s_nop 1
	v_max_f32_e64 v5, s2, s2
	v_max_f32_e32 v5, 0x2edbe6ff, v5
	.loc	1 376 21                        ; layernorm_gated.py:376:21
	v_mul_f32_e32 v5, s17, v5
	.loc	1 377 16                        ; layernorm_gated.py:377:16
	v_div_scale_f32 v6, s[2:3], v5, v5, 1.0
	v_rcp_f32_e32 v7, v6
	v_div_scale_f32 v2, vcc, 1.0, v5, 1.0
	.loc	1 382 32                        ; layernorm_gated.py:382:32
	s_mul_i32 s2, s20, s18
	.loc	1 377 16                        ; layernorm_gated.py:377:16
	v_fma_f32 v9, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v9, v7
	v_mul_f32_e32 v9, v2, v7
	v_fma_f32 v10, -v6, v9, v2
	v_fmac_f32_e32 v9, v10, v7
	v_fma_f32 v2, -v6, v9, v2
	v_div_fmas_f32 v2, v2, v7, v9
	v_div_fixup_f32 v2, v2, v5, 1.0
	.loc	1 378 14                        ; layernorm_gated.py:378:14
	v_mul_f32_e32 v3, v2, v3
	v_mul_f32_e32 v2, v2, v4
	.loc	1 382 43                        ; layernorm_gated.py:382:43
	s_add_i32 s2, s2, s14
	.loc	1 378 31                        ; layernorm_gated.py:378:31
	v_cvt_scalef32_pk_fp8_f32 v2, v3, v2, 1.0
	.loc	1 385 27                        ; layernorm_gated.py:385:27
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_lshl_b32 s2, s2, 2
	.loc	1 378 31                        ; layernorm_gated.py:378:31
	v_cvt_scalef32_pk_fp8_f32 v2, s0, v0, 1.0 op_sel:[0,0,0,1]
	.loc	1 385 27                        ; layernorm_gated.py:385:27
	v_mov_b32_e32 v0, s2
	s_and_b64 vcc, vcc, s[0:1]
	s_mov_b32 s14, s22
	v_cndmask_b32_e32 v0, v8, v0, vcc
	.loc	1 379 50                        ; layernorm_gated.py:379:50
	buffer_store_short v2, v1, s[24:27], 0 offen
	.loc	1 385 27                        ; layernorm_gated.py:385:27
	buffer_store_dword v5, v0, s[12:15], 0 offen
	.loc	1 385 4 is_stmt 0               ; layernorm_gated.py:385:4
	s_endpgm
.Ltmp29:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _rms_norm_gated_group_quant_kernel
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
		.amdhsa_next_free_vgpr 20
		.amdhsa_next_free_sgpr 40
		.amdhsa_accum_offset 20
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
	.size	_rms_norm_gated_group_quant_kernel, .Lfunc_end0-_rms_norm_gated_group_quant_kernel
	.cfi_endproc
                                        ; -- End function
	.set _rms_norm_gated_group_quant_kernel.num_vgpr, 20
	.set _rms_norm_gated_group_quant_kernel.num_agpr, 0
	.set _rms_norm_gated_group_quant_kernel.numbered_sgpr, 40
	.set _rms_norm_gated_group_quant_kernel.num_named_barrier, 0
	.set _rms_norm_gated_group_quant_kernel.private_seg_size, 0
	.set _rms_norm_gated_group_quant_kernel.uses_vcc, 1
	.set _rms_norm_gated_group_quant_kernel.uses_flat_scratch, 0
	.set _rms_norm_gated_group_quant_kernel.has_dyn_sized_stack, 0
	.set _rms_norm_gated_group_quant_kernel.has_recursion, 0
	.set _rms_norm_gated_group_quant_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1532
; TotalNumSgprs: 46
; NumVgprs: 20
; NumAgprs: 0
; TotalNumVgprs: 20
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 46
; NumVGPRsForWavesPerEU: 20
; AccumOffset: 20
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 4
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
	.section	.debug_abbrev,"",@progbits
	.byte	1                               ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	1                               ; DW_CHILDREN_yes
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	2                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	0                               ; DW_CHILDREN_no
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	32                              ; DW_AT_inline
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	3                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	1                               ; DW_CHILDREN_yes
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	4                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	5                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	6                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	7                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0x82 DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	2                               ; DW_AT_language
	.long	.Linfo_string1                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string2                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.byte	2                               ; Abbrev [2] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string3                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x30:0x5c DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	367                             ; DW_AT_call_line
	.byte	28                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4e:0x23 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp4                          ; DW_AT_low_pc
	.long	.Ltmp8-.Ltmp4                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	350                             ; DW_AT_call_line
	.byte	17                              ; DW_AT_call_column
	.byte	4                               ; Abbrev [4] 0x63:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	6                               ; Abbrev [6] 0x71:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	375                             ; DW_AT_call_line
	.byte	31                              ; DW_AT_call_column
	.byte	7                               ; Abbrev [7] 0x7e:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
	.quad	.Ltmp20-.Lfunc_begin0
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.quad	.Ltmp23-.Lfunc_begin0
	.quad	.Ltmp24-.Lfunc_begin0
	.quad	.Ltmp25-.Lfunc_begin0
	.quad	.Ltmp26-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"layernorm_gated.py"            ; string offset=7
.Linfo_string2:
	.asciz	"/netra-server/python/sglang/srt/layers/attention/fla" ; string offset=26
.Linfo_string3:
	.asciz	"_rms_norm_gated_group_quant_kernel" ; string offset=79
	.section	".note.GNU-stack","",@progbits
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
    .name:           _rms_norm_gated_group_quant_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     46
    .sgpr_spill_count: 0
    .symbol:         _rms_norm_gated_group_quant_kernel.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     20
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
	.section	.debug_line,"",@progbits
.Lline_table_start0:
