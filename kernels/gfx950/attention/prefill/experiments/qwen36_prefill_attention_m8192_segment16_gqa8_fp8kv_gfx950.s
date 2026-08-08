	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	; Experimental exact Qwen3.6 target prefill attention: M=8192, GQA8, D=256.
	; Hand-written gfx950/wave64 segment scheduler around the promoted native
	; FP8-E4M3/BF16 MFMA verification core. Grid = [512 segments, 2 KV heads,
	; 2 query-head groups]. Each 512-thread workgroup computes one causal M16
	; segment and shares every prefix K/V tile across four query heads.
	;
	; ABI contract for this experiment: qo_indptr describes one M8192 sequence;
	; kv_indptr describes its original prefix; kv_indices also appends all 8192
	; extension cache locations contiguously after that prefix. Segment n consumes
	; original_prefix + 16*n native-E4M3 cache entries, while its current 16-token
	; tail remains BF16. M8192 is exact and divisible by 16.
	.text
	.globl	qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950  ; -- Begin function qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950
	.p2align	8
	.type	qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950,@function
qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950:         ; @qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.10:
	.file	1 "/netra-kernel/tools/benchmark" "benchmark_qwen36_extend_attention_m756.py"
	.loc	1 242 0 prologue_end            ; benchmark_qwen36_extend_attention_m756.py:242:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_load_dword s22, s[0:1], 0x4c
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.11:
.LBB0_0:
	s_mov_b64 s[24:25], s[2:3]
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_mov_b64 s[44:45], s[10:11]
	s_mov_b64 s[40:41], s[6:7]
	s_mov_b32 s74, s16                 ; segment index in [0,511]
	s_mov_b32 s20, 0                   ; exact single sequence
.Ltmp1:
	.loc	1 242 0 is_stmt 1               ; benchmark_qwen36_extend_attention_m756.py:242
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_readfirstlane_b32 s11, v0
	.loc	1 276 22                        ; benchmark_qwen36_extend_attention_m756.py:276:22
	s_mov_b32 s21, 0
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	s_and_b32 s10, s11, 0x1c0
	.loc	1 276 22                        ; benchmark_qwen36_extend_attention_m756.py:276:22
	; SGLang supplies either int32 eager qo_indptr or int64 piecewise-graph
	; qo_indptr. The bridge passes its element size through the ABI gap at 0x4c.
	; Supported token capacity is below 2^32, so only the low dword is consumed.
	s_cmp_eq_u32 s22, 4
	s_cbranch_scc1 .Lnetra_qo_i32
	s_lshl_b64 s[6:7], s[20:21], 3
	s_add_u32 s14, s14, s6
	s_addc_u32 s15, s15, s7
	v_mov_b32_e32 v4, 0
	global_load_dword v2, v4, s[14:15]
	global_load_dword v3, v4, s[14:15] offset:8
	s_branch .Lnetra_qo_ready
.Lnetra_qo_i32:
	s_lshl_b64 s[6:7], s[20:21], 2
	s_add_u32 s14, s14, s6
	s_addc_u32 s15, s15, s7
	v_mov_b32_e32 v4, 0
	global_load_dword v2, v4, s[14:15]
	global_load_dword v3, v4, s[14:15] offset:4
.Lnetra_qo_ready:
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	v_and_b32_e32 v64, 63, v0
	v_or_b32_e32 v57, s10, v64
	v_lshrrev_b32_e32 v59, 4, v57
	.loc	1 282 31                        ; benchmark_qwen36_extend_attention_m756.py:282:31
	v_bfe_u32 v6, v57, 4, 4
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	v_or_b32_e32 v58, 32, v59
	s_movk_i32 s14, 0x300
	.loc	1 298 27                        ; benchmark_qwen36_extend_attention_m756.py:298:27
	v_lshlrev_b32_e32 v7, 12, v6
	v_lshlrev_b32_e32 v8, 4, v58
	v_and_or_b32 v8, v8, s14, v7
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	v_and_b32_e32 v1, 15, v0
	.loc	1 296 17                        ; benchmark_qwen36_extend_attention_m756.py:296:17
	v_lshlrev_b32_e32 v56, 4, v1
	v_or_b32_e32 v60, 8, v56
	.loc	1 298 16                        ; benchmark_qwen36_extend_attention_m756.py:298:16
	v_bfrev_b32_e32 v5, 1
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	v_lshlrev_b32_e32 v50, 5, v57
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	v_and_b32_e32 v53, 48, v0
	v_lshlrev_b32_e32 v51, 3, v0
	v_lshlrev_b32_e32 v54, 2, v1
	.loc	1 276 22                        ; benchmark_qwen36_extend_attention_m756.py:276:22
	s_waitcnt vmcnt(0)
	v_readfirstlane_b32 s63, v2
	.loc	1 277 47                        ; benchmark_qwen36_extend_attention_m756.py:277:47
	v_readfirstlane_b32 s14, v3
	s_sub_i32 s57, s14, s63
	s_lshl_b32 s75, s74, 4            ; segment token offset
	s_add_u32 s63, s63, s75           ; segment query/tail/output start
	s_mov_b32 s57, 16                 ; exact segment length
	.loc	1 278 23                        ; benchmark_qwen36_extend_attention_m756.py:278:23
	s_waitcnt lgkmcnt(0)
	; kv_indptr is always int32, independent of the qo_indptr representation.
	s_lshl_b64 s[6:7], s[20:21], 2
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	.loc	1 289 29                        ; benchmark_qwen36_extend_attention_m756.py:289:29
	s_lshl_b32 s7, s18, 10
	.loc	1 298 27                        ; benchmark_qwen36_extend_attention_m756.py:298:27
	s_lshl_b32 s15, s17, 11
	s_lshl_b32 s14, s63, 12
	s_add_i32 s33, s15, s7
	s_and_b32 s6, s11, 0x100
	s_add_i32 s33, s33, s14
	.loc	1 278 23                        ; benchmark_qwen36_extend_attention_m756.py:278:23
	global_load_dwordx2 v[2:3], v4, s[2:3]
	.loc	1 298 27                        ; benchmark_qwen36_extend_attention_m756.py:298:27
	v_or_b32_e32 v4, s6, v7
	v_or_b32_e32 v7, s33, v56
	v_or_b32_e32 v9, s33, v60
	.loc	1 298 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:298:16
	v_add_lshl_u32 v10, v7, v4, 1
	.loc	1 286 26 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:286:26
	v_cmp_gt_i32_e32 vcc, s57, v6
	.loc	1 298 16                        ; benchmark_qwen36_extend_attention_m756.py:298:16
	s_and_b32 s25, s25, 0xffff
	v_add_lshl_u32 v4, v9, v4, 1
	v_add_lshl_u32 v7, v7, v8, 1
	v_add_lshl_u32 v8, v9, v8, 1
	v_cndmask_b32_e32 v6, v5, v10, vcc
	v_cndmask_b32_e32 v4, v5, v4, vcc
	v_cndmask_b32_e32 v7, v5, v7, vcc
	v_cndmask_b32_e32 v5, v5, v8, vcc
	buffer_load_dwordx4 v[96:99], v6, s[24:27], 0 offen
	buffer_load_dwordx4 v[92:95], v4, s[24:27], 0 offen
	buffer_load_dwordx4 v[104:107], v7, s[24:27], 0 offen
	buffer_load_dwordx4 v[100:103], v5, s[24:27], 0 offen
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	v_mov_b32_e32 v4, 0xf0
	v_bitop3_b32 v62, s10, v4, v64 bitop3:0xc8
	v_lshlrev_b32_e32 v4, 1, v62
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	s_and_b32 s54, s11, 0xc0
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	v_xad_u32 v4, v4, v50, 0
	.loc	1 286 26                        ; benchmark_qwen36_extend_attention_m756.py:286:26
	v_cmp_gt_i32_e64 s[2:3], s57, v1
	v_lshrrev_b32_e32 v52, 1, v62
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	s_waitcnt vmcnt(3)
	ds_write_b128 v4, v[96:99]
	s_waitcnt vmcnt(2)
	ds_write_b128 v4, v[92:95] offset:16
	s_waitcnt vmcnt(1)
	ds_write_b128 v4, v[104:107] offset:16384
	s_waitcnt vmcnt(0)
	ds_write_b128 v4, v[100:103] offset:16400
	.loc	1 278 23                        ; benchmark_qwen36_extend_attention_m756.py:278:23
	v_readfirstlane_b32 s14, v2
	.loc	1 279 52                        ; benchmark_qwen36_extend_attention_m756.py:279:52
	v_readfirstlane_b32 s6, v3
	s_sub_i32 s66, s6, s14
	s_add_u32 s66, s66, s75           ; original prefix plus earlier segments
	.loc	1 304 40                        ; benchmark_qwen36_extend_attention_m756.py:304:40
	s_cmp_gt_i32 s66, 0
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 304 40                        ; benchmark_qwen36_extend_attention_m756.py:304:40
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	.loc	1 369 16                        ; benchmark_qwen36_extend_attention_m756.py:369:16
	s_and_b32 s56, s11, 64
	s_and_b32 s58, s11, 0x80
	s_lshr_b32 s6, s11, 2
	.loc	1 350 24                        ; benchmark_qwen36_extend_attention_m756.py:350:24
	s_lshl_b32 s65, s17, 8
	.loc	1 369 16                        ; benchmark_qwen36_extend_attention_m756.py:369:16
	s_lshl_b32 s59, s56, 1
	s_lshr_b32 s60, s58, 1
	s_and_b32 s61, s6, 64
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_3
.LBB0_2:
	.loc	1 0 16 is_stmt 0                ; benchmark_qwen36_extend_attention_m756.py:0:16
	s_mov_b64 s[6:7], -1
                                        ; implicit-def: $sgpr65
                                        ; implicit-def: $sgpr56
                                        ; implicit-def: $sgpr59
                                        ; implicit-def: $sgpr58
                                        ; implicit-def: $sgpr60
                                        ; implicit-def: $sgpr61
.LBB0_3:                                ; %Flow373
	s_load_dword s62, s[0:1], 0x48
	s_and_b32 s55, s11, 0x180
	v_lshrrev_b32_e32 v61, 2, v53
	v_lshlrev_b32_e32 v63, 9, v1
	s_andn2_b64 vcc, exec, s[6:7]
	s_lshl_b32 s64, s54, 7
	s_cbranch_vccnz .LBB0_8
