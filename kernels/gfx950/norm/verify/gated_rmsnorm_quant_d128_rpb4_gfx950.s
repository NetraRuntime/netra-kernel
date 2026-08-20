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
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	.loc	1 355 16                        ; layernorm_gated.py:355:16
	s_and_b32 s37, s37, 0xffff
	s_mov_b32 s38, s22
	s_mov_b32 s39, s23
	v_lshlrev_b32_e32 v2, 2, v0
	buffer_load_dword v16, v2, s[36:39], 0 offen
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	s_waitcnt lgkmcnt(0)
	s_abs_i32 s26, s31
	.loc	1 355 58                        ; layernorm_gated.py:355:58
	v_add_u32_e32 v8, 0, v2
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_cvt_f32_u32_e32 v2, s26
	.loc	1 333 35                        ; layernorm_gated.py:333:35
	s_lshl_b32 s6, s16, 2
	.loc	1 334 36                        ; layernorm_gated.py:334:36
	v_lshrrev_b32_e32 v15, 4, v0
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	s_sub_i32 s2, 0, s26
	v_rcp_iflag_f32_e32 v2, v2
	s_bfe_i32 s7, s16, 0x1001d
	.loc	1 334 23                        ; layernorm_gated.py:334:23
	v_or_b32_e32 v11, s6, v15
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_add_u32_e32 v4, s7, v11
	v_mul_f32_e32 v2, 0x4f7ffffe, v2
	v_cvt_u32_f32_e32 v7, v2
	v_xor_b32_e32 v6, s7, v4
	s_ashr_i32 s0, s31, 31
	s_xor_b32 s27, s7, s0
	v_mul_lo_u32 v9, s2, v7
	v_mul_hi_u32 v9, v7, v9
	v_add_u32_e32 v12, v7, v9
	v_mul_hi_u32 v7, v6, v12
	v_mul_lo_u32 v9, v7, s26
	v_sub_u32_e32 v6, v6, v9
	v_add_u32_e32 v13, 1, v7
	v_cmp_le_u32_e32 vcc, s26, v6
	v_subrev_u32_e32 v9, s26, v6
	.loc	1 338 23                        ; layernorm_gated.py:338:23
	v_and_b32_e32 v10, 15, v0
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_cndmask_b32_e32 v7, v7, v13, vcc
	v_cndmask_b32_e32 v6, v6, v9, vcc
	v_add_u32_e32 v9, 1, v7
	v_cmp_le_u32_e32 vcc, s26, v6
	.loc	1 338 23                        ; layernorm_gated.py:338:23
	v_lshlrev_b32_e32 v14, 3, v10
	.loc	1 340 31                        ; layernorm_gated.py:340:31
	v_mul_lo_u32 v3, s14, v11
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_cndmask_b32_e32 v6, v7, v9, vcc
	v_xor_b32_e32 v6, s27, v6
	v_subrev_u32_e32 v6, s27, v6
	.loc	1 362 54 is_stmt 0              ; layernorm_gated.py:362:54
	v_mul_lo_u32 v9, v6, s31
	.loc	1 363 10 is_stmt 1              ; layernorm_gated.py:363:10
	v_mad_u64_u32 v[6:7], s[2:3], v6, s28, v[14:15]
	.loc	1 362 54                        ; layernorm_gated.py:362:54
	v_sub_u32_e32 v7, v11, v9
	.loc	1 363 10                        ; layernorm_gated.py:363:10
	v_mul_lo_u32 v7, v7, s29
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	v_bfrev_b32_e32 v1, 1
	v_add_lshl_u32 v3, v3, v14, 1
	.loc	1 343 31                        ; layernorm_gated.py:343:31
	v_cmp_gt_i32_e64 s[0:1], s30, v11
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	v_add_lshl_u32 v6, v6, v7, 1
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	s_and_b32 s21, s21, 0xffff
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s22
	s_mov_b32 s11, s23
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	v_cndmask_b32_e64 v2, v1, v3, s[0:1]
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	v_cndmask_b32_e64 v6, v1, v6, s[0:1]
	.loc	1 347 16                        ; layernorm_gated.py:347:16
	buffer_load_dwordx4 v[2:5], v2, s[20:23], 0 offen
	.loc	1 334 36                        ; layernorm_gated.py:334:36
	v_and_b32_e32 v20, 3, v0
	.loc	1 334 23 is_stmt 0              ; layernorm_gated.py:334:23
	v_or_b32_e32 v33, s6, v20
	.loc	1 341 48 is_stmt 1              ; layernorm_gated.py:341:48
	v_mul_lo_u32 v34, s15, v11
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_add_u32_e32 v11, s7, v33
	v_xor_b32_e32 v11, s7, v11
	v_mul_hi_u32 v12, v11, v12
	v_mul_lo_u32 v13, v12, s26
	v_sub_u32_e32 v11, v11, v13
	v_cmp_le_u32_e32 vcc, s26, v11
	v_subrev_u32_e32 v13, s26, v11
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mov_b32_e32 v21, 0x42800000
.Ltmp3:
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_cndmask_b32_e32 v11, v11, v13, vcc
.Ltmp4:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_not_b32_e32 v32, 63
.Ltmp5:
	.loc	1 355 58                        ; layernorm_gated.py:355:58
	v_lshl_add_u32 v10, v10, 4, 0
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	s_and_b32 s5, s5, 0xffff
	.loc	1 379 50                        ; layernorm_gated.py:379:50
	s_and_b32 s25, s25, 0xffff
	.loc	1 385 27                        ; layernorm_gated.py:385:27
	s_and_b32 s13, s13, 0xffff
	s_mov_b32 s14, s22
	s_mov_b32 s15, s23
	.loc	1 355 58                        ; layernorm_gated.py:355:58
	s_waitcnt vmcnt(1)
	ds_write_b32 v8, v16
	; wave barrier
	.loc	1 365 16                        ; layernorm_gated.py:365:16
	buffer_load_dwordx4 v[6:9], v6, s[8:11], 0 offen
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_add_u32_e32 v16, 1, v12
	s_mov_b32 s10, 0x3fb8aa3b
	v_cndmask_b32_e32 v12, v12, v16, vcc
	s_mov_b32 s11, 0xc2fc0000
	v_add_u32_e32 v13, 1, v12
	v_cmp_le_u32_e32 vcc, s26, v11
	.loc	1 379 50                        ; layernorm_gated.py:379:50
	s_mov_b32 s26, s22
	.loc	1 347 49                        ; layernorm_gated.py:347:49
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v17, 0xffff0000, v5
	.loc	1 362 20                        ; layernorm_gated.py:362:20
	v_cndmask_b32_e32 v11, v12, v13, vcc
	v_xor_b32_e32 v11, s27, v11
	v_subrev_u32_e32 v35, s27, v11
	.loc	1 362 54 is_stmt 0              ; layernorm_gated.py:362:54
	v_mul_lo_u32 v11, v35, s31
	v_sub_u32_e32 v36, v33, v11
	.loc	1 355 58 is_stmt 1              ; layernorm_gated.py:355:58
	ds_read_b128 v[10:13], v10
	.loc	1 347 49                        ; layernorm_gated.py:347:49
	v_lshlrev_b32_e32 v16, 16, v5
	v_and_b32_e32 v5, 0xffff0000, v4
	v_lshlrev_b32_e32 v4, 16, v4
	.loc	1 349 29                        ; layernorm_gated.py:349:29
	v_cndmask_b32_e64 v39, 0, v4, s[0:1]
	v_cndmask_b32_e64 v40, 0, v5, s[0:1]
	v_cndmask_b32_e64 v37, 0, v16, s[0:1]
	v_cndmask_b32_e64 v38, 0, v17, s[0:1]
	.loc	1 355 58                        ; layernorm_gated.py:355:58
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v19, 0xffff0000, v13
	v_lshlrev_b32_e32 v18, 16, v13
	v_and_b32_e32 v13, 0xffff0000, v12
	v_lshlrev_b32_e32 v12, 16, v12
	.loc	1 379 50                        ; layernorm_gated.py:379:50
	s_mov_b32 s27, s23
	.loc	1 365 49                        ; layernorm_gated.py:365:49
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v23, 0xffff0000, v9
	v_lshlrev_b32_e32 v22, 16, v9
