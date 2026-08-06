	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	; Experimental hand-specialized Qwen3.6 target-prefill attention.
	; Exact contract: one M8192 sequence, GQA8, Dq=Dv=256, BF16 extension
	; Q/K/V and native FP8-E4M3 paged prefix K/V. Grid [1,16,64], block 512,
	; dynamic LDS 65536. This raw source starts from the exact deployed gfx950
	; N128/W8 instruction schedule, then replaces generic sequence/head mapping
	; with the fixed Qwen contract. In particular, cur_head / kv_group_num is a
	; scalar shift by three and the single-sequence qo_indptr is specialized to
	; [0,8192]. No RDNA or wave32 assumptions are used.
	.text
	.globl	qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950                     ; -- Begin function qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950
	.p2align	8
	.type	qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950,@function
qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950:                            ; @qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.27:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/triton_ops" "extend_attention.py"
	.loc	1 359 0 prologue_end            ; extend_attention.py:359:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.28:
.LBB0_0:
	s_mov_b64 s[80:81], s[6:7]
	s_mov_b64 s[84:85], s[2:3]
	s_load_dwordx2 s[6:7], s[0:1], 0x38
	s_load_dword s97, s[0:1], 0x48
	s_load_dwordx2 s[2:3], s[0:1], 0x54
	s_load_dword s19, s[0:1], 0x5c
	s_mov_b32 s99, s17
	v_mov_b32_e32 v109, v0
.Ltmp1:
	.loc	1 359 0 is_stmt 1               ; extend_attention.py:359
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	s_waitcnt lgkmcnt(0)
	; Exact GQA8: cur_kv_head = cur_head >> 3. This replaces the generic
	; signed integer division and its reciprocal/conversion sequence.
	s_lshr_b32 s33, s99, 3
	; Preserve the deployed wave64 lane/workgroup mapping.
	v_readfirstlane_b32 s20, v109
	s_and_b32 s96, s20, 0x1c0
	v_mov_b32_e32 v97, 0
	s_mov_b32 s89, 0
	v_and_b32_e32 v103, 63, v109
	; Exact one-sequence qo_indptr=[0,8192]. Keep the kv_indptr load dynamic so
	; the same HSACO covers all measured prefix lengths.
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v68, 8192
	v_mov_b32_e32 v69, 0
	.loc	1 453 28                        ; extend_attention.py:453:28
	s_lshl_b32 s88, s18, 7
	.loc	1 450 26                        ; extend_attention.py:450:26
	v_or_b32_e32 v112, s96, v103
	v_and_b32_e32 v102, 15, v109
	.loc	1 470 21                        ; extend_attention.py:470:21
	s_mul_i32 s19, s19, s99
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_lshrrev_b32_e32 v4, 4, v112
	.loc	1 450 26                        ; extend_attention.py:450:26
	v_lshlrev_b32_e32 v96, 4, v102
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_or_b32_e32 v5, 32, v4
	v_or_b32_e32 v7, 64, v4
	v_or_b32_e32 v9, 0x60, v4
	.loc	1 474 19                        ; extend_attention.py:474:19
	v_mul_lo_u32 v20, v4, s3
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v4, s88, v4
	.loc	1 474 19                        ; extend_attention.py:474:19
	v_mul_lo_u32 v21, v5, s3
	v_mul_lo_u32 v22, v7, s3
	v_mul_lo_u32 v23, v9, s3
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v6, s88, v5
	v_or_b32_e32 v8, s88, v7
	v_or_b32_e32 v10, s88, v9
	.loc	1 453 48 is_stmt 0              ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v5, 31, v4
	.loc	1 474 8 is_stmt 1               ; extend_attention.py:474:8
	v_bfrev_b32_e32 v105, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v7, 31, v6
	v_ashrrev_i32_e32 v9, 31, v8
	v_ashrrev_i32_e32 v11, 31, v10
	s_mov_b32 s87, 0x27000
	s_mov_b32 s86, 0x7ffffffe
	.loc	1 474 8                         ; extend_attention.py:474:8
	s_and_b32 s85, s85, 0xffff
	.loc	1 438 35                        ; extend_attention.py:438:35
	global_load_dwordx2 v[2:3], v97, s[6:7]
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_and_b32_e32 v114, 48, v109
	.loc	1 474 8                         ; extend_attention.py:474:8
	v_lshlrev_b32_e32 v104, 9, v102
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v124, 0xff800000
	v_mov_b32_e32 v123, 0
	v_lshlrev_b32_e32 v0, 3, v109
	v_lshlrev_b32_e32 v119, 3, v102
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_lshrrev_b32_e32 v84, 2, v114
	.loc	1 468 36                        ; extend_attention.py:468:36
	s_waitcnt vmcnt(1)
	v_lshl_add_u64 v[106:107], v[66:67], 0, s[88:89]
	.loc	1 474 19                        ; extend_attention.py:474:19
	v_mul_lo_u32 v12, v106, s3
	.loc	1 437 60                        ; extend_attention.py:437:60
	v_sub_co_u32_e32 v120, vcc, v68, v66
	.loc	1 474 19                        ; extend_attention.py:474:19
	v_add_u32_e32 v12, s19, v12
	.loc	1 437 60                        ; extend_attention.py:437:60
	s_nop 0
	v_subb_co_u32_e32 v121, vcc, v69, v67, vcc
	.loc	1 474 19                        ; extend_attention.py:474:19
	v_add_u32_e32 v24, v12, v96
	.loc	1 474 8 is_stmt 0               ; extend_attention.py:474:8
	v_add_lshl_u32 v12, v24, v20, 1
	v_add_lshl_u32 v13, v24, v21, 1
	v_add_lshl_u32 v14, v24, v22, 1
	v_add_lshl_u32 v15, v24, v23, 1
	.loc	1 453 48 is_stmt 1              ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[4:5]
	.loc	1 474 19                        ; extend_attention.py:474:19
	v_add_u32_e32 v24, 8, v24
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e64 s[2:3], v[120:121], v[6:7]
	.loc	1 474 8                         ; extend_attention.py:474:8
	v_cndmask_b32_e32 v25, v105, v12, vcc
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e64 s[6:7], v[120:121], v[8:9]
	v_cmp_gt_i64_e64 s[14:15], v[120:121], v[10:11]
	.loc	1 474 8                         ; extend_attention.py:474:8
	v_add_lshl_u32 v20, v24, v20, 1
	v_add_lshl_u32 v21, v24, v21, 1
	v_cndmask_b32_e64 v26, v105, v13, s[2:3]
	v_cndmask_b32_e64 v27, v105, v14, s[6:7]
	v_cndmask_b32_e64 v28, v105, v15, s[14:15]
	buffer_load_dwordx4 v[4:7], v25, s[84:87], 0 offen
	buffer_load_dwordx4 v[8:11], v26, s[84:87], 0 offen
	buffer_load_dwordx4 v[12:15], v27, s[84:87], 0 offen
	buffer_load_dwordx4 v[16:19], v28, s[84:87], 0 offen
	v_add_lshl_u32 v25, v24, v22, 1
	v_add_lshl_u32 v24, v24, v23, 1
	v_cndmask_b32_e32 v20, v105, v20, vcc
	v_cndmask_b32_e64 v36, v105, v21, s[2:3]
	buffer_load_dwordx4 v[20:23], v20, s[84:87], 0 offen
	v_cndmask_b32_e64 v37, v105, v25, s[6:7]
	v_cndmask_b32_e64 v38, v105, v24, s[14:15]
	buffer_load_dwordx4 v[24:27], v36, s[84:87], 0 offen
	buffer_load_dwordx4 v[28:31], v37, s[84:87], 0 offen
	buffer_load_dwordx4 v[32:35], v38, s[84:87], 0 offen
	s_movk_i32 s2, 0xf0
	v_lshlrev_b32_e32 v67, 5, v112
	.loc	1 542 29                        ; extend_attention.py:542:29
	v_lshlrev_b32_e32 v36, 4, v112
	.loc	1 474 8                         ; extend_attention.py:474:8
	v_bitop3_b32 v37, v67, v112, s2 bitop3:0x78
	.loc	1 542 29                        ; extend_attention.py:542:29
	v_bitop3_b32 v36, v36, v112, s2 bitop3:0x78
	.loc	1 474 8                         ; extend_attention.py:474:8
	s_lshl_b32 s2, s96, 7
	v_add_u32_e32 v1, 0, v37
	v_xor_b32_e32 v37, 16, v37
	.loc	1 542 29                        ; extend_attention.py:542:29
	v_add_u32_e32 v113, 0, v36
	.loc	1 474 8                         ; extend_attention.py:474:8
	v_or_b32_e32 v36, s2, v96
	s_movk_i32 s7, 0x80
	s_movk_i32 s14, 0xc0
	v_add_u32_e32 v122, 0, v37
	v_bitop3_b32 v37, s2, v114, v96 bitop3:0x36
	v_bitop3_b32 v36, v36, v104, v114 bitop3:0xde
	v_bitop3_b32 v38, v37, s7, v104 bitop3:0x36
	v_bitop3_b32 v37, v37, s14, v104 bitop3:0x36
	v_add_u32_e32 v39, 0, v36
	v_xad_u32 v42, v36, 64, 0
	v_add_u32_e32 v38, 0, v38
	v_add_u32_e32 v43, 0, v37
	.loc	1 452 26                        ; extend_attention.py:452:26
	s_lshr_b32 s15, s96, 2
	v_or_b32_e32 v68, s15, v102
	.loc	1 438 35                        ; extend_attention.py:438:35
	s_waitcnt vmcnt(8)
	v_readfirstlane_b32 s16, v2
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v110, s88, v68
	.loc	1 439 60                        ; extend_attention.py:439:60
	v_readfirstlane_b32 s17, v3
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v111, 31, v110
	.loc	1 439 60                        ; extend_attention.py:439:60
	s_sub_i32 s90, s17, s16
	v_add_u32_e32 v69, s96, v103
	s_movk_i32 s6, 0x60
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e64 s[2:3], v[120:121], v[110:111]
	.loc	1 494 48                        ; extend_attention.py:494:48
	s_cmp_lt_i32 s90, 1
	v_lshrrev_b32_e32 v252, 4, v69
	.loc	1 474 8                         ; extend_attention.py:474:8
	s_waitcnt vmcnt(7)
	ds_write_b128 v1, v[4:7]
	s_waitcnt vmcnt(6)
	ds_write_b128 v1, v[8:11] offset:16384
	s_waitcnt vmcnt(5)
	ds_write_b128 v1, v[12:15] offset:32768
	s_waitcnt vmcnt(4)
	ds_write_b128 v1, v[16:19] offset:49152
	s_waitcnt vmcnt(2)
	ds_write_b128 v122, v[24:27] offset:16384
	s_waitcnt vmcnt(1)
	ds_write_b128 v122, v[28:31] offset:32768
	s_waitcnt vmcnt(0)
	ds_write_b128 v122, v[32:35] offset:49152
	ds_write_b128 v122, v[20:23]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[190:193], v39
	ds_read_b128 v[170:173], v39 offset:256
	ds_read_b128 v[196:199], v42
	ds_read_b128 v[200:203], v42 offset:256
	ds_read_b128 v[204:207], v38
	ds_read_b128 v[208:211], v38 offset:256
	ds_read_b128 v[212:215], v43
	ds_read_b128 v[174:177], v43 offset:256
	.loc	1 542 29                        ; extend_attention.py:542:29
	v_cvt_scalef32_pk_fp8_bf16 v2, v4, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v3, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v36, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v37, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v40, v12, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v41, v14, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v44, v16, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v45, v18, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v2, v5, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v4, v20, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v5, v22, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v38, v24, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v39, v26, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v42, v28, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v43, v30, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v46, v32, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v47, v34, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v3, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v36, v9, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v37, v11, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v40, v13, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v41, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v44, v17, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v45, v19, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v4, v21, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v5, v23, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v38, v25, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v39, v27, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v42, v29, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v43, v31, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v46, v33, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v47, v35, 1.0 op_sel:[0,0,1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v113, v[2:5]
	ds_write_b128 v113, v[36:39] offset:8192
	ds_write_b128 v113, v[40:43] offset:16384
	ds_write_b128 v113, v[44:47] offset:24576
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v4, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 494 48                        ; extend_attention.py:494:48
	s_cbranch_scc1 .LBB0_20
; %bb.1:                                ; %.lr.ph
	.loc	1 0 48 is_stmt 0                ; extend_attention.py:0:48
	s_load_dwordx4 s[20:23], s[0:1], 0x78
	s_load_dwordx2 s[84:85], s[0:1], 0x40
	s_load_dwordx2 s[82:83], s[0:1], 0x4c
	.loc	1 542 29 is_stmt 1              ; extend_attention.py:542:29
	v_lshlrev_b32_e32 v3, 8, v102
	v_mov_b64_e32 v[218:219], v[176:177]
	.loc	1 534 32                        ; extend_attention.py:534:32
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s17, s33, s21
	.loc	1 575 32                        ; extend_attention.py:575:32
	s_mul_i32 s19, s33, s23
	.loc	1 533 39                        ; extend_attention.py:533:39
	s_ashr_i32 s91, s20, 31
	s_mov_b32 s92, s20
	.loc	1 534 18                        ; extend_attention.py:534:18
	s_ashr_i32 s18, s17, 31
	.loc	1 574 39                        ; extend_attention.py:574:39
	s_ashr_i32 s93, s22, 31
	.loc	1 575 18                        ; extend_attention.py:575:18
	s_ashr_i32 s20, s19, 31
	.loc	1 494 48                        ; extend_attention.py:494:48
	s_add_u32 s10, s10, s17
	s_addc_u32 s11, s11, s18
	v_lshl_add_u64 v[98:99], s[10:11], 0, v[96:97]
	s_add_u32 s10, s12, s19
	s_addc_u32 s11, s13, s20
	.loc	1 555 29                        ; extend_attention.py:555:29
	v_mov_b32_e32 v2, s82
	.loc	1 494 48                        ; extend_attention.py:494:48
	v_lshl_add_u64 v[100:101], s[10:11], 0, v[96:97]
	.loc	1 542 29                        ; extend_attention.py:542:29
	s_lshl_b32 s10, s96, 6
	.loc	1 555 29                        ; extend_attention.py:555:29
	v_mul_f32_e32 v115, s97, v2
	.loc	1 542 29                        ; extend_attention.py:542:29
	v_bitop3_b32 v2, s10, v96, v114 bitop3:0xf6
	v_or_b32_e32 v4, v2, v3
	v_bitop3_b32 v5, v2, s14, v3 bitop3:0x36
	v_bitop3_b32 v2, v2, s7, v3 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v2, 0, v2
	v_mov_b64_e32 v[216:217], v[174:175]
	scratch_store_dwordx4 off, v[170:173], off offset:32 ; 16-byte Folded Spill
	scratch_store_dwordx4 off, v[190:193], off offset:16 ; 16-byte Folded Spill
	ds_read_b128 v[176:179], v5
	ds_read_b128 v[172:175], v2
	v_xad_u32 v2, v4, 64, 0
	v_add_u32_e32 v4, 0, v4
	ds_read_b128 v[184:187], v2
	ds_read_b128 v[180:183], v4
	v_bitop3_b32 v69, v3, v114, v96 bitop3:0x36
	v_mul_u32_u24_e32 v2, 34, v114
	v_and_b32_e32 v3, 14, v109
	v_lshlrev_b32_e32 v5, 2, v109
	v_xor_b32_e32 v68, v68, v2
	v_lshlrev_b32_e32 v2, 7, v114
	v_lshlrev_b32_e32 v4, 6, v3
	v_bitop3_b32 v5, s15, v5, 48 bitop3:0x78
	v_and_b32_e32 v6, 8, v0
	v_or3_b32 v2, v2, v4, v5
	v_or_b32_e32 v74, v2, v6
	v_bitop3_b32 v75, v2, 64, v6 bitop3:0x36
	v_lshlrev_b32_e32 v2, 7, v3
	v_lshl_or_b32 v2, v114, 8, v2
	s_movk_i32 s7, 0x50
	v_bitop3_b32 v82, v2, s6, v119 bitop3:0x36
	s_movk_i32 s6, 0x70
	v_xor_b32_e32 v70, 64, v69
	v_xor_b32_e32 v71, 0x80, v69
	v_xor_b32_e32 v72, 0xc0, v69
	v_xor_b32_e32 v73, 0x110, v68
	v_or_b32_e32 v76, v2, v119
	v_bitop3_b32 v77, v2, 16, v119 bitop3:0x36
	v_bitop3_b32 v78, v2, 32, v119 bitop3:0x36
	v_bitop3_b32 v79, v2, 48, v119 bitop3:0x36
	v_bitop3_b32 v80, v2, 64, v119 bitop3:0x36
	v_bitop3_b32 v81, v2, s7, v119 bitop3:0x36
	v_bitop3_b32 v83, v2, s6, v119 bitop3:0x36
	v_mov_b32_e32 v108, v84
	.loc	1 574 39                        ; extend_attention.py:574:39
	s_mov_b32 s94, s22
	s_and_b32 s85, s85, 0xffff
	.loc	1 584 59                        ; extend_attention.py:584:59
	s_mov_b32 s82, s83
	.loc	1 494 48                        ; extend_attention.py:494:48
	s_lshl_b32 s95, s16, 3
	v_lshlrev_b32_e32 v97, 3, v252
	v_mov_b32_e32 v142, 0xff800000
	v_mov_b32_e32 v141, 0
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v63, 0
	v_add_u32_e32 v116, 0, v69
	v_add_u32_e32 v117, 0, v70
	v_add_u32_e32 v118, 0, v71
	v_add_u32_e32 v125, 0, v72
	s_mov_b32 s98, 0xc2fc0000
	v_add_u32_e32 v126, 0, v68
	v_add_u32_e32 v127, 0, v73
	v_add_u32_e32 v128, 0, v74
	v_add_u32_e32 v129, 0, v75
	v_add_u32_e32 v130, 0, v76
	v_add_u32_e32 v131, 0, v77
	v_add_u32_e32 v132, 0, v78
	v_add_u32_e32 v133, 0, v79
	v_add_u32_e32 v134, 0, v80
	v_add_u32_e32 v135, 0, v81
	v_add_u32_e32 v136, 0, v82
	v_add_u32_e32 v137, 0, v83
	v_mov_b32_e32 v138, 0xff800000
	v_mov_b32_e32 v139, 0x42800000
	v_not_b32_e32 v140, 63
	s_branch .LBB0_3
.LBB0_2:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 28 is_stmt 0                ; extend_attention.py:0:28
	s_or_b64 exec, exec, s[6:7]
	.loc	1 583 21 is_stmt 1              ; extend_attention.py:583:21
	v_cvt_scalef32_pk_fp8_f32 v84, v92, v93, 1.0
	v_cvt_scalef32_pk_fp8_f32 v84, v94, v95, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v85, v144, v145, 1.0
	v_cvt_scalef32_pk_fp8_f32 v85, v146, v147, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v86, v148, v149, 1.0
	v_lshrrev_b32_e32 v92, 8, v84
	v_cvt_scalef32_pk_fp8_f32 v86, v150, v151, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v87, v152, v153, 1.0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b8 v126, v92 offset:128
	ds_write_b8 v126, v85 offset:2048
	v_lshrrev_b32_e32 v92, 8, v85
	v_cvt_scalef32_pk_fp8_f32 v87, v154, v155, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v88, v156, v157, 1.0
	ds_write_b8 v126, v92 offset:2176
	ds_write_b8 v126, v86 offset:4096
	v_lshrrev_b32_e32 v92, 8, v86
	v_cvt_scalef32_pk_fp8_f32 v88, v158, v159, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v89, v160, v161, 1.0
	ds_write_b8 v126, v92 offset:4224
	ds_write_b8 v126, v87 offset:6144
	v_lshrrev_b32_e32 v92, 8, v87
	v_cvt_scalef32_pk_fp8_f32 v89, v162, v163, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v90, v164, v165, 1.0
	ds_write_b8 v126, v92 offset:6272
	ds_write_b8 v126, v88 offset:8192
	v_lshrrev_b32_e32 v92, 8, v88
	v_cvt_scalef32_pk_fp8_f32 v90, v166, v167, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v91, v168, v169, 1.0
	ds_write_b8 v126, v92 offset:8320
	ds_write_b8 v126, v89 offset:10240
	v_lshrrev_b32_e32 v92, 8, v89
	v_cvt_scalef32_pk_fp8_f32 v91, v170, v171, 1.0 op_sel:[0,0,0,1]
	ds_write_b8 v126, v92 offset:10368
	ds_write_b8 v126, v90 offset:12288
	v_lshrrev_b32_e32 v92, 8, v90
	ds_write_b8 v126, v92 offset:12416
	ds_write_b8 v126, v91 offset:14336
	v_lshrrev_b32_e32 v92, 8, v91
	ds_write_b8 v126, v84
	ds_write_b8 v126, v92 offset:14464
	ds_write_b8_d16_hi v127, v84
	v_lshrrev_b32_e32 v84, 24, v84
	ds_write_b8 v127, v84 offset:128
	ds_write_b8_d16_hi v127, v85 offset:2048
	v_lshrrev_b32_e32 v84, 24, v85
	ds_write_b8 v127, v84 offset:2176
	ds_write_b8_d16_hi v127, v86 offset:4096
	v_lshrrev_b32_e32 v84, 24, v86
	ds_write_b8 v127, v84 offset:4224
	ds_write_b8_d16_hi v127, v87 offset:6144
	v_lshrrev_b32_e32 v84, 24, v87
	ds_write_b8 v127, v84 offset:6272
	ds_write_b8_d16_hi v127, v88 offset:8192
	v_lshrrev_b32_e32 v84, 24, v88
	ds_write_b8 v127, v84 offset:8320
	ds_write_b8_d16_hi v127, v89 offset:10240
	v_lshrrev_b32_e32 v84, 24, v89
	ds_write_b8 v127, v84 offset:10368
	ds_write_b8_d16_hi v127, v90 offset:12288
	v_lshrrev_b32_e32 v84, 24, v90
	ds_write_b8 v127, v84 offset:12416
	ds_write_b8_d16_hi v127, v91 offset:14336
	v_lshrrev_b32_e32 v84, 24, v91
	ds_write_b8 v127, v84 offset:14464
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b8 v[144:145], v128
	ds_read_b64_tr_b8 v[148:149], v128 offset:8192
	ds_read_b64_tr_b8 v[146:147], v129 offset:1024
	ds_read_b64_tr_b8 v[150:151], v129 offset:9216
	.loc	1 579 16                        ; extend_attention.py:579:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write_b128 v113, v[68:71]
	ds_write_b128 v113, v[76:79] offset:8192
	ds_write_b128 v113, v[72:75] offset:16384
	ds_write_b128 v113, v[80:83] offset:24576
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b8 v[72:73], v130 offset:16384
	ds_read_b64_tr_b8 v[74:75], v130 offset:18560
	ds_read_b64_tr_b8 v[68:69], v130
	ds_read_b64_tr_b8 v[70:71], v130 offset:2176
	ds_read_b64_tr_b8 v[76:77], v131 offset:16384
	ds_read_b64_tr_b8 v[78:79], v131 offset:18560
	.loc	1 584 54                        ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[68:75], v[144:151], 0
	.loc	1 579 16                        ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[72:73], v131
	ds_read_b64_tr_b8 v[74:75], v131 offset:2176
	ds_read_b64_tr_b8 v[80:81], v132 offset:16384
	ds_read_b64_tr_b8 v[82:83], v132 offset:18560
	ds_read_b64_tr_b8 v[160:161], v136
	ds_read_b64_tr_b8 v[162:163], v136 offset:2176
	ds_read_b64_tr_b8 v[156:157], v137 offset:16384
	ds_read_b64_tr_b8 v[158:159], v137 offset:18560
	ds_read_b64_tr_b8 v[234:235], v134 offset:18432
	ds_read_b64_tr_b8 v[236:237], v135 offset:128
	ds_read_b64_tr_b8 v[238:239], v135 offset:2048
	ds_read_b64_tr_b8 v[240:241], v135 offset:16512
	.loc	1 569 38                        ; extend_attention.py:569:38
	v_sub_f32_e32 v142, v142, v124
	.loc	1 579 16                        ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[242:243], v135 offset:18432
	ds_read_b64_tr_b8 v[244:245], v136 offset:128
	ds_read_b64_tr_b8 v[246:247], v136 offset:2048
	ds_read_b64_tr_b8 v[248:249], v136 offset:16512
	ds_read_b64_tr_b8 v[250:251], v136 offset:18432
	ds_read_b64_tr_b8 v[188:189], v137 offset:128
	ds_read_b64_tr_b8 v[190:191], v137 offset:2048
	ds_read_b64_tr_b8 v[192:193], v137 offset:16512
	ds_read_b64_tr_b8 v[194:195], v137 offset:18432
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:571:47 ] ]
	v_add_f32_e32 v123, v123, v143