; %bb.4:                                ; %.lr.ph
	s_load_dwordx2 s[48:49], s[0:1], 0x40
	.loc	1 281 31 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:281:31
	s_lshr_b32 s0, s10, 6
	s_or_b32 s1, s0, 8
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	v_lshlrev_b32_e32 v2, 5, v1
	v_lshlrev_b32_e32 v3, 1, v53
	.loc	1 286 26                        ; benchmark_qwen36_extend_attention_m756.py:286:26
	s_cmp_lt_i32 s0, s57
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	v_bitop3_b32 v2, v2, v63, v3 bitop3:0xde
	s_movk_i32 s0, 0x180
	v_mov_b32_e32 v4, s64
	v_bitop3_b32 v5, v2, s0, v4 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	ds_read_b128 v[14:17], v5
	ds_read_b128 v[18:21], v5 offset:16
	s_movk_i32 s0, 0x100
	v_bitop3_b32 v5, v2, s0, v4 bitop3:0x36
	s_movk_i32 s0, 0x80
	v_or_b32_e32 v3, s64, v2
	v_bitop3_b32 v2, v2, s0, v4 bitop3:0x36
	s_waitcnt lgkmcnt(0)
	v_cvt_scalef32_pk_fp8_bf16 v14, v14, 1.0
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v2, 0, v2
	v_add_u32_e32 v30, 0, v3
	v_cvt_scalef32_pk_fp8_bf16 v14, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v15, v16, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v16, v18, 1.0
	ds_read_b128 v[10:13], v5
	ds_read_b128 v[22:25], v5 offset:16
	ds_read_b128 v[6:9], v2
	ds_read_b128 v[26:29], v2 offset:16
	ds_read_b128 v[2:5], v30
	ds_read_b128 v[30:33], v30 offset:16
	v_cvt_scalef32_pk_fp8_bf16 v16, v19, 1.0 op_sel:[0,0,1]
	v_mul_u32_u24_e32 v19, 0x110, v1
	.loc	1 286 26                        ; benchmark_qwen36_extend_attention_m756.py:286:26
	s_cselect_b64 s[42:43], -1, 0
	s_cmp_lt_i32 s1, s57
	v_lshlrev_b32_e32 v34, 5, v0
	v_cvt_scalef32_pk_fp8_bf16 v15, v17, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v17, v20, 1.0
	v_lshlrev_b32_e32 v18, 4, v57
	v_xor_b32_e32 v68, v19, v53
	v_lshlrev_b32_e32 v19, 4, v53
	v_lshrrev_b32_e32 v20, 1, v53
	s_cselect_b64 s[52:53], -1, 0
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	s_lshr_b32 s0, s54, 2
	v_and_b32_e32 v34, 0xe0, v34
	v_lshrrev_b32_e32 v35, 1, v0
	v_xor_b32_e32 v67, v18, v62
	v_bitop3_b32 v19, v19, v20, v1 bitop3:0x36
	v_xor_b32_e32 v74, v52, v18
	v_lshlrev_b32_e32 v18, 2, v0
	v_and_b32_e32 v55, 28, v35
	v_add_u32_e32 v66, 0, v34
	s_and_b32 s56, s11, 64
	v_xor_b32_e32 v72, s0, v19
	v_and_b32_e32 v19, 62, v0
	v_and_b32_e32 v18, 0x78, v18
	s_waitcnt lgkmcnt(1)
	v_cvt_scalef32_pk_fp8_bf16 v2, v2, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v17, v21, 1.0 op_sel:[0,0,1]
	v_and_b32_e32 v20, 24, v0
	v_and_b32_e32 v21, 8, v51
	s_lshr_b32 s0, s56, 2
	v_lshl_or_b32 v18, v19, 7, v18
	v_add_u32_e32 v66, v66, v55
	v_xor_b32_e32 v55, 0xc0, v68
	s_lshr_b32 s1, s55, 3
	v_cvt_scalef32_pk_fp8_bf16 v2, v3, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v3, v4, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v7, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v11, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v11, v12, 1.0
	s_lshl_b32 s59, s56, 1
	s_and_b32 s58, s11, 0x80
	s_lshr_b32 s7, s11, 2
	v_lshl_or_b32 v20, v19, 5, v20
	v_bitop3_b32 v76, s0, v18, v21 bitop3:0x36
	.loc	1 304 40                        ; benchmark_qwen36_extend_attention_m756.py:304:40
	v_add_u32_e32 v18, s10, v64
	v_add_u32_e32 v71, 0, v55
	v_xor_b32_e32 v55, 8, v74
	s_lshr_b32 s6, s10, 1
	s_lshl_b32 s65, s17, 8
	v_cvt_scalef32_pk_fp8_bf16 v3, v5, 1.0 op_sel:[0,0,1]
	s_waitcnt lgkmcnt(0)
	v_cvt_scalef32_pk_fp8_bf16 v4, v30, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v5, v32, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v7, v9, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v26, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v9, v28, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v11, v13, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v12, v22, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v13, v24, 1.0
	v_xor_b32_e32 v69, 64, v68
	v_xor_b32_e32 v70, 0x80, v68
	s_lshr_b32 s60, s58, 1
	s_add_i32 s68, s59, 0
	s_and_b32 s61, s7, 64
	s_add_i32 s69, s58, 0
	v_bitop3_b32 v73, s1, v20, v21 bitop3:0x36
	v_lshrrev_b32_e32 v65, 4, v18
	v_add_u32_e32 v75, 0, v55
	v_xor_b32_e32 v55, 32, v76
	v_xor_b32_e32 v78, 64, v76
	v_xor_b32_e32 v79, 0x60, v76
	.loc	1 325 29                        ; benchmark_qwen36_extend_attention_m756.py:325:29
	s_mov_b32 s67, 0
	s_and_b32 s49, s49, 0xffff
	s_mov_b32 s51, 0x27000
	s_mov_b32 s50, 0x7ffffffe
	s_and_b32 s45, s45, 0xffff
	v_cvt_scalef32_pk_fp8_bf16 v4, v31, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v5, v33, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v27, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v9, v29, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v12, v23, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v13, v25, 1.0 op_sel:[0,0,1]
	s_and_b32 s13, s13, 0xffff
	s_add_i32 s68, s68, s60
	s_add_i32 s69, s69, s61
	.loc	1 304 40                        ; benchmark_qwen36_extend_attention_m756.py:304:40
	s_lshl_b32 s70, s14, 3
	.loc	1 306 27                        ; benchmark_qwen36_extend_attention_m756.py:306:27
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	s_add_i32 s71, s6, 0
	v_add_u32_e32 v67, 0, v67
	v_add_u32_e32 v68, 0, v68
	v_add_u32_e32 v69, 0, v69
	v_add_u32_e32 v70, 0, v70
	s_mov_b32 s72, 0xff800000
	s_mov_b32 s73, 0xc2fc0000
	v_add_u32_e32 v72, 0, v72
	v_add_u32_e32 v73, 0, v73
	v_add_u32_e32 v74, 0, v74
	v_add_u32_e32 v76, 0, v76
	v_add_u32_e32 v77, 0, v55
	v_add_u32_e32 v78, 0, v78
	v_add_u32_e32 v79, 0, v79
	v_or_b32_e32 v80, s65, v56
	.loc	1 304 40                        ; benchmark_qwen36_extend_attention_m756.py:304:40
	v_lshlrev_b32_e32 v81, 3, v65
	v_mov_b32_e32 v87, 0xff800000
	v_mov_b32_e32 v55, 0
	v_bfrev_b32_e32 v82, 1
	v_mov_b32_e32 v83, 0xff800000
	v_mov_b32_e32 v84, 0xe0ad78ec
	v_mov_b32_e32 v85, 0x42800000
	v_not_b32_e32 v86, 63
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 304 40                        ; benchmark_qwen36_extend_attention_m756.py:304:40
	s_add_i32 s67, s67, 64
	s_cmp_lt_i32 s67, s66
	v_add_u32_e32 v81, 0x200, v81
	s_cbranch_scc0 .LBB0_9
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 306 36                        ; benchmark_qwen36_extend_attention_m756.py:306:36
	v_add_u32_e32 v88, s67, v64
	v_cmp_gt_i32_e32 vcc, s66, v88
	.loc	1 307 39                        ; benchmark_qwen36_extend_attention_m756.py:307:39
	s_and_b64 s[0:1], s[42:43], vcc
	.loc	1 312 48                        ; benchmark_qwen36_extend_attention_m756.py:312:48
	v_cndmask_b32_e64 v88, 0, 1, s[0:1]
	.loc	1 307 39                        ; benchmark_qwen36_extend_attention_m756.py:307:39
	s_and_b64 s[0:1], s[52:53], vcc
	.loc	1 312 48                        ; benchmark_qwen36_extend_attention_m756.py:312:48
	v_cndmask_b32_e64 v89, 0, 1, s[0:1]
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ] ]
	v_max_i32_dpp v88, v88, v88 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ]
	s_waitcnt lgkmcnt(0)
	s_barrier
.Ltmp4:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ] ]
	v_max_i32_dpp v88, v88, v88 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ]
	v_mov_b32_e32 v90, v88
	s_nop 1
	v_mov_b32_dpp v90, v90 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp6:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ] ]
	v_max_i32_e32 v88, v88, v90
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ]
	s_nop 0
	v_readlane_b32 s16, v88, 63
.Ltmp8:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ] ]
	v_max_i32_dpp v88, v89, v89 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ]
	s_mov_b32 s18, s16
.Ltmp10:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ] ]
	s_nop 0
	v_max_i32_dpp v88, v88, v88 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp11:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ]
	v_mov_b32_e32 v89, v88
	s_nop 1
	v_mov_b32_dpp v89, v89 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp12:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ] ]
	v_max_i32_e32 v88, v88, v89
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp13:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:34 ]
	s_nop 0
	v_readlane_b32 s17, v88, 63
.Ltmp14:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ]
	s_mov_b32 s19, s17
	v_mov_b64_e32 v[110:111], s[18:19]
	v_mov_b32_e32 v88, s71
	v_mov_b64_e32 v[108:109], s[16:17]
	ds_write_b128 v88, v[108:111]
	ds_write_b128 v88, v[108:111] offset:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v88, v66
.Ltmp15:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ] ]
	s_waitcnt lgkmcnt(0)
	s_nop 0
	v_max_i32_dpp v88, v88, v88 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ]
	v_mov_b32_e32 v89, v88
	s_nop 1
	v_mov_b32_dpp v89, v89 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp17:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ] ]
	v_max_i32_e32 v88, v88, v89
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:312:27 ]
	s_nop 0
	v_readlane_b32 s0, v88, 63
