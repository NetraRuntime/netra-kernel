	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950              ; -- Begin function qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950
	.p2align	8
	.type	qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950,@function
qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950:                     ; @qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.1:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/fla" "chunk_o.py"
	.loc	1 30 0 prologue_end             ; chunk_o.py:30:0
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
	s_mov_b64 s[36:37], s[6:7]
.Ltmp1:
	.loc	1 52 33 is_stmt 1               ; chunk_o.py:52:33
	s_ashr_i32 s6, s18, 31
	s_lshr_b32 s6, s6, 27
	s_mov_b64 s[28:29], s[2:3]
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_add_i32 s6, s18, s6
	s_andn2_b32 s6, s6, 31
	s_sub_i32 s52, s18, s6
	.loc	1 56 49                         ; chunk_o.py:56:49
	s_lshl_b32 s6, s17, 1
	s_mov_b64 s[40:41], s[10:11]
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_readfirstlane_b32 s10, v0
	.loc	1 56 27                         ; chunk_o.py:56:27
	s_ashr_i32 s7, s6, 31
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_and_b32 s42, s10, 0xc0
	.loc	1 56 27                         ; chunk_o.py:56:27
	s_lshl_b64 s[6:7], s[6:7], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	s_load_dwordx2 s[6:7], s[2:3], 0x0
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_and_b32_e32 v58, 31, v0
	v_and_b32_e32 v14, 63, v0
	v_or_b32_e32 v57, s42, v14
	v_lshrrev_b32_e32 v1, 4, v57
	.loc	1 59 27                         ; chunk_o.py:59:27
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s3, s6, 31
	s_mov_b32 s2, s6
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s2, s14, s2
	s_addc_u32 s3, s15, s3
	s_load_dwordx2 s[38:39], s[2:3], 0x0
	.loc	1 70 29                         ; chunk_o.py:70:29
	s_bfe_u32 s2, s52, 0x10007
	s_add_i32 s2, s52, s2
	s_bfe_i32 s2, s2, 0x80000
	s_sext_i32_i16 s2, s2
	.loc	1 70 41 is_stmt 0               ; chunk_o.py:70:41
	s_lshl_b32 s2, s2, 6
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s3, s38, 11
	s_and_b32 s2, s2, 0xffffff80
	s_add_i32 s3, s3, s2
	.loc	1 72 27 is_stmt 1               ; chunk_o.py:72:27
	s_lshl_b32 s2, s38, 12
	s_lshl_b32 s6, s52, 7
	s_add_i32 s2, s2, s6
	.loc	1 74 45                         ; chunk_o.py:74:45
	s_lshl_b32 s6, s17, 19
	s_lshl_b32 s11, s52, 14
	.loc	1 90 22                         ; chunk_o.py:90:22
	s_and_b32 s49, s10, 0x80
	.loc	1 74 45                         ; chunk_o.py:74:45
	s_add_i32 s17, s11, s6
	.loc	1 90 22                         ; chunk_o.py:90:22
	s_lshr_b32 s6, s49, 2
	.loc	1 87 38                         ; chunk_o.py:87:38
	s_lshl_b32 s33, s16, 6
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v54, s6, v58
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_lshl_b32 s6, s7, 18
	s_add_i32 s48, s6, s33
	.loc	1 62 18                         ; chunk_o.py:62:18
	s_sub_i32 s34, s39, s38
	.loc	1 81 43                         ; chunk_o.py:81:43
	s_lshl_b32 s39, s7, 6
	.loc	1 90 22                         ; chunk_o.py:90:22
	s_and_b32 s50, s10, 64
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_add_i32 s48, s48, s2
	.loc	1 90 22                         ; chunk_o.py:90:22
	s_lshl_b32 s2, s7, 17
	.loc	1 81 68                         ; chunk_o.py:81:68
	s_ashr_i32 s35, s34, 31
	s_ashr_i32 s51, s39, 31
	.loc	1 87 63                         ; chunk_o.py:87:63
	s_ashr_i32 s46, s33, 31
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v17, 48, v1
	s_lshr_b32 s47, s50, 1
	v_lshrrev_b32_e32 v59, 3, v57
	s_add_i32 s43, s2, s3
	v_or_b32_e32 v15, 16, v1
	v_or_b32_e32 v16, 32, v1
	v_or_b32_e32 v60, 32, v59
	v_or_b32_e32 v8, s39, v17
	v_mov_b32_e32 v9, s51
	s_cmp_gt_i32 s39, -1
	v_or_b32_e32 v2, s39, v1
	v_mov_b32_e32 v3, s51
	v_or_b32_e32 v4, s39, v15
	v_mov_b32_e32 v5, s51
	v_or_b32_e32 v6, s39, v16
	v_mov_b32_e32 v7, s51
	v_or_b32_e32 v52, s39, v54
	v_mov_b32_e32 v53, s51
	v_or_b32_e32 v10, s39, v59
	v_mov_b32_e32 v11, s51
	v_or_b32_e32 v12, s39, v60
	v_mov_b32_e32 v13, s51
	s_cselect_b64 s[44:45], -1, 0
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[8:9]
	v_cmp_gt_i64_e32 vcc, s[34:35], v[2:3]
	v_cmp_gt_i64_e64 s[2:3], s[34:35], v[4:5]
	v_cmp_gt_i64_e64 s[6:7], s[34:35], v[6:7]
	v_cmp_gt_i64_e64 s[14:15], s[34:35], v[52:53]
	v_cmp_gt_i64_e64 s[24:25], s[34:35], v[10:11]
	v_cmp_gt_i64_e64 s[18:19], s[34:35], v[12:13]
	s_and_b64 s[22:23], s[44:45], s[10:11]
	.loc	1 94 22                         ; chunk_o.py:94:22
	s_lshl_b32 s10, s16, 13
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_and_b32_e32 v18, 15, v0
	s_and_b64 s[20:21], s[44:45], vcc
	s_and_b64 s[2:3], s[44:45], s[2:3]
	s_and_b64 s[6:7], s[44:45], s[6:7]
	s_and_b64 vcc, s[44:45], s[14:15]
	s_and_b64 s[24:25], s[44:45], s[24:25]
	s_and_b64 s[26:27], s[44:45], s[18:19]
	s_and_b32 s29, s29, 0xffff
	.loc	1 92 22                         ; chunk_o.py:92:22
	s_and_b32 s5, s5, 0xffff
	.loc	1 94 22                         ; chunk_o.py:94:22
	s_add_i32 s10, s10, s17
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v19, 3, v18
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_or_b32_e32 v2, s33, v1
	v_mov_b32_e32 v3, s46
	v_lshlrev_b32_e32 v4, 7, v1
	v_lshlrev_b32_e32 v5, 7, v15
	v_lshlrev_b32_e32 v6, 7, v16
	v_lshlrev_b32_e32 v7, 7, v17
	s_cmp_gt_i32 s33, -1
	s_mov_b64 s[18:19], 0x80
	v_or3_b32 v4, s10, v4, v19
	v_or3_b32 v5, s10, v5, v19
	v_or3_b32 v6, s10, v6, v19
	v_or3_b32 v7, s10, v7, v19
	s_cselect_b64 s[16:17], -1, 0
	v_cmp_gt_i64_e64 s[10:11], s[18:19], v[2:3]
	s_mov_b32 s31, 0x27000
	s_mov_b32 s30, 0x7ffffffe
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bfrev_b32_e32 v53, 1
	.loc	1 94 22                         ; chunk_o.py:94:22
	s_and_b64 s[14:15], s[16:17], s[10:11]
	v_lshlrev_b32_e32 v2, 1, v4
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s30
	s_mov_b32 s11, s31
	v_cndmask_b32_e64 v2, v53, v2, s[14:15]
	buffer_load_dwordx4 v[10:13], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v5
	v_cndmask_b32_e64 v2, v53, v2, s[14:15]
	buffer_load_dwordx4 v[20:23], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v6
	v_cndmask_b32_e64 v2, v53, v2, s[14:15]
	buffer_load_dwordx4 v[24:27], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v7
	v_cndmask_b32_e64 v2, v53, v2, s[14:15]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v1, 11, v1
	v_or_b32_e32 v5, s43, v19
	.loc	1 94 22                         ; chunk_o.py:94:22
	buffer_load_dwordx4 v[28:31], v2, s[8:11], 0 offen
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v2, 11, v15
	v_add_lshl_u32 v1, v5, v1, 1
	v_lshlrev_b32_e32 v3, 11, v16
	v_cndmask_b32_e64 v6, v53, v1, s[20:21]
	v_add_lshl_u32 v1, v5, v2, 1
	v_lshlrev_b32_e32 v4, 11, v17
	v_cndmask_b32_e64 v2, v53, v1, s[2:3]
	v_add_lshl_u32 v1, v5, v3, 1
	v_cndmask_b32_e64 v3, v53, v1, s[6:7]
	v_add_lshl_u32 v1, v5, v4, 1
	v_cndmask_b32_e64 v4, v53, v1, s[22:23]
	.loc	1 92 22                         ; chunk_o.py:92:22
	s_mov_b32 s6, s30
	s_mov_b32 s7, s31
	.loc	1 90 22                         ; chunk_o.py:90:22
	buffer_load_dwordx4 v[32:35], v6, s[28:31], 0 offen
	buffer_load_dwordx4 v[44:47], v4, s[28:31], 0 offen
	buffer_load_dwordx4 v[36:39], v2, s[28:31], 0 offen
	buffer_load_dwordx4 v[40:43], v3, s[28:31], 0 offen
	.loc	1 92 22                         ; chunk_o.py:92:22
	buffer_load_dwordx4 v[48:51], v6, s[4:7], 0 offen
	buffer_load_dwordx4 v[64:67], v2, s[4:7], 0 offen
	buffer_load_dwordx4 v[68:71], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[72:75], v4, s[4:7], 0 offen
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_mov_b32_e32 v2, 0xe0
	v_bitop3_b32 v2, s42, v2, v14 bitop3:0xc8
	v_and_b32_e32 v4, 14, v0
	v_lshlrev_b32_e32 v3, 4, v2
	v_lshlrev_b32_e32 v6, 3, v4
	v_lshrrev_b32_e32 v2, 1, v2
	v_and_b32_e32 v7, 1, v0
	v_and_b32_e32 v62, 16, v0
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v1, 0xf0
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_lshlrev_b32_e32 v8, 9, v62
	v_bitop3_b32 v2, v3, v2, v6 bitop3:0x36
	v_lshl_add_u32 v3, v7, 12, 0
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v5, s42, v1, v14 bitop3:0xc8
	v_and_b32_e32 v1, 32, v0
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_add3_u32 v2, v3, v8, v2
	v_lshlrev_b32_e32 v3, 13, v7
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v61, 3, v0
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_lshlrev_b32_e32 v6, 7, v1
	s_lshl_b32 s2, s50, 2
	v_lshl_or_b32 v3, v4, 8, v3
	s_waitcnt vmcnt(11)
	ds_write_b128 v2, v[10:13]
	s_waitcnt vmcnt(10)
	ds_write_b128 v2, v[20:23] offset:128
	s_waitcnt vmcnt(9)
	ds_write_b128 v2, v[24:27] offset:256
	s_waitcnt vmcnt(8)
	ds_write_b128 v2, v[28:31] offset:384
	v_and_b32_e32 v2, 0xf0, v61
	v_or3_b32 v3, s2, v6, v3
	v_or_b32_e32 v4, v3, v2
	v_add_u32_e32 v6, 0, v4
	s_movk_i32 s2, 0x50
	s_movk_i32 s3, 0x70
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v20, 8, v58
	v_lshlrev_b32_e32 v18, 4, v18
	v_lshrrev_b32_e32 v21, 1, v1
	v_lshl_or_b32 v22, s49, 6, v20
	v_xor_b32_e32 v23, v18, v21
	v_lshlrev_b32_e32 v63, 4, v57
	v_or_b32_e32 v24, v22, v23
	v_xad_u32 v19, v63, v5, 0
	v_xad_u32 v25, v24, 32, 0
	s_movk_i32 s15, 0x80
	s_movk_i32 s4, 0xc0
	s_movk_i32 s5, 0xe0
	.loc	1 92 22                         ; chunk_o.py:92:22
	v_bitop3_b32 v18, v20, v21, v18 bitop3:0x36
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_lshl_b32 s20, s52, 2
	s_and_b32 s41, s41, 0xffff
	s_mov_b32 s42, s30
	s_mov_b32 s43, s31
	v_add_u32_e32 v52, s38, v52
	v_lshl_add_u32 v52, v52, 7, s20
	v_cndmask_b32_e32 v52, v53, v52, vcc
	s_mov_b32 s14, 0xc2fc0000
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_and_b32 s37, s37, 0xffff
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_and_b32 s13, s13, 0xffff
	.loc	1 97 36                         ; chunk_o.py:97:36
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[26:29], v6
	v_xad_u32 v6, v4, 16, 0
	ds_read_b128 v[76:79], v6
	v_xad_u32 v6, v4, 32, 0
	ds_read_b128 v[80:83], v6
	v_xad_u32 v6, v4, 48, 0
	v_xad_u32 v4, v4, 64, 0
	ds_read_b128 v[84:87], v6
	ds_read_b128 v[88:91], v4
	v_bitop3_b32 v4, v3, s2, v2 bitop3:0x36
	v_add_u32_e32 v4, 0, v4
	s_movk_i32 s2, 0x60
	ds_read_b128 v[92:95], v4
	v_bitop3_b32 v4, v3, s2, v2 bitop3:0x36
	v_bitop3_b32 v2, v3, s3, v2 bitop3:0x36
	v_add_u32_e32 v4, 0, v4
	v_add_u32_e32 v2, 0, v2
	ds_read_b128 v[96:99], v4
	ds_read_b128 v[100:103], v2
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_add_u32_e32 v2, 0, v24
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(7)
	ds_write_b128 v19, v[32:35]
	s_waitcnt vmcnt(5)
	ds_write_b128 v19, v[36:39] offset:4096
	s_waitcnt vmcnt(4)
	ds_write_b128 v19, v[40:43] offset:8192
	ds_write_b128 v19, v[44:47] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[30:33], v2
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[26:29], v[30:33], 0
	.loc	1 90 22                         ; chunk_o.py:90:22
	ds_read_b128 v[26:29], v25
	v_xad_u32 v24, v24, 64, 0
	s_movk_i32 s3, 0xa0
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[76:79], v[26:29], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[80:83], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s2, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[84:87], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s15, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[88:91], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s3, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[92:95], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s4, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	v_bitop3_b32 v22, v22, s5, v23 bitop3:0x36
	v_add_u32_e32 v22, 0, v22
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[96:99], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	ds_read_b128 v[24:27], v22
	v_lshl_or_b32 v22, s50, 7, v20
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[100:103], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v24, v22, v23
	v_add_u32_e32 v25, 0, v24
	ds_read_b128 v[76:79], v25
	v_xad_u32 v25, v24, 32, 0
	v_xad_u32 v24, v24, 64, 0
	ds_read_b128 v[80:83], v25
	ds_read_b128 v[84:87], v24
	v_bitop3_b32 v24, v22, s2, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[88:91], v24
	v_bitop3_b32 v24, v22, s15, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[92:95], v24
	v_bitop3_b32 v24, v22, s3, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[96:99], v24
	v_bitop3_b32 v24, v22, s4, v23 bitop3:0x36
	v_bitop3_b32 v22, v22, s5, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	v_add_u32_e32 v22, 0, v22
	ds_read_b128 v[100:103], v24
	ds_read_b128 v[104:107], v22
	.loc	1 92 22                         ; chunk_o.py:92:22
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(3)
	ds_write_b128 v19, v[48:51]
	s_waitcnt vmcnt(2)
	ds_write_b128 v19, v[64:67] offset:4096
	s_waitcnt vmcnt(1)
	ds_write_b128 v19, v[68:71] offset:8192
	s_waitcnt vmcnt(0)
	ds_write_b128 v19, v[72:75] offset:12288
	v_add_u32_e32 v19, 0, v18
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[20:23], v19
	ds_read_b128 v[64:67], v19 offset:8192
	v_xad_u32 v50, v18, 32, 0
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[20:23], v[76:79], 0
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[20:23], v50
	v_xad_u32 v51, v18, 64, 0
	ds_read_b128 v[108:111], v51 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v69, s51
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[20:23], v[80:83], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v51
	v_xor_b32_e32 v20, 0x60, v18
	v_add_u32_e32 v55, 0, v20
	v_xor_b32_e32 v20, 0x80, v18
	v_add_u32_e32 v56, 0, v20
	v_xor_b32_e32 v20, 0xa0, v18
	v_add_u32_e32 v70, 0, v20
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[84:87], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v55
	v_xor_b32_e32 v20, 0xc0, v18
	v_add_u32_e32 v71, 0, v20
	v_xor_b32_e32 v18, 0xe0, v18
	v_add_u32_e32 v72, 0, v18
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v51, s51
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[88:91], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v56
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[92:95], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v70
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[96:99], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[20:23], v71
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[20:23], v[100:103], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[20:23], v72
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[20:23], v[104:107], v[34:49]
	v_mfma_f32_32x32x16_bf16 v[18:33], v[64:67], v[76:79], 0
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[74:77], v50 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v64, s47, v58
	v_or_b32_e32 v50, s39, v64
	v_lshrrev_b32_e32 v65, 3, v1
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cmp_gt_i64_e64 s[2:3], s[34:35], v[50:51]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v66, s39, v65
	v_mov_b32_e32 v67, s51
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[74:77], v[80:83], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[76:79], v55 offset:8192
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_add_u32_e32 v73, s38, v66
	v_cmp_gt_i64_e64 s[4:5], s[34:35], v[66:67]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v68, 1, v65
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[4:5], s[44:45], s[4:5]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v68, s39, v68
	.loc	1 99 27                         ; chunk_o.py:99:27
	v_mfma_f32_32x32x16_bf16 v[18:33], v[108:111], v[84:87], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[84:87], v72 offset:8192
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v55, s38, v50
	v_lshl_add_u32 v50, v55, 7, s20
	v_cndmask_b32_e64 v50, v53, v50, s[2:3]
	buffer_load_dword v67, v50, s[40:43], 0 offen
	v_lshl_add_u32 v50, v73, 7, s20
	v_cndmask_b32_e64 v50, v53, v50, s[4:5]
	v_add_u32_e32 v74, s38, v68
	v_cmp_gt_i64_e64 s[6:7], s[34:35], v[68:69]
	buffer_load_dword v73, v50, s[40:43], 0 offen
	s_and_b64 s[6:7], s[44:45], s[6:7]
	v_lshl_add_u32 v50, v74, 7, s20
	v_cndmask_b32_e64 v50, v53, v50, s[6:7]
	buffer_load_dword v74, v50, s[40:43], 0 offen
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[76:79], v[88:91], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[76:79], v56 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v75, s51
	v_bfe_i32 v66, v0, 5, 1
	v_lshrrev_b32_e32 v1, 2, v1
	v_or_b32_e32 v1, s47, v1
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v72, v67, v74
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[76:79], v[92:95], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[76:79], v70 offset:8192
	ds_read_b128 v[80:83], v71 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v71, 3, v65
	v_or_b32_e32 v68, s39, v71
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v56, s38, v68
	v_cmp_gt_i64_e64 s[4:5], s[34:35], v[68:69]
	s_and_b64 s[4:5], s[44:45], s[4:5]