.Ltmp6:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mul_f32_e64 v26, -v22, s10
	v_mul_f32_e64 v27, -v23, s10
.Ltmp7:
	.loc	1 365 49                        ; layernorm_gated.py:365:49
	v_and_b32_e32 v9, 0xffff0000, v8
	v_lshlrev_b32_e32 v8, 16, v8
.Ltmp8:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cmp_gt_f32_e32 vcc, s11, v26
	v_cmp_gt_f32_e64 s[2:3], s11, v27
	.loc	2 50 30 is_stmt 0               ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v24, 0, v22
	v_sub_f32_e32 v25, 0, v23
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mul_f32_e64 v30, -v8, s10
	v_mul_f32_e64 v31, -v9, s10
	v_cndmask_b32_e32 v26, 0, v21, vcc
	v_cndmask_b32_e64 v27, 0, v21, s[2:3]
	v_cmp_gt_f32_e64 s[6:7], s11, v30
	v_cmp_gt_f32_e64 s[8:9], s11, v31
	v_fmac_f32_e32 v26, 0x3fb8aa3b, v24
	v_fmac_f32_e32 v27, 0x3fb8aa3b, v25
	.loc	2 50 30                         ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v28, 0, v8
	v_sub_f32_e32 v29, 0, v9
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cndmask_b32_e64 v30, 0, v21, s[6:7]
	v_cndmask_b32_e64 v31, 0, v21, s[8:9]
	v_exp_f32_e32 v26, v26
	v_exp_f32_e32 v27, v27
	v_fmac_f32_e32 v30, 0x3fb8aa3b, v28
	v_fmac_f32_e32 v31, 0x3fb8aa3b, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_cndmask_b32_e32 v24, 0, v32, vcc
	v_cndmask_b32_e64 v25, 0, v32, s[2:3]
	v_ldexp_f32 v24, v26, v24
	v_ldexp_f32 v25, v27, v25
	v_cndmask_b32_e64 v28, 0, v32, s[6:7]
	v_cndmask_b32_e64 v29, 0, v32, s[8:9]
	.loc	2 50 20                         ; standard.py:50:20 @[ layernorm_gated.py:367:28 ]
	v_pk_add_f32 v[24:25], v[24:25], 1.0 op_sel_hi:[1,0]
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_ldexp_f32 v26, v30, v28
	v_ldexp_f32 v27, v31, v29
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_div_scale_f32 v28, s[2:3], v25, v25, 1.0
	.loc	2 50 20                         ; standard.py:50:20 @[ layernorm_gated.py:367:28 ]
	v_pk_add_f32 v[26:27], v[26:27], 1.0 op_sel_hi:[1,0]
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_div_scale_f32 v30, s[2:3], v24, v24, 1.0
	v_rcp_f32_e32 v45, v28
	v_div_scale_f32 v41, s[6:7], v27, v27, 1.0
	v_div_scale_f32 v43, s[8:9], v26, v26, 1.0
	v_rcp_f32_e32 v46, v30
	v_rcp_f32_e32 v47, v41
	v_rcp_f32_e32 v48, v43
	v_fma_f32 v49, -v28, v45, 1.0
	v_div_scale_f32 v29, vcc, 1.0, v25, 1.0
	v_fma_f32 v50, -v30, v46, 1.0
	v_fmac_f32_e32 v45, v49, v45
	v_div_scale_f32 v31, s[2:3], 1.0, v24, 1.0
	v_fma_f32 v51, -v41, v47, 1.0
	v_fma_f32 v52, -v43, v48, 1.0
	v_fmac_f32_e32 v46, v50, v46
	v_mul_f32_e32 v49, v29, v45
	v_div_scale_f32 v42, s[6:7], 1.0, v27, 1.0
	v_fmac_f32_e32 v47, v51, v47
	v_fmac_f32_e32 v48, v52, v48
	v_mul_f32_e32 v50, v31, v46
	v_fma_f32 v52, -v28, v49, v29
	v_mul_f32_e32 v51, v42, v47
	v_fmac_f32_e32 v49, v52, v45
	v_fma_f32 v52, -v30, v50, v31
	v_div_scale_f32 v44, s[8:9], 1.0, v26, 1.0
	v_fmac_f32_e32 v50, v52, v46
	v_fma_f32 v52, -v41, v51, v42
	v_fma_f32 v28, -v28, v49, v29
	v_fmac_f32_e32 v51, v52, v47
	v_mul_f32_e32 v52, v44, v48
	v_fma_f32 v30, -v30, v50, v31
	v_div_fmas_f32 v28, v28, v45, v49
	s_mov_b64 vcc, s[2:3]
	v_fma_f32 v29, -v43, v52, v44
	v_div_fixup_f32 v25, v28, v25, 1.0
	v_div_fmas_f32 v28, v30, v46, v50
	v_fma_f32 v31, -v41, v51, v42
	v_div_fixup_f32 v24, v28, v24, 1.0
	s_mov_b64 vcc, s[6:7]
	v_fmac_f32_e32 v52, v29, v48
	v_div_fmas_f32 v28, v31, v47, v51