.Ltmp3:
	.loc	1 584 54                        ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x128_f8f6f4 v[72:75], v[72:79], v[144:151], 0
	.loc	1 579 16                        ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[76:77], v132
	ds_read_b64_tr_b8 v[78:79], v132 offset:2176
	ds_read_b64_tr_b8 v[84:85], v133 offset:16384
	ds_read_b64_tr_b8 v[86:87], v133 offset:18560
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v68, s82, v68
	v_mul_f32_e64 v69, s83, v69
	v_pk_mul_f32 v[70:71], s[82:83], v[70:71]
	.loc	1 494 48                        ; extend_attention.py:494:48
	s_addk_i32 s89, 0x80
	v_add_u32_e32 v97, 0x400, v97
	s_cmp_lt_i32 s89, s90
	.loc	1 584 59                        ; extend_attention.py:584:59
	s_nop 1
	v_pk_mul_f32 v[72:73], s[82:83], v[72:73]
	.loc	1 584 54 is_stmt 0              ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[76:79], v[76:83], v[144:151], 0
	.loc	1 579 16 is_stmt 1              ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[80:81], v133
	ds_read_b64_tr_b8 v[82:83], v133 offset:2176
	ds_read_b64_tr_b8 v[88:89], v134 offset:16384
	ds_read_b64_tr_b8 v[90:91], v134 offset:18560
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v74, s82, v74
	v_mul_f32_e64 v75, s83, v75
	s_nop 5
	v_pk_mul_f32 v[76:77], s[82:83], v[76:77]
	.loc	1 584 54 is_stmt 0              ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[80:83], v[80:87], v[144:151], 0
	.loc	1 579 16 is_stmt 1              ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[84:85], v134
	ds_read_b64_tr_b8 v[86:87], v134 offset:2176
	ds_read_b64_tr_b8 v[92:93], v135 offset:16384
	ds_read_b64_tr_b8 v[94:95], v135 offset:18560
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v78, s82, v78
	v_mul_f32_e64 v79, s83, v79
	s_nop 5
	v_pk_mul_f32 v[80:81], s[82:83], v[80:81]
	.loc	1 584 54 is_stmt 0              ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[84:87], v[84:91], v[144:151], 0
	.loc	1 579 16 is_stmt 1              ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[88:89], v135
	ds_read_b64_tr_b8 v[90:91], v135 offset:2176
	ds_read_b64_tr_b8 v[164:165], v136 offset:16384
	ds_read_b64_tr_b8 v[166:167], v136 offset:18560
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v82, s82, v82
	v_mul_f32_e64 v83, s83, v83
	s_nop 5
	v_pk_mul_f32 v[84:85], s[82:83], v[84:85]
	.loc	1 584 54 is_stmt 0              ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[88:91], v[88:95], v[144:151], 0
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v86, s82, v86
	v_mul_f32_e64 v87, s83, v87
	.loc	1 584 54                        ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[92:95], v[160:167], v[144:151], 0
	.loc	1 579 16 is_stmt 1              ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[152:153], v137
	ds_read_b64_tr_b8 v[154:155], v137 offset:2176
	ds_read_b64_tr_b8 v[160:161], v130 offset:128
	ds_read_b64_tr_b8 v[162:163], v130 offset:2048
	ds_read_b64_tr_b8 v[164:165], v130 offset:16512
	ds_read_b64_tr_b8 v[166:167], v130 offset:18432
	ds_read_b64_tr_b8 v[220:221], v131 offset:128
	ds_read_b64_tr_b8 v[222:223], v131 offset:2048
	ds_read_b64_tr_b8 v[224:225], v131 offset:16512
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_pk_mul_f32 v[88:89], s[82:83], v[88:89]
	v_pk_mul_f32 v[90:91], s[82:83], v[90:91]
	s_nop 0
	v_pk_mul_f32 v[92:93], s[82:83], v[92:93]
	.loc	1 584 54 is_stmt 0              ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x128_f8f6f4 v[152:155], v[152:159], v[144:151], 0
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v94, s82, v94
	v_mul_f32_e64 v95, s83, v95
	.loc	1 584 54                        ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[156:159], v[160:167], v[144:151], 0
	.loc	1 579 16 is_stmt 1              ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[226:227], v131 offset:18432
	ds_read_b64_tr_b8 v[164:165], v132 offset:128
	ds_read_b64_tr_b8 v[166:167], v132 offset:2048
	ds_read_b64_tr_b8 v[168:169], v132 offset:16512
	.loc	1 584 54                        ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[160:163], v[220:227], v[144:151], 0
	.loc	1 579 16                        ; extend_attention.py:579:16
	ds_read_b64_tr_b8 v[170:171], v132 offset:18432
	ds_read_b64_tr_b8 v[220:221], v133 offset:128
	ds_read_b64_tr_b8 v[222:223], v133 offset:2048
	ds_read_b64_tr_b8 v[224:225], v133 offset:16512
	ds_read_b64_tr_b8 v[226:227], v133 offset:18432
	ds_read_b64_tr_b8 v[228:229], v134 offset:128
	ds_read_b64_tr_b8 v[230:231], v134 offset:2048
	ds_read_b64_tr_b8 v[232:233], v134 offset:16512
	.loc	1 584 54                        ; extend_attention.py:584:54
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x128_f8f6f4 v[164:167], v[164:171], v[144:151], 0
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[168:171], v[220:227], v[144:151], 0
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[220:223], v[228:235], v[144:151], 0
	.loc	1 569 30                        ; extend_attention.py:569:30
	v_mul_f32_e32 v228, 0x3fb8aa3b, v142
	v_cmp_gt_f32_e32 vcc, s98, v228
	s_nop 1
	v_cndmask_b32_e32 v232, 0, v139, vcc
	v_fmac_f32_e32 v232, 0x3fb8aa3b, v142
	v_exp_f32_e32 v142, v232
	v_cndmask_b32_e32 v232, 0, v140, vcc
	.loc	1 584 54                        ; extend_attention.py:584:54
	v_mfma_f32_16x16x128_f8f6f4 v[224:227], v[236:243], v[144:151], 0
	.loc	1 569 30                        ; extend_attention.py:569:30
	v_ldexp_f32 v232, v142, v232
	.loc	1 571 37                        ; extend_attention.py:571:37
	v_fmac_f32_e32 v123, v141, v232
	.loc	1 584 44                        ; extend_attention.py:584:44
	v_fma_f32 v62, v62, v232, v68
	v_fma_f32 v63, v63, v232, v69
	v_fma_f32 v64, v64, v232, v70
	v_fma_f32 v65, v65, v232, v71
	v_pk_fma_f32 v[54:55], v[54:55], v[232:233], v[72:73] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[56:57], v[56:57], v[232:233], v[74:75] op_sel_hi:[1,0,1]
	.loc	1 584 54 is_stmt 0              ; extend_attention.py:584:54
	v_mfma_f32_16x16x128_f8f6f4 v[228:231], v[244:251], v[144:151], 0
	.loc	1 584 44                        ; extend_attention.py:584:44
	v_fma_f32 v58, v58, v232, v76
	v_fma_f32 v59, v59, v232, v77
	v_fma_f32 v60, v60, v232, v78
	v_fma_f32 v61, v61, v232, v79
	v_fma_f32 v50, v50, v232, v80
	v_fma_f32 v51, v51, v232, v81
	v_pk_fma_f32 v[52:53], v[52:53], v[232:233], v[82:83] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[46:47], v[46:47], v[232:233], v[84:85] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[48:49], v[48:49], v[232:233], v[86:87] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[42:43], v[42:43], v[232:233], v[88:89] op_sel_hi:[1,0,1]
	.loc	1 584 54                        ; extend_attention.py:584:54
	v_mfma_f32_16x16x128_f8f6f4 v[142:145], v[188:195], v[144:151], 0
	.loc	1 584 59                        ; extend_attention.py:584:59
	v_mul_f32_e64 v146, s82, v152
	v_mul_f32_e64 v147, s83, v153
	v_mul_f32_e64 v148, s82, v154
	v_mul_f32_e64 v149, s83, v155
	v_mul_f32_e64 v150, s82, v156
	v_mul_f32_e64 v151, s83, v157
	v_pk_mul_f32 v[152:153], s[82:83], v[158:159]
	v_pk_mul_f32 v[154:155], s[82:83], v[160:161]
	v_pk_mul_f32 v[156:157], s[82:83], v[162:163]
	v_pk_mul_f32 v[158:159], s[82:83], v[164:165]
	v_pk_mul_f32 v[160:161], s[82:83], v[166:167]
	v_pk_mul_f32 v[162:163], s[82:83], v[168:169]
	v_pk_mul_f32 v[164:165], s[82:83], v[170:171]
	v_pk_mul_f32 v[166:167], s[82:83], v[220:221]
	v_pk_mul_f32 v[168:169], s[82:83], v[222:223]
	v_pk_mul_f32 v[170:171], s[82:83], v[224:225]
	v_pk_mul_f32 v[220:221], s[82:83], v[226:227]
	v_pk_mul_f32 v[222:223], s[82:83], v[228:229]
	v_pk_mul_f32 v[224:225], s[82:83], v[230:231]
	v_pk_mul_f32 v[142:143], s[82:83], v[142:143]
	v_pk_mul_f32 v[144:145], s[82:83], v[144:145]
	.loc	1 584 44                        ; extend_attention.py:584:44
	v_pk_fma_f32 v[44:45], v[44:45], v[232:233], v[90:91] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[38:39], v[38:39], v[232:233], v[92:93] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[40:41], v[40:41], v[232:233], v[94:95] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[34:35], v[34:35], v[232:233], v[146:147] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[36:37], v[36:37], v[232:233], v[148:149] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[30:31], v[30:31], v[232:233], v[150:151] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[32:33], v[32:33], v[232:233], v[152:153] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[26:27], v[26:27], v[232:233], v[154:155] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[28:29], v[232:233], v[156:157] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[22:23], v[232:233], v[158:159] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[24:25], v[24:25], v[232:233], v[160:161] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[18:19], v[18:19], v[232:233], v[162:163] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[20:21], v[20:21], v[232:233], v[164:165] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[14:15], v[14:15], v[232:233], v[166:167] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[16:17], v[232:233], v[168:169] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[10:11], v[232:233], v[170:171] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[12:13], v[12:13], v[232:233], v[220:221] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[6:7], v[232:233], v[222:223] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[8:9], v[232:233], v[224:225] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[2:3], v[232:233], v[142:143] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[232:233], v[144:145] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v142, v124
	v_mov_b32_e32 v141, v123
	.loc	1 494 48 is_stmt 1              ; extend_attention.py:494:48
	s_cbranch_scc0 .LBB0_19
.LBB0_3:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v68, s89, v252
	v_add_u32_e32 v69, 32, v68
	.loc	1 526 16                        ; extend_attention.py:526:16
	v_add_u32_e32 v72, s95, v97
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v70, 64, v68
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_add_u32_e32 v71, 0x60, v68
	v_cmp_gt_i32_e64 s[12:13], s90, v68
	.loc	1 526 16 is_stmt 1              ; extend_attention.py:526:16
	v_add_u32_e32 v73, 0x100, v72
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[10:11], s90, v69
	.loc	1 526 16                        ; extend_attention.py:526:16
	v_cndmask_b32_e64 v68, v105, v72, s[12:13]
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[6:7], s90, v70
	.loc	1 526 16                        ; extend_attention.py:526:16
	v_cndmask_b32_e64 v69, v105, v73, s[10:11]
	v_add_u32_e32 v73, 0x200, v72
	v_add_u32_e32 v72, 0x300, v72
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e32 vcc, s90, v71
	.loc	1 526 16                        ; extend_attention.py:526:16
	v_cndmask_b32_e64 v70, v105, v73, s[6:7]
	s_nop 0
	v_cndmask_b32_e32 v71, v105, v72, vcc
	buffer_load_dwordx2 v[90:91], v68, s[84:87], 0 offen
	buffer_load_dwordx2 v[88:89], v69, s[84:87], 0 offen
	buffer_load_dwordx2 v[86:87], v70, s[84:87], 0 offen
	buffer_load_dwordx2 v[84:85], v71, s[84:87], 0 offen
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
	.loc	1 538 16                        ; extend_attention.py:538:16
	s_and_saveexec_b64 s[14:15], s[12:13]
	s_cbranch_execz .LBB0_5
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 538 27 is_stmt 0              ; extend_attention.py:538:27
	s_waitcnt vmcnt(3)
	v_mad_u64_u32 v[68:69], s[16:17], v90, s92, v[98:99]
	v_mul_lo_u32 v70, v90, s91
	v_mul_lo_u32 v71, v91, s92
	v_add3_u32 v69, v71, v69, v70
	.loc	1 538 16                        ; extend_attention.py:538:16
	global_load_dwordx4 v[68:71], v[68:69], off
.LBB0_5:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[14:15]
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, v72
	.loc	1 538 16                        ; extend_attention.py:538:16
	s_and_saveexec_b64 s[14:15], s[10:11]
	s_cbranch_execz .LBB0_7
; %bb.6:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 538 27                        ; extend_attention.py:538:27
	s_waitcnt vmcnt(2)
	v_mad_u64_u32 v[74:75], s[16:17], v88, s92, v[98:99]
	v_mul_lo_u32 v73, v88, s91
	v_mul_lo_u32 v76, v89, s92
	v_add3_u32 v75, v76, v75, v73
	.loc	1 538 16                        ; extend_attention.py:538:16
	global_load_dwordx4 v[76:79], v[74:75], off
.LBB0_7:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[14:15]
	v_mov_b32_e32 v73, v72
	v_mov_b32_e32 v74, v72
	v_mov_b32_e32 v75, v72
	.loc	1 538 16                        ; extend_attention.py:538:16
	s_and_saveexec_b64 s[14:15], s[6:7]
	s_cbranch_execz .LBB0_9
; %bb.8:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 538 27                        ; extend_attention.py:538:27
	s_waitcnt vmcnt(1)
	v_mad_u64_u32 v[72:73], s[16:17], v86, s92, v[98:99]
	v_mul_lo_u32 v74, v86, s91
	v_mul_lo_u32 v75, v87, s92
	v_add3_u32 v73, v75, v73, v74
	.loc	1 538 16                        ; extend_attention.py:538:16
	global_load_dwordx4 v[72:75], v[72:73], off
.LBB0_9:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[14:15]
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	.loc	1 538 16                        ; extend_attention.py:538:16
	s_and_saveexec_b64 s[14:15], vcc
	s_cbranch_execz .LBB0_11
; %bb.10:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 538 27                        ; extend_attention.py:538:27
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[80:81], s[16:17], v84, s92, v[98:99]
	v_mul_lo_u32 v82, v84, s91
	v_mul_lo_u32 v83, v85, s92
	v_add3_u32 v81, v83, v81, v82
	.loc	1 538 16                        ; extend_attention.py:538:16
	global_load_dwordx4 v[80:83], v[80:81], off
