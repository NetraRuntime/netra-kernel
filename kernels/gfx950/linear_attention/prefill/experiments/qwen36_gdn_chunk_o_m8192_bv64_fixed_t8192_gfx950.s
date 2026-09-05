	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950              ; -- Begin function qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950
	.p2align	8
	.type	qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950,@function
qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950:                     ; @qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950
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
.Ltmp1:
	.loc	1 52 23 is_stmt 1               ; chunk_o.py:52:23
	s_ashr_i32 s1, s18, 31
	s_lshr_b32 s1, s1, 27
	s_mov_b64 s[28:29], s[2:3]
	s_add_i32 s1, s18, s1
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 43 17                         ; standard.py:43:17 @[ chunk_o.py:65:24 ]
	s_add_i32 s3, s15, 63
	s_mov_b64 s[36:37], s[6:7]
.Ltmp3:
	.loc	1 52 23                         ; chunk_o.py:52:23
	s_ashr_i32 s2, s1, 5
	.loc	1 52 33 is_stmt 0               ; chunk_o.py:52:33
	s_andn2_b32 s1, s1, 31
.Ltmp4:
	.loc	2 43 30 is_stmt 1               ; standard.py:43:30 @[ chunk_o.py:65:24 ]
	s_ashr_i32 s6, s3, 31
.Ltmp5:
	.loc	1 52 33                         ; chunk_o.py:52:33
	s_sub_i32 s1, s18, s1
.Ltmp6:
	.loc	2 43 30                         ; standard.py:43:30 @[ chunk_o.py:65:24 ]
	s_lshr_b32 s6, s6, 26
	s_add_i32 s3, s3, s6
.Ltmp7:
	.loc	1 70 29                         ; chunk_o.py:70:29
	s_bfe_u32 s6, s1, 0x10007
	s_add_i32 s6, s1, s6
.Ltmp8:
	.loc	2 43 30                         ; standard.py:43:30 @[ chunk_o.py:65:24 ]
	s_lshr_b32 s3, s3, 6
