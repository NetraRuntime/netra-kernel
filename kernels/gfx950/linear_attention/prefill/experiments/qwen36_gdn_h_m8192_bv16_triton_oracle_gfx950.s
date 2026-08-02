// SPDX-License-Identifier: MIT
//
// Compiler-derived disassembly oracle for the deployed Triton BV16 schedule.
// This file is deliberately kept under experiments/ and is not an accepted
// Netra compute replacement.  It provides a fixed ABI and bit-exact reference
// while the separately named hand-scheduled gfx950 kernel is developed.
//
// Exact captured Qwen3.6 shape:
//   B=1, T=8192, H=32, Hg=16, K=V=128, BT=64, BV=16
//   grid=(8,32,1), block=(256,1,1), dynamic LDS=69,504 bytes
// Source code-object hash:
//   3cdf1e3c807b2115f6cb3f7c39752f824a007449b6c9b7059d0dfcb7e24fe1fa

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950 ; -- Begin function qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950
	.p2align	8
	.type	qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950,@function
qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950: ; @qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.21:
	.file	1 "/netra-server/python/sglang/srt/layers/attention/fla" "chunk_delta_h.py"
	.loc	1 41 0 prologue_end             ; chunk_delta_h.py:41:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.22:
.LBB0_0:
	s_mov_b64 s[28:29], s[2:3]
	s_load_dwordx4 s[36:39], s[0:1], 0x38
	s_load_dwordx2 s[2:3], s[0:1], 0x48
.Ltmp1:
	.loc	1 69 23 is_stmt 1               ; chunk_delta_h.py:69:23
	s_ashr_i32 s0, s17, 31
	s_lshr_b32 s0, s0, 27
	s_add_i32 s0, s17, s0
	s_ashr_i32 s42, s0, 5
	s_mov_b64 s[20:21], s[14:15]
	.loc	1 270 27                        ; chunk_delta_h.py:270:27
	v_readfirstlane_b32 s15, v0
	.loc	1 69 33                         ; chunk_delta_h.py:69:33
	s_andn2_b32 s0, s0, 31
	.loc	1 71 27                         ; chunk_delta_h.py:71:27
	s_ashr_i32 s43, s42, 31
	.loc	1 270 27                        ; chunk_delta_h.py:270:27
	s_bfe_u32 s59, s15, 0x20006
	.loc	1 69 33                         ; chunk_delta_h.py:69:33
	s_sub_i32 s14, s17, s0
	.loc	1 71 27                         ; chunk_delta_h.py:71:27
	s_lshl_b64 s[0:1], s[42:43], 2
	s_mov_b64 s[24:25], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_add_u32 s6, s38, s0
	s_addc_u32 s7, s39, s1
	s_load_dwordx2 s[52:53], s[6:7], 0x0
	.loc	1 76 22                         ; chunk_delta_h.py:76:22
	s_lshl_b64 s[6:7], s[42:43], 3
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v1, 63, v0
	v_and_b32_e32 v18, 15, v0
	v_lshlrev_b32_e32 v3, 2, v18
	.loc	1 74 18                         ; chunk_delta_h.py:74:18
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s46, s53, s52
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 43 17                         ; standard.py:43:17 @[ chunk_delta_h.py:75:24 ]
	s_add_i32 s60, s46, 63