.LBB0_11:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[14:15]
	.loc	1 538 16                        ; extend_attention.py:538:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write_b128 v113, v[68:71]
	ds_write_b128 v113, v[76:79] offset:8192
	ds_write_b128 v113, v[72:75] offset:16384
	ds_write_b128 v113, v[80:83] offset:24576
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[72:75], v117
	ds_read_b128 v[68:71], v116
	ds_read_b128 v[76:79], v116 offset:4096
	ds_read_b128 v[80:83], v117 offset:4096
	ds_read_b128 v[148:151], v125
	.loc	1 542 39 is_stmt 1              ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[68:75], v[180:187], 0
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[144:147], v118
	ds_read_b128 v[152:155], v118 offset:4096
	ds_read_b128 v[156:159], v125 offset:4096
	ds_read_b128 v[228:231], v118 offset:12288
	ds_read_b128 v[232:235], v125 offset:12288
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v123, s89, v108
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[236:239], v116 offset:16384
	ds_read_b128 v[240:243], v117 offset:16384
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v124, 1, v123
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[14:15], s90, v123
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v143, 2, v123
	.loc	1 542 39 is_stmt 1              ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x128_f8f6f4 v[72:75], v[76:83], v[180:187], 0
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[76:79], v116 offset:8192
	ds_read_b128 v[80:83], v117 offset:8192
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v166, 0x61, v123
	v_add_u32_e32 v167, 0x62, v123
	v_add_u32_e32 v168, 0x63, v123
	v_add_u32_e32 v169, 0x70, v123
	v_add_u32_e32 v170, 0x71, v123
	v_add_u32_e32 v171, 0x72, v123
	.loc	1 542 39                        ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x128_f8f6f4 v[72:75], v[152:159], v[172:179], v[72:75]
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[220:223], v116 offset:12288
	ds_read_b128 v[224:227], v117 offset:12288
	ds_read_b128 v[158:161], v118 offset:8192
	ds_read_b128 v[162:165], v125 offset:8192
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v152, 35, v123
	v_add_u32_e32 v153, 48, v123
	v_add_u32_e32 v154, 49, v123
	v_add_u32_e32 v155, 50, v123
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[38:39], s90, v152
	v_cmp_gt_i32_e64 s[40:41], s90, v153
	.loc	1 542 39 is_stmt 1              ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x128_f8f6f4 v[76:79], v[76:83], v[180:187], 0
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[42:43], s90, v154
	v_cmp_gt_i32_e64 s[44:45], s90, v155
	.loc	1 496 28 is_stmt 0              ; extend_attention.py:496:28
	v_add_u32_e32 v156, 51, v123
	v_add_u32_e32 v157, 64, v123
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[16:17], s90, v124
	.loc	1 498 39 is_stmt 1              ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[14:15]
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[18:19], s90, v143
	.loc	1 542 39                        ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[80:83], v[220:227], v[180:187], 0
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v220, 0x73, v123
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[46:47], s90, v156
	.loc	1 555 18 is_stmt 1              ; extend_attention.py:555:18
	v_mul_f32_e32 v72, v115, v72
	v_mul_f32_e32 v73, v115, v73
	v_mul_f32_e32 v74, v115, v74
	v_mul_f32_e32 v75, v115, v75
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[48:49], s90, v157
	.loc	1 542 39                        ; extend_attention.py:542:39
	v_mfma_f32_16x16x128_f8f6f4 v[80:83], v[228:235], v[172:179], v[80:83]
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[222:225], v116 offset:20480
	ds_read_b128 v[226:229], v117 offset:20480
	ds_read_b128 v[244:247], v118 offset:16384
	ds_read_b128 v[248:251], v125 offset:16384
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[66:67], s90, v166
	v_cmp_gt_i32_e64 s[68:69], s90, v167
	v_cmp_gt_i32_e64 s[70:71], s90, v168
	v_cmp_gt_i32_e64 s[72:73], s90, v169
	v_cmp_gt_i32_e64 s[74:75], s90, v170
	v_cmp_gt_i32_e64 s[76:77], s90, v171
	.loc	1 542 39                        ; extend_attention.py:542:39
	v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[144:151], v[172:179], v[68:71]
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v144, 3, v123
	v_add_u32_e32 v145, 16, v123
	v_add_u32_e32 v146, 17, v123
	v_add_u32_e32 v147, 18, v123
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[20:21], s90, v144
	v_cmp_gt_i32_e64 s[22:23], s90, v145
	v_cmp_gt_i32_e64 s[24:25], s90, v146
	v_cmp_gt_i32_e64 s[26:27], s90, v147
	.loc	1 542 39 is_stmt 1              ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[144:147], v[222:229], v[180:187], 0
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v148, 19, v123
	v_add_u32_e32 v149, 32, v123
	v_add_u32_e32 v150, 33, v123
	v_add_u32_e32 v151, 34, v123
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[28:29], s90, v148
	v_cmp_gt_i32_e64 s[30:31], s90, v149
	v_cmp_gt_i32_e64 s[34:35], s90, v150
	.loc	1 542 39 is_stmt 1              ; extend_attention.py:542:39
	v_mfma_f32_16x16x128_f8f6f4 v[92:95], v[236:243], v[180:187], 0
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[230:233], v118 offset:20480
	ds_read_b128 v[234:237], v125 offset:20480
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[36:37], s90, v151
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[148:151], v116 offset:24576
	ds_read_b128 v[152:155], v117 offset:24576
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v124, v115, v69
	v_mul_f32_e32 v143, v115, v70
	v_mul_f32_e32 v156, v115, v71
	v_mul_f32_e32 v80, v115, v80
	.loc	1 542 39                        ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[144:147], v[230:237], v[172:179], v[144:147]
	.loc	1 538 16                        ; extend_attention.py:538:16
	ds_read_b128 v[222:225], v116 offset:28672
	ds_read_b128 v[226:229], v117 offset:28672
	ds_read_b128 v[230:233], v118 offset:24576
	ds_read_b128 v[234:237], v125 offset:24576
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v81, v115, v81
	v_mul_f32_e32 v82, v115, v82
	v_mul_f32_e32 v83, v115, v83
	.loc	1 496 38                        ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[78:79], s90, v220
	.loc	1 555 18                        ; extend_attention.py:555:18
	s_nop 3
	v_mul_f32_e32 v144, v115, v144
	.loc	1 542 39                        ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x128_f8f6f4 v[148:151], v[148:155], v[180:187], 0
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v145, v115, v145
	v_mul_f32_e32 v146, v115, v146
	v_mul_f32_e32 v147, v115, v147
	.loc	1 542 39                        ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[152:155], v[222:229], v[180:187], 0
	v_mfma_f32_16x16x128_f8f6f4 v[76:79], v[158:165], v[172:179], v[76:79]
	.loc	1 496 28                        ; extend_attention.py:496:28
	v_add_u32_e32 v158, 0x41, v123
	v_add_u32_e32 v159, 0x42, v123
	v_add_u32_e32 v160, 0x43, v123
	v_add_u32_e32 v161, 0x50, v123
	v_add_u32_e32 v162, 0x51, v123
	v_add_u32_e32 v163, 0x52, v123
	v_add_u32_e32 v164, 0x53, v123
	v_add_u32_e32 v165, 0x60, v123
	.loc	1 496 38 is_stmt 0              ; extend_attention.py:496:38
	v_cmp_gt_i32_e64 s[50:51], s90, v158
	v_cmp_gt_i32_e64 s[52:53], s90, v159
	v_cmp_gt_i32_e64 s[54:55], s90, v160
	v_cmp_gt_i32_e64 s[56:57], s90, v161
	v_cmp_gt_i32_e64 s[58:59], s90, v162
	v_cmp_gt_i32_e64 s[60:61], s90, v163
	v_cmp_gt_i32_e64 s[62:63], s90, v164
	v_cmp_gt_i32_e64 s[64:65], s90, v165
	.loc	1 538 16 is_stmt 1              ; extend_attention.py:538:16
	ds_read_b128 v[158:161], v118 offset:28672
	ds_read_b128 v[162:165], v125 offset:28672
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v123, v115, v68
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v123, v138, v123, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[16:17]
	.loc	1 542 39                        ; extend_attention.py:542:39
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[158:165], v[172:179], v[152:155]
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v76, v115, v76
	v_mul_f32_e32 v77, v115, v77
	v_mul_f32_e32 v78, v115, v78
	v_mul_f32_e32 v79, v115, v79
	.loc	1 563 42                        ; extend_attention.py:563:42
	s_nop 2
	v_cndmask_b32_e64 v152, v138, v124, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[18:19]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v143, v138, v143, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[20:21]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v153, v138, v156, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[22:23]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v72, v138, v72, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[24:25]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v73, v138, v73, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[26:27]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v74, v138, v74, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[28:29]
	.loc	1 542 39                        ; extend_attention.py:542:39
	v_mfma_f32_16x16x128_f8f6f4 v[92:95], v[244:251], v[172:179], v[92:95]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v75, v138, v75, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[30:31]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v76, v138, v76, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[34:35]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v77, v138, v77, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[36:37]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v78, v138, v78, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[38:39]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v79, v138, v79, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[40:41]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v80, v138, v80, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[42:43]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v81, v138, v81, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[44:45]
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v82, v138, v82, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[46:47]
	.loc	1 542 39                        ; extend_attention.py:542:39
	v_mfma_f32_16x16x128_f8f6f4 v[148:151], v[230:237], v[172:179], v[148:151]
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v92, v115, v92
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v83, v138, v83, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[48:49]
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v93, v115, v93
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v92, v138, v92, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[50:51]
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v94, v115, v94
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v93, v138, v93, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[52:53]
.Ltmp4:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max_f32_e32 v124, v123, v152
.Ltmp5:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v95, v115, v95
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v94, v138, v94, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[54:55]
.Ltmp6:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v143, v153
.Ltmp7:
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v95, v138, v95, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[56:57]
.Ltmp8:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v72, v73
.Ltmp9:
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v144, v138, v144, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[58:59]
.Ltmp10:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v74, v75
.Ltmp11:
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v145, v138, v145, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[60:61]
.Ltmp12:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v76, v77
.Ltmp13:
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v146, v138, v146, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[62:63]
.Ltmp14:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v78, v79
.Ltmp15:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v148, v115, v148
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v147, v138, v147, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[64:65]
.Ltmp16:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v80, v81
.Ltmp17:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v149, v115, v149
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v148, v138, v148, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[66:67]
.Ltmp18:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v82, v83
.Ltmp19:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v150, v115, v150
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v149, v138, v149, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[68:69]
.Ltmp20:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v92, v93
.Ltmp21:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v151, v115, v151
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v150, v138, v150, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[70:71]
.Ltmp22:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v94, v95
.Ltmp23:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v68, v115, v68
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v151, v138, v151, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[72:73]
.Ltmp24:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v144, v145
.Ltmp25:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v69, v115, v69
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v68, v138, v68, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[74:75]
.Ltmp26:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v146, v147
.Ltmp27:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v70, v115, v70
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v69, v138, v69, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[76:77]
.Ltmp28:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v148, v149
.Ltmp29:
	.loc	1 555 18                        ; extend_attention.py:555:18
	v_mul_f32_e32 v71, v115, v71
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v70, v138, v70, s[14:15]
	.loc	1 498 39                        ; extend_attention.py:498:39
	s_and_b64 s[14:15], s[2:3], s[78:79]
.Ltmp30:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v150, v151
.Ltmp31:
	.loc	1 563 42                        ; extend_attention.py:563:42
	v_cndmask_b32_e64 v71, v138, v71, s[14:15]
.Ltmp32:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max3_f32 v124, v124, v68, v69
	v_max3_f32 v124, v124, v70, v71
.Ltmp33:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:565:33 ]
	v_mov_b32_e32 v154, v124
	s_nop 1
	v_permlane32_swap_b32_e32 v124, v154
.Ltmp34:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max_f32_e32 v154, v154, v154
	v_max_f32_e32 v124, v124, v124
	v_max_f32_e32 v124, v124, v154
.Ltmp35:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:565:33 ]
	v_mov_b32_e32 v154, v124
	s_nop 1
	v_permlane16_swap_b32_e32 v124, v154
.Ltmp36:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:565:33 ] ]
	v_max_f32_e32 v154, v154, v154
	v_max_f32_e32 v124, v124, v124
	v_max_f32_e32 v124, v124, v154
	s_mov_b32 s14, 0xff800000
.Ltmp37:
	.loc	1 566 70                        ; extend_attention.py:566:70
	v_cmp_neq_f32_e64 s[14:15], s14, v124
	v_mov_b32_e32 v154, 0xe0ad78ec
	s_nop 0
	v_cndmask_b32_e64 v124, v154, v124, s[14:15]
	.loc	1 567 48                        ; extend_attention.py:567:48
	v_max_f32_e32 v154, v142, v142
	v_max_f32_e32 v124, v124, v154
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v123, v123, v124
	v_sub_f32_e32 v152, v152, v124
	v_sub_f32_e32 v156, v92, v124
	.loc	1 570 23 is_stmt 0              ; extend_attention.py:570:23
	v_mul_f32_e32 v92, 0x3fb8aa3b, v123
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v157, v93, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_cmp_gt_f32_e64 s[14:15], s98, v92
	v_mul_f32_e32 v93, 0x3fb8aa3b, v152
	v_cmp_gt_f32_e64 s[16:17], s98, v93
	v_cndmask_b32_e64 v92, 0, v139, s[14:15]
	v_fmac_f32_e32 v92, 0x3fb8aa3b, v123
	v_cndmask_b32_e64 v93, 0, v139, s[16:17]
	v_exp_f32_e32 v92, v92
	v_fmac_f32_e32 v93, 0x3fb8aa3b, v152
	v_exp_f32_e32 v93, v93
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v158, v94, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_cndmask_b32_e64 v94, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v143, v143, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v92, v92, v94
	v_cndmask_b32_e64 v94, 0, v140, s[16:17]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v153, v153, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v93, v93, v94
	v_mul_f32_e32 v94, 0x3fb8aa3b, v143
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v159, v95, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_cmp_gt_f32_e64 s[14:15], s98, v94
	v_mul_f32_e32 v95, 0x3fb8aa3b, v153
	v_cmp_gt_f32_e64 s[16:17], s98, v95
	v_cndmask_b32_e64 v94, 0, v139, s[14:15]
	v_fmac_f32_e32 v94, 0x3fb8aa3b, v143
	v_cndmask_b32_e64 v95, 0, v139, s[16:17]
	v_exp_f32_e32 v94, v94
	v_fmac_f32_e32 v95, 0x3fb8aa3b, v153
	v_exp_f32_e32 v95, v95
	v_cndmask_b32_e64 v123, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v72, v72, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v94, v94, v123
	v_cndmask_b32_e64 v123, 0, v140, s[16:17]
	v_ldexp_f32 v95, v95, v123
	v_mul_f32_e32 v123, 0x3fb8aa3b, v72
	v_cmp_gt_f32_e64 s[14:15], s98, v123
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v73, v73, v124
	v_sub_f32_e32 v74, v74, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_cndmask_b32_e64 v123, 0, v139, s[14:15]
	v_fmac_f32_e32 v123, 0x3fb8aa3b, v72
	v_exp_f32_e32 v72, v123
	v_mul_f32_e32 v123, 0x3fb8aa3b, v73
	v_cmp_gt_f32_e64 s[16:17], s98, v123
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v160, v144, v124
	v_sub_f32_e32 v75, v75, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_cndmask_b32_e64 v123, 0, v139, s[16:17]
	v_fmac_f32_e32 v123, 0x3fb8aa3b, v73
	v_exp_f32_e32 v73, v123
	v_cndmask_b32_e64 v123, 0, v140, s[14:15]
	v_ldexp_f32 v144, v72, v123
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v161, v145, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v145, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v74
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v75
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v74
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v75
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v76, v76, v124
	v_sub_f32_e32 v162, v146, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v146, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v77, v77, v124
	v_sub_f32_e32 v163, v147, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v147, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v76
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v77
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v76
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v77
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v78, v78, v124
	v_sub_f32_e32 v164, v148, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v148, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v79, v79, v124
	v_sub_f32_e32 v165, v149, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v149, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v78
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v79
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v78
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v79
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v80, v80, v124
	v_sub_f32_e32 v166, v150, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v150, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v81, v81, v124
	v_sub_f32_e32 v167, v151, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v151, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v80
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v81
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v80
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v81
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v82, v82, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v152, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v83, v83, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v153, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v82
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v83
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v82
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v83
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	v_ldexp_f32 v154, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v155, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v156
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v157
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v156
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v157
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	v_ldexp_f32 v156, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v157, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v158
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v159
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v158
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v159
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	v_ldexp_f32 v158, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v159, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v160
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v161
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v160
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v161
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	v_ldexp_f32 v160, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v161, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v162
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v163
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v162
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v163
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	v_ldexp_f32 v162, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v163, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v164
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v165
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v164
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v165
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	v_ldexp_f32 v164, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v165, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v166
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	v_mul_f32_e32 v73, 0x3fb8aa3b, v167
	v_cmp_gt_f32_e64 s[16:17], s98, v73
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v166
	v_cndmask_b32_e64 v73, 0, v139, s[16:17]
	v_exp_f32_e32 v72, v72
	v_fmac_f32_e32 v73, 0x3fb8aa3b, v167
	v_exp_f32_e32 v73, v73
	v_cndmask_b32_e64 v74, 0, v140, s[14:15]
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v68, v68, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_ldexp_f32 v166, v72, v74
	v_cndmask_b32_e64 v72, 0, v140, s[16:17]
	v_ldexp_f32 v167, v73, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v68
	v_cmp_gt_f32_e64 s[14:15], s98, v72
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v69, v69, v124
	v_sub_f32_e32 v70, v70, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	v_cndmask_b32_e64 v72, 0, v139, s[14:15]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v68
	v_exp_f32_e32 v68, v72
	v_mul_f32_e32 v72, 0x3fb8aa3b, v69
	v_cmp_gt_f32_e64 s[16:17], s98, v72
	.loc	1 570 28                        ; extend_attention.py:570:28
	v_sub_f32_e32 v71, v71, v124
	.loc	1 570 23                        ; extend_attention.py:570:23
	s_nop 0
	v_cndmask_b32_e64 v72, 0, v139, s[16:17]
	v_fmac_f32_e32 v72, 0x3fb8aa3b, v69
	v_exp_f32_e32 v69, v72
	v_cndmask_b32_e64 v72, 0, v140, s[14:15]
	v_ldexp_f32 v168, v68, v72
	v_cndmask_b32_e64 v68, 0, v140, s[16:17]
	v_ldexp_f32 v169, v69, v68
	v_mul_f32_e32 v68, 0x3fb8aa3b, v70
	v_cmp_gt_f32_e64 s[14:15], s98, v68
	v_mul_f32_e32 v69, 0x3fb8aa3b, v71
	v_cmp_gt_f32_e64 s[16:17], s98, v69
	v_cndmask_b32_e64 v68, 0, v139, s[14:15]
	v_fmac_f32_e32 v68, 0x3fb8aa3b, v70
	v_cndmask_b32_e64 v69, 0, v139, s[16:17]
	v_exp_f32_e32 v68, v68
	v_fmac_f32_e32 v69, 0x3fb8aa3b, v71
	v_exp_f32_e32 v69, v69
	v_cndmask_b32_e64 v70, 0, v140, s[14:15]
	v_ldexp_f32 v170, v68, v70
	v_cndmask_b32_e64 v68, 0, v140, s[16:17]
	v_ldexp_f32 v171, v69, v68
.Ltmp38:
	.loc	2 263 15 is_stmt 1              ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:571:47 ] ]
	v_add_f32_e32 v68, v92, v93
	v_add_f32_e32 v68, v94, v68
	v_add_f32_e32 v68, v95, v68
	v_add_f32_e32 v68, v144, v68
	v_add_f32_e32 v68, v145, v68
	v_add_f32_e32 v68, v146, v68
	v_add_f32_e32 v68, v147, v68
	v_add_f32_e32 v68, v148, v68
	v_add_f32_e32 v68, v149, v68
	v_add_f32_e32 v68, v150, v68
	v_add_f32_e32 v68, v151, v68
	v_add_f32_e32 v68, v152, v68
	v_add_f32_e32 v68, v153, v68
	v_add_f32_e32 v68, v154, v68
	v_add_f32_e32 v68, v155, v68
	v_add_f32_e32 v68, v156, v68
	v_add_f32_e32 v68, v157, v68
	v_add_f32_e32 v68, v158, v68
	v_add_f32_e32 v68, v159, v68
	v_add_f32_e32 v68, v160, v68
	v_add_f32_e32 v68, v161, v68
	v_add_f32_e32 v68, v162, v68
	v_add_f32_e32 v68, v163, v68
	v_add_f32_e32 v68, v164, v68
	v_add_f32_e32 v68, v165, v68
	v_add_f32_e32 v68, v166, v68
	v_add_f32_e32 v68, v167, v68
	v_add_f32_e32 v68, v168, v68
	v_add_f32_e32 v68, v169, v68
	v_add_f32_e32 v68, v170, v68
	v_add_f32_e32 v68, v171, v68