.Ltmp9:
	.loc	1 70 29                         ; chunk_o.py:70:29
	s_bfe_i32 s6, s6, 0x80000
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_readfirstlane_b32 s0, v0
	.loc	1 66 21                         ; chunk_o.py:66:21
	s_mul_i32 s3, s3, s2
	.loc	1 67 25                         ; chunk_o.py:67:25
	s_mul_i32 s2, s15, s2
	.loc	1 70 29                         ; chunk_o.py:70:29
	s_sext_i32_i16 s6, s6
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_and_b32 s43, s0, 0xc0
	.loc	1 70 41                         ; chunk_o.py:70:41
	s_lshl_b32 s6, s6, 6
	.loc	1 72 16                         ; chunk_o.py:72:16
	s_lshl_b32 s42, s2, 5
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_and_b32_e32 v16, 63, v0
	s_mov_b32 s26, s15
	.loc	1 66 26                         ; chunk_o.py:66:26
	s_add_i32 s3, s3, s17
	.loc	1 70 41                         ; chunk_o.py:70:41
	s_lshl_b32 s7, s2, 11
	s_and_b32 s6, s6, 0xffffff80
	.loc	1 72 20                         ; chunk_o.py:72:20
	s_add_i32 s42, s42, s1
	.loc	1 81 68                         ; chunk_o.py:81:68
	s_ashr_i32 s27, s15, 31
	.loc	1 87 38                         ; chunk_o.py:87:38
	s_lshl_b32 s15, s16, 6
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v1, s43, v16
	s_and_b32 s48, s0, 0x80
	s_and_b32 s49, s0, 64
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_lshl_b32 s0, s17, 18
	.loc	1 70 41                         ; chunk_o.py:70:41
	s_add_i32 s7, s7, s6
	.loc	1 72 27                         ; chunk_o.py:72:27
	s_lshl_b32 s2, s42, 7
	.loc	1 74 45                         ; chunk_o.py:74:45
	s_lshl_b32 s3, s3, 19
	s_lshl_b32 s1, s1, 14
	.loc	1 81 43                         ; chunk_o.py:81:43
	s_lshl_b32 s50, s17, 6
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshrrev_b32_e32 v17, 4, v1
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_add_i32 s47, s0, s15
	.loc	1 90 22                         ; chunk_o.py:90:22
	s_lshl_b32 s0, s17, 17
	.loc	1 74 45                         ; chunk_o.py:74:45
	s_add_i32 s52, s3, s1
	.loc	1 81 68                         ; chunk_o.py:81:68
	s_ashr_i32 s51, s50, 31
	.loc	1 87 63                         ; chunk_o.py:87:63
	s_ashr_i32 s33, s15, 31
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v18, 16, v17
	v_or_b32_e32 v20, 48, v17
	v_and_b32_e32 v65, 31, v0
	s_lshr_b32 s1, s48, 2
	s_lshr_b32 s46, s49, 1
	v_lshrrev_b32_e32 v66, 3, v1
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_add_i32 s47, s47, s2
	.loc	1 90 22                         ; chunk_o.py:90:22
	s_add_i32 s53, s0, s7
	v_or_b32_e32 v19, 32, v17
	v_or_b32_e32 v53, s1, v65
	v_or_b32_e32 v67, 32, v66
	v_or_b32_e32 v4, s50, v18
	v_mov_b32_e32 v5, s51
	v_or_b32_e32 v8, s50, v20
	v_mov_b32_e32 v9, s51
	s_cmp_gt_i32 s50, -1
	s_mov_b64 s[40:41], s[10:11]
	v_or_b32_e32 v2, s50, v17
	v_mov_b32_e32 v3, s51
	v_or_b32_e32 v6, s50, v19
	v_mov_b32_e32 v7, s51
	v_or_b32_e32 v10, s50, v53
	v_mov_b32_e32 v11, s51
	v_or_b32_e32 v12, s50, v66
	v_mov_b32_e32 v13, s51
	v_or_b32_e32 v14, s50, v67
	v_mov_b32_e32 v15, s51
	s_cselect_b64 s[44:45], -1, 0
	v_cmp_gt_i64_e64 s[0:1], s[26:27], v[4:5]
	v_cmp_gt_i64_e64 s[10:11], s[26:27], v[8:9]
	v_cmp_gt_i64_e32 vcc, s[26:27], v[2:3]
	v_cmp_gt_i64_e64 s[2:3], s[26:27], v[6:7]
	v_cmp_gt_i64_e64 s[20:21], s[26:27], v[10:11]
	v_cmp_gt_i64_e64 s[22:23], s[26:27], v[12:13]
	v_cmp_gt_i64_e64 s[24:25], s[26:27], v[14:15]
	s_and_b64 s[6:7], s[44:45], s[0:1]
	s_and_b64 s[0:1], s[44:45], s[10:11]
	.loc	1 94 22                         ; chunk_o.py:94:22
	s_lshl_b32 s10, s16, 13
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_and_b32_e32 v21, 15, v0
	s_and_b64 s[18:19], s[44:45], vcc
	s_and_b64 s[2:3], s[44:45], s[2:3]
	s_and_b64 vcc, s[44:45], s[20:21]
	s_and_b64 s[34:35], s[44:45], s[22:23]
	s_and_b64 s[38:39], s[44:45], s[24:25]
	s_and_b32 s29, s29, 0xffff
	.loc	1 92 22                         ; chunk_o.py:92:22
	s_and_b32 s5, s5, 0xffff
	.loc	1 94 22                         ; chunk_o.py:94:22
	s_add_i32 s10, s10, s52
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v22, 3, v21
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_or_b32_e32 v2, s15, v17
	v_mov_b32_e32 v3, s33
	v_lshlrev_b32_e32 v4, 7, v17
	v_lshlrev_b32_e32 v5, 7, v18
	v_lshlrev_b32_e32 v6, 7, v19
	v_lshlrev_b32_e32 v7, 7, v20
	s_cmp_gt_i32 s15, -1
	s_mov_b64 s[24:25], 0x80
	v_or3_b32 v4, s10, v4, v22
	v_or3_b32 v5, s10, v5, v22
	v_or3_b32 v6, s10, v6, v22
	v_or3_b32 v7, s10, v7, v22
	s_cselect_b64 s[22:23], -1, 0
	v_cmp_gt_i64_e64 s[10:11], s[24:25], v[2:3]
	s_mov_b32 s31, 0x27000
	s_mov_b32 s30, 0x7ffffffe
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bfrev_b32_e32 v52, 1
	.loc	1 94 22                         ; chunk_o.py:94:22
	s_and_b64 s[20:21], s[22:23], s[10:11]
	v_lshlrev_b32_e32 v2, 1, v4
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s30
	s_mov_b32 s11, s31
	v_cndmask_b32_e64 v2, v52, v2, s[20:21]
	buffer_load_dwordx4 v[10:13], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v5
	v_cndmask_b32_e64 v2, v52, v2, s[20:21]
	buffer_load_dwordx4 v[24:27], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v6
	v_cndmask_b32_e64 v2, v52, v2, s[20:21]
	buffer_load_dwordx4 v[28:31], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v7
	v_cndmask_b32_e64 v2, v52, v2, s[20:21]
	buffer_load_dwordx4 v[32:35], v2, s[8:11], 0 offen
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v2, 11, v17
	v_lshlrev_b32_e32 v3, 11, v18
	v_lshlrev_b32_e32 v4, 11, v19
	v_lshlrev_b32_e32 v5, 11, v20
	v_or_b32_e32 v6, s53, v22
	v_add_lshl_u32 v2, v6, v2, 1
	v_add_lshl_u32 v3, v6, v3, 1
	v_add_lshl_u32 v4, v6, v4, 1
	v_add_lshl_u32 v5, v6, v5, 1
	v_cndmask_b32_e64 v2, v52, v2, s[18:19]
	v_cndmask_b32_e64 v3, v52, v3, s[6:7]
	v_cndmask_b32_e64 v4, v52, v4, s[2:3]
	v_cndmask_b32_e64 v5, v52, v5, s[0:1]
	.loc	1 92 22                         ; chunk_o.py:92:22
	s_mov_b32 s6, s30
	s_mov_b32 s7, s31
	.loc	1 90 22                         ; chunk_o.py:90:22
	buffer_load_dwordx4 v[36:39], v2, s[28:31], 0 offen
	buffer_load_dwordx4 v[40:43], v3, s[28:31], 0 offen
	buffer_load_dwordx4 v[44:47], v4, s[28:31], 0 offen
	buffer_load_dwordx4 v[48:51], v5, s[28:31], 0 offen
	.loc	1 92 22                         ; chunk_o.py:92:22
	buffer_load_dwordx4 v[58:61], v2, s[4:7], 0 offen
	buffer_load_dwordx4 v[68:71], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[72:75], v4, s[4:7], 0 offen
	buffer_load_dwordx4 v[76:79], v5, s[4:7], 0 offen
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_mov_b32_e32 v2, 0xe0
	v_bitop3_b32 v2, s43, v2, v16 bitop3:0xc8
	v_and_b32_e32 v4, 14, v0
	v_lshlrev_b32_e32 v3, 4, v2
	v_lshlrev_b32_e32 v5, 3, v4
	v_lshrrev_b32_e32 v2, 1, v2
	v_and_b32_e32 v7, 1, v0
	v_and_b32_e32 v57, 16, v0
	v_lshlrev_b32_e32 v8, 9, v57
	v_bitop3_b32 v2, v3, v2, v5 bitop3:0x36
	v_lshl_add_u32 v3, v7, 12, 0
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_and_b32_e32 v54, 32, v0
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_add3_u32 v2, v3, v8, v2
	v_lshlrev_b32_e32 v3, 13, v7
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v55, 3, v0
	.loc	1 97 36                         ; chunk_o.py:97:36
	v_lshlrev_b32_e32 v5, 7, v54
	s_lshl_b32 s0, s49, 2
	v_lshl_or_b32 v3, v4, 8, v3
	s_waitcnt vmcnt(11)
	ds_write_b128 v2, v[10:13]
	s_waitcnt vmcnt(10)
	ds_write_b128 v2, v[24:27] offset:128
	s_waitcnt vmcnt(9)
	ds_write_b128 v2, v[28:31] offset:256
	s_waitcnt vmcnt(8)
	ds_write_b128 v2, v[32:35] offset:384
	v_and_b32_e32 v2, 0xf0, v55
	v_or3_b32 v3, s0, v5, v3
	v_or_b32_e32 v4, v3, v2
	v_add_u32_e32 v5, 0, v4
	s_movk_i32 s0, 0x50
	s_movk_i32 s1, 0x70
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshlrev_b32_e32 v19, 8, v65
	v_lshlrev_b32_e32 v20, 4, v21
	v_lshrrev_b32_e32 v21, 1, v54
	v_mov_b32_e32 v6, 0xf0
	v_lshl_or_b32 v22, s48, 6, v19
	v_xor_b32_e32 v23, v20, v21
	v_bitop3_b32 v6, s43, v6, v16 bitop3:0xc8
	v_lshlrev_b32_e32 v56, 4, v1
	v_or_b32_e32 v24, v22, v23
	v_xad_u32 v18, v56, v6, 0
	v_xad_u32 v25, v24, 32, 0
	s_movk_i32 s8, 0x80
	s_movk_i32 s2, 0xc0
	s_movk_i32 s3, 0xe0
	v_mov_b32_e32 v63, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_and_b32 s41, s41, 0xffff
	s_mov_b32 s43, s31
	s_mov_b32 s9, 0xc2fc0000
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_and_b32 s37, s37, 0xffff
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_and_b32 s13, s13, 0xffff
	.loc	1 97 36                         ; chunk_o.py:97:36
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[26:29], v5
	v_xad_u32 v5, v4, 16, 0
	ds_read_b128 v[30:33], v5
	v_xad_u32 v5, v4, 32, 0
	ds_read_b128 v[80:83], v5
	v_xad_u32 v5, v4, 48, 0
	v_xad_u32 v4, v4, 64, 0
	ds_read_b128 v[84:87], v5
	ds_read_b128 v[88:91], v4
	v_bitop3_b32 v4, v3, s0, v2 bitop3:0x36
	v_add_u32_e32 v4, 0, v4
	s_movk_i32 s0, 0x60
	ds_read_b128 v[92:95], v4
	v_bitop3_b32 v4, v3, s0, v2 bitop3:0x36
	v_bitop3_b32 v2, v3, s1, v2 bitop3:0x36
	v_add_u32_e32 v4, 0, v4
	v_add_u32_e32 v2, 0, v2
	ds_read_b128 v[96:99], v4
	ds_read_b128 v[100:103], v2
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_add_u32_e32 v2, 0, v24
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(7)
	ds_write_b128 v18, v[36:39]
	s_waitcnt vmcnt(6)
	ds_write_b128 v18, v[40:43] offset:4096
	s_waitcnt vmcnt(5)
	ds_write_b128 v18, v[44:47] offset:8192
	s_waitcnt vmcnt(4)
	ds_write_b128 v18, v[48:51] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[34:37], v2
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[26:29], v[34:37], 0
	.loc	1 90 22                         ; chunk_o.py:90:22
	ds_read_b128 v[26:29], v25
	v_xad_u32 v24, v24, 64, 0
	s_movk_i32 s1, 0xa0
	v_mov_b32_e32 v51, s51
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[30:33], v[26:29], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[80:83], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s0, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[84:87], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s8, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[88:91], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s1, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[92:95], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bitop3_b32 v24, v22, s2, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[24:27], v24
	v_bitop3_b32 v22, v22, s3, v23 bitop3:0x36
	v_add_u32_e32 v22, 0, v22
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[96:99], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	ds_read_b128 v[24:27], v22
	v_lshl_or_b32 v22, s49, 7, v19
	.loc	1 97 27                         ; chunk_o.py:97:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[100:103], v[24:27], v[2:17]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v24, v22, v23
	v_add_u32_e32 v25, 0, v24
	ds_read_b128 v[80:83], v25
	v_xad_u32 v25, v24, 32, 0
	v_xad_u32 v24, v24, 64, 0
	ds_read_b128 v[84:87], v25
	ds_read_b128 v[88:91], v24
	v_bitop3_b32 v24, v22, s0, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[92:95], v24
	v_bitop3_b32 v24, v22, s8, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[96:99], v24
	v_bitop3_b32 v24, v22, s1, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	ds_read_b128 v[100:103], v24
	v_bitop3_b32 v24, v22, s2, v23 bitop3:0x36
	v_bitop3_b32 v22, v22, s3, v23 bitop3:0x36
	v_add_u32_e32 v24, 0, v24
	v_add_u32_e32 v22, 0, v22
	ds_read_b128 v[104:107], v24
	ds_read_b128 v[108:111], v22
	.loc	1 92 22                         ; chunk_o.py:92:22
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(3)
	ds_write_b128 v18, v[58:61]
	s_waitcnt vmcnt(2)
	ds_write_b128 v18, v[68:71] offset:4096
	s_waitcnt vmcnt(1)
	ds_write_b128 v18, v[72:75] offset:8192
	s_waitcnt vmcnt(0)
	ds_write_b128 v18, v[76:79] offset:12288
	v_bitop3_b32 v18, v19, v21, v20 bitop3:0x36
	v_add_u32_e32 v19, 0, v18
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[22:25], v19
	v_xad_u32 v20, v18, 32, 0
	ds_read_b128 v[112:115], v20 offset:8192
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[80:83], 0
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v20
	v_xad_u32 v58, v18, 64, 0
	v_xor_b32_e32 v21, 0x60, v18
	v_add_u32_e32 v61, 0, v21
	v_xor_b32_e32 v21, 0x80, v18
	v_add_u32_e32 v64, 0, v21
	v_xor_b32_e32 v21, 0xa0, v18
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[84:87], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v58
	v_add_u32_e32 v68, 0, v21
	v_xor_b32_e32 v21, 0xc0, v18
	v_add_u32_e32 v69, 0, v21
	v_xor_b32_e32 v18, 0xe0, v18
	v_add_u32_e32 v70, 0, v18
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v59, s46, v65
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[88:91], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v61
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshrrev_b32_e32 v60, 3, v54
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_lshl_b32 s0, s17, 11
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v50, s50, v59
	v_or_b32_e32 v62, s50, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_add_i32 s11, s42, s0
	v_lshlrev_b32_e32 v71, 5, v59
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[92:95], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v64
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cmp_gt_i64_e64 s[0:1], s[26:27], v[50:51]
	v_cmp_gt_i64_e64 s[2:3], s[26:27], v[62:63]
	s_lshl_b32 s10, s11, 2
	s_and_b64 s[0:1], s[44:45], s[0:1]
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_add_lshl_u32 v50, s11, v71, 2
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[96:99], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v68
	.loc	1 104 22                        ; chunk_o.py:104:22
	s_mov_b32 s42, s30
	v_cndmask_b32_e64 v50, v52, v50, s[0:1]
	buffer_load_dword v76, v50, s[40:43], 0 offen
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_mov_b32_e32 v63, 0x42800000
	v_not_b32_e32 v62, 63
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_mov_b32_e32 v51, s33
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[100:103], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v69
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[104:107], v[34:49]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[22:25], v70
	ds_read_b128 v[72:75], v19 offset:8192
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[22:25], v[108:111], v[34:49]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[72:75], v[80:83], 0
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[78:81], v58 offset:8192
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshlrev_b32_e32 v72, 2, v54
	v_add_lshl_u32 v72, s11, v72, 2
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v74, 2, v60
	v_or_b32_e32 v73, 3, v60
	v_and_b32_e32 v75, 56, v55
	.loc	1 99 27                         ; chunk_o.py:99:27
	v_mfma_f32_32x32x16_bf16 v[18:33], v[112:115], v[84:87], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[84:87], v70 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v70, 9, v60
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[78:81], v[88:91], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[78:81], v61 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_bfe_i32 v61, v0, 5, 1
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[78:81], v[92:95], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[80:83], v64 offset:8192
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v79, 8, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v58, v79, 7, s10
	v_cndmask_b32_e64 v58, v52, v58, s[2:3]
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[80:83], v[96:99], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[80:83], v68 offset:8192
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[80:83], v[100:103], v[18:33]
	.loc	1 92 22                         ; chunk_o.py:92:22
	ds_read_b128 v[80:83], v69 offset:8192
	.loc	1 99 27                         ; chunk_o.py:99:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[80:83], v[104:107], v[18:33]
	.loc	1 104 22                        ; chunk_o.py:104:22
	buffer_load_dword v80, v58, s[40:43], 0 offen
	v_cndmask_b32_e64 v50, v52, v72, s[2:3]
	buffer_load_dword v71, v50, s[40:43], 0 offen
	v_lshl_add_u32 v58, v70, 7, s10
	v_cndmask_b32_e64 v58, v52, v58, s[2:3]
	buffer_load_dword v81, v58, s[40:43], 0 offen
	v_add_u32_e32 v50, 0x80, v72
	v_cndmask_b32_e64 v50, v52, v50, s[2:3]
	buffer_load_dword v72, v50, s[40:43], 0 offen
