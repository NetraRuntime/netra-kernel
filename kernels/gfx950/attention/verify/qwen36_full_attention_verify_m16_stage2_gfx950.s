	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
; Qwen3.6 full-attention M=16 speculative verification, stage 2.
; Hand-maintained gfx950/wave64 assembly for the real deterministic serving
; contract (MAX_KV_SPLITS=129).  The pointer at kernarg offset 32 addresses
; sixteen int32 sequence lengths rather than a 17-entry CSR indptr.
	.text
	.globl	qwen36_full_attention_verify_m16_stage2_gfx950              ; -- Begin function qwen36_full_attention_verify_m16_stage2_gfx950
	.p2align	8
	.type	qwen36_full_attention_verify_m16_stage2_gfx950,@function
qwen36_full_attention_verify_m16_stage2_gfx950:                     ; @qwen36_full_attention_verify_m16_stage2_gfx950
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.9:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/triton_ops" "decode_attention.py"
	.loc	1 523 0 prologue_end            ; decode_attention.py:523:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.10:
.LBB0_0:
	s_mov_b64 s[24:25], s[2:3]
.Ltmp1:
	.loc	1 549 56 is_stmt 1              ; decode_attention.py:549:56
	s_ashr_i32 s3, s16, 31
	.loc	1 549 32 is_stmt 0              ; decode_attention.py:549:32
	s_mov_b32 s2, s16
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s2, s10, s2
	s_addc_u32 s3, s11, s3
	.loc	1 550 8 is_stmt 1               ; decode_attention.py:550:8
	s_mov_b64 s[10:11], s[2:3]
	s_mov_b64 s[20:21], s[6:7]
	.loc	1 549 32                        ; decode_attention.py:549:32
	s_load_dword s18, s[10:11], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_load_dword s6, s[0:1], 0x40
	s_mov_b32 s9, s17
	.loc	1 550 8                         ; decode_attention.py:550:8
	s_ashr_i32 s17, s16, 31
	.loc	1 549 61                        ; decode_attention.py:549:61
	s_waitcnt lgkmcnt(0)
	s_mov_b32 s10, s18
	.loc	1 552 24                        ; decode_attention.py:552:24
	s_lshl_b64 s[0:1], s[16:17], 2
	s_add_u32 s0, s12, s0
	s_addc_u32 s1, s13, s1
	s_load_dword s0, s[0:1], 0x0
	.loc	1 554 26                        ; decode_attention.py:554:26
	v_readfirstlane_b32 s7, v0
	v_and_b32_e32 v2, 63, v0
	.loc	1 561 25                        ; decode_attention.py:561:25
	s_mul_i32 s1, s14, s16
	.loc	1 561 52 is_stmt 0              ; decode_attention.py:561:52
	s_mul_i32 s17, s15, s9
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 43 30 is_stmt 1               ; standard.py:43:30 @[ decode_attention.py:564:43 ]
	s_waitcnt lgkmcnt(0)
	s_abs_i32 s13, s0
	v_cvt_f32_u32_e32 v0, s13
.Ltmp3:
	.loc	1 561 41                        ; decode_attention.py:561:41
	s_add_i32 s11, s17, s1
	.loc	1 562 75                        ; decode_attention.py:562:75
	s_ashr_i32 s12, s11, 31
	s_lshr_b32 s12, s12, 24
.Ltmp4:
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:564:43 ]
	v_rcp_iflag_f32_e32 v0, v0
	s_sub_i32 s15, 0, s13
.Ltmp5:
	.loc	1 562 75                        ; decode_attention.py:562:75
	s_add_i32 s11, s11, s12
.Ltmp6:
	.loc	2 43 23                         ; standard.py:43:23 @[ decode_attention.py:564:43 ]
	s_add_i32 s12, s0, s10
	.loc	2 43 30 is_stmt 0               ; standard.py:43:30 @[ decode_attention.py:564:43 ]
	v_mul_f32_e32 v0, 0x4f7ffffe, v0
	v_cvt_u32_f32_e32 v0, v0
	.loc	2 43 17                         ; standard.py:43:17 @[ decode_attention.py:564:43 ]
	s_add_i32 s12, s12, -1
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:564:43 ]
	s_abs_i32 s14, s12
	s_xor_b32 s0, s12, s0
	v_readfirstlane_b32 s18, v0
	s_mul_i32 s15, s15, s18
	s_mul_hi_u32 s15, s18, s15
	s_add_i32 s18, s18, s15
	s_mul_hi_u32 s15, s14, s18
	s_mul_i32 s18, s15, s13
	s_sub_i32 s14, s14, s18