.Ltmp39:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:571:47 ]
	v_mov_b32_e32 v69, v68
	s_nop 1
	v_permlane32_swap_b32_e32 v68, v69
.Ltmp40:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:571:47 ] ]
	v_add_f32_e32 v123, v68, v69
.Ltmp41:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:571:47 ]
	v_mov_b32_e32 v143, v123
	s_nop 1
	v_permlane16_swap_b32_e32 v123, v143
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
.Ltmp42:
	.loc	1 579 16                        ; extend_attention.py:579:16
	s_and_saveexec_b64 s[14:15], s[12:13]
	s_cbranch_execz .LBB0_13
; %bb.12:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 579 27 is_stmt 0              ; extend_attention.py:579:27
	v_mad_u64_u32 v[68:69], s[12:13], v90, s94, v[100:101]
	v_mul_lo_u32 v70, v90, s93
	v_mul_lo_u32 v71, v91, s94
	v_add3_u32 v69, v71, v69, v70
	.loc	1 579 16                        ; extend_attention.py:579:16
	global_load_dwordx4 v[68:71], v[68:69], off
.LBB0_13:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[14:15]
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, v72
	.loc	1 579 16                        ; extend_attention.py:579:16
	s_and_saveexec_b64 s[12:13], s[10:11]
	s_cbranch_execz .LBB0_15
; %bb.14:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 579 27                        ; extend_attention.py:579:27
	v_mad_u64_u32 v[74:75], s[10:11], v88, s94, v[100:101]
	v_mul_lo_u32 v73, v88, s93
	v_mul_lo_u32 v76, v89, s94
	v_add3_u32 v75, v76, v75, v73
	.loc	1 579 16                        ; extend_attention.py:579:16
	global_load_dwordx4 v[76:79], v[74:75], off
.LBB0_15:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[12:13]
	v_mov_b32_e32 v73, v72
	v_mov_b32_e32 v74, v72
	v_mov_b32_e32 v75, v72
	.loc	1 579 16                        ; extend_attention.py:579:16
	s_and_saveexec_b64 s[10:11], s[6:7]
	s_cbranch_execz .LBB0_17
; %bb.16:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 579 27                        ; extend_attention.py:579:27
	v_mad_u64_u32 v[72:73], s[6:7], v86, s94, v[100:101]
	v_mul_lo_u32 v74, v86, s93
	v_mul_lo_u32 v75, v87, s94
	v_add3_u32 v73, v75, v73, v74
	.loc	1 579 16                        ; extend_attention.py:579:16
	global_load_dwordx4 v[72:75], v[72:73], off
.LBB0_17:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 16                          ; extend_attention.py:0:16
	s_or_b64 exec, exec, s[10:11]
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	.loc	1 579 16                        ; extend_attention.py:579:16
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_2
; %bb.18:                               ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 579 27                        ; extend_attention.py:579:27
	v_mad_u64_u32 v[80:81], s[10:11], v84, s94, v[100:101]
	v_mul_lo_u32 v82, v84, s93
	v_mul_lo_u32 v83, v85, s94
	v_add3_u32 v81, v83, v81, v82
	.loc	1 579 16                        ; extend_attention.py:579:16
	global_load_dwordx4 v[80:83], v[80:81], off
	s_branch .LBB0_2
.LBB0_19:                               ; %Flow1619
	.loc	1 0 16                          ; extend_attention.py:0:16
	scratch_load_dwordx4 v[190:193], off, off offset:16 ; 16-byte Folded Reload
	scratch_load_dwordx4 v[170:173], off, off offset:32 ; 16-byte Folded Reload
	v_mov_b64_e32 v[174:175], v[216:217]
	v_mov_b64_e32 v[176:177], v[218:219]
	v_mov_b32_e32 v84, v108
.LBB0_20:                               ; %Flow1620
	s_load_dwordx4 s[12:15], s[0:1], 0x60
	s_load_dwordx2 s[48:49], s[0:1], 0x70
	.loc	1 593 64 is_stmt 1              ; extend_attention.py:593:64
	s_add_i32 s0, s88, 0x80
	.loc	1 593 44 is_stmt 0              ; extend_attention.py:593:44
	s_ashr_i32 s1, s0, 31
	v_mov_b32_e32 v69, s1
	v_cmp_gt_i64_e32 vcc, s[0:1], v[120:121]
	.loc	1 474 8 is_stmt 1               ; extend_attention.py:474:8
	v_mov_b32_e32 v68, 0xf0
	v_bitop3_b32 v68, s96, v68, v103 bitop3:0xc8
	.loc	1 593 44                        ; extend_attention.py:593:44
	v_cndmask_b32_e32 v117, v69, v121, vcc
	v_mov_b32_e32 v69, s0
	v_cndmask_b32_e32 v116, v69, v120, vcc
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_cmp_lt_i64_e32 vcc, 0, v[116:117]
	s_mov_b64 s[0:1], 0
	s_cbranch_vccz .LBB0_22
; %bb.21:
	.loc	1 0 45 is_stmt 0                ; extend_attention.py:0:45
	s_mov_b64 s[0:1], -1
.LBB0_22:                               ; %Flow1617
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_26
; %bb.23:                               ; %.lr.ph34
	.loc	1 595 45 is_stmt 1              ; extend_attention.py:595:45
	v_add_u32_e32 v66, v66, v252
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s0, s15, s33
	v_add_u32_e32 v79, 0x60, v66
	s_lshl_b32 s0, s0, 1
	v_mul_lo_u32 v80, s14, v79
	v_lshl_add_u32 v126, v80, 1, s0
	v_add_u32_e32 v80, 64, v66
	v_mul_lo_u32 v81, s14, v80
	v_lshl_add_u32 v127, v81, 1, s0
	v_add_u32_e32 v81, 32, v66
	v_mul_lo_u32 v82, s14, v81
	v_lshl_add_u32 v128, v82, 1, s0
	v_mul_lo_u32 v82, s14, v66
	v_lshrrev_b32_e32 v68, 1, v68
	v_and_b32_e32 v75, 60, v109
	v_lshl_add_u32 v129, v82, 1, s0
	s_mul_i32 s0, s13, s33
	v_xor_b32_e32 v67, v68, v67
	v_lshlrev_b32_e32 v76, 7, v75
	v_and_b32_e32 v77, 24, v0
	v_lshlrev_b32_e32 v75, 1, v75
	s_lshl_b32 s0, s0, 1
	v_mul_lo_u32 v79, s12, v79
	v_bitop3_b32 v69, v104, v114, v96 bitop3:0x36
	v_xor_b32_e32 v68, 8, v67
	scratch_store_dword off, v0, off offset:84 ; 4-byte Folded Spill
	v_bitop3_b32 v75, v76, v75, v77 bitop3:0x36
	v_lshl_add_u32 v130, v79, 1, s0
	v_mul_lo_u32 v79, s12, v80
	v_add_u32_e32 v0, 0, v67
                                        ; implicit-def: $vgpr255 : SGPR spill to VGPR lane
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_mov_b32_e32 v85, 0
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_xor_b32_e32 v70, 64, v69
	v_xor_b32_e32 v71, 0x80, v69
	v_xor_b32_e32 v72, 0xc0, v69
	v_xor_b32_e32 v73, 16, v67
	v_xor_b32_e32 v74, 24, v67
	v_xor_b32_e32 v76, 32, v75
	v_xor_b32_e32 v77, 64, v75
	v_xor_b32_e32 v78, 0x60, v75
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_lshl_add_u32 v131, v79, 1, s0
	v_mul_lo_u32 v79, s12, v81
	v_mul_lo_u32 v66, s12, v66
	scratch_store_dword off, v0, off offset:32 ; 4-byte Folded Spill
	v_add_u32_e32 v0, 0, v68
	v_writelane_b32 v255, s99, 0
	s_and_b32 s5, s5, 0xffff
	s_and_b32 s81, s81, 0xffff
	v_lshlrev_b32_e32 v125, 5, v102
	v_mov_b32_e32 v253, v85
	s_lshl_b32 s89, s14, 8
	s_lshl_b32 s98, s12, 8
	v_lshl_add_u32 v132, v79, 1, s0
	v_lshl_add_u32 v133, v66, 1, s0
	s_mov_b64 s[50:51], 0
	s_mov_b64 s[52:53], 0x60
	s_mov_b64 s[54:55], 0x70
	s_mov_b64 s[56:57], 0x71
	s_mov_b64 s[58:59], 0x72
	s_mov_b64 s[60:61], 0x73
	v_add_u32_e32 v134, 0, v69
	v_add_u32_e32 v135, 0, v70
	v_add_u32_e32 v136, 0, v71
	v_add_u32_e32 v137, 0, v72
	s_mov_b32 s99, 0xff800000
	s_mov_b32 s33, 0xc2fc0000
	scratch_store_dword off, v0, off offset:48 ; 4-byte Folded Spill
	v_add_u32_e32 v0, 0, v73
	v_add_u32_e32 v195, 0, v74
	v_add_u32_e32 v142, 0, v75
	v_add_u32_e32 v143, 0, v76
	v_add_u32_e32 v144, 0, v77
	v_add_u32_e32 v145, 0, v78
	v_bfrev_b32_e32 v146, 1
	v_mov_b32_e32 v147, 0xff800000
	v_mov_b32_e32 v148, 0x42800000
	v_not_b32_e32 v149, 63
	s_mov_b32 s82, s6
	s_mov_b32 s83, s7
	scratch_store_dwordx2 off, v[106:107], off offset:56 ; 8-byte Folded Spill
	scratch_store_dword off, v119, off offset:72 ; 4-byte Folded Spill
	scratch_store_dword off, v112, off offset:76 ; 4-byte Folded Spill
	scratch_store_dwordx2 off, v[120:121], off offset:64 ; 8-byte Folded Spill
	scratch_store_dword off, v114, off offset:80 ; 4-byte Folded Spill
	scratch_store_dword off, v109, off offset:88 ; 4-byte Folded Spill
	scratch_store_dword off, v0, off offset:52 ; 4-byte Folded Spill
	scratch_store_dwordx4 off, v[212:215], off ; 16-byte Folded Spill
	scratch_store_dwordx2 off, v[84:85], off offset:16 ; 8-byte Folded Spill
