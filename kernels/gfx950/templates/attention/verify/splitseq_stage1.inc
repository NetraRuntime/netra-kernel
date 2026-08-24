// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
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
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.5:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/triton_ops" "decode_attention.py"
	.loc	1 253 0 prologue_end            ; decode_attention.py:253:0
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
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
	.loc	1 253 0 is_stmt 1               ; decode_attention.py:253
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	.loc	1 305 37                        ; decode_attention.py:305:37
	s_ashr_i32 s17, s16, 31
	s_lshl_b64 s[14:15], s[16:17], 2
	s_add_u32 s2, s10, s14
	s_addc_u32 s3, s11, s15
	v_mov_b32_e32 v1, 0
	global_load_dword v2, v1, s[2:3]
	.loc	1 306 61                        ; decode_attention.py:306:61
	NETRA_WAIT_VM0
	v_readfirstlane_b32 s10, v2
	s_mov_b32 s2, 0
	.loc	1 307 24                        ; decode_attention.py:307:24
	NETRA_WAIT_LGKM0
	s_add_u32 s6, s6, s14
	s_addc_u32 s7, s7, s15
	global_load_dword v1, v1, s[6:7]
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 43 23                         ; standard.py:43:23 @[ decode_attention.py:325:43 ]
	NETRA_WAIT_VM0
	v_readfirstlane_b32 s3, v1
	.loc	2 43 30 is_stmt 0               ; standard.py:43:30 @[ decode_attention.py:325:43 ]
	s_abs_i32 s6, s3
	v_cvt_f32_u32_e32 v1, s6
	s_sub_i32 s11, 0, s6
	.loc	2 43 23                         ; standard.py:43:23 @[ decode_attention.py:325:43 ]
	s_add_i32 s7, s3, s10
	.loc	2 43 17                         ; standard.py:43:17 @[ decode_attention.py:325:43 ]
	s_add_i32 s7, s7, -1
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:325:43 ]
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
	.loc	2 43 17                         ; standard.py:43:17 @[ decode_attention.py:325:55 ]
	s_add_i32 s3, s3, 31
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:325:55 ]
	s_ashr_i32 s6, s3, 31
	s_lshr_b32 s6, s6, 27
	s_add_i32 s3, s3, s6
.Ltmp4:
	.loc	1 325 71 is_stmt 1              ; decode_attention.py:325:71
	s_and_b32 s6, s3, 0xffffffe0
	.loc	1 327 40                        ; decode_attention.py:327:40
	s_mul_i32 s19, s6, s18
	.loc	1 328 47                        ; decode_attention.py:328:47
	s_add_i32 s6, s19, s6
	.loc	1 328 65 is_stmt 0              ; decode_attention.py:328:65
	s_min_i32 s33, s6, s10
	.loc	1 341 22 is_stmt 1              ; decode_attention.py:341:22
	s_cmp_le_i32 s33, s19
	.loc	1 421 12                        ; decode_attention.py:421:12
	v_readfirstlane_b32 s6, v0
	.loc	1 341 7                         ; decode_attention.py:341:7
	s_cbranch_scc1 .LBB0_4
