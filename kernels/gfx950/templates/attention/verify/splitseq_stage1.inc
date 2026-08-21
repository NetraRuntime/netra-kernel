// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/attention/common/kernel_descriptor.inc"
	.include "kernels/gfx950/templates/attention/verify/splitseq_metadata.inc"
	NETRA_GFX950_MODULE_HEADER 5
; Qwen3.6 full-attention M=16 speculative verification, stage 1.
; Hand-maintained gfx950/wave64 assembly, re-derived from the deployed
; single-query decode kernel.  The pointer at kernarg offset 32 addresses
; sixteen int32 sequence lengths instead of a 17-entry CSR indptr.  All
; queries share the int64 KV-index array at offset 40, whose first index is 0.
	.macro NETRA_ATTENTION_SPLITSEQ_STAGE1 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 16
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 16
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 2
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 256
	NETRA_REQUIRE_EQ NETRA_KV_SPLITS_MAX, 129
	NETRA_KERNEL_ENTRY \symbol, 0
.Lfunc_begin0:
; %bb.5:
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.6:
.LBB0_0:
	s_mov_b64 s[48:49], s[6:7]
	s_load_dwordx2 s[6:7], s[0:1], 0x40
	s_mov_b32 s9, s17
	s_mov_b64 s[44:45], s[14:15]
	s_mov_b64 s[20:21], s[2:3]
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	s_ashr_i32 s17, s16, 31
	s_lshl_b64 s[14:15], s[16:17], 2
	s_add_u32 s2, s10, s14
	s_addc_u32 s3, s11, s15
	v_mov_b32_e32 v1, 0
	global_load_dword v2, v1, s[2:3]
	NETRA_WAIT_VM0
	v_readfirstlane_b32 s10, v2
	s_mov_b32 s2, 0
	NETRA_WAIT_LGKM0
	s_add_u32 s6, s6, s14
	s_addc_u32 s7, s7, s15
	global_load_dword v1, v1, s[6:7]
.Ltmp2:
	NETRA_WAIT_VM0
	v_readfirstlane_b32 s3, v1
	s_abs_i32 s6, s3
	v_cvt_f32_u32_e32 v1, s6
	s_sub_i32 s11, 0, s6
	s_add_i32 s7, s3, s10
	s_add_i32 s7, s7, -1
	v_rcp_iflag_f32_e32 v1, v1
	s_xor_b32 s3, s7, s3
	s_abs_i32 s7, s7
	s_ashr_i32 s3, s3, 31
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_nop 0
	v_readfirstlane_b32 s14, v1
	s_mul_i32 s11, s11, s14
	s_mul_hi_u32 s11, s14, s11
	s_add_i32 s14, s14, s11
	s_mul_hi_u32 s11, s7, s14
	s_mul_i32 s14, s11, s6
	s_sub_i32 s7, s7, s14
	s_add_i32 s15, s11, 1
	s_sub_i32 s14, s7, s6
	s_cmp_ge_u32 s7, s6
	s_cselect_b32 s11, s15, s11
	s_cselect_b32 s7, s14, s7
	s_add_i32 s14, s11, 1
	s_cmp_ge_u32 s7, s6
	s_cselect_b32 s6, s14, s11
	s_xor_b32 s6, s6, s3
	s_sub_i32 s3, s6, s3
.Ltmp3:
	s_add_i32 s3, s3, 31
	s_ashr_i32 s6, s3, 31
	s_lshr_b32 s6, s6, 27
	s_add_i32 s3, s3, s6
.Ltmp4:
	s_and_b32 s6, s3, 0xffffffe0
	s_mul_i32 s19, s6, s18
	s_add_i32 s6, s19, s6
	s_min_i32 s33, s6, s10
	s_cmp_le_i32 s33, s19
	v_readfirstlane_b32 s6, v0
	s_cbranch_scc1 .LBB0_4