.Ltmp10:
	.file	3 "/netra-server/python/sglang/srt/layers/attention/fla" "op.py"
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_mov_b32_e32 v82, 0xff800000
.Ltmp11:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v50, v74, 7, s10
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v83, 11, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v50, v52, v50, s[2:3]
	buffer_load_dword v77, v50, s[40:43], 0 offen
	.loc	1 99 27                         ; chunk_o.py:99:27
	v_mfma_f32_32x32x16_bf16 v[18:33], v[84:87], v[108:111], v[18:33]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v85, 16, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshlrev_b32_e32 v58, 5, v53
	v_lshlrev_b32_e32 v86, 5, v85
	v_add_lshl_u32 v58, s11, v58, 2
	v_cndmask_b32_e32 v58, v52, v58, vcc
	buffer_load_dword v58, v58, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v64, v76, v71
.Ltmp12:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[0:1], 0, v64
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v64, 0x3fb8aa3b, v64
.Ltmp13:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v71, 10, v60
.Ltmp14:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v64, v82, v64, s[0:1]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[0:1], s9, v64
	s_nop 1
	v_cndmask_b32_e64 v68, 0, v63, s[0:1]
	v_add_f32_e32 v64, v64, v68
	v_exp_f32_e32 v64, v64
.Ltmp15:
	.loc	1 106 44 is_stmt 1              ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v68, v76, v72