.Ltmp9:
	.loc	1 367 17 is_stmt 1              ; layernorm_gated.py:367:17
	v_pk_mul_f32 v[22:23], v[24:25], v[22:23]
.Ltmp10:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v24, -v43, v52, v44
	s_mov_b64 vcc, s[8:9]
	v_div_fmas_f32 v24, v24, v48, v52
	v_div_fixup_f32 v24, v24, v26, 1.0
.Ltmp11:
	.loc	1 365 49                        ; layernorm_gated.py:365:49
	v_lshlrev_b32_e32 v26, 16, v7
.Ltmp12:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_div_fixup_f32 v25, v28, v27, 1.0
	.loc	2 50 29 is_stmt 0               ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mul_f32_e64 v28, -v26, s10
	v_cmp_gt_f32_e32 vcc, s11, v28
.Ltmp13:
	.loc	1 367 17 is_stmt 1              ; layernorm_gated.py:367:17
	v_pk_mul_f32 v[8:9], v[24:25], v[8:9]
	.loc	1 347 49                        ; layernorm_gated.py:347:49
	v_and_b32_e32 v25, 0xffff0000, v3
	v_lshlrev_b32_e32 v24, 16, v3
.Ltmp14:
	.loc	2 50 30                         ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v3, 0, v26
	.loc	2 50 29 is_stmt 0               ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cndmask_b32_e32 v28, 0, v21, vcc