.Ltmp19:
	.loc	1 0 0 is_stmt 0                 ; benchmark_qwen36_extend_attention_m756.py:0
	s_cmp_eq_u32 s0, 0
	.loc	1 313 11 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:313:11
	s_cbranch_scc1 .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 306 36                        ; benchmark_qwen36_extend_attention_m756.py:306:36
	v_add_u32_e32 v88, s67, v65
	v_add_u32_e32 v89, 32, v88
	.loc	1 315 16                        ; benchmark_qwen36_extend_attention_m756.py:315:16
	v_add_u32_e32 v90, s70, v81
	.loc	1 306 36                        ; benchmark_qwen36_extend_attention_m756.py:306:36
	v_cmp_gt_i32_e32 vcc, s66, v88
	.loc	1 315 16                        ; benchmark_qwen36_extend_attention_m756.py:315:16
	v_add_u32_e32 v88, 0x100, v90
	.loc	1 306 36                        ; benchmark_qwen36_extend_attention_m756.py:306:36
	v_cmp_gt_i32_e64 s[0:1], s66, v89
	.loc	1 315 16                        ; benchmark_qwen36_extend_attention_m756.py:315:16
	v_cndmask_b32_e32 v108, v82, v90, vcc
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	s_mov_b32 s46, s50
	.loc	1 315 16                        ; benchmark_qwen36_extend_attention_m756.py:315:16
	v_cndmask_b32_e64 v109, v82, v88, s[0:1]
	buffer_load_dwordx2 v[88:89], v108, s[48:51], 0 offen
	buffer_load_dwordx2 v[90:91], v109, s[48:51], 0 offen
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	s_mov_b32 s47, s51
	.loc	1 329 43                        ; benchmark_qwen36_extend_attention_m756.py:329:43
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v91, v87, v87
	.loc	1 324 35                        ; benchmark_qwen36_extend_attention_m756.py:324:35
	v_lshl_add_u32 v88, v88, 9, v80
	v_lshl_add_u32 v89, v90, 9, v80
	.loc	1 324 24 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:324:24
	v_cndmask_b32_e32 v88, v82, v88, vcc
	v_cndmask_b32_e64 v89, v82, v89, s[0:1]
	buffer_load_dwordx4 v[108:111], v88, s[44:47], 0 offen
	buffer_load_dwordx4 v[112:115], v89, s[44:47], 0 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 306 27 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:306:27
	v_add_u32_e32 v90, s67, v61
	.loc	1 306 36 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:306:36
	v_add_u32_e32 v120, 35, v90
	v_add_u32_e32 v121, 34, v90
	v_add_u32_e32 v122, 33, v90
	v_add_u32_e32 v123, 32, v90
	v_cmp_gt_i32_e64 s[16:17], s66, v120
	v_cmp_gt_i32_e64 s[18:19], s66, v121
	v_cmp_gt_i32_e64 s[20:21], s66, v122
	v_cmp_gt_i32_e64 s[22:23], s66, v123
	v_add_u32_e32 v116, 51, v90
	v_add_u32_e32 v117, 50, v90
	v_add_u32_e32 v118, 49, v90
	v_add_u32_e32 v119, 48, v90
	v_cmp_gt_i32_e64 s[0:1], s66, v116
	v_cmp_gt_i32_e64 s[6:7], s66, v117
	v_cmp_gt_i32_e64 s[10:11], s66, v118
	v_cmp_gt_i32_e64 s[14:15], s66, v119
	v_add_u32_e32 v124, 19, v90
	v_add_u32_e32 v125, 18, v90
	v_add_u32_e32 v126, 17, v90
	v_add_u32_e32 v127, 16, v90
	v_add_u32_e32 v128, 3, v90
	v_add_u32_e32 v129, 2, v90
	v_add_u32_e32 v130, 1, v90
	v_cmp_gt_i32_e64 s[24:25], s66, v124
	v_cmp_gt_i32_e64 s[26:27], s66, v125
	v_cmp_gt_i32_e64 s[28:29], s66, v126
	v_cmp_gt_i32_e64 s[30:31], s66, v127
	v_cmp_gt_i32_e64 s[34:35], s66, v128
	v_cmp_gt_i32_e64 s[36:37], s66, v129
	v_cmp_gt_i32_e64 s[38:39], s66, v130
	v_cmp_gt_i32_e32 vcc, s66, v90
	.loc	1 307 39 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:307:39
	s_and_b64 vcc, s[2:3], vcc
	s_and_b64 s[38:39], s[2:3], s[38:39]
	s_and_b64 s[36:37], s[2:3], s[36:37]
	s_and_b64 s[34:35], s[2:3], s[34:35]
	s_and_b64 s[30:31], s[2:3], s[30:31]
	s_and_b64 s[28:29], s[2:3], s[28:29]
	s_and_b64 s[26:27], s[2:3], s[26:27]
	s_and_b64 s[24:25], s[2:3], s[24:25]
	s_and_b64 s[22:23], s[2:3], s[22:23]
	s_and_b64 s[20:21], s[2:3], s[20:21]
	s_and_b64 s[18:19], s[2:3], s[18:19]
	s_and_b64 s[16:17], s[2:3], s[16:17]
	s_and_b64 s[14:15], s[2:3], s[14:15]
	s_and_b64 s[10:11], s[2:3], s[10:11]
	s_and_b64 s[6:7], s[2:3], s[6:7]
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	s_waitcnt vmcnt(1)
	ds_write_b128 v67, v[108:111]
	s_waitcnt vmcnt(0)
	ds_write_b128 v67, v[112:115] offset:8192
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[112:115], v69
	ds_read_b128 v[108:111], v68
	ds_read_b128 v[132:135], v68 offset:4096
	ds_read_b128 v[136:139], v69 offset:4096
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[108:111], v[108:115], v[2:9], 0
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	ds_read_b128 v[140:143], v68 offset:8192
	ds_read_b128 v[144:147], v69 offset:8192
	ds_read_b128 v[124:127], v70 offset:8192
	ds_read_b128 v[128:131], v71 offset:8192
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[132:139], v[2:9], 0
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	ds_read_b128 v[132:135], v68 offset:12288
	ds_read_b128 v[136:139], v69 offset:12288
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[132:139], v[2:9], 0
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	ds_read_b128 v[132:135], v70 offset:4096
	ds_read_b128 v[136:139], v71 offset:4096
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[140:147], v[2:9], 0
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	ds_read_b128 v[140:143], v70
	ds_read_b128 v[144:147], v71
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[132:139], v[10:17], v[112:115]
	.loc	1 324 24                        ; benchmark_qwen36_extend_attention_m756.py:324:24
	ds_read_b128 v[132:135], v70 offset:12288
	ds_read_b128 v[136:139], v71 offset:12288
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[108:111], v[140:147], v[10:17], v[108:111]
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[124:131], v[10:17], v[116:119]
	.loc	1 325 66 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:325:66
	s_nop 10
	v_mul_f32_e32 v90, s62, v108
	v_mul_f32_e32 v108, s62, v109
	v_mul_f32_e32 v109, s62, v110
	v_mul_f32_e32 v110, s62, v111
	v_mul_f32_e32 v111, s62, v112
	v_mul_f32_e32 v112, s62, v113
	v_mul_f32_e32 v113, s62, v114
	.loc	1 325 39                        ; benchmark_qwen36_extend_attention_m756.py:325:39
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[132:139], v[10:17], v[120:123]
	.loc	1 325 66                        ; benchmark_qwen36_extend_attention_m756.py:325:66
	v_mul_f32_e32 v114, s62, v115
	v_mul_f32_e32 v115, s62, v116
	v_mul_f32_e32 v116, s62, v117
	v_mul_f32_e32 v117, s62, v118
	v_mul_f32_e32 v118, s62, v119
	.loc	1 326 42 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v108, v83, v108, s[38:39]
	v_cndmask_b32_e64 v109, v83, v109, s[36:37]
	.loc	1 325 66                        ; benchmark_qwen36_extend_attention_m756.py:325:66
	s_nop 4
	v_mul_f32_e32 v119, s62, v120
	v_mul_f32_e32 v120, s62, v121
	v_mul_f32_e32 v121, s62, v122
	v_mul_f32_e32 v122, s62, v123
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e32 v123, v83, v90, vcc
	v_cndmask_b32_e64 v110, v83, v110, s[34:35]
.Ltmp20:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max_f32_e32 v90, v123, v108
.Ltmp21:
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v111, v83, v111, s[30:31]
	v_cndmask_b32_e64 v112, v83, v112, s[28:29]
.Ltmp22:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max3_f32 v90, v90, v109, v110
.Ltmp23:
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v113, v83, v113, s[26:27]
	v_cndmask_b32_e64 v114, v83, v114, s[24:25]
.Ltmp24:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max3_f32 v90, v90, v111, v112
.Ltmp25:
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v115, v83, v115, s[22:23]
	v_cndmask_b32_e64 v116, v83, v116, s[20:21]
.Ltmp26:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max3_f32 v90, v90, v113, v114
.Ltmp27:
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v117, v83, v117, s[18:19]
	v_cndmask_b32_e64 v118, v83, v118, s[16:17]
.Ltmp28:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max3_f32 v90, v90, v115, v116
.Ltmp29:
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v119, v83, v119, s[14:15]
	v_cndmask_b32_e64 v120, v83, v120, s[10:11]
.Ltmp30:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max3_f32 v90, v90, v117, v118
.Ltmp31:
	.loc	1 326 42                        ; benchmark_qwen36_extend_attention_m756.py:326:42
	v_cndmask_b32_e64 v121, v83, v121, s[6:7]
	v_cndmask_b32_e64 v122, v83, v122, s[0:1]
.Ltmp32:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max3_f32 v90, v90, v119, v120
	v_max3_f32 v90, v90, v121, v122
.Ltmp33:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ]
	v_mov_b32_e32 v124, v90
	s_nop 1
	v_permlane32_swap_b32_e32 v90, v124
.Ltmp34:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max_f32_e32 v124, v124, v124
	v_max_f32_e32 v90, v90, v90
	v_max_f32_e32 v90, v90, v124
.Ltmp35:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ]
	v_mov_b32_e32 v124, v90
	s_nop 1
	v_permlane16_swap_b32_e32 v90, v124
.Ltmp36:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:327:29 ] ]
	v_max_f32_e32 v124, v124, v124
	v_max_f32_e32 v90, v90, v90
	v_max_f32_e32 v90, v90, v124