; %bb.1:
	.loc	1 0 7 is_stmt 0                 ; decode_attention.py:0:7
	s_load_dwordx8 s[36:43], s[0:1], 0x48
	.loc	1 421 12 is_stmt 1              ; decode_attention.py:421:12
	s_bfe_u32 s17, s6, 0x20006
	.loc	1 296 29                        ; decode_attention.py:296:29
	s_lshl_b32 s34, s9, 3
	.loc	1 296 58 is_stmt 0              ; decode_attention.py:296:58
	v_and_b32_e32 v1, 63, v0
	s_lshl_b32 s6, s17, 6
	v_or_b32_e32 v14, s6, v1
	.loc	1 315 25 is_stmt 1              ; decode_attention.py:315:25
	NETRA_WAIT_LGKM0
	s_mul_i32 s10, s36, s16
	.loc	1 300 26                        ; decode_attention.py:300:26
	v_lshlrev_b32_e32 v15, 3, v0
	.loc	1 342 24                        ; decode_attention.py:342:24
	s_mul_i32 s11, s37, s34
	.loc	1 297 44                        ; decode_attention.py:297:44
	s_add_i32 s7, s34, 8
	.loc	1 300 26                        ; decode_attention.py:300:26
	v_and_b32_e32 v2, 0xf8, v15
	.loc	1 296 58                        ; decode_attention.py:296:58
	v_lshrrev_b32_e32 v3, 5, v14
	.loc	1 342 24                        ; decode_attention.py:342:24
	s_add_i32 s11, s11, s10
	.loc	1 298 23                        ; decode_attention.py:298:23
	s_min_i32 s7, s7, 16
	.loc	1 296 58                        ; decode_attention.py:296:58
	v_or_b32_e32 v4, 8, v3
	.loc	1 296 45 is_stmt 0              ; decode_attention.py:296:45
	v_or_b32_e32 v5, s34, v3
	.loc	1 342 24 is_stmt 1              ; decode_attention.py:342:24
	v_mul_lo_u32 v3, v3, s37
	v_add_u32_e32 v8, s11, v2
	.loc	1 296 45                        ; decode_attention.py:296:45
	v_add_u32_e32 v6, s34, v4
	.loc	1 342 24                        ; decode_attention.py:342:24
	v_mul_lo_u32 v7, v4, s37
	.loc	1 342 20 is_stmt 0              ; decode_attention.py:342:20
	v_add_lshl_u32 v2, v8, v3, 1
	v_bfrev_b32_e32 v19, 1
	.loc	1 298 23 is_stmt 1              ; decode_attention.py:298:23
	v_cmp_gt_i32_e32 vcc, s7, v5
	.loc	1 342 20                        ; decode_attention.py:342:20
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_cndmask_b32_e32 v2, v19, v2, vcc
	v_add_lshl_u32 v7, v8, v7, 1
	.loc	1 298 23                        ; decode_attention.py:298:23
	v_cmp_gt_i32_e32 vcc, s7, v6
	.loc	1 342 20                        ; decode_attention.py:342:20
	buffer_load_dwordx4 v[2:5], v2, s[20:23], 0 offen
	.loc	1 296 58                        ; decode_attention.py:296:58
	v_and_b32_e32 v20, 15, v0
	.loc	1 342 20                        ; decode_attention.py:342:20
	v_cndmask_b32_e32 v6, v19, v7, vcc
	buffer_load_dwordx4 v[6:9], v6, s[20:23], 0 offen
	.loc	1 300 26                        ; decode_attention.py:300:26
	v_mov_b32_e32 v10, 0xf0
	.loc	1 343 19                        ; decode_attention.py:343:19
	v_and_b32_e32 v17, 48, v0
	.loc	1 296 45                        ; decode_attention.py:296:45
	v_add_u32_e32 v11, s34, v20
	.loc	1 300 26                        ; decode_attention.py:300:26
	v_lshlrev_b32_e32 v12, 4, v20
	.loc	1 343 19                        ; decode_attention.py:343:19
	v_lshlrev_b32_e32 v13, 8, v20
	s_load_dwordx2 s[36:37], s[0:1], 0x38
	s_load_dword s35, s[0:1], 0x68
	s_movk_i32 s11, 0x70
	s_movk_i32 s20, 0x80
	.loc	1 300 26                        ; decode_attention.py:300:26
	v_bitop3_b32 v22, s6, v10, v1 bitop3:0xc8
	.loc	1 343 19                        ; decode_attention.py:343:19
	v_bitop3_b32 v1, v12, v0, 48 bitop3:0x78
	v_bitop3_b32 v10, v12, v13, v17 bitop3:0xde
	.loc	1 298 23                        ; decode_attention.py:298:23
	v_cmp_gt_i32_e64 s[0:1], s7, v11
	.loc	1 343 19                        ; decode_attention.py:343:19
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
	.loc	1 339 36                        ; decode_attention.py:339:36
	s_mul_i32 s6, s41, s9
	.loc	1 335 32                        ; decode_attention.py:335:32
	s_mul_i32 s7, s39, s9
	.loc	1 343 19                        ; decode_attention.py:343:19
	v_add_u32_e32 v32, 0, v11
	v_add_u32_e32 v33, 0, v10
	v_bitop3_b32 v27, v13, v17, v12 bitop3:0x36
	v_add_u32_e32 v1, 0, v1
	.loc	1 339 52                        ; decode_attention.py:339:52
	v_add_u32_e32 v16, s6, v12
	.loc	1 335 48                        ; decode_attention.py:335:48
	v_add_u32_e32 v18, s7, v12
	v_lshlrev_b32_e32 v25, 4, v14
	s_movk_i32 s7, 0x1f00
	s_lshl_b32 s6, s17, 4
	.loc	1 0 0 is_stmt 0                 ; decode_attention.py:0
	s_ashr_i32 s3, s3, 5
	s_movk_i32 s10, 0xf0
	v_xor_b32_e32 v28, 64, v27
	v_xor_b32_e32 v29, 0x80, v27
	v_xor_b32_e32 v30, 0xc0, v27
	v_bitop3_b32 v31, v25, v14, s10 bitop3:0x78
	s_and_b32 s13, s13, 0xffff
	s_and_b32 s5, s5, 0xffff
	s_and_b32 s49, s49, 0xffff
	.loc	1 349 44 is_stmt 1              ; decode_attention.py:349:44
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
	.loc	1 343 19                        ; decode_attention.py:343:19
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
	.loc	1 348 62                        ; decode_attention.py:348:62
	v_lshrrev_b32_e32 v23, 4, v14
	v_bitop3_b32 v34, s6, v0, v2 bitop3:0x36
	v_lshlrev_b32_e32 v0, 3, v23
	v_xor_b32_e32 v33, 8, v32
	v_xor_b32_e32 v35, 64, v34
	v_lshl_add_u32 v24, s2, 3, v0
	s_mul_i32 s2, s18, s3
	s_lshl_b32 s9, s2, 8
	v_mov_b32_e32 v25, 0
	.loc	1 349 31                        ; decode_attention.py:349:31
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
	.loc	1 349 31                        ; decode_attention.py:349:31
	v_add_u32_e32 v39, s19, v23
	.loc	1 351 16                        ; decode_attention.py:351:16
	v_add_u32_e32 v41, s9, v24
	.loc	1 349 31                        ; decode_attention.py:349:31
	v_add_u32_e32 v58, 16, v39
	.loc	1 352 30                        ; decode_attention.py:352:30
	v_cmp_gt_i32_e32 vcc, s33, v39
	.loc	1 349 31                        ; decode_attention.py:349:31
	v_add_u32_e32 v40, s19, v21
	.loc	1 351 16                        ; decode_attention.py:351:16
	v_add_u32_e32 v66, 0x80, v41
	v_cndmask_b32_e32 v39, v19, v41, vcc
	.loc	1 352 30                        ; decode_attention.py:352:30
	v_cmp_gt_i32_e64 s[10:11], s33, v58
	.loc	1 349 31                        ; decode_attention.py:349:31
	v_add_u32_e32 v59, 1, v40
	v_add_u32_e32 v60, 2, v40
	v_add_u32_e32 v61, 3, v40
	v_add_u32_e32 v62, 16, v40
	v_add_u32_e32 v63, 17, v40
	v_add_u32_e32 v64, 18, v40
	.loc	1 352 30                        ; decode_attention.py:352:30
	v_add_u32_e32 v65, 19, v40
	.loc	1 358 40                        ; decode_attention.py:358:40
	v_cmp_gt_i32_e64 s[2:3], s33, v40
	.loc	1 351 16                        ; decode_attention.py:351:16
	buffer_load_dwordx2 v[40:41], v39, s[12:15], 0 offen
	v_cndmask_b32_e64 v39, v19, v66, s[10:11]
	buffer_load_dwordx2 v[66:67], v39, s[12:15], 0 offen
	.loc	1 358 40                        ; decode_attention.py:358:40
	v_cmp_gt_i32_e64 s[20:21], s33, v59
	.loc	1 357 16                        ; decode_attention.py:357:16
	s_mov_b32 s6, s14
	s_mov_b32 s7, s15
	.loc	1 358 40                        ; decode_attention.py:358:40
	v_cmp_gt_i32_e64 s[22:23], s33, v60
	v_cmp_gt_i32_e64 s[24:25], s33, v61
	v_cmp_gt_i32_e64 s[28:29], s33, v64
	v_cmp_gt_i32_e64 s[30:31], s33, v65
	.loc	1 386 20                        ; decode_attention.py:386:20
	s_mov_b32 s50, s14
	s_mov_b32 s51, s15
	.loc	1 379 35                        ; decode_attention.py:379:35
	s_and_b64 s[2:3], s[0:1], s[2:3]
	.loc	1 348 62                        ; decode_attention.py:348:62
	s_add_i32 s19, s19, 32
	s_addk_i32 s9, 0x100
	.loc	1 357 27                        ; decode_attention.py:357:27
	s_waitcnt vmcnt(1)
	v_mad_u64_u32 v[58:59], s[26:27], s38, v40, v[18:19]
	NETRA_WAIT_VM0
	v_mad_u64_u32 v[60:61], s[26:27], s38, v66, v[18:19]
	.loc	1 357 16 is_stmt 0              ; decode_attention.py:357:16
	v_cndmask_b32_e32 v39, v19, v58, vcc
	v_cndmask_b32_e64 v41, v19, v60, s[10:11]
	buffer_load_dwordx4 v[58:61], v39, s[4:7], 0 offen
	buffer_load_dwordx4 v[68:71], v41, s[4:7], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	.loc	1 358 40 is_stmt 1              ; decode_attention.py:358:40
	v_cmp_gt_i32_e64 s[6:7], s33, v62
	v_cmp_gt_i32_e64 s[26:27], s33, v63
	.loc	1 386 31                        ; decode_attention.py:386:31
	v_mad_u64_u32 v[40:41], s[46:47], s40, v40, v[16:17]
	v_mad_u64_u32 v[66:67], s[46:47], s40, v66, v[16:17]
	.loc	1 386 20 is_stmt 0              ; decode_attention.py:386:20
	v_cndmask_b32_e32 v39, v19, v40, vcc
	v_cndmask_b32_e64 v40, v19, v66, s[10:11]
	.loc	1 379 35 is_stmt 1              ; decode_attention.py:379:35
	s_and_b64 vcc, s[0:1], s[20:21]
	s_and_b64 s[10:11], s[0:1], s[22:23]
	s_and_b64 s[20:21], s[0:1], s[24:25]
	s_and_b64 s[6:7], s[0:1], s[6:7]
	s_and_b64 s[22:23], s[0:1], s[26:27]
	s_and_b64 s[24:25], s[0:1], s[28:29]
	s_and_b64 s[26:27], s[0:1], s[30:31]
	.loc	1 348 62                        ; decode_attention.py:348:62
	s_cmp_lt_i32 s19, s33
	.loc	1 357 16                        ; decode_attention.py:357:16
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
	.loc	1 361 29                        ; decode_attention.py:361:29
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[58:61], v[68:75], v[42:49], 0
	.loc	1 357 16                        ; decode_attention.py:357:16
	ds_read_b128 v[72:75], v30
	.loc	1 361 29                        ; decode_attention.py:361:29
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x128_f8f6f4 v[62:65], v[76:83], v[42:49], 0
	.loc	1 357 16                        ; decode_attention.py:357:16
	ds_read_b128 v[68:71], v29
	ds_read_b128 v[76:79], v29 offset:4096
	ds_read_b128 v[80:83], v30 offset:4096
	.loc	1 361 29                        ; decode_attention.py:361:29
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[58:61], v[68:75], v[50:57], v[58:61]
	.loc	1 386 20                        ; decode_attention.py:386:20
	buffer_load_dwordx4 v[66:69], v39, s[48:51], 0 offen
	buffer_load_dwordx4 v[70:73], v40, s[48:51], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write2st64_b64 v31, v[66:67], v[70:71] offset1:8
	ds_write2st64_b64 v32, v[68:69], v[72:73] offset1:8
	.loc	1 361 29                        ; decode_attention.py:361:29
	v_mfma_f32_16x16x128_f8f6f4 v[62:65], v[76:83], v[50:57], v[62:65]
	.loc	1 370 18                        ; decode_attention.py:370:18
	s_nop 3
	v_mul_f32_e32 v39, s8, v58
	v_mul_f32_e32 v40, s8, v59
	v_mul_f32_e32 v41, s8, v60
	v_mul_f32_e32 v58, s8, v61
	.loc	1 379 72                        ; decode_attention.py:379:72
	v_cndmask_b32_e32 v40, v35, v40, vcc
	v_cndmask_b32_e64 v41, v35, v41, s[10:11]
	v_cndmask_b32_e64 v58, v35, v58, s[20:21]
	.loc	1 370 18                        ; decode_attention.py:370:18
	s_nop 0
	v_mul_f32_e32 v60, s8, v63
	.loc	1 379 72                        ; decode_attention.py:379:72
	v_cndmask_b32_e64 v63, v35, v39, s[2:3]
	.loc	1 370 18                        ; decode_attention.py:370:18
	v_mul_f32_e32 v59, s8, v62