.Ltmp15:
	.loc	1 365 49 is_stmt 1              ; layernorm_gated.py:365:49
	v_and_b32_e32 v27, 0xffff0000, v7
.Ltmp16:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_fmac_f32_e32 v28, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v28
	v_mul_f32_e64 v28, -v27, s10
	v_cmp_gt_f32_e64 s[2:3], s11, v28
	.loc	2 50 30 is_stmt 0               ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v7, 0, v27
.Ltmp17:
	.loc	1 355 58 is_stmt 1              ; layernorm_gated.py:355:58
	v_and_b32_e32 v31, 0xffff0000, v11
.Ltmp18:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cndmask_b32_e64 v28, 0, v21, s[2:3]
	v_fmac_f32_e32 v28, 0x3fb8aa3b, v7
	v_exp_f32_e32 v7, v28
	v_cndmask_b32_e32 v28, 0, v32, vcc
	v_ldexp_f32 v28, v3, v28
	v_cndmask_b32_e64 v3, 0, v32, s[2:3]
	v_ldexp_f32 v29, v7, v3
	.loc	2 50 20 is_stmt 0               ; standard.py:50:20 @[ layernorm_gated.py:367:28 ]
	v_pk_add_f32 v[28:29], v[28:29], 1.0 op_sel_hi:[1,0]
.Ltmp19:
	.loc	1 355 58 is_stmt 1              ; layernorm_gated.py:355:58
	v_lshlrev_b32_e32 v30, 16, v11
.Ltmp20:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_div_scale_f32 v3, s[2:3], v29, v29, 1.0
	v_rcp_f32_e32 v7, v3
.Ltmp21:
	.loc	1 349 29                        ; layernorm_gated.py:349:29
	v_cndmask_b32_e64 v41, 0, v24, s[0:1]
	v_cndmask_b32_e64 v42, 0, v25, s[0:1]
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	s_mov_b32 s6, s22
.Ltmp22:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v11, -v3, v7, 1.0
	v_fmac_f32_e32 v7, v11, v7
	v_div_scale_f32 v11, vcc, 1.0, v29, 1.0
	v_mul_f32_e32 v43, v11, v7
	v_fma_f32 v44, -v3, v43, v11
	v_fmac_f32_e32 v43, v44, v7
	v_fma_f32 v3, -v3, v43, v11
	v_div_scale_f32 v11, s[2:3], v28, v28, 1.0
	v_rcp_f32_e32 v44, v11
	v_div_fmas_f32 v3, v3, v7, v43
	v_div_fixup_f32 v29, v3, v29, 1.0
.Ltmp23:
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	s_mov_b32 s7, s23
.Ltmp24:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v3, -v11, v44, 1.0
	v_fmac_f32_e32 v44, v3, v44
	v_div_scale_f32 v3, vcc, 1.0, v28, 1.0
	v_mul_f32_e32 v7, v3, v44
	v_fma_f32 v43, -v11, v7, v3
	v_fmac_f32_e32 v7, v43, v44
	v_fma_f32 v3, -v11, v7, v3
	v_div_fmas_f32 v3, v3, v44, v7
	v_div_fixup_f32 v28, v3, v28, 1.0