.Ltmp3:
	.loc	1 76 22                         ; chunk_delta_h.py:76:22
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	.loc	1 93 17                         ; chunk_delta_h.py:93:17
	s_lshl_b32 s43, s52, 5
	.loc	1 93 21 is_stmt 0               ; chunk_delta_h.py:93:21
	s_add_i32 s43, s43, s14
	.loc	1 92 32 is_stmt 1               ; chunk_delta_h.py:92:32
	s_lshl_b32 s56, s14, 14
	.loc	1 93 28                         ; chunk_delta_h.py:93:28
	s_lshl_b32 s33, s43, 7
	.loc	1 103 20                        ; chunk_delta_h.py:103:20
	s_add_u32 s0, s36, s0
	s_addc_u32 s1, s37, s1
	s_load_dword s6, s[0:1], 0x0
	.loc	1 76 22                         ; chunk_delta_h.py:76:22
	s_load_dwordx2 s[44:45], s[2:3], 0x0
	.loc	1 113 62                        ; chunk_delta_h.py:113:62
	s_lshl_b32 s40, s16, 4
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	s_lshl_b32 s53, s59, 6
	.loc	1 113 80                        ; chunk_delta_h.py:113:80
	s_ashr_i32 s41, s40, 31
	.loc	1 104 33                        ; chunk_delta_h.py:104:33
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s0, s6, 19
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v7, s53, v1
	.loc	1 107 18                        ; chunk_delta_h.py:107:18
	s_add_i32 s0, s0, s56
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v2, 4, v7
	s_lshl_b64 s[34:35], s[40:41], 7
	v_or_b32_e32 v4, s40, v2
	v_mov_b32_e32 v5, s41
	v_lshl_or_b32 v2, v2, 7, v3
	s_cmp_gt_i32 s40, -1
	s_mov_b64 s[50:51], 0x80
	v_or_b32_e32 v6, s0, v2
	s_cselect_b64 s[48:49], -1, 0
	v_cmp_gt_i64_e32 vcc, s[50:51], v[4:5]
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_add_lshl_u32 v3, v6, s34, 1
	v_bfrev_b32_e32 v9, 1
	s_and_b64 s[2:3], s[48:49], vcc
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s22, s26
	s_mov_b32 s23, s27
	v_cndmask_b32_e64 v28, v9, v3, s[2:3]
	buffer_load_dwordx2 v[10:11], v28, s[20:23], 0 offen
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	s_and_b32 s62, s15, 64
	s_lshr_b32 s57, s62, 5
	s_cmp_lt_u32 s59, 2
	s_cselect_b64 s[54:55], -1, 0
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_bfe_i32 v4, v0, 5, 1
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	s_and_b64 s[0:1], s[54:55], exec
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v17, 16, v0
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_lshlrev_b32_e32 v5, 3, v18
	v_and_b32_e32 v4, 0x84, v4
	s_cselect_b32 s0, 0, 0x200
	v_lshlrev_b32_e32 v3, 6, v17
	.loc	1 119 28 is_stmt 1              ; chunk_delta_h.py:119:28
	s_or_b32 s45, s34, 64
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_or3_b32 v4, v4, s0, v5
	.loc	1 119 28                        ; chunk_delta_h.py:119:28
	v_add_lshl_u32 v5, v6, s45, 1
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_or3_b32 v4, v4, s57, v3
	.loc	1 119 28                        ; chunk_delta_h.py:119:28
	v_cndmask_b32_e64 v29, v9, v5, s[2:3]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_add_u32_e32 v6, 0, v4
	v_xad_u32 v14, v4, 4, 0
	v_xad_u32 v15, v4, 32, 0
	v_xad_u32 v19, v4, 36, 0
	.loc	1 114 24 is_stmt 0              ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v23, 1, v0
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_bfe_i32 v4, v0, 1, 1
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v20, 28, v23
	v_and_b32_e32 v16, 3, v0
	v_lshlrev_b32_e32 v30, 3, v0
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_and_b32_e32 v12, 0x120, v4
	v_lshrrev_b32_e32 v4, 3, v17
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v5, s59, v20
	v_lshlrev_b32_e32 v21, 2, v16
	v_and_b32_e32 v8, 56, v30
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	v_lshl_or_b32 v22, v5, 12, v8
	v_cmp_gt_i32_e32 vcc, s46, v5
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_and_b32_e32 v31, 12, v0
	s_lshl_b32 s35, s59, 5
	.loc	1 154 63                        ; chunk_delta_h.py:154:63
	s_ashr_i32 s47, s46, 31
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v33, 32, v0
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	v_lshlrev_b32_e32 v32, 4, v33
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	s_mul_i32 s58, s59, 0x420
	v_add_lshl_u32 v22, v22, s33, 1
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_or_b32_e32 v25, 0x80, v22
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	s_waitcnt vmcnt(0)
	ds_write_b16 v6, v10
	ds_write_b16_d16_hi v14, v10
	ds_write_b16 v15, v11 offset:256
	ds_write_b16_d16_hi v19, v11 offset:256
	v_and_b32_e32 v10, 1, v0
	v_lshl_or_b32 v13, v10, 2, v4
	.loc	1 114 24 is_stmt 0              ; chunk_delta_h.py:114:24
	v_or_b32_e32 v4, 32, v5
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	v_lshl_or_b32 v24, v4, 12, v8
	v_cmp_gt_i32_e64 s[6:7], s46, v4
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v4, s40, v21
	v_mov_b32_e32 v5, s41
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	v_cmp_gt_i64_e64 s[0:1], s[50:51], v[4:5]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_lshlrev_b32_e32 v11, 1, v31
	v_bitop3_b32 v5, s35, v12, v11 bitop3:0x36
	v_or3_b32 v5, v5, v13, v32
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_lshl_u32 v24, v24, s33, 1
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_add_u32_e32 v27, 0, v5
	v_xad_u32 v37, v5, 4, 0
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_or_b32_e32 v26, 0x80, v24
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 119 28                        ; chunk_delta_h.py:119:28
	buffer_load_dwordx2 v[34:35], v29, s[20:23], 0 offen
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_and_b64 s[22:23], s[48:49], s[0:1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmp_gt_i32 s60, 63
	s_cselect_b64 s[0:1], -1, 0
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 s61, s58, 0
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, vcc, s[0:1]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_and_b32 s25, s25, 0xffff
	s_add_i32 s15, s61, 0x1080
	v_cndmask_b32_e32 v22, v9, v22, vcc
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[6:7], s[6:7], s[0:1]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_mov_b32 m0, s61
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 s18, s61, 0x41e0
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cndmask_b32_e64 v24, v9, v24, s[6:7]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	ds_read_u16 v5, v27
	ds_read_u16 v12, v27 offset:1024
	ds_read_u16 v11, v37 offset:128
	ds_read_u16 v13, v37 offset:1152
	.loc	1 119 20                        ; chunk_delta_h.py:119:20
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 s19, s61, 0x5260
	v_cndmask_b32_e32 v25, v9, v25, vcc
	v_cndmask_b32_e64 v26, v9, v26, s[6:7]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 s63, s61, 0x80
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_and_b32 s5, s5, 0xffff
	.loc	1 119 20                        ; chunk_delta_h.py:119:20
	s_waitcnt vmcnt(0)
	ds_write_b16 v6, v34
	ds_write_b16_d16_hi v14, v34
	ds_write_b16 v15, v35 offset:256
	ds_write_b16_d16_hi v19, v35 offset:256
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v34, v27
	ds_read_u16 v36, v27 offset:1024
	ds_read_u16 v35, v37 offset:128
	ds_read_u16 v37, v37 offset:1152
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_waitcnt lgkmcnt(0)
	s_barrier
	buffer_load_dwordx4 v22, s[24:27], 0 offen lds
	s_mov_b32 m0, s15
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v6, 2, v7
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	buffer_load_dwordx4 v24, s[24:27], 0 offen lds
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_mov_b32 m0, s18
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cmp_gt_i32_e32 vcc, s46, v6
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v25, s[24:27], 0 offen lds
	s_mov_b32 m0, s19
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshlrev_b32_e32 v6, 12, v6
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v26, s[24:27], 0 offen lds
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_add_i32 s15, s40, s33
	s_and_b64 s[6:7], s[22:23], vcc
	v_or_b32_e32 v14, v6, v21
	v_add_lshl_u32 v14, s15, v14, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, s[0:1], s[6:7]
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_cmp_eq_u32_e64 s[18:19], 0, v33
	v_mov_b32_e32 v26, 0
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmp_lt_i32 s60, 64
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_mov_b32 s6, s26
	s_mov_b32 s7, s27
	v_cndmask_b32_e32 v14, v9, v14, vcc
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_cbranch_scc1 .LBB0_2
; %bb.1:
	.loc	1 0 31 is_stmt 0                ; chunk_delta_h.py:0:31
	s_min_u32 s15, s46, 64
	s_lshl_b32 s15, s15, 5
	s_add_i32 s15, s43, s15
	s_sub_i32 s30, s15, 32
	s_ashr_i32 s31, s30, 31
	s_lshl_b64 s[30:31], s[30:31], 2
	s_add_u32 s30, s10, s30
	s_addc_u32 s31, s11, s31
	v_mov_b32_e32 v15, 0
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	global_load_dword v26, v15, s[30:31]
.LBB0_2:
	.loc	1 0 31                          ; chunk_delta_h.py:0:31
	buffer_load_dwordx2 v[24:25], v14, s[4:7], 0 offen
	.loc	1 94 30 is_stmt 1               ; chunk_delta_h.py:94:30
	s_bfe_u32 s6, s14, 0x10007
	s_add_i32 s14, s14, s6
	s_sext_i32_i8 s6, s14
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	s_lshl_b32 s65, s59, 4
	.loc	1 94 30                         ; chunk_delta_h.py:94:30
	s_ashr_i32 s66, s6, 1
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v21, 2, v17
	v_lshrrev_b32_e32 v22, 1, v33
	v_or_b32_e32 v15, s65, v18
	.loc	1 94 42                         ; chunk_delta_h.py:94:42
	s_lshl_b32 s6, s52, 11
	s_lshl_b32 s7, s66, 7
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v19, 8, v0
	v_or_b32_e32 v14, v22, v21
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cmp_gt_i32_e32 vcc, s46, v15
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	v_lshlrev_b32_e32 v15, 7, v15
	.loc	1 94 42                         ; chunk_delta_h.py:94:42
	s_add_i32 s64, s6, s7
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or3_b32 v14, v14, v19, s59
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	v_lshl_add_u32 v15, s43, 2, v15
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[6:7], vcc, s[0:1]
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v43, 32, v14
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	s_and_b32 s37, s11, 0xffff
	s_mov_b32 s36, s10
	s_mov_b32 s38, s26
	s_mov_b32 s39, s27
	v_cndmask_b32_e64 v15, v9, v15, s[6:7]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_lshl_or_b32 v38, v14, 11, v8
	v_cmp_gt_i32_e64 s[6:7], s46, v14
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	buffer_load_dword v27, v15, s[36:39], 0 offen
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_lshlrev_b32_e32 v15, 11, v43
	v_or_b32_e32 v8, s64, v8
	v_cmp_gt_i32_e64 s[14:15], s46, v43
	v_add_lshl_u32 v14, v38, s64, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[6:7], s[6:7], s[0:1]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_and_b32 s29, s29, 0xffff
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	s_add_i32 m0, s61, 0x83c0
	v_cndmask_b32_e64 v38, v9, v14, s[6:7]
	v_add_lshl_u32 v8, v8, v15, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[14:15], s[14:15], s[0:1]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	buffer_load_dwordx4 v38, s[28:31], 0 offen lds
	s_add_i32 m0, s63, 0x93c0
	v_cndmask_b32_e64 v15, v9, v8, s[14:15]
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_or_b32_e32 v14, 0x80, v14
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	buffer_load_dwordx4 v15, s[28:31], 0 offen lds
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	s_add_i32 m0, s61, 0xc5a0
	v_cndmask_b32_e64 v14, v9, v14, s[6:7]
	v_or_b32_e32 v8, 0x80, v8
	buffer_load_dwordx4 v14, s[28:31], 0 offen lds
	s_add_i32 m0, s63, 0xd5a0
	v_cndmask_b32_e64 v8, v9, v8, s[14:15]
	buffer_load_dwordx4 v8, s[28:31], 0 offen lds
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v45, 48, v0
.Ltmp4:
	.loc	2 43 30                         ; standard.py:43:30 @[ chunk_delta_h.py:75:24 ]
	s_ashr_i32 s6, s60, 31
.Ltmp5:
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v8, 2, v45
.Ltmp6:
	.loc	2 43 30                         ; standard.py:43:30 @[ chunk_delta_h.py:75:24 ]
	s_lshr_b32 s6, s6, 26
.Ltmp7:
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v38, s40, v8
	v_mov_b32_e32 v39, s41
.Ltmp8:
	.loc	2 43 30                         ; standard.py:43:30 @[ chunk_delta_h.py:75:24 ]
	s_add_i32 s6, s60, s6
.Ltmp9:
	.loc	1 114 58                        ; chunk_delta_h.py:114:58
	v_lshlrev_b32_e32 v9, 16, v12
	v_lshlrev_b32_e32 v8, 16, v5
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	v_cmp_gt_i64_e64 s[14:15], s[50:51], v[38:39]
	.loc	1 0 0 is_stmt 0                 ; chunk_delta_h.py:0
	v_and_b32_e32 v40, 2, v0
.Ltmp10:
	.loc	2 43 30 is_stmt 1               ; standard.py:43:30 @[ chunk_delta_h.py:75:24 ]
	s_ashr_i32 s61, s6, 6
.Ltmp11:
	.loc	1 114 58                        ; chunk_delta_h.py:114:58
	v_lshlrev_b32_e32 v13, 16, v13
	v_lshlrev_b32_e32 v12, 16, v11
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	v_pk_add_f32 v[14:15], v[8:9], 0 op_sel_hi:[1,0]
	.loc	1 119 62 is_stmt 1              ; chunk_delta_h.py:119:62
	v_lshlrev_b32_e32 v9, 16, v36
	v_lshlrev_b32_e32 v8, 16, v34
	v_lshlrev_b32_e32 v37, 16, v37
	v_lshlrev_b32_e32 v36, 16, v35
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[48:49], s[14:15], s[48:49]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_cmp_eq_u32_e64 s[6:7], 0, v10
	v_pk_add_f32 v[10:11], v[12:13], 0 op_sel_hi:[1,0]
	.loc	1 119 20                        ; chunk_delta_h.py:119:20
	v_pk_add_f32 v[12:13], v[8:9], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[8:9], v[36:37], 0 op_sel_hi:[1,0]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmpk_gt_i32 s60, 0x7f
	v_lshlrev_b32_e32 v53, 2, v31
	v_lshlrev_b32_e32 v54, 1, v40
	v_lshrrev_b32_e32 v55, 2, v33
	v_lshlrev_b32_e32 v52, 4, v7
	v_and_b32_e32 v49, 2, v23
	v_lshlrev_b32_e32 v50, 3, v19
	v_lshlrev_b32_e32 v51, 5, v17
	v_lshlrev_b32_e32 v48, 10, v16
	v_lshlrev_b32_e32 v44, 5, v7
	v_lshlrev_b32_e32 v46, 5, v45
	v_lshlrev_b32_e32 v47, 1, v1
	v_lshlrev_b32_e32 v17, 7, v18
	s_cbranch_scc1 .LBB0_4
; %bb.3:                                ; %._crit_edge126
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_mov_b32_e32 v5, 0x140
	s_and_b64 s[14:15], s[54:55], exec
	v_cndmask_b32_e64 v5, v5, 0, s[6:7]
	s_cselect_b32 s14, 0, 64
	v_bitop3_b32 v5, s14, v5, v53 bitop3:0x1e
	v_mov_b32_e32 v7, 0x88
	v_or3_b32 v42, v55, v54, v5
	v_and_b32_e32 v5, 0x430, v52
	v_cndmask_b32_e64 v7, v7, 0, s[18:19]
	s_cselect_b32 s14, 0, 8
	s_movk_i32 s30, 0x140
	v_or3_b32 v23, v49, v50, v51
	v_bitop3_b32 v5, v5, s14, v7 bitop3:0x36
	v_or_b32_e32 v33, v5, v23
	v_bitop3_b32 v34, v5, s30, v23 bitop3:0x36
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_or_b32 v5, s62, 3, v48
	s_movk_i32 s30, 0x1180
	v_and_or_b32 v5, v44, s30, v5
	v_or_b32_e32 v7, v5, v45
	v_lshrrev_b32_e32 v5, 5, v5
	v_and_b32_e32 v5, 0xe0, v5
	s_movk_i32 s30, 0x70
	v_add_u32_e32 v39, v5, v7
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_bitop3_b32 v40, s35, v46, v47 bitop3:0x1e
	v_and_b32_e32 v5, 0x70, v30
	v_bitop3_b32 v7, v30, v45, s30 bitop3:0x6c
	s_mov_b32 s15, 0x27000
	s_mov_b32 s14, 0x7ffffffe
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_and_b32 s41, s13, 0xffff
	s_mov_b32 s40, s12
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v23, 64, v39
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_xor_b32_e32 v41, 0x110, v40
	v_bitop3_b32 v5, v5, v17, v45 bitop3:0xde
	v_bitop3_b32 v35, v7, 64, v17 bitop3:0x36
	s_mov_b64 s[30:31], 0
	s_branch .LBB0_5
.LBB0_4:
	.loc	1 0 44 is_stmt 0                ; chunk_delta_h.py:0:44
	s_mov_b64 s[30:31], -1
                                        ; implicit-def: $vgpr42
                                        ; implicit-def: $vgpr33
                                        ; implicit-def: $vgpr34
                                        ; implicit-def: $sgpr40_sgpr41
                                        ; implicit-def: $vgpr39
                                        ; implicit-def: $vgpr23
                                        ; implicit-def: $vgpr40
                                        ; implicit-def: $vgpr41
                                        ; implicit-def: $vgpr5
                                        ; implicit-def: $vgpr35
.LBB0_5:                                ; %Flow
	s_add_i32 s61, s61, -1
	s_and_b64 s[50:51], vcc, s[48:49]
	s_andn2_b64 vcc, exec, s[30:31]
	v_bfe_u32 v37, v0, 4, 2
	v_lshlrev_b32_e32 v38, 2, v0
	v_lshlrev_b32_e32 v36, 3, v31
	s_cbranch_vccnz .LBB0_9
; %bb.6:                                ; %.lr.ph
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	s_lshl_b32 s14, s59, 10
	s_lshr_b32 s15, s14, 5
	s_or_b32 s63, s15, s14
	v_mov_b32_e32 v33, 0x140
	v_cndmask_b32_e64 v33, v33, 0, s[6:7]
	s_and_b64 s[6:7], s[54:55], exec
	s_cselect_b32 s6, 0, 64
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_mov_b32_e32 v5, s47
	v_sub_co_u32_e32 v6, vcc, s46, v43
	v_bitop3_b32 v33, s6, v33, v53 bitop3:0x1e
	s_nop 0
	v_subbrev_co_u32_e32 v7, vcc, 0, v5, vcc
	v_or_b32_e32 v5, s57, v3
	v_or3_b32 v42, v55, v54, v33
	s_movk_i32 s6, 0x88
	v_mov_b32_e32 v33, 0x88
	v_or_b32_e32 v56, v42, v5
	v_bitop3_b32 v57, v42, s6, v5 bitop3:0x36
	v_and_b32_e32 v5, 0x430, v52
	v_cndmask_b32_e64 v33, v33, 0, s[18:19]
	s_cselect_b32 s6, 0, 8
	s_movk_i32 s14, 0x140
	v_or3_b32 v34, v49, v50, v51
	v_bitop3_b32 v5, v5, s6, v33 bitop3:0x36
	v_or_b32_e32 v33, v5, v34
	v_bitop3_b32 v34, v5, s14, v34 bitop3:0x36
	v_lshl_or_b32 v5, s62, 3, v48
	s_movk_i32 s6, 0x1180
	v_and_or_b32 v5, v44, s6, v5
	v_or_b32_e32 v43, v5, v45
	v_lshrrev_b32_e32 v5, 5, v5
	s_movk_i32 s7, 0x70
	v_and_b32_e32 v44, 0xe0, v5
	v_and_b32_e32 v5, 0x70, v30
	v_bitop3_b32 v35, v30, v45, s7 bitop3:0x6c
	v_bitop3_b32 v5, v5, v17, v45 bitop3:0xde
	v_bitop3_b32 v35, v35, 64, v17 bitop3:0x36
	v_and_or_b32 v17, v38, 60, v37
	v_or_b32_e32 v23, s35, v32
	v_bitop3_b32 v40, s35, v46, v47 bitop3:0x1e
	v_lshlrev_b32_e32 v45, 2, v17
	v_lshlrev_b32_e32 v17, 8, v31
	v_and_b32_e32 v46, 0x98, v30
	s_lshl_b32 s7, s59, 17
	s_lshl_b32 s18, s52, 13
	s_lshl_b32 s19, s17, 8
	s_lshl_b32 s16, s16, 5
	s_movk_i32 s6, 0xe0
	v_or3_b32 v17, v17, v46, v23
	v_mov_b32_e32 v23, 0x80
	s_add_i32 s7, s7, s18
	s_add_i32 s16, s16, s19
	v_bitop3_b32 v23, v36, s6, v23 bitop3:0xc8
	s_add_i32 s7, s16, s7
	v_add_u32_e32 v46, v17, v36
	s_max_i32 s6, s61, 1
	v_add_u32_e32 v47, v23, v17
	v_lshl_add_u32 v17, v18, 13, s7
	v_lshl_or_b32 v17, v37, 3, v17
	s_lshl_b32 s7, s42, 13
	s_lshl_b32 s64, s6, 6
	s_lshl_b32 s6, s59, 11
	v_subrev_u32_e32 v48, s7, v17
	v_add_u32_e32 v17, s52, v18
	s_lshl2_add_u32 s6, s17, s6
	v_lshl_add_u32 v17, v17, 7, s6
	s_lshl_b32 s6, s42, 7
	v_subrev_u32_e32 v17, s6, v17
	v_add_u32_e32 v49, 0x2000, v17
	v_and_b32_e32 v17, 7, v0
	v_lshlrev_b32_e32 v50, 4, v17
	v_lshlrev_b32_e32 v17, 11, v0
	v_lshlrev_b32_e32 v23, 12, v0
	v_lshlrev_b32_e32 v0, 10, v0
	s_add_i32 s6, s52, s59
	v_and_b32_e32 v17, 0x10000, v17
	v_and_b32_e32 v51, 0x8000, v23
	v_and_b32_e32 v0, 0x4000, v0
	s_lshl_b32 s30, s6, 12
	s_lshl_b32 s31, s66, 8
	v_or3_b32 v0, v17, v51, v0
	s_add_i32 s30, s31, s30
	v_add_u32_e32 v0, s30, v0
	v_add_u32_e32 v51, 0x60000, v0
	v_add_u32_e32 v0, v22, v19
	v_add3_u32 v22, v0, v21, s59
	v_add_u32_e32 v0, s53, v1
	v_lshrrev_b32_e32 v0, 2, v0
	s_add_i32 s16, s16, s18
	v_lshl_add_u32 v17, v0, 13, s16
	v_lshl_or_b32 v16, v16, 3, v17
	v_subrev_u32_e32 v16, s7, v16
	s_lshl_b32 s6, s6, 13
	v_add_u32_e32 v53, 0x80000, v16
	v_and_b32_e32 v16, 0x38000, v23
	s_add_i32 s19, s19, s6
	v_add_u32_e32 v17, s19, v16
	s_lshl_b32 s30, s52, 12
	v_mov_b32_e32 v1, 0
	v_subrev_u32_e32 v54, s7, v17
	s_lshl_b32 s6, s59, 13
	s_lshl_b32 s7, s43, 8
	s_add_i32 s31, s31, s30
	s_add_i32 s7, s7, s6
	v_mov_b32_e32 v23, v1
	v_lshl_add_u32 v52, v22, 12, s31
	v_add_u32_e32 v55, s7, v16
	v_lshl_add_u64 v[16:17], v[22:23], 0, 64
	v_add_u32_e32 v22, s59, v20
	s_lshl_b32 s6, s44, 19
	s_lshl_b32 s7, s17, 14
	s_mov_b32 s60, 0
	v_add_u32_e32 v18, s65, v18
	v_mov_b32_e32 v19, v1
	v_add_u32_e32 v20, 32, v22
	v_mov_b32_e32 v21, v1
	s_add_i32 s6, s6, s7
	s_lshl_b32 s7, s42, 19
	s_add_i32 s66, 0, 0x10780
	s_and_b32 s13, s13, 0xffff
	s_mov_b32 s15, 0x27000
	s_mov_b32 s14, 0x7ffffffe
	v_add_u32_e32 v39, v44, v43
	v_xor_b32_e32 v41, 0x110, v40
	s_and_b32 s41, s9, 0xffff
	s_mov_b32 s40, s8
	s_sub_i32 s62, s43, 32
	s_bitset1_b32 s63, 7
	v_lshl_add_u64 v[18:19], v[18:19], 0, 64
	v_lshl_add_u64 v[20:21], v[20:21], 0, 64
	v_or_b32_e32 v22, 64, v22
	v_mov_b32_e32 v23, s60
	s_sub_i32 s65, s6, s7
	s_add_i32 s71, 0, 0x41e0
	s_add_i32 s16, 0, 0x83c0
	s_add_i32 s59, 0, 0xc5a0
	s_mov_b64 s[52:53], 0
	v_add_u32_e32 v56, s66, v56
	v_add_u32_e32 v57, s66, v57
	s_mov_b32 s67, 0x5040100
	s_mov_b32 s68, 0xc2fc0000
	v_bfrev_b32_e32 v58, 1
	v_mov_b32_e32 v59, 0xff800000
	v_mov_b32_e32 v60, 0x42800000
	v_not_b32_e32 v61, 63
	s_mov_b32 s69, 0
	s_mov_b32 s70, 0
                                        ; implicit-def: $sgpr18_sgpr19
.LBB0_7:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_cvt_pk_bf16_f32 v64, v14, s0
	v_add_u32_e32 v68, s66, v33
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_cvt_pk_bf16_f32 v65, v15, s0
	v_cvt_pk_bf16_f32 v66, v10, s0
	v_cvt_pk_bf16_f32 v67, v11, s0
	v_add_u32_e32 v69, s66, v34
	ds_write_b16 v56, v64
	ds_write_b16 v56, v65 offset:512
	ds_write_b16 v57, v66
	ds_write_b16 v57, v67 offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v62, v68
	ds_read_u16 v63, v68 offset:4
	ds_read_u16 v70, v69 offset:4
	ds_read_u16 v71, v69
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_add_i32 s6, s70, 1
	s_cmp_lt_i32 s6, 2
	s_cselect_b32 s70, s6, 0
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_add_i32 s6, s65, s69
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v63, v70, v63, s67
	v_add_u32_e32 v70, s6, v2
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v62, v71, v62, s67
	v_add_lshl_u32 v71, v70, s34, 1
	v_cndmask_b32_e64 v71, v58, v71, s[2:3]
	buffer_store_dwordx2 v[62:63], v71, s[12:15], 0 offen
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	v_cvt_pk_bf16_f32 v71, v12, s0
	v_cvt_pk_bf16_f32 v76, v9, s0
	v_cvt_pk_bf16_f32 v74, v13, s0
	v_cvt_pk_bf16_f32 v75, v8, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v56, v71
	ds_write_b16 v56, v74 offset:512
	ds_write_b16 v57, v75
	ds_write_b16 v57, v76 offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v62, v68
	ds_read_u16 v63, v68 offset:4
	ds_read_u16 v68, v69 offset:4
	ds_read_u16 v69, v69
	s_mov_b64 s[54:55], s[52:53]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_u32 s52, s54, 64
	s_addc_u32 s53, s55, 0
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v63, v68, v63, s67
	v_add_lshl_u32 v68, v70, s45, 1
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v62, v69, v62, s67
	v_cndmask_b32_e64 v68, v58, v68, s[2:3]
	buffer_store_dwordx2 v[62:63], v68, s[12:15], 0 offen
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[62:63], v[22:23], 0, s[54:55]
	v_cmp_gt_i64_e64 s[6:7], s[46:47], v[62:63]
	v_lshl_add_u64 v[62:63], v[20:21], 0, s[54:55]
	v_cmp_gt_i64_e32 vcc, s[46:47], v[62:63]
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	ds_bpermute_b32 v62, v45, v25
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_lshl_b32 s17, s70, 12
	s_ashr_i32 s30, s17, 5
	s_add_i32 s30, s30, s17
	v_add_u32_e32 v68, v50, v55
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v73, 0xffff0000, v62
	v_lshlrev_b32_e32 v72, 16, v62
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v62, s60, v39
	s_lshl1_add_u32 s60, s30, 0
	v_add_u32_e32 v69, 0x80000, v68
	v_add_u32_e32 v70, v50, v54
	s_add_i32 s73, s60, s58
	v_add_u32_e32 v77, 0xc0000, v70
	ds_read_b128 v[78:81], v62
	ds_read_b128 v[82:85], v62 offset:64
	v_cndmask_b32_e64 v62, v58, v69, s[6:7]
	s_mov_b32 m0, s73
	s_add_i32 s72, s60, s63
	buffer_load_dwordx4 v62, s[24:27], 0 offen lds
	v_cndmask_b32_e32 v62, v58, v77, vcc
	s_add_i32 m0, s72, 0x1000
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v63, s66, v41
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	buffer_load_dwordx4 v62, s[24:27], 0 offen lds
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v62, s66, v40
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write_b16 v62, v64
	ds_write_b16 v62, v65 offset:128
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_add_u32_e32 v64, 0x80080, v68
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_write_b16 v63, v66
	ds_write_b16 v63, v67 offset:128
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_cndmask_b32_e64 v66, v58, v64, s[6:7]
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v64, s66, v5
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[86:89], v64
	v_add_u32_e32 v65, s66, v35
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 m0, s73, 0x41e0
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_read_b128 v[90:93], v65
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v66, s[24:27], 0 offen lds
	v_add_u32_e32 v66, s71, v39
	ds_read_b128 v[94:97], v66
	ds_read_b128 v[98:101], v66 offset:64
	v_add_u32_e32 v66, 0xc0080, v70
	v_cndmask_b32_e32 v66, v58, v66, vcc
	s_add_i32 m0, s72, 0x51e0
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	ds_bpermute_b32 v24, v45, v24
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v66, s[24:27], 0 offen lds
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write_b16 v62, v71
	ds_write_b16 v62, v74 offset:128
	ds_write_b16 v63, v75
	ds_write_b16 v63, v76 offset:128
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[74:77], v64
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	v_mfma_f32_16x16x32_bf16 v[66:69], v[86:89], v[78:81], 0
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_read_b128 v[78:81], v65
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_and_b32_e32 v25, 0xffff0000, v24
	v_lshlrev_b32_e32 v24, 16, v24
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	v_mfma_f32_16x16x32_bf16 v[66:69], v[90:93], v[82:85], v[66:69]
	s_mov_b32 s71, s16
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_mov_b32 s6, s26
	s_mov_b32 s7, s27
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[74:77], v[94:97], v[66:69]
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_mov_b32 s42, s14
	s_mov_b32 s43, s15
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v74, v50, v52
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[68:71], v[78:81], v[98:101], v[68:71]
	v_mov_b32_e32 v66, v26
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	v_add_u32_e32 v26, s69, v53
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add_u32_e32 v67, s69, v48
	v_cndmask_b32_e64 v67, v58, v67, s[50:51]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_mov_b32 s30, s26
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_nop 2
	v_pk_add_f32 v[24:25], v[24:25], v[68:69] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[68:69], v[18:19], 0, s[54:55]
	v_cmp_gt_i64_e32 vcc, s[46:47], v[68:69]
	v_lshl_add_u64 v[68:69], s[52:53], 0, v[0:1]
	v_cmp_gt_i64_e64 s[16:17], s[46:47], v[68:69]
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_and_b64 s[16:17], s[22:23], s[16:17]
	.loc	1 179 52 is_stmt 0              ; chunk_delta_h.py:179:52
	v_pk_add_f32 v[70:71], v[72:73], v[70:71] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	v_cndmask_b32_e64 v26, v58, v26, s[16:17]
	buffer_load_dwordx2 v[68:69], v26, s[4:7], 0 offen
	.loc	1 194 44 is_stmt 1              ; chunk_delta_h.py:194:44
	v_sub_f32_e32 v26, v66, v27
.Ltmp12:
	.file	3 "/netra-server/python/sglang/srt/layers/attention/fla" "op.py"
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_mul_f32_e32 v27, 0x3fb8aa3b, v26
	.loc	3 27 29 is_stmt 0               ; op.py:27:29 @[ chunk_delta_h.py:194:33 ]
	v_cmp_ge_f32_e64 s[16:17], 0, v26
.Ltmp13:
	.loc	1 185 33 is_stmt 1              ; chunk_delta_h.py:185:33
	v_cvt_pk_bf16_f32 v72, v24, v25
	v_cvt_pk_bf16_f32 v73, v70, v71
.Ltmp14:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e64 v26, v59, v27, s[16:17]
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cmp_gt_f32_e64 s[16:17], s68, v26
.Ltmp15:
	.loc	1 185 26 is_stmt 1              ; chunk_delta_h.py:185:26
	buffer_store_dwordx2 v[72:73], v67, s[40:43], 0 offen
	.loc	1 187 39                        ; chunk_delta_h.py:187:39
	s_add_i32 s42, s54, 0x80
.Ltmp16:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e64 v27, 0, v60, s[16:17]
	v_add_f32_e32 v26, v26, v27
	v_exp_f32_e32 v26, v26
.Ltmp17:
	.loc	1 187 39                        ; chunk_delta_h.py:187:39
	s_min_i32 s42, s42, s46
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[72:73], v[16:17], 0, s[54:55]
.Ltmp18:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e64 v27, 0, v61, s[16:17]
.Ltmp19:
	.loc	1 189 56                        ; chunk_delta_h.py:189:56
	s_lshl_b32 s42, s42, 5
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_cmp_gt_i64_e64 s[6:7], s[46:47], v[72:73]
	v_add_u32_e32 v73, v50, v51
.Ltmp20:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_ldexp_f32 v72, v26, v27
.Ltmp21:
	.loc	1 189 60                        ; chunk_delta_h.py:189:60
	s_add_i32 s42, s62, s42
	.loc	1 194 24                        ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[26:27], v[72:73], v[24:25] op_sel_hi:[0,1]
	v_pk_mul_f32 v[24:25], v[72:73], v[70:71] op_sel_hi:[0,1]
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_mul_f32_e32 v70, 0x3fb8aa3b, v66
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_ashr_i32 s43, s42, 31
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v71, s71, v46
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_cmp_gt_f32_e64 s[16:17], s68, v70
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v70, s71, v47
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 s71, s60, 0x41e0
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_lshl_b64 s[42:43], s[42:43], 2
	s_add_u32 s42, s10, s42
	s_addc_u32 s43, s11, s43
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v67, 0x40000, v74
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_add_u32_e32 v72, 0x40080, v74
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	ds_read_b64_tr_b16 v[78:79], v70 offset:4096
	ds_read_b64_tr_b16 v[80:81], v70 offset:4352
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_cndmask_b32_e64 v70, 0, v60, s[16:17]
	s_and_b64 s[16:17], s[16:17], exec
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_mov_b32 s31, s27
	v_cndmask_b32_e64 v67, v58, v67, s[6:7]
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	s_cselect_b32 s17, 0xffffffc0, 0
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_add_i32 m0, s73, 0x83c0
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_cndmask_b32_e64 v72, v58, v72, s[6:7]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_cmp_lt_i64_e64 s[6:7], s[52:53], v[6:7]
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	s_mov_b32 s36, s10
	s_mov_b32 s38, s26
	s_mov_b32 s39, s27
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	ds_read_b64_tr_b16 v[74:75], v71
	ds_read_b64_tr_b16 v[76:77], v71 offset:256
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_add_u32_e32 v71, 0x80, v73
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	buffer_load_dwordx4 v67, s[28:31], 0 offen lds
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	v_cndmask_b32_e32 v67, v58, v49, vcc
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_cndmask_b32_e64 v73, v58, v73, s[6:7]
	s_add_i32 m0, s72, 0x93c0
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	buffer_load_dword v67, v67, s[36:39], 0 offen
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_cndmask_b32_e64 v71, v58, v71, s[6:7]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	buffer_load_dwordx4 v73, s[28:31], 0 offen lds
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	s_add_i32 m0, s73, 0xc5a0
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	v_cvt_pk_bf16_f32 v73, v26, s0
	v_cvt_pk_bf16_f32 v27, v27, s0
	v_cvt_pk_bf16_f32 v24, v24, s0
	v_cvt_pk_bf16_f32 v25, v25, s0
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	global_load_dword v26, v1, s[42:43]
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(1)
	ds_write_b16 v62, v73
	ds_write_b16 v62, v27 offset:128
	ds_write_b16 v63, v24
	ds_write_b16 v63, v25 offset:128
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[82:85], v64
	ds_read_b128 v[86:89], v65
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	buffer_load_dwordx4 v72, s[28:31], 0 offen lds
	s_add_i32 m0, s72, 0xd5a0
	v_add_u32_e32 v24, s59, v46
	buffer_load_dwordx4 v71, s[28:31], 0 offen lds
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_fmac_f32_e32 v70, 0x3fb8aa3b, v66
	v_exp_f32_e32 v27, v70
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	ds_read_b64_tr_b16 v[70:71], v24
	v_add_u32_e32 v25, s59, v47
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[62:65], v[82:85], v[74:77], 0
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	ds_read_b64_tr_b16 v[72:73], v24 offset:256
	ds_read_b64_tr_b16 v[74:75], v25 offset:4096
	ds_read_b64_tr_b16 v[76:77], v25 offset:4352
	s_and_b64 s[50:51], vcc, s[48:49]
	s_andn2_b64 s[6:7], s[18:19], exec
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[70:73], v[82:85], v[70:73], 0
	s_and_b64 s[18:19], s[50:51], exec
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_add_i32 s16, s60, 0x83c0
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	s_add_i32 s59, s60, 0xc5a0
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	v_mfma_f32_16x16x32_bf16 v[62:65], v[86:89], v[78:81], v[62:65]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_add_i32 s69, s69, 0x80000
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_ldexp_f32 v24, v27, s17
	s_or_b64 s[18:19], s[6:7], s[18:19]
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[70:73], v[86:89], v[74:77], v[70:73]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_add_u32_e32 v51, 0x40000, v51
	v_add_u32_e32 v52, 0x40000, v52
	v_add_u32_e32 v54, 0x80000, v54
	v_add_u32_e32 v55, 0x80000, v55
	v_add_u32_e32 v49, 0x2000, v49
	s_cmp_lg_u32 s64, s52
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[14:15], v[14:15], v[24:25], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[10:11], v[24:25], v[64:65] op_sel_hi:[1,0,1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[12:13], v[12:13], v[24:25], v[70:71] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[8:9], v[24:25], v[72:73] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v24, v68
	v_mov_b32_e32 v25, v69
	v_mov_b32_e32 v27, v67
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cbranch_scc1 .LBB0_7
; %bb.8:                                ; %._crit_edge
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[52:53]
	v_add3_u32 v23, v44, v43, 64
	v_lshlrev_b64 v[6:7], 12, v[0:1]
	s_mov_b64 s[50:51], s[18:19]
	v_mov_b32_e32 v24, v68
	v_mov_b32_e32 v25, v69
	v_mov_b32_e32 v27, v67
	s_mov_b64 s[40:41], s[12:13]
	s_branch .LBB0_10
.LBB0_9:
	.loc	1 0 21 is_stmt 0                ; chunk_delta_h.py:0:21
	s_mov_b32 s60, 0
	s_add_i32 s71, 0, 0x41e0
	s_add_i32 s16, 0, 0x83c0
	s_add_i32 s59, 0, 0xc5a0
.LBB0_10:
	.loc	1 132 21 is_stmt 1              ; chunk_delta_h.py:132:21
	s_max_i32 s4, s61, 0
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_or_b32_e32 v0, s57, v42
	s_movk_i32 s6, 0x88
	.loc	1 134 16                        ; chunk_delta_h.py:134:16
	s_add_i32 s5, s4, s44
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_or_b32_e32 v16, v0, v3
	s_add_i32 s4, 0, 0x10780
	v_bitop3_b32 v17, v0, s6, v3 bitop3:0x36
	v_add_u32_e32 v7, s4, v16
	v_cvt_pk_bf16_f32 v46, v14, s0
	v_cvt_pk_bf16_f32 v47, v15, s0
	v_add_u32_e32 v3, s4, v17
	v_cvt_pk_bf16_f32 v48, v10, s0
	v_cvt_pk_bf16_f32 v49, v11, s0
	v_add_u32_e32 v18, s4, v33
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	ds_write_b16 v7, v46
	ds_write_b16 v7, v47 offset:512
	ds_write_b16 v3, v48
	ds_write_b16 v3, v49 offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v42, s4, v34
	ds_read_u16 v0, v18
	ds_read_u16 v1, v18 offset:4
	ds_read_u16 v19, v42
	ds_read_u16 v20, v42 offset:4
	.loc	1 134 16                        ; chunk_delta_h.py:134:16
	s_lshl_b32 s5, s5, 19
	s_add_i32 s5, s5, s56
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_add_u32_e32 v2, s5, v2
	s_mov_b32 s5, 0x5040100
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v0, v19, v0, s5
	v_add_lshl_u32 v19, v2, s34, 1
	v_bfrev_b32_e32 v43, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, s[0:1], s[2:3]
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v1, v20, v1, s5
	v_cndmask_b32_e32 v19, v43, v19, vcc
	s_mov_b32 s42, s14
	s_mov_b32 s43, s15
	buffer_store_dwordx2 v[0:1], v19, s[40:43], 0 offen
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	v_cvt_pk_bf16_f32 v19, v12, s0
	v_cvt_pk_bf16_f32 v20, v13, s0
	v_cvt_pk_bf16_f32 v21, v8, s0
	v_cvt_pk_bf16_f32 v22, v9, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v7, v19
	ds_write_b16 v7, v20 offset:512
	ds_write_b16 v3, v21
	ds_write_b16 v3, v22 offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v0, v18
	ds_read_u16 v1, v18 offset:4
	ds_read_u16 v3, v42 offset:4
	ds_read_u16 v7, v42
	v_add_lshl_u32 v2, v2, s45, 1
	v_cndmask_b32_e32 v2, v43, v2, vcc
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v18, s4, v40
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v1, v3, v1, s5
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v0, v7, v0, s5
	buffer_store_dwordx2 v[0:1], v2, s[40:43], 0 offen
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v0, s60, v39
	v_add_u32_e32 v1, s60, v23
	ds_read_b128 v[42:45], v0
	ds_read_b128 v[0:3], v1
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	v_cndmask_b32_e64 v40, 0, 1, s[0:1]
	.loc	1 157 44 is_stmt 0              ; chunk_delta_h.py:157:44
	v_add_u32_e32 v7, s4, v41
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	v_cmp_ne_u32_e64 s[2:3], 1, v40
	s_andn2_b64 vcc, exec, s[0:1]
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v18, v46
	ds_write_b16 v18, v47 offset:128
	ds_write_b16 v7, v48
	ds_write_b16 v7, v49 offset:128
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_cbranch_vccnz .LBB0_12
; %bb.11:
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v40, s4, v5
	ds_read_b128 v[48:51], v40
	v_add_u32_e32 v46, s4, v35
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[40:43], v[48:51], v[42:45], 0
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_read_b128 v[44:47], v46
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[44:47], v[0:3], v[40:43]
	s_branch .LBB0_13
.LBB0_12:
	.loc	1 0 0                           ; chunk_delta_h.py:0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
.LBB0_13:
	.loc	1 162 26 is_stmt 1              ; chunk_delta_h.py:162:26
	v_add_u32_e32 v39, s71, v39
	v_add_u32_e32 v23, s71, v23
	ds_read_b128 v[44:47], v39
	s_nop 0
	ds_read_b128 v[40:43], v23
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_and_b64 vcc, exec, s[2:3]
	.loc	1 163 49 is_stmt 0              ; chunk_delta_h.py:163:49
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v18, v19
	ds_write_b16 v18, v20 offset:128
	ds_write_b16 v7, v21
	ds_write_b16 v7, v22 offset:128
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_cbranch_vccnz .LBB0_15
; %bb.14:
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	v_add_u32_e32 v19, s4, v5
	ds_read_b128 v[20:23], v19
	v_add_u32_e32 v19, s4, v35
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[20:23], v[44:47], v[0:3]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_read_b128 v[20:23], v19
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[20:23], v[40:43], v[0:3]
.LBB0_15:
	.loc	1 179 52 is_stmt 1              ; chunk_delta_h.py:179:52
	v_and_or_b32 v19, v38, 60, v37
	v_lshlrev_b32_e32 v19, 2, v19
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add3_u32 v4, v6, v4, s33
	ds_bpermute_b32 v4, v19, v4
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	ds_bpermute_b32 v22, v19, v25
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_bfrev_b32_e32 v6, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, s[0:1], s[50:51]
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	ds_bpermute_b32 v20, v19, v24
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_waitcnt lgkmcnt(2)
	v_lshlrev_b32_e32 v4, 1, v4
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v23, 0xffff0000, v22
	v_lshlrev_b32_e32 v22, 16, v22
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_cndmask_b32_e32 v4, v6, v4, vcc
	.loc	1 194 44                        ; chunk_delta_h.py:194:44
	v_sub_f32_e32 v6, v26, v27
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_pk_add_f32 v[2:3], v[22:23], v[2:3] neg_lo:[0,1] neg_hi:[0,1]
.Ltmp22:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_mul_f32_e32 v19, 0x3fb8aa3b, v6
	.loc	3 27 35 is_stmt 0               ; op.py:27:35 @[ chunk_delta_h.py:194:33 ]
	v_mov_b32_e32 v22, 0xff800000
	.loc	3 27 29                         ; op.py:27:29 @[ chunk_delta_h.py:194:33 ]
	v_cmp_ge_f32_e32 vcc, 0, v6
	s_mov_b32 s5, 0xc2fc0000
.Ltmp23:
	.loc	1 179 52 is_stmt 1              ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v21, 0xffff0000, v20
.Ltmp24:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e32 v6, v22, v19, vcc
	.loc	3 27 15 is_stmt 0               ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_mov_b32_e32 v19, 0x42800000
	v_cmp_gt_f32_e32 vcc, s5, v6
.Ltmp25:
	.loc	1 179 52 is_stmt 1              ; chunk_delta_h.py:179:52
	v_lshlrev_b32_e32 v20, 16, v20
	v_pk_add_f32 v[0:1], v[20:21], v[0:1] neg_lo:[0,1] neg_hi:[0,1]
.Ltmp26:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e32 v19, 0, v19, vcc
	v_add_f32_e32 v6, v6, v19
	v_exp_f32_e32 v6, v6
.Ltmp27:
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_cvt_pk_bf16_f32 v20, v0, v1
	v_cvt_pk_bf16_f32 v21, v2, v3
	.loc	1 185 26 is_stmt 0              ; chunk_delta_h.py:185:26
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s11, 0x27000
	s_mov_b32 s10, 0x7ffffffe
	buffer_store_dwordx2 v[20:21], v4, s[8:11], 0 offen
.Ltmp28:
	.loc	3 27 15 is_stmt 1               ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_not_b32_e32 v4, 63
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_ldexp_f32 v4, v6, v4
.Ltmp29:
	.loc	1 194 24                        ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[20:21], v[4:5], v[0:1] op_sel_hi:[0,1]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_and_b32_e32 v0, 0x98, v30
	v_lshl_or_b32 v0, v31, 8, v0
	s_movk_i32 s5, 0xe0
	v_mov_b32_e32 v1, 0x80
	v_or3_b32 v0, s35, v0, v32
	v_bitop3_b32 v1, v36, s5, v1 bitop3:0xc8
	.loc	1 194 24                        ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[22:23], v[4:5], v[2:3] op_sel_hi:[0,1]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v4, v0, v36
	v_add_u32_e32 v6, v1, v0
	v_add_u32_e32 v2, s16, v4
	v_add_u32_e32 v19, s16, v6
	ds_read_b64_tr_b16 v[0:1], v2
	ds_read_b64_tr_b16 v[2:3], v2 offset:256
	ds_read_b64_tr_b16 v[36:37], v19 offset:4096
	ds_read_b64_tr_b16 v[38:39], v19 offset:4352
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	v_cvt_pk_bf16_f32 v19, v20, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v18, v19
	v_cvt_pk_bf16_f32 v19, v21, s0
	ds_write_b16 v18, v19 offset:128
	v_cvt_pk_bf16_f32 v18, v22, s0
	ds_write_b16 v7, v18
	v_cvt_pk_bf16_f32 v18, v23, s0
	v_add_u32_e32 v5, s4, v5
	ds_write_b16 v7, v18 offset:128
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v7, s4, v35
	ds_read_b128 v[18:21], v5
	ds_read_b128 v[22:25], v7
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_18
; %bb.16:
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[18:21], v[0:3], 0
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[22:25], v[36:39], v[0:3]
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_19
.LBB0_17:
	.loc	1 0 0 is_stmt 0                 ; chunk_delta_h.py:0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_branch .LBB0_20
.LBB0_18:
	.loc	1 0 0                           ; chunk_delta_h.py:0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	.loc	1 248 41 is_stmt 1              ; chunk_delta_h.py:248:41
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_17
.LBB0_19:
	.loc	1 0 0 is_stmt 0                 ; chunk_delta_h.py:0
	v_add_u32_e32 v4, s59, v4
	ds_read_b64_tr_b16 v[36:37], v4
	ds_read_b64_tr_b16 v[38:39], v4 offset:256
	v_add_u32_e32 v4, s59, v6
	ds_read_b64_tr_b16 v[40:41], v4 offset:4096
	ds_read_b64_tr_b16 v[42:43], v4 offset:4352
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[18:21], v[36:39], 0
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[22:25], v[40:43], v[4:7]
.LBB0_20:
	.loc	1 195 27 is_stmt 1              ; chunk_delta_h.py:195:27
	s_waitcnt lgkmcnt(1)
	v_mul_f32_e32 v18, 0x3fb8aa3b, v26
	s_mov_b32 s2, 0xc2fc0000
	v_mov_b32_e32 v19, 0x42800000
	v_cmp_gt_f32_e32 vcc, s2, v18
	s_and_b64 s[2:3], vcc, exec
	s_cselect_b32 s2, 0xffffffc0, 0
	v_cndmask_b32_e32 v18, 0, v19, vcc
	v_fmac_f32_e32 v18, 0x3fb8aa3b, v26
	v_exp_f32_e32 v18, v18
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	s_mov_b32 s22, s26
	s_mov_b32 s23, s27
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_ldexp_f32 v18, v18, s2
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[14:15], v[18:19], v[0:1] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v15, v15, v1, s[0:1]
	v_cndmask_b32_e64 v14, v14, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[10:11], v[18:19], v[2:3] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v2, v11, v1, s[0:1]
	v_cndmask_b32_e64 v3, v10, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[12:13], v[18:19], v[4:5] op_sel_hi:[1,0,1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	v_add_u32_e32 v10, 0, v16
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v5, v12, v0, s[0:1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	v_cvt_pk_bf16_f32 v0, v14, s0
	ds_write_b16 v10, v0
	v_cvt_pk_bf16_f32 v0, v15, s0
	ds_write_b16 v10, v0 offset:512
	v_cvt_pk_bf16_f32 v0, v3, s0
	v_add_u32_e32 v3, 0, v17
	ds_write_b16 v3, v0
	v_cvt_pk_bf16_f32 v0, v2, s0
	v_add_u32_e32 v2, 0, v33
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v4, v13, v1, s[0:1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	ds_write_b16 v3, v0 offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v11, 0, v34
	ds_read_u16 v12, v2
	ds_read_u16 v13, v2 offset:4
	ds_read_u16 v14, v11
	ds_read_u16 v15, v11 offset:4
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[8:9], v[18:19], v[6:7] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v6, v9, v1, s[0:1]
	v_cndmask_b32_e64 v7, v8, v0, s[0:1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	s_mov_b32 s0, 0x5040100
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v1, v15, v13, s0
	v_perm_b32 v0, v14, v12, s0
	buffer_store_dwordx2 v[0:1], v28, s[20:23], 0 offen
	.loc	1 270 27                        ; chunk_delta_h.py:270:27
	v_cvt_pk_bf16_f32 v0, v5, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v10, v0
	v_cvt_pk_bf16_f32 v0, v4, s0
	ds_write_b16 v10, v0 offset:512
	v_cvt_pk_bf16_f32 v0, v7, s0
	ds_write_b16 v3, v0
	v_cvt_pk_bf16_f32 v0, v6, s0
	ds_write_b16 v3, v0 offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v0, v2
	ds_read_u16 v1, v2 offset:4
	ds_read_u16 v2, v11 offset:4
	ds_read_u16 v3, v11
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v1, v2, v1, s0
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v0, v3, v0, s0
	buffer_store_dwordx2 v[0:1], v29, s[20:23], 0 offen
	.loc	1 263 4                         ; chunk_delta_h.py:263:4
	s_endpgm
.Ltmp30:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 102
		.amdhsa_next_free_sgpr 74
		.amdhsa_accum_offset 104
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
	.size	qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950, .Lfunc_end0-qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.num_vgpr, 102
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.num_agpr, 0
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.numbered_sgpr, 74
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.num_named_barrier, 0
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.private_seg_size, 0
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.uses_vcc, 1
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.uses_flat_scratch, 0
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.has_dyn_sized_stack, 0
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.has_recursion, 0
	.set qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 6424
; TotalNumSgprs: 80
; NumVgprs: 102
; NumAgprs: 0
; TotalNumVgprs: 102
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 9
; VGPRBlocks: 12
; NumSGPRsForWavesPerEU: 80
; NumVGPRsForWavesPerEU: 102
; AccumOffset: 104
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 25
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
	.byte	75                              ; DW_AT_call_line
	.byte	24                              ; DW_AT_call_column
	.byte	4                               ; Abbrev [4] 0x4d:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	194                             ; DW_AT_call_line
	.byte	33                              ; DW_AT_call_column
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
	.quad	0
	.quad	0
.Ldebug_ranges1:
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
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"chunk_delta_h.py"              ; string offset=7
.Linfo_string2:
	.asciz	"/netra-server/python/sglang/srt/layers/attention/fla" ; string offset=24
.Linfo_string3:
	.asciz	"qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950" ; string offset=77
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
    .max_flat_workgroup_size: 256
    .name:           qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     80
    .sgpr_spill_count: 0
    .symbol:         qwen36_gdn_h_m8192_bv16_triton_oracle_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     102
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