.Ltmp5:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ decode_attention.py:391:44 ] ]
	v_max_f32_e32 v39, v63, v40
.Ltmp6:
	.loc	1 370 18                        ; decode_attention.py:370:18
	v_mul_f32_e32 v61, s8, v64
	v_mul_f32_e32 v62, s8, v65
	.loc	1 379 72                        ; decode_attention.py:379:72
	v_cndmask_b32_e64 v59, v35, v59, s[6:7]
	v_cndmask_b32_e64 v60, v35, v60, s[22:23]
.Ltmp7:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ decode_attention.py:391:44 ] ]
	v_max3_f32 v39, v39, v41, v58
.Ltmp8:
	.loc	1 379 72                        ; decode_attention.py:379:72
	v_cndmask_b32_e64 v61, v35, v61, s[24:25]
	v_cndmask_b32_e64 v62, v35, v62, s[26:27]
.Ltmp9:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ decode_attention.py:391:44 ] ]
	v_max3_f32 v39, v39, v59, v60
	v_max3_f32 v39, v39, v61, v62
.Ltmp10:
	.loc	2 191 40                        ; standard.py:191:40 @[ decode_attention.py:391:44 ]
	v_mov_b32_e32 v64, v39
	s_nop 1
	v_permlane32_swap_b32_e32 v39, v64