.Ltmp2:
	.file	2 "/netra-server/python/sglang/srt/layers/attention/fla" "op.py"
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_mov_b32_e32 v70, 0xff800000
.Ltmp3:
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[76:79], v[96:99], v[18:33]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v76, 2, v65
	v_or_b32_e32 v50, s39, v76
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v55, s38, v50
	v_cmp_gt_i64_e64 s[2:3], s[34:35], v[50:51]
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_lshl_add_u32 v50, v55, 7, s20
	v_cndmask_b32_e64 v50, v53, v50, s[2:3]
	buffer_load_dword v77, v50, s[40:43], 0 offen
	v_lshl_add_u32 v50, v56, 7, s20
	v_cndmask_b32_e64 v50, v53, v50, s[4:5]
	buffer_load_dword v78, v50, s[40:43], 0 offen
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[80:83], v[100:103], v[18:33]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v80, 8, v65
	v_or_b32_e32 v50, s39, v80
	v_or_b32_e32 v79, 9, v65
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v55, s38, v50
	v_cmp_gt_i64_e64 s[2:3], s[34:35], v[50:51]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v68, s39, v79
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_lshl_add_u32 v50, v55, 7, s20
	v_add_u32_e32 v56, s38, v68
	v_cmp_gt_i64_e64 s[4:5], s[34:35], v[68:69]
	v_cndmask_b32_e64 v50, v53, v50, s[2:3]
	s_and_b64 s[4:5], s[44:45], s[4:5]
	buffer_load_dword v81, v50, s[40:43], 0 offen
	buffer_load_dword v55, v52, s[40:43], 0 offen
	v_lshl_add_u32 v50, v56, 7, s20
	v_cndmask_b32_e64 v50, v53, v50, s[4:5]
	buffer_load_dword v82, v50, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v69, v67, v73