.Ltmp7:
	.loc	1 562 75 is_stmt 1              ; decode_attention.py:562:75
	s_ashr_i32 s11, s11, 8
.Ltmp8:
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:564:43 ]
	s_ashr_i32 s0, s0, 31
	s_add_i32 s18, s15, 1
	s_sub_i32 s19, s14, s13
	s_cmp_ge_u32 s14, s13
	s_cselect_b32 s15, s18, s15
	s_cselect_b32 s14, s19, s14
	s_add_i32 s18, s15, 1
	s_cmp_ge_u32 s14, s13
	s_cselect_b32 s13, s18, s15
	s_xor_b32 s13, s13, s0
	s_sub_i32 s0, s13, s0
.Ltmp9:
	.loc	2 43 17 is_stmt 0               ; standard.py:43:17 @[ decode_attention.py:564:55 ]
	s_add_i32 s0, s0, 31
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:564:55 ]
	s_ashr_i32 s13, s0, 31
	s_lshr_b32 s13, s13, 27
.Ltmp10:
	.loc	1 567 50 is_stmt 1              ; decode_attention.py:567:50
	s_lshl_b32 s1, s1, 2
.Ltmp11:
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:564:55 ]
	s_add_i32 s13, s0, s13
.Ltmp12:
	.loc	1 567 50                        ; decode_attention.py:567:50
	s_lshl2_add_u32 s1, s17, s1
	s_lshl_b32 s17, s7, 2
.Ltmp13:
	.loc	2 43 30                         ; standard.py:43:30 @[ decode_attention.py:564:55 ]
	s_ashr_i32 s0, s13, 5
.Ltmp14:
	.loc	1 567 50                        ; decode_attention.py:567:50
	v_lshlrev_b32_e32 v3, 2, v2
	s_and_b32 s17, s17, 0x300
	v_mov_b32_e32 v0, 0
	s_mov_b32 s12, 0
	.loc	1 564 71                        ; decode_attention.py:564:71
	s_andn2_b32 s13, s13, 31
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	s_and_b32 s25, s25, 0xffff
	.loc	1 567 50                        ; decode_attention.py:567:50
	s_lshl_b32 s14, s2, 1
	s_mul_i32 s15, s2, 3
	v_lshl_add_u32 v4, s2, 3, v3
	s_add_i32 s17, s1, s17
	s_mul_i32 s18, s2, 12
	v_lshl_add_u32 v5, s2, 2, v3
	s_mul_i32 s19, s0, 0x60
	s_lshl_b32 s22, s0, 6
	v_mov_b32_e32 v1, v0
	s_movk_i32 s23, 0x81
	v_mov_b32_e32 v7, 0xff800000
	s_mov_b32 s28, 0xc2fc0000
	v_mov_b32_e32 v6, 0x42800000
	s_mov_b32 s29, 0
	s_branch .LBB0_2
.LBB0_1:                                ;   in Loop: Header=BB0_2 Depth=1
	.loc	1 567 50                        ; decode_attention.py:567:50
	s_add_i32 s23, s23, -3
	s_add_i32 s29, s29, s15
	s_add_i32 s17, s17, s18
	s_cmp_lg_u32 s23, 0
	s_cbranch_scc0 .LBB0_8
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 569 69                        ; decode_attention.py:569:69
	s_add_i32 s31, s13, s12
	s_min_i32 s0, s31, s10
	.loc	1 571 26                        ; decode_attention.py:571:26
	s_cmp_le_i32 s0, s12
	.loc	1 571 11 is_stmt 0              ; decode_attention.py:571:11
	s_cbranch_scc0 .LBB0_5
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=1
	.loc	1 569 69 is_stmt 1              ; decode_attention.py:569:69
	s_add_i32 s30, s22, s12
	s_min_i32 s0, s30, s10
	.loc	1 571 26                        ; decode_attention.py:571:26
	s_cmp_le_i32 s0, s31
	.loc	1 571 11 is_stmt 0              ; decode_attention.py:571:11
	s_cbranch_scc0 .LBB0_6
.LBB0_4:                                ;   in Loop: Header=BB0_2 Depth=1
	.loc	1 569 69 is_stmt 1              ; decode_attention.py:569:69
	s_add_i32 s12, s19, s12
	s_min_i32 s0, s12, s10
	.loc	1 571 26                        ; decode_attention.py:571:26
	s_cmp_le_i32 s0, s30
	.loc	1 571 11 is_stmt 0              ; decode_attention.py:571:11
	s_cbranch_scc1 .LBB0_1
	s_branch .LBB0_7
.LBB0_5:                                ;   in Loop: Header=BB0_2 Depth=1
	.loc	1 573 16 is_stmt 1              ; decode_attention.py:573:16
	v_add_u32_e32 v8, s17, v3
	buffer_load_dword v9, v8, s[24:27], 0 offen
	.loc	1 575 83                        ; decode_attention.py:575:83
	s_ashr_i32 s0, s29, 31
	s_lshr_b32 s0, s0, 24
	s_add_i32 s0, s29, s0
	s_ashr_i32 s0, s0, 8
	.loc	1 575 52 is_stmt 0              ; decode_attention.py:575:52
	s_add_i32 s0, s0, s11
	.loc	1 575 29                        ; decode_attention.py:575:29
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_load_dword s0, s[0:1], 0x0
	.loc	1 576 41 is_stmt 1              ; decode_attention.py:576:41
	v_max_f32_e32 v8, v7, v7
	s_waitcnt lgkmcnt(0)
	v_max_f32_e64 v10, s0, s0
	v_max_f32_e32 v12, v10, v8
	.loc	1 578 39                        ; decode_attention.py:578:39
	v_sub_f32_e32 v7, v7, v12
	.loc	1 580 40                        ; decode_attention.py:580:40
	v_sub_f32_e32 v8, s0, v12
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_mul_f32_e32 v11, 0x3fb8aa3b, v8
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_cmp_gt_f32_e32 vcc, s28, v10
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_cmp_gt_f32_e64 s[0:1], s28, v11
	.loc	1 578 31                        ; decode_attention.py:578:31
	s_and_b64 s[34:35], vcc, exec
	v_cndmask_b32_e32 v10, 0, v6, vcc
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_cndmask_b32_e64 v11, 0, v6, s[0:1]
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v8
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_exp_f32_e32 v7, v10
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_exp_f32_e32 v10, v11
	.loc	1 578 31                        ; decode_attention.py:578:31
	s_cselect_b32 s30, 0xffffffc0, 0
	.loc	1 580 31                        ; decode_attention.py:580:31
	s_and_b64 s[0:1], s[0:1], exec
	s_cselect_b32 s0, 0xffffffc0, 0
	v_ldexp_f32 v10, v10, s0
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_ldexp_f32 v8, v7, s30
	v_mov_b32_e32 v7, v12
	.loc	1 581 31                        ; decode_attention.py:581:31
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v11, v9, v10
	.loc	1 583 40                        ; decode_attention.py:583:40
	v_pk_fma_f32 v[0:1], v[0:1], v[8:9], v[10:11] op_sel_hi:[1,0,1]
	.loc	1 569 69                        ; decode_attention.py:569:69
	s_add_i32 s30, s22, s12
	s_min_i32 s0, s30, s10
	.loc	1 571 26                        ; decode_attention.py:571:26
	s_cmp_le_i32 s0, s31
	.loc	1 571 11 is_stmt 0              ; decode_attention.py:571:11
	s_cbranch_scc1 .LBB0_4
.LBB0_6:                                ;   in Loop: Header=BB0_2 Depth=1
	.loc	1 573 16 is_stmt 1              ; decode_attention.py:573:16
	v_add_u32_e32 v8, s17, v5
	buffer_load_dword v9, v8, s[24:27], 0 offen
	.loc	1 573 33 is_stmt 0              ; decode_attention.py:573:33
	s_add_i32 s0, s2, s29
	.loc	1 575 83 is_stmt 1              ; decode_attention.py:575:83
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 8
	.loc	1 575 52 is_stmt 0              ; decode_attention.py:575:52
	s_add_i32 s0, s0, s11
	.loc	1 575 29                        ; decode_attention.py:575:29
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_load_dword s0, s[0:1], 0x0
	.loc	1 576 41 is_stmt 1              ; decode_attention.py:576:41
	v_max_f32_e32 v8, v7, v7
	s_waitcnt lgkmcnt(0)
	v_max_f32_e64 v10, s0, s0
	v_max_f32_e32 v12, v10, v8
	.loc	1 578 39                        ; decode_attention.py:578:39
	v_sub_f32_e32 v7, v7, v12
	.loc	1 580 40                        ; decode_attention.py:580:40
	v_sub_f32_e32 v8, s0, v12
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_mul_f32_e32 v11, 0x3fb8aa3b, v8
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_cmp_gt_f32_e32 vcc, s28, v10
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_cmp_gt_f32_e64 s[0:1], s28, v11
	.loc	1 578 31                        ; decode_attention.py:578:31
	s_and_b64 s[34:35], vcc, exec
	v_cndmask_b32_e32 v10, 0, v6, vcc
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_cndmask_b32_e64 v11, 0, v6, s[0:1]
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v8
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_exp_f32_e32 v7, v10
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_exp_f32_e32 v10, v11
	.loc	1 578 31                        ; decode_attention.py:578:31
	s_cselect_b32 s31, 0xffffffc0, 0
	.loc	1 580 31                        ; decode_attention.py:580:31
	s_and_b64 s[0:1], s[0:1], exec
	s_cselect_b32 s0, 0xffffffc0, 0
	v_ldexp_f32 v10, v10, s0
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_ldexp_f32 v8, v7, s31
	v_mov_b32_e32 v7, v12
	.loc	1 581 31                        ; decode_attention.py:581:31
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v11, v9, v10
	.loc	1 583 40                        ; decode_attention.py:583:40
	v_pk_fma_f32 v[0:1], v[0:1], v[8:9], v[10:11] op_sel_hi:[1,0,1]
	.loc	1 569 69                        ; decode_attention.py:569:69
	s_add_i32 s12, s19, s12
	s_min_i32 s0, s12, s10
	.loc	1 571 26                        ; decode_attention.py:571:26
	s_cmp_le_i32 s0, s30
	.loc	1 571 11 is_stmt 0              ; decode_attention.py:571:11
	s_cbranch_scc1 .LBB0_1
.LBB0_7:                                ;   in Loop: Header=BB0_2 Depth=1
	.loc	1 573 16 is_stmt 1              ; decode_attention.py:573:16
	v_add_u32_e32 v8, s17, v4
	buffer_load_dword v9, v8, s[24:27], 0 offen
	.loc	1 573 33 is_stmt 0              ; decode_attention.py:573:33
	s_add_i32 s0, s14, s29
	.loc	1 575 83 is_stmt 1              ; decode_attention.py:575:83
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 8
	.loc	1 575 52 is_stmt 0              ; decode_attention.py:575:52
	s_add_i32 s0, s0, s11
	.loc	1 575 29                        ; decode_attention.py:575:29
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_load_dword s0, s[0:1], 0x0
	.loc	1 576 41 is_stmt 1              ; decode_attention.py:576:41
	v_max_f32_e32 v8, v7, v7
	s_waitcnt lgkmcnt(0)
	v_max_f32_e64 v10, s0, s0
	v_max_f32_e32 v12, v10, v8
	.loc	1 578 39                        ; decode_attention.py:578:39
	v_sub_f32_e32 v7, v7, v12
	.loc	1 580 40                        ; decode_attention.py:580:40
	v_sub_f32_e32 v8, s0, v12
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_mul_f32_e32 v11, 0x3fb8aa3b, v8
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_cmp_gt_f32_e32 vcc, s28, v10
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_cmp_gt_f32_e64 s[0:1], s28, v11
	.loc	1 578 31                        ; decode_attention.py:578:31
	s_and_b64 s[30:31], vcc, exec
	v_cndmask_b32_e32 v10, 0, v6, vcc
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_cndmask_b32_e64 v11, 0, v6, s[0:1]
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v8
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_exp_f32_e32 v7, v10
	.loc	1 580 31                        ; decode_attention.py:580:31
	v_exp_f32_e32 v10, v11
	.loc	1 578 31                        ; decode_attention.py:578:31
	s_cselect_b32 s30, 0xffffffc0, 0
	.loc	1 580 31                        ; decode_attention.py:580:31
	s_and_b64 s[0:1], s[0:1], exec
	s_cselect_b32 s0, 0xffffffc0, 0
	v_ldexp_f32 v10, v10, s0
	.loc	1 578 31                        ; decode_attention.py:578:31
	v_ldexp_f32 v8, v7, s30
	v_mov_b32_e32 v7, v12
	.loc	1 581 31                        ; decode_attention.py:581:31
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v11, v9, v10
	.loc	1 583 40                        ; decode_attention.py:583:40
	v_pk_fma_f32 v[0:1], v[0:1], v[8:9], v[10:11] op_sel_hi:[1,0,1]
	s_branch .LBB0_1
.LBB0_8:
	.loc	1 592 8                         ; decode_attention.py:592:8
	s_and_b32 s0, s7, 0xc0
	.loc	1 554 26                        ; decode_attention.py:554:26
	v_or_b32_e32 v2, s0, v2
	.loc	1 592 14                        ; decode_attention.py:592:14
	v_div_scale_f32 v3, s[0:1], v0, v0, v1
	v_rcp_f32_e32 v4, v3
	.loc	1 591 24                        ; decode_attention.py:591:24
	s_mul_i32 s0, s3, s16
	.loc	1 591 48 is_stmt 0              ; decode_attention.py:591:48
	s_mul_i32 s1, s6, s9
	.loc	1 591 37                        ; decode_attention.py:591:37
	s_add_i32 s1, s1, s0
	.loc	1 592 14 is_stmt 1              ; decode_attention.py:592:14
	v_fma_f32 v5, -v3, v4, 1.0
	v_fmac_f32_e32 v4, v5, v4
	v_div_scale_f32 v5, vcc, v1, v0, v1
	v_mul_f32_e32 v6, v5, v4
	v_fma_f32 v7, -v3, v6, v5
	v_fmac_f32_e32 v6, v7, v4
	v_fma_f32 v3, -v3, v6, v5
	v_div_fmas_f32 v3, v3, v4, v6
	v_div_fixup_f32 v0, v3, v0, v1
	.loc	1 592 22 is_stmt 0              ; decode_attention.py:592:22
	v_mul_f32_e32 v0, s8, v0
	.loc	1 592 8                         ; decode_attention.py:592:8
	v_cvt_pk_bf16_f32 v0, v0, s0
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_add_lshl_u32 v1, s1, v2, 1
	buffer_store_short v0, v1, s[20:23], 0 offen
	.loc	1 590 4 is_stmt 1               ; decode_attention.py:590:4
	s_endpgm
.Ltmp15:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_full_attention_verify_m16_stage2_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 88
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
		.amdhsa_next_free_vgpr 97
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 16
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
	.size	qwen36_full_attention_verify_m16_stage2_gfx950, .Lfunc_end0-qwen36_full_attention_verify_m16_stage2_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_full_attention_verify_m16_stage2_gfx950.num_vgpr, 13
	.set qwen36_full_attention_verify_m16_stage2_gfx950.num_agpr, 0
	.set qwen36_full_attention_verify_m16_stage2_gfx950.numbered_sgpr, 36
	.set qwen36_full_attention_verify_m16_stage2_gfx950.num_named_barrier, 0
	.set qwen36_full_attention_verify_m16_stage2_gfx950.private_seg_size, 0
	.set qwen36_full_attention_verify_m16_stage2_gfx950.uses_vcc, 1
	.set qwen36_full_attention_verify_m16_stage2_gfx950.uses_flat_scratch, 0
	.set qwen36_full_attention_verify_m16_stage2_gfx950.has_dyn_sized_stack, 0
	.set qwen36_full_attention_verify_m16_stage2_gfx950.has_recursion, 0
	.set qwen36_full_attention_verify_m16_stage2_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1564
; TotalNumSgprs: 42
; NumVgprs: 13
; NumAgprs: 0
; TotalNumVgprs: 13
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 12
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 97
; AccumOffset: 16
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
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
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0x52 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x2c DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	564                             ; DW_AT_call_line
	.byte	43                              ; DW_AT_call_column
	.byte	4                               ; Abbrev [4] 0x4e:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	564                             ; DW_AT_call_line
	.byte	55                              ; DW_AT_call_column
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
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
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
	.asciz	"qwen36_full_attention_verify_m16_stage2_gfx950"            ; string offset=87
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
      - .address_space:  global
        .offset:         72
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .max_flat_workgroup_size: 256
    .name:           qwen36_full_attention_verify_m16_stage2_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     42
    .sgpr_spill_count: 0
    .symbol:         qwen36_full_attention_verify_m16_stage2_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     13
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