.Ltmp25:
	.loc	1 347 49                        ; layernorm_gated.py:347:49
	v_and_b32_e32 v3, 0xffff0000, v2
	.loc	1 349 29                        ; layernorm_gated.py:349:29
	v_cndmask_b32_e64 v7, 0, v3, s[0:1]
	.loc	1 350 24                        ; layernorm_gated.py:350:24
	v_mul_f32_e32 v43, v7, v7
	.loc	1 365 49                        ; layernorm_gated.py:365:49
	v_and_b32_e32 v7, 0xffff0000, v6
	v_lshlrev_b32_e32 v6, 16, v6
.Ltmp26:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_mul_f32_e64 v44, -v6, s10
	v_cmp_gt_f32_e32 vcc, s11, v44
.Ltmp27:
	.loc	1 367 17                        ; layernorm_gated.py:367:17
	v_pk_mul_f32 v[26:27], v[28:29], v[26:27]
.Ltmp28:
	.loc	2 50 30                         ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v28, 0, v6
	.loc	2 50 29 is_stmt 0               ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cndmask_b32_e32 v44, 0, v21, vcc
	v_fmac_f32_e32 v44, 0x3fb8aa3b, v28
	v_exp_f32_e32 v28, v44
	v_mul_f32_e64 v44, -v7, s10
	v_cmp_gt_f32_e64 s[2:3], s11, v44
	.loc	2 50 30                         ; standard.py:50:30 @[ layernorm_gated.py:367:28 ]
	v_sub_f32_e32 v29, 0, v7
.Ltmp29:
	.loc	1 347 49 is_stmt 1              ; layernorm_gated.py:347:49
	v_lshlrev_b32_e32 v2, 16, v2
.Ltmp30:
	.loc	2 50 29                         ; standard.py:50:29 @[ layernorm_gated.py:367:28 ]
	v_cndmask_b32_e64 v21, 0, v21, s[2:3]
	v_fmac_f32_e32 v21, 0x3fb8aa3b, v29
	v_exp_f32_e32 v21, v21
	v_cndmask_b32_e32 v29, 0, v32, vcc
	v_ldexp_f32 v28, v28, v29
	v_cndmask_b32_e64 v29, 0, v32, s[2:3]
	v_ldexp_f32 v29, v21, v29
	.loc	2 50 20 is_stmt 0               ; standard.py:50:20 @[ layernorm_gated.py:367:28 ]
	v_pk_add_f32 v[28:29], v[28:29], 1.0 op_sel_hi:[1,0]
.Ltmp31:
	.loc	1 349 29 is_stmt 1              ; layernorm_gated.py:349:29
	v_cndmask_b32_e64 v11, 0, v2, s[0:1]
.Ltmp32:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_div_scale_f32 v21, s[2:3], v29, v29, 1.0
	v_rcp_f32_e32 v32, v21
.Ltmp33:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_fmac_f32_e32 v43, v11, v11
	v_fmac_f32_e32 v43, v41, v41
	v_fmac_f32_e32 v43, v42, v42
.Ltmp34:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v44, -v21, v32, 1.0
	v_fmac_f32_e32 v32, v44, v32
	v_div_scale_f32 v44, vcc, 1.0, v29, 1.0
	v_mul_f32_e32 v45, v44, v32
	v_fma_f32 v46, -v21, v45, v44
	v_fmac_f32_e32 v45, v46, v32
	v_fma_f32 v21, -v21, v45, v44
	v_div_scale_f32 v44, s[2:3], v28, v28, 1.0
	v_rcp_f32_e32 v46, v44
	v_div_fmas_f32 v21, v21, v32, v45
	v_div_fixup_f32 v29, v21, v29, 1.0
.Ltmp35:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_fmac_f32_e32 v43, v39, v39
.Ltmp36:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v21, -v44, v46, 1.0
	v_fmac_f32_e32 v46, v21, v46
	v_div_scale_f32 v21, vcc, 1.0, v28, 1.0