.Ltmp4:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v69
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v69, 0x3fb8aa3b, v69
.Ltmp5:
	.loc	1 105 24 is_stmt 1              ; chunk_o.py:105:24
	v_mov_b32_e32 v56, 0x42800000
.Ltmp6:
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, v70, v69, s[2:3]
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[2:3], s14, v69
.Ltmp7:
	.loc	1 99 27 is_stmt 1               ; chunk_o.py:99:27
	v_mfma_f32_32x32x16_bf16 v[18:33], v[84:87], v[104:107], v[18:33]
.Ltmp8:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v72
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v73, 0, v56, s[2:3]
	v_mul_f32_e32 v72, 0x3fb8aa3b, v72
.Ltmp9:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v85, 10, v65
.Ltmp10:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_add_f32_e32 v69, v69, v73
	.loc	2 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v83, v70, v72, s[4:5]
.Ltmp11:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v72, s39, v85
	v_mov_b32_e32 v73, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v86, s38, v72
	v_cmp_gt_i64_e64 s[6:7], s[34:35], v[72:73]
	s_and_b64 s[6:7], s[44:45], s[6:7]
	v_lshl_add_u32 v72, v86, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[6:7]
	buffer_load_dword v86, v72, s[40:43], 0 offen
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v84, 11, v65
	v_or_b32_e32 v74, s39, v84
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v87, s38, v74
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[74:75]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v72, v87, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[8:9]
	buffer_load_dword v87, v72, s[40:43], 0 offen