; %bb.1:
	s_load_dwordx8 s[36:43], s[0:1], 0x48
	s_bfe_u32 s17, s6, 0x20006
	s_lshl_b32 s34, s9, 3
	v_and_b32_e32 v1, 63, v0
	s_lshl_b32 s6, s17, 6
	v_or_b32_e32 v14, s6, v1
	NETRA_WAIT_LGKM0
	s_mul_i32 s10, s36, s16
	v_lshlrev_b32_e32 v15, 3, v0
	s_mul_i32 s11, s37, s34
	s_add_i32 s7, s34, 8
	v_and_b32_e32 v2, 0xf8, v15
	v_lshrrev_b32_e32 v3, 5, v14
	s_add_i32 s11, s11, s10
	s_min_i32 s7, s7, 16
	v_or_b32_e32 v4, 8, v3
	v_or_b32_e32 v5, s34, v3
	v_mul_lo_u32 v3, v3, s37
	v_add_u32_e32 v8, s11, v2
	v_add_u32_e32 v6, s34, v4
	v_mul_lo_u32 v7, v4, s37
	v_add_lshl_u32 v2, v8, v3, 1
	v_bfrev_b32_e32 v19, 1
	v_cmp_gt_i32_e32 vcc, s7, v5
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_cndmask_b32_e32 v2, v19, v2, vcc
	v_add_lshl_u32 v7, v8, v7, 1
	v_cmp_gt_i32_e32 vcc, s7, v6
	buffer_load_dwordx4 v[2:5], v2, s[20:23], 0 offen
	v_and_b32_e32 v20, 15, v0
	v_cndmask_b32_e32 v6, v19, v7, vcc
	buffer_load_dwordx4 v[6:9], v6, s[20:23], 0 offen
	v_mov_b32_e32 v10, 0xf0
	v_and_b32_e32 v17, 48, v0
	v_add_u32_e32 v11, s34, v20
	v_lshlrev_b32_e32 v12, 4, v20
	v_lshlrev_b32_e32 v13, 8, v20
	s_load_dwordx2 s[36:37], s[0:1], 0x38
	s_load_dword s35, s[0:1], 0x68
	s_movk_i32 s11, 0x70
	s_movk_i32 s20, 0x80
	v_bitop3_b32 v22, s6, v10, v1 bitop3:0xc8
	v_bitop3_b32 v1, v12, v0, 48 bitop3:0x78
	v_bitop3_b32 v10, v12, v13, v17 bitop3:0xde
	v_cmp_gt_i32_e64 s[0:1], s7, v11
	v_lshlrev_b32_e32 v11, 3, v14
	v_lshrrev_b32_e32 v16, 1, v14
	v_add_u32_e32 v23, 0, v10
	v_xad_u32 v24, v10, 64, 0
	v_bitop3_b32 v10, v1, s20, v13 bitop3:0x36
	v_bitop3_b32 v11, v16, v11, s11 bitop3:0x6c
	s_movk_i32 s21, 0xc0
	v_add_u32_e32 v26, 0, v10
	v_xor_b32_e32 v10, 0x80, v11
	v_bitop3_b32 v1, v1, s21, v13 bitop3:0x36
	s_mul_i32 s6, s41, s9
	s_mul_i32 s7, s39, s9
	v_add_u32_e32 v32, 0, v11
	v_add_u32_e32 v33, 0, v10
	v_bitop3_b32 v27, v13, v17, v12 bitop3:0x36
	v_add_u32_e32 v1, 0, v1
	v_add_u32_e32 v16, s6, v12
	v_add_u32_e32 v18, s7, v12
	v_lshlrev_b32_e32 v25, 4, v14
	s_movk_i32 s7, 0x1f00
	s_lshl_b32 s6, s17, 4
	s_ashr_i32 s3, s3, 5
	s_movk_i32 s10, 0xf0
	v_xor_b32_e32 v28, 64, v27
	v_xor_b32_e32 v29, 0x80, v27
	v_xor_b32_e32 v30, 0xc0, v27
	v_bitop3_b32 v31, v25, v14, s10 bitop3:0x78
	s_and_b32 s13, s13, 0xffff
	s_and_b32 s5, s5, 0xffff
	s_and_b32 s49, s49, 0xffff
	v_lshrrev_b32_e32 v21, 2, v17
	s_mov_b32 s14, s22
	s_mov_b32 s15, s23
	v_mov_b32_e32 v36, 0xff800000
	v_add_u32_e32 v27, 0, v27
	v_add_u32_e32 v28, 0, v28
	v_add_u32_e32 v29, 0, v29
	v_add_u32_e32 v30, 0, v30
	s_mov_b32 s39, 0xc2fc0000
	v_mov_b32_e32 v37, 0x42800000
	v_not_b32_e32 v38, 63
	s_waitcnt vmcnt(1)
	v_cvt_scalef32_pk_fp8_bf16 v10, v2, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v11, v4, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v3, 1.0 op_sel:[0,0,1]
	NETRA_WAIT_VM0
	v_cvt_scalef32_pk_fp8_bf16 v12, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v13, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v11, v5, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v12, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v13, v9, 1.0 op_sel:[0,0,1]
	ds_write_b64 v32, v[10:11]
	ds_write_b64 v33, v[12:13] offset:2048
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[42:45], v23
	ds_read_b128 v[46:49], v24
	ds_read_b128 v[50:53], v26
	ds_read_b128 v[54:57], v1
	v_lshrrev_b32_e32 v1, 1, v22
	v_xor_b32_e32 v32, v1, v25
	v_lshlrev_b32_e32 v1, 7, v0
	v_lshlrev_b32_e32 v0, 2, v0
	v_and_b32_e32 v0, 0x78, v0
	v_and_b32_e32 v2, 8, v15
	v_and_or_b32 v0, v1, s7, v0
	v_lshrrev_b32_e32 v23, 4, v14
	v_bitop3_b32 v34, s6, v0, v2 bitop3:0x36
	v_lshlrev_b32_e32 v0, 3, v23
	v_xor_b32_e32 v33, 8, v32
	v_xor_b32_e32 v35, 64, v34
	v_lshl_add_u32 v24, s2, 3, v0
	s_mul_i32 s2, s18, s3
	s_lshl_b32 s9, s2, 8
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_add_u32_e32 v26, 0, v31
	v_add_u32_e32 v31, 0, v32
	v_add_u32_e32 v32, 0, v33
	v_add_u32_e32 v33, 0, v34
	v_add_u32_e32 v34, 0, v35
	v_mov_b32_e32 v35, 0xff800000
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v39, s19, v23
	v_add_u32_e32 v41, s9, v24
	v_add_u32_e32 v58, 16, v39
	v_cmp_gt_i32_e32 vcc, s33, v39
	v_add_u32_e32 v40, s19, v21
	v_add_u32_e32 v66, 0x80, v41
	v_cndmask_b32_e32 v39, v19, v41, vcc
	v_cmp_gt_i32_e64 s[10:11], s33, v58
	v_add_u32_e32 v59, 1, v40
	v_add_u32_e32 v60, 2, v40
	v_add_u32_e32 v61, 3, v40
	v_add_u32_e32 v62, 16, v40
	v_add_u32_e32 v63, 17, v40
	v_add_u32_e32 v64, 18, v40
	v_add_u32_e32 v65, 19, v40
	v_cmp_gt_i32_e64 s[2:3], s33, v40
	buffer_load_dwordx2 v[40:41], v39, s[12:15], 0 offen
	v_cndmask_b32_e64 v39, v19, v66, s[10:11]
	buffer_load_dwordx2 v[66:67], v39, s[12:15], 0 offen
	v_cmp_gt_i32_e64 s[20:21], s33, v59
	s_mov_b32 s6, s14
	s_mov_b32 s7, s15
	v_cmp_gt_i32_e64 s[22:23], s33, v60
	v_cmp_gt_i32_e64 s[24:25], s33, v61
	v_cmp_gt_i32_e64 s[28:29], s33, v64
	v_cmp_gt_i32_e64 s[30:31], s33, v65
	s_mov_b32 s50, s14
	s_mov_b32 s51, s15
	s_and_b64 s[2:3], s[0:1], s[2:3]
	s_add_i32 s19, s19, 32
	s_addk_i32 s9, 0x100
	s_waitcnt vmcnt(1)
	v_mad_u64_u32 v[58:59], s[26:27], s38, v40, v[18:19]
	NETRA_WAIT_VM0
	v_mad_u64_u32 v[60:61], s[26:27], s38, v66, v[18:19]
	v_cndmask_b32_e32 v39, v19, v58, vcc
	v_cndmask_b32_e64 v41, v19, v60, s[10:11]
	buffer_load_dwordx4 v[58:61], v39, s[4:7], 0 offen
	buffer_load_dwordx4 v[68:71], v41, s[4:7], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_cmp_gt_i32_e64 s[6:7], s33, v62
	v_cmp_gt_i32_e64 s[26:27], s33, v63
	v_mad_u64_u32 v[40:41], s[46:47], s40, v40, v[16:17]
	v_mad_u64_u32 v[66:67], s[46:47], s40, v66, v[16:17]
	v_cndmask_b32_e32 v39, v19, v40, vcc
	v_cndmask_b32_e64 v40, v19, v66, s[10:11]
	s_and_b64 vcc, s[0:1], s[20:21]
	s_and_b64 s[10:11], s[0:1], s[22:23]
	s_and_b64 s[20:21], s[0:1], s[24:25]
	s_and_b64 s[6:7], s[0:1], s[6:7]
	s_and_b64 s[22:23], s[0:1], s[26:27]
	s_and_b64 s[24:25], s[0:1], s[28:29]
	s_and_b64 s[26:27], s[0:1], s[30:31]
	s_cmp_lt_i32 s19, s33
	s_waitcnt vmcnt(1)
	ds_write_b128 v26, v[58:61]
	NETRA_WAIT_VM0
	ds_write_b128 v26, v[68:71] offset:4096
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[72:75], v28
	ds_read_b128 v[68:71], v27
	ds_read_b128 v[76:79], v27 offset:4096
	ds_read_b128 v[80:83], v28 offset:4096
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[58:61], v[68:75], v[42:49], 0
	ds_read_b128 v[72:75], v30
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x128_f8f6f4 v[62:65], v[76:83], v[42:49], 0
	ds_read_b128 v[68:71], v29
	ds_read_b128 v[76:79], v29 offset:4096
	ds_read_b128 v[80:83], v30 offset:4096
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[58:61], v[68:75], v[50:57], v[58:61]
	buffer_load_dwordx4 v[66:69], v39, s[48:51], 0 offen
	buffer_load_dwordx4 v[70:73], v40, s[48:51], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write2st64_b64 v31, v[66:67], v[70:71] offset1:8
	ds_write2st64_b64 v32, v[68:69], v[72:73] offset1:8
	v_mfma_f32_16x16x128_f8f6f4 v[62:65], v[76:83], v[50:57], v[62:65]
	s_nop 3
	v_mul_f32_e32 v39, s8, v58
	v_mul_f32_e32 v40, s8, v59
	v_mul_f32_e32 v41, s8, v60
	v_mul_f32_e32 v58, s8, v61
	v_cndmask_b32_e32 v40, v35, v40, vcc
	v_cndmask_b32_e64 v41, v35, v41, s[10:11]
	v_cndmask_b32_e64 v58, v35, v58, s[20:21]
	s_nop 0
	v_mul_f32_e32 v60, s8, v63
	v_cndmask_b32_e64 v63, v35, v39, s[2:3]
	v_mul_f32_e32 v59, s8, v62
.Ltmp5:
	v_max_f32_e32 v39, v63, v40
.Ltmp6:
	v_mul_f32_e32 v61, s8, v64
	v_mul_f32_e32 v62, s8, v65
	v_cndmask_b32_e64 v59, v35, v59, s[6:7]
	v_cndmask_b32_e64 v60, v35, v60, s[22:23]
.Ltmp7:
	v_max3_f32 v39, v39, v41, v58
.Ltmp8:
	v_cndmask_b32_e64 v61, v35, v61, s[24:25]
	v_cndmask_b32_e64 v62, v35, v62, s[26:27]
.Ltmp9:
	v_max3_f32 v39, v39, v59, v60
	v_max3_f32 v39, v39, v61, v62
.Ltmp10:
	v_mov_b32_e32 v64, v39
	s_nop 1
	v_permlane32_swap_b32_e32 v39, v64
.Ltmp11:
	v_max_f32_e32 v64, v64, v64
	v_max_f32_e32 v39, v39, v39
	v_max_f32_e32 v39, v39, v64
.Ltmp12:
	v_mov_b32_e32 v64, v39
	s_nop 1
	v_permlane16_swap_b32_e32 v39, v64
.Ltmp13:
	v_max3_f32 v39, v39, v64, v36
	v_sub_f32_e32 v64, v36, v39
	v_sub_f32_e32 v63, v63, v39
	v_sub_f32_e32 v40, v40, v39
	v_sub_f32_e32 v41, v41, v39
	v_sub_f32_e32 v58, v58, v39
	v_mul_f32_e32 v65, 0x3fb8aa3b, v64
	v_mul_f32_e32 v74, 0x3fb8aa3b, v63
	v_mul_f32_e32 v75, 0x3fb8aa3b, v40
	v_mul_f32_e32 v76, 0x3fb8aa3b, v41
	v_mul_f32_e32 v77, 0x3fb8aa3b, v58
	v_cmp_gt_f32_e32 vcc, s39, v65
	v_cmp_gt_f32_e64 s[2:3], s39, v74
	v_cmp_gt_f32_e64 s[6:7], s39, v75
	v_sub_f32_e32 v59, v59, v39
	v_sub_f32_e32 v60, v60, v39
	v_cndmask_b32_e32 v65, 0, v37, vcc
	v_cndmask_b32_e64 v74, 0, v37, s[2:3]
	v_cndmask_b32_e64 v75, 0, v37, s[6:7]
	v_cmp_gt_f32_e64 s[10:11], s39, v76
	v_cmp_gt_f32_e64 s[20:21], s39, v77
	v_mul_f32_e32 v78, 0x3fb8aa3b, v59
	v_mul_f32_e32 v79, 0x3fb8aa3b, v60
	v_cndmask_b32_e64 v76, 0, v37, s[10:11]
	v_cndmask_b32_e64 v77, 0, v37, s[20:21]
	v_fmac_f32_e32 v65, 0x3fb8aa3b, v64
	v_fmac_f32_e32 v74, 0x3fb8aa3b, v63
	v_fmac_f32_e32 v75, 0x3fb8aa3b, v40
	v_sub_f32_e32 v61, v61, v39
	v_cmp_gt_f32_e64 s[22:23], s39, v78
	v_cmp_gt_f32_e64 s[24:25], s39, v79
	v_fmac_f32_e32 v76, 0x3fb8aa3b, v41
	v_fmac_f32_e32 v77, 0x3fb8aa3b, v58
	v_exp_f32_e32 v58, v65
	v_exp_f32_e32 v65, v74
	v_exp_f32_e32 v74, v75
	v_sub_f32_e32 v62, v62, v39
	v_mul_f32_e32 v80, 0x3fb8aa3b, v61
	v_cndmask_b32_e64 v78, 0, v37, s[22:23]
	v_cndmask_b32_e64 v79, 0, v37, s[24:25]
	v_exp_f32_e32 v75, v76
	v_mul_f32_e32 v81, 0x3fb8aa3b, v62
	v_cmp_gt_f32_e64 s[26:27], s39, v80
	v_fmac_f32_e32 v78, 0x3fb8aa3b, v59
	v_fmac_f32_e32 v79, 0x3fb8aa3b, v60
	v_exp_f32_e32 v76, v77
	v_cndmask_b32_e64 v80, 0, v37, s[26:27]
	v_cmp_gt_f32_e64 s[28:29], s39, v81
	v_cndmask_b32_e32 v64, 0, v38, vcc
	v_cndmask_b32_e64 v63, 0, v38, s[2:3]
	v_cndmask_b32_e64 v40, 0, v38, s[6:7]
	v_exp_f32_e32 v77, v78
	v_exp_f32_e32 v78, v79
	v_cndmask_b32_e64 v81, 0, v37, s[28:29]
	v_cndmask_b32_e64 v41, 0, v38, s[10:11]
	v_fmac_f32_e32 v80, 0x3fb8aa3b, v61
	v_ldexp_f32 v58, v58, v64
	v_ldexp_f32 v63, v65, v63
	v_ldexp_f32 v64, v74, v40
	v_cndmask_b32_e64 v82, 0, v38, s[20:21]
	v_fmac_f32_e32 v81, 0x3fb8aa3b, v62
	v_exp_f32_e32 v79, v80
	v_ldexp_f32 v65, v75, v41
	v_cvt_scalef32_pk_fp8_f32 v40, v63, v64, 1.0
.Ltmp14:
	v_add_f32_e32 v63, v63, v64
.Ltmp15:
	v_cndmask_b32_e64 v59, 0, v38, s[22:23]
	v_cndmask_b32_e64 v60, 0, v38, s[24:25]
	v_exp_f32_e32 v80, v81
	v_ldexp_f32 v74, v76, v82
.Ltmp16:
	v_add_f32_e32 v63, v65, v63
.Ltmp17:
	v_ldexp_f32 v59, v77, v59
	v_ldexp_f32 v60, v78, v60
.Ltmp18:
	v_add_f32_e32 v63, v74, v63
.Ltmp19:
	v_cndmask_b32_e64 v61, 0, v38, s[26:27]
	v_cvt_scalef32_pk_fp8_f32 v41, v59, v60, 1.0
	v_pk_mul_f32 v[14:15], v[14:15], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[58:59] op_sel_hi:[1,0]
.Ltmp20:
	v_add_f32_e32 v59, v59, v63
.Ltmp21:
	v_cndmask_b32_e64 v62, 0, v38, s[28:29]
	v_ldexp_f32 v61, v79, v61
.Ltmp22:
	v_add_f32_e32 v59, v60, v59
.Ltmp23:
	v_ldexp_f32 v62, v80, v62
.Ltmp24:
	v_add_f32_e32 v59, v61, v59
.Ltmp25:
	v_cvt_scalef32_pk_fp8_f32 v40, v65, v74, 1.0 op_sel:[0,0,0,1]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b8 v[64:65], v33
	ds_read_b64_tr_b8 v[66:67], v34
	ds_read_b64_tr_b8 v[68:69], v33 offset:128
	ds_read_b64_tr_b8 v[70:71], v34 offset:128
.Ltmp26:
	v_add_f32_e32 v59, v62, v59
.Ltmp27:
	v_mov_b32_e32 v60, v59
.Ltmp28:
	v_cvt_scalef32_pk_fp8_f32 v41, v61, v62, 1.0 op_sel:[0,0,0,1]
.Ltmp29:
	s_nop 0
	v_permlane32_swap_b32_e32 v59, v60
.Ltmp30:
	v_permlane32_swap_b32_e32 v40, v41
.Ltmp31:
	v_add_f32_e32 v59, v59, v60
.Ltmp32:
	s_nop 0
	v_permlane16_swap_b32_e32 v40, v41
.Ltmp33:
	v_mov_b32_e32 v60, v59
.Ltmp34:
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[12:15], v[64:65], v[40:41], v[12:15]
.Ltmp35:
	v_permlane16_swap_b32_e32 v59, v60
	v_mov_b32_e32 v36, v39