.Ltmp16:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v68
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v68, 0x3fb8aa3b, v68
	v_cndmask_b32_e64 v69, 0, v62, s[0:1]
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v68, v82, v68, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[0:1], s9, v68
	v_ldexp_f32 v64, v64, v69
.Ltmp17:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v72, v71, 7, s10
.Ltmp18:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v63, s[0:1]
	v_add_f32_e32 v68, v68, v69
	v_exp_f32_e32 v68, v68
	v_cndmask_b32_e64 v69, 0, v62, s[0:1]
.Ltmp19:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_mul_f32_e32 v64, v34, v64
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v72, v52, v72, s[2:3]
.Ltmp20:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_ldexp_f32 v68, v68, v69
.Ltmp21:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_mul_f32_e32 v34, v35, v68
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v35, v83, 7, s10
	v_cndmask_b32_e64 v35, v52, v35, s[2:3]
	buffer_load_dword v72, v72, s[40:43], 0 offen
	.loc	1 109 26                        ; chunk_o.py:109:26
	v_cmp_gt_u32_e64 s[0:1], v59, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	buffer_load_dword v84, v35, s[40:43], 0 offen
	v_lshl_add_u32 v50, v73, 7, s10
	v_cndmask_b32_e64 v50, v52, v50, s[2:3]
	buffer_load_dword v78, v50, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v35, v76, v77
.Ltmp22:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v35
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
.Ltmp23:
	.loc	1 94 22 is_stmt 1               ; chunk_o.py:94:22
	v_or_b32_e32 v50, s15, v75
.Ltmp24:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v35, v82, v35, s[2:3]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s9, v35
.Ltmp25:
	.loc	1 122 38 is_stmt 1              ; chunk_o.py:122:38
	v_cvt_pk_bf16_f32 v64, v64, s0
	v_cvt_pk_bf16_f32 v34, v34, s0
.Ltmp26:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v63, s[6:7]
	v_add_f32_e32 v35, v35, v69
.Ltmp27:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_mov_b32_e32 v69, s51
.Ltmp28:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v35, v35
.Ltmp29:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v34, 0, v34, s[0:1]
	s_movk_i32 s1, 0x108
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v68, v76, v78
.Ltmp30:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v68
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v68, 0x3fb8aa3b, v68
.Ltmp31:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v78, 17, v60
.Ltmp32:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v77, v82, v68, s[4:5]
.Ltmp33:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v68, s50, v85
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cmp_gt_i64_e64 s[2:3], s[26:27], v[68:69]
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_add_lshl_u32 v68, s11, v86, 2
	v_cndmask_b32_e64 v68, v52, v68, s[2:3]
	buffer_load_dword v86, v68, s[40:43], 0 offen
	v_lshl_add_u32 v68, v78, 7, s10
	v_cndmask_b32_e64 v68, v52, v68, s[2:3]
	buffer_load_dword v87, v68, s[40:43], 0 offen
.Ltmp34:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v77
	s_nop 1
	v_cndmask_b32_e64 v68, 0, v63, s[4:5]
	v_add_f32_e32 v68, v77, v68
	v_exp_f32_e32 v69, v68
	v_cndmask_b32_e64 v68, 0, v62, s[6:7]
	v_ldexp_f32 v68, v35, v68
	v_cndmask_b32_e64 v35, 0, v62, s[4:5]
	v_ldexp_f32 v69, v69, v35
.Ltmp35:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[36:37], v[36:37], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v73
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v73, 19, v60
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v68, v76, v81
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v35, 0, v37, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v74
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v37, v76, v80
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v74, 18, v60
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v36, 0, v36, s[4:5]
.Ltmp36:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v37
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v37, 0x3fb8aa3b, v37
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v68
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v37, v82, v37, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v37
	v_mul_f32_e32 v68, 0x3fb8aa3b, v68
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v68, v82, v68, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v37, v37, v69
.Ltmp37:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v69, v74, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v77, v69, s[40:43], 0 offen
	v_lshl_add_u32 v69, v73, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v80, v69, s[40:43], 0 offen
.Ltmp38:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s9, v68
	v_exp_f32_e32 v37, v37
	s_nop 0
	v_cndmask_b32_e64 v69, 0, v63, s[6:7]
	v_add_f32_e32 v68, v68, v69
	v_exp_f32_e32 v69, v68
	v_cndmask_b32_e64 v68, 0, v62, s[4:5]
	v_ldexp_f32 v68, v37, v68
	v_cndmask_b32_e64 v37, 0, v62, s[6:7]
	v_ldexp_f32 v69, v69, v37
.Ltmp39:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[38:39], v[38:39], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v70
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v69, v76, v84
.Ltmp40:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v69
.Ltmp41:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v37, 0, v39, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v79
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v39, v76, v72
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v72, 24, v60
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v38, 0, v38, s[4:5]
.Ltmp42:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v39
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v39, 0x3fb8aa3b, v39
.Ltmp43:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v70, 25, v60
.Ltmp44:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v39, v82, v39, s[4:5]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v39
	s_nop 1
	v_cndmask_b32_e64 v68, 0, v63, s[4:5]
	v_add_f32_e32 v39, v39, v68
	v_exp_f32_e32 v39, v39
	v_cndmask_b32_e64 v68, 0, v62, s[4:5]
	v_ldexp_f32 v68, v39, v68
	v_mul_f32_e32 v39, 0x3fb8aa3b, v69
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v39, v82, v39, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v39
	s_nop 1
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v39, v39, v69
.Ltmp45:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v69, v72, 7, s10
.Ltmp46:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v39, v39
.Ltmp47:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v79, v69, s[40:43], 0 offen
	v_lshl_add_u32 v69, v70, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v81, v69, s[40:43], 0 offen
.Ltmp48:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v62, s[4:5]
	v_ldexp_f32 v69, v39, v69
.Ltmp49:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[40:41], v[40:41], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v83
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v68, v76, v87
.Ltmp50:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v68
.Ltmp51:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v39, 0, v41, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v71
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v41, v76, v86
.Ltmp52:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v68, 0x3fb8aa3b, v68
.Ltmp53:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v40, 0, v40, s[4:5]
.Ltmp54:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v41
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v41, 0x3fb8aa3b, v41
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v68, v82, v68, s[6:7]
	v_cndmask_b32_e64 v41, v82, v41, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v41
	v_cmp_gt_f32_e64 s[6:7], s9, v68