.Ltmp12:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v83
	v_exp_f32_e32 v69, v69
.Ltmp13:
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_not_b32_e32 v52, 63
.Ltmp14:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v72, 0, v56, s[4:5]
	v_add_f32_e32 v72, v83, v72
	v_exp_f32_e32 v72, v72
	v_cndmask_b32_e64 v73, 0, v52, s[2:3]
	v_ldexp_f32 v69, v69, v73
	v_cndmask_b32_e64 v73, 0, v52, s[4:5]
	v_ldexp_f32 v72, v72, v73
.Ltmp15:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_mul_f32_e32 v69, v34, v69
	v_mul_f32_e32 v34, v35, v72
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_and_b32_e32 v68, 56, v61
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_or_b32_e32 v50, s33, v68
	v_mov_b32_e32 v51, s46
	.loc	1 109 26                        ; chunk_o.py:109:26
	v_cmp_gt_u32_e64 s[2:3], v64, v65
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_cvt_pk_bf16_f32 v34, v34, s0
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(6)
	v_sub_f32_e32 v35, v67, v77
.Ltmp16:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v35
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
.Ltmp17:
	.loc	1 106 44 is_stmt 1              ; chunk_o.py:106:44
	s_waitcnt vmcnt(5)
	v_sub_f32_e32 v72, v67, v78
.Ltmp18:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v72
	.loc	2 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v35, v70, v35, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v72, 0x3fb8aa3b, v72
	v_cmp_gt_f32_e64 s[4:5], s14, v35
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v72, v70, v72, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v72
	v_cndmask_b32_e64 v73, 0, v56, s[4:5]
	v_add_f32_e32 v35, v35, v73
	v_cndmask_b32_e64 v73, 0, v56, s[6:7]
	v_exp_f32_e32 v35, v35
	v_add_f32_e32 v72, v72, v73
	v_exp_f32_e32 v73, v72
	v_cndmask_b32_e64 v72, 0, v52, s[4:5]
	v_ldexp_f32 v72, v35, v72
	v_cndmask_b32_e64 v35, 0, v52, s[6:7]
	v_ldexp_f32 v73, v73, v35
.Ltmp19:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v78, 16, v65
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[36:37], v[36:37], v[72:73]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v71
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v72, s39, v78
	v_mov_b32_e32 v73, s51
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v35, 0, v37, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v37, v67, v81
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v77, 17, v65
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v81, s38, v72
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[72:73]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v74, s39, v77
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v72, v81, 7, s20
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v71, v67, v82
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v82, s38, v74
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[74:75]
	v_cndmask_b32_e64 v72, v53, v72, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v81, v72, s[40:43], 0 offen
	v_lshl_add_u32 v72, v82, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[10:11]
	buffer_load_dword v82, v72, s[40:43], 0 offen
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v76
.Ltmp20:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v71
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v71, 0x3fb8aa3b, v71
.Ltmp21:
	.loc	1 110 29 is_stmt 1              ; chunk_o.py:110:29
	v_cndmask_b32_e64 v36, 0, v36, s[4:5]
.Ltmp22:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v37
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v37, 0x3fb8aa3b, v37
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v71, v70, v71, s[6:7]
	v_cndmask_b32_e64 v37, v70, v37, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v37
	v_cmp_gt_f32_e64 s[6:7], s14, v71
.Ltmp23:
	.loc	1 110 29 is_stmt 1              ; chunk_o.py:110:29
	v_cndmask_b32_e64 v34, 0, v34, s[2:3]
.Ltmp24:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v76, 0, v56, s[4:5]
	v_add_f32_e32 v37, v37, v76
	v_cndmask_b32_e64 v72, 0, v56, s[6:7]
	v_exp_f32_e32 v37, v37
	v_add_f32_e32 v71, v71, v72
	v_exp_f32_e32 v71, v71
	v_cndmask_b32_e64 v72, 0, v52, s[4:5]
	v_ldexp_f32 v72, v37, v72
	v_cndmask_b32_e64 v37, 0, v52, s[6:7]
	v_ldexp_f32 v73, v71, v37
.Ltmp25:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[38:39], v[38:39], v[72:73]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v79
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v73, s51
	v_or_b32_e32 v79, 19, v65
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v37, 0, v39, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v80
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v80, 18, v65
	v_or_b32_e32 v72, s39, v80
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v83, s38, v72
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[72:73]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v74, s39, v79
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v72, v83, 7, s20
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v39, v67, v86
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v86, s38, v74
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[74:75]
	v_cndmask_b32_e64 v72, v53, v72, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v83, v72, s[40:43], 0 offen
	v_lshl_add_u32 v72, v86, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[10:11]
	buffer_load_dword v86, v72, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v71, v67, v87
.Ltmp26:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v71
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v71, 0x3fb8aa3b, v71
.Ltmp27:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v87, 24, v65
.Ltmp28:
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v71, v70, v71, s[6:7]
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v71
.Ltmp29:
	.loc	1 110 29 is_stmt 1              ; chunk_o.py:110:29
	v_cndmask_b32_e64 v38, 0, v38, s[4:5]
.Ltmp30:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v39
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v72, 0, v56, s[6:7]
	v_add_f32_e32 v71, v71, v72
.Ltmp31:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v72, s39, v87
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v88, s38, v72
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[72:73]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v72, v88, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[8:9]
	buffer_load_dword v88, v72, s[40:43], 0 offen
.Ltmp32:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v39, 0x3fb8aa3b, v39
	.loc	2 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v39, v70, v39, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v39
	v_exp_f32_e32 v71, v71
	s_movk_i32 s3, 0x108
	v_cndmask_b32_e64 v76, 0, v56, s[4:5]
	v_add_f32_e32 v39, v39, v76
.Ltmp33:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v76, 25, v65
	v_or_b32_e32 v74, s39, v76
.Ltmp34:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v39, v39
.Ltmp35:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v89, s38, v74
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[74:75]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	v_lshl_add_u32 v72, v89, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[10:11]
	buffer_load_dword v89, v72, s[40:43], 0 offen
.Ltmp36:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v72, 0, v52, s[4:5]
	v_ldexp_f32 v72, v39, v72
	v_cndmask_b32_e64 v39, 0, v52, s[6:7]
	v_ldexp_f32 v73, v71, v39
.Ltmp37:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[40:41], v[40:41], v[72:73]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v84
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v71, v67, v82
.Ltmp38:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v71
.Ltmp39:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v39, 0, v41, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v85
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v41, v67, v81
.Ltmp40:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v71, 0x3fb8aa3b, v71
.Ltmp41:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v40, 0, v40, s[4:5]
.Ltmp42:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v41
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v41, 0x3fb8aa3b, v41
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v71, v70, v71, s[6:7]
	v_cndmask_b32_e64 v41, v70, v41, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v41
	v_cmp_gt_f32_e64 s[6:7], s14, v71
.Ltmp43:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v82, 26, v65
.Ltmp44:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v72, 0, v56, s[4:5]
	v_add_f32_e32 v41, v41, v72
	v_cndmask_b32_e64 v72, 0, v56, s[6:7]
	v_add_f32_e32 v71, v71, v72