.LBB0_24:                               ; =>This Inner Loop Header: Depth=1
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[68:69], v[252:253], 0, s[50:51]
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v66, v125, v133
	.loc	1 597 28                        ; extend_attention.py:597:28
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[70:71], v[84:85], 0, s[50:51]
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v67, v125, v129
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[68:69], v[116:117]
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v118, 16, v66
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, 1
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v154, 16, v67
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[74:75], v[70:71], 0, 2
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_cndmask_b32_e32 v155, v146, v66, vcc
	v_cndmask_b32_e32 v118, v146, v118, vcc
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[12:13], v[72:73], v[116:117]
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_cndmask_b32_e32 v67, v146, v67, vcc
	v_cndmask_b32_e32 v66, v146, v154, vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[72:73], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[76:77], v[70:71], 0, 3
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[14:15], v[74:75], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[92:93], s[12:13], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[74:75], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[78:79], v[70:71], 0, 16
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[16:17], v[76:77], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[90:91], s[14:15], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[76:77], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[80:81], v[70:71], 0, 17
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[18:19], v[78:79], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[86:87], s[16:17], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[78:79], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[82:83], v[70:71], 0, 18
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[20:21], v[80:81], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[84:85], s[18:19], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[80:81], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[84:85], v[70:71], 0, 19
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[22:23], v[82:83], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[78:79], s[20:21], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[82:83], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[86:87], v[70:71], 0, 32
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[24:25], v[84:85], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[76:77], s[22:23], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[84:85], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[88:89], v[70:71], 0, 33
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[26:27], v[86:87], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[74:75], s[24:25], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[86:87], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[90:91], v[70:71], 0, 34
	s_mov_b64 s[0:1], 0x41
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[28:29], v[88:89], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[72:73], s[26:27], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[88:89], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[92:93], v[70:71], 0, 35
	v_lshl_add_u64 v[104:105], v[70:71], 0, s[0:1]
	s_mov_b64 s[0:1], 0x42
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[30:31], v[90:91], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[62:63], s[28:29], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[90:91], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[94:95], v[70:71], 0, 48
	v_lshl_add_u64 v[150:151], v[70:71], 0, s[0:1]
	s_mov_b64 s[0:1], 0x43
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[34:35], v[92:93], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[28:29], s[30:31], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[92:93], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[96:97], v[70:71], 0, 49
	v_lshl_add_u64 v[152:153], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[0:1], v[70:71], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[10:11], v[70:71], v[110:111]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[36:37], v[94:95], v[116:117]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[26:27], s[34:35], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[94:95], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[98:99], v[70:71], 0, 50
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[38:39], v[96:97], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[94:95], s[0:1], s[10:11]
	s_and_b64 s[10:11], s[36:37], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[96:97], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[100:101], v[70:71], 0, 51
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[40:41], v[98:99], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[12:13], s[38:39], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[98:99], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[102:103], v[70:71], 0, 64
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[42:43], v[100:101], v[116:117]
	.loc	1 619 28 is_stmt 1              ; extend_attention.py:619:28
	s_and_b64 s[14:15], s[40:41], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[100:101], v[110:111]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[44:45], v[102:103], v[116:117]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[16:17], s[42:43], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[102:103], v[110:111]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[46:47], v[104:105], v[116:117]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[18:19], s[44:45], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[104:105], v[110:111]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e64 s[0:1], v[150:151], v[116:117]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[20:21], s[46:47], vcc
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e32 vcc, v[150:151], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[22:23], s[0:1], vcc
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[152:153], v[116:117]
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[152:153], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[24:25], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x50
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[30:31], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x51
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[34:35], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x52
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[36:37], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x53
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[52:53]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[38:39], vcc, s[0:1]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[40:41], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x61
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[42:43], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x62
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[44:45], vcc, s[0:1]
	s_mov_b64 s[0:1], 0x63
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[0:1]
	.loc	1 597 38 is_stmt 0              ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16 is_stmt 1              ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[54:55]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[46:47], vcc, s[0:1]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[56:57]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[64:65], vcc, s[0:1]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[72:73], v[70:71], 0, s[58:59]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[66:67], vcc, s[0:1]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[72:73], v[116:117]
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[72:73], v[110:111]
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[70:71], v[70:71], 0, s[60:61]
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[68:69], vcc, s[0:1]
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[70:71], v[116:117]
	.loc	1 617 16                        ; extend_attention.py:617:16
	v_cmp_le_i64_e64 s[0:1], v[70:71], v[110:111]
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v72, v125, v132
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[70:71], v[68:69], 0, 32
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[70:71], vcc, s[0:1]
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v73, v125, v128
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v74, 16, v72
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[70:71], v[116:117]
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v75, 16, v73
	v_add_u32_e32 v77, v125, v127
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_cndmask_b32_e32 v76, v146, v74, vcc
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_cndmask_b32_e32 v74, v146, v73, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v73, v125, v131
	.loc	1 597 28                        ; extend_attention.py:597:28
	v_lshl_add_u64 v[70:71], v[68:69], 0, 64
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_cndmask_b32_e32 v72, v146, v72, vcc
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_cndmask_b32_e32 v75, v146, v75, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v78, 16, v73
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v79, 16, v77
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[70:71], v[116:117]
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v70, v125, v130
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v71, v125, v126
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_lshl_add_u64 v[68:69], v[68:69], 0, s[52:53]
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_cndmask_b32_e32 v73, v146, v73, vcc
	v_cndmask_b32_e32 v88, v146, v78, vcc
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_cndmask_b32_e32 v78, v146, v77, vcc
	v_cndmask_b32_e32 v79, v146, v79, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_add_u32_e32 v77, 16, v70
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_add_u32_e32 v80, 16, v71
	.loc	1 597 38                        ; extend_attention.py:597:38
	v_cmp_lt_i64_e32 vcc, v[68:69], v[116:117]
	v_mov_b64_e32 v[218:219], v[210:211]
	v_mov_b64_e32 v[216:217], v[208:209]
	.loc	1 644 16                        ; extend_attention.py:644:16
	v_cndmask_b32_e32 v89, v146, v70, vcc
	v_cndmask_b32_e32 v77, v146, v77, vcc
	.loc	1 685 16                        ; extend_attention.py:685:16
	v_cndmask_b32_e32 v91, v146, v71, vcc
	v_cndmask_b32_e32 v90, v146, v80, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	buffer_load_dwordx4 v[68:71], v155, s[4:7], 0 offen
	buffer_load_dwordx4 v[80:83], v118, s[4:7], 0 offen
	buffer_load_dwordx4 v[84:87], v72, s[4:7], 0 offen
	buffer_load_dwordx4 v[96:99], v73, s[4:7], 0 offen
	buffer_load_dwordx4 v[100:103], v89, s[4:7], 0 offen
	buffer_load_dwordx4 v[92:95], v76, s[4:7], 0 offen
	buffer_load_dwordx4 v[150:153], v88, s[4:7], 0 offen
	buffer_load_dwordx4 v[154:157], v77, s[4:7], 0 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(7)
	ds_write_b128 v1, v[68:71]
	s_waitcnt vmcnt(6)
	ds_write_b128 v122, v[80:83]
	s_waitcnt vmcnt(5)
	ds_write_b128 v1, v[84:87] offset:16384
	s_waitcnt vmcnt(4)
	ds_write_b128 v1, v[96:99] offset:32768
	s_waitcnt vmcnt(3)
	ds_write_b128 v1, v[100:103] offset:49152
	s_waitcnt vmcnt(2)
	ds_write_b128 v122, v[92:95] offset:16384
	s_waitcnt vmcnt(1)
	ds_write_b128 v122, v[150:153] offset:32768
	s_waitcnt vmcnt(0)
	ds_write_b128 v122, v[154:157] offset:49152
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[68:71], v134
	ds_read_b128 v[106:109], v135 offset:32768
	ds_read_b128 v[80:83], v135
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[68:71], v[190:193], 0
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v135 offset:40960
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[94:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[84:87], v134 offset:49152
	ds_read_b128 v[92:95], v134 offset:57344
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[196:199], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[0:1], s[2:3], s[12:13]
	s_and_b64 s[12:13], s[2:3], s[16:17]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[204:207], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[16:17], s[2:3], s[20:21]
	s_and_b64 s[20:21], s[2:3], s[24:25]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[212:215], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v134 offset:256
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[24:25], s[2:3], s[34:35]
	s_and_b64 s[34:35], s[2:3], s[42:43]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[170:173], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:256
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[42:43], s[2:3], s[66:67]
	.loc	1 673 48                        ; extend_attention.py:673:48
	v_max_f32_e32 v157, v124, v124
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[200:203], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:256
	v_mov_b32_e32 v194, v1
	v_mov_b64_e32 v[188:189], v[252:253]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[208:211], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:256
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_add_u32_e32 v126, s89, v126
	v_add_u32_e32 v127, s89, v127
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[174:177], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:8192
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_add_u32_e32 v128, s89, v128
	v_add_u32_e32 v129, s89, v129
	.loc	1 661 18                        ; extend_attention.py:661:18
	s_nop 4
	v_mul_f32_e32 v68, s97, v68
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v102, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[92:93]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v69
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v103, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[90:91]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v70
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v104, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[86:87]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v71
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v105, v147, v68, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[68:71], v134 offset:8192
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[68:71], v[190:193], 0
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[84:85]
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_add_u32_e32 v130, s98, v130
	v_add_u32_e32 v131, s98, v131
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[196:199], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:8192
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_add_u32_e32 v132, s98, v132
	v_add_u32_e32 v133, s98, v133
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[204:207], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:8192
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[212:215], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v134 offset:8448
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[170:173], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:8448
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[200:203], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:8448
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[208:211], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:8448
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[174:177], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:16384
	.loc	1 661 18                        ; extend_attention.py:661:18
	s_nop 6
	v_mul_f32_e32 v68, s97, v68
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v118, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[78:79]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v69
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v150, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[76:77]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v70
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v151, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[74:75]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v71
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v152, v147, v68, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[68:71], v134 offset:16384
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[68:71], v[190:193], 0
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[72:73]
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[196:199], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:16384
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[204:207], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:16384
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[212:215], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v134 offset:16640
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[170:173], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:16640
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[200:203], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:16640
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[208:211], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:16640
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[174:177], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:24576
	.loc	1 661 18                        ; extend_attention.py:661:18
	s_nop 6
	v_mul_f32_e32 v68, s97, v68
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v153, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[62:63]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v69
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v154, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[28:29]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v70
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v155, v147, v68, vcc
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[26:27]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v68, s97, v71
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v156, v147, v68, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[68:71], v134 offset:24576
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[68:71], v[190:193], 0
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 vcc, s[2:3], s[10:11]
	s_and_b64 s[10:11], s[2:3], s[14:15]
	s_and_b64 s[14:15], s[2:3], s[18:19]
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[196:199], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:24576
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[18:19], s[2:3], s[22:23]
	s_and_b64 s[22:23], s[2:3], s[30:31]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[204:207], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:24576
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[26:27], s[2:3], s[36:37]
	s_and_b64 s[28:29], s[2:3], s[38:39]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[212:215], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v134 offset:24832
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[30:31], s[2:3], s[40:41]
	s_and_b64 s[36:37], s[2:3], s[44:45]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[170:173], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v135 offset:24832
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[38:39], s[2:3], s[46:47]
	s_and_b64 s[40:41], s[2:3], s[64:65]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[200:203], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v136 offset:24832
	.loc	1 619 28                        ; extend_attention.py:619:28
	s_and_b64 s[44:45], s[2:3], s[68:69]
	s_and_b64 s[46:47], s[2:3], s[70:71]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[80:83], v[208:211], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[80:83], v137 offset:24832
	.loc	1 595 45                        ; extend_attention.py:595:45
	s_add_u32 s50, s50, 0x80
	s_addc_u32 s51, s51, 0
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[98:101], v[80:83], v[174:177], v[68:71]
	.loc	1 661 18                        ; extend_attention.py:661:18
	s_nop 7
	v_mul_f32_e32 v68, s97, v98
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e32 v98, v147, v68, vcc
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[68:71], v134 offset:32768
	ds_read_b128 v[80:83], v134 offset:40960
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[68:71], v[190:193], 0
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v99, s97, v99
	v_mul_f32_e32 v100, s97, v100
	v_mul_f32_e32 v101, s97, v101
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[80:83], v[80:83], v[190:193], 0
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v99, v147, v99, s[0:1]
	v_cndmask_b32_e64 v100, v147, v100, s[10:11]
	v_cndmask_b32_e64 v101, v147, v101, s[12:13]
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[68:71], v[106:109], v[196:199], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v135 offset:49152
	.loc	1 595 45                        ; extend_attention.py:595:45
	v_cmp_lt_i64_e32 vcc, s[50:51], v[116:117]
	s_and_b64 vcc, exec, vcc
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[80:83], v[112:115], v[196:199], v[80:83]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v135 offset:57344
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[84:87], v[84:87], v[190:193], 0
	v_mfma_f32_16x16x32_bf16 v[92:95], v[92:95], v[190:193], 0
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[84:87], v[106:109], v[196:199], v[84:87]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v136 offset:32768
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[112:115], v[196:199], v[92:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v136 offset:40960
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[106:109], v[204:207], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v136 offset:49152
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[80:83], v[112:115], v[204:207], v[80:83]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v136 offset:57344
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[84:87], v[106:109], v[204:207], v[84:87]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v137 offset:40960
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[112:115], v[204:207], v[92:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v137 offset:49152
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[84:87], v[112:115], v[212:215], v[84:87]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v137 offset:32768
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[80:83], v[106:109], v[212:215], v[80:83]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v137 offset:57344
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[106:109], v[212:215], v[92:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v134 offset:49408
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[68:71], v[112:115], v[212:215], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v134 offset:57600
	v_mov_b64_e32 v[214:215], v[206:207]
	v_mov_b64_e32 v[212:213], v[204:205]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[84:87], v[106:109], v[170:173], v[84:87]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v134 offset:33024
	v_mov_b64_e32 v[206:207], v[198:199]
	v_mov_b64_e32 v[204:205], v[196:197]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[112:115], v[170:173], v[92:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v134 offset:41216
	v_mov_b64_e32 v[198:199], v[176:177]
	v_mov_b64_e32 v[196:197], v[174:175]
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[80:83], v[112:115], v[170:173], v[80:83]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v135 offset:49408
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[68:71], v[106:109], v[170:173], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v135 offset:33024
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[84:87], v[112:115], v[200:203], v[84:87]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v135 offset:41216
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[106:109], v[200:203], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v135 offset:57600
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[80:83], v[112:115], v[200:203], v[80:83]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[112:115], v136 offset:49408
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[162:165], v[112:115], v[208:211], v[84:87]
	.loc	1 644 16                        ; extend_attention.py:644:16
	s_nop 2
	ds_read_b128 v[84:87], v136 offset:41216
	ds_read_b128 v[112:115], v137 offset:49408
	ds_read_b128 v[138:141], v137 offset:57600
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[92:95], v[106:109], v[200:203], v[92:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	ds_read_b128 v[106:109], v136 offset:33024
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[158:161], v[106:109], v[208:211], v[68:71]
	.loc	1 644 16                        ; extend_attention.py:644:16
	s_nop 2
	ds_read_b128 v[68:71], v136 offset:57600
	.loc	1 647 27                        ; extend_attention.py:647:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[166:169], v[68:71], v[208:211], v[92:95]
	.loc	1 644 16                        ; extend_attention.py:644:16
	s_nop 2
	ds_read_b128 v[92:95], v137 offset:33024
	ds_read_b128 v[106:109], v137 offset:41216
	.loc	1 685 16                        ; extend_attention.py:685:16
	buffer_load_dwordx4 v[70:73], v67, s[80:83], 0 offen
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[86:89], v[84:87], v[208:211], v[80:83]
	v_mov_b64_e32 v[210:211], v[202:203]
	v_mov_b64_e32 v[208:209], v[200:201]
	v_mov_b64_e32 v[202:203], v[172:173]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[158:161], v[92:95], v[174:177], v[158:161]
	v_mov_b64_e32 v[200:201], v[170:171]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[170:173], v[106:109], v[174:177], v[86:89]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_nop 2
	buffer_load_dwordx4 v[86:89], v78, s[80:83], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[78:81], v79, s[80:83], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[94:97], v91, s[80:83], 0 offen
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v158, s97, v158
	v_mul_f32_e32 v159, s97, v159
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[162:165], v[112:115], v[174:177], v[162:165]
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v160, s97, v160
	v_mul_f32_e32 v161, s97, v161
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v158, v147, v158, s[14:15]
	.loc	1 647 27                        ; extend_attention.py:647:27
	v_mfma_f32_16x16x32_bf16 v[166:169], v[138:141], v[174:177], v[166:169]
.Ltmp43:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max_f32_e32 v174, v102, v103
	v_max3_f32 v174, v174, v104, v105
	v_max3_f32 v174, v174, v118, v150
	v_max3_f32 v174, v174, v151, v152
	v_max3_f32 v174, v174, v153, v154
	v_max3_f32 v174, v174, v155, v156
	v_max3_f32 v174, v174, v98, v99
.Ltmp44:
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v159, v147, v159, s[16:17]
.Ltmp45:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v100, v101
.Ltmp46:
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v170, s97, v170
	v_mul_f32_e32 v171, s97, v171
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v160, v147, v160, s[18:19]
	v_cndmask_b32_e64 v161, v147, v161, s[20:21]
.Ltmp47:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v158, v159
.Ltmp48:
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v172, s97, v172
	v_mul_f32_e32 v173, s97, v173
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v170, v147, v170, s[22:23]
	v_cndmask_b32_e64 v171, v147, v171, s[24:25]
.Ltmp49:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v160, v161
.Ltmp50:
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v162, s97, v162
	v_mul_f32_e32 v163, s97, v163
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v172, v147, v172, s[26:27]
	v_cndmask_b32_e64 v173, v147, v173, s[28:29]
.Ltmp51:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v170, v171
.Ltmp52:
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v164, s97, v164
	v_mul_f32_e32 v165, s97, v165
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v162, v147, v162, s[30:31]
	v_cndmask_b32_e64 v163, v147, v163, s[34:35]
.Ltmp53:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v172, v173
.Ltmp54:
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v166, s97, v166
	v_mul_f32_e32 v167, s97, v167
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v164, v147, v164, s[36:37]
	v_cndmask_b32_e64 v165, v147, v165, s[38:39]
.Ltmp55:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v162, v163
.Ltmp56:
	.loc	1 661 18                        ; extend_attention.py:661:18
	v_mul_f32_e32 v168, s97, v168
	v_mul_f32_e32 v169, s97, v169
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v166, v147, v166, s[40:41]
	v_cndmask_b32_e64 v167, v147, v167, s[42:43]
.Ltmp57:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v164, v165
.Ltmp58:
	.loc	1 669 42                        ; extend_attention.py:669:42
	v_cndmask_b32_e64 v168, v147, v168, s[44:45]
	v_cndmask_b32_e64 v169, v147, v169, s[46:47]
.Ltmp59:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max3_f32 v174, v174, v166, v167
	v_max3_f32 v174, v174, v168, v169
.Ltmp60:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:671:33 ]
	v_mov_b32_e32 v175, v174
	s_nop 1
	v_permlane32_swap_b32_e32 v174, v175
.Ltmp61:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max_f32_e32 v175, v175, v175
	v_max_f32_e32 v174, v174, v174
	v_max_f32_e32 v174, v174, v175
.Ltmp62:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:671:33 ]
	v_mov_b32_e32 v175, v174
	s_nop 1
	v_permlane16_swap_b32_e32 v174, v175
.Ltmp63:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:671:33 ] ]
	v_max_f32_e32 v175, v175, v175
	v_max_f32_e32 v174, v174, v174
	v_max_f32_e32 v174, v174, v175
.Ltmp64:
	.loc	1 672 70                        ; extend_attention.py:672:70
	v_cmp_neq_f32_e64 s[0:1], s99, v174
	v_mov_b32_e32 v175, 0xe0ad78ec
	.loc	1 685 16                        ; extend_attention.py:685:16
	buffer_load_dwordx4 v[90:93], v90, s[80:83], 0 offen
	.loc	1 672 70                        ; extend_attention.py:672:70
	v_cndmask_b32_e64 v174, v175, v174, s[0:1]
	.loc	1 673 48                        ; extend_attention.py:673:48
	v_max_f32_e32 v157, v174, v157
	.loc	1 675 38                        ; extend_attention.py:675:38
	v_sub_f32_e32 v174, v124, v157
	.loc	1 676 28                        ; extend_attention.py:676:28
	v_sub_f32_e32 v153, v153, v157
	v_sub_f32_e32 v102, v102, v157
	v_sub_f32_e32 v103, v103, v157
	v_sub_f32_e32 v104, v104, v157
	v_sub_f32_e32 v105, v105, v157
	v_sub_f32_e32 v118, v118, v157
	v_sub_f32_e32 v150, v150, v157
	v_sub_f32_e32 v151, v151, v157
	v_sub_f32_e32 v152, v152, v157
	v_sub_f32_e32 v154, v154, v157
	v_sub_f32_e32 v155, v155, v157
	v_sub_f32_e32 v156, v156, v157
	v_sub_f32_e32 v98, v98, v157
	v_sub_f32_e32 v99, v99, v157
	v_sub_f32_e32 v100, v100, v157
	v_sub_f32_e32 v101, v101, v157
	v_sub_f32_e32 v158, v158, v157
	v_sub_f32_e32 v159, v159, v157
	v_sub_f32_e32 v160, v160, v157
	v_sub_f32_e32 v161, v161, v157
	v_sub_f32_e32 v170, v170, v157
	v_sub_f32_e32 v171, v171, v157
	v_sub_f32_e32 v172, v172, v157
	v_sub_f32_e32 v173, v173, v157
	v_sub_f32_e32 v162, v162, v157
	v_sub_f32_e32 v163, v163, v157
	v_sub_f32_e32 v164, v164, v157
	v_sub_f32_e32 v165, v165, v157
	v_sub_f32_e32 v166, v166, v157
	v_sub_f32_e32 v167, v167, v157
	v_sub_f32_e32 v168, v168, v157
	v_sub_f32_e32 v169, v169, v157
	v_mov_b32_e32 v124, v157
	.loc	1 675 30                        ; extend_attention.py:675:30
	v_mul_f32_e32 v157, 0x3fb8aa3b, v174
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_mul_f32_e32 v183, 0x3fb8aa3b, v153
	v_mul_f32_e32 v175, 0x3fb8aa3b, v102
	v_mul_f32_e32 v177, 0x3fb8aa3b, v104
	v_mul_f32_e32 v179, 0x3fb8aa3b, v118
	v_mul_f32_e32 v185, 0x3fb8aa3b, v155
	v_mul_f32_e32 v186, 0x3fb8aa3b, v156
	v_mul_f32_e32 v224, 0x3fb8aa3b, v159
	v_mul_f32_e32 v225, 0x3fb8aa3b, v160
	v_mul_f32_e32 v234, 0x3fb8aa3b, v165
	.loc	1 675 30                        ; extend_attention.py:675:30
	v_cmp_gt_f32_e64 s[18:19], s33, v157
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cmp_gt_f32_e64 s[44:45], s33, v183
	v_mul_f32_e32 v180, 0x3fb8aa3b, v150
	v_mul_f32_e32 v182, 0x3fb8aa3b, v152
	v_mul_f32_e32 v184, 0x3fb8aa3b, v154
	v_mul_f32_e32 v228, 0x3fb8aa3b, v171
	v_mul_f32_e32 v230, 0x3fb8aa3b, v173
	v_cmp_gt_f32_e64 s[20:21], s33, v175
	v_cmp_gt_f32_e64 s[24:25], s33, v177
	v_cmp_gt_f32_e64 s[28:29], s33, v179
	v_cmp_gt_f32_e64 s[42:43], s33, v185
	v_cmp_gt_f32_e64 s[38:39], s33, v186
	v_cmp_gt_f32_e64 s[16:17], s33, v224
	.loc	1 675 30                        ; extend_attention.py:675:30
	v_cndmask_b32_e64 v157, 0, v148, s[18:19]
	v_cndmask_b32_e64 v175, 0, v149, s[18:19]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cmp_gt_f32_e64 s[18:19], s33, v225
	v_cndmask_b32_e64 v224, 0, v148, s[44:45]
	v_cndmask_b32_e64 v225, 0, v149, s[44:45]
	v_cmp_gt_f32_e64 s[44:45], s33, v234
	v_mul_f32_e32 v176, 0x3fb8aa3b, v103
	v_mul_f32_e32 v226, 0x3fb8aa3b, v161
	v_cmp_gt_f32_e64 s[30:31], s33, v180
	v_cmp_gt_f32_e64 s[40:41], s33, v182
	v_cmp_gt_f32_e64 s[46:47], s33, v184
	v_cndmask_b32_e64 v180, 0, v148, s[24:25]
	v_cndmask_b32_e64 v182, 0, v149, s[24:25]
	v_cmp_gt_f32_e64 s[24:25], s33, v228
	v_cndmask_b32_e64 v184, 0, v148, s[28:29]
	v_cndmask_b32_e64 v185, 0, v149, s[28:29]
	v_cmp_gt_f32_e64 s[28:29], s33, v230
	v_cndmask_b32_e64 v228, 0, v148, s[42:43]
	v_cndmask_b32_e64 v230, 0, v148, s[38:39]
	v_cndmask_b32_e64 v248, 0, v148, s[44:45]
	v_cmp_gt_f32_e64 s[22:23], s33, v176
	v_cndmask_b32_e64 v176, 0, v148, s[20:21]
	v_cndmask_b32_e64 v177, 0, v149, s[20:21]
	v_cmp_gt_f32_e64 s[20:21], s33, v226
	v_cndmask_b32_e64 v226, 0, v148, s[46:47]
	v_fmac_f32_e32 v228, 0x3fb8aa3b, v155
	v_fmac_f32_e32 v230, 0x3fb8aa3b, v156
	v_fmac_f32_e32 v248, 0x3fb8aa3b, v165
	v_mul_f32_e32 v178, 0x3fb8aa3b, v105
	v_fmac_f32_e32 v224, 0x3fb8aa3b, v153
	v_fmac_f32_e32 v226, 0x3fb8aa3b, v154
	v_exp_f32_e32 v153, v228
	v_exp_f32_e32 v154, v230
	v_exp_f32_e32 v230, v248
	v_mul_f32_e32 v181, 0x3fb8aa3b, v151
	v_mul_f32_e32 v229, 0x3fb8aa3b, v172
	v_cmp_gt_f32_e64 s[26:27], s33, v178
	v_cmp_gt_f32_e64 s[36:37], s33, v181
	v_cndmask_b32_e64 v0, 0, v149, s[44:45]
	v_cndmask_b32_e64 v181, 0, v148, s[26:27]
	v_cndmask_b32_e64 v183, 0, v149, s[26:27]
	v_cmp_gt_f32_e64 s[26:27], s33, v229
	v_cndmask_b32_e64 v229, 0, v149, s[42:43]
	.loc	1 685 16                        ; extend_attention.py:685:16
	buffer_load_dwordx4 v[66:69], v66, s[80:83], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[82:85], v74, s[80:83], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[74:77], v75, s[80:83], 0 offen
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v243, 0, v148, s[26:27]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_fmac_f32_e32 v243, 0x3fb8aa3b, v172
	v_ldexp_f32 v172, v153, v229
	v_ldexp_f32 v153, v230, v0
	scratch_load_dword v0, off, off offset:32 ; 4-byte Folded Reload
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v0, v[70:71], v[82:83] offset1:32
	ds_write2st64_b64 v0, v[86:87], v[94:95] offset0:64 offset1:96
	scratch_load_dword v0, off, off offset:48 ; 4-byte Folded Reload
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v0, v[72:73], v[84:85] offset1:32
	ds_write2st64_b64 v0, v[88:89], v[96:97] offset0:64 offset1:96
	scratch_load_dword v0, off, off offset:52 ; 4-byte Folded Reload
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_mul_f32_e32 v187, 0x3fb8aa3b, v98
	v_mul_f32_e32 v222, 0x3fb8aa3b, v101
	v_mul_f32_e32 v227, 0x3fb8aa3b, v170
	v_mul_f32_e32 v220, 0x3fb8aa3b, v99
	v_mul_f32_e32 v221, 0x3fb8aa3b, v100
	v_mul_f32_e32 v223, 0x3fb8aa3b, v158
	v_mul_f32_e32 v232, 0x3fb8aa3b, v163
	v_mul_f32_e32 v233, 0x3fb8aa3b, v164
	v_mul_f32_e32 v236, 0x3fb8aa3b, v167
	v_mul_f32_e32 v238, 0x3fb8aa3b, v169
	v_cmp_gt_f32_e64 s[34:35], s33, v187
	v_cmp_gt_f32_e64 s[12:13], s33, v222
	v_cndmask_b32_e64 v178, 0, v148, s[22:23]
	v_cndmask_b32_e64 v179, 0, v149, s[22:23]
	v_cmp_gt_f32_e64 s[22:23], s33, v227
	v_mul_f32_e32 v231, 0x3fb8aa3b, v162
	v_mul_f32_e32 v235, 0x3fb8aa3b, v166
	v_mul_f32_e32 v237, 0x3fb8aa3b, v168
	v_cmp_gt_f32_e64 s[0:1], s33, v220
	v_cmp_gt_f32_e64 s[10:11], s33, v221
	v_cmp_gt_f32_e64 s[14:15], s33, v223
	v_cndmask_b32_e64 v220, 0, v148, s[36:37]
	v_cndmask_b32_e64 v221, 0, v149, s[36:37]
	v_cmp_gt_f32_e64 s[36:37], s33, v232
	v_cndmask_b32_e64 v222, 0, v148, s[40:41]
	v_cndmask_b32_e64 v223, 0, v149, s[40:41]
	v_cmp_gt_f32_e64 s[40:41], s33, v233
	v_cmp_gt_f32_e64 s[42:43], s33, v236
	v_cndmask_b32_e64 v232, 0, v148, s[34:35]
	v_cndmask_b32_e64 v233, 0, v149, s[34:35]
	v_cmp_gt_f32_e64 s[34:35], s33, v238
	v_cndmask_b32_e64 v236, 0, v148, s[12:13]
	v_cndmask_b32_e64 v238, 0, v148, s[16:17]
	v_cndmask_b32_e64 v239, 0, v148, s[18:19]
	v_cndmask_b32_e64 v241, 0, v148, s[22:23]
	v_cndmask_b32_e64 v244, 0, v148, s[28:29]
	.loc	1 675 30                        ; extend_attention.py:675:30
	v_fmac_f32_e32 v157, 0x3fb8aa3b, v174
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v186, 0, v148, s[30:31]
	v_cndmask_b32_e64 v187, 0, v149, s[30:31]
	v_cmp_gt_f32_e64 s[30:31], s33, v231
	v_cndmask_b32_e64 v227, 0, v149, s[46:47]
	v_cmp_gt_f32_e64 s[46:47], s33, v235
	v_cndmask_b32_e64 v231, 0, v149, s[38:39]
	v_cmp_gt_f32_e64 s[38:39], s33, v237
	v_cndmask_b32_e64 v234, 0, v148, s[0:1]
	v_cndmask_b32_e64 v235, 0, v148, s[10:11]
	v_cndmask_b32_e64 v237, 0, v148, s[14:15]
	v_cndmask_b32_e64 v240, 0, v148, s[20:21]
	v_fmac_f32_e32 v176, 0x3fb8aa3b, v102
	v_fmac_f32_e32 v178, 0x3fb8aa3b, v103
	v_fmac_f32_e32 v180, 0x3fb8aa3b, v104
	v_fmac_f32_e32 v181, 0x3fb8aa3b, v105
	v_fmac_f32_e32 v184, 0x3fb8aa3b, v118
	v_fmac_f32_e32 v220, 0x3fb8aa3b, v151
	v_fmac_f32_e32 v222, 0x3fb8aa3b, v152
	v_fmac_f32_e32 v232, 0x3fb8aa3b, v98
	v_fmac_f32_e32 v236, 0x3fb8aa3b, v101
	v_fmac_f32_e32 v238, 0x3fb8aa3b, v159
	v_fmac_f32_e32 v239, 0x3fb8aa3b, v160
	v_fmac_f32_e32 v241, 0x3fb8aa3b, v170
	v_fmac_f32_e32 v244, 0x3fb8aa3b, v173
	.loc	1 675 30                        ; extend_attention.py:675:30
	v_exp_f32_e32 v98, v157
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_fmac_f32_e32 v186, 0x3fb8aa3b, v150
	v_fmac_f32_e32 v234, 0x3fb8aa3b, v99
	v_fmac_f32_e32 v235, 0x3fb8aa3b, v100
	v_fmac_f32_e32 v237, 0x3fb8aa3b, v158
	v_fmac_f32_e32 v240, 0x3fb8aa3b, v161
	v_exp_f32_e32 v99, v176
	v_exp_f32_e32 v100, v178
	v_exp_f32_e32 v101, v180
	v_exp_f32_e32 v102, v181
	v_exp_f32_e32 v103, v184
	v_exp_f32_e32 v105, v220
	v_exp_f32_e32 v150, v222
	v_exp_f32_e32 v158, v236
	v_exp_f32_e32 v160, v238
	v_exp_f32_e32 v161, v239
	v_exp_f32_e32 v184, v241
	v_exp_f32_e32 v220, v243
	v_exp_f32_e32 v222, v244
	v_cndmask_b32_e64 v245, 0, v148, s[30:31]
	v_cndmask_b32_e64 v247, 0, v148, s[40:41]
	v_cndmask_b32_e64 v120, 0, v149, s[12:13]
	v_cndmask_b32_e64 v119, 0, v149, s[16:17]
	v_cndmask_b32_e64 v1, 0, v149, s[18:19]
	v_cndmask_b32_e64 v106, 0, v149, s[22:23]
	v_cndmask_b32_e64 v114, 0, v149, s[26:27]
	v_cndmask_b32_e64 v115, 0, v149, s[28:29]
	v_exp_f32_e32 v104, v186
	.loc	1 675 30                        ; extend_attention.py:675:30
	v_ldexp_f32 v118, v98, v175
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_fmac_f32_e32 v245, 0x3fb8aa3b, v162
	v_fmac_f32_e32 v247, 0x3fb8aa3b, v164
	v_ldexp_f32 v180, v99, v177
	v_ldexp_f32 v181, v100, v179
	v_ldexp_f32 v179, v101, v182
	v_ldexp_f32 v177, v102, v183
	v_ldexp_f32 v178, v103, v185
	v_ldexp_f32 v174, v105, v221
	v_ldexp_f32 v175, v150, v223
	v_ldexp_f32 v165, v158, v120
	v_ldexp_f32 v164, v160, v119
	v_ldexp_f32 v162, v161, v1
	v_ldexp_f32 v161, v184, v106
	v_ldexp_f32 v160, v220, v114
	v_ldexp_f32 v158, v222, v115
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[184:185], v[48:49], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[182:183], v[46:47], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[222:223], v[44:45], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[220:221], v[42:43], v[118:119] op_sel_hi:[1,0]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v0, v[66:67], v[74:75] offset1:32
	ds_write2st64_b64 v0, v[78:79], v[90:91] offset0:64 offset1:96
	ds_write2st64_b64 v195, v[68:69], v[76:77] offset1:32
	ds_write2st64_b64 v195, v[80:81], v[92:93] offset0:64 offset1:96
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[42:43], v142
	ds_read_b64_tr_b16 v[44:45], v142 offset:8192
	ds_read_b64_tr_b16 v[46:47], v143
	ds_read_b64_tr_b16 v[48:49], v143 offset:8192
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[68:69], v[36:37], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[66:67], v[34:35], v[118:119] op_sel_hi:[1,0]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[36:37], v144 offset:8192
	ds_read_b64_tr_b16 v[34:35], v144
	ds_read_b64_tr_b16 v[70:71], v142 offset:128
	ds_read_b64_tr_b16 v[74:75], v145
	ds_read_b64_tr_b16 v[76:77], v145 offset:8192
	ds_read_b64_tr_b16 v[78:79], v142 offset:256
	ds_read_b64_tr_b16 v[82:83], v142 offset:384
	ds_read_b64_tr_b16 v[72:73], v142 offset:8320
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_ldexp_f32 v176, v104, v187
	.loc	1 687 21                        ; extend_attention.py:687:21
	v_cvt_pk_bf16_f32 v102, v180, v181
	v_cvt_pk_bf16_f32 v103, v179, v177
	v_cvt_pk_bf16_f32 v104, v178, v176
	v_cvt_pk_bf16_f32 v105, v174, v175
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[64:65], v[64:65], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[62:63], v[62:63], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[56:57], v[56:57], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[54:55], v[54:55], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[60:61], v[60:61], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[58:59], v[58:59], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[52:53], v[52:53], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[50:51], v[50:51], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[62:65], v[42:45], v[102:105], v[62:65]
	v_mul_f32_e64 v40, v40, v118
	v_mul_f32_e64 v41, v41, v118
	v_pk_mul_f32 v[38:39], v[38:39], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[28:29], v[28:29], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[54:57], v[46:49], v[102:105], v[54:57]
	v_mul_f32_e64 v26, v26, v118
	v_mul_f32_e64 v27, v27, v118
	v_pk_mul_f32 v[24:25], v[24:25], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[22:23], v[22:23], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[34:37], v[102:105], v[58:61]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[80:81], v142 offset:8448
	ds_read_b64_tr_b16 v[34:35], v143 offset:128
	ds_read_b64_tr_b16 v[36:37], v143 offset:8320
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[4:5], v[4:5], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[74:77], v[102:105], v[50:53]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[84:85], v142 offset:8576
	ds_read_b64_tr_b16 v[76:77], v144 offset:8320
	ds_read_b64_tr_b16 v[74:75], v144 offset:128
	ds_read_b64_tr_b16 v[96:97], v144 offset:8576
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v151, v224
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_bf16 v[50:53], v[70:73], v[102:105], v[182:185]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[70:71], v143 offset:256
	ds_read_b64_tr_b16 v[86:87], v145 offset:128
	ds_read_b64_tr_b16 v[88:89], v145 offset:8320
	ds_read_b64_tr_b16 v[90:91], v143 offset:384
	ds_read_b64_tr_b16 v[72:73], v143 offset:8448
	ds_read_b64_tr_b16 v[92:93], v143 offset:8576
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v152, v226
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[58:61], v[34:37], v[102:105], v[220:223]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v155, v232
	v_exp_f32_e32 v156, v234
	v_exp_f32_e32 v157, v235
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[74:77], v[102:105], v[38:41]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[76:77], v144 offset:8448
	ds_read_b64_tr_b16 v[74:75], v144 offset:256
	ds_read_b64_tr_b16 v[94:95], v144 offset:384
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[20:21], v[20:21], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[18:19], v[18:19], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[86:89], v[102:105], v[66:69]
	v_mul_f32_e64 v12, v12, v118
	v_mul_f32_e64 v13, v13, v118
	v_pk_mul_f32 v[10:11], v[10:11], v[118:119] op_sel_hi:[1,0]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v242, 0, v148, s[24:25]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[66:67], v145 offset:256
	ds_read_b64_tr_b16 v[68:69], v145 offset:8448
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[70:73], v[102:105], v[26:29]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[72:73], v145 offset:8576
	ds_read_b64_tr_b16 v[70:71], v145 offset:384
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v250, 0, v148, s[42:43]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_bf16 v[22:25], v[74:77], v[102:105], v[22:25]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[74:75], v143 offset:16384
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v251, 0, v148, s[38:39]
	v_cndmask_b32_e64 v252, 0, v148, s[34:35]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[70:73], v[102:105], v[2:5]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[70:71], v144 offset:16384
	ds_read_b64_tr_b16 v[76:77], v143 offset:24576
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v253, 0, v149, s[0:1]
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[18:21], v[66:69], v[102:105], v[18:21]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v254, 0, v149, s[10:11]
	v_fmac_f32_e32 v242, 0x3fb8aa3b, v171
	v_fmac_f32_e32 v250, 0x3fb8aa3b, v167
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[66:69], v[90:93], v[102:105], v[10:13]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_nop 2
	ds_read_b64_tr_b16 v[10:11], v142 offset:16384
	ds_read_b64_tr_b16 v[12:13], v142 offset:24576
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_fmac_f32_e32 v251, 0x3fb8aa3b, v168
	v_fmac_f32_e32 v252, 0x3fb8aa3b, v169
	v_ldexp_f32 v173, v151, v225
	v_ldexp_f32 v171, v152, v227
	v_ldexp_f32 v170, v154, v231
	v_ldexp_f32 v168, v155, v233
	v_ldexp_f32 v169, v156, v253
	v_ldexp_f32 v167, v157, v254
	.loc	1 687 21                        ; extend_attention.py:687:21
	v_cvt_pk_bf16_f32 v98, v173, v171
	v_cvt_pk_bf16_f32 v99, v172, v170
	v_cvt_pk_bf16_f32 v100, v168, v169
	v_cvt_pk_bf16_f32 v101, v167, v165
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[32:33], v[32:33], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[30:31], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[62:65], v[10:13], v[98:101], v[62:65]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[72:73], v144 offset:24576
	ds_read_b64_tr_b16 v[10:11], v145 offset:16384
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[16:17], v[16:17], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[14:15], v[118:119] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[54:57], v[74:77], v[98:101], v[54:57]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[12:13], v145 offset:24576
	ds_read_b64_tr_b16 v[74:75], v142 offset:16512
	ds_read_b64_tr_b16 v[0:1], v143 offset:32768
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v246, 0, v148, s[36:37]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[70:73], v[98:101], v[42:45]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[76:77], v142 offset:24704
	ds_read_b64_tr_b16 v[72:73], v143 offset:24704
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_pk_mul_f32 v[8:9], v[8:9], v[118:119] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[118:119] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[10:13], v[98:101], v[46:49]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[70:71], v143 offset:16512
	ds_read_b64_tr_b16 v[12:13], v144 offset:24704
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_fmac_f32_e32 v246, 0x3fb8aa3b, v163
	v_exp_f32_e32 v159, v237
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[50:53], v[74:77], v[98:101], v[50:53]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[10:11], v144 offset:16512
	ds_read_b64_tr_b16 v[74:75], v145 offset:16512
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v163, v240
	v_exp_f32_e32 v186, v242
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[58:61], v[70:73], v[98:101], v[58:61]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[76:77], v145 offset:24704
	ds_read_b64_tr_b16 v[70:71], v142 offset:16640
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v249, 0, v148, s[46:47]
	v_cndmask_b32_e64 v109, 0, v149, s[14:15]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[10:13], v[98:101], v[34:37]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[72:73], v142 offset:24832
	ds_read_b64_tr_b16 v[10:11], v143 offset:16640
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v108, 0, v149, s[20:21]
	v_cndmask_b32_e64 v107, 0, v149, s[24:25]
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[30:33], v[78:81], v[102:105], v[30:33]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_fmac_f32_e32 v249, 0x3fb8aa3b, v166
	v_ldexp_f32 v166, v159, v109
	v_ldexp_f32 v163, v163, v108
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[74:77], v[98:101], v[38:41]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[12:13], v143 offset:24832
	ds_read_b64_tr_b16 v[74:75], v144 offset:24832
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_ldexp_f32 v159, v186, v107
	v_exp_f32_e32 v224, v245
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[70:73], v[98:101], v[30:33]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[72:73], v144 offset:16640
	ds_read_b64_tr_b16 v[76:77], v145 offset:16640
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v226, v246
	v_exp_f32_e32 v228, v247
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[10:13], v[98:101], v[26:29]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[78:79], v145 offset:24832
	ds_read_b64_tr_b16 v[10:11], v142 offset:16768
	ds_read_b64_tr_b16 v[12:13], v142 offset:24960
	ds_read_b64_tr_b16 v[70:71], v143 offset:16768
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v232, v249
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[14:17], v[82:85], v[102:105], v[14:17]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[82:83], v142 offset:32768
	ds_read_b64_tr_b16 v[84:85], v142 offset:40960
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v234, v250
	v_exp_f32_e32 v235, v251
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_bf16 v[18:21], v[76:79], v[98:101], v[18:21]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_exp_f32_e32 v236, v252
	v_cndmask_b32_e64 v112, 0, v149, s[30:31]
	v_cndmask_b32_e64 v113, 0, v149, s[36:37]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[10:13], v[10:13], v[98:101], v[14:17]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[76:77], v144 offset:24960
	s_nop 1
	ds_read_b64_tr_b16 v[14:15], v145 offset:16768
	ds_read_b64_tr_b16 v[16:17], v145 offset:24960
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v138, 0, v149, s[40:41]
	v_cndmask_b32_e64 v139, 0, v149, s[46:47]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[78:81], v[14:17], v[98:101], v[2:5]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v140, 0, v149, s[42:43]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_nop 1
	ds_read_b64_tr_b16 v[2:3], v143 offset:40960
	ds_read_b64_tr_b16 v[4:5], v144 offset:32768
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[22:25], v[72:75], v[98:101], v[22:25]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[72:73], v143 offset:24960
	ds_read_b64_tr_b16 v[74:75], v144 offset:16768
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_cndmask_b32_e64 v141, 0, v149, s[38:39]
	v_cndmask_b32_e64 v121, 0, v149, s[34:35]
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[6:9], v[94:97], v[102:105], v[6:9]
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_ldexp_f32 v150, v224, v112
	v_ldexp_f32 v151, v226, v113
	v_ldexp_f32 v152, v228, v138
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[74:77], v[74:77], v[98:101], v[6:9]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_nop 2
	ds_read_b64_tr_b16 v[6:7], v144 offset:40960
	ds_read_b64_tr_b16 v[14:15], v145 offset:32768
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_ldexp_f32 v154, v232, v139
	v_ldexp_f32 v155, v234, v140
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[66:69], v[70:73], v[98:101], v[66:69]
	.loc	1 687 21                        ; extend_attention.py:687:21
	v_cvt_pk_bf16_f32 v70, v166, v164
	v_cvt_pk_bf16_f32 v71, v162, v163
	v_cvt_pk_bf16_f32 v72, v161, v159
	v_cvt_pk_bf16_f32 v73, v160, v158
	.loc	1 676 23                        ; extend_attention.py:676:23
	v_ldexp_f32 v156, v235, v141
	v_ldexp_f32 v157, v236, v121
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[54:57], v[0:3], v[70:73], v[54:57]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[16:17], v145 offset:40960
	ds_read_b64_tr_b16 v[0:1], v142 offset:32896
	.loc	1 687 21                        ; extend_attention.py:687:21
	v_cvt_pk_bf16_f32 v94, v150, v151
	v_cvt_pk_bf16_f32 v95, v152, v153
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[4:7], v[70:73], v[42:45]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[2:3], v142 offset:41088
	ds_read_b64_tr_b16 v[6:7], v143 offset:41088
	.loc	1 687 21                        ; extend_attention.py:687:21
	v_cvt_pk_bf16_f32 v96, v154, v155
	v_cvt_pk_bf16_f32 v97, v156, v157
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[14:17], v[70:73], v[46:49]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[4:5], v143 offset:32896
	ds_read_b64_tr_b16 v[16:17], v144 offset:41088
	ds_read_b64_tr_b16 v[98:99], v143 offset:49280
	ds_read_b64_tr_b16 v[102:103], v143 offset:49408
	ds_read_b64_tr_b16 v[106:107], v143 offset:49536
	v_mov_b64_e32 v[252:253], v[188:189]
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[62:65], v[82:85], v[70:73], v[62:65]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[82:85], v[0:3], v[70:73], v[50:53]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[14:15], v144 offset:32896
	ds_read_b64_tr_b16 v[0:1], v145 offset:32896
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[86:89], v[4:7], v[70:73], v[58:61]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[2:3], v145 offset:41088
	ds_read_b64_tr_b16 v[4:5], v142 offset:33024
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[14:17], v[70:73], v[34:37]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[6:7], v142 offset:41216
	ds_read_b64_tr_b16 v[14:15], v143 offset:33024
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[90:93], v[0:3], v[70:73], v[38:41]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[16:17], v143 offset:41216
	s_nop 1
	ds_read_b64_tr_b16 v[40:41], v144 offset:41216
.Ltmp65:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v180, v181
	v_add_f32_e32 v0, v179, v0
.Ltmp66:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[6:9], v[4:7], v[70:73], v[30:33]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[38:39], v144 offset:33024
	s_nop 1
	ds_read_b64_tr_b16 v[30:31], v145 offset:33024
	ds_read_b64_tr_b16 v[32:33], v145 offset:41216
.Ltmp67:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v177, v0
	v_add_f32_e32 v0, v178, v0
.Ltmp68:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[14:17], v[70:73], v[26:29]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_nop 2
	ds_read_b64_tr_b16 v[26:27], v142 offset:33152
	ds_read_b64_tr_b16 v[28:29], v142 offset:41344
	ds_read_b64_tr_b16 v[50:51], v143 offset:33152
.Ltmp69:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v176, v0
	v_add_f32_e32 v0, v174, v0
.Ltmp70:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_bf16 v[14:17], v[38:41], v[70:73], v[22:25]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[52:53], v143 offset:41344
	s_nop 1
	ds_read_b64_tr_b16 v[22:23], v144 offset:33152
	ds_read_b64_tr_b16 v[24:25], v144 offset:41344
.Ltmp71:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v175, v0
	v_mov_b64_e32 v[174:175], v[196:197]
.Ltmp72:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[18:21], v[30:33], v[70:73], v[18:21]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[30:31], v145 offset:33152
	ds_read_b64_tr_b16 v[32:33], v145 offset:41344
	v_mov_b64_e32 v[176:177], v[198:199]
	v_mov_b64_e32 v[196:197], v[204:205]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[10:13], v[26:29], v[70:73], v[10:13]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[26:27], v142 offset:49152
	ds_read_b64_tr_b16 v[28:29], v142 offset:57344
	ds_read_b64_tr_b16 v[38:39], v142 offset:49280
	v_mov_b64_e32 v[198:199], v[206:207]
	v_mov_b64_e32 v[204:205], v[212:213]
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_bf16 v[66:69], v[50:53], v[70:73], v[66:69]
	v_mov_b64_e32 v[206:207], v[214:215]
	scratch_load_dwordx4 v[212:215], off, off ; 16-byte Folded Reload
.Ltmp73:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v173, v0
.Ltmp74:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_bf16 v[74:77], v[22:25], v[70:73], v[74:77]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[22:23], v142 offset:49408
	ds_read_b64_tr_b16 v[50:51], v143 offset:49152
	ds_read_b64_tr_b16 v[52:53], v143 offset:57344
.Ltmp75:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v171, v0
	v_add_f32_e32 v0, v172, v0
.Ltmp76:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[70:73], v[30:33], v[70:73], v[78:81]
	.loc	1 685 16                        ; extend_attention.py:685:16
	s_nop 2
	ds_read_b64_tr_b16 v[78:79], v142 offset:49536
	ds_read_b64_tr_b16 v[30:31], v144 offset:49152
	ds_read_b64_tr_b16 v[32:33], v144 offset:57344
	ds_read_b64_tr_b16 v[24:25], v142 offset:57600
	ds_read_b64_tr_b16 v[80:81], v142 offset:57728
	ds_read_b64_tr_b16 v[100:101], v143 offset:57472
.Ltmp77:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v170, v0
.Ltmp78:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[62:65], v[26:29], v[94:97], v[62:65]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[40:41], v142 offset:57472
	ds_read_b64_tr_b16 v[26:27], v145 offset:49152
	ds_read_b64_tr_b16 v[28:29], v145 offset:57344
.Ltmp79:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v168, v0
	v_add_f32_e32 v0, v169, v0
.Ltmp80:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(9)
	v_mfma_f32_16x16x32_bf16 v[54:57], v[50:53], v[94:97], v[54:57]
.Ltmp81:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v167, v0
	v_add_f32_e32 v0, v165, v0
	v_add_f32_e32 v0, v166, v0
.Ltmp82:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[58:61], v[30:33], v[94:97], v[42:45]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[108:109], v143 offset:57728
	ds_read_b64_tr_b16 v[30:31], v145 offset:49280
	ds_read_b64_tr_b16 v[32:33], v145 offset:57472
.Ltmp83:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v164, v0
	v_add_f32_e32 v0, v162, v0
.Ltmp84:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[50:53], v[26:29], v[94:97], v[46:49]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[104:105], v143 offset:57600
	ds_read_b64_tr_b16 v[28:29], v144 offset:57472
	ds_read_b64_tr_b16 v[26:27], v144 offset:49280
.Ltmp85:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v163, v0
	v_add_f32_e32 v0, v161, v0
.Ltmp86:
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[46:49], v[38:41], v[94:97], v[82:85]
.Ltmp87:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v159, v0
	v_add_f32_e32 v0, v160, v0
	v_add_f32_e32 v0, v158, v0
.Ltmp88:
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[42:45], v[98:101], v[94:97], v[86:89]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[84:85], v144 offset:57600
	ds_read_b64_tr_b16 v[82:83], v144 offset:49408
	s_nop 0
	ds_read_b64_tr_b16 v[86:87], v144 offset:49536
.Ltmp89:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v150, v0
	v_add_f32_e32 v0, v151, v0
.Ltmp90:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[26:29], v[94:97], v[34:37]
.Ltmp91:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v152, v0
	v_add_f32_e32 v0, v153, v0
	v_add_f32_e32 v0, v154, v0
.Ltmp92:
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[34:37], v[30:33], v[94:97], v[90:93]
.Ltmp93:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v155, v0
	v_add_f32_e32 v0, v156, v0
.Ltmp94:
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[88:89], v144 offset:57728
	ds_read_b64_tr_b16 v[98:99], v145 offset:49408
	ds_read_b64_tr_b16 v[112:113], v145 offset:49536
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[30:33], v[22:25], v[94:97], v[6:9]
	.loc	1 685 16                        ; extend_attention.py:685:16
	ds_read_b64_tr_b16 v[100:101], v145 offset:57600
	ds_read_b64_tr_b16 v[114:115], v145 offset:57728
.Ltmp95:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v157, v0
.Ltmp96:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:677:47 ]
	v_mov_b32_e32 v1, v0
.Ltmp97:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[22:25], v[82:85], v[94:97], v[14:17]
	scratch_load_dwordx2 v[84:85], off, off offset:16 ; 8-byte Folded Reload
.Ltmp98:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:677:47 ]
	v_permlane32_swap_b32_e32 v0, v1