.Ltmp11:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ decode_attention.py:391:44 ] ]
	v_max_f32_e32 v64, v64, v64
	v_max_f32_e32 v39, v39, v39
	v_max_f32_e32 v39, v39, v64
.Ltmp12:
	.loc	2 191 40                        ; standard.py:191:40 @[ decode_attention.py:391:44 ]
	v_mov_b32_e32 v64, v39
	s_nop 1
	v_permlane16_swap_b32_e32 v39, v64
.Ltmp13:
	.loc	1 391 48                        ; decode_attention.py:391:48
	v_max3_f32 v39, v39, v64, v36
	.loc	1 392 38                        ; decode_attention.py:392:38
	v_sub_f32_e32 v64, v36, v39
	.loc	1 393 28                        ; decode_attention.py:393:28
	v_sub_f32_e32 v63, v63, v39
	v_sub_f32_e32 v40, v40, v39
	v_sub_f32_e32 v41, v41, v39
	v_sub_f32_e32 v58, v58, v39
	.loc	1 392 30                        ; decode_attention.py:392:30
	v_mul_f32_e32 v65, 0x3fb8aa3b, v64
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_mul_f32_e32 v74, 0x3fb8aa3b, v63
	v_mul_f32_e32 v75, 0x3fb8aa3b, v40
	v_mul_f32_e32 v76, 0x3fb8aa3b, v41
	v_mul_f32_e32 v77, 0x3fb8aa3b, v58
	.loc	1 392 30                        ; decode_attention.py:392:30
	v_cmp_gt_f32_e32 vcc, s39, v65
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cmp_gt_f32_e64 s[2:3], s39, v74
	v_cmp_gt_f32_e64 s[6:7], s39, v75
	.loc	1 393 28 is_stmt 0              ; decode_attention.py:393:28
	v_sub_f32_e32 v59, v59, v39
	v_sub_f32_e32 v60, v60, v39
	.loc	1 392 30 is_stmt 1              ; decode_attention.py:392:30
	v_cndmask_b32_e32 v65, 0, v37, vcc
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cndmask_b32_e64 v74, 0, v37, s[2:3]
	v_cndmask_b32_e64 v75, 0, v37, s[6:7]
	v_cmp_gt_f32_e64 s[10:11], s39, v76
	v_cmp_gt_f32_e64 s[20:21], s39, v77
	v_mul_f32_e32 v78, 0x3fb8aa3b, v59
	v_mul_f32_e32 v79, 0x3fb8aa3b, v60
	v_cndmask_b32_e64 v76, 0, v37, s[10:11]
	v_cndmask_b32_e64 v77, 0, v37, s[20:21]
	.loc	1 392 30                        ; decode_attention.py:392:30
	v_fmac_f32_e32 v65, 0x3fb8aa3b, v64
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_fmac_f32_e32 v74, 0x3fb8aa3b, v63
	v_fmac_f32_e32 v75, 0x3fb8aa3b, v40
	.loc	1 393 28 is_stmt 0              ; decode_attention.py:393:28
	v_sub_f32_e32 v61, v61, v39
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cmp_gt_f32_e64 s[22:23], s39, v78
	v_cmp_gt_f32_e64 s[24:25], s39, v79
	v_fmac_f32_e32 v76, 0x3fb8aa3b, v41
	v_fmac_f32_e32 v77, 0x3fb8aa3b, v58
	.loc	1 392 30 is_stmt 1              ; decode_attention.py:392:30
	v_exp_f32_e32 v58, v65
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_exp_f32_e32 v65, v74
	v_exp_f32_e32 v74, v75
	.loc	1 393 28 is_stmt 0              ; decode_attention.py:393:28
	v_sub_f32_e32 v62, v62, v39
	.loc	1 393 23                        ; decode_attention.py:393:23
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
	.loc	1 392 30 is_stmt 1              ; decode_attention.py:392:30
	v_cndmask_b32_e32 v64, 0, v38, vcc
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cndmask_b32_e64 v63, 0, v38, s[2:3]
	v_cndmask_b32_e64 v40, 0, v38, s[6:7]
	v_exp_f32_e32 v77, v78
	v_exp_f32_e32 v78, v79
	v_cndmask_b32_e64 v81, 0, v37, s[28:29]
	v_cndmask_b32_e64 v41, 0, v38, s[10:11]
	v_fmac_f32_e32 v80, 0x3fb8aa3b, v61
	.loc	1 392 30                        ; decode_attention.py:392:30
	v_ldexp_f32 v58, v58, v64
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_ldexp_f32 v63, v65, v63
	v_ldexp_f32 v64, v74, v40
	v_cndmask_b32_e64 v82, 0, v38, s[20:21]
	v_fmac_f32_e32 v81, 0x3fb8aa3b, v62
	v_exp_f32_e32 v79, v80
	v_ldexp_f32 v65, v75, v41
	.loc	1 395 31                        ; decode_attention.py:395:31
	v_cvt_scalef32_pk_fp8_f32 v40, v63, v64, 1.0