.Ltmp45:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v72, s39, v82
	v_mov_b32_e32 v73, s51
	v_or_b32_e32 v81, 27, v65
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v84, s38, v72
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[72:73]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v74, s39, v81
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v72, v84, 7, s20
	v_add_u32_e32 v85, s38, v74
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[74:75]
	v_cndmask_b32_e64 v72, v53, v72, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v74, v72, s[40:43], 0 offen
	v_lshl_add_u32 v72, v85, 7, s20
	v_cndmask_b32_e64 v72, v53, v72, s[10:11]
	buffer_load_dword v75, v72, s[40:43], 0 offen
.Ltmp46:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v41, v41
	v_exp_f32_e32 v71, v71
	v_cndmask_b32_e64 v72, 0, v52, s[4:5]
.Ltmp47:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v77
.Ltmp48:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_ldexp_f32 v72, v41, v72
	v_cndmask_b32_e64 v41, 0, v52, s[6:7]
	v_ldexp_f32 v73, v71, v41
.Ltmp49:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[42:43], v[42:43], v[72:73]
	.loc	1 122 38                        ; chunk_o.py:122:38
	s_lshr_b32 s2, s49, 1
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v41, 0, v43, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v78
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v43, v67, v86
.Ltmp50:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v43
.Ltmp51:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v71, 0, v42, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v42, v67, v83
.Ltmp52:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v42
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v42, 0x3fb8aa3b, v42
	v_mul_f32_e32 v43, 0x3fb8aa3b, v43
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v42, v70, v42, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v42
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v43, v70, v43, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v43
	v_cndmask_b32_e64 v72, 0, v56, s[4:5]
	v_add_f32_e32 v42, v42, v72
	v_cndmask_b32_e64 v72, 0, v56, s[6:7]
	v_exp_f32_e32 v42, v42
	v_add_f32_e32 v43, v43, v72
	v_exp_f32_e32 v43, v43
	v_cndmask_b32_e64 v72, 0, v52, s[4:5]
	v_ldexp_f32 v42, v42, v72
	v_cndmask_b32_e64 v72, 0, v52, s[6:7]
	v_ldexp_f32 v43, v43, v72
.Ltmp53:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[42:43], v[44:45], v[42:43]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v79
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v83, 32, v65
	v_mov_b32_e32 v45, s51
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v72, 0, v43, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v80
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v43, s51
	v_or_b32_e32 v80, 33, v65
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v73, 0, v42, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v42, v67, v88
.Ltmp54:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v42
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v42, 0x3fb8aa3b, v42
.Ltmp55:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v44, s39, v80
.Ltmp56:
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v78, v70, v42, s[4:5]
.Ltmp57:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v42, s39, v83
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v84, s38, v42
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[42:43]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v42, v84, 7, s20
	v_cndmask_b32_e64 v42, v53, v42, s[8:9]
	buffer_load_dword v84, v42, s[40:43], 0 offen
	v_add_u32_e32 v85, s38, v44
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[44:45]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	v_lshl_add_u32 v42, v85, 7, s20
	v_cndmask_b32_e64 v42, v53, v42, s[10:11]
	buffer_load_dword v85, v42, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v77, v67, v89
.Ltmp58:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v77
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v43, 0x3fb8aa3b, v77
	v_cmp_gt_f32_e64 s[4:5], s14, v78
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v43, v70, v43, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v43
	v_cndmask_b32_e64 v79, 0, v56, s[4:5]
	v_add_f32_e32 v42, v78, v79
	v_cndmask_b32_e64 v44, 0, v56, s[6:7]
	v_exp_f32_e32 v42, v42
	v_add_f32_e32 v43, v43, v44
	v_exp_f32_e32 v43, v43
	v_cndmask_b32_e64 v44, 0, v52, s[4:5]
	v_ldexp_f32 v42, v42, v44
	v_cndmask_b32_e64 v44, 0, v52, s[6:7]
	v_ldexp_f32 v43, v43, v44
.Ltmp59:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[42:43], v[46:47], v[42:43]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v76
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v78, 34, v65
	v_or_b32_e32 v77, 35, v65
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v46, 0, v43, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v87
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v43, s51
	v_or_b32_e32 v44, s39, v77
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v47, 0, v42, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v42, v67, v74
.Ltmp60:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v42
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v42, 0x3fb8aa3b, v42
.Ltmp61:
	.loc	1 106 44 is_stmt 1              ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v74, v67, v75
.Ltmp62:
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v75, v70, v42, s[4:5]
.Ltmp63:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v42, s39, v78
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v79, s38, v42
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[42:43]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v42, v79, 7, s20
	v_add_u32_e32 v86, s38, v44
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[44:45]
	v_cndmask_b32_e64 v42, v53, v42, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v79, v42, s[40:43], 0 offen
	v_lshl_add_u32 v42, v86, 7, s20
	v_cndmask_b32_e64 v42, v53, v42, s[10:11]
	buffer_load_dword v86, v42, s[40:43], 0 offen
.Ltmp64:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v75
	.loc	2 27 29 is_stmt 0               ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v74
.Ltmp65:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v87, 40, v65
.Ltmp66:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v76, 0, v56, s[4:5]
	v_add_f32_e32 v42, v75, v76
	v_exp_f32_e32 v75, v42
	v_mul_f32_e32 v42, 0x3fb8aa3b, v74
	.loc	2 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v42, v70, v42, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v42
.Ltmp67:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v76, 41, v65
	v_or_b32_e32 v44, s39, v76
.Ltmp68:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v43, 0, v56, s[6:7]
	v_add_f32_e32 v74, v42, v43
.Ltmp69:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v42, s39, v87
	v_mov_b32_e32 v43, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v88, s38, v42
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[42:43]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v42, v88, 7, s20
	v_add_u32_e32 v89, s38, v44
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[44:45]
	v_cndmask_b32_e64 v42, v53, v42, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v44, v42, s[40:43], 0 offen
	v_lshl_add_u32 v42, v89, 7, s20
	v_cndmask_b32_e64 v42, v53, v42, s[10:11]
	buffer_load_dword v45, v42, s[40:43], 0 offen
.Ltmp70:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v43, v74
	v_cndmask_b32_e64 v42, 0, v52, s[4:5]
	v_cndmask_b32_e64 v74, 0, v52, s[6:7]
	v_ldexp_f32 v42, v75, v42
	v_ldexp_f32 v43, v43, v74
.Ltmp71:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[42:43], v[48:49], v[42:43]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v81
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v81, 42, v65
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v74, v67, v85
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v48, 0, v43, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v82
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v43, s51
.Ltmp72:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v74
.Ltmp73:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v49, 0, v42, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v42, v67, v84
.Ltmp74:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v42
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v75, 0x3fb8aa3b, v42
.Ltmp75:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v42, s39, v81
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v82, s38, v42
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[42:43]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v42, v82, 7, s20
	v_cndmask_b32_e64 v42, v53, v42, s[8:9]
	buffer_load_dword v82, v42, s[40:43], 0 offen
.Ltmp76:
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v42, v70, v75, s[4:5]
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v42
.Ltmp77:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v84, 43, v65
.Ltmp78:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	s_nop 0
	v_cndmask_b32_e64 v43, 0, v56, s[4:5]
	v_add_f32_e32 v42, v42, v43
	v_exp_f32_e32 v75, v42
	v_mul_f32_e32 v42, 0x3fb8aa3b, v74
	.loc	2 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v42, v70, v42, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v42
	s_nop 1
	v_cndmask_b32_e64 v43, 0, v56, s[6:7]
	v_add_f32_e32 v74, v42, v43
.Ltmp79:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v42, s39, v84
	v_mov_b32_e32 v43, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v85, s38, v42
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[42:43]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v42, v85, 7, s20
	v_cndmask_b32_e64 v42, v53, v42, s[8:9]
	buffer_load_dword v85, v42, s[40:43], 0 offen