.Ltmp37:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_fmac_f32_e32 v43, v40, v40
.Ltmp38:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_mul_f32_e32 v45, v21, v46
.Ltmp39:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_fmac_f32_e32 v43, v37, v37
.Ltmp40:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v32, -v44, v45, v21
.Ltmp41:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_fmac_f32_e32 v43, v38, v38
.Ltmp42:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fmac_f32_e32 v45, v32, v46
.Ltmp43:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_e32 v32, v43
.Ltmp44:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_fma_f32 v21, -v44, v45, v21
	v_div_fmas_f32 v21, v21, v46, v45
.Ltmp45:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_dpp v32, v32 row_shr:8 row_mask:0xf bank_mask:0xc
.Ltmp46:
	.loc	1 355 58                        ; layernorm_gated.py:355:58
	v_and_b32_e32 v11, 0xffff0000, v10
	v_lshlrev_b32_e32 v10, 16, v10
.Ltmp47:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_dpp v32, v43 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp48:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_add_f32_e32 v32, v43, v32
.Ltmp49:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_e32 v37, v32
.Ltmp50:
	.loc	2 50 16                         ; standard.py:50:16 @[ layernorm_gated.py:367:28 ]
	v_div_fixup_f32 v28, v21, v28, 1.0
.Ltmp51:
	.loc	1 367 17                        ; layernorm_gated.py:367:17
	v_pk_mul_f32 v[6:7], v[28:29], v[6:7]
.Ltmp52:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_dpp v37, v37 row_shr:4 row_mask:0xf bank_mask:0xa
	s_mov_b32 s2, 0x2edbe6ff
	s_nop 0
	v_mov_b32_dpp v37, v32 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp53:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_add_f32_e32 v32, v32, v37
.Ltmp54:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_e32 v37, v32
	s_nop 1
	v_mov_b32_dpp v37, v37 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp55:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_add_f32_e32 v32, v32, v37
.Ltmp56:
	.loc	2 293 36                        ; standard.py:293:36 @[ layernorm_gated.py:350:17 ]
	v_mov_b32_e32 v37, v32
	s_nop 1
	v_mov_b32_dpp v37, v37 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp57:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ layernorm_gated.py:350:17 ] ]
	v_add_f32_e32 v32, v32, v37
.Ltmp58:
	.loc	1 351 26                        ; layernorm_gated.py:351:26
	v_mov_b32_e32 v37, s19
	v_fmamk_f32 v32, v32, 0x3c000000, v37
	.loc	1 351 20 is_stmt 0              ; layernorm_gated.py:351:20
	v_rsq_f32_e32 v32, v32
	.loc	1 357 16 is_stmt 1              ; layernorm_gated.py:357:16
	s_nop 0
	v_pk_mul_f32 v[2:3], v[32:33], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[24:25], v[32:33], v[24:25] op_sel_hi:[0,1]
	.loc	1 358 16                        ; layernorm_gated.py:358:16
	v_pk_mul_f32 v[2:3], v[2:3], v[10:11]
	v_pk_mul_f32 v[10:11], v[24:25], v[30:31]
	.loc	1 367 13                        ; layernorm_gated.py:367:13
	v_pk_mul_f32 v[2:3], v[2:3], v[6:7]
	.loc	1 357 16                        ; layernorm_gated.py:357:16
	v_pk_mul_f32 v[4:5], v[32:33], v[4:5] op_sel_hi:[0,1]
	v_pk_mul_f32 v[16:17], v[32:33], v[16:17] op_sel_hi:[0,1]
	.loc	1 367 13                        ; layernorm_gated.py:367:13
	v_pk_mul_f32 v[6:7], v[10:11], v[26:27]
	.loc	1 371 15                        ; layernorm_gated.py:371:15
	v_cvt_pk_bf16_f32 v2, v2, v3
	.loc	1 358 16                        ; layernorm_gated.py:358:16
	v_pk_mul_f32 v[4:5], v[4:5], v[12:13]
	v_pk_mul_f32 v[12:13], v[16:17], v[18:19]
	.loc	1 371 15                        ; layernorm_gated.py:371:15
	v_cvt_pk_bf16_f32 v3, v6, v7
	.loc	1 374 31                        ; layernorm_gated.py:374:31
	v_lshlrev_b32_e32 v6, 16, v2
	v_and_b32_e32 v7, 0xffff0000, v2
	.loc	1 367 13                        ; layernorm_gated.py:367:13
	v_pk_mul_f32 v[4:5], v[4:5], v[8:9]
	v_pk_mul_f32 v[8:9], v[12:13], v[22:23]
	.loc	1 374 44                        ; layernorm_gated.py:374:44
	v_cndmask_b32_e64 v6, 0, v6, s[0:1]
	v_cndmask_b32_e64 v7, 0, v7, s[0:1]
	.loc	1 371 15                        ; layernorm_gated.py:371:15
	v_cvt_pk_bf16_f32 v4, v4, v5
	v_cvt_pk_bf16_f32 v5, v8, v9
	.loc	1 374 31                        ; layernorm_gated.py:374:31
	v_lshlrev_b32_e32 v8, 16, v3
	v_and_b32_e32 v9, 0xffff0000, v3