.Ltmp99:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	v_add_f32_e32 v0, v0, v1
.Ltmp100:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:677:47 ]
	v_mov_b32_e32 v1, v0
.Ltmp101:
	.loc	1 688 54                        ; extend_attention.py:688:54
	v_mfma_f32_16x16x32_bf16 v[26:29], v[102:105], v[94:97], v[2:5]
	v_mov_b64_e32 v[170:171], v[200:201]
.Ltmp102:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:677:47 ]
	v_permlane16_swap_b32_e32 v0, v1
.Ltmp103:
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[18:21], v[98:101], v[94:97], v[18:21]
	v_mov_b64_e32 v[172:173], v[202:203]
	v_mov_b64_e32 v[200:201], v[208:209]
	v_mov_b64_e32 v[202:203], v[210:211]
	v_mfma_f32_16x16x32_bf16 v[14:17], v[78:81], v[94:97], v[10:13]
	v_mov_b64_e32 v[208:209], v[216:217]
	v_mov_b64_e32 v[210:211], v[218:219]
	v_mfma_f32_16x16x32_bf16 v[10:13], v[106:109], v[94:97], v[66:69]
	v_mfma_f32_16x16x32_bf16 v[6:9], v[86:89], v[94:97], v[74:77]
.Ltmp104:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:677:47 ] ]
	s_nop 1
	v_add_f32_e32 v66, v0, v1