.Ltmp80:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v43, v74
	v_cndmask_b32_e64 v42, 0, v52, s[4:5]
	v_cndmask_b32_e64 v74, 0, v52, s[6:7]
	v_ldexp_f32 v42, v75, v42
	v_ldexp_f32 v43, v43, v74
.Ltmp81:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[18:19], v[42:43]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v80
	s_nop 1
	v_cndmask_b32_e64 v42, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v83
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v19, v67, v86
.Ltmp82:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp83:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v43, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v67, v79
.Ltmp84:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v18
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v70, v19, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v19
	v_cndmask_b32_e64 v74, 0, v56, s[4:5]
	v_add_f32_e32 v18, v18, v74
	v_cndmask_b32_e64 v74, 0, v56, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v74
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v74, 0, v52, s[4:5]
	v_ldexp_f32 v18, v18, v74
	v_cndmask_b32_e64 v74, 0, v52, s[6:7]
	v_ldexp_f32 v19, v19, v74
.Ltmp85:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[20:21], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v77
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v77, 48, v65
	v_mov_b32_e32 v21, s51
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v74, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v78
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v19, v67, v45
.Ltmp86:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp87:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v75, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v67, v44
.Ltmp88:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v18
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v70, v19, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v19
	v_cndmask_b32_e64 v20, 0, v56, s[4:5]
	v_add_f32_e32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v56, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v20
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v20, 0, v52, s[4:5]
	v_ldexp_f32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v52, s[6:7]
	v_ldexp_f32 v19, v19, v20
.Ltmp89:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[22:23], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v76
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v76, 49, v65
	v_or_b32_e32 v20, s39, v76
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v44, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v87
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v19, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v78, s38, v20
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v45, 0, v18, s[4:5]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v18, s39, v77
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v23, s38, v18
	v_cmp_gt_i64_e64 s[4:5], s[34:35], v[18:19]
	s_and_b64 s[4:5], s[44:45], s[4:5]
	v_lshl_add_u32 v18, v23, 7, s20
	v_cmp_gt_i64_e64 s[6:7], s[34:35], v[20:21]
	v_cndmask_b32_e64 v18, v53, v18, s[4:5]
	s_and_b64 s[6:7], s[44:45], s[6:7]
	buffer_load_dword v79, v18, s[40:43], 0 offen
	v_lshl_add_u32 v18, v78, 7, s20
	v_cndmask_b32_e64 v18, v53, v18, s[6:7]
	buffer_load_dword v78, v18, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v22, v67, v82
.Ltmp90:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v22
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v22
.Ltmp91:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v83, 50, v65
.Ltmp92:
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v22, v70, v18, s[4:5]
.Ltmp93:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v18, s39, v83
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v23, v67, v85
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v82, 51, v65
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v85, s38, v18
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[18:19]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v20, s39, v82
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v18, v85, 7, s20
	v_add_u32_e32 v86, s38, v20
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[20:21]
	v_cndmask_b32_e64 v18, v53, v18, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v85, v18, s[40:43], 0 offen
	v_lshl_add_u32 v18, v86, 7, s20
	v_cndmask_b32_e64 v18, v53, v18, s[10:11]
	buffer_load_dword v86, v18, s[40:43], 0 offen
.Ltmp94:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v22
	.loc	2 27 29 is_stmt 0               ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v23
.Ltmp95:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v87, 56, v65
.Ltmp96:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v80, 0, v56, s[4:5]
	v_add_f32_e32 v18, v22, v80
	v_exp_f32_e32 v22, v18
	v_mul_f32_e32 v18, 0x3fb8aa3b, v23
	.loc	2 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v18
.Ltmp97:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v80, 57, v65
	v_or_b32_e32 v20, s39, v80
.Ltmp98:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, 0, v56, s[6:7]
	v_add_f32_e32 v23, v18, v19
.Ltmp99:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v18, s39, v87
	v_mov_b32_e32 v19, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v88, s38, v18
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[18:19]
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_lshl_add_u32 v18, v88, 7, s20
	v_add_u32_e32 v89, s38, v20
	v_cmp_gt_i64_e64 s[10:11], s[34:35], v[20:21]
	v_cndmask_b32_e64 v18, v53, v18, s[8:9]
	s_and_b64 s[10:11], s[44:45], s[10:11]
	buffer_load_dword v88, v18, s[40:43], 0 offen
	v_lshl_add_u32 v18, v89, 7, s20
	v_cndmask_b32_e64 v18, v53, v18, s[10:11]
	buffer_load_dword v89, v18, s[40:43], 0 offen
.Ltmp100:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v19, v23
	v_cndmask_b32_e64 v18, 0, v52, s[4:5]
	v_cndmask_b32_e64 v20, 0, v52, s[6:7]
	v_ldexp_f32 v18, v22, v18
	v_ldexp_f32 v19, v19, v20
.Ltmp101:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[24:25], v[18:19]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v25, 58, v65
	v_or_b32_e32 v24, 59, v65
	v_or_b32_e32 v20, s39, v25
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v84
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v22, s39, v24
	v_mov_b32_e32 v23, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_add_u32_e32 v84, s38, v20
	v_cmp_gt_i64_e64 s[6:7], s[34:35], v[20:21]
	v_add_u32_e32 v90, s38, v22
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[22:23]
	s_and_b64 s[6:7], s[44:45], s[6:7]
	v_lshl_add_u32 v20, v84, 7, s20
	s_and_b64 s[8:9], s[44:45], s[8:9]
	v_cndmask_b32_e64 v20, v53, v20, s[6:7]
	v_lshl_add_u32 v21, v90, 7, s20
	buffer_load_dword v20, v20, s[40:43], 0 offen
	v_cndmask_b32_e64 v21, v53, v21, s[8:9]
	buffer_load_dword v21, v21, s[40:43], 0 offen
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v84, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v81
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_or_b32_e32 v23, s48, v68
	s_mov_b32 s38, s30
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v81, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(7)
	v_sub_f32_e32 v18, v67, v79
.Ltmp102:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
.Ltmp103:
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(6)
	v_sub_f32_e32 v19, v67, v78
.Ltmp104:
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	.loc	2 27 29 is_stmt 0               ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	v_cmp_gt_f32_e64 s[4:5], s14, v18
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v70, v19, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v19
	v_cndmask_b32_e64 v22, 0, v56, s[4:5]
	v_add_f32_e32 v18, v18, v22
	v_cndmask_b32_e64 v22, 0, v56, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v22
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v22, 0, v52, s[4:5]
	v_ldexp_f32 v18, v18, v22
	v_cndmask_b32_e64 v22, 0, v52, s[6:7]
	v_ldexp_f32 v19, v19, v22
.Ltmp105:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[26:27], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v76
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_mov_b32 s39, s31
	.loc	1 110 29                        ; chunk_o.py:110:29
	s_nop 0
	v_cndmask_b32_e64 v26, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v77
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v19, v67, v86
.Ltmp106:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp107:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v27, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v67, v85
.Ltmp108:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v18
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v70, v19, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v19
	v_cndmask_b32_e64 v22, 0, v56, s[4:5]
	v_add_f32_e32 v18, v18, v22
	v_cndmask_b32_e64 v22, 0, v56, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v22
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v22, 0, v52, s[4:5]
	v_ldexp_f32 v18, v18, v22
	v_cndmask_b32_e64 v22, 0, v52, s[6:7]
	v_ldexp_f32 v19, v19, v22
.Ltmp109:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[28:29], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v82
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_cvt_pk_bf16_f32 v27, v27, s0
	v_cvt_pk_bf16_f32 v26, v26, s0
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v28, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v83
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v19, v67, v89
.Ltmp110:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp111:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v29, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v67, v88
.Ltmp112:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v18
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v70, v19, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v19
	v_cndmask_b32_e64 v22, 0, v56, s[4:5]
	v_add_f32_e32 v18, v18, v22
	v_cndmask_b32_e64 v22, 0, v56, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v22
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v22, 0, v52, s[4:5]
	v_ldexp_f32 v18, v18, v22
	v_cndmask_b32_e64 v22, 0, v52, s[6:7]
	v_ldexp_f32 v19, v19, v22
.Ltmp113:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[30:31], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v80
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_lshlrev_b32_e32 v22, 12, v60
	v_add_lshl_u32 v22, v23, v22, 1
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v30, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v87
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v19, v67, v21
.Ltmp114:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp115:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v31, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v67, v20
.Ltmp116:
	.loc	2 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	2 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v70, v18, s[4:5]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s14, v18
	.loc	2 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v70, v19, s[6:7]
	.loc	2 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s14, v19
	v_cndmask_b32_e64 v20, 0, v56, s[4:5]
	v_add_f32_e32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v56, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v20
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v20, 0, v52, s[4:5]
	v_ldexp_f32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v52, s[6:7]
	v_ldexp_f32 v19, v19, v20
.Ltmp117:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[32:33], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v24
	s_nop 1
	v_cndmask_b32_e64 v32, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v64, v25
	s_nop 1
	v_cndmask_b32_e64 v33, 0, v18, s[4:5]
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_cmp_gt_i64_e64 s[4:5], s[18:19], v[50:51]
	v_lshlrev_b32_e32 v18, 12, v59
	s_and_b64 s[6:7], s[16:17], s[4:5]
	s_and_b64 s[4:5], s[6:7], s[24:25]
	s_and_b64 s[6:7], s[6:7], s[26:27]
	v_add_lshl_u32 v18, v23, v18, 1
	v_cndmask_b32_e64 v18, v53, v18, s[4:5]
	v_cndmask_b32_e64 v22, v53, v22, s[6:7]
	buffer_load_dwordx4 v[18:21], v18, s[36:39], 0 offen
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_lshlrev_b32_e32 v50, 1, v58
	.loc	1 118 18                        ; chunk_o.py:118:18
	buffer_load_dwordx4 v[22:25], v22, s[36:39], 0 offen
	s_movk_i32 s4, 0x210
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_bitop3_b32 v50, v66, v50, s4 bitop3:0x6c
	v_or_b32_e32 v50, s50, v50
	v_add_u32_e32 v58, 0, v50
	v_cvt_pk_bf16_f32 v59, v69, s0
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v64, v65
	.loc	1 122 38                        ; chunk_o.py:122:38
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v59, 0, v59, s[4:5]
	.loc	1 122 38                        ; chunk_o.py:122:38
	ds_write_b16 v58, v27 offset:6144
	ds_write_b16 v58, v26 offset:6272
	v_xad_u32 v26, v50, 8, 0
	v_cvt_pk_bf16_f32 v27, v36, s0
	ds_write_b16 v58, v59
	ds_write_b16 v58, v34 offset:128
	v_cvt_pk_bf16_f32 v34, v71, s0
	ds_write_b16 v26, v27 offset:256
	v_cvt_pk_bf16_f32 v27, v35, s0
	ds_write_b16 v58, v34 offset:2048
	v_cvt_pk_bf16_f32 v34, v41, s0
	ds_write_b16 v26, v27 offset:384
	v_cvt_pk_bf16_f32 v27, v73, s0
	ds_write_b16 v58, v34 offset:2176
	v_cvt_pk_bf16_f32 v34, v43, s0
	ds_write_b16 v26, v27 offset:2304
	v_cvt_pk_bf16_f32 v27, v72, s0
	ds_write_b16 v58, v34 offset:4096
	v_cvt_pk_bf16_f32 v34, v42, s0
	ds_write_b16 v26, v27 offset:2432
	v_cvt_pk_bf16_f32 v27, v75, s0
	ds_write_b16 v58, v34 offset:4224
	ds_write_b16 v26, v27 offset:4352
	v_cvt_pk_bf16_f32 v27, v74, s0
	ds_write_b16 v26, v27 offset:4480
	v_cvt_pk_bf16_f32 v27, v29, s0
	ds_write_b16 v26, v27 offset:6400
	v_cvt_pk_bf16_f32 v27, v28, s0
	ds_write_b16 v26, v27 offset:6528
	v_xad_u32 v26, v50, 32, 0
	v_cvt_pk_bf16_f32 v27, v38, s0
	ds_write_b16 v26, v27 offset:1024
	v_cvt_pk_bf16_f32 v27, v37, s0
	ds_write_b16 v26, v27 offset:1152
	v_cvt_pk_bf16_f32 v27, v47, s0
	ds_write_b16 v26, v27 offset:3072
	v_cvt_pk_bf16_f32 v27, v46, s0
	ds_write_b16 v26, v27 offset:3200
	v_cvt_pk_bf16_f32 v27, v45, s0
	ds_write_b16 v26, v27 offset:5120
	v_cvt_pk_bf16_f32 v27, v44, s0
	ds_write_b16 v26, v27 offset:5248
	v_cvt_pk_bf16_f32 v27, v31, s0
	ds_write_b16 v26, v27 offset:7168
	v_cvt_pk_bf16_f32 v27, v30, s0
	ds_write_b16 v26, v27 offset:7296
	v_xad_u32 v26, v50, 40, 0
	v_cvt_pk_bf16_f32 v27, v40, s0
	ds_write_b16 v26, v27 offset:1280
	v_cvt_pk_bf16_f32 v27, v39, s0
	ds_write_b16 v26, v27 offset:1408
	v_cvt_pk_bf16_f32 v27, v49, s0
	ds_write_b16 v26, v27 offset:3328
	v_cvt_pk_bf16_f32 v27, v48, s0
	ds_write_b16 v26, v27 offset:3456
	v_cvt_pk_bf16_f32 v27, v81, s0
	ds_write_b16 v26, v27 offset:5376
	v_cvt_pk_bf16_f32 v27, v84, s0
	ds_write_b16 v26, v27 offset:5504
	v_cvt_pk_bf16_f32 v27, v33, s0
	ds_write_b16 v26, v27 offset:7424
	v_cvt_pk_bf16_f32 v27, v32, s0
	ds_write_b16 v26, v27 offset:7552
	v_and_b32_e32 v26, 24, v61
	v_lshlrev_b32_e32 v27, 5, v0
	v_bfe_i32 v0, v0, 3, 1
	v_and_b32_e32 v51, 0x210, v66
	v_bitop3_b32 v0, v0, v26, s3 bitop3:0x6c
	v_xor_b32_e32 v0, v0, v51
	v_lshlrev_b32_e32 v28, 1, v62
	v_and_or_b32 v0, v27, s15, v0
	v_or3_b32 v0, v0, s2, v28
	v_add_u32_e32 v29, 0, v0
	v_xad_u32 v0, v0, 32, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[60:61], v0 offset:1024
	ds_read_b64_tr_b16 v[46:47], v0 offset:3072
	ds_read_b64_tr_b16 v[42:43], v0 offset:5120
	ds_read_b64_tr_b16 v[38:39], v0 offset:7168
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_lshrrev_b32_e32 v0, 1, v57
	v_bitop3_b32 v0, v0, v63, 56 bitop3:0x6c
	.loc	1 122 38                        ; chunk_o.py:122:38
	ds_read_b64_tr_b16 v[58:59], v29
	ds_read_b64_tr_b16 v[44:45], v29 offset:2048
	ds_read_b64_tr_b16 v[40:41], v29 offset:4096
	ds_read_b64_tr_b16 v[36:37], v29 offset:6144
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_add_u32_e32 v29, 0, v0
	v_xad_u32 v0, v0, 8, 0
	s_movk_i32 s2, 0x180
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v29, v[18:19], v[22:23] offset1:8
	ds_write2st64_b64 v0, v[20:21], v[24:25] offset1:8
	v_and_or_b32 v0, v27, s2, v26
	s_movk_i32 s2, 0x48
	v_and_or_b32 v18, v57, s2, v51
	v_bitop3_b32 v18, v18, v28, v0 bitop3:0xde
	v_add_u32_e32 v0, 0, v18
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[62:63], v0
	v_xad_u32 v34, v18, 32, 0
	ds_read_b64_tr_b16 v[64:65], v34 offset:1024
	ds_read_b64_tr_b16 v[48:49], v0 offset:2048
	ds_read_b64_tr_b16 v[50:51], v34 offset:3072
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[62:65], v[58:61], 0
	.loc	1 118 18                        ; chunk_o.py:118:18
	ds_read_b64_tr_b16 v[58:59], v0 offset:4096
	ds_read_b64_tr_b16 v[60:61], v34 offset:5120
	s_load_dword s2, s[0:1], 0x40
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v35, s48, v1
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_mov_b32 s15, s31
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[48:51], v[44:47], v[18:33]
	.loc	1 118 18                        ; chunk_o.py:118:18
	ds_read_b64_tr_b16 v[46:47], v0 offset:6144
	ds_read_b64_tr_b16 v[48:49], v34 offset:7168
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_mul_f32_e32 v44, 0x3fb8aa3b, v55
	v_cmp_gt_f32_e64 s[0:1], s14, v44
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_or_b32_e32 v0, s33, v1
	v_mov_b32_e32 v1, s46
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_cndmask_b32_e64 v44, 0, v56, s[0:1]
	v_fmac_f32_e32 v44, 0x3fb8aa3b, v55
	.loc	1 122 50                        ; chunk_o.py:122:50
	v_mfma_f32_32x32x16_bf16 v[18:33], v[58:61], v[40:43], v[18:33]
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_exp_f32_e32 v44, v44
	v_cndmask_b32_e64 v34, 0, v52, s[0:1]
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_cmp_gt_i64_e64 s[0:1], s[18:19], v[0:1]
	s_and_b64 s[0:1], s[16:17], s[0:1]
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_ldexp_f32 v34, v44, v34
	.loc	1 105 20 is_stmt 0              ; chunk_o.py:105:20
	v_pk_mul_f32 v[0:1], v[2:3], v[34:35] op_sel_hi:[1,0]
	.loc	1 118 18 is_stmt 1              ; chunk_o.py:118:18
	s_and_b64 vcc, s[0:1], vcc
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[46:49], v[36:39], v[18:33]
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_mov_b32 s14, s30
	.loc	1 122 57                        ; chunk_o.py:122:57
	s_nop 10
	v_pk_mul_f32 v[2:3], s[2:3], v[18:19] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[0:1], s[2:3], v[0:1], v[2:3] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[2:3], v[4:5], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[4:5], s[2:3], v[20:21] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[2:3], s[2:3], v[2:3], v[4:5] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[6:7], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[6:7], s[2:3], v[22:23] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[6:7], s[2:3], v[4:5], v[6:7] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[8:9], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[8:9], s[2:3], v[24:25] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[8:9], s[2:3], v[4:5], v[8:9] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[10:11], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[10:11], s[2:3], v[26:27] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[10:11], s[2:3], v[4:5], v[10:11] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[12:13], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[12:13], s[2:3], v[28:29] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[12:13], s[2:3], v[4:5], v[12:13] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[14:15], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[14:15], s[2:3], v[30:31] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[14:15], s[2:3], v[4:5], v[14:15] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[16:17], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[16:17], s[2:3], v[32:33] op_sel_hi:[0,1]
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_cvt_pk_bf16_f32 v6, v6, v7
	v_cvt_pk_bf16_f32 v7, v8, v9
	.loc	1 123 18 is_stmt 0              ; chunk_o.py:123:18
	v_lshlrev_b32_e32 v8, 12, v54
	.loc	1 122 24 is_stmt 1              ; chunk_o.py:122:24
	v_pk_fma_f32 v[16:17], s[2:3], v[4:5], v[16:17] op_sel_hi:[0,1,1]
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_cvt_pk_bf16_f32 v4, v0, v1
	v_cvt_pk_bf16_f32 v5, v2, v3
	.loc	1 123 18 is_stmt 0              ; chunk_o.py:123:18
	v_add_lshl_u32 v8, v8, v35, 1
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_permlane32_swap_b32_e32 v4, v6
	v_permlane32_swap_b32_e32 v5, v7
	.loc	1 123 18                        ; chunk_o.py:123:18
	v_cndmask_b32_e32 v9, v53, v8, vcc
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_cvt_pk_bf16_f32 v0, v10, v11
	v_cvt_pk_bf16_f32 v1, v12, v13
	v_cvt_pk_bf16_f32 v2, v14, v15
	v_cvt_pk_bf16_f32 v3, v16, v17
	.loc	1 123 18                        ; chunk_o.py:123:18
	buffer_store_dwordx4 v[4:7], v9, s[12:15], 0 offen
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_permlane32_swap_b32_e32 v0, v2
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_nop 0
	v_or_b32_e32 v4, 32, v8
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_permlane32_swap_b32_e32 v1, v3
	.loc	1 123 18                        ; chunk_o.py:123:18
	v_cndmask_b32_e32 v4, v53, v4, vcc
	buffer_store_dwordx4 v[0:3], v4, s[12:15], 0 offen
	.loc	1 123 4                         ; chunk_o.py:123:4
	s_endpgm