.Ltmp55:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v71, 26, v60
.Ltmp56:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v41, v41, v69
	v_cndmask_b32_e64 v69, 0, v63, s[6:7]
	v_exp_f32_e32 v41, v41
	v_add_f32_e32 v68, v68, v69
	v_exp_f32_e32 v69, v68
	v_cndmask_b32_e64 v68, 0, v62, s[4:5]
	v_ldexp_f32 v68, v41, v68
	v_cndmask_b32_e64 v41, 0, v62, s[6:7]
	v_ldexp_f32 v69, v69, v41
.Ltmp57:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v41, v71, 7, s10
	v_cndmask_b32_e64 v41, v52, v41, s[2:3]
	buffer_load_dword v83, v41, s[40:43], 0 offen
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[42:43], v[42:43], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v78
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v78, 27, v60
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v68, v76, v80
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v41, 0, v43, s[4:5]
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v43, v78, 7, s10
	v_cndmask_b32_e64 v43, v52, v43, s[2:3]
	buffer_load_dword v84, v43, s[40:43], 0 offen
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v43, v76, v77
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v85
.Ltmp58:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v43
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v43, 0x3fb8aa3b, v43
.Ltmp59:
	.loc	1 110 29 is_stmt 1              ; chunk_o.py:110:29
	v_cndmask_b32_e64 v42, 0, v42, s[4:5]
.Ltmp60:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v68
	.loc	3 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v43, v82, v43, s[2:3]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v68, 0x3fb8aa3b, v68
	v_cmp_gt_f32_e64 s[6:7], s9, v43
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v68, v82, v68, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v68
	v_cndmask_b32_e64 v69, 0, v63, s[6:7]
	v_add_f32_e32 v43, v43, v69
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v68, v68, v69
.Ltmp61:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v80, 32, v60
.Ltmp62:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v77, v68
.Ltmp63:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v68, s50, v80
	v_mov_b32_e32 v69, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshlrev_b32_e32 v85, 5, v80
	v_cmp_gt_i64_e64 s[2:3], s[26:27], v[68:69]
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_add_lshl_u32 v68, s11, v85, 2
	v_cndmask_b32_e64 v68, v52, v68, s[2:3]
	buffer_load_dword v85, v68, s[40:43], 0 offen
.Ltmp64:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v43, v43
	v_cndmask_b32_e64 v68, 0, v62, s[6:7]
	v_ldexp_f32 v68, v43, v68
	v_cndmask_b32_e64 v43, 0, v62, s[4:5]
	v_ldexp_f32 v69, v77, v43
.Ltmp65:
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v77, 33, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v43, v77, 7, s10
	v_cndmask_b32_e64 v43, v52, v43, s[2:3]
	buffer_load_dword v86, v43, s[40:43], 0 offen
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[44:45], v[44:45], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v73
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v73, 35, v60
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v68, v76, v81
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v43, 0, v45, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v74
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v45, v76, v79
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v74, 34, v60
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v44, 0, v44, s[4:5]
.Ltmp66:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v45
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v45, 0x3fb8aa3b, v45
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v68
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v45, v82, v45, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v45
	v_mul_f32_e32 v68, 0x3fb8aa3b, v68
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v68, v82, v68, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v45, v45, v69
.Ltmp67:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v69, v74, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v79, v69, s[40:43], 0 offen
	v_lshl_add_u32 v69, v73, 7, s10
.Ltmp68:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s9, v68
.Ltmp69:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v81, v69, s[40:43], 0 offen
.Ltmp70:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v63, s[6:7]
	v_exp_f32_e32 v45, v45
	v_add_f32_e32 v68, v68, v69
	v_exp_f32_e32 v69, v68
	v_cndmask_b32_e64 v68, 0, v62, s[4:5]
	v_ldexp_f32 v68, v45, v68
	v_cndmask_b32_e64 v45, 0, v62, s[6:7]
	v_ldexp_f32 v69, v69, v45
.Ltmp71:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[46:47], v[46:47], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v70
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v69, v76, v84
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v45, 0, v47, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v72
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v47, v76, v83
.Ltmp72:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v69
.Ltmp73:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v46, 0, v46, s[4:5]
.Ltmp74:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v47
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v47, 0x3fb8aa3b, v47
.Ltmp75:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v83, 40, v60
.Ltmp76:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v47, v82, v47, s[4:5]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v47
.Ltmp77:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v72, 41, v60
.Ltmp78:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	s_nop 0
	v_cndmask_b32_e64 v68, 0, v63, s[4:5]
	v_add_f32_e32 v47, v47, v68
	v_exp_f32_e32 v47, v47
	v_cndmask_b32_e64 v68, 0, v62, s[4:5]
	v_ldexp_f32 v68, v47, v68
	v_mul_f32_e32 v47, 0x3fb8aa3b, v69
	.loc	3 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v47, v82, v47, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v47
	s_nop 1
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v47, v47, v69
.Ltmp79:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v69, v83, 7, s10
.Ltmp80:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v47, v47
.Ltmp81:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v84, v69, s[40:43], 0 offen
	v_lshl_add_u32 v69, v72, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v87, v69, s[40:43], 0 offen
.Ltmp82:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v69, 0, v62, s[4:5]
	v_ldexp_f32 v69, v47, v69
.Ltmp83:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[48:49], v[48:49], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v78
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v69, v76, v86
.Ltmp84:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v69
.Ltmp85:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v47, 0, v49, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v71
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v49, v76, v85
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v85, 42, v60
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v48, 0, v48, s[4:5]
.Ltmp86:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v49
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v49, 0x3fb8aa3b, v49
.Ltmp87:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v78, 43, v60
.Ltmp88:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v49, v82, v49, s[4:5]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v49
	s_nop 1
	v_cndmask_b32_e64 v68, 0, v63, s[4:5]
	v_add_f32_e32 v49, v49, v68
	v_exp_f32_e32 v49, v49
	v_cndmask_b32_e64 v68, 0, v62, s[4:5]
	v_ldexp_f32 v68, v49, v68
	v_mul_f32_e32 v49, 0x3fb8aa3b, v69
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v49, v82, v49, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v49
	s_nop 1
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_add_f32_e32 v49, v49, v69
.Ltmp89:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v69, v85, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v86, v69, s[40:43], 0 offen
	v_lshl_add_u32 v69, v78, 7, s10
	v_cndmask_b32_e64 v69, v52, v69, s[2:3]
	buffer_load_dword v88, v69, s[40:43], 0 offen
.Ltmp90:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_exp_f32_e32 v49, v49
	v_cndmask_b32_e64 v69, 0, v62, s[4:5]
.Ltmp91:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v77
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v77, 49, v60
.Ltmp92:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_ldexp_f32 v69, v49, v69
.Ltmp93:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[18:19], v[68:69]
	.loc	1 110 29                        ; chunk_o.py:110:29
	s_nop 0
	v_cndmask_b32_e64 v49, 0, v19, s[2:3]
	v_cmp_ge_u32_e64 s[2:3], v59, v80
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v19, v76, v81
.Ltmp94:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v19
.Ltmp95:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v68, 0, v18, s[2:3]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v76, v79
.Ltmp96:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[2:3]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[2:3], s9, v18
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v19
	v_cndmask_b32_e64 v69, 0, v63, s[2:3]
	v_add_f32_e32 v18, v18, v69
	v_cndmask_b32_e64 v69, 0, v63, s[4:5]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v69
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v69, 0, v62, s[2:3]
	v_ldexp_f32 v18, v18, v69
	v_cndmask_b32_e64 v69, 0, v62, s[4:5]
	v_ldexp_f32 v19, v19, v69