.Ltmp37:
	.loc	1 328 66                        ; benchmark_qwen36_extend_attention_m756.py:328:66
	v_cmp_neq_f32_e32 vcc, s72, v90
	s_nop 1
	v_cndmask_b32_e32 v90, v84, v90, vcc
	.loc	1 329 43                        ; benchmark_qwen36_extend_attention_m756.py:329:43
	v_max_f32_e32 v90, v90, v91
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v108, v108, v90
	v_sub_f32_e32 v113, v113, v90
	.loc	1 331 35 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_mul_f32_e32 v125, 0x3fb8aa3b, v108
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v109, v109, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_mul_f32_e32 v130, 0x3fb8aa3b, v113
	v_cmp_gt_f32_e64 s[6:7], s73, v125
	v_mul_f32_e32 v126, 0x3fb8aa3b, v109
	v_cmp_gt_f32_e64 s[20:21], s73, v130
	v_cndmask_b32_e64 v125, 0, v85, s[6:7]
	.loc	1 330 37 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:330:37
	v_sub_f32_e32 v87, v87, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_cmp_gt_f32_e64 s[10:11], s73, v126
	v_cndmask_b32_e64 v130, 0, v85, s[20:21]
	v_fmac_f32_e32 v125, 0x3fb8aa3b, v108
	.loc	1 331 40 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v91, v123, v90
	v_sub_f32_e32 v111, v111, v90
	.loc	1 330 29 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_mul_f32_e32 v123, 0x3fb8aa3b, v87
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_cndmask_b32_e64 v126, 0, v85, s[10:11]
	v_fmac_f32_e32 v130, 0x3fb8aa3b, v113
	v_exp_f32_e32 v108, v125
	v_mul_f32_e32 v128, 0x3fb8aa3b, v111
	.loc	1 330 29                        ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_cmp_gt_f32_e32 vcc, s73, v123
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_fmac_f32_e32 v126, 0x3fb8aa3b, v109
	v_exp_f32_e32 v113, v130
	v_mul_f32_e32 v124, 0x3fb8aa3b, v91
	v_cmp_gt_f32_e64 s[16:17], s73, v128
	.loc	1 330 29                        ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_cndmask_b32_e32 v123, 0, v85, vcc
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_exp_f32_e32 v109, v126
	.loc	1 331 40 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v110, v110, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_cmp_gt_f32_e64 s[0:1], s73, v124
	v_cndmask_b32_e64 v128, 0, v85, s[16:17]
	v_cndmask_b32_e64 v133, 0, v86, s[6:7]
	.loc	1 330 29 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_fmac_f32_e32 v123, 0x3fb8aa3b, v87
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v114, v114, v90
	.loc	1 331 35 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_mul_f32_e32 v127, 0x3fb8aa3b, v110
	v_cndmask_b32_e64 v124, 0, v85, s[0:1]
	v_fmac_f32_e32 v128, 0x3fb8aa3b, v111
	.loc	1 330 29 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_exp_f32_e32 v87, v123
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v123, v108, v133
	v_cndmask_b32_e64 v108, 0, v86, s[20:21]
	.loc	1 331 40 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v115, v115, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_cmp_gt_f32_e64 s[14:15], s73, v127
	v_cndmask_b32_e64 v134, 0, v86, s[10:11]
	v_fmac_f32_e32 v124, 0x3fb8aa3b, v91
	v_exp_f32_e32 v111, v128
	v_ldexp_f32 v128, v113, v108
	v_mul_f32_e32 v108, 0x3fb8aa3b, v114
	v_cndmask_b32_e64 v127, 0, v85, s[14:15]
	.loc	1 330 29 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_cndmask_b32_e32 v131, 0, v86, vcc
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_exp_f32_e32 v91, v124
	v_ldexp_f32 v124, v109, v134
	v_cmp_gt_f32_e32 vcc, s73, v108
	v_mul_f32_e32 v109, 0x3fb8aa3b, v115
	v_cndmask_b32_e64 v132, 0, v86, s[0:1]
	v_fmac_f32_e32 v127, 0x3fb8aa3b, v110
	v_cndmask_b32_e32 v108, 0, v85, vcc
	v_cmp_gt_f32_e64 s[0:1], s73, v109
	.loc	1 331 40 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v112, v112, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_exp_f32_e32 v110, v127
	v_fmac_f32_e32 v108, 0x3fb8aa3b, v114
	v_cndmask_b32_e64 v109, 0, v85, s[0:1]
	v_mul_f32_e32 v129, 0x3fb8aa3b, v112
	v_exp_f32_e32 v108, v108
	v_fmac_f32_e32 v109, 0x3fb8aa3b, v115
	v_cmp_gt_f32_e64 s[18:19], s73, v129
	v_exp_f32_e32 v109, v109
	v_cndmask_b32_e64 v135, 0, v86, s[14:15]
	v_cndmask_b32_e64 v129, 0, v85, s[18:19]
	v_fmac_f32_e32 v129, 0x3fb8aa3b, v112
	v_ldexp_f32 v125, v110, v135
	v_cndmask_b32_e32 v110, 0, v86, vcc
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v116, v116, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_exp_f32_e32 v112, v129
	v_ldexp_f32 v129, v108, v110
	v_cndmask_b32_e64 v108, 0, v86, s[0:1]
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v117, v117, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v130, v109, v108
	v_mul_f32_e32 v108, 0x3fb8aa3b, v116
	v_cmp_gt_f32_e32 vcc, s73, v108
	v_mul_f32_e32 v109, 0x3fb8aa3b, v117
	v_cmp_gt_f32_e64 s[0:1], s73, v109
	v_cndmask_b32_e32 v108, 0, v85, vcc
	v_fmac_f32_e32 v108, 0x3fb8aa3b, v116
	v_cndmask_b32_e64 v109, 0, v85, s[0:1]
	v_exp_f32_e32 v108, v108
	v_fmac_f32_e32 v109, 0x3fb8aa3b, v117
	v_exp_f32_e32 v109, v109
	v_cndmask_b32_e32 v110, 0, v86, vcc
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v118, v118, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v116, v108, v110
	v_cndmask_b32_e64 v108, 0, v86, s[0:1]
	v_ldexp_f32 v117, v109, v108
	v_mul_f32_e32 v108, 0x3fb8aa3b, v118
	v_cmp_gt_f32_e32 vcc, s73, v108
	v_cndmask_b32_e64 v136, 0, v86, s[16:17]
	v_cndmask_b32_e64 v137, 0, v86, s[18:19]
	v_cndmask_b32_e32 v108, 0, v85, vcc
	v_fmac_f32_e32 v108, 0x3fb8aa3b, v118
	.loc	1 339 24 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:339:24
	s_mov_b32 s14, s50
	s_mov_b32 s15, s51
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v126, v111, v136
	v_ldexp_f32 v127, v112, v137
	v_exp_f32_e32 v118, v108
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	buffer_load_dwordx4 v[108:111], v88, s[12:15], 0 offen
	buffer_load_dwordx4 v[112:115], v89, s[12:15], 0 offen
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v119, v119, v90
	.loc	1 331 35 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_cndmask_b32_e32 v88, 0, v86, vcc
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v120, v120, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v89, v118, v88
	v_mul_f32_e32 v88, 0x3fb8aa3b, v119
	v_cmp_gt_f32_e32 vcc, s73, v88
	v_mul_f32_e32 v118, 0x3fb8aa3b, v120
	v_cmp_gt_f32_e64 s[0:1], s73, v118
	v_cndmask_b32_e32 v88, 0, v85, vcc
	v_fmac_f32_e32 v88, 0x3fb8aa3b, v119
	v_cndmask_b32_e64 v118, 0, v85, s[0:1]
	v_exp_f32_e32 v88, v88
	v_fmac_f32_e32 v118, 0x3fb8aa3b, v120
	v_exp_f32_e32 v118, v118
	v_cndmask_b32_e32 v119, 0, v86, vcc
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v121, v121, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v119, v88, v119
	v_cndmask_b32_e64 v88, 0, v86, s[0:1]
	.loc	1 331 40                        ; benchmark_qwen36_extend_attention_m756.py:331:40
	v_sub_f32_e32 v122, v122, v90
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v118, v118, v88
	v_mul_f32_e32 v88, 0x3fb8aa3b, v121
	v_cmp_gt_f32_e32 vcc, s73, v88
	v_mul_f32_e32 v120, 0x3fb8aa3b, v122
	v_cmp_gt_f32_e64 s[0:1], s73, v120
	v_cndmask_b32_e32 v88, 0, v85, vcc
	v_fmac_f32_e32 v88, 0x3fb8aa3b, v121
	v_cndmask_b32_e64 v120, 0, v85, s[0:1]
	v_exp_f32_e32 v88, v88
	v_fmac_f32_e32 v120, 0x3fb8aa3b, v122
	v_exp_f32_e32 v120, v120
	v_ldexp_f32 v91, v91, v132
	v_cndmask_b32_e32 v121, 0, v86, vcc
	v_ldexp_f32 v121, v88, v121
	v_cndmask_b32_e64 v88, 0, v86, s[0:1]
	.loc	1 341 33 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:341:33
	v_cvt_scalef32_pk_fp8_f32 v122, v91, v123, 1.0
	.loc	1 330 29                        ; benchmark_qwen36_extend_attention_m756.py:330:29
	v_ldexp_f32 v87, v87, v131
	.loc	1 331 35                        ; benchmark_qwen36_extend_attention_m756.py:331:35
	v_ldexp_f32 v120, v120, v88
	.loc	1 340 24                        ; benchmark_qwen36_extend_attention_m756.py:340:24
	v_add_u32_e32 v88, s68, v54
	.loc	1 341 33                        ; benchmark_qwen36_extend_attention_m756.py:341:33
	v_cvt_scalef32_pk_fp8_f32 v122, v124, v125, 1.0 op_sel:[0,0,0,1]
	.loc	1 340 24                        ; benchmark_qwen36_extend_attention_m756.py:340:24
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b32 v88, v87
	v_add_u32_e32 v88, s69, v54
	.loc	1 341 33                        ; benchmark_qwen36_extend_attention_m756.py:341:33
	v_cvt_scalef32_pk_fp8_f32 v131, v126, v127, 1.0
	v_lshrrev_b32_e32 v134, 8, v122
	.loc	1 340 24                        ; benchmark_qwen36_extend_attention_m756.py:340:24
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v88, v88
	.loc	1 341 33                        ; benchmark_qwen36_extend_attention_m756.py:341:33
	v_cvt_scalef32_pk_fp8_f32 v131, v128, v129, 1.0 op_sel:[0,0,0,1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b8 v72, v122
	ds_write_b8 v72, v134 offset:64
	ds_write_b8_d16_hi v72, v122 offset:128
	v_lshrrev_b32_e32 v122, 24, v122
	v_cvt_scalef32_pk_fp8_f32 v132, v130, v116, 1.0
	ds_write_b8 v72, v122 offset:192
	ds_write_b8 v72, v131 offset:1024
	v_lshrrev_b32_e32 v122, 8, v131
	v_cvt_scalef32_pk_fp8_f32 v132, v117, v89, 1.0 op_sel:[0,0,0,1]
	ds_write_b8 v72, v122 offset:1088
	ds_write_b8_d16_hi v72, v131 offset:1152
	v_lshrrev_b32_e32 v122, 24, v131
	v_cvt_scalef32_pk_fp8_f32 v133, v119, v118, 1.0
	ds_write_b8 v72, v122 offset:1216
	ds_write_b8 v72, v132 offset:2048
	v_lshrrev_b32_e32 v122, 8, v132
	v_cvt_scalef32_pk_fp8_f32 v133, v121, v120, 1.0 op_sel:[0,0,0,1]
	ds_write_b8 v72, v122 offset:2112
	ds_write_b8_d16_hi v72, v132 offset:2176
	v_lshrrev_b32_e32 v122, 24, v132
	ds_write_b8 v72, v122 offset:2240
	ds_write_b8 v72, v133 offset:3072
	v_lshrrev_b32_e32 v122, 8, v133
	ds_write_b8 v72, v122 offset:3136
	ds_write_b8_d16_hi v72, v133 offset:3200
	v_lshrrev_b32_e32 v122, 24, v133
	ds_write_b8 v72, v122 offset:3264
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b8 v[132:133], v73
	ds_read_b64_tr_b8 v[134:135], v73 offset:2048
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v74, v[108:109], v[112:113] offset1:16
	ds_write2st64_b64 v75, v[110:111], v[114:115] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b8 v[108:109], v76
	ds_read_b64_tr_b8 v[110:111], v76 offset:8192
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[48:49], v[48:49], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[46:47], v[46:47], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[44:45], v[44:45], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[42:43], v[42:43], v[88:89] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_fp8_fp8 v[46:49], v[108:109], v[132:133], v[46:49]
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	ds_read_b64_tr_b8 v[108:109], v77
	ds_read_b64_tr_b8 v[112:113], v76 offset:8320
	ds_read_b64_tr_b8 v[114:115], v76 offset:128
.Ltmp38:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v91, v91, v123
	v_add_f32_e32 v91, v124, v91
.Ltmp39:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[42:45], v[108:109], v[132:133], v[42:45]
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	ds_read_b64_tr_b8 v[108:109], v78
.Ltmp40:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v91, v125, v91
	v_add_f32_e32 v91, v126, v91
	v_add_f32_e32 v91, v127, v91
	v_add_f32_e32 v91, v128, v91
	v_add_f32_e32 v91, v129, v91
	v_add_f32_e32 v91, v130, v91
.Ltmp41:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_mfma_f32_16x16x32_fp8_fp8 v[46:49], v[110:111], v[134:135], v[46:49]
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	ds_read_b64_tr_b8 v[110:111], v77 offset:8192
	ds_read_b64_tr_b8 v[136:137], v77 offset:8320
	ds_read_b64_tr_b8 v[138:139], v77 offset:128
.Ltmp42:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v91, v116, v91
.Ltmp43:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[40:41], v[40:41], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[38:39], v[38:39], v[88:89] op_sel_hi:[1,0]
.Ltmp44:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v91, v117, v91
.Ltmp45:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[36:37], v[36:37], v[88:89] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[108:109], v[132:133], v[38:41]
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	ds_read_b64_tr_b8 v[108:109], v79
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[34:35], v[34:35], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[32:33], v[32:33], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[30:31], v[88:89] op_sel_hi:[1,0]
.Ltmp46:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v89, v89, v91
.Ltmp47:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[42:45], v[110:111], v[134:135], v[42:45]
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	ds_read_b64_tr_b8 v[110:111], v78 offset:8192
	ds_read_b64_tr_b8 v[122:123], v78 offset:8320
	ds_read_b64_tr_b8 v[140:141], v78 offset:128
.Ltmp48:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v89, v119, v89
.Ltmp49:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[28:29], v[28:29], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[26:27], v[26:27], v[88:89] op_sel_hi:[1,0]
.Ltmp50:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v89, v118, v89
	v_add_f32_e32 v89, v121, v89
.Ltmp51:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[110:111], v[134:135], v[38:41]
	.loc	1 339 24                        ; benchmark_qwen36_extend_attention_m756.py:339:24
	ds_read_b64_tr_b8 v[110:111], v79 offset:8192
	ds_read_b64_tr_b8 v[124:125], v79 offset:8320
	ds_read_b64_tr_b8 v[142:143], v79 offset:128
.Ltmp52:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v89, v120, v89
.Ltmp53:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ]
	v_mov_b32_e32 v91, v89
.Ltmp54:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[24:25], v[24:25], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[22:23], v[22:23], v[88:89] op_sel_hi:[1,0]
.Ltmp55:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ]
	v_permlane32_swap_b32_e32 v89, v91
.Ltmp56:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v89, v89, v91
.Ltmp57:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_pk_mul_f32 v[20:21], v[20:21], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[18:19], v[18:19], v[88:89] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[108:109], v[132:133], v[34:37]
.Ltmp58:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ]
	v_mov_b32_e32 v91, v89
	s_nop 1
	v_permlane16_swap_b32_e32 v89, v91
.Ltmp59:
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_mfma_f32_16x16x32_fp8_fp8 v[30:33], v[114:115], v[132:133], v[30:33]
.Ltmp60:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:332:43 ] ]
	v_add_f32_e32 v88, v89, v91
.Ltmp61:
	.loc	1 332 36                        ; benchmark_qwen36_extend_attention_m756.py:332:36
	v_fmac_f32_e32 v88, v55, v87
	v_mov_b32_e32 v55, v88
	.loc	1 341 43                        ; benchmark_qwen36_extend_attention_m756.py:341:43
	v_mfma_f32_16x16x32_fp8_fp8 v[26:29], v[138:139], v[132:133], v[26:29]
	v_mov_b32_e32 v87, v90
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[22:25], v[140:141], v[132:133], v[22:25]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_fp8_fp8 v[18:21], v[142:143], v[132:133], v[18:21]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[110:111], v[134:135], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[30:33], v[112:113], v[134:135], v[30:33]
	v_mfma_f32_16x16x32_fp8_fp8 v[26:29], v[136:137], v[134:135], v[26:29]
	v_mfma_f32_16x16x32_fp8_fp8 v[22:25], v[122:123], v[134:135], v[22:25]
	v_mfma_f32_16x16x32_fp8_fp8 v[18:21], v[124:125], v[134:135], v[18:21]
	s_branch .LBB0_5
.LBB0_8:
	.loc	1 0 43 is_stmt 0                ; benchmark_qwen36_extend_attention_m756.py:0:43
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v87, 0xff800000
	v_mov_b32_e32 v55, 0
.LBB0_9:                                ; %._crit_edge
	.loc	1 353 27 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:353:27
	s_lshl_b32 s0, s63, 9
	v_lshlrev_b32_e32 v2, 9, v59
	s_add_i32 s0, s0, s65
	v_or_b32_e32 v4, v2, v56
	v_or_b32_e32 v2, v2, v60
	v_lshlrev_b32_e32 v3, 9, v58
	v_or_b32_e32 v5, s0, v56
	.loc	1 353 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:353:16
	v_add_lshl_u32 v4, v4, s0, 1
	v_bfrev_b32_e32 v16, 1
	.loc	1 345 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:345:22
	v_cmp_gt_i32_e32 vcc, s57, v59
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	v_add_lshl_u32 v2, v2, s0, 1
	.loc	1 353 27 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:353:27
	v_or_b32_e32 v6, s0, v60
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	v_cndmask_b32_e32 v12, v16, v4, vcc
	v_cndmask_b32_e32 v17, v16, v2, vcc
	v_add_lshl_u32 v2, v5, v3, 1
	.loc	1 345 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:345:22
	v_cmp_gt_i32_e32 vcc, s57, v58
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e32 v13, v16, v2, vcc
	v_add_lshl_u32 v2, v6, v3, 1
	buffer_load_dwordx4 v[64:67], v12, s[4:7], 0 offen
	buffer_load_dwordx4 v[68:71], v17, s[4:7], 0 offen
	v_cndmask_b32_e32 v58, v16, v2, vcc
	buffer_load_dwordx4 v[72:75], v13, s[4:7], 0 offen
	buffer_load_dwordx4 v[76:79], v58, s[4:7], 0 offen
	.loc	1 298 16                        ; benchmark_qwen36_extend_attention_m756.py:298:16
	v_or_b32_e32 v3, s64, v56
	v_xor_b32_e32 v2, v50, v62
	v_bitop3_b32 v4, s64, v53, v56 bitop3:0x36
	s_movk_i32 s4, 0x80
	s_movk_i32 s5, 0xc0
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	v_bitop3_b32 v5, v63, v53, v56 bitop3:0x36
	.loc	1 298 16                        ; benchmark_qwen36_extend_attention_m756.py:298:16
	v_bitop3_b32 v3, v3, v63, v53 bitop3:0xde
	v_add_u32_e32 v11, 0, v2
	v_bitop3_b32 v14, v4, s4, v63 bitop3:0x36
	v_bitop3_b32 v4, v4, s5, v63 bitop3:0x36
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	v_add_u32_e32 v15, 0, v5
	.loc	1 298 16                        ; benchmark_qwen36_extend_attention_m756.py:298:16
	v_add_u32_e32 v56, 0, v3
	v_xad_u32 v2, v2, 16, 0
	v_xad_u32 v3, v3, 64, 0
	v_add_u32_e32 v14, 0, v14
	v_add_u32_e32 v4, 0, v4
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v11, v[96:99]
	ds_write_b128 v11, v[104:107] offset:16384
	ds_write_b128 v2, v[92:95]
	ds_write_b128 v2, v[100:103] offset:16384
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[80:83], v56
	ds_read_b128 v[88:91], v56 offset:256
	ds_read_b128 v[92:95], v3
	ds_read_b128 v[96:99], v3 offset:256
	ds_read_b128 v[100:103], v14
	ds_read_b128 v[104:107], v14 offset:256
	ds_read_b128 v[108:111], v4
	ds_read_b128 v[112:115], v4 offset:256
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_xor_b32_e32 v14, 0xc0, v5
	.loc	1 281 31                        ; benchmark_qwen36_extend_attention_m756.py:281:31
	v_or_b32_e32 v6, 1, v61
	v_or_b32_e32 v7, 2, v61
	v_or_b32_e32 v8, 3, v61
	.loc	1 345 22                        ; benchmark_qwen36_extend_attention_m756.py:345:22
	v_cmp_gt_i32_e32 vcc, s57, v61
	.loc	1 347 41                        ; benchmark_qwen36_extend_attention_m756.py:347:41
	v_cmp_ge_u32_e64 s[0:1], v1, v61
	v_cmp_gt_u32_e64 s[4:5], v1, v61
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	v_add_u32_e32 v14, 0, v14
	.loc	1 345 22                        ; benchmark_qwen36_extend_attention_m756.py:345:22
	v_cmp_gt_i32_e64 s[10:11], s57, v6
	.loc	1 347 18                        ; benchmark_qwen36_extend_attention_m756.py:347:18
	s_and_b64 s[0:1], s[0:1], vcc
	.loc	1 345 22                        ; benchmark_qwen36_extend_attention_m756.py:345:22
	v_cmp_gt_i32_e64 s[12:13], s57, v7
	.loc	1 347 41                        ; benchmark_qwen36_extend_attention_m756.py:347:41
	v_cmp_ge_u32_e64 s[16:17], v1, v7
	.loc	1 347 18 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:347:18
	s_and_b64 s[4:5], s[4:5], s[10:11]
	s_and_b64 vcc, s[2:3], s[0:1]
	.loc	1 345 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:345:22
	v_cmp_gt_i32_e64 s[14:15], s57, v8
	.loc	1 347 41                        ; benchmark_qwen36_extend_attention_m756.py:347:41
	v_cmp_ge_u32_e64 s[18:19], v1, v8
	.loc	1 347 18 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:347:18
	s_and_b64 s[10:11], s[16:17], s[12:13]
	s_and_b64 s[12:13], s[18:19], s[14:15]
	s_mov_b32 s20, 0xff800000
	.loc	1 296 17 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:296:17
	v_lshrrev_b32_e32 v9, 2, v57
	.loc	1 378 22                        ; benchmark_qwen36_extend_attention_m756.py:378:22
	v_lshlrev_b32_e32 v10, 12, v1
	.loc	1 359 21                        ; benchmark_qwen36_extend_attention_m756.py:359:21
	v_not_b32_e32 v57, 63
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	s_and_b32 s41, s41, 0xffff
	s_mov_b32 s42, s6
	s_mov_b32 s43, s7
	.loc	1 370 25                        ; benchmark_qwen36_extend_attention_m756.py:370:25
	v_lshlrev_b32_e32 v1, 1, v1
	v_lshl_or_b32 v1, v53, 5, v1
	v_and_b32_e32 v51, 24, v51
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	s_and_b32 s9, s9, 0xffff
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	s_waitcnt vmcnt(3)
	ds_write_b128 v11, v[64:67]
	s_waitcnt vmcnt(2)
	ds_write_b128 v2, v[68:71]
	s_waitcnt vmcnt(1)
	ds_write_b128 v11, v[72:75] offset:16384
	s_waitcnt vmcnt(0)
	ds_write_b128 v2, v[76:79] offset:16384
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[62:65], v15
	v_xad_u32 v11, v5, 64, 0
	ds_read_b128 v[66:69], v11
	v_xor_b32_e32 v2, 0x80, v5
	v_add_u32_e32 v56, 0, v2
	.loc	1 354 31                        ; benchmark_qwen36_extend_attention_m756.py:354:31
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[62:65], v[80:83], 0
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	ds_read_b128 v[70:73], v15 offset:256
	ds_read_b128 v[74:77], v56
	ds_read_b128 v[60:63], v11 offset:256
	ds_read_b128 v[78:81], v14
	.loc	1 355 34                        ; benchmark_qwen36_extend_attention_m756.py:355:34
	v_mov_b32_e32 v11, 0xff800000
	.loc	1 354 31                        ; benchmark_qwen36_extend_attention_m756.py:354:31
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[66:69], v[92:95], v[2:5]
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	ds_read_b128 v[64:67], v56 offset:256
	.loc	1 357 58                        ; benchmark_qwen36_extend_attention_m756.py:357:58
	v_mov_b32_e32 v15, 0xe0ad78ec
	.loc	1 296 17                        ; benchmark_qwen36_extend_attention_m756.py:296:17
	v_and_b32_e32 v68, 28, v9
	.loc	1 354 31                        ; benchmark_qwen36_extend_attention_m756.py:354:31
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[74:77], v[100:103], v[2:5]
	.loc	1 353 16                        ; benchmark_qwen36_extend_attention_m756.py:353:16
	ds_read_b128 v[74:77], v14 offset:256
	.loc	1 358 35                        ; benchmark_qwen36_extend_attention_m756.py:358:35
	v_max_f32_e32 v56, v87, v87
	.loc	1 378 22                        ; benchmark_qwen36_extend_attention_m756.py:378:22
	v_lshl_or_b32 v69, s55, 1, v10
	.loc	1 354 31                        ; benchmark_qwen36_extend_attention_m756.py:354:31
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[78:81], v[108:111], v[2:5]
	.loc	1 378 22                        ; benchmark_qwen36_extend_attention_m756.py:378:22
	v_add_u32_e32 v6, s33, v69
	.loc	1 354 31                        ; benchmark_qwen36_extend_attention_m756.py:354:31
	v_mfma_f32_16x16x32_bf16 v[2:5], v[70:73], v[88:91], v[2:5]
	.loc	1 296 17                        ; benchmark_qwen36_extend_attention_m756.py:296:17
	v_or_b32_e32 v70, v68, v6
	.loc	1 354 31                        ; benchmark_qwen36_extend_attention_m756.py:354:31
	v_mfma_f32_16x16x32_bf16 v[2:5], v[60:63], v[96:99], v[2:5]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[64:67], v[104:107], v[2:5]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[74:77], v[112:115], v[2:5]
	.loc	1 354 58 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:354:58
	s_nop 7
	v_mul_f32_e32 v2, s62, v2
	v_mul_f32_e32 v3, s62, v3
	.loc	1 355 34 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:355:34
	v_cndmask_b32_e32 v2, v11, v2, vcc
	.loc	1 347 18                        ; benchmark_qwen36_extend_attention_m756.py:347:18
	s_and_b64 vcc, s[2:3], s[4:5]
	.loc	1 354 58                        ; benchmark_qwen36_extend_attention_m756.py:354:58
	v_mul_f32_e32 v4, s62, v4
	.loc	1 355 34                        ; benchmark_qwen36_extend_attention_m756.py:355:34
	v_cndmask_b32_e32 v3, v11, v3, vcc
	.loc	1 347 18                        ; benchmark_qwen36_extend_attention_m756.py:347:18
	s_and_b64 vcc, s[2:3], s[10:11]
	.loc	1 354 58                        ; benchmark_qwen36_extend_attention_m756.py:354:58
	v_mul_f32_e32 v5, s62, v5
	.loc	1 355 34                        ; benchmark_qwen36_extend_attention_m756.py:355:34
	v_cndmask_b32_e32 v4, v11, v4, vcc
	.loc	1 347 18                        ; benchmark_qwen36_extend_attention_m756.py:347:18
	s_and_b64 vcc, s[2:3], s[12:13]
	.loc	1 355 34                        ; benchmark_qwen36_extend_attention_m756.py:355:34
	v_cndmask_b32_e32 v5, v11, v5, vcc
.Ltmp62:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:356:21 ] ]
	v_max3_f32 v7, v2, v3, v4
	v_max3_f32 v7, v7, v5, s20
.Ltmp63:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:356:21 ]
	v_mov_b32_e32 v8, v7
	s_nop 1
	v_permlane32_swap_b32_e32 v7, v8
.Ltmp64:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:356:21 ] ]
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v7, v7, v7
	v_max_f32_e32 v7, v7, v8
.Ltmp65:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:356:21 ]
	v_mov_b32_e32 v8, v7
	s_nop 1
	v_permlane16_swap_b32_e32 v7, v8
.Ltmp66:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:356:21 ] ]
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v7, v7, v7
	v_max_f32_e32 v7, v7, v8
.Ltmp67:
	.loc	1 357 58                        ; benchmark_qwen36_extend_attention_m756.py:357:58
	v_cmp_neq_f32_e32 vcc, s20, v7
	s_mov_b32 s4, 0xc2fc0000
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	s_mov_b32 s10, s6
	.loc	1 357 58                        ; benchmark_qwen36_extend_attention_m756.py:357:58
	v_cndmask_b32_e32 v7, v15, v7, vcc
	.loc	1 358 35                        ; benchmark_qwen36_extend_attention_m756.py:358:35
	v_max_f32_e32 v7, v7, v56
	.loc	1 359 29                        ; benchmark_qwen36_extend_attention_m756.py:359:29
	v_sub_f32_e32 v8, v87, v7
	.loc	1 359 21 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:359:21
	v_mul_f32_e32 v9, 0x3fb8aa3b, v8
	v_mov_b32_e32 v56, 0x42800000
	v_cmp_gt_f32_e32 vcc, s4, v9
	.loc	1 360 32 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:360:32
	v_sub_f32_e32 v2, v2, v7
	v_sub_f32_e32 v3, v3, v7
	.loc	1 359 21                        ; benchmark_qwen36_extend_attention_m756.py:359:21
	v_cndmask_b32_e32 v9, 0, v56, vcc
	v_fmac_f32_e32 v9, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v9
	v_cndmask_b32_e32 v6, 0, v57, vcc
	.loc	1 360 32                        ; benchmark_qwen36_extend_attention_m756.py:360:32
	v_sub_f32_e32 v59, v5, v7
	v_sub_f32_e32 v4, v4, v7
	.loc	1 359 21                        ; benchmark_qwen36_extend_attention_m756.py:359:21
	v_ldexp_f32 v71, v8, v6
	.loc	1 360 27                        ; benchmark_qwen36_extend_attention_m756.py:360:27
	v_mul_f32_e32 v6, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e32 vcc, s4, v6
	.loc	1 360 32 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:360:32
	v_sub_f32_e32 v60, 0xff800000, v7
	.loc	1 378 38 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:378:38
	s_mov_b32 s11, s7
	.loc	1 360 27                        ; benchmark_qwen36_extend_attention_m756.py:360:27
	v_cndmask_b32_e32 v6, 0, v56, vcc
	v_fmac_f32_e32 v6, 0x3fb8aa3b, v2
	v_exp_f32_e32 v2, v6
	v_cndmask_b32_e32 v5, 0, v57, vcc
	v_ldexp_f32 v61, v2, v5
	v_mul_f32_e32 v2, 0x3fb8aa3b, v3
	v_cmp_gt_f32_e32 vcc, s4, v2
	s_nop 1
	v_cndmask_b32_e32 v2, 0, v56, vcc
	v_fmac_f32_e32 v2, 0x3fb8aa3b, v3
	v_exp_f32_e32 v2, v2
	v_mul_f32_e32 v3, 0x3fb8aa3b, v4
	v_cmp_gt_f32_e64 s[0:1], s4, v3
	s_nop 1
	v_cndmask_b32_e64 v3, 0, v56, s[0:1]
	v_fmac_f32_e32 v3, 0x3fb8aa3b, v4
	v_cndmask_b32_e32 v4, 0, v57, vcc
	v_ldexp_f32 v62, v2, v4
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	buffer_load_dwordx4 v[4:7], v12, s[40:43], 0 offen
	buffer_load_dwordx4 v[8:11], v13, s[40:43], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[12:15], v17, s[40:43], 0 offen
	buffer_load_dwordx4 v[64:67], v58, s[40:43], 0 offen
	.loc	1 360 27                        ; benchmark_qwen36_extend_attention_m756.py:360:27
	v_exp_f32_e32 v3, v3
	v_cndmask_b32_e64 v2, 0, v57, s[0:1]
	v_mul_f32_e32 v17, 0x3fb8aa3b, v60
	v_cmp_gt_f32_e64 s[0:1], s4, v17
	v_ldexp_f32 v3, v3, v2
	v_mul_f32_e32 v2, 0x3fb8aa3b, v59
	v_cmp_gt_f32_e32 vcc, s4, v2
	v_cndmask_b32_e64 v17, 0, v56, s[0:1]
	v_fmac_f32_e32 v17, 0x3fb8aa3b, v60
	v_cndmask_b32_e32 v2, 0, v56, vcc
	v_fmac_f32_e32 v2, 0x3fb8aa3b, v59
	v_exp_f32_e32 v2, v2
	v_cndmask_b32_e32 v56, 0, v57, vcc
	v_exp_f32_e32 v17, v17
	.loc	1 369 16                        ; benchmark_qwen36_extend_attention_m756.py:369:16
	s_waitcnt lgkmcnt(0)
	.loc	1 360 27                        ; benchmark_qwen36_extend_attention_m756.py:360:27
	v_ldexp_f32 v56, v2, v56
	v_cndmask_b32_e64 v2, 0, v57, s[0:1]
	.loc	1 369 16                        ; benchmark_qwen36_extend_attention_m756.py:369:16
	s_add_i32 s0, s59, 0
	s_add_i32 s0, s0, s60
	v_add_u32_e32 v73, s0, v54
	s_add_i32 s0, s58, 0
	s_add_i32 s0, s0, s61
	v_add_u32_e32 v54, s0, v54
	.loc	1 370 25                        ; benchmark_qwen36_extend_attention_m756.py:370:25
	s_lshr_b32 s0, s54, 1
	.loc	1 360 27                        ; benchmark_qwen36_extend_attention_m756.py:360:27
	v_ldexp_f32 v17, v17, v2
.Ltmp68:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v2, v61, v62
.Ltmp69:
	.loc	1 370 25                        ; benchmark_qwen36_extend_attention_m756.py:370:25
	v_bitop3_b32 v1, s0, v53, v1 bitop3:0x36
.Ltmp70:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v2, v3, v2
.Ltmp71:
	.loc	1 370 25                        ; benchmark_qwen36_extend_attention_m756.py:370:25
	v_add_u32_e32 v53, 0, v1
	v_cvt_pk_bf16_f32 v57, v61, s0
.Ltmp72:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v72, v56, v2
.Ltmp73:
	.loc	1 369 16                        ; benchmark_qwen36_extend_attention_m756.py:369:16
	s_barrier
	ds_write_b32 v73, v71
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v2, v54
	.loc	1 370 25                        ; benchmark_qwen36_extend_attention_m756.py:370:25
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v53, v57
	v_cvt_pk_bf16_f32 v57, v62, s0
	v_xad_u32 v1, v1, 8, 0
	v_cvt_pk_bf16_f32 v3, v3, s0
	ds_write_b16 v53, v57 offset:128
	v_cvt_pk_bf16_f32 v57, v17, s0
	ds_write_b16 v1, v3 offset:256
	v_cvt_pk_bf16_f32 v3, v56, s0
	ds_write_b16 v53, v57 offset:2048
	ds_write_b16 v53, v57 offset:2176
	ds_write_b16 v53, v57 offset:4096
	ds_write_b16 v53, v57 offset:4224
	ds_write_b16 v53, v57 offset:6144
	ds_write_b16 v53, v57 offset:6272
	ds_write_b16 v1, v3 offset:384
	ds_write_b16 v1, v57 offset:2304
	ds_write_b16 v1, v57 offset:2432
	ds_write_b16 v1, v57 offset:4352
	ds_write_b16 v1, v57 offset:4480
	ds_write_b16 v1, v57 offset:6400
	ds_write_b16 v1, v57 offset:6528
	v_and_b32_e32 v1, 60, v0
	v_lshlrev_b32_e32 v3, 5, v1
	v_and_b32_e32 v0, 56, v0
	s_lshr_b32 s0, s55, 2
	v_bitop3_b32 v0, v3, v0, v51 bitop3:0x36
	v_xor_b32_e32 v0, s0, v0
	v_add_u32_e32 v0, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[60:61], v0
	ds_read_b64_tr_b16 v[62:63], v0 offset:2048
	ds_read_b64_tr_b16 v[56:57], v0 offset:4096
	ds_read_b64_tr_b16 v[58:59], v0 offset:6144
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	v_xor_b32_e32 v0, v52, v50
	v_add_u32_e32 v3, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_lshr_b32 s0, s56, 1
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v3, v[4:5], v[8:9] offset1:32
	v_xad_u32 v3, v0, 8, 0
	ds_write2st64_b64 v3, v[6:7], v[10:11] offset1:32
	v_xad_u32 v3, v0, 16, 0
	v_xad_u32 v0, v0, 24, 0
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v3, v[12:13], v[64:65] offset1:32
	ds_write2st64_b64 v0, v[14:15], v[66:67] offset1:32
	v_lshlrev_b32_e32 v0, 7, v1
	v_lshlrev_b32_e32 v1, 1, v1
	v_bitop3_b32 v0, v0, v1, v51 bitop3:0x36
	v_xor_b32_e32 v0, s0, v0
	v_add_u32_e32 v1, 0, v0
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[6:7], v[48:49], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[46:47], v[2:3] op_sel_hi:[1,0]
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[8:9], v1
	ds_read_b64_tr_b16 v[12:13], v1 offset:128
	ds_read_b64_tr_b16 v[50:51], v1 offset:256
	ds_read_b64_tr_b16 v[64:65], v1 offset:384
	ds_read_b64_tr_b16 v[10:11], v1 offset:8192
	ds_read_b64_tr_b16 v[14:15], v1 offset:8320
	ds_read_b64_tr_b16 v[52:53], v1 offset:8448
	ds_read_b64_tr_b16 v[66:67], v1 offset:8576
	ds_read_b64_tr_b16 v[74:75], v1 offset:16384
	ds_read_b64_tr_b16 v[78:79], v1 offset:16512
	ds_read_b64_tr_b16 v[82:83], v1 offset:16640
	ds_read_b64_tr_b16 v[86:87], v1 offset:16768
	ds_read_b64_tr_b16 v[76:77], v1 offset:24576
	ds_read_b64_tr_b16 v[80:81], v1 offset:24704
	ds_read_b64_tr_b16 v[84:85], v1 offset:24832
	ds_read_b64_tr_b16 v[88:89], v1 offset:24960
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[8:11], v[60:63], v[4:7]
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	v_xad_u32 v0, v0, 64, 0
	ds_read_b64_tr_b16 v[92:93], v0 offset:24576
	ds_read_b64_tr_b16 v[94:95], v0
	ds_read_b64_tr_b16 v[98:99], v0 offset:128
	ds_read_b64_tr_b16 v[102:103], v0 offset:256
	ds_read_b64_tr_b16 v[106:107], v0 offset:384
	ds_read_b64_tr_b16 v[96:97], v0 offset:8192
	ds_read_b64_tr_b16 v[100:101], v0 offset:8320
	ds_read_b64_tr_b16 v[104:105], v0 offset:8448
	ds_read_b64_tr_b16 v[108:109], v0 offset:8576
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	s_waitcnt lgkmcnt(12)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[74:77], v[56:59], v[4:7]
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	ds_read_b64_tr_b16 v[90:91], v0 offset:16384
	ds_read_b64_tr_b16 v[8:9], v0 offset:16512
	ds_read_b64_tr_b16 v[74:75], v0 offset:16640
	ds_read_b64_tr_b16 v[110:111], v0 offset:16768
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[6:7], v[44:45], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[42:43], v[2:3] op_sel_hi:[1,0]
	.loc	1 368 16                        ; benchmark_qwen36_extend_attention_m756.py:368:16
	ds_read_b64_tr_b16 v[10:11], v0 offset:24704
	ds_read_b64_tr_b16 v[76:77], v0 offset:24832
	ds_read_b64_tr_b16 v[112:113], v0 offset:24960
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[94:97], v[60:63], v[4:7]
.Ltmp74:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v17, v72
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp75:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[90:93], v[56:59], v[4:7]
.Ltmp76:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp77:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[6:7], v[40:41], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[38:39], v[2:3] op_sel_hi:[1,0]
.Ltmp78:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp79:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[12:15], v[60:63], v[4:7]
.Ltmp80:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp81:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[38:41], v[78:81], v[56:59], v[4:7]
.Ltmp82:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v17, v0
.Ltmp83:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ]
	v_mov_b32_e32 v1, v0
	s_nop 1
	v_permlane32_swap_b32_e32 v0, v1
.Ltmp84:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[6:7], v[36:37], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[34:35], v[2:3] op_sel_hi:[1,0]
.Ltmp85:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v0, v1
.Ltmp86:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ]
	v_mov_b32_e32 v1, v0
.Ltmp87:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[98:101], v[60:63], v[4:7]
.Ltmp88:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ]
	s_nop 0
	v_permlane16_swap_b32_e32 v0, v1
.Ltmp89:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:361:35 ] ]
	v_add_f32_e32 v0, v0, v1
.Ltmp90:
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[8:11], v[56:59], v[4:7]
	.loc	1 361 28                        ; benchmark_qwen36_extend_attention_m756.py:361:28
	v_fmac_f32_e32 v0, v55, v71
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[6:7], v[32:33], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[30:31], v[2:3] op_sel_hi:[1,0]
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	ds_write_b32 v73, v0
	s_waitcnt lgkmcnt(0)
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[50:53], v[60:63], v[4:7]
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	s_barrier
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[20:21], v[20:21], v[2:3] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[12:15], v[82:85], v[56:59], v[4:7]
	v_mul_f32_e64 v18, v18, v2
	v_mul_f32_e64 v19, v19, v2
	.loc	1 378 22                        ; benchmark_qwen36_extend_attention_m756.py:378:22
	v_lshlrev_b32_e32 v17, 1, v70
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	s_nop 1
	v_pk_mul_f32 v[6:7], v[28:29], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[26:27], v[2:3] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[4:7], v[102:105], v[60:63], v[4:7]
	v_mfma_f32_16x16x32_bf16 v[8:11], v[74:77], v[56:59], v[4:7]
	s_nop 6
	v_mul_f32_e64 v4, v22, v2
	v_mul_f32_e64 v5, v23, v2
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	ds_read_b32 v22, v54
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_pk_mul_f32 v[6:7], v[24:25], v[2:3] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[0:3], v[106:109], v[60:63], v[18:21]
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	s_waitcnt lgkmcnt(0)
	s_nop 1
	v_div_scale_f32 v19, s[0:1], v22, v22, v46
	v_rcp_f32_e32 v20, v19
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[64:67], v[60:63], v[4:7]
	.loc	1 378 22                        ; benchmark_qwen36_extend_attention_m756.py:378:22
	v_or_b32_e32 v18, v68, v69
	.loc	1 378 38 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_add_lshl_u32 v18, v18, s33, 1
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v21, -v19, v20, 1.0
	v_fmac_f32_e32 v20, v21, v20
	v_div_scale_f32 v21, vcc, v46, v22, v46
	v_mul_f32_e32 v23, v21, v20
	v_fma_f32 v24, -v19, v23, v21
	v_fmac_f32_e32 v23, v24, v20
	v_fma_f32 v19, -v19, v23, v21
	v_div_scale_f32 v21, s[0:1], v22, v22, v47
	v_rcp_f32_e32 v24, v21
	v_div_fmas_f32 v19, v19, v20, v23
	.loc	1 370 35 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[86:89], v[56:59], v[4:7]
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_div_fixup_f32 v19, v19, v22, v46
	v_fma_f32 v20, -v21, v24, 1.0
	v_fmac_f32_e32 v24, v20, v24
	v_div_scale_f32 v20, vcc, v47, v22, v47
	v_mul_f32_e32 v23, v20, v24
	v_fma_f32 v25, -v21, v23, v20
	v_fmac_f32_e32 v23, v25, v24
	v_fma_f32 v20, -v21, v23, v20
	v_div_scale_f32 v21, s[0:1], v22, v22, v48
	v_rcp_f32_e32 v25, v21
	v_div_fmas_f32 v20, v20, v24, v23
	.loc	1 370 35                        ; benchmark_qwen36_extend_attention_m756.py:370:35
	v_mfma_f32_16x16x32_bf16 v[0:3], v[110:113], v[56:59], v[0:3]
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_div_fixup_f32 v20, v20, v22, v47
	v_fma_f32 v23, -v21, v25, 1.0
	v_fmac_f32_e32 v25, v23, v25
	v_div_scale_f32 v23, vcc, v48, v22, v48
	v_mul_f32_e32 v24, v23, v25
	v_fma_f32 v26, -v21, v24, v23
	v_fmac_f32_e32 v24, v26, v25
	v_fma_f32 v21, -v21, v24, v23
	v_div_scale_f32 v23, s[0:1], v22, v22, v49
	v_rcp_f32_e32 v26, v23
	v_div_fmas_f32 v21, v21, v25, v24
	v_div_fixup_f32 v21, v21, v22, v48
	.loc	1 378 38 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cndmask_b32_e64 v18, v16, v18, s[2:3]
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v24, -v23, v26, 1.0
	v_fmac_f32_e32 v26, v24, v26
	v_div_scale_f32 v24, vcc, v49, v22, v49
	v_mul_f32_e32 v25, v24, v26
	v_fma_f32 v27, -v23, v25, v24
	v_fmac_f32_e32 v25, v27, v26
	v_fma_f32 v23, -v23, v25, v24
	v_div_scale_f32 v24, s[0:1], v22, v22, v42
	v_rcp_f32_e32 v27, v24
	v_div_fmas_f32 v23, v23, v26, v25
	v_div_fixup_f32 v23, v23, v22, v49
	v_fma_f32 v25, -v24, v27, 1.0
	v_fmac_f32_e32 v27, v25, v27
	v_div_scale_f32 v25, vcc, v42, v22, v42
	v_mul_f32_e32 v26, v25, v27
	v_fma_f32 v28, -v24, v26, v25
	v_fmac_f32_e32 v26, v28, v27
	v_fma_f32 v24, -v24, v26, v25
	v_div_scale_f32 v25, s[0:1], v22, v22, v43
	v_rcp_f32_e32 v28, v25
	v_div_fmas_f32 v24, v24, v27, v26
	v_div_fixup_f32 v24, v24, v22, v42
	v_fma_f32 v26, -v25, v28, 1.0
	v_fmac_f32_e32 v28, v26, v28
	v_div_scale_f32 v26, vcc, v43, v22, v43
	v_mul_f32_e32 v27, v26, v28
	v_fma_f32 v29, -v25, v27, v26
	v_fmac_f32_e32 v27, v29, v28
	v_fma_f32 v25, -v25, v27, v26
	v_div_scale_f32 v26, s[0:1], v22, v22, v44
	v_rcp_f32_e32 v29, v26
	v_div_fmas_f32 v25, v25, v28, v27
	v_div_fixup_f32 v25, v25, v22, v43
	v_fma_f32 v27, -v26, v29, 1.0
	v_fmac_f32_e32 v29, v27, v29
	v_div_scale_f32 v27, vcc, v44, v22, v44
	v_mul_f32_e32 v28, v27, v29
	v_fma_f32 v30, -v26, v28, v27
	v_fmac_f32_e32 v28, v30, v29
	v_fma_f32 v26, -v26, v28, v27
	v_div_scale_f32 v27, s[0:1], v22, v22, v45
	v_rcp_f32_e32 v30, v27
	v_div_fmas_f32 v26, v26, v29, v28
	v_div_fixup_f32 v26, v26, v22, v44
	v_fma_f32 v28, -v27, v30, 1.0
	v_fmac_f32_e32 v30, v28, v30
	v_div_scale_f32 v28, vcc, v45, v22, v45
	v_mul_f32_e32 v29, v28, v30
	v_fma_f32 v31, -v27, v29, v28
	v_fmac_f32_e32 v29, v31, v30
	v_fma_f32 v27, -v27, v29, v28
	v_div_scale_f32 v28, s[0:1], v22, v22, v38
	v_rcp_f32_e32 v31, v28
	v_div_fmas_f32 v27, v27, v30, v29
	v_div_fixup_f32 v27, v27, v22, v45
	v_fma_f32 v29, -v28, v31, 1.0
	v_fmac_f32_e32 v31, v29, v31
	v_div_scale_f32 v29, vcc, v38, v22, v38
	v_mul_f32_e32 v30, v29, v31
	v_fma_f32 v32, -v28, v30, v29
	v_fmac_f32_e32 v30, v32, v31
	v_fma_f32 v28, -v28, v30, v29
	v_div_scale_f32 v29, s[0:1], v22, v22, v39
	v_rcp_f32_e32 v32, v29
	v_div_fmas_f32 v28, v28, v31, v30
	v_div_fixup_f32 v28, v28, v22, v38
	v_fma_f32 v30, -v29, v32, 1.0
	v_fmac_f32_e32 v32, v30, v32
	v_div_scale_f32 v30, vcc, v39, v22, v39
	v_mul_f32_e32 v31, v30, v32
	v_fma_f32 v33, -v29, v31, v30
	v_fmac_f32_e32 v31, v33, v32
	v_fma_f32 v29, -v29, v31, v30
	v_div_scale_f32 v30, s[0:1], v22, v22, v40
	v_rcp_f32_e32 v33, v30
	v_div_fmas_f32 v29, v29, v32, v31
	v_div_fixup_f32 v29, v29, v22, v39
	v_fma_f32 v31, -v30, v33, 1.0
	v_fmac_f32_e32 v33, v31, v33
	v_div_scale_f32 v31, vcc, v40, v22, v40
	v_mul_f32_e32 v32, v31, v33
	v_fma_f32 v38, -v30, v32, v31
	v_fmac_f32_e32 v32, v38, v33
	v_fma_f32 v30, -v30, v32, v31
	v_div_scale_f32 v31, s[0:1], v22, v22, v41
	v_rcp_f32_e32 v38, v31
	v_div_fmas_f32 v30, v30, v33, v32
	v_div_fixup_f32 v30, v30, v22, v40
	v_fma_f32 v32, -v31, v38, 1.0
	v_fmac_f32_e32 v38, v32, v38
	v_div_scale_f32 v32, vcc, v41, v22, v41
	v_mul_f32_e32 v33, v32, v38
	v_fma_f32 v39, -v31, v33, v32
	v_fmac_f32_e32 v33, v39, v38
	v_fma_f32 v31, -v31, v33, v32
	v_div_scale_f32 v32, s[0:1], v22, v22, v34
	v_rcp_f32_e32 v39, v32
	v_div_fmas_f32 v31, v31, v38, v33
	v_div_fixup_f32 v31, v31, v22, v41
	v_fma_f32 v33, -v32, v39, 1.0
	v_fmac_f32_e32 v39, v33, v39
	v_div_scale_f32 v33, vcc, v34, v22, v34
	v_mul_f32_e32 v38, v33, v39
	v_fma_f32 v40, -v32, v38, v33
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v32, -v32, v38, v33
	v_div_scale_f32 v33, s[0:1], v22, v22, v35
	v_rcp_f32_e32 v40, v33
	v_div_fmas_f32 v32, v32, v39, v38
	v_div_fixup_f32 v32, v32, v22, v34
	v_fma_f32 v34, -v33, v40, 1.0
	v_fmac_f32_e32 v40, v34, v40
	v_div_scale_f32 v34, vcc, v35, v22, v35
	v_mul_f32_e32 v38, v34, v40
	v_fma_f32 v39, -v33, v38, v34
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v33, -v33, v38, v34
	v_div_scale_f32 v34, s[0:1], v22, v22, v36
	v_rcp_f32_e32 v39, v34
	v_div_fmas_f32 v33, v33, v40, v38
	v_div_fixup_f32 v33, v33, v22, v35
	v_fma_f32 v35, -v34, v39, 1.0
	v_fmac_f32_e32 v39, v35, v39
	v_div_scale_f32 v35, vcc, v36, v22, v36
	v_mul_f32_e32 v38, v35, v39
	v_fma_f32 v40, -v34, v38, v35
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v34, -v34, v38, v35
	v_div_scale_f32 v35, s[0:1], v22, v22, v37
	v_rcp_f32_e32 v40, v35
	v_div_fmas_f32 v34, v34, v39, v38
	v_div_fixup_f32 v34, v34, v22, v36
	v_fma_f32 v36, -v35, v40, 1.0
	v_fmac_f32_e32 v40, v36, v40
	v_div_scale_f32 v36, vcc, v37, v22, v37
	v_mul_f32_e32 v38, v36, v40
	v_fma_f32 v39, -v35, v38, v36
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v35, -v35, v38, v36
	v_div_scale_f32 v36, s[0:1], v22, v22, v12
	v_rcp_f32_e32 v39, v36
	v_div_fmas_f32 v35, v35, v40, v38
	v_div_fixup_f32 v35, v35, v22, v37
	v_fma_f32 v37, -v36, v39, 1.0
	v_fmac_f32_e32 v39, v37, v39
	v_div_scale_f32 v37, vcc, v12, v22, v12
	v_mul_f32_e32 v38, v37, v39
	v_fma_f32 v40, -v36, v38, v37
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v36, -v36, v38, v37
	v_div_scale_f32 v37, s[0:1], v22, v22, v13
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v36, v36, v39, v38
	v_div_fixup_f32 v12, v36, v22, v12
	v_fma_f32 v36, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v36, v40
	v_div_scale_f32 v36, vcc, v13, v22, v13
	v_mul_f32_e32 v38, v36, v40
	v_fma_f32 v39, -v37, v38, v36
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v14
	v_rcp_f32_e32 v39, v37
	v_div_fmas_f32 v36, v36, v40, v38
	v_div_fixup_f32 v13, v36, v22, v13
	v_fma_f32 v36, -v37, v39, 1.0
	v_fmac_f32_e32 v39, v36, v39
	v_div_scale_f32 v36, vcc, v14, v22, v14
	v_mul_f32_e32 v38, v36, v39
	v_fma_f32 v40, -v37, v38, v36
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v15
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v36, v36, v39, v38
	v_div_fixup_f32 v14, v36, v22, v14
	v_fma_f32 v36, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v36, v40
	v_div_scale_f32 v36, vcc, v15, v22, v15
	v_mul_f32_e32 v38, v36, v40
	v_fma_f32 v39, -v37, v38, v36
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v8
	v_rcp_f32_e32 v39, v37
	v_div_fmas_f32 v36, v36, v40, v38
	v_div_fixup_f32 v15, v36, v22, v15
	v_fma_f32 v36, -v37, v39, 1.0
	v_fmac_f32_e32 v39, v36, v39
	v_div_scale_f32 v36, vcc, v8, v22, v8
	v_mul_f32_e32 v38, v36, v39
	v_fma_f32 v40, -v37, v38, v36
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v9
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v36, v36, v39, v38
	v_div_fixup_f32 v36, v36, v22, v8
	v_fma_f32 v8, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v8, v40
	v_div_scale_f32 v8, vcc, v9, v22, v9
	v_mul_f32_e32 v38, v8, v40
	v_fma_f32 v39, -v37, v38, v8
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v8, -v37, v38, v8
	v_div_scale_f32 v37, s[0:1], v22, v22, v10
	v_rcp_f32_e32 v39, v37
	v_div_fmas_f32 v8, v8, v40, v38
	v_div_fixup_f32 v38, v8, v22, v9
	v_fma_f32 v8, -v37, v39, 1.0
	v_fmac_f32_e32 v39, v8, v39
	v_div_scale_f32 v8, vcc, v10, v22, v10
	v_mul_f32_e32 v9, v8, v39
	v_fma_f32 v40, -v37, v9, v8
	v_fmac_f32_e32 v9, v40, v39
	v_fma_f32 v8, -v37, v9, v8
	v_div_scale_f32 v37, s[0:1], v22, v22, v11
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v8, v8, v39, v9
	v_div_fixup_f32 v39, v8, v22, v10
	v_fma_f32 v8, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v8, v40
	v_div_scale_f32 v8, vcc, v11, v22, v11
	v_mul_f32_e32 v9, v8, v40
	v_fma_f32 v10, -v37, v9, v8
	v_fmac_f32_e32 v9, v10, v40
	v_div_scale_f32 v10, s[0:1], v22, v22, v4
	v_fma_f32 v8, -v37, v9, v8
	v_rcp_f32_e32 v37, v10
	v_div_fmas_f32 v8, v8, v40, v9
	v_div_fixup_f32 v11, v8, v22, v11
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v11, v39, v11
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v8, -v10, v37, 1.0
	v_fmac_f32_e32 v37, v8, v37
	v_div_scale_f32 v8, vcc, v4, v22, v4
	v_mul_f32_e32 v9, v8, v37
	v_fma_f32 v40, -v10, v9, v8
	v_fmac_f32_e32 v9, v40, v37
	v_fma_f32 v8, -v10, v9, v8
	v_div_scale_f32 v10, s[0:1], v22, v22, v5
	v_rcp_f32_e32 v40, v10
	v_div_fmas_f32 v8, v8, v37, v9
	v_div_fixup_f32 v37, v8, v22, v4
	v_fma_f32 v4, -v10, v40, 1.0
	v_fmac_f32_e32 v40, v4, v40
	v_div_scale_f32 v4, vcc, v5, v22, v5
	v_mul_f32_e32 v8, v4, v40
	v_fma_f32 v9, -v10, v8, v4
	v_fmac_f32_e32 v8, v9, v40
	v_div_scale_f32 v9, s[0:1], v22, v22, v6
	v_fma_f32 v4, -v10, v8, v4
	v_rcp_f32_e32 v10, v9
	v_div_fmas_f32 v4, v4, v40, v8
	v_div_fixup_f32 v40, v4, v22, v5
	v_fma_f32 v4, -v9, v10, 1.0
	v_fmac_f32_e32 v10, v4, v10
	v_div_scale_f32 v4, vcc, v6, v22, v6
	v_mul_f32_e32 v5, v4, v10
	v_fma_f32 v8, -v9, v5, v4
	v_fmac_f32_e32 v5, v8, v10
	v_div_scale_f32 v8, s[0:1], v22, v22, v7
	v_fma_f32 v4, -v9, v5, v4
	v_rcp_f32_e32 v9, v8
	v_div_fmas_f32 v4, v4, v10, v5
	v_div_fixup_f32 v41, v4, v22, v6
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v10, v36, v38
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v4, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v4, v9
	v_div_scale_f32 v4, vcc, v7, v22, v7
	v_mul_f32_e32 v5, v4, v9
	v_fma_f32 v6, -v8, v5, v4
	v_fmac_f32_e32 v5, v6, v9
	v_div_scale_f32 v6, s[0:1], v22, v22, v0
	v_fma_f32 v4, -v8, v5, v4
	v_rcp_f32_e32 v8, v6
	v_div_fmas_f32 v4, v4, v9, v5
	v_div_fixup_f32 v42, v4, v22, v7
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v9, v14, v15
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v4, -v6, v8, 1.0
	v_fmac_f32_e32 v8, v4, v8
	v_div_scale_f32 v4, vcc, v0, v22, v0
	v_mul_f32_e32 v5, v4, v8
	v_fma_f32 v7, -v6, v5, v4
	v_fmac_f32_e32 v5, v7, v8
	v_fma_f32 v4, -v6, v5, v4
	v_div_scale_f32 v6, s[0:1], v22, v22, v1
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v4, v4, v8, v5
	v_div_fixup_f32 v43, v4, v22, v0
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v8, v12, v13
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v0, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v0, v7
	v_div_scale_f32 v0, vcc, v1, v22, v1
	v_mul_f32_e32 v4, v0, v7
	v_fma_f32 v5, -v6, v4, v0
	v_fmac_f32_e32 v4, v5, v7
	v_div_scale_f32 v5, s[0:1], v22, v22, v2
	v_fma_f32 v0, -v6, v4, v0
	v_rcp_f32_e32 v6, v5
	v_div_fmas_f32 v0, v0, v7, v4
	v_div_fixup_f32 v44, v0, v22, v1
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v7, v34, v35
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v0, -v5, v6, 1.0
	v_fmac_f32_e32 v6, v0, v6
	v_div_scale_f32 v0, vcc, v2, v22, v2
	v_mul_f32_e32 v1, v0, v6
	v_fma_f32 v4, -v5, v1, v0
	v_fmac_f32_e32 v1, v4, v6
	v_div_scale_f32 v4, s[0:1], v22, v22, v3
	v_fma_f32 v0, -v5, v1, v0
	v_rcp_f32_e32 v5, v4
	v_div_fmas_f32 v0, v0, v6, v1
	v_div_fixup_f32 v45, v0, v22, v2
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v6, v32, v33
	.loc	1 378 44                        ; benchmark_qwen36_extend_attention_m756.py:378:44
	v_fma_f32 v0, -v4, v5, 1.0
	v_fmac_f32_e32 v5, v0, v5
	v_div_scale_f32 v0, vcc, v3, v22, v3
	v_mul_f32_e32 v1, v0, v5
	v_fma_f32 v2, -v4, v1, v0
	v_fmac_f32_e32 v1, v2, v5
	v_fma_f32 v0, -v4, v1, v0
	v_div_fmas_f32 v0, v0, v5, v1
	v_div_fixup_f32 v22, v0, v22, v3
	.loc	1 378 38                        ; benchmark_qwen36_extend_attention_m756.py:378:38
	v_cvt_pk_bf16_f32 v0, v19, v20
	v_cvt_pk_bf16_f32 v1, v21, v23
	buffer_store_dwordx2 v[0:1], v18, s[8:11], 0 offen
	v_or_b32_e32 v0, 64, v17
	v_cvt_pk_bf16_f32 v2, v24, v25
	v_cvt_pk_bf16_f32 v3, v26, v27
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[2:3], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x80, v17
	v_cvt_pk_bf16_f32 v4, v28, v29
	v_cvt_pk_bf16_f32 v5, v30, v31
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[4:5], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0xc0, v17
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[6:7], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x100, v17
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[8:9], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x140, v17
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[10:11], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x180, v17
	v_cvt_pk_bf16_f32 v12, v37, v40
	v_cvt_pk_bf16_f32 v13, v41, v42
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[12:13], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x1c0, v17
	v_cvt_pk_bf16_f32 v14, v43, v44
	v_cvt_pk_bf16_f32 v15, v45, v22
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[14:15], v0, s[8:11], 0 offen
	.loc	1 378 4                         ; benchmark_qwen36_extend_attention_m756.py:378:4
	s_endpgm
.Ltmp91:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
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
		.amdhsa_next_free_vgpr 148
		.amdhsa_next_free_sgpr 76
		.amdhsa_accum_offset 148
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
	.size	qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950, .Lfunc_end0-qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.num_vgpr, 148
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.num_agpr, 0
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.numbered_sgpr, 76
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.num_named_barrier, 0
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.private_seg_size, 0
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.uses_vcc, 1
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.uses_flat_scratch, 0
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.has_dyn_sized_stack, 0
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.has_recursion, 0
	.set qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 10060
; TotalNumSgprs: 80
; NumVgprs: 148
; NumAgprs: 0
; TotalNumVgprs: 148
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 9
; VGPRBlocks: 18
; NumSGPRsForWavesPerEU: 80
; NumVGPRsForWavesPerEU: 148
; AccumOffset: 148
; Occupancy: 3
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 36
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
	.byte	11                              ; DW_FORM_data1
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
	.byte	5                               ; DW_FORM_data2
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	7                               ; Abbreviation Code
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
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0xde DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0xb8 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	312                             ; DW_AT_call_line
	.byte	34                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4e:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x5b:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	312                             ; DW_AT_call_line
	.byte	27                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x68:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x75:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	327                             ; DW_AT_call_line
	.byte	29                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x82:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x8f:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	332                             ; DW_AT_call_line
	.byte	43                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x9c:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0xaa:0x22 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp62                         ; DW_AT_low_pc
	.long	.Ltmp67-.Ltmp62                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	356                             ; DW_AT_call_line
	.byte	21                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0xbf:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges8                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xcc:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges9                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	361                             ; DW_AT_call_line
	.byte	35                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0xd9:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges10                ; DW_AT_ranges
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
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
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
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges4:
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
.Ldebug_ranges5:
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
.Ldebug_ranges6:
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
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp49-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp51-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges7:
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
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp49-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp51-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	.Ltmp53-.Lfunc_begin0
	.quad	.Ltmp56-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges9:
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
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges10:
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
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"benchmark_qwen36_extend_attention_m756.py" ; string offset=7
.Linfo_string2:
	.asciz	"/netra-kernel/tools/benchmark" ; string offset=49
.Linfo_string3:
	.asciz	"qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950" ; string offset=79
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
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .max_flat_workgroup_size: 512
    .name:           qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     80
    .sgpr_spill_count: 0
    .symbol:         qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     148
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