.Ltmp105:
	.loc	1 677 37                        ; extend_attention.py:677:37
	v_fmac_f32_e32 v66, v123, v118
	v_mov_b32_e32 v1, v194
	.loc	1 688 54                        ; extend_attention.py:688:54
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[112:115], v[94:97], v[70:73]
	v_mov_b32_e32 v123, v66
	.loc	1 595 45                        ; extend_attention.py:595:45
	s_cbranch_vccnz .LBB0_24
; %bb.25:                               ; %Flow
	.loc	1 0 45 is_stmt 0                ; extend_attention.py:0:45
	scratch_load_dword v109, off, off offset:88 ; 4-byte Folded Reload
	scratch_load_dwordx2 v[120:121], off, off offset:64 ; 8-byte Folded Reload
	scratch_load_dword v112, off, off offset:76 ; 4-byte Folded Reload
	scratch_load_dword v114, off, off offset:80 ; 4-byte Folded Reload
	scratch_load_dword v119, off, off offset:72 ; 4-byte Folded Reload
	scratch_load_dwordx2 v[106:107], off, off offset:56 ; 8-byte Folded Reload
	scratch_load_dword v0, off, off offset:84 ; 4-byte Folded Reload
	v_mov_b32_e32 v123, v66
	v_readlane_b32 s99, v255, 0