.Ltmp36:
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[8:11], v[66:67], v[40:41], v[8:11]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_fp8_fp8 v[4:7], v[68:69], v[40:41], v[4:7]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_fp8_fp8 v[0:3], v[70:71], v[40:41], v[0:3]
.Ltmp37:
	v_add_f32_e32 v40, v59, v60
.Ltmp38:
	v_fmac_f32_e32 v40, v25, v58
	v_mov_b32_e32 v25, v40
	s_cbranch_scc1 .LBB0_2
; %bb.3:
	v_div_scale_f32 v19, s[2:3], v40, v40, v12
	v_mul_lo_u32 v18, s43, v20
	v_rcp_f32_e32 v20, v19
	v_lshrrev_b32_e32 v16, 2, v22
	s_mul_i32 s4, s42, s16
	s_mul_i32 s5, s35, s18
	v_fma_f32 v21, -v19, v20, 1.0
	v_fmac_f32_e32 v20, v21, v20
	v_div_scale_f32 v21, vcc, v12, v40, v12
	v_mul_f32_e32 v22, v21, v20
	s_mul_i32 s6, s43, s34
	s_add_i32 s2, s5, s4
	v_fma_f32 v23, -v19, v22, v21
	s_add_i32 s2, s2, s6
	v_fmac_f32_e32 v22, v23, v20
	v_add_u32_e32 v18, s2, v18
	v_fma_f32 v19, -v19, v22, v21
	v_div_scale_f32 v21, s[2:3], v40, v40, v13
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v20, v22
	v_div_fixup_f32 v12, v19, v40, v12
	v_add_lshl_u32 v16, v18, v16, 2
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v13, v40, v13
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v14
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v13, v19, v40, v13
	s_and_b32 s45, s45, 0xffff
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v14, v40, v14
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v15
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v14, v19, v40, v14
	s_mov_b32 s47, 0x27000
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v15, v40, v15
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v8
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v15, v19, v40, v15
	s_mov_b32 s46, 0x7ffffffe
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v8, v40, v8
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v9
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v8, v19, v40, v8
	s_and_b32 s37, s37, 0xffff
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v9, v40, v9
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v10
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v9, v19, v40, v9
	s_mov_b32 s38, s46
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v10, v40, v10
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v11
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v10, v19, v40, v10
	s_mov_b32 s39, s47
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v11, v40, v11
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v4
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v11, v19, v40, v11
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v4, v40, v4
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v5
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v4, v19, v40, v4
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v5, v40, v5
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v6
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v5, v19, v40, v5
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v6, v40, v6
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v7
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v6, v19, v40, v6
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v7, v40, v7
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v0
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v7, v19, v40, v7
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v0, v40, v0
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v1
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v0, v19, v40, v0
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v1, v40, v1
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v2
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v1, v19, v40, v1
	v_fma_f32 v19, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v19, v22
	v_div_scale_f32 v19, vcc, v2, v40, v2
	v_mul_f32_e32 v20, v19, v22
	v_fma_f32 v23, -v21, v20, v19
	v_fmac_f32_e32 v20, v23, v22
	v_fma_f32 v19, -v21, v20, v19
	v_div_scale_f32 v21, s[2:3], v40, v40, v3
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v22, v20
	v_div_fixup_f32 v2, v19, v40, v2
	s_mov_b32 s2, 0x800000
	v_fma_f32 v19, -v21, v23, 1.0
	v_fmac_f32_e32 v23, v19, v23
	v_div_scale_f32 v19, vcc, v3, v40, v3
	v_mul_f32_e32 v20, v19, v23
	v_fma_f32 v22, -v21, v20, v19
	v_fmac_f32_e32 v20, v22, v23
	v_fma_f32 v19, -v21, v20, v19
	v_div_fmas_f32 v19, v19, v23, v20
	v_div_fixup_f32 v3, v19, v40, v3
	v_bfrev_b32_e32 v19, 1
	v_cndmask_b32_e64 v20, v19, v16, s[0:1]
	buffer_store_dwordx4 v[12:15], v20, s[44:47], 0 offen
	v_cmp_gt_f32_e32 vcc, s2, v40
	s_mov_b32 s2, 0x3f317217
	v_add_u32_e32 v12, 0x100, v16
	v_cndmask_b32_e64 v12, v19, v12, s[0:1]
	buffer_store_dwordx4 v[8:11], v12, s[44:47], 0 offen
	s_nop 1
	v_add_u32_e32 v8, 0x200, v16
	v_cndmask_b32_e64 v8, v19, v8, s[0:1]
	buffer_store_dwordx4 v[4:7], v8, s[44:47], 0 offen
	s_nop 1
	v_add_u32_e32 v4, 0x300, v16
	v_cndmask_b32_e64 v4, v19, v4, s[0:1]
	buffer_store_dwordx4 v[0:3], v4, s[44:47], 0 offen
	s_nop 1
	v_cndmask_b32_e64 v1, 0, 32, vcc
	v_ldexp_f32 v1, v40, v1
	v_log_f32_e32 v1, v1
	v_ashrrev_i32_e32 v0, 31, v18
	v_add_u32_sdwa v0, v18, v0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_3
	v_ashrrev_i32_e32 v0, 8, v0
	v_mul_f32_e32 v2, 0x3f317217, v1
	v_fma_f32 v2, v1, s2, -v2
	v_fmamk_f32 v2, v1, 0x3377d1cf, v2
	s_mov_b32 s2, 0x7f800000
	v_fmac_f32_e32 v2, 0x3f317217, v1
	v_cmp_lt_f32_e64 s[2:3], |v1|, s2
	v_lshlrev_b32_e32 v0, 2, v0
	s_nop 0
	v_cndmask_b32_e64 v1, v1, v2, s[2:3]
	v_mov_b32_e32 v2, 0x41b17218
	v_cndmask_b32_e32 v2, 0, v2, vcc
	v_sub_f32_e32 v1, v1, v2
	v_or_b32_e32 v2, s17, v17
	v_cmp_eq_u32_e32 vcc, 0, v2
	s_and_b64 vcc, s[0:1], vcc
	v_add_f32_e32 v1, v39, v1
	v_cndmask_b32_e32 v0, v19, v0, vcc
	buffer_store_dword v1, v0, s[36:39], 0 offen
.LBB0_4:
	s_endpgm
.Ltmp39:
	NETRA_ATTENTION_KERNEL_DESCRIPTOR \symbol, 0, 128, 1, 1, 257, 96, 84
	.text
.Lfunc_end0:
	.size	\symbol, .Lfunc_end0-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 84
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 52
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4244
; TotalNumSgprs: 58
; NumVgprs: 84
; NumAgprs: 0
; TotalNumVgprs: 84
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 32
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 257
; AccumOffset: 84
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 20
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
	.section	".note.GNU-stack","",@progbits
	NETRA_ATTENTION_SPLITSEQ_STAGE1_METADATA \symbol
	.endm