.Ltmp118:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950
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
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 112
		.amdhsa_next_free_sgpr 53
		.amdhsa_accum_offset 112
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
	.size	qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950, .Lfunc_end0-qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.num_vgpr, 112
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.num_agpr, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.numbered_sgpr, 53
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.num_named_barrier, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.private_seg_size, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.uses_vcc, 1
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.uses_flat_scratch, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.has_dyn_sized_stack, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.has_recursion, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 8528
; TotalNumSgprs: 59
; NumVgprs: 112
; NumAgprs: 0
; TotalNumVgprs: 112
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 7
; VGPRBlocks: 13
; NumSGPRsForWavesPerEU: 59
; NumVGPRsForWavesPerEU: 112
; AccumOffset: 112
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 27
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
	.byte	1                               ; Abbrev [1] 0xb:0x44 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x1e DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	106                             ; DW_AT_call_line
	.byte	29                              ; DW_AT_call_column
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
	.quad	.Ltmp109-.Lfunc_begin0
	.quad	.Ltmp110-.Lfunc_begin0
	.quad	.Ltmp111-.Lfunc_begin0
	.quad	.Ltmp112-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.quad	.Ltmp114-.Lfunc_begin0
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp116-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"chunk_o.py"                    ; string offset=7
.Linfo_string2:
	.asciz	"/netra-server/python/sglang/srt/layers/attention/fla" ; string offset=18
.Linfo_string3:
	.asciz	"qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950"            ; string offset=71
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
      - .offset:         64
        .size:           4
        .value_kind:     by_value
      - .offset:         68
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
    .name:           qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     59
    .sgpr_spill_count: 0
    .symbol:         qwen36_gdn_chunk_o_m8192_bv64_oracle_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     112
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