.Ltmp59:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e64 v16, |v7|, |v7|
	v_max_f32_e64 v17, |v6|, |v6|
.Ltmp60:
	.loc	1 374 31                        ; layernorm_gated.py:374:31
	v_lshlrev_b32_e32 v10, 16, v4
	v_and_b32_e32 v11, 0xffff0000, v4
	.loc	1 374 44 is_stmt 0              ; layernorm_gated.py:374:44
	v_cndmask_b32_e64 v8, 0, v8, s[0:1]
	v_cndmask_b32_e64 v9, 0, v9, s[0:1]
.Ltmp61:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v16, v17, v16
.Ltmp62:
	.loc	1 374 31                        ; layernorm_gated.py:374:31
	v_lshlrev_b32_e32 v12, 16, v5
	v_and_b32_e32 v13, 0xffff0000, v5
	.loc	1 374 44 is_stmt 0              ; layernorm_gated.py:374:44
	v_cndmask_b32_e64 v10, 0, v10, s[0:1]
	v_cndmask_b32_e64 v11, 0, v11, s[0:1]
.Ltmp63:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max3_f32 v16, v16, |v8|, |v9|
.Ltmp64:
	.loc	1 374 44                        ; layernorm_gated.py:374:44
	v_cndmask_b32_e64 v12, 0, v12, s[0:1]
	v_cndmask_b32_e64 v13, 0, v13, s[0:1]
.Ltmp65:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max3_f32 v16, v16, |v10|, |v11|
	v_max3_f32 v16, v16, |v12|, |v13|
.Ltmp66:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	v_mov_b32_e32 v17, v16
.Ltmp67:
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	v_add_lshl_u32 v19, v34, v14, 1
	v_cndmask_b32_e64 v19, v1, v19, s[0:1]
.Ltmp68:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	v_mov_b32_dpp v17, v17 row_shr:8 row_mask:0xf bank_mask:0xc
.Ltmp69:
	.loc	1 372 21                        ; layernorm_gated.py:372:21
	buffer_store_dwordx4 v[2:5], v19, s[4:7], 0 offen
.Ltmp70:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	s_nop 0
	v_mov_b32_dpp v17, v16 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp71:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v17, v17, v17
	v_max_f32_e32 v16, v16, v17
.Ltmp72:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	v_mov_b32_e32 v17, v16
	s_nop 1
	v_mov_b32_dpp v17, v17 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v17, v16 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp73:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v17, v17, v17
	v_max_f32_e32 v16, v16, v17
.Ltmp74:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	v_mov_b32_e32 v17, v16
	s_nop 1
	v_mov_b32_dpp v17, v17 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp75:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ layernorm_gated.py:375:31 ] ]
	v_max_f32_e32 v17, v17, v17
	v_max_f32_e32 v16, v16, v17
.Ltmp76:
	.loc	2 191 40                        ; standard.py:191:40 @[ layernorm_gated.py:375:31 ]
	v_mov_b32_e32 v17, v16
	s_nop 1
	v_mov_b32_dpp v17, v17 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp77:
	.loc	1 375 52                        ; layernorm_gated.py:375:52
	v_max3_f32 v16, v16, v17, s2
	.loc	1 376 21                        ; layernorm_gated.py:376:21
	v_mul_f32_e32 v16, s17, v16
	.loc	1 377 16                        ; layernorm_gated.py:377:16
	v_div_scale_f32 v17, s[2:3], v16, v16, 1.0
	v_rcp_f32_e32 v18, v17
	.loc	1 379 17                        ; layernorm_gated.py:379:17
	s_lshl_b32 s2, s16, 9
	.loc	1 377 16                        ; layernorm_gated.py:377:16
	v_fma_f32 v2, -v17, v18, 1.0
	v_fmac_f32_e32 v18, v2, v18
	v_div_scale_f32 v2, vcc, 1.0, v16, 1.0
	v_mul_f32_e32 v3, v2, v18
	v_fma_f32 v4, -v17, v3, v2
	v_fmac_f32_e32 v3, v4, v18
	v_fma_f32 v2, -v17, v3, v2
	v_div_fmas_f32 v2, v2, v18, v3
	v_div_fixup_f32 v2, v2, v16, 1.0
	.loc	1 378 14                        ; layernorm_gated.py:378:14
	v_mul_f32_e32 v3, v6, v2
	v_mul_f32_e32 v4, v7, v2
	v_mul_f32_e32 v5, v8, v2
	v_mul_f32_e32 v6, v9, v2
	v_mul_f32_e32 v7, v10, v2
	v_mul_f32_e32 v8, v11, v2
	v_mul_f32_e32 v9, v12, v2
	v_mul_f32_e32 v10, v13, v2
	.loc	1 378 31 is_stmt 0              ; layernorm_gated.py:378:31
	v_cvt_scalef32_pk_fp8_f32 v2, v3, v4, 1.0
	.loc	1 379 37 is_stmt 1              ; layernorm_gated.py:379:37
	v_lshlrev_b32_e32 v4, 7, v15
	.loc	1 378 31                        ; layernorm_gated.py:378:31
	v_cvt_scalef32_pk_fp8_f32 v3, v7, v8, 1.0
	.loc	1 379 37                        ; layernorm_gated.py:379:37
	v_or3_b32 v4, v4, s2, v14
	.loc	1 378 31                        ; layernorm_gated.py:378:31
	v_cvt_scalef32_pk_fp8_f32 v2, v5, v6, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v3, v9, v10, 1.0 op_sel:[0,0,0,1]
	.loc	1 379 50                        ; layernorm_gated.py:379:50
	v_cndmask_b32_e64 v4, v1, v4, s[0:1]
	buffer_store_dwordx2 v[2:3], v4, s[24:27], 0 offen
	.loc	1 385 27                        ; layernorm_gated.py:385:27
	v_lshlrev_b32_e32 v3, 4, v20
	v_and_b32_e32 v4, 12, v0
	v_or3_b32 v3, v3, v4, v15
	v_lshlrev_b32_e32 v3, 2, v3
	ds_bpermute_b32 v3, v3, v16
	v_and_b32_e32 v0, 60, v0
	.loc	1 380 23                        ; layernorm_gated.py:380:23
	v_cmp_gt_i32_e32 vcc, s30, v33
	.loc	1 385 21                        ; layernorm_gated.py:385:21
	v_mul_lo_u32 v2, v36, s18
	.loc	1 385 27 is_stmt 0              ; layernorm_gated.py:385:27
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	v_add_lshl_u32 v0, v2, v35, 2
	s_and_b64 vcc, s[0:1], vcc
	v_cndmask_b32_e32 v0, v1, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dword v3, v0, s[12:15], 0 offen
	.loc	1 385 4                         ; layernorm_gated.py:385:4
	s_endpgm
.Ltmp78:
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
		.amdhsa_next_free_vgpr 53
		.amdhsa_next_free_sgpr 40
		.amdhsa_accum_offset 56
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
	.set _rms_norm_gated_group_quant_kernel.num_vgpr, 53
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
; codeLenInByte = 2940
; TotalNumSgprs: 46
; NumVgprs: 53
; NumAgprs: 0
; TotalNumVgprs: 53
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 46
; NumVGPRsForWavesPerEU: 53
; AccumOffset: 56
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 13
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
	.byte	6                               ; Abbreviation Code
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
	.byte	1                               ; Abbrev [1] 0xb:0x7a DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x54 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	367                             ; DW_AT_call_line
	.byte	28                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4e:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	350                             ; DW_AT_call_line
	.byte	17                              ; DW_AT_call_column
	.byte	4                               ; Abbrev [4] 0x5b:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x69:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	375                             ; DW_AT_call_line
	.byte	31                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x76:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
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
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
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
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	.Ltmp29-.Lfunc_begin0
	.quad	.Ltmp30-.Lfunc_begin0
	.quad	.Ltmp31-.Lfunc_begin0
	.quad	.Ltmp32-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp45-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp51-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp45-.Lfunc_begin0
	.quad	.Ltmp46-.Lfunc_begin0
	.quad	.Ltmp47-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp49-.Lfunc_begin0
	.quad	.Ltmp53-.Lfunc_begin0
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.quad	.Ltmp56-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp70-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp71-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp75-.Lfunc_begin0
	.quad	.Ltmp76-.Lfunc_begin0
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
    .vgpr_count:     53
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