.Ltmp97:
	.loc	1 90 22 is_stmt 1               ; chunk_o.py:90:22
	v_or_b32_e32 v79, 48, v60
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[20:21], v[18:19]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v20, s50, v79
	v_mov_b32_e32 v21, s51
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshlrev_b32_e32 v69, 5, v79
	v_cmp_gt_i64_e64 s[2:3], s[26:27], v[20:21]
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_add_lshl_u32 v20, s11, v69, 2
	v_cndmask_b32_e64 v20, v52, v20, s[2:3]
	v_lshl_add_u32 v21, v77, 7, s10
	buffer_load_dword v20, v20, s[40:43], 0 offen
	v_cndmask_b32_e64 v21, v52, v21, s[2:3]
	buffer_load_dword v21, v21, s[40:43], 0 offen
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v73
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v81, 50, v60
	v_or_b32_e32 v80, 51, v60
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v69, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v74
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v19, v76, v87
.Ltmp98:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp99:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v70, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v76, v84
.Ltmp100:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v18
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s9, v19
	v_cndmask_b32_e64 v71, 0, v63, s[4:5]
	v_add_f32_e32 v18, v18, v71
.Ltmp101:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	v_lshl_add_u32 v71, v81, 7, s10
	v_cndmask_b32_e64 v71, v52, v71, s[2:3]
	buffer_load_dword v84, v71, s[40:43], 0 offen
	v_lshl_add_u32 v71, v80, 7, s10
	v_cndmask_b32_e64 v71, v52, v71, s[2:3]
	buffer_load_dword v87, v71, s[40:43], 0 offen
.Ltmp102:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v71, 0, v63, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v71
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v71, 0, v62, s[4:5]
	v_ldexp_f32 v18, v18, v71
	v_cndmask_b32_e64 v71, 0, v62, s[6:7]
	v_ldexp_f32 v19, v19, v71
.Ltmp103:
	.loc	1 106 20                        ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[22:23], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v72
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v23, 56, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v73, v23, 7, s10
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v71, 0, v19, s[4:5]
	v_cmp_ge_u32_e64 s[4:5], v59, v83
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v22, 57, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v73, v52, v73, s[2:3]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v72, 0, v18, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(5)
	v_sub_f32_e32 v18, v76, v86
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v19, v76, v88
.Ltmp104:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
.Ltmp105:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	buffer_load_dword v83, v73, s[40:43], 0 offen
	v_lshl_add_u32 v73, v22, 7, s10
.Ltmp106:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[6:7], 0, v19
.Ltmp107:
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v73, v52, v73, s[2:3]
.Ltmp108:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[4:5]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
.Ltmp109:
	.loc	1 104 22 is_stmt 1              ; chunk_o.py:104:22
	buffer_load_dword v86, v73, s[40:43], 0 offen
.Ltmp110:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v18
	.loc	3 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[6:7]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[6:7], s9, v19
	v_cndmask_b32_e64 v73, 0, v63, s[4:5]
	v_add_f32_e32 v18, v18, v73
	v_cndmask_b32_e64 v73, 0, v63, s[6:7]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v73
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v73, 0, v62, s[4:5]
	v_ldexp_f32 v18, v18, v73
	v_cndmask_b32_e64 v73, 0, v62, s[6:7]
	v_ldexp_f32 v19, v19, v73
.Ltmp111:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[24:25], v[18:19]
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v25, 58, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_lshl_add_u32 v73, v25, 7, s10
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v24, 59, v60
	.loc	1 104 22                        ; chunk_o.py:104:22
	v_cndmask_b32_e64 v73, v52, v73, s[2:3]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[4:5], v59, v78
	.loc	1 104 22                        ; chunk_o.py:104:22
	buffer_load_dword v78, v73, s[40:43], 0 offen
	v_lshl_add_u32 v73, v24, 7, s10
	v_cndmask_b32_e64 v73, v52, v73, s[2:3]
	buffer_load_dword v88, v73, s[40:43], 0 offen
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v85
	v_cndmask_b32_e64 v73, 0, v19, s[4:5]
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(6)
	v_sub_f32_e32 v19, v76, v21
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v74, 0, v18, s[2:3]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v76, v20
.Ltmp112:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v19
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[2:3]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	v_cmp_gt_f32_e64 s[2:3], s9, v18
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v19
	v_cndmask_b32_e64 v20, 0, v63, s[2:3]
	v_add_f32_e32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v63, s[4:5]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v20
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v20, 0, v62, s[2:3]
	v_ldexp_f32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v62, s[4:5]
	v_ldexp_f32 v19, v19, v20
.Ltmp113:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[26:27], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v77
	s_nop 1
	v_cndmask_b32_e64 v26, 0, v19, s[2:3]
	v_cmp_ge_u32_e64 s[2:3], v59, v79
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v19, v76, v87
.Ltmp114:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v19
.Ltmp115:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v27, 0, v18, s[2:3]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v76, v84
.Ltmp116:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[2:3]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[2:3], s9, v18
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v19
	v_cndmask_b32_e64 v20, 0, v63, s[2:3]
	v_add_f32_e32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v63, s[4:5]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v20
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v20, 0, v62, s[2:3]
	v_ldexp_f32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v62, s[4:5]
	v_ldexp_f32 v19, v19, v20
.Ltmp117:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[28:29], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v80
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_cvt_pk_bf16_f32 v27, v27, s0
	v_cvt_pk_bf16_f32 v26, v26, s0
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v28, 0, v19, s[2:3]
	v_cmp_ge_u32_e64 s[2:3], v59, v81
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v19, v76, v86
.Ltmp118:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v19
.Ltmp119:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v29, 0, v18, s[2:3]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v76, v83
.Ltmp120:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[2:3]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[2:3], s9, v18
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v19
	v_cndmask_b32_e64 v20, 0, v63, s[2:3]
	v_add_f32_e32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v63, s[4:5]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v20
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v20, 0, v62, s[2:3]
	v_ldexp_f32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v62, s[4:5]
	v_ldexp_f32 v19, v19, v20
.Ltmp121:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[30:31], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v22
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_lshlrev_b32_e32 v22, 12, v67
	.loc	1 110 29                        ; chunk_o.py:110:29
	s_nop 0
	v_cndmask_b32_e64 v30, 0, v19, s[2:3]
	v_cmp_ge_u32_e64 s[2:3], v59, v23
	.loc	1 106 44                        ; chunk_o.py:106:44
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v19, v76, v88
.Ltmp122:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[4:5], 0, v19
.Ltmp123:
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v31, 0, v18, s[2:3]
	.loc	1 106 44                        ; chunk_o.py:106:44
	v_sub_f32_e32 v18, v76, v78
.Ltmp124:
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_o.py:106:29 ]
	v_cmp_ge_f32_e64 s[2:3], 0, v18
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_mul_f32_e32 v18, 0x3fb8aa3b, v18
	v_mul_f32_e32 v19, 0x3fb8aa3b, v19
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v18, v82, v18, s[2:3]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[2:3], s9, v18
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_o.py:106:29 ]
	v_cndmask_b32_e64 v19, v82, v19, s[4:5]
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_o.py:106:29 ]
	v_cmp_gt_f32_e64 s[4:5], s9, v19
	v_cndmask_b32_e64 v20, 0, v63, s[2:3]
	v_add_f32_e32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v63, s[4:5]
	v_exp_f32_e32 v18, v18
	v_add_f32_e32 v19, v19, v20
	v_exp_f32_e32 v19, v19
	v_cndmask_b32_e64 v20, 0, v62, s[2:3]
	v_ldexp_f32 v18, v18, v20
	v_cndmask_b32_e64 v20, 0, v62, s[4:5]
	v_ldexp_f32 v19, v19, v20
.Ltmp125:
	.loc	1 106 20 is_stmt 1              ; chunk_o.py:106:20
	v_pk_mul_f32 v[18:19], v[32:33], v[18:19]
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v24
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_or_b32_e32 v23, s47, v75
	v_add_lshl_u32 v22, v23, v22, 1
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v32, 0, v19, s[2:3]
	v_cmp_ge_u32_e64 s[2:3], v59, v25
	s_nop 1
	v_cndmask_b32_e64 v33, 0, v18, s[2:3]
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_cmp_gt_i64_e64 s[2:3], s[24:25], v[50:51]
	v_lshlrev_b32_e32 v18, 12, v66
	s_and_b64 s[4:5], s[22:23], s[2:3]
	s_and_b64 s[2:3], s[4:5], s[34:35]
	s_and_b64 s[4:5], s[4:5], s[38:39]
	v_add_lshl_u32 v18, v23, v18, 1
	s_mov_b32 s38, s30
	s_mov_b32 s39, s31
	v_cndmask_b32_e64 v18, v52, v18, s[2:3]
	v_cndmask_b32_e64 v22, v52, v22, s[4:5]
	buffer_load_dwordx4 v[18:21], v18, s[36:39], 0 offen
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_lshlrev_b32_e32 v50, 1, v65
	.loc	1 118 18                        ; chunk_o.py:118:18
	buffer_load_dwordx4 v[22:25], v22, s[36:39], 0 offen
	s_movk_i32 s2, 0x210
	.loc	1 122 38                        ; chunk_o.py:122:38
	v_bitop3_b32 v50, v61, v50, s2 bitop3:0x6c
	v_or_b32_e32 v50, s49, v50
	v_and_b32_e32 v51, 0x210, v61
	v_add_u32_e32 v61, 0, v50
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cmp_ge_u32_e64 s[2:3], v59, v60
	.loc	1 122 38                        ; chunk_o.py:122:38
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 110 29                        ; chunk_o.py:110:29
	v_cndmask_b32_e64 v59, 0, v64, s[2:3]
	.loc	1 122 38                        ; chunk_o.py:122:38
	ds_write_b16 v61, v27 offset:6144
	ds_write_b16 v61, v26 offset:6272
	v_xad_u32 v26, v50, 8, 0
	v_cvt_pk_bf16_f32 v27, v36, s0
	ds_write_b16 v61, v59
	ds_write_b16 v61, v34 offset:128
	v_cvt_pk_bf16_f32 v34, v42, s0
	ds_write_b16 v26, v27 offset:256
	v_cvt_pk_bf16_f32 v27, v35, s0
	ds_write_b16 v61, v34 offset:2048
	v_cvt_pk_bf16_f32 v34, v41, s0
	ds_write_b16 v26, v27 offset:384
	v_cvt_pk_bf16_f32 v27, v44, s0
	ds_write_b16 v61, v34 offset:2176
	v_cvt_pk_bf16_f32 v34, v68, s0
	ds_write_b16 v26, v27 offset:2304
	v_cvt_pk_bf16_f32 v27, v43, s0
	ds_write_b16 v61, v34 offset:4096
	v_cvt_pk_bf16_f32 v34, v49, s0
	ds_write_b16 v26, v27 offset:2432
	v_cvt_pk_bf16_f32 v27, v70, s0
	ds_write_b16 v61, v34 offset:4224
	ds_write_b16 v26, v27 offset:4352
	v_cvt_pk_bf16_f32 v27, v69, s0
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
	v_cvt_pk_bf16_f32 v27, v46, s0
	ds_write_b16 v26, v27 offset:3072
	v_cvt_pk_bf16_f32 v27, v45, s0
	ds_write_b16 v26, v27 offset:3200
	v_cvt_pk_bf16_f32 v27, v72, s0
	ds_write_b16 v26, v27 offset:5120
	v_cvt_pk_bf16_f32 v27, v71, s0
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
	v_cvt_pk_bf16_f32 v27, v48, s0
	ds_write_b16 v26, v27 offset:3328
	v_cvt_pk_bf16_f32 v27, v47, s0
	ds_write_b16 v26, v27 offset:3456
	v_cvt_pk_bf16_f32 v27, v74, s0
	ds_write_b16 v26, v27 offset:5376
	v_cvt_pk_bf16_f32 v27, v73, s0
	ds_write_b16 v26, v27 offset:5504
	v_cvt_pk_bf16_f32 v27, v33, s0
	ds_write_b16 v26, v27 offset:7424
	v_cvt_pk_bf16_f32 v27, v32, s0
	ds_write_b16 v26, v27 offset:7552
	v_and_b32_e32 v26, 24, v55
	v_lshlrev_b32_e32 v27, 5, v0
	v_bfe_i32 v0, v0, 3, 1
	v_bitop3_b32 v0, v0, v26, s1 bitop3:0x6c
	v_xor_b32_e32 v0, v0, v51
	v_lshlrev_b32_e32 v28, 1, v57
	s_lshr_b32 s0, s48, 1
	v_and_or_b32 v0, v27, s8, v0
	v_or3_b32 v0, v0, s0, v28
	v_add_u32_e32 v29, 0, v0
	v_xad_u32 v0, v0, 32, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[36:37], v0 offset:1024
	ds_read_b64_tr_b16 v[40:41], v0 offset:3072
	ds_read_b64_tr_b16 v[44:45], v0 offset:5120
	ds_read_b64_tr_b16 v[48:49], v0 offset:7168
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_lshrrev_b32_e32 v0, 1, v1
	v_bitop3_b32 v0, v0, v56, 56 bitop3:0x6c
	.loc	1 122 38                        ; chunk_o.py:122:38
	ds_read_b64_tr_b16 v[34:35], v29
	ds_read_b64_tr_b16 v[38:39], v29 offset:2048
	ds_read_b64_tr_b16 v[42:43], v29 offset:4096
	ds_read_b64_tr_b16 v[46:47], v29 offset:6144
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_add_u32_e32 v29, 0, v0
	v_xad_u32 v0, v0, 8, 0
	s_movk_i32 s0, 0x180
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v29, v[18:19], v[22:23] offset1:8
	ds_write2st64_b64 v0, v[20:21], v[24:25] offset1:8
	v_and_or_b32 v0, v27, s0, v26
	s_movk_i32 s0, 0x48
	v_and_or_b32 v1, v1, s0, v51
	v_bitop3_b32 v0, v1, v28, v0 bitop3:0xde
	v_add_u32_e32 v1, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[64:65], v1
	v_xad_u32 v0, v0, 32, 0
	ds_read_b64_tr_b16 v[66:67], v0 offset:1024
	ds_read_b64_tr_b16 v[68:69], v1 offset:2048
	ds_read_b64_tr_b16 v[70:71], v0 offset:3072
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[64:67], v[34:37], 0
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_lshrrev_b32_e32 v34, 2, v54
	.loc	1 118 18                        ; chunk_o.py:118:18
	ds_read_b64_tr_b16 v[54:55], v1 offset:4096
	ds_read_b64_tr_b16 v[56:57], v0 offset:5120
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_mul_f32_e32 v36, 0x3fb8aa3b, v58
	v_cmp_gt_f32_e64 s[0:1], s9, v36
	.loc	1 90 22                         ; chunk_o.py:90:22
	v_or_b32_e32 v34, s46, v34
	v_or_b32_e32 v35, s47, v34
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_cndmask_b32_e64 v36, 0, v63, s[0:1]
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[68:71], v[38:41], v[18:33]
	.loc	1 118 18                        ; chunk_o.py:118:18
	ds_read_b64_tr_b16 v[38:39], v1 offset:6144
	ds_read_b64_tr_b16 v[40:41], v0 offset:7168
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v58
	v_exp_f32_e32 v36, v36
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_or_b32_e32 v0, s15, v34
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_cndmask_b32_e64 v34, 0, v62, s[0:1]
	.loc	1 94 22                         ; chunk_o.py:94:22
	v_mov_b32_e32 v1, s33
	.loc	1 105 24                        ; chunk_o.py:105:24
	v_ldexp_f32 v34, v36, v34
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[54:57], v[42:45], v[18:33]
	.loc	1 118 18                        ; chunk_o.py:118:18
	v_cmp_gt_i64_e64 s[0:1], s[24:25], v[0:1]
	.loc	1 105 20                        ; chunk_o.py:105:20
	v_mul_f32_e64 v0, v2, v34
	v_mul_f32_e64 v1, v3, v34
	.loc	1 118 18                        ; chunk_o.py:118:18
	s_and_b64 s[0:1], s[22:23], s[0:1]
	s_and_b64 vcc, vcc, s[0:1]
	.loc	1 122 50                        ; chunk_o.py:122:50
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[38:41], v[46:49], v[18:33]
	.loc	1 122 57 is_stmt 0              ; chunk_o.py:122:57
	s_nop 11
	v_pk_mul_f32 v[2:3], s[14:15], v[18:19] op_sel_hi:[0,1]
	.loc	1 122 24                        ; chunk_o.py:122:24
	v_pk_fma_f32 v[0:1], s[14:15], v[0:1], v[2:3] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[2:3], v[4:5], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[4:5], s[14:15], v[20:21] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[2:3], s[14:15], v[2:3], v[4:5] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[6:7], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[6:7], s[14:15], v[22:23] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[6:7], s[14:15], v[4:5], v[6:7] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[8:9], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[8:9], s[14:15], v[24:25] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[8:9], s[14:15], v[4:5], v[8:9] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[10:11], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[10:11], s[14:15], v[26:27] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[10:11], s[14:15], v[4:5], v[10:11] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[12:13], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[12:13], s[14:15], v[28:29] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[12:13], s[14:15], v[4:5], v[12:13] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[14:15], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[14:15], s[14:15], v[30:31] op_sel_hi:[0,1]
	.loc	1 122 24 is_stmt 0              ; chunk_o.py:122:24
	v_pk_fma_f32 v[14:15], s[14:15], v[4:5], v[14:15] op_sel_hi:[0,1,1]
	.loc	1 105 20 is_stmt 1              ; chunk_o.py:105:20
	v_pk_mul_f32 v[4:5], v[16:17], v[34:35] op_sel_hi:[1,0]
	.loc	1 122 57                        ; chunk_o.py:122:57
	v_pk_mul_f32 v[16:17], s[14:15], v[32:33] op_sel_hi:[0,1]
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_cvt_pk_bf16_f32 v6, v6, v7
	v_cvt_pk_bf16_f32 v7, v8, v9
	.loc	1 123 18 is_stmt 0              ; chunk_o.py:123:18
	v_lshlrev_b32_e32 v8, 12, v53
	.loc	1 122 24 is_stmt 1              ; chunk_o.py:122:24
	v_pk_fma_f32 v[16:17], s[14:15], v[4:5], v[16:17] op_sel_hi:[0,1,1]
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_cvt_pk_bf16_f32 v4, v0, v1
	v_cvt_pk_bf16_f32 v5, v2, v3
	.loc	1 123 18 is_stmt 0              ; chunk_o.py:123:18
	v_add_lshl_u32 v8, v8, v35, 1
	.loc	1 123 25                        ; chunk_o.py:123:25
	v_permlane32_swap_b32_e32 v4, v6
	v_permlane32_swap_b32_e32 v5, v7
	.loc	1 123 18                        ; chunk_o.py:123:18
	s_mov_b32 s14, s30
	s_mov_b32 s15, s31
	v_cndmask_b32_e32 v9, v52, v8, vcc
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
	v_cndmask_b32_e32 v4, v52, v4, vcc
	buffer_store_dwordx4 v[0:3], v4, s[12:15], 0 offen
	.loc	1 123 4                         ; chunk_o.py:123:4
	s_endpgm
.Ltmp126:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 72
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
		.amdhsa_next_free_vgpr 116
		.amdhsa_next_free_sgpr 54
		.amdhsa_accum_offset 116
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
	.size	qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950, .Lfunc_end0-qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.num_vgpr, 116
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.num_agpr, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.numbered_sgpr, 54
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.num_named_barrier, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.private_seg_size, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.uses_vcc, 1
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.uses_flat_scratch, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.has_dyn_sized_stack, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.has_recursion, 0
	.set qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 7896
; TotalNumSgprs: 60
; NumVgprs: 116
; NumAgprs: 0
; TotalNumVgprs: 116
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 7
; VGPRBlocks: 14
; NumSGPRsForWavesPerEU: 60
; NumVGPRsForWavesPerEU: 116
; AccumOffset: 116
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 28
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
	.byte	1                               ; Abbrev [1] 0xb:0x50 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x2a DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	65                              ; DW_AT_call_line
	.byte	24                              ; DW_AT_call_column
	.byte	4                               ; Abbrev [4] 0x4d:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
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
	.quad	0
	.quad	0
.Ldebug_ranges1:
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
	.quad	.Ltmp118-.Lfunc_begin0
	.quad	.Ltmp119-.Lfunc_begin0
	.quad	.Ltmp120-.Lfunc_begin0
	.quad	.Ltmp121-.Lfunc_begin0
	.quad	.Ltmp122-.Lfunc_begin0
	.quad	.Ltmp123-.Lfunc_begin0
	.quad	.Ltmp124-.Lfunc_begin0
	.quad	.Ltmp125-.Lfunc_begin0
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
	.asciz	"qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950"            ; string offset=71
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
      - .address_space:  global
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         64
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .max_flat_workgroup_size: 256
    .name:           qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     60
    .sgpr_spill_count: 0
    .symbol:         qwen36_gdn_chunk_o_m8192_bv64_fixed_t8192_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     116
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