.Ltmp14:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v63, v63, v64
.Ltmp15:
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cndmask_b32_e64 v59, 0, v38, s[22:23]
	v_cndmask_b32_e64 v60, 0, v38, s[24:25]
	v_exp_f32_e32 v80, v81
	v_ldexp_f32 v74, v76, v82
.Ltmp16:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v63, v65, v63
.Ltmp17:
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_ldexp_f32 v59, v77, v59
	v_ldexp_f32 v60, v78, v60
.Ltmp18:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v63, v74, v63
.Ltmp19:
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cndmask_b32_e64 v61, 0, v38, s[26:27]
	.loc	1 395 31                        ; decode_attention.py:395:31
	v_cvt_scalef32_pk_fp8_f32 v41, v59, v60, 1.0
	.loc	1 395 41 is_stmt 0              ; decode_attention.py:395:41
	v_pk_mul_f32 v[14:15], v[14:15], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[58:59] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[58:59] op_sel_hi:[1,0]
.Ltmp20:
	.loc	2 263 15 is_stmt 1              ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v59, v59, v63
.Ltmp21:
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_cndmask_b32_e64 v62, 0, v38, s[28:29]
	v_ldexp_f32 v61, v79, v61
.Ltmp22:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v59, v60, v59
.Ltmp23:
	.loc	1 393 23                        ; decode_attention.py:393:23
	v_ldexp_f32 v62, v80, v62