.LBB0_26:                               ; %._crit_edge35
	.loc	1 452 26 is_stmt 1              ; extend_attention.py:452:26
	s_waitcnt vmcnt(4)
	v_lshrrev_b32_e32 v1, 5, v112
	.loc	1 450 26                        ; extend_attention.py:450:26
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v0, 0xf8, v0
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_or_b32_e32 v89, 16, v1
	.loc	1 699 21                        ; extend_attention.py:699:21
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s0, s49, s99
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_or_b32_e32 v88, 32, v1
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_add_u32_e32 v82, s0, v0
	v_add_u32_e32 v0, v89, v106
	.loc	1 452 26                        ; extend_attention.py:452:26
	v_or_b32_e32 v83, 0x70, v1
	v_or_b32_e32 v84, 0x60, v1
	v_or_b32_e32 v85, 0x50, v1
	v_or_b32_e32 v86, 64, v1
	v_or_b32_e32 v87, 48, v1
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v78, s88, v89
	v_or_b32_e32 v80, s88, v1
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_add_u32_e32 v1, v1, v106
	v_mul_lo_u32 v89, v0, s48
	v_add_u32_e32 v0, v88, v106
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v76, s88, v88
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_mul_lo_u32 v90, v1, s48
	v_mul_lo_u32 v88, v0, s48
	v_add_u32_e32 v0, v87, v106
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_div_scale_f32 v1, s[0:1], v123, v123, v62
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v74, s88, v87
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_mul_lo_u32 v87, v0, s48
	v_add_u32_e32 v0, v86, v106
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_rcp_f32_e32 v91, v1
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v72, s88, v86
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_mul_lo_u32 v86, v0, s48
	v_add_u32_e32 v0, v85, v106
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v70, s88, v85
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_mul_lo_u32 v85, v0, s48
	v_add_u32_e32 v0, v84, v106
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v68, s88, v84
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_mul_lo_u32 v84, v0, s48
	v_add_u32_e32 v0, v83, v106
	.loc	1 453 38                        ; extend_attention.py:453:38
	v_or_b32_e32 v66, s88, v83
	.loc	1 704 23                        ; extend_attention.py:704:23
	v_mul_lo_u32 v83, v0, s48
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v91, 1.0
	v_fmac_f32_e32 v91, v0, v91
	v_div_scale_f32 v0, vcc, v62, v123, v62
	v_mul_f32_e32 v92, v0, v91
	v_fma_f32 v93, -v1, v92, v0
	v_fmac_f32_e32 v92, v93, v91
	v_fma_f32 v0, -v1, v92, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v63
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v91, v92
	v_div_fixup_f32 v62, v0, v123, v62
	.loc	1 705 12 is_stmt 0              ; extend_attention.py:705:12
	s_waitcnt lgkmcnt(0)
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v63, v123, v63
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v64
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v63, v0, v123, v63
	.loc	1 705 12                        ; extend_attention.py:705:12
	s_barrier
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v64, v123, v64
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v65
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v64, v0, v123, v64
	.loc	1 453 48 is_stmt 1              ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v81, 31, v80
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v65, v123, v65
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v54
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v65, v0, v123, v65
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v79, 31, v78
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v54, v123, v54
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v55
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v54, v0, v123, v54
	.loc	1 705 12 is_stmt 0              ; extend_attention.py:705:12
	s_and_b32 s9, s9, 0xffff
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v55, v123, v55
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v56
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v55, v0, v123, v55
	s_mov_b32 s11, 0x27000
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v56, v123, v56
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v57
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v56, v0, v123, v56
	s_mov_b32 s10, 0x7ffffffe
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v57, v123, v57
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v58
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v57, v0, v123, v57
	.loc	1 453 48 is_stmt 1              ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v77, 31, v76
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v58, v123, v58
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v59
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v58, v0, v123, v58
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v75, 31, v74
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v59, v123, v59
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v60
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v59, v0, v123, v59
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v73, 31, v72
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v60, v123, v60
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v61
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v60, v0, v123, v60
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v71, 31, v70
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v61, v123, v61
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v50
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v61, v0, v123, v61
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v69, 31, v68
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v50, v123, v50
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v51
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v50, v0, v123, v50
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_ashrrev_i32_e32 v67, 31, v66
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v51, v123, v51
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v52
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v51, v0, v123, v51
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v52, v123, v52
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v53
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v52, v0, v123, v52
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v53, v123, v53
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v46
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v53, v0, v123, v53
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v46, v123, v46
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v47
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v46, v0, v123, v46
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v47, v123, v47
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v48
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v47, v0, v123, v47
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v48, v123, v48
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v49
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v48, v0, v123, v48
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v49, v123, v49
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v42
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v49, v0, v123, v49
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v42, v123, v42
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v43
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v42, v0, v123, v42
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v43, v123, v43
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v44
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v43, v0, v123, v43
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v44, v123, v44
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v45
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v44, v0, v123, v44
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v45, v123, v45
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v38
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v45, v0, v123, v45
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v38, v123, v38
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v39
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v38, v0, v123, v38
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v39, v123, v39
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v40
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v39, v0, v123, v39
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v40, v123, v40
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v41
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v40, v0, v123, v40
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v41, v123, v41
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v34
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v41, v0, v123, v41
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v34, v123, v34
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v35
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v34, v0, v123, v34
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v35, v123, v35
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v36
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v35, v0, v123, v35
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v36, v123, v36
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v37
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v36, v0, v123, v36
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v37, v123, v37
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v30
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v37, v0, v123, v37
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v30, v123, v30
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v31
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v30, v0, v123, v30
	v_fma_f32 v0, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v0, v93
	v_div_scale_f32 v0, vcc, v31, v123, v31
	v_mul_f32_e32 v91, v0, v93
	v_fma_f32 v92, -v1, v91, v0
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v32
	v_rcp_f32_e32 v92, v1
	v_div_fmas_f32 v0, v0, v93, v91
	v_div_fixup_f32 v31, v0, v123, v31
	v_fma_f32 v0, -v1, v92, 1.0
	v_fmac_f32_e32 v92, v0, v92
	v_div_scale_f32 v0, vcc, v32, v123, v32
	v_mul_f32_e32 v91, v0, v92
	v_fma_f32 v93, -v1, v91, v0
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v0, -v1, v91, v0
	v_div_scale_f32 v1, s[0:1], v123, v123, v33
	v_rcp_f32_e32 v93, v1
	v_div_fmas_f32 v0, v0, v92, v91
	v_div_fixup_f32 v0, v0, v123, v32
	v_fma_f32 v32, -v1, v93, 1.0
	v_fmac_f32_e32 v93, v32, v93
	v_div_scale_f32 v32, vcc, v33, v123, v33
	v_mul_f32_e32 v91, v32, v93
	v_fma_f32 v92, -v1, v91, v32
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v1, -v1, v91, v32
	v_div_scale_f32 v32, s[0:1], v123, v123, v26
	v_rcp_f32_e32 v92, v32
	v_div_fmas_f32 v1, v1, v93, v91
	v_div_fixup_f32 v1, v1, v123, v33
	v_fma_f32 v33, -v32, v92, 1.0
	v_fmac_f32_e32 v92, v33, v92
	v_div_scale_f32 v33, vcc, v26, v123, v26
	v_mul_f32_e32 v91, v33, v92
	v_fma_f32 v93, -v32, v91, v33
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v32, -v32, v91, v33
	v_div_scale_f32 v33, s[0:1], v123, v123, v27
	v_rcp_f32_e32 v93, v33
	v_div_fmas_f32 v32, v32, v92, v91
	v_div_fixup_f32 v26, v32, v123, v26
	v_fma_f32 v32, -v33, v93, 1.0
	v_fmac_f32_e32 v93, v32, v93
	v_div_scale_f32 v32, vcc, v27, v123, v27
	v_mul_f32_e32 v91, v32, v93
	v_fma_f32 v92, -v33, v91, v32
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v28
	v_rcp_f32_e32 v92, v33
	v_div_fmas_f32 v32, v32, v93, v91
	v_div_fixup_f32 v27, v32, v123, v27
	v_fma_f32 v32, -v33, v92, 1.0
	v_fmac_f32_e32 v92, v32, v92
	v_div_scale_f32 v32, vcc, v28, v123, v28
	v_mul_f32_e32 v91, v32, v92
	v_fma_f32 v93, -v33, v91, v32
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v29
	v_rcp_f32_e32 v93, v33
	v_div_fmas_f32 v32, v32, v92, v91
	v_div_fixup_f32 v28, v32, v123, v28
	v_fma_f32 v32, -v33, v93, 1.0
	v_fmac_f32_e32 v93, v32, v93
	v_div_scale_f32 v32, vcc, v29, v123, v29
	v_mul_f32_e32 v91, v32, v93
	v_fma_f32 v92, -v33, v91, v32
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v22
	v_rcp_f32_e32 v92, v33
	v_div_fmas_f32 v32, v32, v93, v91
	v_div_fixup_f32 v29, v32, v123, v29
	v_fma_f32 v32, -v33, v92, 1.0
	v_fmac_f32_e32 v92, v32, v92
	v_div_scale_f32 v32, vcc, v22, v123, v22
	v_mul_f32_e32 v91, v32, v92
	v_fma_f32 v93, -v33, v91, v32
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v23
	v_rcp_f32_e32 v93, v33
	v_div_fmas_f32 v32, v32, v92, v91
	v_div_fixup_f32 v22, v32, v123, v22
	v_fma_f32 v32, -v33, v93, 1.0
	v_fmac_f32_e32 v93, v32, v93
	v_div_scale_f32 v32, vcc, v23, v123, v23
	v_mul_f32_e32 v91, v32, v93
	v_fma_f32 v92, -v33, v91, v32
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v24
	v_rcp_f32_e32 v92, v33
	v_div_fmas_f32 v32, v32, v93, v91
	v_div_fixup_f32 v23, v32, v123, v23
	.loc	1 705 12 is_stmt 0              ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v22, v22, v23
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v32, -v33, v92, 1.0
	v_fmac_f32_e32 v92, v32, v92
	v_div_scale_f32 v32, vcc, v24, v123, v24
	v_mul_f32_e32 v91, v32, v92
	v_fma_f32 v93, -v33, v91, v32
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v25
	v_rcp_f32_e32 v93, v33
	v_div_fmas_f32 v32, v32, v92, v91
	v_div_fixup_f32 v24, v32, v123, v24
	v_fma_f32 v32, -v33, v93, 1.0
	v_fmac_f32_e32 v93, v32, v93
	v_div_scale_f32 v32, vcc, v25, v123, v25
	v_mul_f32_e32 v91, v32, v93
	v_fma_f32 v92, -v33, v91, v32
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v18
	v_rcp_f32_e32 v92, v33
	v_div_fmas_f32 v32, v32, v93, v91
	v_div_fixup_f32 v25, v32, v123, v25
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v23, v24, v25
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v32, -v33, v92, 1.0
	v_fmac_f32_e32 v92, v32, v92
	v_div_scale_f32 v32, vcc, v18, v123, v18
	v_mul_f32_e32 v91, v32, v92
	v_fma_f32 v93, -v33, v91, v32
	v_fmac_f32_e32 v91, v93, v92
	v_fma_f32 v32, -v33, v91, v32
	v_div_scale_f32 v33, s[0:1], v123, v123, v19
	v_rcp_f32_e32 v93, v33
	v_div_fmas_f32 v32, v32, v92, v91
	v_div_fixup_f32 v32, v32, v123, v18
	v_fma_f32 v18, -v33, v93, 1.0
	v_fmac_f32_e32 v93, v18, v93
	v_div_scale_f32 v18, vcc, v19, v123, v19
	v_mul_f32_e32 v91, v18, v93
	v_fma_f32 v92, -v33, v91, v18
	v_fmac_f32_e32 v91, v92, v93
	v_fma_f32 v18, -v33, v91, v18
	v_div_scale_f32 v33, s[0:1], v123, v123, v20
	v_rcp_f32_e32 v92, v33
	v_div_fmas_f32 v18, v18, v93, v91
	v_div_fixup_f32 v91, v18, v123, v19
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v24, v32, v91
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v18, -v33, v92, 1.0
	v_fmac_f32_e32 v92, v18, v92
	v_div_scale_f32 v18, vcc, v20, v123, v20
	v_mul_f32_e32 v19, v18, v92
	v_fma_f32 v93, -v33, v19, v18
	v_fmac_f32_e32 v19, v93, v92
	v_fma_f32 v18, -v33, v19, v18
	v_div_scale_f32 v33, s[0:1], v123, v123, v21
	v_rcp_f32_e32 v93, v33
	v_div_fmas_f32 v18, v18, v92, v19
	v_div_fixup_f32 v92, v18, v123, v20
	v_fma_f32 v18, -v33, v93, 1.0
	v_fmac_f32_e32 v93, v18, v93
	v_div_scale_f32 v18, vcc, v21, v123, v21
	v_mul_f32_e32 v19, v18, v93
	v_fma_f32 v20, -v33, v19, v18
	v_fmac_f32_e32 v19, v20, v93
	v_div_scale_f32 v20, s[0:1], v123, v123, v14
	v_fma_f32 v18, -v33, v19, v18
	v_rcp_f32_e32 v33, v20
	v_div_fmas_f32 v18, v18, v93, v19
	v_div_fixup_f32 v93, v18, v123, v21
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v25, v92, v93
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v18, -v20, v33, 1.0
	v_fmac_f32_e32 v33, v18, v33
	v_div_scale_f32 v18, vcc, v14, v123, v14
	v_mul_f32_e32 v19, v18, v33
	v_fma_f32 v21, -v20, v19, v18
	v_fmac_f32_e32 v19, v21, v33
	v_fma_f32 v18, -v20, v19, v18
	v_div_scale_f32 v20, s[0:1], v123, v123, v15
	v_rcp_f32_e32 v21, v20
	v_div_fmas_f32 v18, v18, v33, v19
	v_div_fixup_f32 v33, v18, v123, v14
	v_fma_f32 v14, -v20, v21, 1.0
	v_fmac_f32_e32 v21, v14, v21
	v_div_scale_f32 v14, vcc, v15, v123, v15
	v_mul_f32_e32 v18, v14, v21
	v_fma_f32 v19, -v20, v18, v14
	v_fmac_f32_e32 v18, v19, v21
	v_div_scale_f32 v19, s[0:1], v123, v123, v16
	v_fma_f32 v14, -v20, v18, v14
	v_rcp_f32_e32 v20, v19
	v_div_fmas_f32 v14, v14, v21, v18
	v_div_fixup_f32 v94, v14, v123, v15
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v21, v28, v29
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v14, -v19, v20, 1.0
	v_fmac_f32_e32 v20, v14, v20
	v_div_scale_f32 v14, vcc, v16, v123, v16
	v_mul_f32_e32 v15, v14, v20
	v_fma_f32 v18, -v19, v15, v14
	v_fmac_f32_e32 v15, v18, v20
	v_div_scale_f32 v18, s[0:1], v123, v123, v17
	v_fma_f32 v14, -v19, v15, v14
	v_rcp_f32_e32 v19, v18
	v_div_fmas_f32 v14, v14, v20, v15
	v_div_fixup_f32 v95, v14, v123, v16
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v20, v26, v27
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v14, -v18, v19, 1.0
	v_fmac_f32_e32 v19, v14, v19
	v_div_scale_f32 v14, vcc, v17, v123, v17
	v_mul_f32_e32 v15, v14, v19
	v_fma_f32 v16, -v18, v15, v14
	v_fmac_f32_e32 v15, v16, v19
	v_div_scale_f32 v16, s[0:1], v123, v123, v10
	v_fma_f32 v14, -v18, v15, v14
	v_rcp_f32_e32 v18, v16
	v_div_fmas_f32 v14, v14, v19, v15
	v_div_fixup_f32 v96, v14, v123, v17
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v19, v0, v1
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v14, -v16, v18, 1.0
	v_fmac_f32_e32 v18, v14, v18
	v_div_scale_f32 v14, vcc, v10, v123, v10
	v_mul_f32_e32 v15, v14, v18
	v_fma_f32 v17, -v16, v15, v14
	v_fmac_f32_e32 v15, v17, v18
	v_fma_f32 v14, -v16, v15, v14
	v_div_scale_f32 v16, s[0:1], v123, v123, v11
	v_rcp_f32_e32 v17, v16
	v_div_fmas_f32 v14, v14, v18, v15
	v_div_fixup_f32 v97, v14, v123, v10
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_lshl_or_b32 v0, v114, 10, v119
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v10, -v16, v17, 1.0
	v_fmac_f32_e32 v17, v10, v17
	v_div_scale_f32 v10, vcc, v11, v123, v11
	v_mul_f32_e32 v14, v10, v17
	v_fma_f32 v15, -v16, v14, v10
	v_fmac_f32_e32 v14, v15, v17
	v_div_scale_f32 v15, s[0:1], v123, v123, v12
	v_fma_f32 v10, -v16, v14, v10
	v_rcp_f32_e32 v16, v15
	v_div_fmas_f32 v10, v10, v17, v14
	v_div_fixup_f32 v98, v10, v123, v11
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v17, v36, v37
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v10, -v15, v16, 1.0
	v_fmac_f32_e32 v16, v10, v16
	v_div_scale_f32 v10, vcc, v12, v123, v12
	v_mul_f32_e32 v11, v10, v16
	v_fma_f32 v14, -v15, v11, v10
	v_fmac_f32_e32 v11, v14, v16
	v_div_scale_f32 v14, s[0:1], v123, v123, v13
	v_fma_f32 v10, -v15, v11, v10
	v_rcp_f32_e32 v15, v14
	v_div_fmas_f32 v10, v10, v16, v11
	v_div_fixup_f32 v99, v10, v123, v12
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v16, v34, v35
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v10, -v14, v15, 1.0
	v_fmac_f32_e32 v15, v10, v15
	v_div_scale_f32 v10, vcc, v13, v123, v13
	v_mul_f32_e32 v11, v10, v15
	v_fma_f32 v12, -v14, v11, v10
	v_fmac_f32_e32 v11, v12, v15
	v_div_scale_f32 v12, s[0:1], v123, v123, v6
	v_fma_f32 v10, -v14, v11, v10
	v_rcp_f32_e32 v14, v12
	v_div_fmas_f32 v10, v10, v15, v11
	v_div_fixup_f32 v100, v10, v123, v13
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v15, v40, v41
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v10, -v12, v14, 1.0
	v_fmac_f32_e32 v14, v10, v14
	v_div_scale_f32 v10, vcc, v6, v123, v6
	v_mul_f32_e32 v11, v10, v14
	v_fma_f32 v13, -v12, v11, v10
	v_fmac_f32_e32 v11, v13, v14
	v_fma_f32 v10, -v12, v11, v10
	v_div_scale_f32 v12, s[0:1], v123, v123, v7
	v_rcp_f32_e32 v13, v12
	v_div_fmas_f32 v10, v10, v14, v11
	v_div_fixup_f32 v101, v10, v123, v6
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v14, v38, v39
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v6, -v12, v13, 1.0
	v_fmac_f32_e32 v13, v6, v13
	v_div_scale_f32 v6, vcc, v7, v123, v7
	v_mul_f32_e32 v10, v6, v13
	v_fma_f32 v11, -v12, v10, v6
	v_fmac_f32_e32 v10, v11, v13
	v_div_scale_f32 v11, s[0:1], v123, v123, v8
	v_fma_f32 v6, -v12, v10, v6
	v_rcp_f32_e32 v12, v11
	v_div_fmas_f32 v6, v6, v13, v10
	v_div_fixup_f32 v102, v6, v123, v7
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v13, v44, v45
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v6, -v11, v12, 1.0
	v_fmac_f32_e32 v12, v6, v12
	v_div_scale_f32 v6, vcc, v8, v123, v8
	v_mul_f32_e32 v7, v6, v12
	v_fma_f32 v10, -v11, v7, v6
	v_fmac_f32_e32 v7, v10, v12
	v_div_scale_f32 v10, s[0:1], v123, v123, v9
	v_fma_f32 v6, -v11, v7, v6
	v_rcp_f32_e32 v11, v10
	v_div_fmas_f32 v6, v6, v12, v7
	v_div_fixup_f32 v103, v6, v123, v8
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v12, v42, v43
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v6, -v10, v11, 1.0
	v_fmac_f32_e32 v11, v6, v11
	v_div_scale_f32 v6, vcc, v9, v123, v9
	v_mul_f32_e32 v7, v6, v11
	v_fma_f32 v8, -v10, v7, v6
	v_fmac_f32_e32 v7, v8, v11
	v_div_scale_f32 v8, s[0:1], v123, v123, v2
	v_fma_f32 v6, -v10, v7, v6
	v_rcp_f32_e32 v10, v8
	v_div_fmas_f32 v6, v6, v11, v7
	v_div_fixup_f32 v104, v6, v123, v9
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v11, v48, v49
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v6, -v8, v10, 1.0
	v_fmac_f32_e32 v10, v6, v10
	v_div_scale_f32 v6, vcc, v2, v123, v2
	v_mul_f32_e32 v7, v6, v10
	v_fma_f32 v9, -v8, v7, v6
	v_fmac_f32_e32 v7, v9, v10
	v_fma_f32 v6, -v8, v7, v6
	v_div_scale_f32 v8, s[0:1], v123, v123, v3
	v_rcp_f32_e32 v9, v8
	v_div_fmas_f32 v6, v6, v10, v7
	v_div_fixup_f32 v105, v6, v123, v2
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v10, v46, v47
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v2, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v2, v9
	v_div_scale_f32 v2, vcc, v3, v123, v3
	v_mul_f32_e32 v6, v2, v9
	v_fma_f32 v7, -v8, v6, v2
	v_fmac_f32_e32 v6, v7, v9
	v_div_scale_f32 v7, s[0:1], v123, v123, v4
	v_fma_f32 v2, -v8, v6, v2
	v_rcp_f32_e32 v8, v7
	v_div_fmas_f32 v2, v2, v9, v6
	v_div_fixup_f32 v106, v2, v123, v3
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v9, v52, v53
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v2, -v7, v8, 1.0
	v_fmac_f32_e32 v8, v2, v8
	v_div_scale_f32 v2, vcc, v4, v123, v4
	v_mul_f32_e32 v3, v2, v8
	v_fma_f32 v6, -v7, v3, v2
	v_fmac_f32_e32 v3, v6, v8
	v_div_scale_f32 v6, s[0:1], v123, v123, v5
	v_fma_f32 v2, -v7, v3, v2
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v2, v2, v8, v3
	v_div_fixup_f32 v107, v2, v123, v4
	.loc	1 705 12                        ; extend_attention.py:705:12
	s_lshl_b32 s0, s96, 1
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_fma_f32 v2, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v2, v7
	v_div_scale_f32 v2, vcc, v5, v123, v5
	v_mul_f32_e32 v3, v2, v7
	v_fma_f32 v4, -v6, v3, v2
	v_fmac_f32_e32 v3, v4, v7
	v_fma_f32 v2, -v6, v3, v2
	v_div_fmas_f32 v2, v2, v7, v3
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_or_b32_e32 v1, s0, v0
	.loc	1 705 19                        ; extend_attention.py:705:19
	v_div_fixup_f32 v108, v2, v123, v5
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_cvt_pk_bf16_f32 v2, v62, v63
	v_cvt_pk_bf16_f32 v3, v64, v65
	v_add_u32_e32 v34, 0, v1
	v_cvt_pk_bf16_f32 v4, v54, v55
	v_cvt_pk_bf16_f32 v5, v56, v57
	ds_write_b64 v34, v[2:3]
	v_xad_u32 v2, v1, 8, 0
	v_cvt_pk_bf16_f32 v6, v58, v59
	v_cvt_pk_bf16_f32 v7, v60, v61
	ds_write_b64 v2, v[4:5] offset:1024
	v_xad_u32 v2, v1, 16, 0
	v_cvt_pk_bf16_f32 v8, v50, v51
	ds_write_b64 v2, v[6:7] offset:2048
	v_xad_u32 v2, v1, 24, 0
	ds_write_b64 v2, v[8:9] offset:3072
	v_xad_u32 v2, v1, 32, 0
	ds_write_b64 v2, v[10:11] offset:4096
	v_xad_u32 v2, v1, 40, 0
	ds_write_b64 v2, v[12:13] offset:5120
	v_xad_u32 v2, v1, 48, 0
	v_cvt_pk_bf16_f32 v18, v30, v31
	ds_write_b64 v2, v[14:15] offset:6144
	v_xad_u32 v2, v1, 56, 0
	v_xad_u32 v1, v1, 64, 0
	ds_write_b64 v2, v[16:17] offset:7168
	ds_write_b64 v1, v[18:19] offset:8192
	v_mov_b32_e32 v1, 0x48
	v_bitop3_b32 v1, s0, v1, v0 bitop3:0x36
	v_add_u32_e32 v1, 0, v1
	ds_write_b64 v1, v[20:21] offset:9216
	v_mov_b32_e32 v1, 0x50
	v_bitop3_b32 v1, s0, v1, v0 bitop3:0x36
	v_add_u32_e32 v1, 0, v1
	ds_write_b64 v1, v[22:23] offset:10240
	v_mov_b32_e32 v1, 0x58
	v_bitop3_b32 v1, s0, v1, v0 bitop3:0x36
	v_add_u32_e32 v1, 0, v1
	ds_write_b64 v1, v[24:25] offset:11264
	v_mov_b32_e32 v1, 0x60
	v_bitop3_b32 v1, s0, v1, v0 bitop3:0x36
	v_cvt_pk_bf16_f32 v26, v33, v94
	v_cvt_pk_bf16_f32 v27, v95, v96
	v_add_u32_e32 v1, 0, v1
	ds_write_b64 v1, v[26:27] offset:12288
	v_mov_b32_e32 v1, 0x68
	v_bitop3_b32 v1, s0, v1, v0 bitop3:0x36
	v_cvt_pk_bf16_f32 v28, v97, v98
	v_cvt_pk_bf16_f32 v29, v99, v100
	v_add_u32_e32 v1, 0, v1
	ds_write_b64 v1, v[28:29] offset:13312
	v_mov_b32_e32 v1, 0x70
	v_bitop3_b32 v1, s0, v1, v0 bitop3:0x36
	v_cvt_pk_bf16_f32 v30, v101, v102
	v_cvt_pk_bf16_f32 v31, v103, v104
	v_add_u32_e32 v1, 0, v1
	ds_write_b64 v1, v[30:31] offset:14336
	v_mov_b32_e32 v1, 0x78
	v_bitop3_b32 v0, s0, v1, v0 bitop3:0x36
	v_cvt_pk_bf16_f32 v32, v105, v106
	v_cvt_pk_bf16_f32 v33, v107, v108
	v_add_u32_e32 v0, 0, v0
	ds_write_b64 v0, v[32:33] offset:15360
	v_and_b32_e32 v0, 30, v109
	s_movk_i32 s1, 0x78
	v_lshrrev_b32_e32 v1, 2, v112
	v_lshlrev_b32_e32 v2, 15, v109
	v_mul_u32_u24_e32 v0, 0x204, v0
	v_and_b32_e32 v2, 0x8000, v2
	v_bitop3_b32 v0, v1, v0, s1 bitop3:0x6c
	v_add3_u32 v4, 0, v2, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read2_b64 v[0:3], v4 offset1:16
	v_add_u32_e32 v5, 0x4000, v4
	ds_read2_b64 v[6:9], v5 offset1:16
	ds_read2_b64 v[10:13], v4 offset0:32 offset1:48
	ds_read2_b64 v[16:19], v5 offset0:32 offset1:48
	ds_read2_b64 v[20:23], v4 offset0:64 offset1:80
	ds_read2_b64 v[26:29], v5 offset0:64 offset1:80
	ds_read2_b64 v[30:33], v4 offset0:96 offset1:112
	ds_read2_b64 v[36:39], v5 offset0:96 offset1:112
	.loc	1 453 48 is_stmt 1              ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[80:81]
	.loc	1 705 12                        ; extend_attention.py:705:12
	s_waitcnt lgkmcnt(5)
	v_mov_b32_e32 v14, v10
	v_mov_b32_e32 v4, v0
	v_mov_b32_e32 v5, v1
	v_add_lshl_u32 v0, v82, v90, 1
	v_bfrev_b32_e32 v1, 1
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[4:7], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v89, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[78:79]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v4, v8
	v_mov_b32_e32 v5, v9
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[2:5], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v88, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[76:77]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v15, v11
	s_waitcnt lgkmcnt(3)
	v_mov_b32_e32 v24, v20
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[14:17], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v87, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[74:75]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v14, v18
	v_mov_b32_e32 v15, v19
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[12:15], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v86, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[72:73]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v25, v21
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v34, v30
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[24:27], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v85, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[70:71]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v24, v28
	v_mov_b32_e32 v25, v29
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[22:25], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v84, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[68:69]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v35, v31
	s_nop 0
	v_cndmask_b32_e32 v0, v1, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx4 v[34:37], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v82, v83, 1
	.loc	1 453 48                        ; extend_attention.py:453:48
	v_cmp_gt_i64_e32 vcc, v[120:121], v[66:67]
	.loc	1 705 12                        ; extend_attention.py:705:12
	v_mov_b32_e32 v34, v38
	v_mov_b32_e32 v35, v39
	v_cndmask_b32_e32 v0, v1, v0, vcc
	buffer_store_dwordx4 v[32:35], v0, s[8:11], 0 offen
	.loc	1 702 4                         ; extend_attention.py:702:4
	s_endpgm
.Ltmp106:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 96
		.amdhsa_kernarg_size 152
		.amdhsa_user_sgpr_count 16
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 14
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 256
		.amdhsa_next_free_sgpr 100
		.amdhsa_accum_offset 256
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
	.size	qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950, .Lfunc_end0-qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.num_vgpr, 256
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.num_agpr, 0
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.numbered_sgpr, 100
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.num_named_barrier, 0
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.private_seg_size, 96
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.uses_vcc, 1
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.uses_flat_scratch, 0
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.has_dyn_sized_stack, 0
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.has_recursion, 0
	.set qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 23172
; TotalNumSgprs: 106
; NumVgprs: 256
; NumAgprs: 0
; TotalNumVgprs: 256
; ScratchSize: 96
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 13
; VGPRBlocks: 31
; NumSGPRsForWavesPerEU: 106
; NumVGPRsForWavesPerEU: 256
; AccumOffset: 256
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 1
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 63
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
	.byte	5                               ; Abbreviation Code
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
	.byte	1                               ; Abbrev [1] 0xb:0xa2 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x7c DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	571                             ; DW_AT_call_line
	.byte	47                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4e:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x5c:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	565                             ; DW_AT_call_line
	.byte	33                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x69:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x76:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	671                             ; DW_AT_call_line
	.byte	33                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x83:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x90:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	677                             ; DW_AT_call_line
	.byte	47                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x9d:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
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
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
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
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp45-.Lfunc_begin0
	.quad	.Ltmp46-.Lfunc_begin0
	.quad	.Ltmp47-.Lfunc_begin0
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp49-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp51-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	.Ltmp53-.Lfunc_begin0
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.quad	.Ltmp56-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges5:
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp45-.Lfunc_begin0
	.quad	.Ltmp46-.Lfunc_begin0
	.quad	.Ltmp47-.Lfunc_begin0
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp49-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp51-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	.Ltmp53-.Lfunc_begin0
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.quad	.Ltmp56-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges6:
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp70-.Lfunc_begin0
	.quad	.Ltmp71-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp75-.Lfunc_begin0
	.quad	.Ltmp76-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	.Ltmp78-.Lfunc_begin0
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp80-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp83-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp91-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp94-.Lfunc_begin0
	.quad	.Ltmp95-.Lfunc_begin0
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp98-.Lfunc_begin0
	.quad	.Ltmp101-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp104-.Lfunc_begin0
	.quad	.Ltmp105-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp70-.Lfunc_begin0
	.quad	.Ltmp71-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp75-.Lfunc_begin0
	.quad	.Ltmp76-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	.Ltmp78-.Lfunc_begin0
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp80-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp83-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp91-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp94-.Lfunc_begin0
	.quad	.Ltmp95-.Lfunc_begin0
	.quad	.Ltmp96-.Lfunc_begin0
	.quad	.Ltmp99-.Lfunc_begin0
	.quad	.Ltmp100-.Lfunc_begin0
	.quad	.Ltmp104-.Lfunc_begin0
	.quad	.Ltmp105-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"extend_attention.py"           ; string offset=7
.Linfo_string2:
	.asciz	"/netra-server/python/sglang/srt/layers/attention/triton_ops" ; string offset=27
.Linfo_string3:
	.asciz	"qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950"                   ; string offset=87
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
      - .offset:         108
        .size:           4
        .value_kind:     by_value
      - .offset:         112
        .size:           4
        .value_kind:     by_value
      - .offset:         116
        .size:           4
        .value_kind:     by_value
      - .offset:         120
        .size:           4
        .value_kind:     by_value
      - .offset:         124
        .size:           4
        .value_kind:     by_value
      - .offset:         128
        .size:           4
        .value_kind:     by_value
      - .offset:         132
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         136
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         144
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 152
    .max_flat_workgroup_size: 512
    .name:           qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950
    .private_segment_fixed_size: 96
    .sgpr_count:     106
    .sgpr_spill_count: 1
    .symbol:         qwen36_prefill_attention_m8192_m128n128_w8_exact_gqa8_fp8kv_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     256
    .vgpr_spill_count: 26
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
	.section	.debug_line,"",@progbits
.Lline_table_start0:
