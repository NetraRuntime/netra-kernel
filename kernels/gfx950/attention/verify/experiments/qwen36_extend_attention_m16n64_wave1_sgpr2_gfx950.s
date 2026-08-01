	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	; Qwen3.6 dFlash verification extend-attention, exact M16xN64 wave64 path.
	; Hand-maintained gfx950 experiment re-derived from the deployed one-wave
	; Triton ISA.  Two long-lived scalar spills use the last addressable SGPRs
	; s100-s101 without crossing the deployed 106-SGPR allocation bucket.
	.text
	.globl	qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950
	.p2align	8
	.type	qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950,@function
qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950:
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.12:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/triton_ops" "extend_attention.py"
	.loc	1 322 0 prologue_end            ; extend_attention.py:322:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.13:
.LBB0_0:
	s_mov_b64 s[88:89], s[10:11]
	s_mov_b64 s[96:97], s[8:9]
	s_load_dwordx2 s[10:11], s[0:1], 0x64
	s_load_dword s8, s[0:1], 0x6c
	s_mov_b32 s20, s16
	s_mov_b64 s[30:31], s[0:1]
.Ltmp1:
	.loc	1 399 39 is_stmt 1              ; extend_attention.py:399:39
	s_ashr_i32 s21, s16, 31
	.loc	1 397 30                        ; extend_attention.py:397:30
	s_waitcnt lgkmcnt(0)
	s_xor_b32 s0, s17, s10
	s_abs_i32 s10, s10
	s_ashr_i32 s9, s0, 31
	s_abs_i32 s22, s17
	s_sub_i32 s19, 0, s10
	.loc	1 399 39                        ; extend_attention.py:399:39
	s_lshl_b64 s[0:1], s[20:21], 2
	s_mov_b64 s[92:93], s[2:3]
	s_add_u32 s2, s14, s0
	s_addc_u32 s3, s15, s1
	s_mov_b64 s[84:85], s[6:7]
	s_load_dwordx2 s[28:29], s[2:3], 0x0
	s_load_dwordx2 s[6:7], s[30:31], 0x38
	s_load_dword s33, s[30:31], 0x58
                                        ; implicit-def: $vgpr203 : SGPR spill to VGPR lane
	.loc	1 413 26                        ; extend_attention.py:413:26
	v_and_b32_e32 v34, 15, v0
	.loc	1 415 26                        ; extend_attention.py:415:26
	v_lshrrev_b32_e32 v93, 4, v0
	.loc	1 400 60                        ; extend_attention.py:400:60
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s29, s29, s28
	.loc	1 401 35                        ; extend_attention.py:401:35
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s7, s1
	s_load_dwordx2 s[6:7], s[0:1], 0x0
	.loc	1 416 28                        ; extend_attention.py:416:28
	s_lshl_b32 s16, s18, 4
	.loc	1 416 38 is_stmt 0              ; extend_attention.py:416:38
	s_or_b32 s0, s16, 1
	s_or_b32 s1, s16, 2
	s_or_b32 s2, s16, 3
	.loc	1 402 60 is_stmt 1              ; extend_attention.py:402:60
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s81, s7, s6
	.loc	1 416 38                        ; extend_attention.py:416:38
	s_or_b32 s3, s16, 4
	s_or_b32 s7, s16, 5
	s_or_b32 s14, s16, 6
	s_or_b32 s15, s16, 7
	s_or_b32 s18, s16, 8
	s_or_b32 s20, s16, 9
	s_or_b32 s21, s16, 10
	s_or_b32 s23, s16, 11
	s_or_b32 s24, s16, 12
	s_or_b32 s25, s16, 13
	s_or_b32 s26, s16, 14
	s_or_b32 s27, s16, 15
	.loc	1 416 48 is_stmt 0              ; extend_attention.py:416:48
	s_cmp_lt_i32 s16, s29
	s_cselect_b64 s[64:65], -1, 0
	s_cmp_lt_i32 s0, s29
	v_writelane_b32 v203, s0, 0
	s_cselect_b64 s[66:67], -1, 0
	s_cmp_lt_i32 s1, s29
	v_writelane_b32 v203, s1, 1
	s_cselect_b64 s[68:69], -1, 0
	s_cmp_lt_i32 s2, s29
	v_writelane_b32 v203, s2, 2
	s_cselect_b64 s[70:71], -1, 0
	s_cmp_lt_i32 s3, s29
	v_writelane_b32 v203, s3, 3
	s_cselect_b64 s[72:73], -1, 0
	s_cmp_lt_i32 s7, s29
	v_writelane_b32 v203, s7, 4
	s_cselect_b64 s[74:75], -1, 0
	s_cmp_lt_i32 s14, s29
	v_writelane_b32 v203, s14, 5
	s_cselect_b64 s[76:77], -1, 0
	s_cmp_lt_i32 s15, s29
	v_writelane_b32 v203, s15, 6
	s_cselect_b64 s[78:79], -1, 0
	s_cmp_lt_i32 s18, s29
	v_writelane_b32 v203, s18, 7
	s_cselect_b64 s[0:1], -1, 0
	v_writelane_b32 v203, s0, 8
	s_cmp_lt_i32 s20, s29
	.loc	1 433 21 is_stmt 1              ; extend_attention.py:433:21
	s_mul_i32 s8, s8, s17
	v_writelane_b32 v203, s1, 9
	v_writelane_b32 v203, s20, 10
	.loc	1 416 48                        ; extend_attention.py:416:48
	s_cselect_b64 s[0:1], -1, 0
	v_writelane_b32 v203, s0, 11
	s_cmp_lt_i32 s21, s29
	.loc	1 413 26                        ; extend_attention.py:413:26
	v_lshlrev_b32_e32 v92, 3, v34
	v_writelane_b32 v203, s1, 12
	v_writelane_b32 v203, s21, 13
	.loc	1 416 48                        ; extend_attention.py:416:48
	s_cselect_b64 s[0:1], -1, 0
	s_mov_b32 s100, s0
	s_cmp_lt_i32 s23, s29
	.loc	1 437 19                        ; extend_attention.py:437:19
	v_mul_lo_u32 v5, s11, v93
	v_writelane_b32 v203, s1, 15
	v_writelane_b32 v203, s23, 16
	.loc	1 416 48                        ; extend_attention.py:416:48
	s_cselect_b64 s[0:1], -1, 0
	v_writelane_b32 v203, s0, 17
	s_cmp_lt_i32 s24, s29
	.loc	1 416 38 is_stmt 0              ; extend_attention.py:416:38
	v_or_b32_e32 v1, s16, v93
	v_writelane_b32 v203, s1, 18
	v_writelane_b32 v203, s24, 19
	.loc	1 416 48                        ; extend_attention.py:416:48
	s_cselect_b64 s[0:1], -1, 0
	v_writelane_b32 v203, s0, 20
	s_cmp_lt_i32 s25, s29
	.loc	1 415 26 is_stmt 1              ; extend_attention.py:415:26
	v_or_b32_e32 v94, 4, v93
	v_writelane_b32 v203, s1, 21
	v_writelane_b32 v203, s25, 22
	.loc	1 416 48                        ; extend_attention.py:416:48
	s_cselect_b64 s[0:1], -1, 0
	v_writelane_b32 v203, s0, 23
	s_cmp_lt_i32 s26, s29
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_bfrev_b32_e32 v78, 1
	v_writelane_b32 v203, s1, 24
	v_writelane_b32 v203, s26, 25
	.loc	1 416 48                        ; extend_attention.py:416:48
	s_cselect_b64 s[0:1], -1, 0
	s_mov_b32 s101, s0
	s_cmp_lt_i32 s27, s29
	v_cmp_gt_i32_e64 s[14:15], s29, v1
	v_writelane_b32 v203, s1, 27
	v_writelane_b32 v203, s27, 28
	s_cselect_b64 s[0:1], -1, 0
	.loc	1 431 36                        ; extend_attention.py:431:36
	v_writelane_b32 v203, s0, 29
	.loc	1 416 38                        ; extend_attention.py:416:38
	v_or_b32_e32 v2, s16, v94
	.loc	1 437 8                         ; extend_attention.py:437:8
	s_and_b32 s93, s93, 0xffff
	.loc	1 431 36                        ; extend_attention.py:431:36
	v_writelane_b32 v203, s1, 30
	s_add_i32 s0, s28, s16
	v_writelane_b32 v203, s17, 31
	v_writelane_b32 v203, s0, 32
	.loc	1 437 19                        ; extend_attention.py:437:19
	s_mul_i32 s0, s0, s11
	s_add_i32 s0, s0, s8
	v_add3_u32 v5, s0, v92, v5
	.loc	1 437 8 is_stmt 0               ; extend_attention.py:437:8
	v_lshlrev_b32_e32 v6, 1, v5
	.loc	1 437 19                        ; extend_attention.py:437:19
	s_lshl_b32 s1, s11, 2
	s_mov_b32 s95, 0x27000
	s_mov_b32 s94, 0x7ffffffe
	v_writelane_b32 v203, s14, 33
	.loc	1 415 26 is_stmt 1              ; extend_attention.py:415:26
	v_or_b32_e32 v95, 8, v93
	.loc	1 416 38                        ; extend_attention.py:416:38
	v_or_b32_e32 v3, s16, v95
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_cndmask_b32_e64 v1, v78, v6, s[14:15]
	v_writelane_b32 v203, s15, 34
	buffer_load_dwordx4 v[6:9], v1, s[92:95], 0 offen
	v_add_lshl_u32 v1, v5, s1, 1
	.loc	1 416 48                        ; extend_attention.py:416:48
	v_cmp_gt_i32_e64 s[0:1], s29, v2
	.loc	1 437 19                        ; extend_attention.py:437:19
	s_lshl_b32 s2, s11, 3
	.loc	1 415 26                        ; extend_attention.py:415:26
	v_or_b32_e32 v96, 12, v93
	v_writelane_b32 v203, s0, 35
	.loc	1 416 38                        ; extend_attention.py:416:38
	v_or_b32_e32 v4, s16, v96
	.loc	1 437 19                        ; extend_attention.py:437:19
	s_mul_i32 s3, s11, 12
	.loc	1 437 8 is_stmt 0               ; extend_attention.py:437:8
	v_cndmask_b32_e64 v1, v78, v1, s[0:1]
	v_writelane_b32 v203, s1, 36
	buffer_load_dwordx4 v[10:13], v1, s[92:95], 0 offen
	v_add_lshl_u32 v1, v5, s2, 1
	.loc	1 416 48 is_stmt 1              ; extend_attention.py:416:48
	v_cmp_gt_i32_e64 s[0:1], s29, v3
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_lshlrev_b32_e32 v73, 4, v0
	v_lshlrev_b32_e32 v102, 4, v34
	v_writelane_b32 v203, s0, 37
	.loc	1 416 38                        ; extend_attention.py:416:38
	v_or_b32_e32 v97, s16, v34
	s_mov_b32 s18, 0
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_cndmask_b32_e64 v1, v78, v1, s[0:1]
	v_writelane_b32 v203, s1, 38
	buffer_load_dwordx4 v[14:17], v1, s[92:95], 0 offen
	v_add_lshl_u32 v1, v5, s3, 1
	.loc	1 416 48                        ; extend_attention.py:416:48
	v_cmp_gt_i32_e64 s[0:1], s29, v4
	.loc	1 457 48                        ; extend_attention.py:457:48
	s_cmp_lt_i32 s81, 1
	v_mov_b32_e32 v68, 0xff800000
	v_writelane_b32 v203, s0, 39
	v_lshlrev_b32_e32 v70, 2, v34
	v_lshlrev_b32_e32 v91, 1, v0
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_cndmask_b32_e64 v1, v78, v1, s[0:1]
	buffer_load_dwordx4 v[18:21], v1, s[92:95], 0 offen
	.loc	1 397 30                        ; extend_attention.py:397:30
	v_cvt_f32_u32_e32 v1, s10
	v_writelane_b32 v203, s1, 40
	v_writelane_b32 v203, s64, 41
	s_movk_i32 s0, 0x80
	v_rcp_iflag_f32_e32 v1, v1
	v_writelane_b32 v203, s65, 42
	v_writelane_b32 v203, s66, 43
	s_movk_i32 s1, 0xc0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_writelane_b32 v203, s67, 44
	v_writelane_b32 v203, s68, 45
	v_lshlrev_b32_e32 v74, 3, v0
	v_mul_lo_u32 v2, s19, v1
	v_mul_hi_u32 v2, v1, v2
	v_add_u32_e32 v1, v1, v2
	v_mul_hi_u32 v1, s22, v1
	v_mul_lo_u32 v2, v1, s10
	v_sub_u32_e32 v2, s22, v2
	v_add_u32_e32 v3, 1, v1
	v_subrev_u32_e32 v4, s10, v2
	v_cmp_le_u32_e32 vcc, s10, v2
	v_writelane_b32 v203, s69, 46
	v_writelane_b32 v203, s70, 47
	v_cndmask_b32_e32 v1, v1, v3, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	v_add_u32_e32 v3, 1, v1
	v_cmp_le_u32_e32 vcc, s10, v2
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_bitop3_b32 v2, v73, v0, 48 bitop3:0x78
	v_add_u32_e32 v98, 0, v2
	.loc	1 397 30                        ; extend_attention.py:397:30
	v_cndmask_b32_e32 v1, v1, v3, vcc
	v_xor_b32_e32 v3, 64, v2
	v_xor_b32_e32 v1, s9, v1
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_add_u32_e32 v99, 0, v3
	v_xor_b32_e32 v3, 0x80, v2
	v_xor_b32_e32 v2, 0xc0, v2
	.loc	1 397 30                        ; extend_attention.py:397:30
	v_subrev_u32_e32 v72, s9, v1
	.loc	1 415 26                        ; extend_attention.py:415:26
	v_and_b32_e32 v1, 48, v0
	.loc	1 437 8                         ; extend_attention.py:437:8
	v_add_u32_e32 v101, 0, v2
	v_lshlrev_b32_e32 v2, 8, v34
	v_bitop3_b32 v4, v102, v2, v1 bitop3:0xde
	v_add_u32_e32 v100, 0, v3
	v_bitop3_b32 v3, v102, v0, 48 bitop3:0x78
	v_add_u32_e32 v5, 0, v4
	v_xad_u32 v4, v4, 64, 0
	v_writelane_b32 v203, s71, 48
	v_writelane_b32 v203, s72, 49
	v_bitop3_b32 v76, v2, v1, v102 bitop3:0x36
	.loc	1 416 48                        ; extend_attention.py:416:48
	v_cmp_gt_i32_e32 vcc, s29, v97
	v_writelane_b32 v203, s73, 50
	.loc	1 437 8                         ; extend_attention.py:437:8
	s_waitcnt vmcnt(3)
	ds_write_b128 v98, v[6:9]
	v_writelane_b32 v203, s74, 51
	.loc	1 451 26                        ; extend_attention.py:451:26
	v_lshrrev_b32_e32 v103, 2, v1
	v_xor_b32_e32 v71, 64, v76
	v_writelane_b32 v203, s75, 52
	v_writelane_b32 v203, s76, 53
	v_lshrrev_b32_e32 v77, 1, v1
	v_and_b32_e32 v75, 60, v0
	v_writelane_b32 v203, s77, 54
	v_add_u32_e32 v104, 0, v76
	.loc	1 437 8                         ; extend_attention.py:437:8
	s_waitcnt vmcnt(2)
	ds_write_b128 v99, v[10:13] offset:1024
	v_writelane_b32 v203, s78, 55
	s_waitcnt vmcnt(1)
	ds_write_b128 v100, v[14:17] offset:2048
	v_writelane_b32 v203, s79, 56
	s_waitcnt vmcnt(0)
	ds_write_b128 v101, v[18:21] offset:3072
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 v[170:173], v5
	ds_read_b128 v[174:177], v4
	v_bitop3_b32 v4, v3, s0, v2 bitop3:0x36
	v_add_u32_e32 v4, 0, v4
	v_bitop3_b32 v3, v3, s1, v2 bitop3:0x36
	v_add_u32_e32 v3, 0, v3
	ds_read_b128 v[178:181], v4
	ds_read_b128 v[182:185], v3
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, v4
	v_mov_b64_e32 v[2:3], v[4:5]
	v_mov_b64_e32 v[8:9], v[4:5]
	v_mov_b64_e32 v[6:7], v[4:5]
	v_mov_b64_e32 v[12:13], v[4:5]
	v_mov_b64_e32 v[10:11], v[4:5]
	v_mov_b64_e32 v[16:17], v[4:5]
	v_mov_b64_e32 v[14:15], v[4:5]
	v_mov_b64_e32 v[20:21], v[4:5]
	v_mov_b64_e32 v[18:19], v[4:5]
	v_mov_b64_e32 v[24:25], v[4:5]
	v_mov_b64_e32 v[22:23], v[4:5]
	v_mov_b64_e32 v[28:29], v[4:5]
	v_mov_b64_e32 v[26:27], v[4:5]
	v_mov_b64_e32 v[32:33], v[4:5]
	v_mov_b64_e32 v[30:31], v[4:5]
	v_mov_b32_e32 v69, v4
	.loc	1 457 48                        ; extend_attention.py:457:48
	s_cbranch_scc1 .LBB0_6
; %bb.1:                                ; %.lr.ph
	.loc	1 0 48 is_stmt 0                ; extend_attention.py:0:48
	v_writelane_b32 v203, s29, 57
	v_writelane_b32 v203, s28, 58
                                        ; implicit-def: $vgpr202 : SGPR spill to VGPR lane
	.loc	1 479 37 is_stmt 1              ; extend_attention.py:479:37
	s_add_i32 s19, s81, s16
	.loc	1 479 61 is_stmt 0              ; extend_attention.py:479:61
	s_add_i32 s0, s19, 1
	v_writelane_b32 v203, s29, 59
	v_writelane_b32 v203, s96, 60
	v_and_b32_e32 v2, 3, v0
	s_add_i32 s1, s19, 8
	v_writelane_b32 v203, s97, 61
	v_writelane_b32 v203, s98, 62
	v_writelane_b32 v203, s99, 63
	s_load_dwordx4 s[96:99], s[30:31], 0x88
	s_load_dwordx2 s[92:93], s[30:31], 0x40
	v_writelane_b32 v202, s30, 0
	s_load_dwordx2 s[86:87], s[30:31], 0x5c
	v_lshlrev_b32_e32 v3, 6, v2
	v_writelane_b32 v202, s31, 1
	v_writelane_b32 v202, s0, 2
	s_add_i32 s0, s19, 9
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v8, s86
	v_mul_f32_e32 v81, s33, v8
	v_mul_lo_u32 v8, v72, s99
	v_lshlrev_b32_e32 v16, 6, v75
	v_lshlrev_b32_e32 v2, 3, v2
	v_lshlrev_b32_e32 v17, 1, v75
	.loc	1 457 48 is_stmt 1              ; extend_attention.py:457:48
	v_writelane_b32 v202, s0, 3
	.loc	1 479 61                        ; extend_attention.py:479:61
	s_add_i32 s17, s19, 7
	v_and_b32_e32 v5, 0x100, v74
	v_mul_lo_u32 v6, v72, s97
	v_add_u32_e32 v82, v8, v92
	v_xor_b32_e32 v8, v73, v77
	v_bitop3_b32 v2, v16, v17, v2 bitop3:0x36
	v_mov_b32_e32 v66, 0
	.loc	1 457 48                        ; extend_attention.py:457:48
	v_writelane_b32 v202, s1, 4
	.loc	1 479 61                        ; extend_attention.py:479:61
	s_add_i32 s3, s19, 6
	v_and_b32_e32 v4, 56, v91
	v_add3_u32 v3, 0, v3, v5
	v_lshlrev_b32_e32 v5, 2, v1
	v_add_u32_e32 v80, v6, v92
	v_xor_b32_e32 v6, 0x80, v76
	v_xor_b32_e32 v7, 0xc0, v76
	v_xor_b32_e32 v9, 8, v8
	v_xor_b32_e32 v10, 32, v8
	v_xor_b32_e32 v11, 40, v8
	v_xor_b32_e32 v12, 64, v8
	v_xor_b32_e32 v13, 0x48, v8
	v_xor_b32_e32 v14, 0x60, v8
	v_xor_b32_e32 v15, 0x68, v8
	v_xor_b32_e32 v16, 32, v2
	v_xor_b32_e32 v17, 64, v2
	v_xor_b32_e32 v18, 0x60, v2
	v_mov_b32_e32 v67, v66
	.loc	1 457 48                        ; extend_attention.py:457:48
	v_writelane_b32 v202, s17, 5
	.loc	1 479 61                        ; extend_attention.py:479:61
	v_add_u32_e32 v79, s19, v34
	s_add_i32 s52, s19, 2
	s_add_i32 s8, s19, 3
	s_add_i32 s80, s19, 4
	s_add_i32 s2, s19, 5
	s_add_i32 s53, s19, 10
	s_add_i32 s54, s19, 11
	s_add_i32 s55, s19, 12
	s_add_i32 s56, s19, 13
	s_add_i32 s57, s19, 14
	s_add_i32 s58, s19, 15
	s_and_b32 s93, s93, 0xffff
	s_and_b32 s89, s89, 0xffff
	s_and_b32 s13, s13, 0xffff
	.loc	1 547 59                        ; extend_attention.py:547:59
	s_mov_b32 s86, s87
	.loc	1 457 48                        ; extend_attention.py:457:48
	v_add_lshl_u32 v83, s6, v0, 3
	v_mov_b32_e32 v68, 0xff800000
	v_add_u32_e32 v84, 0, v70
	v_add_u32_e32 v85, v3, v4
	v_add_u32_e32 v86, 0, v5
	v_add_u32_e32 v87, 0, v71
	v_add_u32_e32 v88, 0, v6
	v_add_u32_e32 v89, 0, v7
	s_mov_b32 s97, 0xc2fc0000
	v_add_u32_e32 v90, 0, v8
	v_add_u32_e32 v105, 0, v9
	v_add_u32_e32 v106, 0, v10
	v_add_u32_e32 v107, 0, v11
	v_add_u32_e32 v108, 0, v12
	v_add_u32_e32 v109, 0, v13
	v_add_u32_e32 v110, 0, v14
	v_add_u32_e32 v111, 0, v15
	v_add_u32_e32 v112, 0, v2
	v_add_u32_e32 v113, 0, v16
	v_add_u32_e32 v114, 0, v17
	v_add_u32_e32 v115, 0, v18
	v_mov_b32_e32 v116, 0xff800000
	v_mov_b32_e32 v117, 0xe0ad78ec
	v_mov_b32_e32 v118, 0x42800000
	v_not_b32_e32 v119, 63
	v_mov_b32_e32 v69, 0
	v_mov_b64_e32 v[30:31], v[66:67]
	v_mov_b64_e32 v[32:33], v[66:67]
	v_mov_b64_e32 v[26:27], v[66:67]
	v_mov_b64_e32 v[28:29], v[66:67]
	v_mov_b64_e32 v[22:23], v[66:67]
	v_mov_b64_e32 v[24:25], v[66:67]
	v_mov_b64_e32 v[18:19], v[66:67]
	v_mov_b64_e32 v[20:21], v[66:67]
	v_mov_b64_e32 v[14:15], v[66:67]
	v_mov_b64_e32 v[16:17], v[66:67]
	v_mov_b64_e32 v[10:11], v[66:67]
	v_mov_b64_e32 v[12:13], v[66:67]
	v_mov_b64_e32 v[6:7], v[66:67]
	v_mov_b64_e32 v[8:9], v[66:67]
	v_mov_b64_e32 v[2:3], v[66:67]
	v_mov_b64_e32 v[4:5], v[66:67]
	v_writelane_b32 v202, s3, 6
	v_writelane_b32 v202, s2, 7
	s_branch .LBB0_3
.LBB0_2:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 0 48 is_stmt 0                ; extend_attention.py:0:48
	s_or_b64 exec, exec, s[20:21]
	.loc	1 457 48 is_stmt 1              ; extend_attention.py:457:48
	s_add_i32 s18, s18, 64
	s_cmp_lt_i32 s18, s81
	v_add_u32_e32 v83, 0x200, v83
	s_cbranch_scc0 .LBB0_5
.LBB0_3:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_add_u32_e32 v34, s18, v0
	v_cmp_gt_i32_e64 s[6:7], s81, v34
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_add_u32_e32 v34, 0xfff, v34
	v_cmp_le_i32_e64 s[10:11], s19, v34
	v_readlane_b32 s14, v202, 2
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[6:7], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[22:23], s52, v34
	v_cmp_le_i32_e64 s[14:15], s14, v34
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[14:15], s[6:7], s[14:15]
	s_and_b64 s[10:11], s[64:65], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[24:25], s8, v34
	v_cmp_le_i32_e64 s[26:27], s80, v34
	v_cmp_le_i32_e64 s[28:29], s2, v34
	v_cmp_le_i32_e64 s[30:31], s3, v34
	v_cmp_le_i32_e64 s[34:35], s17, v34
	v_cmp_le_i32_e64 s[36:37], s1, v34
	v_cmp_le_i32_e64 s[38:39], s0, v34
	v_cmp_le_i32_e64 s[40:41], s53, v34
	v_cmp_le_i32_e64 s[42:43], s54, v34
	v_cmp_le_i32_e64 s[44:45], s55, v34
	v_cmp_le_i32_e64 s[46:47], s56, v34
	v_cmp_le_i32_e64 s[48:49], s57, v34
	v_cmp_le_i32_e64 s[50:51], s58, v34
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[20:21], s[6:7], s[22:23]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v34, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[66:67], s[14:15]
	s_and_b64 s[22:23], s[6:7], s[24:25]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v35, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[68:69], s[20:21]
	s_and_b64 s[24:25], s[6:7], s[26:27]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v36, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[70:71], s[22:23]
	s_and_b64 s[26:27], s[6:7], s[28:29]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v37, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[72:73], s[24:25]
	s_and_b64 s[28:29], s[6:7], s[30:31]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v38, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[74:75], s[26:27]
	s_and_b64 s[30:31], s[6:7], s[34:35]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v39, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[76:77], s[28:29]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v40, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[78:79], s[30:31]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v41, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s10, v203, 8
	s_and_b64 s[34:35], s[6:7], s[36:37]
	v_readlane_b32 s11, v203, 9
	s_and_b64 s[10:11], s[10:11], s[34:35]
	s_and_b64 s[36:37], s[6:7], s[38:39]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v42, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s10, v203, 11
	v_readlane_b32 s11, v203, 12
	s_and_b64 s[10:11], s[10:11], s[36:37]
	s_and_b64 s[38:39], s[6:7], s[40:41]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v43, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_mov_b32 s10, s100
	v_readlane_b32 s11, v203, 15
	s_and_b64 s[10:11], s[10:11], s[38:39]
	s_and_b64 s[40:41], s[6:7], s[42:43]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v44, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s10, v203, 17
	v_readlane_b32 s11, v203, 18
	s_and_b64 s[10:11], s[10:11], s[40:41]
	s_and_b64 s[42:43], s[6:7], s[44:45]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v45, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s10, v203, 20
	v_readlane_b32 s11, v203, 21
	s_and_b64 s[10:11], s[10:11], s[42:43]
	s_and_b64 s[44:45], s[6:7], s[46:47]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v46, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s10, v203, 23
	v_readlane_b32 s11, v203, 24
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[10:11], s[44:45]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v47, 0, 1, s[10:11]
.Ltmp4:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_mov_b32 s10, s101
	s_and_b64 s[46:47], s[6:7], s[48:49]
.Ltmp6:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s11, v203, 27
	s_and_b64 s[10:11], s[10:11], s[46:47]
.Ltmp8:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v50, v34
.Ltmp10:
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v48, 0, 1, s[10:11]
	.loc	1 481 26                        ; extend_attention.py:481:26
	v_readlane_b32 s10, v203, 29
.Ltmp11:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_dpp v50, v50 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp12:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[48:49], s[6:7], s[50:51]
	v_readlane_b32 s11, v203, 30
.Ltmp13:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v50
.Ltmp14:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[10:11], s[10:11], s[48:49]
	.loc	1 485 52                        ; extend_attention.py:485:52
	v_cndmask_b32_e64 v49, 0, 1, s[10:11]
.Ltmp15:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	s_waitcnt lgkmcnt(0)
.Ltmp17:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_readlane_b32 s10, v34, 63
.Ltmp18:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	; wave barrier
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp19:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp20:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp21:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s11, v34, 63
.Ltmp22:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v36, v36 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp23:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp24:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp25:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s14, v34, 63
.Ltmp26:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v37, v37 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp27:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	s_nop 0
	v_mov_b32_e32 v36, s14
.Ltmp28:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp29:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp30:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp31:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s15, v34, 63
.Ltmp32:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v38, v38 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	s_nop 0
	v_mov_b32_e32 v37, s15
.Ltmp34:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp35:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp36:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp37:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s20, v34, 63
.Ltmp38:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v39, v39 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp39:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp40:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp41:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s21, v34, 63
.Ltmp42:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v40, v40 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp43:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp44:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp45:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s22, v34, 63
.Ltmp46:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v41, v41 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp47:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp48:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp49:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s23, v34, 63
.Ltmp50:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v42, v42 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp51:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp52:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp53:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s24, v34, 63
.Ltmp54:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v43, v43 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp55:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp56:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp57:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s25, v34, 63
.Ltmp58:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v44, v44 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp59:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp60:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp61:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s26, v34, 63
.Ltmp62:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v45, v45 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp63:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp64:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp65:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s27, v34, 63
.Ltmp66:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v46, v46 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp67:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp68:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp69:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s28, v34, 63
.Ltmp70:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v47, v47 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp71:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp72:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp73:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s29, v34, 63
.Ltmp74:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v48, v48 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp75:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp76:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp77:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s30, v34, 63
.Ltmp78:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_dpp v34, v49, v49 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp79:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp80:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp81:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	v_mov_b32_e32 v35, s11
.Ltmp82:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:38 ] ]
	s_nop 0
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp83:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:38 ]
	s_nop 0
	v_readlane_b32 s31, v34, 63
.Ltmp84:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	v_mov_b32_e32 v34, s10
	ds_write_b128 v66, v[34:37]
	v_mov_b32_e32 v34, s20
	v_mov_b32_e32 v35, s21
	v_mov_b32_e32 v36, s22
	v_mov_b32_e32 v37, s23
	ds_write_b128 v66, v[34:37] offset:16
	v_mov_b32_e32 v34, s24
	v_mov_b32_e32 v35, s25
	v_mov_b32_e32 v36, s26
	v_mov_b32_e32 v37, s27
	ds_write_b128 v66, v[34:37] offset:32
	v_mov_b32_e32 v34, s28
	v_mov_b32_e32 v35, s29
	v_mov_b32_e32 v36, s30
	v_mov_b32_e32 v37, s31
	ds_write_b128 v66, v[34:37] offset:48
	; wave barrier
	ds_read_b32 v34, v84
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v35, v34 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp85:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp86:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v35, v34 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp87:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp88:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp89:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp90:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:485:31 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp91:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:485:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp92:
	.loc	1 0 0 is_stmt 0                 ; extend_attention.py:0
	v_cmp_ne_u32_e64 s[10:11], 0, v34
	.loc	1 487 11 is_stmt 1              ; extend_attention.py:487:11
	s_and_saveexec_b64 s[20:21], s[10:11]
	s_cbranch_execz .LBB0_2
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v34, s18, v103
	v_add_u32_e32 v35, 51, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1032, v34
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 459 38 is_stmt 1              ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[14:15], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 50, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1031, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[50:51], s[14:15], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[14:15], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 49, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1030, v34
	s_mov_b32 s9, s52
	s_mov_b32 s99, s53
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[52:53], s[14:15], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[14:15], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 48, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x102f, v34
	s_mov_b32 s17, s8
	s_mov_b32 s8, s16
	s_mov_b32 s16, s19
	s_mov_b32 s19, s54
	s_mov_b32 s3, s55
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[54:55], s[14:15], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[14:15], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 35, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1022, v34
	s_mov_b32 s2, s56
	s_mov_b32 s1, s57
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[56:57], s[14:15], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[14:15], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 34, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1021, v34
	s_mov_b32 s0, s58
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[58:59], s[14:15], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[14:15], s81, v35
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1020, v34
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[60:61], s[14:15], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[10:11], v79, v36
	.loc	1 489 16                        ; extend_attention.py:489:16
	v_cndmask_b32_e64 v36, v78, v83, s[6:7]
	buffer_load_dwordx2 v[120:121], v36, s[92:95], 0 offen
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 33, v34
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[6:7], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 32, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x101f, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[62:63], s[6:7], s[10:11]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 19, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1012, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[64:65], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 18, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1011, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[66:67], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 17, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1010, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[68:69], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 16, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x100f, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[70:71], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 3, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1002, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[72:73], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 2, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1001, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[74:75], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 480 46                        ; extend_attention.py:480:46
	v_add_u32_e32 v35, 1, v34
	.loc	1 480 18 is_stmt 0              ; extend_attention.py:480:18
	v_add_u32_e32 v36, 0x1000, v34
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[76:77], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v36
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[78:79], s[10:11], s[6:7]
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_add_u32_e32 v35, 0xfff, v34
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[10:11], s81, v34
	v_add_u32_e32 v34, s18, v93
	.loc	1 480 18                        ; extend_attention.py:480:18
	v_cmp_le_i32_e64 s[6:7], v79, v35
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_add_u32_e32 v35, 60, v34
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[82:83], s[10:11], s[6:7]
	.loc	1 459 38                        ; extend_attention.py:459:38
	v_cmp_gt_i32_e64 s[6:7], s81, v35
	v_add_u32_e32 v35, 56, v34
	v_cmp_gt_i32_e64 s[10:11], s81, v35
	v_add_u32_e32 v35, 52, v34
	v_cmp_gt_i32_e64 s[22:23], s81, v35
	v_add_u32_e32 v35, 48, v34
	v_cmp_gt_i32_e64 s[26:27], s81, v35
	v_add_u32_e32 v35, 44, v34
	v_cmp_gt_i32_e64 s[24:25], s81, v35
	v_add_u32_e32 v35, 40, v34
	v_cmp_gt_i32_e64 s[28:29], s81, v35
	v_add_u32_e32 v35, 36, v34
	v_cmp_gt_i32_e64 s[30:31], s81, v35
	v_add_u32_e32 v35, 32, v34
	v_cmp_gt_i32_e64 s[34:35], s81, v35
	v_add_u32_e32 v35, 28, v34
	v_cmp_gt_i32_e64 s[36:37], s81, v35
	v_add_u32_e32 v35, 24, v34
	v_cmp_gt_i32_e64 s[38:39], s81, v35
	v_add_u32_e32 v35, 20, v34
	v_cmp_gt_i32_e64 s[40:41], s81, v35
	v_add_u32_e32 v35, 16, v34
	v_cmp_gt_i32_e64 s[42:43], s81, v35
	v_add_u32_e32 v35, 12, v34
	v_cmp_gt_i32_e64 s[44:45], s81, v35
	v_add_u32_e32 v35, 8, v34
	v_cmp_gt_i32_e64 s[46:47], s81, v35
	v_add_u32_e32 v35, 4, v34
	v_cmp_gt_i32_e64 s[48:49], s81, v35
	v_cmp_gt_i32_e64 s[14:15], s81, v34
	.loc	1 539 18                        ; extend_attention.py:539:18
	s_waitcnt vmcnt(0) lgkmcnt(0)
	; wave barrier
	ds_write_b64 v85, v[120:121]
	; wave barrier
	ds_read_b128 v[62:65], v86
	ds_read_b128 v[58:61], v86 offset:16
	ds_read_b128 v[54:57], v86 offset:32
	ds_read_b128 v[50:53], v86 offset:48
	ds_read_b128 v[46:49], v86 offset:256
	ds_read_b128 v[42:45], v86 offset:272
	ds_read_b128 v[38:41], v86 offset:288
	ds_read_b128 v[34:37], v86 offset:304
	.loc	1 501 16                        ; extend_attention.py:501:16
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_write_b64 v85, v[120:121]
	; wave barrier
	ds_read_b128 v[120:123], v86
	ds_read_b128 v[124:127], v86 offset:16
	ds_read_b128 v[128:131], v86 offset:32
	ds_read_b128 v[132:135], v86 offset:48
	ds_read_b128 v[136:139], v86 offset:256
	ds_read_b128 v[140:143], v86 offset:272
	ds_read_b128 v[144:147], v86 offset:288
	ds_read_b128 v[148:151], v86 offset:304
	.loc	1 501 27 is_stmt 0              ; extend_attention.py:501:27
	s_waitcnt lgkmcnt(7)
	v_mul_lo_u32 v35, v120, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	v_add_lshl_u32 v35, v80, v35, 1
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v37, v122, s96
	s_waitcnt lgkmcnt(1)
	v_mul_lo_u32 v61, v146, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	v_cndmask_b32_e64 v35, v78, v35, s[14:15]
	s_mov_b32 s90, s94
	s_mov_b32 s91, s95
	buffer_load_dwordx4 v[120:123], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v37, 1
	v_add_lshl_u32 v37, v80, v61, 1
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v39, v124, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	v_cndmask_b32_e64 v35, v78, v35, s[48:49]
	v_cndmask_b32_e64 v37, v78, v37, s[22:23]
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v41, v126, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[124:127], v35, s[88:91], 0 offen
	buffer_load_dwordx4 v[186:189], v37, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v39, 1
	v_cndmask_b32_e64 v35, v78, v35, s[46:47]
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v43, v128, s96
	v_mul_lo_u32 v45, v130, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[128:131], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v41, 1
	v_cndmask_b32_e64 v35, v78, v35, s[44:45]
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v47, v132, s96
	v_mul_lo_u32 v49, v134, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[132:135], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v43, 1
	v_cndmask_b32_e64 v35, v78, v35, s[42:43]
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v51, v136, s96
	v_mul_lo_u32 v53, v138, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[136:139], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v45, 1
	v_cndmask_b32_e64 v35, v78, v35, s[40:41]
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v55, v140, s96
	v_mul_lo_u32 v57, v142, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[140:143], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v47, 1
	v_cndmask_b32_e64 v35, v78, v35, s[38:39]
	.loc	1 501 27                        ; extend_attention.py:501:27
	v_mul_lo_u32 v59, v144, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[144:147], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v49, 1
	v_cndmask_b32_e64 v35, v78, v35, s[36:37]
	.loc	1 501 27                        ; extend_attention.py:501:27
	s_waitcnt lgkmcnt(0)
	v_mul_lo_u32 v63, v148, s96
	v_mul_lo_u32 v65, v150, s96
	.loc	1 501 16                        ; extend_attention.py:501:16
	buffer_load_dwordx4 v[148:151], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v51, 1
	v_cndmask_b32_e64 v35, v78, v35, s[34:35]
	buffer_load_dwordx4 v[152:155], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v53, 1
	v_cndmask_b32_e64 v35, v78, v35, s[30:31]
	buffer_load_dwordx4 v[156:159], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v55, 1
	v_cndmask_b32_e64 v35, v78, v35, s[28:29]
	buffer_load_dwordx4 v[160:163], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v59, 1
	v_cndmask_b32_e64 v35, v78, v35, s[26:27]
	v_add_lshl_u32 v37, v80, v63, 1
	buffer_load_dwordx4 v[164:167], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v57, 1
	v_cndmask_b32_e64 v37, v78, v37, s[10:11]
	v_cndmask_b32_e64 v35, v78, v35, s[24:25]
	buffer_load_dwordx4 v[190:193], v37, s[88:91], 0 offen
	buffer_load_dwordx4 v[194:197], v35, s[88:91], 0 offen
	v_add_lshl_u32 v35, v80, v65, 1
	v_cndmask_b32_e64 v35, v78, v35, s[6:7]
	buffer_load_dwordx4 v[198:201], v35, s[88:91], 0 offen
	s_waitcnt lgkmcnt(0)
	; wave barrier
	.loc	1 481 26 is_stmt 1              ; extend_attention.py:481:26
	s_and_b64 s[78:79], vcc, s[78:79]
	.loc	1 501 16                        ; extend_attention.py:501:16
	s_waitcnt vmcnt(15)
	ds_write_b128 v98, v[120:123]
	s_waitcnt vmcnt(10)
	ds_write_b128 v98, v[136:139] offset:4096
	s_waitcnt vmcnt(6)
	ds_write_b128 v98, v[152:155] offset:8192
	s_waitcnt vmcnt(3)
	ds_write_b128 v98, v[164:167] offset:12288
	ds_write_b128 v99, v[124:127] offset:1024
	ds_write_b128 v99, v[140:143] offset:5120
	ds_write_b128 v99, v[156:159] offset:9216
	ds_write_b128 v99, v[186:189] offset:13312
	ds_write_b128 v100, v[128:131] offset:2048
	ds_write_b128 v100, v[144:147] offset:6144
	ds_write_b128 v100, v[160:163] offset:10240
	s_waitcnt vmcnt(2)
	ds_write_b128 v100, v[190:193] offset:14336
	ds_write_b128 v101, v[132:135] offset:3072
	ds_write_b128 v101, v[148:151] offset:7168
	s_waitcnt vmcnt(1)
	ds_write_b128 v101, v[194:197] offset:11264
	s_waitcnt vmcnt(0)
	ds_write_b128 v101, v[198:201] offset:15360
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 v[120:123], v104
	ds_read_b128 v[124:127], v87
	ds_read_b128 v[128:131], v88
	ds_read_b128 v[132:135], v87 offset:4096
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[120:123], v[120:123], v[170:173], 0
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[140:143], v89 offset:8192
	ds_read_b128 v[144:147], v89 offset:12288
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[82:83], vcc, s[82:83]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[120:123], v[124:127], v[174:177], v[120:123]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[124:127], v89
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[60:61], vcc, s[60:61]
	s_and_b64 s[74:75], vcc, s[74:75]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[120:123], v[128:131], v[178:181], v[120:123]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[128:131], v104 offset:4096
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[76:77], vcc, s[76:77]
	s_and_b64 s[70:71], vcc, s[70:71]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[120:123], v[124:127], v[182:185], v[120:123]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[72:73], vcc, s[72:73]
	s_and_b64 s[66:67], vcc, s[66:67]
	s_and_b64 s[68:69], vcc, s[68:69]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[124:127], v[128:131], v[170:173], 0
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[128:131], v88 offset:4096
	.loc	1 518 18                        ; extend_attention.py:518:18
	s_nop 1
	v_mul_f32_e32 v35, v81, v120
	v_mul_f32_e32 v37, v81, v121
	.loc	1 505 39                        ; extend_attention.py:505:39
	v_mfma_f32_16x16x32_bf16 v[124:127], v[132:135], v[174:177], v[124:127]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[132:135], v89 offset:4096
	.loc	1 518 18                        ; extend_attention.py:518:18
	v_mul_f32_e32 v39, v81, v122
	v_mul_f32_e32 v41, v81, v123
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[124:127], v[128:131], v[178:181], v[124:127]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[128:131], v104 offset:8192
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v35, v116, v35, s[82:83]
	v_cndmask_b32_e64 v37, v116, v37, s[78:79]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[124:127], v[132:135], v[182:185], v[124:127]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[132:135], v87 offset:8192
	ds_read_b128 v[136:139], v88 offset:8192
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v39, v116, v39, s[76:77]
	v_cndmask_b32_e64 v41, v116, v41, s[74:75]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[128:131], v[128:131], v[170:173], 0
	.loc	1 518 18                        ; extend_attention.py:518:18
	s_nop 1
	v_mul_f32_e32 v43, v81, v124
	v_mul_f32_e32 v45, v81, v125
	v_mul_f32_e32 v47, v81, v126
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[128:131], v[132:135], v[174:177], v[128:131]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[132:135], v104 offset:12288
	.loc	1 518 18                        ; extend_attention.py:518:18
	v_mul_f32_e32 v49, v81, v127
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v43, v116, v43, s[72:73]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[128:131], v[136:139], v[178:181], v[128:131]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[136:139], v87 offset:12288
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v45, v116, v45, s[70:71]
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[62:63], vcc, s[62:63]
	.loc	1 505 39                        ; extend_attention.py:505:39
	v_mfma_f32_16x16x32_bf16 v[128:131], v[140:143], v[182:185], v[128:131]
	.loc	1 501 16                        ; extend_attention.py:501:16
	ds_read_b128 v[140:143], v88 offset:12288
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[64:65], vcc, s[64:65]
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v47, v116, v47, s[68:69]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[132:135], v[132:135], v[170:173], 0
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v49, v116, v49, s[66:67]
	.loc	1 518 18                        ; extend_attention.py:518:18
	s_nop 1
	v_mul_f32_e32 v55, v81, v130
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v67, v116, v55, s[60:61]
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[132:135], v[136:139], v[174:177], v[132:135]
.Ltmp93:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max_f32_e32 v55, v35, v37
	v_max3_f32 v55, v55, v39, v41
.Ltmp94:
	.loc	1 518 18                        ; extend_attention.py:518:18
	v_mul_f32_e32 v51, v81, v128
	.loc	1 505 39                        ; extend_attention.py:505:39
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[132:135], v[140:143], v[178:181], v[132:135]
	.loc	1 518 18                        ; extend_attention.py:518:18
	v_mul_f32_e32 v53, v81, v129
.Ltmp95:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max3_f32 v55, v55, v43, v45
.Ltmp96:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[58:59], vcc, s[58:59]
	.loc	1 505 39                        ; extend_attention.py:505:39
	v_mfma_f32_16x16x32_bf16 v[132:135], v[144:147], v[182:185], v[132:135]
	.loc	1 518 18                        ; extend_attention.py:518:18
	v_mul_f32_e32 v57, v81, v131
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v51, v116, v51, s[64:65]
	v_cndmask_b32_e64 v53, v116, v53, s[62:63]
.Ltmp97:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max3_f32 v55, v55, v47, v49
.Ltmp98:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[54:55], vcc, s[54:55]
	s_and_b64 s[56:57], vcc, s[56:57]
	.loc	1 518 18                        ; extend_attention.py:518:18
	s_nop 1
	v_mul_f32_e32 v59, v81, v132
	v_mul_f32_e32 v61, v81, v133
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v57, v116, v57, s[58:59]
.Ltmp99:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max3_f32 v55, v55, v51, v53
.Ltmp100:
	.loc	1 481 26                        ; extend_attention.py:481:26
	s_and_b64 s[50:51], vcc, s[50:51]
	s_and_b64 s[52:53], vcc, s[52:53]
	.loc	1 518 18                        ; extend_attention.py:518:18
	v_mul_f32_e32 v63, v81, v134
	v_mul_f32_e32 v65, v81, v135
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v59, v116, v59, s[56:57]
	v_cndmask_b32_e64 v61, v116, v61, s[54:55]
.Ltmp101:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max3_f32 v55, v55, v67, v57
.Ltmp102:
	.loc	1 526 42                        ; extend_attention.py:526:42
	v_cndmask_b32_e64 v63, v116, v63, s[52:53]
	v_cndmask_b32_e64 v65, v116, v65, s[50:51]
.Ltmp103:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max3_f32 v55, v55, v59, v61
	v_max3_f32 v55, v55, v63, v65
.Ltmp104:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:528:33 ]
	v_mov_b32_e32 v120, v55
	s_nop 1
	v_permlane32_swap_b32_e32 v55, v120
.Ltmp105:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max_f32_e32 v120, v120, v120
	v_max_f32_e32 v55, v55, v55
	v_max_f32_e32 v55, v55, v120
.Ltmp106:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:528:33 ]
	v_mov_b32_e32 v120, v55
	s_nop 1
	v_permlane16_swap_b32_e32 v55, v120
.Ltmp107:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:528:33 ] ]
	v_max_f32_e32 v120, v120, v120
	v_max_f32_e32 v55, v55, v55
	v_max_f32_e32 v55, v55, v120
	s_mov_b32 s50, 0xff800000
.Ltmp108:
	.loc	1 529 70                        ; extend_attention.py:529:70
	v_cmp_neq_f32_e64 s[50:51], s50, v55
	.loc	1 530 48                        ; extend_attention.py:530:48
	v_max_f32_e32 v120, v68, v68
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v144, v38, s98
	.loc	1 529 70                        ; extend_attention.py:529:70
	v_cndmask_b32_e64 v55, v117, v55, s[50:51]
	.loc	1 530 48                        ; extend_attention.py:530:48
	v_max_f32_e32 v55, v55, v120
	.loc	1 532 38                        ; extend_attention.py:532:38
	v_sub_f32_e32 v68, v68, v55
	.loc	1 532 30 is_stmt 0              ; extend_attention.py:532:30
	v_mul_f32_e32 v120, 0x3fb8aa3b, v68
	v_cmp_gt_f32_e64 s[50:51], s97, v120
	.loc	1 533 28 is_stmt 1              ; extend_attention.py:533:28
	v_sub_f32_e32 v35, v35, v55
	v_sub_f32_e32 v164, v51, v55
	.loc	1 532 30                        ; extend_attention.py:532:30
	v_cndmask_b32_e64 v120, 0, v118, s[50:51]
	v_fmac_f32_e32 v120, 0x3fb8aa3b, v68
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_mul_f32_e32 v51, 0x3fb8aa3b, v35
	.loc	1 532 30                        ; extend_attention.py:532:30
	v_exp_f32_e32 v68, v120
	v_cndmask_b32_e64 v120, 0, v119, s[50:51]
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cmp_gt_f32_e64 s[50:51], s97, v51
	.loc	1 533 28 is_stmt 0              ; extend_attention.py:533:28
	v_sub_f32_e32 v37, v37, v55
	v_sub_f32_e32 v39, v39, v55
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cndmask_b32_e64 v51, 0, v118, s[50:51]
	v_fmac_f32_e32 v51, 0x3fb8aa3b, v35
	v_exp_f32_e32 v35, v51
	v_cndmask_b32_e64 v51, 0, v119, s[50:51]
	.loc	1 533 28                        ; extend_attention.py:533:28
	v_sub_f32_e32 v41, v41, v55
	v_sub_f32_e32 v43, v43, v55
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_ldexp_f32 v35, v35, v51
	v_mul_f32_e32 v51, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e64 s[50:51], s97, v51
	.loc	1 533 28                        ; extend_attention.py:533:28
	v_sub_f32_e32 v45, v45, v55
	v_sub_f32_e32 v47, v47, v55
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cndmask_b32_e64 v51, 0, v118, s[50:51]
	v_fmac_f32_e32 v51, 0x3fb8aa3b, v37
	v_exp_f32_e32 v37, v51
	v_mul_f32_e32 v51, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e64 s[52:53], s97, v51
	.loc	1 533 28                        ; extend_attention.py:533:28
	v_sub_f32_e32 v49, v49, v55
	v_sub_f32_e32 v165, v53, v55
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cndmask_b32_e64 v51, 0, v118, s[52:53]
	v_fmac_f32_e32 v51, 0x3fb8aa3b, v39
	v_exp_f32_e32 v39, v51
	v_cndmask_b32_e64 v51, 0, v119, s[50:51]
	v_ldexp_f32 v37, v37, v51
	v_cndmask_b32_e64 v51, 0, v119, s[52:53]
	v_ldexp_f32 v186, v39, v51
	v_mul_f32_e32 v39, 0x3fb8aa3b, v41
	v_cmp_gt_f32_e64 s[50:51], s97, v39
	.loc	1 532 30 is_stmt 1              ; extend_attention.py:532:30
	v_ldexp_f32 v68, v68, v120
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v50, v50, s98
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cndmask_b32_e64 v39, 0, v118, s[50:51]
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v41
	v_mul_f32_e32 v41, 0x3fb8aa3b, v43
	v_cmp_gt_f32_e64 s[52:53], s97, v41
	v_exp_f32_e32 v39, v39
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v136, v48, s98
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cndmask_b32_e64 v41, 0, v118, s[52:53]
	v_fmac_f32_e32 v41, 0x3fb8aa3b, v43
	v_exp_f32_e32 v41, v41
	v_cndmask_b32_e64 v43, 0, v119, s[50:51]
	v_ldexp_f32 v187, v39, v43
	v_cndmask_b32_e64 v39, 0, v119, s[52:53]
	v_ldexp_f32 v188, v41, v39
	v_mul_f32_e32 v39, 0x3fb8aa3b, v45
	v_cmp_gt_f32_e64 s[50:51], s97, v39
	v_mul_f32_e32 v41, 0x3fb8aa3b, v47
	v_cmp_gt_f32_e64 s[52:53], s97, v41
	v_cndmask_b32_e64 v39, 0, v118, s[50:51]
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v45
	v_cndmask_b32_e64 v41, 0, v118, s[52:53]
	v_exp_f32_e32 v39, v39
	v_fmac_f32_e32 v41, 0x3fb8aa3b, v47
	v_exp_f32_e32 v41, v41
	v_cndmask_b32_e64 v43, 0, v119, s[50:51]
	v_ldexp_f32 v51, v39, v43
	v_cndmask_b32_e64 v39, 0, v119, s[52:53]
	v_ldexp_f32 v53, v41, v39
	v_mul_f32_e32 v39, 0x3fb8aa3b, v49
	v_cmp_gt_f32_e64 s[50:51], s97, v39
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v41, v64, s98
	v_mul_lo_u32 v64, v46, s98
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_cndmask_b32_e64 v39, 0, v118, s[50:51]
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v49
	v_exp_f32_e32 v189, v39
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v39, v62, s98
	v_mul_lo_u32 v49, v54, s98
	.loc	1 542 16 is_stmt 0              ; extend_attention.py:542:16
	v_add_lshl_u32 v38, v82, v39, 1
	v_add_lshl_u32 v46, v82, v49, 1
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v54, v56, s98
	.loc	1 542 16                        ; extend_attention.py:542:16
	v_cndmask_b32_e64 v38, v78, v38, s[14:15]
	s_mov_b32 s14, s94
	s_mov_b32 s15, s95
	v_cndmask_b32_e64 v46, v78, v46, s[42:43]
	buffer_load_dwordx4 v[120:123], v46, s[12:15], 0 offen
	v_add_lshl_u32 v46, v82, v54, 1
	v_cndmask_b32_e64 v46, v78, v46, s[40:41]
	buffer_load_dwordx4 v[124:127], v46, s[12:15], 0 offen
	v_add_lshl_u32 v46, v82, v50, 1
	v_add_lshl_u32 v50, v82, v64, 1
	v_cndmask_b32_e64 v50, v78, v50, s[34:35]
	buffer_load_dwordx4 v[132:135], v50, s[12:15], 0 offen
	v_add_lshl_u32 v50, v82, v136, 1
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v140, v42, s98
	.loc	1 542 16                        ; extend_attention.py:542:16
	v_cndmask_b32_e64 v50, v78, v50, s[30:31]
	buffer_load_dwordx4 v[136:139], v50, s[12:15], 0 offen
	v_add_lshl_u32 v50, v82, v140, 1
	v_cndmask_b32_e64 v50, v78, v50, s[28:29]
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v34, v34, s98
	.loc	1 542 16                        ; extend_attention.py:542:16
	buffer_load_dwordx4 v[140:143], v50, s[12:15], 0 offen
	v_add_lshl_u32 v50, v82, v144, 1
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v148, v44, s98
	.loc	1 542 16                        ; extend_attention.py:542:16
	v_cndmask_b32_e64 v50, v78, v50, s[26:27]
	v_add_lshl_u32 v34, v82, v34, 1
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v36, v36, s98
	.loc	1 542 16                        ; extend_attention.py:542:16
	buffer_load_dwordx4 v[144:147], v50, s[12:15], 0 offen
	v_add_lshl_u32 v50, v82, v148, 1
	v_cndmask_b32_e64 v34, v78, v34, s[10:11]
	v_cndmask_b32_e64 v50, v78, v50, s[24:25]
	buffer_load_dwordx4 v[152:155], v34, s[12:15], 0 offen
	buffer_load_dwordx4 v[156:159], v50, s[12:15], 0 offen
	v_add_lshl_u32 v34, v82, v36, 1
	.loc	1 533 28 is_stmt 1              ; extend_attention.py:533:28
	v_sub_f32_e32 v166, v57, v55
	v_sub_f32_e32 v167, v59, v55
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v43, v58, s98
	.loc	1 542 16 is_stmt 0              ; extend_attention.py:542:16
	buffer_load_dwordx4 v[56:59], v38, s[12:15], 0 offen
	v_cndmask_b32_e64 v34, v78, v34, s[6:7]
	buffer_load_dwordx4 v[160:163], v34, s[12:15], 0 offen
	v_add_lshl_u32 v38, v82, v41, 1
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v52, v52, s98
	v_mul_lo_u32 v149, v40, s98
	.loc	1 542 16                        ; extend_attention.py:542:16
	v_cndmask_b32_e64 v38, v78, v38, s[48:49]
	v_cndmask_b32_e64 v46, v78, v46, s[38:39]
	.loc	1 533 28 is_stmt 1              ; extend_attention.py:533:28
	v_sub_f32_e32 v168, v61, v55
	v_sub_f32_e32 v169, v63, v55
	.loc	1 542 27                        ; extend_attention.py:542:27
	v_mul_lo_u32 v47, v60, s98
	.loc	1 542 16 is_stmt 0              ; extend_attention.py:542:16
	buffer_load_dwordx4 v[60:63], v38, s[12:15], 0 offen
	buffer_load_dwordx4 v[128:131], v46, s[12:15], 0 offen
	v_add_lshl_u32 v38, v82, v43, 1
	v_add_lshl_u32 v46, v82, v52, 1
	v_add_lshl_u32 v52, v82, v149, 1
	v_cndmask_b32_e64 v38, v78, v38, s[46:47]
	v_cndmask_b32_e64 v52, v78, v52, s[22:23]
	buffer_load_dwordx4 v[42:45], v38, s[12:15], 0 offen
	buffer_load_dwordx4 v[148:151], v52, s[12:15], 0 offen
	v_add_lshl_u32 v38, v82, v47, 1
	v_cndmask_b32_e64 v38, v78, v38, s[44:45]
	v_cndmask_b32_e64 v46, v78, v46, s[36:37]
	buffer_load_dwordx4 v[38:41], v38, s[12:15], 0 offen
	.loc	1 533 23 is_stmt 1              ; extend_attention.py:533:23
	v_cndmask_b32_e64 v34, 0, v119, s[50:51]
	.loc	1 542 16                        ; extend_attention.py:542:16
	buffer_load_dwordx4 v[46:49], v46, s[12:15], 0 offen
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_ldexp_f32 v50, v189, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v164
	v_cmp_gt_f32_e64 s[6:7], s97, v34
	v_mul_f32_e32 v36, 0x3fb8aa3b, v165
	v_cmp_gt_f32_e64 s[10:11], s97, v36
	v_cndmask_b32_e64 v34, 0, v118, s[6:7]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v164
	v_cndmask_b32_e64 v36, 0, v118, s[10:11]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v165
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e64 v52, 0, v119, s[6:7]
	.loc	1 533 28 is_stmt 0              ; extend_attention.py:533:28
	v_sub_f32_e32 v67, v67, v55
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_ldexp_f32 v54, v34, v52
	v_cndmask_b32_e64 v34, 0, v119, s[10:11]
	v_ldexp_f32 v64, v36, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v67
	v_cmp_gt_f32_e64 s[6:7], s97, v34
	v_mul_f32_e32 v36, 0x3fb8aa3b, v166
	v_cmp_gt_f32_e64 s[10:11], s97, v36
	v_cndmask_b32_e64 v34, 0, v118, s[6:7]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v67
	v_cndmask_b32_e64 v36, 0, v118, s[10:11]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v166
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e64 v52, 0, v119, s[6:7]
	v_ldexp_f32 v67, v34, v52
	v_cndmask_b32_e64 v34, 0, v119, s[10:11]
	v_ldexp_f32 v164, v36, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v167
	v_cmp_gt_f32_e64 s[6:7], s97, v34
	v_mul_f32_e32 v36, 0x3fb8aa3b, v168
	v_cmp_gt_f32_e64 s[10:11], s97, v36
	v_cndmask_b32_e64 v34, 0, v118, s[6:7]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v167
	v_cndmask_b32_e64 v36, 0, v118, s[10:11]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v168
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e64 v52, 0, v119, s[6:7]
	v_ldexp_f32 v165, v34, v52
	v_cndmask_b32_e64 v34, 0, v119, s[10:11]
	.loc	1 533 28                        ; extend_attention.py:533:28
	v_sub_f32_e32 v65, v65, v55
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_ldexp_f32 v166, v36, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v169
	v_cmp_gt_f32_e64 s[6:7], s97, v34
	v_mul_f32_e32 v36, 0x3fb8aa3b, v65
	v_cmp_gt_f32_e64 s[10:11], s97, v36
	v_cndmask_b32_e64 v34, 0, v118, s[6:7]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v169
	v_cndmask_b32_e64 v36, 0, v118, s[10:11]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v65
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e64 v52, 0, v119, s[6:7]
	v_ldexp_f32 v65, v34, v52
	v_cndmask_b32_e64 v34, 0, v119, s[10:11]
	.loc	1 542 16 is_stmt 1              ; extend_attention.py:542:16
	s_waitcnt vmcnt(7) lgkmcnt(0)
	; wave barrier
	ds_write2st64_b64 v90, v[56:57], v[120:121] offset1:8
	ds_write2st64_b64 v90, v[132:133], v[144:145] offset0:16 offset1:24
	ds_write2st64_b64 v105, v[58:59], v[122:123] offset1:8
	ds_write2st64_b64 v105, v[134:135], v[146:147] offset0:16 offset1:24
	s_waitcnt vmcnt(5)
	ds_write2st64_b64 v106, v[60:61], v[124:125] offset0:2 offset1:10
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v106, v[136:137], v[148:149] offset0:18 offset1:26
	ds_write2st64_b64 v107, v[62:63], v[126:127] offset0:2 offset1:10
	ds_write2st64_b64 v107, v[138:139], v[150:151] offset0:18 offset1:26
	ds_write2st64_b64 v108, v[42:43], v[128:129] offset0:4 offset1:12
	ds_write2st64_b64 v108, v[140:141], v[152:153] offset0:20 offset1:28
	ds_write2st64_b64 v109, v[44:45], v[130:131] offset0:4 offset1:12
	ds_write2st64_b64 v109, v[142:143], v[154:155] offset0:20 offset1:28
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v110, v[38:39], v[46:47] offset0:6 offset1:14
	ds_write2st64_b64 v110, v[156:157], v[160:161] offset0:22 offset1:30
	ds_write2st64_b64 v111, v[40:41], v[48:49] offset0:6 offset1:14
	ds_write2st64_b64 v111, v[158:159], v[162:163] offset0:22 offset1:30
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b16 v[42:43], v112
	ds_read_b64_tr_b16 v[44:45], v112 offset:4096
	.loc	1 533 23                        ; extend_attention.py:533:23
	v_ldexp_f32 v167, v36, v34
.Ltmp109:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v34, v35, v37
	v_add_f32_e32 v34, v186, v34
	v_add_f32_e32 v34, v187, v34
	v_add_f32_e32 v52, v188, v34
.Ltmp110:
	.loc	1 546 21                        ; extend_attention.py:546:21
	v_cvt_pk_bf16_f32 v34, v35, v37
	v_cvt_pk_bf16_f32 v35, v186, v187
	v_cvt_pk_bf16_f32 v36, v188, v51
	v_cvt_pk_bf16_f32 v37, v53, v50
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[46:47], v112 offset:8192
	ds_read_b64_tr_b16 v[48:49], v112 offset:12288
	ds_read_b64_tr_b16 v[56:57], v113
	ds_read_b64_tr_b16 v[58:59], v113 offset:4096
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[42:45], v[34:37], 0
	.loc	1 546 21                        ; extend_attention.py:546:21
	v_cvt_pk_bf16_f32 v38, v54, v64
	v_cvt_pk_bf16_f32 v39, v67, v164
	v_cvt_pk_bf16_f32 v40, v165, v166
	v_cvt_pk_bf16_f32 v41, v65, v167
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[60:61], v113 offset:8192
	ds_read_b64_tr_b16 v[62:63], v113 offset:12288
	ds_read_b64_tr_b16 v[120:121], v114
	ds_read_b64_tr_b16 v[122:123], v114 offset:4096
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[46:49], v[38:41], v[42:45]
.Ltmp111:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v51, v51, v52
	v_add_f32_e32 v51, v53, v51
.Ltmp112:
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[124:125], v114 offset:8192
	ds_read_b64_tr_b16 v[126:127], v114 offset:12288
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[56:59], v[34:37], 0
.Ltmp113:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v56, v50, v51
	v_add_f32_e32 v54, v54, v56
.Ltmp114:
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[128:129], v112 offset:8320
	ds_read_b64_tr_b16 v[130:131], v112 offset:12416
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[60:63], v[38:41], v[46:49]
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[58:59], v115
	ds_read_b64_tr_b16 v[60:61], v115 offset:4096
.Ltmp115:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v54, v64, v54
.Ltmp116:
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[136:137], v115 offset:128
	ds_read_b64_tr_b16 v[138:139], v115 offset:4224
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[50:53], v[120:123], v[34:37], 0
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[120:121], v115 offset:8192
	ds_read_b64_tr_b16 v[122:123], v115 offset:12288
.Ltmp117:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v54, v67, v54
	v_add_f32_e32 v54, v164, v54
.Ltmp118:
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[50:53], v[124:127], v[38:41], v[50:53]
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[124:125], v112 offset:128
	ds_read_b64_tr_b16 v[126:127], v112 offset:4224
.Ltmp119:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v54, v165, v54
	v_add_f32_e32 v54, v166, v54
.Ltmp120:
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[56:59], v[58:61], v[34:37], 0
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[132:133], v114 offset:8320
	ds_read_b64_tr_b16 v[134:135], v114 offset:12416
.Ltmp121:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v54, v65, v54
	v_add_f32_e32 v54, v167, v54
.Ltmp122:
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[56:59], v[120:123], v[38:41], v[56:59]
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[120:121], v113 offset:128
	ds_read_b64_tr_b16 v[122:123], v113 offset:4224
.Ltmp123:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:534:47 ]
	v_mov_b32_e32 v64, v54
	s_nop 1
	v_permlane32_swap_b32_e32 v54, v64
.Ltmp124:
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[60:63], v[124:127], v[34:37], 0
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[124:125], v113 offset:8320
	ds_read_b64_tr_b16 v[126:127], v113 offset:12416
.Ltmp125:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v54, v54, v64
.Ltmp126:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:534:47 ]
	v_mov_b32_e32 v64, v54
.Ltmp127:
	.loc	1 547 54                        ; extend_attention.py:547:54
	v_mfma_f32_16x16x32_bf16 v[60:63], v[128:131], v[38:41], v[60:63]
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[128:129], v114 offset:128
	ds_read_b64_tr_b16 v[130:131], v114 offset:4224
.Ltmp128:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:534:47 ]
	v_permlane16_swap_b32_e32 v54, v64
.Ltmp129:
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[120:123], v[120:123], v[34:37], 0
.Ltmp130:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:534:47 ] ]
	v_add_f32_e32 v54, v54, v64
	v_readlane_b32 s78, v203, 55
	v_readlane_b32 s76, v203, 53
.Ltmp131:
	.loc	1 547 54                        ; extend_attention.py:547:54
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[120:123], v[124:127], v[38:41], v[120:123]
	v_readlane_b32 s74, v203, 51
	v_readlane_b32 s72, v203, 49
	v_readlane_b32 s70, v203, 47
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[124:127], v[128:131], v[34:37], 0
	.loc	1 542 16                        ; extend_attention.py:542:16
	ds_read_b64_tr_b16 v[128:129], v115 offset:8320
	ds_read_b64_tr_b16 v[130:131], v115 offset:12416
	v_readlane_b32 s68, v203, 45
	v_readlane_b32 s66, v203, 43
	.loc	1 547 54                        ; extend_attention.py:547:54
	v_mfma_f32_16x16x32_bf16 v[34:37], v[136:139], v[34:37], 0
	v_readlane_b32 s64, v203, 41
	.loc	1 534 37                        ; extend_attention.py:534:37
	v_fmac_f32_e32 v54, v69, v68
	v_readlane_b32 s79, v203, 56
	.loc	1 547 54                        ; extend_attention.py:547:54
	v_mfma_f32_16x16x32_bf16 v[124:127], v[132:135], v[38:41], v[124:127]
	v_readlane_b32 s77, v203, 54
	v_readlane_b32 s75, v203, 52
	v_readlane_b32 s73, v203, 50
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[128:131], v[38:41], v[34:37]
	.loc	1 547 59 is_stmt 0              ; extend_attention.py:547:59
	v_mul_f32_e64 v38, s86, v42
	v_mul_f32_e64 v39, s87, v43
	v_pk_mul_f32 v[40:41], s[86:87], v[44:45]
	v_pk_mul_f32 v[42:43], s[86:87], v[46:47]
	v_pk_mul_f32 v[44:45], s[86:87], v[48:49]
	v_pk_mul_f32 v[46:47], s[86:87], v[50:51]
	v_pk_mul_f32 v[48:49], s[86:87], v[52:53]
	v_pk_mul_f32 v[50:51], s[86:87], v[56:57]
	v_pk_mul_f32 v[52:53], s[86:87], v[58:59]
	v_pk_mul_f32 v[56:57], s[86:87], v[60:61]
	v_pk_mul_f32 v[58:59], s[86:87], v[62:63]
	v_pk_mul_f32 v[60:61], s[86:87], v[120:121]
	v_pk_mul_f32 v[62:63], s[86:87], v[122:123]
	v_pk_mul_f32 v[64:65], s[86:87], v[124:125]
	v_pk_mul_f32 v[120:121], s[86:87], v[126:127]
	v_pk_mul_f32 v[34:35], s[86:87], v[34:35]
	v_pk_mul_f32 v[36:37], s[86:87], v[36:37]
	v_readlane_b32 s71, v203, 48
	v_readlane_b32 s69, v203, 46
	v_readlane_b32 s67, v203, 44
	v_readlane_b32 s65, v203, 42
	s_mov_b32 s58, s0
	s_mov_b32 s57, s1
	s_mov_b32 s56, s2
	s_mov_b32 s55, s3
	s_mov_b32 s54, s19
	s_mov_b32 s19, s16
	s_mov_b32 s16, s8
	s_mov_b32 s53, s99
	s_mov_b32 s52, s9
	s_mov_b32 s8, s17
	v_readlane_b32 s2, v202, 7
	v_readlane_b32 s3, v202, 6
	v_readlane_b32 s17, v202, 5
	v_readlane_b32 s1, v202, 4
	v_readlane_b32 s0, v202, 3
	.loc	1 547 44                        ; extend_attention.py:547:44
	v_pk_fma_f32 v[30:31], v[30:31], v[68:69], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[32:33], v[32:33], v[68:69], v[40:41] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[26:27], v[26:27], v[68:69], v[42:43] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[28:29], v[68:69], v[44:45] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[22:23], v[68:69], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[24:25], v[24:25], v[68:69], v[48:49] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[18:19], v[18:19], v[68:69], v[50:51] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[20:21], v[20:21], v[68:69], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[14:15], v[14:15], v[68:69], v[56:57] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[16:17], v[68:69], v[58:59] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[10:11], v[68:69], v[60:61] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[12:13], v[12:13], v[68:69], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[6:7], v[68:69], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[8:9], v[68:69], v[120:121] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[2:3], v[68:69], v[34:35] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[68:69], v[36:37] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v69, v54
	v_mov_b32_e32 v68, v55
	s_branch .LBB0_2
.LBB0_5:                                ; %Flow481
	.loc	1 0 44                          ; extend_attention.py:0:44
	v_readlane_b32 s28, v203, 58
	v_readlane_b32 s96, v203, 60
	v_readlane_b32 s29, v203, 59
	v_readlane_b32 s30, v202, 0
	v_readlane_b32 s97, v203, 61
	v_readlane_b32 s31, v202, 1
	v_readlane_b32 s29, v203, 57
	v_readlane_b32 s98, v203, 62
	v_readlane_b32 s99, v203, 63
.LBB0_6:                                ; %Flow482
	s_load_dwordx2 s[82:83], s[30:31], 0x80
	s_load_dwordx4 s[12:15], s[30:31], 0x70
	.loc	1 556 64 is_stmt 1              ; extend_attention.py:556:64
	s_add_i32 s0, s16, 16
	.loc	1 556 44 is_stmt 0              ; extend_attention.py:556:44
	s_min_i32 s20, s29, s0
	.loc	1 558 45 is_stmt 1              ; extend_attention.py:558:45
	s_cmp_lt_i32 s20, 1
	v_readlane_b32 s81, v203, 0
	v_readlane_b32 s92, v203, 1
	v_readlane_b32 s93, v203, 2
	v_readlane_b32 s94, v203, 3
	v_readlane_b32 s95, v203, 4
	s_cbranch_scc1 .LBB0_11
; %bb.7:                                ; %.lr.ph12
	s_waitcnt lgkmcnt(0)
	v_mul_lo_u32 v48, s15, v72
	v_add_u32_e32 v49, s28, v93
	v_lshlrev_b32_e32 v48, 1, v48
	v_mul_lo_u32 v50, s14, v49
	v_lshl_add_u32 v105, v50, 1, v48
	v_add_u32_e32 v50, 4, v49
	v_mul_lo_u32 v51, s14, v50
	v_lshl_add_u32 v106, v51, 1, v48
	v_add_u32_e32 v51, 8, v49
	v_mul_lo_u32 v52, s14, v51
	v_lshl_add_u32 v107, v52, 1, v48
	v_add_u32_e32 v52, 12, v49
	v_mul_lo_u32 v53, s14, v52
	v_lshl_add_u32 v108, v53, 1, v48
	v_add_u32_e32 v53, 16, v49
	v_mul_lo_u32 v54, s14, v53
	v_lshl_add_u32 v109, v54, 1, v48
	v_add_u32_e32 v54, 20, v49
	v_mul_lo_u32 v55, s14, v54
	v_lshl_add_u32 v110, v55, 1, v48
	v_add_u32_e32 v55, 24, v49
	v_mul_lo_u32 v56, s14, v55
	v_lshl_add_u32 v111, v56, 1, v48
	v_add_u32_e32 v56, 28, v49
	v_mul_lo_u32 v57, s14, v56
	v_lshl_add_u32 v112, v57, 1, v48
	v_add_u32_e32 v57, 32, v49
	v_mul_lo_u32 v58, s14, v57
	v_lshl_add_u32 v113, v58, 1, v48
	v_add_u32_e32 v58, 36, v49
	v_mul_lo_u32 v59, s14, v58
	v_lshl_add_u32 v114, v59, 1, v48
	v_add_u32_e32 v59, 40, v49
	v_mul_lo_u32 v60, s14, v59
	v_lshl_add_u32 v115, v60, 1, v48
	v_add_u32_e32 v60, 44, v49
	v_mul_lo_u32 v61, s14, v60
	v_lshl_add_u32 v116, v61, 1, v48
	v_add_u32_e32 v61, 48, v49
	v_mul_lo_u32 v62, s14, v61
	v_lshl_add_u32 v117, v62, 1, v48
	v_add_u32_e32 v62, 52, v49
	v_mul_lo_u32 v63, s14, v62
	v_lshl_add_u32 v118, v63, 1, v48
	v_add_u32_e32 v63, 56, v49
	v_mul_lo_u32 v64, s14, v63
	v_lshl_add_u32 v119, v64, 1, v48
	v_add_u32_e32 v64, 60, v49
	v_mul_lo_u32 v65, s14, v64
	v_lshl_add_u32 v120, v65, 1, v48
	v_mul_lo_u32 v48, s13, v72
	v_lshlrev_b32_e32 v48, 1, v48
	v_mul_lo_u32 v49, s12, v49
	v_lshl_add_u32 v121, v49, 1, v48
	v_mul_lo_u32 v49, s12, v50
	v_lshl_add_u32 v122, v49, 1, v48
	v_mul_lo_u32 v49, s12, v51
	v_lshl_add_u32 v123, v49, 1, v48
	v_mul_lo_u32 v49, s12, v52
	v_lshl_add_u32 v124, v49, 1, v48
	v_mul_lo_u32 v49, s12, v53
	v_lshl_add_u32 v125, v49, 1, v48
	v_mul_lo_u32 v49, s12, v54
	v_lshl_add_u32 v126, v49, 1, v48
	v_mul_lo_u32 v49, s12, v55
	v_lshl_add_u32 v127, v49, 1, v48
	v_mul_lo_u32 v49, s12, v56
	v_lshl_add_u32 v128, v49, 1, v48
	v_mul_lo_u32 v49, s12, v57
	v_lshl_add_u32 v129, v49, 1, v48
	v_mul_lo_u32 v49, s12, v58
	v_lshl_add_u32 v130, v49, 1, v48
	v_mul_lo_u32 v49, s12, v59
	v_lshl_add_u32 v131, v49, 1, v48
	v_mul_lo_u32 v49, s12, v60
	v_lshl_add_u32 v132, v49, 1, v48
	v_mul_lo_u32 v49, s12, v61
	v_lshlrev_b32_e32 v44, 6, v75
	v_and_b32_e32 v45, 24, v74
	v_lshlrev_b32_e32 v46, 1, v75
	v_lshl_add_u32 v133, v49, 1, v48
	v_mul_lo_u32 v49, s12, v62
	v_xor_b32_e32 v36, v73, v77
	v_bitop3_b32 v44, v44, v46, v45 bitop3:0x36
	v_lshl_add_u32 v134, v49, 1, v48
	v_mul_lo_u32 v49, s12, v63
	v_xor_b32_e32 v34, 0x80, v76
	v_xor_b32_e32 v35, 0xc0, v76
	v_xor_b32_e32 v37, 8, v36
	v_xor_b32_e32 v38, 32, v36
	v_xor_b32_e32 v39, 40, v36
	v_xor_b32_e32 v40, 64, v36
	v_xor_b32_e32 v41, 0x48, v36
	v_xor_b32_e32 v42, 0x60, v36
	v_xor_b32_e32 v43, 0x68, v36
	v_xor_b32_e32 v45, 32, v44
	v_xor_b32_e32 v46, 64, v44
	v_xor_b32_e32 v47, 0x60, v44
	v_lshl_add_u32 v135, v49, 1, v48
	v_mul_lo_u32 v49, s12, v64
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	s_and_b32 s85, s85, 0xffff
	s_lshl_b32 s21, s14, 7
	s_lshl_b32 s90, s12, 7
	v_lshl_add_u32 v136, v49, 1, v48
	s_mov_b32 s91, 0
	v_add_u32_e32 v137, 0, v70
	v_add_u32_e32 v138, 0, v71
	v_add_u32_e32 v139, 0, v34
	v_add_u32_e32 v140, 0, v35
	s_mov_b32 s80, 0xc2fc0000
	v_add_u32_e32 v141, 0, v36
	v_add_u32_e32 v142, 0, v37
	v_add_u32_e32 v143, 0, v38
	v_add_u32_e32 v144, 0, v39
	v_add_u32_e32 v145, 0, v40
	v_add_u32_e32 v146, 0, v41
	v_add_u32_e32 v147, 0, v42
	v_add_u32_e32 v148, 0, v43
	v_add_u32_e32 v149, 0, v44
	v_add_u32_e32 v150, 0, v45
	v_add_u32_e32 v151, 0, v46
	v_add_u32_e32 v152, 0, v47
	v_mov_b32_e32 v153, 0
	v_bfrev_b32_e32 v154, 1
	v_mov_b32_e32 v155, 0xff800000
	v_mov_b32_e32 v156, 0x42800000
	v_not_b32_e32 v157, 63
	s_branch .LBB0_9
.LBB0_8:                                ;   in Loop: Header=BB0_9 Depth=1
	.loc	1 0 45 is_stmt 0                ; extend_attention.py:0:45
	s_or_b64 exec, exec, s[88:89]
	.loc	1 558 45 is_stmt 1              ; extend_attention.py:558:45
	s_add_i32 s91, s91, 64
	v_add_u32_e32 v105, s21, v105
	v_add_u32_e32 v106, s21, v106
	v_add_u32_e32 v107, s21, v107
	v_add_u32_e32 v108, s21, v108
	v_add_u32_e32 v109, s21, v109
	v_add_u32_e32 v110, s21, v110
	v_add_u32_e32 v111, s21, v111
	v_add_u32_e32 v112, s21, v112
	v_add_u32_e32 v113, s21, v113
	v_add_u32_e32 v114, s21, v114
	v_add_u32_e32 v115, s21, v115
	v_add_u32_e32 v116, s21, v116
	v_add_u32_e32 v117, s21, v117
	v_add_u32_e32 v118, s21, v118
	v_add_u32_e32 v119, s21, v119
	v_add_u32_e32 v120, s21, v120
	v_add_u32_e32 v121, s90, v121
	v_add_u32_e32 v122, s90, v122
	v_add_u32_e32 v123, s90, v123
	v_add_u32_e32 v124, s90, v124
	v_add_u32_e32 v125, s90, v125
	v_add_u32_e32 v126, s90, v126
	v_add_u32_e32 v127, s90, v127
	v_add_u32_e32 v128, s90, v128
	v_add_u32_e32 v129, s90, v129
	v_add_u32_e32 v130, s90, v130
	v_add_u32_e32 v131, s90, v131
	v_add_u32_e32 v132, s90, v132
	v_add_u32_e32 v133, s90, v133
	v_add_u32_e32 v134, s90, v134
	v_add_u32_e32 v135, s90, v135
	s_cmp_lt_i32 s91, s20
	v_add_u32_e32 v136, s90, v136
	s_cbranch_scc0 .LBB0_11
.LBB0_9:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_add_u32_e32 v34, s91, v0
	v_readlane_b32 s17, v203, 5
	v_readlane_b32 s54, v203, 6
	v_readlane_b32 s55, v203, 7
	v_readlane_b32 s56, v203, 10
	v_readlane_b32 s57, v203, 13
	v_readlane_b32 s58, v203, 16
	v_readlane_b32 s59, v203, 19
	v_readlane_b32 s60, v203, 22
	v_readlane_b32 s61, v203, 25
	v_readlane_b32 s62, v203, 28
	v_cmp_gt_i32_e64 s[0:1], s20, v34
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[14:15], s16, v34
	v_cmp_ge_i32_e64 s[22:23], s81, v34
	v_cmp_ge_i32_e64 s[24:25], s92, v34
	v_cmp_ge_i32_e64 s[26:27], s93, v34
	v_cmp_ge_i32_e64 s[28:29], s94, v34
	v_cmp_ge_i32_e64 s[30:31], s95, v34
	v_cmp_ge_i32_e64 s[34:35], s17, v34
	v_cmp_ge_i32_e64 s[36:37], s54, v34
	v_cmp_ge_i32_e64 s[38:39], s55, v34
	v_cmp_ge_i32_e64 s[40:41], s56, v34
	v_cmp_ge_i32_e64 s[42:43], s57, v34
	v_cmp_ge_i32_e64 s[44:45], s58, v34
	v_cmp_ge_i32_e64 s[46:47], s59, v34
	v_cmp_ge_i32_e64 s[48:49], s60, v34
	v_cmp_ge_i32_e64 s[12:13], s61, v34
	v_cmp_ge_i32_e64 s[10:11], s62, v34
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v34, 0xfff, v34
	v_cmp_lt_i32_e64 s[52:53], s16, v34
	v_cmp_le_i32_e64 s[50:51], s16, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[8:9], s[52:53], s[0:1]
	s_and_b64 s[2:3], s[14:15], s[50:51]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s92, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[8:9], s[8:9], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s93, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[18:19], s[24:25], s[14:15]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s94, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[24:25], s[26:27], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s95, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[26:27], s[28:29], s[14:15]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s17, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[28:29], s[30:31], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s54, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[30:31], s[34:35], s[14:15]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s55, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[34:35], s[36:37], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s56, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[36:37], s[38:39], s[14:15]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s57, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[38:39], s[40:41], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s58, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[0:1], s[2:3]
	s_and_b64 s[40:41], s[42:43], s[14:15]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s59, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[42:43], s[44:45], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s60, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[64:65], s[2:3]
	s_and_b64 s[44:45], s[46:47], s[14:15]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[14:15], s61, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[46:47], s[48:49], s[22:23]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[22:23], s62, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[18:19], s[0:1], s[18:19]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v34, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[66:67], s[8:9]
	s_and_b64 s[24:25], s[0:1], s[24:25]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v35, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[68:69], s[18:19]
	s_and_b64 s[26:27], s[0:1], s[26:27]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v36, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[70:71], s[24:25]
	s_and_b64 s[28:29], s[0:1], s[28:29]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v37, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[72:73], s[26:27]
	s_and_b64 s[30:31], s[0:1], s[30:31]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v38, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[74:75], s[28:29]
	s_and_b64 s[34:35], s[0:1], s[34:35]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v39, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[76:77], s[30:31]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v40, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[78:79], s[34:35]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v41, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	v_readlane_b32 s2, v203, 8
	s_and_b64 s[36:37], s[0:1], s[36:37]
	v_readlane_b32 s3, v203, 9
	s_and_b64 s[2:3], s[2:3], s[36:37]
	s_and_b64 s[38:39], s[0:1], s[38:39]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v42, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	v_readlane_b32 s2, v203, 11
	v_readlane_b32 s3, v203, 12
	s_and_b64 s[2:3], s[2:3], s[38:39]
	s_and_b64 s[40:41], s[0:1], s[40:41]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v43, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_mov_b32 s2, s100
	v_readlane_b32 s3, v203, 15
	s_and_b64 s[2:3], s[2:3], s[40:41]
	s_and_b64 s[42:43], s[0:1], s[42:43]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v44, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	v_readlane_b32 s2, v203, 17
	v_readlane_b32 s3, v203, 18
	s_and_b64 s[2:3], s[2:3], s[42:43]
	s_and_b64 s[44:45], s[0:1], s[44:45]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v45, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	v_readlane_b32 s2, v203, 20
	v_readlane_b32 s3, v203, 21
	s_and_b64 s[2:3], s[2:3], s[44:45]
	s_and_b64 s[46:47], s[0:1], s[46:47]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v46, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	v_readlane_b32 s2, v203, 23
	v_readlane_b32 s3, v203, 24
.Ltmp132:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp133:
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[2:3], s[46:47]
	s_and_b64 s[12:13], s[12:13], s[14:15]
.Ltmp134:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp135:
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v47, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_mov_b32 s2, s101
.Ltmp136:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp137:
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[12:13], s[0:1], s[12:13]
	v_readlane_b32 s3, v203, 27
.Ltmp138:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp139:
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[2:3], s[2:3], s[12:13]
.Ltmp140:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v50, v34
.Ltmp141:
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[10:11], s[10:11], s[22:23]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v48, 0, 1, s[2:3]
	.loc	1 593 26                        ; extend_attention.py:593:26
	v_readlane_b32 s2, v203, 29
.Ltmp142:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_dpp v50, v50 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp143:
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[0:1], s[10:11]
	v_readlane_b32 s3, v203, 30
.Ltmp144:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v50
.Ltmp145:
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 597 52                        ; extend_attention.py:597:52
	v_cndmask_b32_e64 v49, 0, 1, s[0:1]
.Ltmp146:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp147:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	s_waitcnt lgkmcnt(0)
.Ltmp148:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_readlane_b32 s0, v34, 63
.Ltmp149:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	; wave barrier
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp150:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp151:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp152:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s1, v34, 63
.Ltmp153:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v36, v36 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp154:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp155:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp156:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s2, v34, 63
.Ltmp157:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v37, v37 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp158:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	s_nop 0
	v_mov_b32_e32 v36, s2
.Ltmp159:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp160:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp161:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp162:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s3, v34, 63
.Ltmp163:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v38, v38 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp164:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	s_nop 0
	v_mov_b32_e32 v37, s3
.Ltmp165:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp166:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp167:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp168:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s8, v34, 63
.Ltmp169:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v39, v39 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp170:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp171:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp172:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s9, v34, 63
.Ltmp173:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v40, v40 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp174:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp175:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp176:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s10, v34, 63
.Ltmp177:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v41, v41 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp178:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp179:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp180:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s11, v34, 63
.Ltmp181:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v42, v42 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp182:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp183:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp184:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s12, v34, 63
.Ltmp185:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v43, v43 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp186:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp187:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp188:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s13, v34, 63
.Ltmp189:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v44, v44 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp190:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp191:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp192:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s14, v34, 63
.Ltmp193:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v45, v45 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp194:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp195:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp196:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s15, v34, 63
.Ltmp197:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v46, v46 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp198:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp199:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp200:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s17, v34, 63
.Ltmp201:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v47, v47 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp202:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp203:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp204:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s18, v34, 63
.Ltmp205:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v48, v48 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp206:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp207:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp208:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s19, v34, 63
.Ltmp209:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_dpp v34, v49, v49 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v34, v34, v34 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp210:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp211:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp212:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	v_mov_b32_e32 v35, s1
.Ltmp213:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:38 ] ]
	s_nop 0
	v_max_i32_dpp v34, v34, v34 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp214:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:38 ]
	s_nop 0
	v_readlane_b32 s22, v34, 63
.Ltmp215:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	v_mov_b32_e32 v34, s0
	ds_write_b128 v153, v[34:37]
	v_mov_b32_e32 v34, s8
	v_mov_b32_e32 v35, s9
	v_mov_b32_e32 v36, s10
	v_mov_b32_e32 v37, s11
	ds_write_b128 v153, v[34:37] offset:16
	v_mov_b32_e32 v34, s12
	v_mov_b32_e32 v35, s13
	v_mov_b32_e32 v36, s14
	v_mov_b32_e32 v37, s15
	ds_write_b128 v153, v[34:37] offset:32
	v_mov_b32_e32 v34, s17
	v_mov_b32_e32 v35, s18
	v_mov_b32_e32 v36, s19
	v_mov_b32_e32 v37, s22
	ds_write_b128 v153, v[34:37] offset:48
	; wave barrier
	ds_read_b32 v34, v137
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v35, v34 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp216:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp217:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v35, v34 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp218:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp219:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp220:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp221:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:597:31 ]
	v_mov_b32_e32 v35, v34
	s_nop 1
	v_mov_b32_dpp v35, v35 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp222:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:597:31 ] ]
	v_max_i32_e32 v34, v34, v35
.Ltmp223:
	.loc	1 0 0 is_stmt 0                 ; extend_attention.py:0
	v_cmp_ne_u32_e64 s[0:1], 0, v34
	.loc	1 599 11 is_stmt 1              ; extend_attention.py:599:11
	s_and_saveexec_b64 s[88:89], s[0:1]
	s_cbranch_execz .LBB0_8
; %bb.10:                               ;   in Loop: Header=BB0_9 Depth=1
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v34, s91, v103
	v_add_u32_e32 v35, 51, v34
	.loc	1 591 16 is_stmt 0              ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1032, v34
	.loc	1 560 38 is_stmt 1              ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 50, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1031, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[38:39], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 49, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1030, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[42:43], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 48, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x102f, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[46:47], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 35, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1022, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[50:51], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 34, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1021, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[56:57], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 33, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1020, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[58:59], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 32, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x101f, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[60:61], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 19, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1012, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[62:63], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 18, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1011, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[64:65], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 17, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1010, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[66:67], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 16, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x100f, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[68:69], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 3, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1002, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[70:71], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 2, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1001, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[72:73], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 591 44                        ; extend_attention.py:591:44
	v_add_u32_e32 v35, 1, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v36, 0x1000, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v35
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[74:75], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v36
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_add_u32_e32 v35, 0xfff, v34
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[10:11], s20, v34
	.loc	1 580 16                        ; extend_attention.py:580:16
	v_cmp_ge_i32_e64 s[12:13], v97, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[76:77], vcc, s[0:1]
	.loc	1 591 16                        ; extend_attention.py:591:16
	v_cmp_le_i32_e64 s[0:1], v97, v35
	.loc	1 582 28                        ; extend_attention.py:582:28
	s_and_b64 s[2:3], s[10:11], s[12:13]
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_add_u32_e32 v34, s91, v93
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_add_u32_e32 v35, 60, v34
	.loc	1 593 26                        ; extend_attention.py:593:26
	s_and_b64 s[78:79], vcc, s[0:1]
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[0:1], s20, v35
	v_add_u32_e32 v35, 56, v34
	v_cmp_gt_i32_e64 s[10:11], s20, v35
	v_add_u32_e32 v35, 52, v34
	v_cmp_gt_i32_e64 s[12:13], s20, v35
	v_add_u32_e32 v35, 48, v34
	v_cmp_gt_i32_e64 s[14:15], s20, v35
	v_add_u32_e32 v35, 44, v34
	v_cmp_gt_i32_e64 s[22:23], s20, v35
	v_add_u32_e32 v35, 40, v34
	v_cmp_gt_i32_e64 s[24:25], s20, v35
	v_add_u32_e32 v35, 36, v34
	v_cmp_gt_i32_e64 s[26:27], s20, v35
	v_add_u32_e32 v35, 32, v34
	v_cmp_gt_i32_e64 s[28:29], s20, v35
	v_add_u32_e32 v35, 28, v34
	v_cmp_gt_i32_e64 s[30:31], s20, v35
	v_add_u32_e32 v35, 24, v34
	v_cmp_gt_i32_e64 s[34:35], s20, v35
	v_add_u32_e32 v35, 20, v34
	v_cmp_gt_i32_e64 s[36:37], s20, v35
	v_add_u32_e32 v35, 16, v34
	v_cmp_gt_i32_e64 s[40:41], s20, v35
	v_add_u32_e32 v35, 12, v34
	v_cmp_gt_i32_e64 s[44:45], s20, v35
	v_add_u32_e32 v35, 8, v34
	v_cmp_gt_i32_e64 s[48:49], s20, v35
	v_add_u32_e32 v35, 4, v34
	v_cmp_gt_i32_e64 s[54:55], s20, v34
	.loc	1 607 16                        ; extend_attention.py:607:16
	v_add_u32_e32 v34, v102, v121
	.loc	1 560 38                        ; extend_attention.py:560:38
	v_cmp_gt_i32_e64 s[52:53], s20, v35
	.loc	1 607 16                        ; extend_attention.py:607:16
	v_cndmask_b32_e64 v34, v154, v34, s[54:55]
	buffer_load_dwordx4 v[36:39], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v122
	v_cndmask_b32_e64 v34, v154, v34, s[52:53]
	buffer_load_dwordx4 v[40:43], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v123
	v_cndmask_b32_e64 v34, v154, v34, s[48:49]
	buffer_load_dwordx4 v[44:47], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v124
	v_cndmask_b32_e64 v34, v154, v34, s[44:45]
	buffer_load_dwordx4 v[48:51], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v125
	v_cndmask_b32_e64 v34, v154, v34, s[40:41]
	buffer_load_dwordx4 v[52:55], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v126
	v_cndmask_b32_e64 v34, v154, v34, s[36:37]
	buffer_load_dwordx4 v[56:59], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v127
	v_cndmask_b32_e64 v34, v154, v34, s[34:35]
	buffer_load_dwordx4 v[60:63], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v128
	v_cndmask_b32_e64 v34, v154, v34, s[30:31]
	buffer_load_dwordx4 v[64:67], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v129
	v_cndmask_b32_e64 v34, v154, v34, s[28:29]
	buffer_load_dwordx4 v[70:73], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v130
	v_cndmask_b32_e64 v34, v154, v34, s[26:27]
	buffer_load_dwordx4 v[74:77], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v131
	v_cndmask_b32_e64 v34, v154, v34, s[24:25]
	buffer_load_dwordx4 v[78:81], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v132
	v_cndmask_b32_e64 v34, v154, v34, s[22:23]
	buffer_load_dwordx4 v[82:85], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v133
	v_cndmask_b32_e64 v34, v154, v34, s[14:15]
	buffer_load_dwordx4 v[86:89], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v134
	v_cndmask_b32_e64 v34, v154, v34, s[12:13]
	buffer_load_dwordx4 v[158:161], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v135
	v_cndmask_b32_e64 v34, v154, v34, s[10:11]
	buffer_load_dwordx4 v[162:165], v34, s[4:7], 0 offen
	v_add_u32_e32 v34, v102, v136
	v_cndmask_b32_e64 v34, v154, v34, s[0:1]
	buffer_load_dwordx4 v[166:169], v34, s[4:7], 0 offen
	s_waitcnt vmcnt(15) lgkmcnt(0)
	; wave barrier
	ds_write_b128 v98, v[36:39]
	s_waitcnt vmcnt(11)
	ds_write_b128 v98, v[52:55] offset:4096
	s_waitcnt vmcnt(7)
	ds_write_b128 v98, v[70:73] offset:8192
	s_waitcnt vmcnt(3)
	ds_write_b128 v98, v[86:89] offset:12288
	ds_write_b128 v99, v[40:43] offset:1024
	ds_write_b128 v99, v[56:59] offset:5120
	ds_write_b128 v99, v[74:77] offset:9216
	s_waitcnt vmcnt(2)
	ds_write_b128 v99, v[158:161] offset:13312
	ds_write_b128 v100, v[44:47] offset:2048
	ds_write_b128 v100, v[60:63] offset:6144
	ds_write_b128 v100, v[78:81] offset:10240
	s_waitcnt vmcnt(1)
	ds_write_b128 v100, v[162:165] offset:14336
	ds_write_b128 v101, v[48:51] offset:3072
	ds_write_b128 v101, v[64:67] offset:7168
	ds_write_b128 v101, v[82:85] offset:11264
	s_waitcnt vmcnt(0)
	ds_write_b128 v101, v[166:169] offset:15360
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 v[34:37], v104
	ds_read_b128 v[38:41], v104 offset:4096
	ds_read_b128 v[42:45], v104 offset:8192
	ds_read_b128 v[46:49], v104 offset:12288
	ds_read_b128 v[50:53], v138
	ds_read_b128 v[54:57], v138 offset:4096
	ds_read_b128 v[58:61], v138 offset:8192
	ds_read_b128 v[62:65], v138 offset:12288
	ds_read_b128 v[70:73], v139
	ds_read_b128 v[74:77], v139 offset:4096
	ds_read_b128 v[78:81], v139 offset:8192
	ds_read_b128 v[82:85], v139 offset:12288
	ds_read_b128 v[86:89], v140
	ds_read_b128 v[158:161], v140 offset:4096
	ds_read_b128 v[162:165], v140 offset:8192
	ds_read_b128 v[166:169], v140 offset:12288
	.loc	1 610 27                        ; extend_attention.py:610:27
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[34:37], v[170:173], 0
	s_mov_b32 s2, 0xff800000
	.loc	1 648 16                        ; extend_attention.py:648:16
	s_mov_b32 s86, s6
	s_mov_b32 s87, s7
	.loc	1 610 27                        ; extend_attention.py:610:27
	v_mfma_f32_16x16x32_bf16 v[38:41], v[38:41], v[170:173], 0
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[50:53], v[174:177], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[42:45], v[42:45], v[170:173], 0
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[54:57], v[174:177], v[38:41]
	v_mfma_f32_16x16x32_bf16 v[46:49], v[46:49], v[170:173], 0
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[70:73], v[178:181], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[42:45], v[58:61], v[174:177], v[42:45]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[74:77], v[178:181], v[38:41]
	v_mfma_f32_16x16x32_bf16 v[46:49], v[62:65], v[174:177], v[46:49]
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[86:89], v[182:185], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[42:45], v[78:81], v[178:181], v[42:45]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[158:161], v[182:185], v[38:41]
	.loc	1 624 18                        ; extend_attention.py:624:18
	s_nop 4
	v_mul_f32_e32 v34, s33, v34
	v_mul_f32_e32 v35, s33, v35
	v_mul_f32_e32 v36, s33, v36
	.loc	1 610 27                        ; extend_attention.py:610:27
	v_mfma_f32_16x16x32_bf16 v[46:49], v[82:85], v[178:181], v[46:49]
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v37, s33, v37
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v34, v155, v34, s[78:79]
	v_cndmask_b32_e64 v35, v155, v35, s[76:77]
	.loc	1 610 27                        ; extend_attention.py:610:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[162:165], v[182:185], v[42:45]
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v38, s33, v38
	v_mul_f32_e32 v39, s33, v39
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v36, v155, v36, s[74:75]
	.loc	1 610 27                        ; extend_attention.py:610:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[166:169], v[182:185], v[46:49]
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v37, v155, v37, s[72:73]
.Ltmp224:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max_f32_e32 v50, v34, v35
.Ltmp225:
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v40, s33, v40
	v_mul_f32_e32 v41, s33, v41
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v38, v155, v38, s[70:71]
	v_cndmask_b32_e64 v39, v155, v39, s[68:69]
.Ltmp226:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max3_f32 v50, v50, v36, v37
.Ltmp227:
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v42, s33, v42
	v_mul_f32_e32 v43, s33, v43
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v40, v155, v40, s[66:67]
	v_cndmask_b32_e64 v41, v155, v41, s[64:65]
.Ltmp228:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max3_f32 v50, v50, v38, v39
.Ltmp229:
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v44, s33, v44
	v_mul_f32_e32 v45, s33, v45
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v42, v155, v42, s[62:63]
	v_cndmask_b32_e64 v43, v155, v43, s[60:61]
.Ltmp230:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max3_f32 v50, v50, v40, v41
.Ltmp231:
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v46, s33, v46
	v_mul_f32_e32 v47, s33, v47
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v44, v155, v44, s[58:59]
	v_cndmask_b32_e64 v45, v155, v45, s[56:57]
.Ltmp232:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max3_f32 v50, v50, v42, v43
.Ltmp233:
	.loc	1 624 18                        ; extend_attention.py:624:18
	v_mul_f32_e32 v48, s33, v48
	v_mul_f32_e32 v49, s33, v49
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v46, v155, v46, s[50:51]
	v_cndmask_b32_e64 v47, v155, v47, s[46:47]
.Ltmp234:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max3_f32 v50, v50, v44, v45
.Ltmp235:
	.loc	1 632 42                        ; extend_attention.py:632:42
	v_cndmask_b32_e64 v48, v155, v48, s[42:43]
	v_cndmask_b32_e64 v49, v155, v49, s[38:39]
.Ltmp236:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max3_f32 v50, v50, v46, v47
	v_max3_f32 v50, v50, v48, v49
.Ltmp237:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:634:33 ]
	v_mov_b32_e32 v51, v50
	s_nop 1
	v_permlane32_swap_b32_e32 v50, v51
.Ltmp238:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max_f32_e32 v51, v51, v51
	v_max_f32_e32 v50, v50, v50
	v_max_f32_e32 v50, v50, v51
.Ltmp239:
	.loc	2 191 40                        ; standard.py:191:40 @[ extend_attention.py:634:33 ]
	v_mov_b32_e32 v51, v50
	s_nop 1
	v_permlane16_swap_b32_e32 v50, v51
.Ltmp240:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ extend_attention.py:634:33 ] ]
	v_max_f32_e32 v51, v51, v51
	v_max_f32_e32 v50, v50, v50
	v_max_f32_e32 v50, v50, v51
.Ltmp241:
	.loc	1 635 70                        ; extend_attention.py:635:70
	v_cmp_neq_f32_e64 s[38:39], s2, v50
	v_mov_b32_e32 v51, 0xe0ad78ec
	v_readlane_b32 s78, v203, 55
	v_cndmask_b32_e64 v50, v51, v50, s[38:39]
	.loc	1 636 48                        ; extend_attention.py:636:48
	v_max_f32_e32 v51, v68, v68
	v_max_f32_e32 v158, v50, v51
	.loc	1 638 38                        ; extend_attention.py:638:38
	v_sub_f32_e32 v50, v68, v158
	.loc	1 638 30 is_stmt 0              ; extend_attention.py:638:30
	v_mul_f32_e32 v51, 0x3fb8aa3b, v50
	v_cmp_gt_f32_e64 s[38:39], s80, v51
	.loc	1 639 28 is_stmt 1              ; extend_attention.py:639:28
	v_sub_f32_e32 v34, v34, v158
	v_sub_f32_e32 v35, v35, v158
	.loc	1 638 30                        ; extend_attention.py:638:30
	v_cndmask_b32_e64 v51, 0, v156, s[38:39]
	v_fmac_f32_e32 v51, 0x3fb8aa3b, v50
	v_exp_f32_e32 v50, v51
	v_cndmask_b32_e64 v51, 0, v157, s[38:39]
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v36, v36, v158
	v_sub_f32_e32 v37, v37, v158
	.loc	1 638 30                        ; extend_attention.py:638:30
	v_ldexp_f32 v90, v50, v51
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v50, v40, v158
	.loc	1 639 23 is_stmt 0              ; extend_attention.py:639:23
	v_mul_f32_e32 v40, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e64 s[38:39], s80, v40
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v38, v38, v158
	v_sub_f32_e32 v39, v39, v158
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v40, 0, v156, s[38:39]
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v40
	v_cndmask_b32_e64 v40, 0, v157, s[38:39]
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v51, v41, v158
	v_sub_f32_e32 v42, v42, v158
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v34, v34, v40
	v_mul_f32_e32 v40, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e64 s[38:39], s80, v40
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v43, v43, v158
	v_sub_f32_e32 v44, v44, v158
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v40, 0, v156, s[38:39]
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v35
	v_exp_f32_e32 v35, v40
	v_cndmask_b32_e64 v40, 0, v157, s[38:39]
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v45, v45, v158
	v_sub_f32_e32 v46, v46, v158
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v35, v35, v40
	v_mul_f32_e32 v40, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e64 s[38:39], s80, v40
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v47, v47, v158
	v_sub_f32_e32 v48, v48, v158
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v40, 0, v156, s[38:39]
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v36
	v_exp_f32_e32 v36, v40
	v_cndmask_b32_e64 v40, 0, v157, s[38:39]
	.loc	1 639 28                        ; extend_attention.py:639:28
	v_sub_f32_e32 v49, v49, v158
	.loc	1 651 54 is_stmt 1              ; extend_attention.py:651:54
	v_pk_mul_f32 v[32:33], v[32:33], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v36, v36, v40
	v_mul_f32_e32 v40, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e64 s[38:39], s80, v40
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[30:31], v[30:31], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[28:29], v[28:29], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v40, 0, v156, s[38:39]
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v37
	v_exp_f32_e32 v37, v40
	v_cndmask_b32_e64 v40, 0, v157, s[38:39]
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[26:27], v[26:27], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[24:25], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v37, v37, v40
	v_mul_f32_e32 v40, 0x3fb8aa3b, v38
	v_cmp_gt_f32_e64 s[38:39], s80, v40
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[22:23], v[22:23], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[20:21], v[20:21], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v40, 0, v156, s[38:39]
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v38
	v_exp_f32_e32 v38, v40
	v_cndmask_b32_e64 v40, 0, v157, s[38:39]
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[18:19], v[18:19], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[16:17], v[16:17], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v40, v38, v40
	v_mul_f32_e32 v38, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[14:15], v[14:15], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v39
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[10:11], v[10:11], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v41, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v50
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[6:7], v[6:7], v[90:91] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], v[90:91] op_sel_hi:[1,0]
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v50
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_pk_mul_f32 v[2:3], v[2:3], v[90:91] op_sel_hi:[1,0]
	v_readlane_b32 s76, v203, 53
	.loc	1 639 23                        ; extend_attention.py:639:23
	v_ldexp_f32 v160, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v51
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	v_readlane_b32 s74, v203, 51
	v_readlane_b32 s72, v203, 49
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v51
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_readlane_b32 s70, v203, 47
	v_readlane_b32 s68, v203, 45
	v_ldexp_f32 v161, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v42
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	v_readlane_b32 s66, v203, 43
	v_readlane_b32 s64, v203, 41
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v42
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_readlane_b32 s79, v203, 56
	v_readlane_b32 s77, v203, 54
	v_ldexp_f32 v162, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v43
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	v_readlane_b32 s75, v203, 52
	v_readlane_b32 s73, v203, 50
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v43
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_readlane_b32 s71, v203, 48
	v_readlane_b32 s69, v203, 46
	v_ldexp_f32 v163, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v44
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	v_readlane_b32 s67, v203, 44
	v_readlane_b32 s65, v203, 42
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v44
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_ldexp_f32 v164, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v45
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	s_nop 1
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v45
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_ldexp_f32 v165, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v46
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	s_nop 1
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v46
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_ldexp_f32 v166, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v47
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	s_nop 1
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v47
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_ldexp_f32 v167, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v48
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	s_nop 1
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v48
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_ldexp_f32 v168, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v49
	v_cmp_gt_f32_e64 s[38:39], s80, v38
	s_nop 1
	v_cndmask_b32_e64 v38, 0, v156, s[38:39]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v49
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v157, s[38:39]
	v_ldexp_f32 v169, v38, v39
.Ltmp242:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:640:47 ] ]
	v_add_f32_e32 v38, v34, v35
	v_add_f32_e32 v38, v36, v38
	v_add_f32_e32 v38, v37, v38
	v_add_f32_e32 v38, v40, v38
	v_add_f32_e32 v38, v41, v38
	v_add_f32_e32 v38, v160, v38
	v_add_f32_e32 v38, v161, v38
	v_add_f32_e32 v38, v162, v38
	v_add_f32_e32 v38, v163, v38
	v_add_f32_e32 v38, v164, v38
	v_add_f32_e32 v38, v165, v38
	v_add_f32_e32 v38, v166, v38
	v_add_f32_e32 v38, v167, v38
	v_add_f32_e32 v38, v168, v38
	v_add_f32_e32 v38, v169, v38
.Ltmp243:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:640:47 ]
	v_mov_b32_e32 v39, v38
	s_nop 1
	v_permlane32_swap_b32_e32 v38, v39
.Ltmp244:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:640:47 ] ]
	v_add_f32_e32 v38, v38, v39
.Ltmp245:
	.loc	2 293 36                        ; standard.py:293:36 @[ extend_attention.py:640:47 ]
	v_mov_b32_e32 v39, v38
	s_nop 1
	v_permlane16_swap_b32_e32 v38, v39
.Ltmp246:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ extend_attention.py:640:47 ] ]
	v_add_f32_e32 v159, v38, v39
.Ltmp247:
	.loc	1 648 16                        ; extend_attention.py:648:16
	v_add_u32_e32 v38, v102, v105
	v_cndmask_b32_e64 v38, v154, v38, s[54:55]
	.loc	1 640 37                        ; extend_attention.py:640:37
	v_fmac_f32_e32 v159, v69, v90
	.loc	1 648 16                        ; extend_attention.py:648:16
	buffer_load_dwordx4 v[66:69], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v106
	v_cndmask_b32_e64 v38, v154, v38, s[52:53]
	buffer_load_dwordx4 v[54:57], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v107
	v_cndmask_b32_e64 v38, v154, v38, s[48:49]
	buffer_load_dwordx4 v[46:49], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v108
	v_cndmask_b32_e64 v38, v154, v38, s[44:45]
	buffer_load_dwordx4 v[42:45], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v109
	v_cndmask_b32_e64 v38, v154, v38, s[40:41]
	buffer_load_dwordx4 v[82:85], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v110
	v_cndmask_b32_e64 v38, v154, v38, s[36:37]
	buffer_load_dwordx4 v[74:77], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v111
	v_cndmask_b32_e64 v38, v154, v38, s[34:35]
	buffer_load_dwordx4 v[62:65], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v112
	v_cndmask_b32_e64 v38, v154, v38, s[30:31]
	buffer_load_dwordx4 v[50:53], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v113
	v_cndmask_b32_e64 v38, v154, v38, s[28:29]
	buffer_load_dwordx4 v[186:189], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v114
	v_cndmask_b32_e64 v38, v154, v38, s[26:27]
	buffer_load_dwordx4 v[86:89], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v115
	v_cndmask_b32_e64 v38, v154, v38, s[24:25]
	buffer_load_dwordx4 v[70:73], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v116
	v_cndmask_b32_e64 v38, v154, v38, s[22:23]
	buffer_load_dwordx4 v[58:61], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v117
	v_cndmask_b32_e64 v38, v154, v38, s[14:15]
	buffer_load_dwordx4 v[190:193], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v118
	v_cndmask_b32_e64 v38, v154, v38, s[12:13]
	buffer_load_dwordx4 v[194:197], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v119
	v_cndmask_b32_e64 v38, v154, v38, s[10:11]
	buffer_load_dwordx4 v[198:201], v38, s[84:87], 0 offen
	v_add_u32_e32 v38, v102, v120
	v_cndmask_b32_e64 v38, v154, v38, s[0:1]
	buffer_load_dwordx4 v[78:81], v38, s[84:87], 0 offen
	.loc	1 650 21                        ; extend_attention.py:650:21
	v_cvt_pk_bf16_f32 v38, v34, v35
	v_cvt_pk_bf16_f32 v39, v36, v37
	v_cvt_pk_bf16_f32 v40, v40, v41
	v_cvt_pk_bf16_f32 v41, v160, v161
	v_cvt_pk_bf16_f32 v34, v162, v163
	v_cvt_pk_bf16_f32 v35, v164, v165
	v_cvt_pk_bf16_f32 v36, v166, v167
	.loc	1 648 16                        ; extend_attention.py:648:16
	s_waitcnt vmcnt(11) lgkmcnt(0)
	; wave barrier
	ds_write2st64_b64 v141, v[66:67], v[82:83] offset1:8
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v141, v[186:187], v[190:191] offset0:16 offset1:24
	ds_write2st64_b64 v142, v[68:69], v[84:85] offset1:8
	ds_write2st64_b64 v142, v[188:189], v[192:193] offset0:16 offset1:24
	ds_write2st64_b64 v143, v[54:55], v[74:75] offset0:2 offset1:10
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v143, v[86:87], v[194:195] offset0:18 offset1:26
	ds_write2st64_b64 v144, v[56:57], v[76:77] offset0:2 offset1:10
	ds_write2st64_b64 v144, v[88:89], v[196:197] offset0:18 offset1:26
	ds_write2st64_b64 v145, v[46:47], v[62:63] offset0:4 offset1:12
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v145, v[70:71], v[198:199] offset0:20 offset1:28
	ds_write2st64_b64 v146, v[48:49], v[64:65] offset0:4 offset1:12
	ds_write2st64_b64 v146, v[72:73], v[200:201] offset0:20 offset1:28
	ds_write2st64_b64 v147, v[42:43], v[50:51] offset0:6 offset1:14
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v147, v[58:59], v[78:79] offset0:22 offset1:30
	ds_write2st64_b64 v148, v[44:45], v[52:53] offset0:6 offset1:14
	ds_write2st64_b64 v148, v[60:61], v[80:81] offset0:22 offset1:30
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b16 v[42:43], v149
	ds_read_b64_tr_b16 v[44:45], v149 offset:4096
	ds_read_b64_tr_b16 v[46:47], v149 offset:8192
	ds_read_b64_tr_b16 v[48:49], v149 offset:12288
	ds_read_b64_tr_b16 v[50:51], v149 offset:128
	ds_read_b64_tr_b16 v[52:53], v149 offset:4224
	ds_read_b64_tr_b16 v[54:55], v149 offset:8320
	ds_read_b64_tr_b16 v[56:57], v149 offset:12416
	ds_read_b64_tr_b16 v[58:59], v150
	ds_read_b64_tr_b16 v[60:61], v150 offset:4096
	ds_read_b64_tr_b16 v[62:63], v150 offset:8192
	ds_read_b64_tr_b16 v[64:65], v150 offset:12288
	ds_read_b64_tr_b16 v[66:67], v150 offset:128
	ds_read_b64_tr_b16 v[68:69], v150 offset:4224
	ds_read_b64_tr_b16 v[70:71], v150 offset:8320
	ds_read_b64_tr_b16 v[72:73], v150 offset:12416
	ds_read_b64_tr_b16 v[74:75], v151
	ds_read_b64_tr_b16 v[76:77], v151 offset:4096
	ds_read_b64_tr_b16 v[78:79], v151 offset:8192
	ds_read_b64_tr_b16 v[80:81], v151 offset:12288
	ds_read_b64_tr_b16 v[82:83], v151 offset:128
	ds_read_b64_tr_b16 v[84:85], v151 offset:4224
	ds_read_b64_tr_b16 v[86:87], v151 offset:8320
	ds_read_b64_tr_b16 v[88:89], v151 offset:12416
	ds_read_b64_tr_b16 v[160:161], v152
	ds_read_b64_tr_b16 v[162:163], v152 offset:4096
	ds_read_b64_tr_b16 v[164:165], v152 offset:8192
	ds_read_b64_tr_b16 v[166:167], v152 offset:12288
	ds_read_b64_tr_b16 v[186:187], v152 offset:128
	ds_read_b64_tr_b16 v[188:189], v152 offset:4224
	ds_read_b64_tr_b16 v[190:191], v152 offset:8320
	ds_read_b64_tr_b16 v[192:193], v152 offset:12416
	.loc	1 651 54                        ; extend_attention.py:651:54
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[42:45], v[38:41], v[30:33]
	.loc	1 650 21                        ; extend_attention.py:650:21
	v_cvt_pk_bf16_f32 v37, v168, v169
	.loc	1 651 54                        ; extend_attention.py:651:54
	v_mfma_f32_16x16x32_bf16 v[26:29], v[58:61], v[38:41], v[26:29]
	v_mfma_f32_16x16x32_bf16 v[22:25], v[74:77], v[38:41], v[22:25]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[18:21], v[160:163], v[38:41], v[18:21]
	v_mfma_f32_16x16x32_bf16 v[14:17], v[50:53], v[38:41], v[14:17]
	v_mfma_f32_16x16x32_bf16 v[10:13], v[66:69], v[38:41], v[10:13]
	v_mov_b32_e32 v69, v159
	v_mov_b32_e32 v68, v158
	v_mfma_f32_16x16x32_bf16 v[6:9], v[82:85], v[38:41], v[6:9]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[186:189], v[38:41], v[2:5]
	v_mfma_f32_16x16x32_bf16 v[30:33], v[46:49], v[34:37], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[26:29], v[62:65], v[34:37], v[26:29]
	v_mfma_f32_16x16x32_bf16 v[22:25], v[78:81], v[34:37], v[22:25]
	v_mfma_f32_16x16x32_bf16 v[18:21], v[164:167], v[34:37], v[18:21]
	v_mfma_f32_16x16x32_bf16 v[14:17], v[54:57], v[34:37], v[14:17]
	v_mfma_f32_16x16x32_bf16 v[10:13], v[70:73], v[34:37], v[10:13]
	v_mfma_f32_16x16x32_bf16 v[6:9], v[86:89], v[34:37], v[6:9]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[190:193], v[34:37], v[2:5]
	s_branch .LBB0_8
.LBB0_11:                               ; %._crit_edge13
	.loc	1 0 54 is_stmt 0                ; extend_attention.py:0:54
	v_readlane_b32 s0, v203, 32
	.loc	1 668 12 is_stmt 1              ; extend_attention.py:668:12
	s_waitcnt lgkmcnt(0)
	; wave barrier
	s_and_b32 s97, s97, 0xffff
	.loc	1 431 60                        ; extend_attention.py:431:60
	v_add_u32_e32 v34, s0, v96
	v_add_u32_e32 v35, s0, v95
	v_add_u32_e32 v36, s0, v94
	v_add_u32_e32 v37, s0, v93
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_div_scale_f32 v39, s[0:1], v69, v69, v30
	v_rcp_f32_e32 v40, v39
	.loc	1 662 21                        ; extend_attention.py:662:21
	v_readlane_b32 s0, v203, 31
	s_mul_i32 s0, s83, s0
	.loc	1 661 10                        ; extend_attention.py:661:10
	v_mul_lo_u32 v38, v37, s82
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v41, -v39, v40, 1.0
	v_fmac_f32_e32 v40, v41, v40
	v_div_scale_f32 v41, vcc, v30, v69, v30
	v_mul_f32_e32 v42, v41, v40
	v_fma_f32 v43, -v39, v42, v41
	v_fmac_f32_e32 v42, v43, v40
	.loc	1 661 10                        ; extend_attention.py:661:10
	v_mul_lo_u32 v37, v36, s82
	.loc	1 662 10                        ; extend_attention.py:662:10
	v_add_u32_e32 v36, s0, v92
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v39, -v39, v42, v41
	v_div_scale_f32 v41, s[0:1], v69, v69, v31
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v40, v42
	v_div_fixup_f32 v30, v39, v69, v30
	s_mov_b32 s99, 0x27000
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v31, v69, v31
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v32
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v31, v39, v69, v31
	s_mov_b32 s98, 0x7ffffffe
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v32, v69, v32
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v33
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v32, v39, v69, v32
	.loc	1 661 10                        ; extend_attention.py:661:10
	v_mul_lo_u32 v35, v35, s82
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v33, v69, v33
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v26
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v33, v39, v69, v33
	.loc	1 661 10                        ; extend_attention.py:661:10
	v_mul_lo_u32 v34, v34, s82
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v26, v69, v26
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v27
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v26, v39, v69, v26
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v27, v69, v27
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v28
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v27, v39, v69, v27
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v28, v69, v28
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v29
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v28, v39, v69, v28
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v29, v69, v29
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v22
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v29, v39, v69, v29
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v22, v69, v22
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v23
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v22, v39, v69, v22
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v23, v69, v23
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v24
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v23, v39, v69, v23
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v24, v69, v24
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v25
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v24, v39, v69, v24
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v25, v69, v25
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v18
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v25, v39, v69, v25
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v18, v69, v18
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v19
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v18, v39, v69, v18
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v19, v69, v19
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v20
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v19, v39, v69, v19
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v20, v69, v20
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v21
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v20, v39, v69, v20
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v21, v69, v21
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v14
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v21, v39, v69, v21
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v14, v69, v14
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v15
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v14, v39, v69, v14
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v15, v69, v15
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v16
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v15, v39, v69, v15
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v16, v69, v16
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v17
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v16, v39, v69, v16
	v_fma_f32 v39, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v39, v43
	v_div_scale_f32 v39, vcc, v17, v69, v17
	v_mul_f32_e32 v40, v39, v43
	v_fma_f32 v42, -v41, v40, v39
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v10
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v39, v39, v43, v40
	v_div_fixup_f32 v17, v39, v69, v17
	v_fma_f32 v39, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v39, v42
	v_div_scale_f32 v39, vcc, v10, v69, v10
	v_mul_f32_e32 v40, v39, v42
	v_fma_f32 v43, -v41, v40, v39
	v_fmac_f32_e32 v40, v43, v42
	v_fma_f32 v39, -v41, v40, v39
	v_div_scale_f32 v41, s[0:1], v69, v69, v11
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v39, v39, v42, v40
	v_div_fixup_f32 v39, v39, v69, v10
	v_fma_f32 v10, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v10, v43
	v_div_scale_f32 v10, vcc, v11, v69, v11
	v_mul_f32_e32 v40, v10, v43
	v_fma_f32 v42, -v41, v40, v10
	v_fmac_f32_e32 v40, v42, v43
	v_fma_f32 v10, -v41, v40, v10
	v_div_scale_f32 v41, s[0:1], v69, v69, v12
	v_rcp_f32_e32 v42, v41
	v_div_fmas_f32 v10, v10, v43, v40
	v_div_fixup_f32 v40, v10, v69, v11
	v_fma_f32 v10, -v41, v42, 1.0
	v_fmac_f32_e32 v42, v10, v42
	v_div_scale_f32 v10, vcc, v12, v69, v12
	v_mul_f32_e32 v11, v10, v42
	v_fma_f32 v43, -v41, v11, v10
	v_fmac_f32_e32 v11, v43, v42
	v_fma_f32 v10, -v41, v11, v10
	v_div_scale_f32 v41, s[0:1], v69, v69, v13
	v_rcp_f32_e32 v43, v41
	v_div_fmas_f32 v10, v10, v42, v11
	v_div_fixup_f32 v42, v10, v69, v12
	v_fma_f32 v10, -v41, v43, 1.0
	v_fmac_f32_e32 v43, v10, v43
	v_div_scale_f32 v10, vcc, v13, v69, v13
	v_mul_f32_e32 v11, v10, v43
	v_fma_f32 v12, -v41, v11, v10
	v_fmac_f32_e32 v11, v12, v43
	v_div_scale_f32 v12, s[0:1], v69, v69, v6
	v_fma_f32 v10, -v41, v11, v10
	v_rcp_f32_e32 v41, v12
	v_div_fmas_f32 v10, v10, v43, v11
	v_div_fixup_f32 v13, v10, v69, v13
	.loc	1 668 12 is_stmt 0              ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v13, v42, v13
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v10, -v12, v41, 1.0
	v_fmac_f32_e32 v41, v10, v41
	v_div_scale_f32 v10, vcc, v6, v69, v6
	v_mul_f32_e32 v11, v10, v41
	v_fma_f32 v43, -v12, v11, v10
	v_fmac_f32_e32 v11, v43, v41
	v_fma_f32 v10, -v12, v11, v10
	v_div_scale_f32 v12, s[0:1], v69, v69, v7
	v_rcp_f32_e32 v43, v12
	v_div_fmas_f32 v10, v10, v41, v11
	v_div_fixup_f32 v41, v10, v69, v6
	v_fma_f32 v6, -v12, v43, 1.0
	v_fmac_f32_e32 v43, v6, v43
	v_div_scale_f32 v6, vcc, v7, v69, v7
	v_mul_f32_e32 v10, v6, v43
	v_fma_f32 v11, -v12, v10, v6
	v_fmac_f32_e32 v10, v11, v43
	v_div_scale_f32 v11, s[0:1], v69, v69, v8
	v_fma_f32 v6, -v12, v10, v6
	v_rcp_f32_e32 v12, v11
	v_div_fmas_f32 v6, v6, v43, v10
	v_div_fixup_f32 v43, v6, v69, v7
	v_fma_f32 v6, -v11, v12, 1.0
	v_fmac_f32_e32 v12, v6, v12
	v_div_scale_f32 v6, vcc, v8, v69, v8
	v_mul_f32_e32 v7, v6, v12
	v_fma_f32 v10, -v11, v7, v6
	v_fmac_f32_e32 v7, v10, v12
	v_div_scale_f32 v10, s[0:1], v69, v69, v9
	v_fma_f32 v6, -v11, v7, v6
	v_rcp_f32_e32 v11, v10
	v_div_fmas_f32 v6, v6, v12, v7
	v_div_fixup_f32 v44, v6, v69, v8
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v12, v39, v40
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v6, -v10, v11, 1.0
	v_fmac_f32_e32 v11, v6, v11
	v_div_scale_f32 v6, vcc, v9, v69, v9
	v_mul_f32_e32 v7, v6, v11
	v_fma_f32 v8, -v10, v7, v6
	v_fmac_f32_e32 v7, v8, v11
	v_div_scale_f32 v8, s[0:1], v69, v69, v2
	v_fma_f32 v6, -v10, v7, v6
	v_rcp_f32_e32 v10, v8
	v_div_fmas_f32 v6, v6, v11, v7
	v_div_fixup_f32 v45, v6, v69, v9
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v11, v16, v17
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v6, -v8, v10, 1.0
	v_fmac_f32_e32 v10, v6, v10
	v_div_scale_f32 v6, vcc, v2, v69, v2
	v_mul_f32_e32 v7, v6, v10
	v_fma_f32 v9, -v8, v7, v6
	v_fmac_f32_e32 v7, v9, v10
	v_fma_f32 v6, -v8, v7, v6
	v_div_scale_f32 v8, s[0:1], v69, v69, v3
	v_rcp_f32_e32 v9, v8
	v_div_fmas_f32 v6, v6, v10, v7
	v_div_fixup_f32 v46, v6, v69, v2
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v10, v14, v15
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v2, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v2, v9
	v_div_scale_f32 v2, vcc, v3, v69, v3
	v_mul_f32_e32 v6, v2, v9
	v_fma_f32 v7, -v8, v6, v2
	v_fmac_f32_e32 v6, v7, v9
	v_div_scale_f32 v7, s[0:1], v69, v69, v4
	v_fma_f32 v2, -v8, v6, v2
	v_rcp_f32_e32 v8, v7
	v_div_fmas_f32 v2, v2, v9, v6
	v_div_fixup_f32 v47, v2, v69, v3
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v9, v20, v21
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v2, -v7, v8, 1.0
	v_fmac_f32_e32 v8, v2, v8
	v_div_scale_f32 v2, vcc, v4, v69, v4
	v_mul_f32_e32 v3, v2, v8
	v_fma_f32 v6, -v7, v3, v2
	v_fmac_f32_e32 v3, v6, v8
	v_div_scale_f32 v6, s[0:1], v69, v69, v5
	v_fma_f32 v2, -v7, v3, v2
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v2, v2, v8, v3
	v_div_fixup_f32 v48, v2, v69, v4
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v8, v18, v19
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v2, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v2, v7
	v_div_scale_f32 v2, vcc, v5, v69, v5
	v_mul_f32_e32 v3, v2, v7
	v_fma_f32 v4, -v6, v3, v2
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_lshlrev_b32_e32 v18, 5, v0
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fmac_f32_e32 v3, v4, v7
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_and_b32_e32 v18, 0x60, v18
	v_and_b32_e32 v19, 12, v0
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_fma_f32 v2, -v6, v3, v2
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_lshlrev_b32_e32 v20, 1, v19
	v_lshl_or_b32 v1, v1, 6, v18
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_div_fmas_f32 v2, v2, v7, v3
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_or_b32_e32 v18, v1, v20
	.loc	1 668 19                        ; extend_attention.py:668:19
	v_div_fixup_f32 v49, v2, v69, v5
	.loc	1 668 12                        ; extend_attention.py:668:12
	v_cvt_pk_bf16_f32 v2, v30, v31
	v_cvt_pk_bf16_f32 v3, v32, v33
	v_add_u32_e32 v21, 0, v18
	v_cvt_pk_bf16_f32 v4, v26, v27
	v_cvt_pk_bf16_f32 v5, v28, v29
	ds_write_b64 v21, v[2:3]
	v_xad_u32 v2, v18, 64, 0
	v_cvt_pk_bf16_f32 v6, v22, v23
	v_cvt_pk_bf16_f32 v7, v24, v25
	ds_write_b64 v2, v[4:5] offset:128
	v_xad_u32 v2, v18, 8, 0
	s_movk_i32 s0, 0x48
	ds_write_b64 v2, v[6:7] offset:256
	v_bitop3_b32 v2, v1, s0, v20 bitop3:0x36
	v_add_u32_e32 v2, 0, v2
	ds_write_b64 v2, v[8:9] offset:384
	v_xad_u32 v2, v18, 16, 0
	s_movk_i32 s0, 0x50
	ds_write_b64 v2, v[10:11] offset:512
	v_bitop3_b32 v2, v1, s0, v20 bitop3:0x36
	s_movk_i32 s0, 0x58
	v_add_u32_e32 v2, 0, v2
	v_bitop3_b32 v1, v1, s0, v20 bitop3:0x36
	v_cvt_pk_bf16_f32 v14, v41, v43
	v_cvt_pk_bf16_f32 v15, v44, v45
	v_cvt_pk_bf16_f32 v16, v46, v47
	v_cvt_pk_bf16_f32 v17, v48, v49
	ds_write_b64 v2, v[12:13] offset:640
	v_xad_u32 v2, v18, 24, 0
	v_add_u32_e32 v1, 0, v1
	v_lshlrev_b32_e32 v3, 11, v0
	v_bfe_i32 v0, v0, 1, 1
	ds_write_b64 v2, v[14:15] offset:768
	ds_write_b64 v1, v[16:17] offset:896
	v_lshlrev_b32_e32 v1, 6, v19
	v_and_b32_e32 v2, 0x78, v91
	v_and_b32_e32 v0, 0xc0, v0
	v_bitop3_b32 v0, v1, v0, v2 bitop3:0x36
	s_movk_i32 s0, 0x800
	v_and_or_b32 v0, v3, s0, v0
	v_add_u32_e32 v1, 0, v0
	; wave barrier
	ds_read2st64_b64 v[2:5], v1 offset1:2
	v_xad_u32 v1, v0, 8, 0
	ds_read2st64_b64 v[6:9], v1 offset1:2
	v_xad_u32 v1, v0, 16, 0
	v_xad_u32 v0, v0, 24, 0
	v_readlane_b32 s0, v203, 33
	ds_read2st64_b64 v[10:13], v1 offset1:2
	ds_read2st64_b64 v[14:17], v0 offset1:2
	v_add_lshl_u32 v0, v36, v38, 1
	v_bfrev_b32_e32 v1, 1
	v_readlane_b32 s1, v203, 34
	s_nop 1
	v_cndmask_b32_e64 v0, v1, v0, s[0:1]
	v_readlane_b32 s0, v203, 35
	s_waitcnt lgkmcnt(3)
	buffer_store_dwordx4 v[2:5], v0, s[96:99], 0 offen
	v_add_lshl_u32 v0, v36, v37, 1
	v_readlane_b32 s1, v203, 36
	s_nop 1
	v_cndmask_b32_e64 v0, v1, v0, s[0:1]
	v_readlane_b32 s0, v203, 37
	s_waitcnt lgkmcnt(2)
	buffer_store_dwordx4 v[6:9], v0, s[96:99], 0 offen
	v_add_lshl_u32 v0, v36, v35, 1
	v_readlane_b32 s1, v203, 38
	s_nop 1
	v_cndmask_b32_e64 v0, v1, v0, s[0:1]
	v_readlane_b32 s0, v203, 39
	s_waitcnt lgkmcnt(1)
	buffer_store_dwordx4 v[10:13], v0, s[96:99], 0 offen
	v_add_lshl_u32 v0, v36, v34, 1
	v_readlane_b32 s1, v203, 40
	s_nop 1
	v_cndmask_b32_e64 v0, v1, v0, s[0:1]
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx4 v[14:17], v0, s[96:99], 0 offen
	.loc	1 665 4 is_stmt 1               ; extend_attention.py:665:4
	s_endpgm
.Ltmp248:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 176
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
		.amdhsa_next_free_sgpr 102
		.amdhsa_accum_offset 204
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
	.size	qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950, .Lfunc_end0-qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.num_vgpr, 204
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.num_agpr, 0
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.numbered_sgpr, 102
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.num_named_barrier, 0
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.private_seg_size, 0
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.uses_vcc, 1
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.uses_flat_scratch, 0
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.has_dyn_sized_stack, 0
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.has_recursion, 0
	.set qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 20468
; TotalNumSgprs: 106
; NumVgprs: 204
; NumAgprs: 0
; TotalNumVgprs: 204
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 13
; VGPRBlocks: 32
; NumSGPRsForWavesPerEU: 106
; NumVGPRsForWavesPerEU: 257
; AccumOffset: 204
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 50
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
	.byte	1                               ; Abbrev [1] 0xb:0x112 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0xec DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	485                             ; DW_AT_call_line
	.byte	38                              ; DW_AT_call_column
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
	.short	485                             ; DW_AT_call_line
	.byte	31                              ; DW_AT_call_column
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
	.short	528                             ; DW_AT_call_line
	.byte	33                              ; DW_AT_call_column
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
	.short	534                             ; DW_AT_call_line
	.byte	47                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x9c:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xaa:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges8                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	597                             ; DW_AT_call_line
	.byte	38                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0xb7:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges9                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xc4:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges10                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	597                             ; DW_AT_call_line
	.byte	31                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0xd1:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges11                ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xde:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges12                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	634                             ; DW_AT_call_line
	.byte	33                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0xeb:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges13                ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0xf8:0x23 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp242                        ; DW_AT_low_pc
	.long	.Ltmp247-.Ltmp242               ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	640                             ; DW_AT_call_line
	.byte	47                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x10d:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges14                ; DW_AT_ranges
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
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
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
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
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
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp91-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp94-.Lfunc_begin0
	.quad	.Ltmp95-.Lfunc_begin0
	.quad	.Ltmp96-.Lfunc_begin0
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp98-.Lfunc_begin0
	.quad	.Ltmp99-.Lfunc_begin0
	.quad	.Ltmp100-.Lfunc_begin0
	.quad	.Ltmp101-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp108-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges5:
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp94-.Lfunc_begin0
	.quad	.Ltmp95-.Lfunc_begin0
	.quad	.Ltmp96-.Lfunc_begin0
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp98-.Lfunc_begin0
	.quad	.Ltmp99-.Lfunc_begin0
	.quad	.Ltmp100-.Lfunc_begin0
	.quad	.Ltmp101-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp104-.Lfunc_begin0
	.quad	.Ltmp105-.Lfunc_begin0
	.quad	.Ltmp106-.Lfunc_begin0
	.quad	.Ltmp107-.Lfunc_begin0
	.quad	.Ltmp108-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges6:
	.quad	.Ltmp109-.Lfunc_begin0
	.quad	.Ltmp110-.Lfunc_begin0
	.quad	.Ltmp111-.Lfunc_begin0
	.quad	.Ltmp112-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.quad	.Ltmp114-.Lfunc_begin0
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp116-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.quad	.Ltmp118-.Lfunc_begin0
	.quad	.Ltmp119-.Lfunc_begin0
	.quad	.Ltmp120-.Lfunc_begin0
	.quad	.Ltmp121-.Lfunc_begin0
	.quad	.Ltmp122-.Lfunc_begin0
	.quad	.Ltmp123-.Lfunc_begin0
	.quad	.Ltmp124-.Lfunc_begin0
	.quad	.Ltmp125-.Lfunc_begin0
	.quad	.Ltmp127-.Lfunc_begin0
	.quad	.Ltmp128-.Lfunc_begin0
	.quad	.Ltmp129-.Lfunc_begin0
	.quad	.Ltmp130-.Lfunc_begin0
	.quad	.Ltmp131-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp109-.Lfunc_begin0
	.quad	.Ltmp110-.Lfunc_begin0
	.quad	.Ltmp111-.Lfunc_begin0
	.quad	.Ltmp112-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.quad	.Ltmp114-.Lfunc_begin0
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp116-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.quad	.Ltmp118-.Lfunc_begin0
	.quad	.Ltmp119-.Lfunc_begin0
	.quad	.Ltmp120-.Lfunc_begin0
	.quad	.Ltmp121-.Lfunc_begin0
	.quad	.Ltmp122-.Lfunc_begin0
	.quad	.Ltmp125-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.quad	.Ltmp130-.Lfunc_begin0
	.quad	.Ltmp131-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp132-.Lfunc_begin0
	.quad	.Ltmp133-.Lfunc_begin0
	.quad	.Ltmp134-.Lfunc_begin0
	.quad	.Ltmp135-.Lfunc_begin0
	.quad	.Ltmp136-.Lfunc_begin0
	.quad	.Ltmp137-.Lfunc_begin0
	.quad	.Ltmp138-.Lfunc_begin0
	.quad	.Ltmp139-.Lfunc_begin0
	.quad	.Ltmp140-.Lfunc_begin0
	.quad	.Ltmp141-.Lfunc_begin0
	.quad	.Ltmp142-.Lfunc_begin0
	.quad	.Ltmp143-.Lfunc_begin0
	.quad	.Ltmp144-.Lfunc_begin0
	.quad	.Ltmp145-.Lfunc_begin0
	.quad	.Ltmp146-.Lfunc_begin0
	.quad	.Ltmp147-.Lfunc_begin0
	.quad	.Ltmp148-.Lfunc_begin0
	.quad	.Ltmp158-.Lfunc_begin0
	.quad	.Ltmp159-.Lfunc_begin0
	.quad	.Ltmp164-.Lfunc_begin0
	.quad	.Ltmp165-.Lfunc_begin0
	.quad	.Ltmp212-.Lfunc_begin0
	.quad	.Ltmp213-.Lfunc_begin0
	.quad	.Ltmp215-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges9:
	.quad	.Ltmp132-.Lfunc_begin0
	.quad	.Ltmp133-.Lfunc_begin0
	.quad	.Ltmp134-.Lfunc_begin0
	.quad	.Ltmp135-.Lfunc_begin0
	.quad	.Ltmp136-.Lfunc_begin0
	.quad	.Ltmp137-.Lfunc_begin0
	.quad	.Ltmp138-.Lfunc_begin0
	.quad	.Ltmp139-.Lfunc_begin0
	.quad	.Ltmp144-.Lfunc_begin0
	.quad	.Ltmp145-.Lfunc_begin0
	.quad	.Ltmp146-.Lfunc_begin0
	.quad	.Ltmp147-.Lfunc_begin0
	.quad	.Ltmp149-.Lfunc_begin0
	.quad	.Ltmp150-.Lfunc_begin0
	.quad	.Ltmp151-.Lfunc_begin0
	.quad	.Ltmp152-.Lfunc_begin0
	.quad	.Ltmp153-.Lfunc_begin0
	.quad	.Ltmp154-.Lfunc_begin0
	.quad	.Ltmp155-.Lfunc_begin0
	.quad	.Ltmp156-.Lfunc_begin0
	.quad	.Ltmp157-.Lfunc_begin0
	.quad	.Ltmp158-.Lfunc_begin0
	.quad	.Ltmp159-.Lfunc_begin0
	.quad	.Ltmp160-.Lfunc_begin0
	.quad	.Ltmp161-.Lfunc_begin0
	.quad	.Ltmp162-.Lfunc_begin0
	.quad	.Ltmp163-.Lfunc_begin0
	.quad	.Ltmp164-.Lfunc_begin0
	.quad	.Ltmp165-.Lfunc_begin0
	.quad	.Ltmp166-.Lfunc_begin0
	.quad	.Ltmp167-.Lfunc_begin0
	.quad	.Ltmp168-.Lfunc_begin0
	.quad	.Ltmp169-.Lfunc_begin0
	.quad	.Ltmp170-.Lfunc_begin0
	.quad	.Ltmp171-.Lfunc_begin0
	.quad	.Ltmp172-.Lfunc_begin0
	.quad	.Ltmp173-.Lfunc_begin0
	.quad	.Ltmp174-.Lfunc_begin0
	.quad	.Ltmp175-.Lfunc_begin0
	.quad	.Ltmp176-.Lfunc_begin0
	.quad	.Ltmp177-.Lfunc_begin0
	.quad	.Ltmp178-.Lfunc_begin0
	.quad	.Ltmp179-.Lfunc_begin0
	.quad	.Ltmp180-.Lfunc_begin0
	.quad	.Ltmp181-.Lfunc_begin0
	.quad	.Ltmp182-.Lfunc_begin0
	.quad	.Ltmp183-.Lfunc_begin0
	.quad	.Ltmp184-.Lfunc_begin0
	.quad	.Ltmp185-.Lfunc_begin0
	.quad	.Ltmp186-.Lfunc_begin0
	.quad	.Ltmp187-.Lfunc_begin0
	.quad	.Ltmp188-.Lfunc_begin0
	.quad	.Ltmp189-.Lfunc_begin0
	.quad	.Ltmp190-.Lfunc_begin0
	.quad	.Ltmp191-.Lfunc_begin0
	.quad	.Ltmp192-.Lfunc_begin0
	.quad	.Ltmp193-.Lfunc_begin0
	.quad	.Ltmp194-.Lfunc_begin0
	.quad	.Ltmp195-.Lfunc_begin0
	.quad	.Ltmp196-.Lfunc_begin0
	.quad	.Ltmp197-.Lfunc_begin0
	.quad	.Ltmp198-.Lfunc_begin0
	.quad	.Ltmp199-.Lfunc_begin0
	.quad	.Ltmp200-.Lfunc_begin0
	.quad	.Ltmp201-.Lfunc_begin0
	.quad	.Ltmp202-.Lfunc_begin0
	.quad	.Ltmp203-.Lfunc_begin0
	.quad	.Ltmp204-.Lfunc_begin0
	.quad	.Ltmp205-.Lfunc_begin0
	.quad	.Ltmp206-.Lfunc_begin0
	.quad	.Ltmp207-.Lfunc_begin0
	.quad	.Ltmp208-.Lfunc_begin0
	.quad	.Ltmp209-.Lfunc_begin0
	.quad	.Ltmp210-.Lfunc_begin0
	.quad	.Ltmp211-.Lfunc_begin0
	.quad	.Ltmp212-.Lfunc_begin0
	.quad	.Ltmp213-.Lfunc_begin0
	.quad	.Ltmp214-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges10:
	.quad	.Ltmp147-.Lfunc_begin0
	.quad	.Ltmp148-.Lfunc_begin0
	.quad	.Ltmp158-.Lfunc_begin0
	.quad	.Ltmp159-.Lfunc_begin0
	.quad	.Ltmp164-.Lfunc_begin0
	.quad	.Ltmp165-.Lfunc_begin0
	.quad	.Ltmp212-.Lfunc_begin0
	.quad	.Ltmp213-.Lfunc_begin0
	.quad	.Ltmp215-.Lfunc_begin0
	.quad	.Ltmp223-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges11:
	.quad	.Ltmp216-.Lfunc_begin0
	.quad	.Ltmp217-.Lfunc_begin0
	.quad	.Ltmp218-.Lfunc_begin0
	.quad	.Ltmp219-.Lfunc_begin0
	.quad	.Ltmp220-.Lfunc_begin0
	.quad	.Ltmp221-.Lfunc_begin0
	.quad	.Ltmp222-.Lfunc_begin0
	.quad	.Ltmp223-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges12:
	.quad	.Ltmp224-.Lfunc_begin0
	.quad	.Ltmp225-.Lfunc_begin0
	.quad	.Ltmp226-.Lfunc_begin0
	.quad	.Ltmp227-.Lfunc_begin0
	.quad	.Ltmp228-.Lfunc_begin0
	.quad	.Ltmp229-.Lfunc_begin0
	.quad	.Ltmp230-.Lfunc_begin0
	.quad	.Ltmp231-.Lfunc_begin0
	.quad	.Ltmp232-.Lfunc_begin0
	.quad	.Ltmp233-.Lfunc_begin0
	.quad	.Ltmp234-.Lfunc_begin0
	.quad	.Ltmp235-.Lfunc_begin0
	.quad	.Ltmp236-.Lfunc_begin0
	.quad	.Ltmp241-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges13:
	.quad	.Ltmp224-.Lfunc_begin0
	.quad	.Ltmp225-.Lfunc_begin0
	.quad	.Ltmp226-.Lfunc_begin0
	.quad	.Ltmp227-.Lfunc_begin0
	.quad	.Ltmp228-.Lfunc_begin0
	.quad	.Ltmp229-.Lfunc_begin0
	.quad	.Ltmp230-.Lfunc_begin0
	.quad	.Ltmp231-.Lfunc_begin0
	.quad	.Ltmp232-.Lfunc_begin0
	.quad	.Ltmp233-.Lfunc_begin0
	.quad	.Ltmp234-.Lfunc_begin0
	.quad	.Ltmp235-.Lfunc_begin0
	.quad	.Ltmp236-.Lfunc_begin0
	.quad	.Ltmp237-.Lfunc_begin0
	.quad	.Ltmp238-.Lfunc_begin0
	.quad	.Ltmp239-.Lfunc_begin0
	.quad	.Ltmp240-.Lfunc_begin0
	.quad	.Ltmp241-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges14:
	.quad	.Ltmp242-.Lfunc_begin0
	.quad	.Ltmp243-.Lfunc_begin0
	.quad	.Ltmp244-.Lfunc_begin0
	.quad	.Ltmp245-.Lfunc_begin0
	.quad	.Ltmp246-.Lfunc_begin0
	.quad	.Ltmp247-.Lfunc_begin0
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
	.asciz	"qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950"
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
      - .address_space:  global
        .offset:         72
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
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
      - .offset:         136
        .size:           4
        .value_kind:     by_value
      - .offset:         140
        .size:           4
        .value_kind:     by_value
      - .offset:         144
        .size:           4
        .value_kind:     by_value
      - .offset:         148
        .size:           4
        .value_kind:     by_value
      - .offset:         152
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         160
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         168
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 176
    .max_flat_workgroup_size: 64
    .name:           qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     106
    .sgpr_spill_count: 70
    .symbol:         qwen36_extend_attention_m16n64_wave1_sgpr2_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     204
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