.Ltmp24:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v59, v61, v59
.Ltmp25:
	.loc	1 395 31                        ; decode_attention.py:395:31
	v_cvt_scalef32_pk_fp8_f32 v40, v65, v74, 1.0 op_sel:[0,0,0,1]
	.loc	1 386 20                        ; decode_attention.py:386:20
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b8 v[64:65], v33
	ds_read_b64_tr_b8 v[66:67], v34
	ds_read_b64_tr_b8 v[68:69], v33 offset:128
	ds_read_b64_tr_b8 v[70:71], v34 offset:128
.Ltmp26:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v59, v62, v59
.Ltmp27:
	.loc	2 293 36                        ; standard.py:293:36 @[ decode_attention.py:397:49 ]
	v_mov_b32_e32 v60, v59
.Ltmp28:
	.loc	1 395 31                        ; decode_attention.py:395:31
	v_cvt_scalef32_pk_fp8_f32 v41, v61, v62, 1.0 op_sel:[0,0,0,1]
.Ltmp29:
	.loc	2 293 36                        ; standard.py:293:36 @[ decode_attention.py:397:49 ]
	s_nop 0
	v_permlane32_swap_b32_e32 v59, v60
.Ltmp30:
	.loc	1 395 31                        ; decode_attention.py:395:31
	v_permlane32_swap_b32_e32 v40, v41
.Ltmp31:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v59, v59, v60
.Ltmp32:
	.loc	1 395 31                        ; decode_attention.py:395:31
	s_nop 0
	v_permlane16_swap_b32_e32 v40, v41
.Ltmp33:
	.loc	2 293 36                        ; standard.py:293:36 @[ decode_attention.py:397:49 ]
	v_mov_b32_e32 v60, v59
.Ltmp34:
	.loc	1 395 41                        ; decode_attention.py:395:41
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[12:15], v[64:65], v[40:41], v[12:15]
.Ltmp35:
	.loc	2 293 36                        ; standard.py:293:36 @[ decode_attention.py:397:49 ]
	v_permlane16_swap_b32_e32 v59, v60
	v_mov_b32_e32 v36, v39
.Ltmp36:
	.loc	1 395 41                        ; decode_attention.py:395:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[8:11], v[66:67], v[40:41], v[8:11]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_fp8_fp8 v[4:7], v[68:69], v[40:41], v[4:7]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_fp8_fp8 v[0:3], v[70:71], v[40:41], v[0:3]
.Ltmp37:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ decode_attention.py:397:49 ] ]
	v_add_f32_e32 v40, v59, v60
.Ltmp38:
	.loc	1 397 39                        ; decode_attention.py:397:39
	v_fmac_f32_e32 v40, v25, v58
	v_mov_b32_e32 v25, v40
	.loc	1 348 62                        ; decode_attention.py:348:62
	s_cbranch_scc1 .LBB0_2
; %bb.3:
	.loc	1 409 18                        ; decode_attention.py:409:18
	v_div_scale_f32 v19, s[2:3], v40, v40, v12
	.loc	1 408 22                        ; decode_attention.py:408:22
	v_mul_lo_u32 v18, s43, v20
	.loc	1 409 18                        ; decode_attention.py:409:18
	v_rcp_f32_e32 v20, v19
	.loc	1 300 26                        ; decode_attention.py:300:26
	v_lshrrev_b32_e32 v16, 2, v22
	.loc	1 401 24                        ; decode_attention.py:401:24
	s_mul_i32 s4, s42, s16
	.loc	1 403 28                        ; decode_attention.py:403:28
	s_mul_i32 s5, s35, s18
	.loc	1 409 18                        ; decode_attention.py:409:18
	v_fma_f32 v21, -v19, v20, 1.0
	v_fmac_f32_e32 v20, v21, v20
	v_div_scale_f32 v21, vcc, v12, v40, v12
	v_mul_f32_e32 v22, v21, v20
	.loc	1 408 22                        ; decode_attention.py:408:22
	s_mul_i32 s6, s43, s34
	s_add_i32 s2, s5, s4
	.loc	1 409 18                        ; decode_attention.py:409:18
	v_fma_f32 v23, -v19, v22, v21
	.loc	1 408 22                        ; decode_attention.py:408:22
	s_add_i32 s2, s2, s6
	.loc	1 409 18                        ; decode_attention.py:409:18
	v_fmac_f32_e32 v22, v23, v20
	.loc	1 408 22                        ; decode_attention.py:408:22
	v_add_u32_e32 v18, s2, v18
	.loc	1 409 18                        ; decode_attention.py:409:18
	v_fma_f32 v19, -v19, v22, v21
	v_div_scale_f32 v21, s[2:3], v40, v40, v13
	v_rcp_f32_e32 v23, v21
	v_div_fmas_f32 v19, v19, v20, v22
	v_div_fixup_f32 v12, v19, v40, v12
	.loc	1 408 22                        ; decode_attention.py:408:22
	v_add_lshl_u32 v16, v18, v16, 2
	.loc	1 409 18                        ; decode_attention.py:409:18
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
	.loc	1 409 12 is_stmt 0              ; decode_attention.py:409:12
	s_and_b32 s45, s45, 0xffff
	.loc	1 409 18                        ; decode_attention.py:409:18
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
	.loc	1 421 12 is_stmt 1              ; decode_attention.py:421:12
	s_and_b32 s37, s37, 0xffff
	.loc	1 409 18                        ; decode_attention.py:409:18
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
	.loc	1 421 12                        ; decode_attention.py:421:12
	s_mov_b32 s38, s46
	.loc	1 409 18                        ; decode_attention.py:409:18
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
	.loc	1 421 12                        ; decode_attention.py:421:12
	s_mov_b32 s39, s47
	.loc	1 409 18                        ; decode_attention.py:409:18
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
	.loc	1 409 12 is_stmt 0              ; decode_attention.py:409:12
	v_bfrev_b32_e32 v19, 1
	v_cndmask_b32_e64 v20, v19, v16, s[0:1]
	buffer_store_dwordx4 v[12:15], v20, s[44:47], 0 offen
	.loc	1 421 27 is_stmt 1              ; decode_attention.py:421:27
	v_cmp_gt_f32_e32 vcc, s2, v40
	s_mov_b32 s2, 0x3f317217
	.loc	1 409 12                        ; decode_attention.py:409:12
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
	.loc	1 421 27                        ; decode_attention.py:421:27
	s_nop 1
	v_cndmask_b32_e64 v1, 0, 32, vcc
	v_ldexp_f32 v1, v40, v1
	v_log_f32_e32 v1, v1
	.loc	1 417 13                        ; decode_attention.py:417:13
	v_ashrrev_i32_e32 v0, 31, v18
	v_add_u32_sdwa v0, v18, v0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_3
	v_ashrrev_i32_e32 v0, 8, v0
	.loc	1 421 27                        ; decode_attention.py:421:27
	v_mul_f32_e32 v2, 0x3f317217, v1
	v_fma_f32 v2, v1, s2, -v2
	v_fmamk_f32 v2, v1, 0x3377d1cf, v2
	s_mov_b32 s2, 0x7f800000
	v_fmac_f32_e32 v2, 0x3f317217, v1
	v_cmp_lt_f32_e64 s[2:3], |v1|, s2
	.loc	1 421 12 is_stmt 0              ; decode_attention.py:421:12
	v_lshlrev_b32_e32 v0, 2, v0
	.loc	1 421 27                        ; decode_attention.py:421:27
	s_nop 0
	v_cndmask_b32_e64 v1, v1, v2, s[2:3]
	v_mov_b32_e32 v2, 0x41b17218
	v_cndmask_b32_e32 v2, 0, v2, vcc
	v_sub_f32_e32 v1, v1, v2
	.loc	1 421 12                        ; decode_attention.py:421:12
	v_or_b32_e32 v2, s17, v17
	v_cmp_eq_u32_e32 vcc, 0, v2
	s_and_b64 vcc, s[0:1], vcc
	.loc	1 421 20                        ; decode_attention.py:421:20
	v_add_f32_e32 v1, v39, v1
	.loc	1 421 12                        ; decode_attention.py:421:12
	v_cndmask_b32_e32 v0, v19, v0, vcc
	buffer_store_dword v1, v0, s[36:39], 0 offen
.LBB0_4:
	.loc	1 425 4 is_stmt 1               ; decode_attention.py:425:4
	s_endpgm
.Ltmp39:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 128
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
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 257
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 84
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
	.cfi_endproc
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
	.byte	5                               ; DW_FORM_data2
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
	.byte	1                               ; Abbrev [1] 0xb:0x97 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x71 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x15 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp2                          ; DW_AT_low_pc
	.long	.Ltmp3-.Ltmp2                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	325                             ; DW_AT_call_line
	.byte	43                              ; DW_AT_call_column
	.byte	4                               ; Abbrev [4] 0x56:0x15 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	325                             ; DW_AT_call_line
	.byte	55                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x6b:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	391                             ; DW_AT_call_line
	.byte	44                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x78:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x85:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	397                             ; DW_AT_call_line
	.byte	49                              ; DW_AT_call_column
	.byte	7                               ; Abbrev [7] 0x92:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
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
	.quad	0
	.quad	0
.Ldebug_ranges3:
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
	.quad	.Ltmp31-.Lfunc_begin0
	.quad	.Ltmp32-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"decode_attention.py"           ; string offset=7
.Linfo_string2:
	.asciz	"/netra-server/python/sglang/srt/layers/attention/triton_ops" ; string offset=27
.Linfo_string3:
	.asciz	"\symbol"    ; string offset=87
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
      - .offset:         24
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         64
        .size:           8
        .value_kind:     global_buffer
      - .offset:         72
        .size:           4
        .value_kind:     by_value
      - .offset:         76
        .size:           4
        .value_kind:     by_value
      - .offset:         80
        .size:           4
        .value_kind:     by_value
      - .offset:         84
        .size:           4
        .value_kind:     by_value
      - .offset:         88
        .size:           4
        .value_kind:     by_value
      - .offset:         92
        .size:           4
        .value_kind:     by_value
      - .offset:         96
        .size:           4
        .value_kind:     by_value
      - .offset:         100
        .size:           4
        .value_kind:     by_value
      - .offset:         104
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         112
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         120
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 128
    .max_flat_workgroup_size: 256
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     58
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     84
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
	.endm
