// SPDX-License-Identifier: MIT
//
// Compiler-derived gfx950 oracle for the deployed high-parallelism BV32 GDN
// recurrence. This quarantined source is not an accepted Netra replacement;
// it fixes the exact code-object ABI and instruction stream from which the
// separately named hand-scheduled wave64 kernel is being derived.
//
// Captured current-stack shape:
//   varlen B=1, N=16, T=16384, per-sequence T=1024
//   H=32, Hg=16, K=V=128, BT=64, BV=32
//   grid=(4,512,1), block=(256,1,1), dynamic LDS=72,064 bytes
// Triton 3.6.0 options: four wave64 waves, two stages, kpack=1.
// Captured AMDGCN SHA-256:
//   f61a18f97d5d5d6abe288bf78db6ac26cb90b60cf56dff2483f560a7993549ce
// Captured HSACO SHA-256:
//   d153711ece41ea89c407c764a7c98abcf8713595fbbf9b65e65bda67a3f8838a

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950 ; -- Begin function qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950
	.p2align	8
	.type	qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950,@function
qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950: ; @qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950
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
	s_mov_b64 s[44:45], s[2:3]
	s_load_dwordx4 s[28:31], s[0:1], 0x38
	s_load_dwordx2 s[2:3], s[0:1], 0x48
.Ltmp1:
	.loc	1 69 23 is_stmt 1               ; chunk_delta_h.py:69:23
	s_ashr_i32 s0, s17, 31
	s_lshr_b32 s0, s0, 27
	s_add_i32 s0, s17, s0
	s_ashr_i32 s22, s0, 5
	s_mov_b64 s[36:37], s[14:15]
	.loc	1 270 27                        ; chunk_delta_h.py:270:27
	v_readfirstlane_b32 s14, v0
	.loc	1 69 33                         ; chunk_delta_h.py:69:33
	s_andn2_b32 s0, s0, 31
	.loc	1 71 27                         ; chunk_delta_h.py:71:27
	s_ashr_i32 s23, s22, 31
	.loc	1 270 27                        ; chunk_delta_h.py:270:27
	s_bfe_u32 s76, s14, 0x20006
	.loc	1 69 33                         ; chunk_delta_h.py:69:33
	s_sub_i32 s27, s17, s0
	.loc	1 71 27                         ; chunk_delta_h.py:71:27
	s_lshl_b64 s[0:1], s[22:23], 2
	s_mov_b64 s[40:41], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_add_u32 s6, s30, s0
	s_addc_u32 s7, s31, s1
	s_load_dwordx2 s[24:25], s[6:7], 0x0
	.loc	1 76 22                         ; chunk_delta_h.py:76:22
	s_lshl_b64 s[6:7], s[22:23], 3
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v1, 63, v0
	v_and_b32_e32 v19, 7, v0
	v_lshlrev_b32_e32 v23, 3, v19
	.loc	1 74 18                         ; chunk_delta_h.py:74:18
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s64, s25, s24
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 43 17                         ; standard.py:43:17 @[ chunk_delta_h.py:75:24 ]
	s_add_i32 s25, s64, 63
.Ltmp3:
	.loc	1 76 22                         ; chunk_delta_h.py:76:22
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	.loc	1 93 17                         ; chunk_delta_h.py:93:17
	s_lshl_b32 s26, s24, 5
	.loc	1 93 21 is_stmt 0               ; chunk_delta_h.py:93:21
	s_add_i32 s26, s26, s27
	.loc	1 92 32 is_stmt 1               ; chunk_delta_h.py:92:32
	s_lshl_b32 s77, s27, 14
	.loc	1 93 28                         ; chunk_delta_h.py:93:28
	s_lshl_b32 s33, s26, 7
	.loc	1 103 20                        ; chunk_delta_h.py:103:20
	s_add_u32 s0, s28, s0
	s_addc_u32 s1, s29, s1
	s_load_dword s6, s[0:1], 0x0
	.loc	1 76 22                         ; chunk_delta_h.py:76:22
	s_load_dwordx2 s[60:61], s[2:3], 0x0
	.loc	1 113 62                        ; chunk_delta_h.py:113:62
	s_lshl_b32 s58, s16, 5
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	s_lshl_b32 s23, s76, 6
	.loc	1 113 80                        ; chunk_delta_h.py:113:80
	s_ashr_i32 s59, s58, 31
	.loc	1 104 33                        ; chunk_delta_h.py:104:33
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s0, s6, 19
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v10, s23, v1
	.loc	1 107 18                        ; chunk_delta_h.py:107:18
	s_add_i32 s0, s0, s77
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v4, 3, v10
	s_and_b32 s28, s14, 64
	s_lshl_b64 s[62:63], s[58:59], 7
	v_or_b32_e32 v2, s58, v4
	v_mov_b32_e32 v3, s59
	s_cmp_gt_i32 s58, -1
	s_mov_b64 s[20:21], 0x80
	v_lshl_or_b32 v70, v4, 7, v23
	s_cselect_b64 s[14:15], -1, 0
	v_cmp_gt_i64_e32 vcc, s[20:21], v[2:3]
	v_or_b32_e32 v2, s0, v70
	s_mov_b32 s43, 0x27000
	s_mov_b32 s42, 0x7ffffffe
	v_add_lshl_u32 v3, v2, s62, 1
	v_bfrev_b32_e32 v20, 1
	s_and_b64 s[18:19], s[14:15], vcc
	s_and_b32 s37, s37, 0xffff
	s_mov_b32 s38, s42
	s_mov_b32 s39, s43
	v_cndmask_b32_e64 v71, v20, v3, s[18:19]
	buffer_load_dwordx4 v[6:9], v71, s[36:39], 0 offen
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	s_lshr_b32 s0, s28, 5
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_and_b32_e32 v86, 32, v0
	s_cmp_lt_u32 s76, 2
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_bfe_i32 v3, v0, 4, 1
	v_lshrrev_b32_e32 v103, 3, v86
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	s_cselect_b64 s[56:57], -1, 0
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_and_b32_e32 v87, 8, v0
	v_and_b32_e32 v100, 0x108, v3
	v_or_b32_e32 v101, s0, v103
	s_and_b64 s[0:1], s[56:57], exec
	v_lshl_or_b32 v3, v87, 7, v100
	s_cselect_b32 s63, 0, 0x80
	v_lshlrev_b32_e32 v90, 4, v19
	s_cselect_b32 s61, 0, 64
	.loc	1 119 28 is_stmt 1              ; chunk_delta_h.py:119:28
	s_or_b32 s78, s62, 64
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_or3_b32 v3, v101, v3, s63
	s_movk_i32 s2, 0x48
	.loc	1 119 28                        ; chunk_delta_h.py:119:28
	v_add_lshl_u32 v2, v2, s78, 1
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_or_b32_e32 v4, v3, v90
	v_bitop3_b32 v3, v3, s2, v90 bitop3:0x36
	.loc	1 119 28                        ; chunk_delta_h.py:119:28
	v_cndmask_b32_e64 v84, v20, v2, s[18:19]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_add_u32_e32 v11, 0, v4
	v_xad_u32 v12, v4, 8, 0
	v_xad_u32 v13, v4, 64, 0
	v_add_u32_e32 v14, 0, v3
	.loc	1 114 24 is_stmt 0              ; chunk_delta_h.py:114:24
	v_and_b32_e32 v88, 3, v0
	v_lshlrev_b32_e32 v85, 3, v88
	v_or_b32_e32 v68, s58, v85
	v_mov_b32_e32 v69, s59
	v_and_b32_e32 v18, 56, v0
	.loc	1 179 22 is_stmt 1              ; chunk_delta_h.py:179:22
	v_cmp_gt_i64_e64 s[0:1], s[20:21], v[68:69]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_and_b32_e32 v26, 24, v0
	v_and_b32_e32 v89, 2, v0
	v_bfe_i32 v2, v0, 2, 1
	.loc	1 114 24 is_stmt 0              ; chunk_delta_h.py:114:24
	v_or_b32_e32 v4, s76, v18
	.loc	1 154 63 is_stmt 1              ; chunk_delta_h.py:154:63
	s_ashr_i32 s65, s64, 31
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_and_b64 s[68:69], s[14:15], s[0:1]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_and_b32_e32 v27, 1, v0
	v_lshlrev_b32_e32 v3, 1, v26
	v_lshlrev_b32_e32 v105, 2, v89
	v_and_b32_e32 v2, 0x240, v2
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmp_gt_i32 s25, 63
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_lshl_or_b32 v5, v27, 11, v105
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_mul_i32 s79, s76, 0x410
	v_cmp_gt_i32_e32 vcc, s64, v4
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_bitop3_b32 v107, s61, v2, v3 bitop3:0x1e
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cselect_b64 s[0:1], -1, 0
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_or3_b32 v2, v5, v103, v107
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 s6, s79, 0
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, vcc, s[0:1]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_and_b32 s41, s41, 0xffff
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_add_u32_e32 v15, 0, v2
	s_waitcnt vmcnt(0)
	ds_write_b16 v11, v6
	ds_write_b16_d16_hi v11, v6 offset:2048
	ds_write_b16 v12, v7
	ds_write_b16_d16_hi v12, v7 offset:2048
	ds_write_b16 v13, v8 offset:512
	ds_write_b16_d16_hi v13, v8 offset:2560
	ds_write_b16 v14, v9 offset:512
	ds_write_b16_d16_hi v14, v9 offset:2560
	.loc	1 114 24 is_stmt 0              ; chunk_delta_h.py:114:24
	v_or_b32_e32 v6, 4, v4
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	v_lshl_or_b32 v7, v4, 12, v23
	v_lshl_or_b32 v8, v6, 12, v23
	v_cmp_gt_i32_e64 s[2:3], s64, v6
	v_add_lshl_u32 v4, v7, s33, 1
	v_add_lshl_u32 v6, v8, s33, 1
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_or_b32_e32 v7, 0x80, v4
	v_or_b32_e32 v8, 0x80, v6
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_xad_u32 v16, v2, 8, 0
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 m0, s6, 0x8780
	s_add_i32 s7, s6, 0x97c0
	v_cndmask_b32_e32 v17, v20, v4, vcc
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[2:3], s[2:3], s[0:1]
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 s29, s6, 0xc870
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cndmask_b32_e64 v21, v20, v6, s[2:3]
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_add_u32_e32 v22, 0x400, v15
	v_add_u32_e32 v24, 0x400, v16
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_cndmask_b32_e32 v25, v20, v7, vcc
	v_cndmask_b32_e64 v28, v20, v8, s[2:3]
	s_add_i32 s6, s6, 0xd8b0
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_and_b32 s5, s5, 0xffff
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_mov_b32_e32 v106, 0
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	v_and_b32_e32 v69, 16, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 119 28 is_stmt 1              ; chunk_delta_h.py:119:28
	buffer_load_dwordx4 v[30:33], v84, s[36:39], 0 offen
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	ds_read2_b32 v[2:3], v15 offset1:32
	ds_read2_b32 v[6:7], v22 offset1:32
	ds_read2_b32 v[4:5], v16 offset0:64 offset1:96
	ds_read2_b32 v[8:9], v24 offset0:64 offset1:96
	.loc	1 119 20                        ; chunk_delta_h.py:119:20
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write_b16 v11, v30
	ds_write_b16_d16_hi v11, v30 offset:2048
	ds_write_b16 v12, v31
	ds_write_b16_d16_hi v12, v31 offset:2048
	ds_write_b16 v13, v32 offset:512
	ds_write_b16_d16_hi v13, v32 offset:2560
	ds_write_b16 v14, v33 offset:512
	ds_write_b16_d16_hi v14, v33 offset:2560
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	buffer_load_dwordx4 v17, s[40:43], 0 offen lds
	s_mov_b32 m0, s7
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_mov_b32 s7, s43
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	buffer_load_dwordx4 v21, s[40:43], 0 offen lds
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_mov_b32 m0, s29
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v21, 2, v10
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v25, s[40:43], 0 offen lds
	s_mov_b32 m0, s6
	.loc	1 119 20                        ; chunk_delta_h.py:119:20
	s_waitcnt vmcnt(0)
	ds_read2_b32 v[10:11], v15 offset1:32
	ds_read2_b32 v[14:15], v22 offset1:32
	ds_read2_b32 v[12:13], v16 offset0:64 offset1:96
	ds_read2_b32 v[16:17], v24 offset0:64 offset1:96
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v28, s[40:43], 0 offen lds
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cmp_gt_i32_e32 vcc, s64, v21
	v_lshlrev_b32_e32 v24, 12, v21
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_add_i32 s6, s58, s33
	s_and_b64 s[2:3], s[68:69], vcc
	v_or_b32_e32 v21, v24, v85
	v_add_lshl_u32 v21, s6, v21, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, s[0:1], s[2:3]
	s_cmp_lt_i32 s25, 64
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_mov_b32 s6, s42
	v_cndmask_b32_e32 v21, v20, v21, vcc
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_cbranch_scc1 .LBB0_2
; %bb.1:
	.loc	1 0 31 is_stmt 0                ; chunk_delta_h.py:0:31
	s_min_u32 s2, s64, 64
	s_lshl_b32 s2, s2, 5
	s_add_i32 s2, s26, s2
	s_sub_i32 s2, s2, 32
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s2, s10, s2
	s_addc_u32 s3, s11, s3
	v_mov_b32_e32 v22, 0
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	global_load_dword v106, v22, s[2:3]
.LBB0_2:
.Ltmp4:
	.loc	2 43 30 is_stmt 1               ; standard.py:43:30 @[ chunk_delta_h.py:75:24 ]
	s_ashr_i32 s2, s25, 31
	s_lshr_b32 s2, s2, 26
	s_add_i32 s2, s25, s2
	s_ashr_i32 s31, s2, 6
.Ltmp5:
	.loc	1 94 30                         ; chunk_delta_h.py:94:30
	s_bfe_u32 s2, s27, 0x10007
	s_add_i32 s27, s27, s2
	s_sext_i32_i8 s2, s27
	s_ashr_i32 s27, s2, 1
	.loc	1 94 42 is_stmt 0               ; chunk_delta_h.py:94:42
	s_lshl_b32 s2, s24, 11
	s_lshl_b32 s3, s27, 7
	buffer_load_dwordx4 v[32:35], v21, s[4:7], 0 offen
	s_add_i32 s6, s2, s3
	.loc	1 114 24 is_stmt 1              ; chunk_delta_h.py:114:24
	s_cmp_eq_u32 s28, 0
	s_cselect_b64 s[38:39], -1, 0
	s_lshr_b32 s28, s28, 6
	v_lshrrev_b32_e32 v21, 2, v18
	s_and_b64 s[2:3], s[56:57], exec
	s_cselect_b32 s29, 0, 16
	v_or_b32_e32 v22, s28, v21
	v_or_b32_e32 v28, s29, v22
	v_and_b32_e32 v22, 31, v0
	s_cselect_b32 s30, 0, 32
	v_or_b32_e32 v25, s30, v22
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cmp_gt_i32_e32 vcc, s64, v25
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	v_lshlrev_b32_e32 v25, 7, v25
	v_lshl_add_u32 v25, s26, 2, v25
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[2:3], s[0:1], vcc
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v29, 32, v28
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	v_cndmask_b32_e64 v25, v20, v25, s[2:3]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_lshlrev_b32_e32 v30, 11, v28
	v_or_b32_e32 v23, s6, v23
	v_cmp_gt_i32_e64 s[2:3], s64, v28
	s_mul_i32 s80, s76, 0x440
	v_lshlrev_b32_e32 v31, 11, v29
	v_cmp_gt_i32_e64 s[6:7], s64, v29
	s_add_i32 s34, s80, 0
	v_add_lshl_u32 v28, v30, v23, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[2:3], s[0:1], s[2:3]
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	s_and_b32 s49, s11, 0xffff
	s_mov_b32 s48, s10
	s_mov_b32 s50, s42
	s_mov_b32 s51, s43
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_and_b32 s45, s45, 0xffff
	s_mov_b32 s46, s42
	s_mov_b32 s47, s43
	v_cndmask_b32_e64 v29, v20, v28, s[2:3]
	s_mov_b32 m0, s34
	v_add_lshl_u32 v23, v31, v23, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[6:7], s[0:1], s[6:7]
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	buffer_load_dword v25, v25, s[48:51], 0 offen
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_waitcnt lgkmcnt(0)
	s_barrier
	buffer_load_dwordx4 v29, s[44:47], 0 offen lds
	s_add_i32 m0, s34, 0x1100
	v_cndmask_b32_e64 v29, v20, v23, s[6:7]
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_or_b32_e32 v28, 0x80, v28
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	buffer_load_dwordx4 v29, s[44:47], 0 offen lds
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	s_add_i32 m0, s34, 0x43c0
	v_cndmask_b32_e64 v28, v20, v28, s[2:3]
	v_or_b32_e32 v23, 0x80, v23
	buffer_load_dwordx4 v28, s[44:47], 0 offen lds
	s_add_i32 m0, s34, 0x54c0
	v_cndmask_b32_e64 v20, v20, v23, s[6:7]
	buffer_load_dwordx4 v20, s[44:47], 0 offen lds
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_lshrrev_b32_e32 v20, 2, v86
	v_or_b32_e32 v28, s58, v20
	v_mov_b32_e32 v29, s59
	.loc	1 114 58 is_stmt 0              ; chunk_delta_h.py:114:58
	v_lshlrev_b32_e32 v31, 16, v6
	v_lshlrev_b32_e32 v30, 16, v2
	v_lshlrev_b32_e32 v37, 16, v8
	v_lshlrev_b32_e32 v36, 16, v4
	v_and_b32_e32 v39, 0xffff0000, v6
	v_and_b32_e32 v38, 0xffff0000, v2
	v_and_b32_e32 v41, 0xffff0000, v8
	v_and_b32_e32 v40, 0xffff0000, v4
	v_lshlrev_b32_e32 v43, 16, v7
	v_lshlrev_b32_e32 v42, 16, v3
	v_and_b32_e32 v7, 0xffff0000, v7
	v_and_b32_e32 v6, 0xffff0000, v3
	v_and_b32_e32 v3, 0xffff0000, v9
	v_and_b32_e32 v2, 0xffff0000, v5
	.loc	1 179 22 is_stmt 1              ; chunk_delta_h.py:179:22
	v_cmp_gt_i64_e64 s[6:7], s[20:21], v[28:29]
	.loc	1 114 58                        ; chunk_delta_h.py:114:58
	v_lshlrev_b32_e32 v45, 16, v9
	v_lshlrev_b32_e32 v44, 16, v5
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	v_pk_add_f32 v[66:67], v[30:31], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[62:63], v[36:37], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[54:55], v[40:41], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[50:51], v[42:43], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[42:43], v[6:7], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[40:41], v[2:3], 0 op_sel_hi:[1,0]
	.loc	1 119 62 is_stmt 1              ; chunk_delta_h.py:119:62
	v_lshlrev_b32_e32 v3, 16, v14
	v_lshlrev_b32_e32 v2, 16, v10
	v_lshlrev_b32_e32 v5, 16, v16
	v_lshlrev_b32_e32 v4, 16, v12
	v_and_b32_e32 v7, 0xffff0000, v14
	v_and_b32_e32 v6, 0xffff0000, v10
	v_and_b32_e32 v9, 0xffff0000, v16
	v_and_b32_e32 v8, 0xffff0000, v12
	v_lshlrev_b32_e32 v31, 16, v15
	v_lshlrev_b32_e32 v30, 16, v11
	v_lshlrev_b32_e32 v37, 16, v17
	v_lshlrev_b32_e32 v36, 16, v13
	v_and_b32_e32 v15, 0xffff0000, v15
	v_and_b32_e32 v14, 0xffff0000, v11
	v_and_b32_e32 v11, 0xffff0000, v17
	v_and_b32_e32 v10, 0xffff0000, v13
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 s[70:71], s[6:7], s[14:15]
	v_cmp_eq_u32_e64 s[34:35], 0, v69
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_cmp_eq_u32_e64 s[2:3], 0, v86
	.loc	1 114 16 is_stmt 0              ; chunk_delta_h.py:114:16
	v_pk_add_f32 v[58:59], v[38:39], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[46:47], v[44:45], 0 op_sel_hi:[1,0]
	.loc	1 119 20 is_stmt 1              ; chunk_delta_h.py:119:20
	v_pk_add_f32 v[64:65], v[2:3], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[60:61], v[4:5], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[56:57], v[6:7], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[52:53], v[8:9], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[48:49], v[30:31], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[44:45], v[36:37], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[38:39], v[14:15], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[36:37], v[10:11], 0 op_sel_hi:[1,0]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmpk_gt_i32 s25, 0x7f
	v_lshlrev_b32_e32 v98, 10, v27
	v_lshlrev_b32_e32 v102, 8, v87
	v_lshlrev_b32_e32 v6, 4, v26
	v_lshrrev_b32_e32 v3, 1, v86
	v_lshlrev_b32_e32 v5, 1, v22
	v_lshlrev_b32_e32 v2, 7, v22
	v_lshlrev_b32_e32 v4, 3, v0
	s_cbranch_scc1 .LBB0_4
; %bb.3:                                ; %._crit_edge417
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_and_b32 s21, s13, 0xffff
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_and_b64 s[6:7], s[56:57], exec
	s_cselect_b32 s6, 0, 0x200
	v_lshl_or_b32 v7, v19, 10, s6
	v_or3_b32 v7, v7, v6, v3
	v_add_u32_e32 v108, v7, v90
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_mov_b32_e32 v7, 0x220
	v_cndmask_b32_e64 v7, v7, 0, s[2:3]
	v_xor_b32_e32 v8, v7, v5
	v_bitop3_b32 v112, s61, v7, v5 bitop3:0xf6
	v_mov_b32_e32 v7, 0x110
	v_bitop3_b32 v111, s61, v7, v8 bitop3:0x36
	v_mov_b32_e32 v7, 0x440
	v_bitop3_b32 v110, s61, v7, v8 bitop3:0x36
	v_mov_b32_e32 v7, 0x550
	s_movk_i32 s7, 0x70
	s_movk_i32 s6, 0x60
	v_bitop3_b32 v109, s61, v7, v8 bitop3:0x36
	v_and_b32_e32 v7, 0x70, v4
	v_bitop3_b32 v8, v4, v3, s7 bitop3:0x6c
	s_mov_b32 s15, 0x27000
	s_mov_b32 s14, 0x7ffffffe
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_mov_b32 s20, s12
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v16, 32, v108
	v_add_u32_e32 v17, 64, v108
	v_add_u32_e32 v20, 0x60, v108
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_bitop3_b32 v92, v7, v2, v3 bitop3:0xde
	v_bitop3_b32 v93, v8, 32, v2 bitop3:0x36
	v_bitop3_b32 v94, v8, 64, v2 bitop3:0x36
	v_bitop3_b32 v95, v8, s6, v2 bitop3:0x36
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_5
.LBB0_4:
	.loc	1 0 44 is_stmt 0                ; chunk_delta_h.py:0:44
	s_mov_b64 s[6:7], -1
                                        ; implicit-def: $sgpr20_sgpr21
                                        ; implicit-def: $vgpr108
                                        ; implicit-def: $vgpr16
                                        ; implicit-def: $vgpr17
                                        ; implicit-def: $vgpr20
                                        ; implicit-def: $vgpr112
                                        ; implicit-def: $vgpr111
                                        ; implicit-def: $vgpr110
                                        ; implicit-def: $vgpr109
                                        ; implicit-def: $vgpr92
                                        ; implicit-def: $vgpr93
                                        ; implicit-def: $vgpr94
                                        ; implicit-def: $vgpr95
.LBB0_5:                                ; %Flow
	v_and_b32_e32 v91, 4, v0
	s_add_i32 s59, s31, -1
	s_and_b64 s[66:67], vcc, s[70:71]
	s_andn2_b64 vcc, exec, s[6:7]
	v_lshlrev_b32_e32 v104, 2, v0
	v_lshlrev_b32_e32 v99, 4, v0
	v_lshlrev_b32_e32 v96, 8, v91
	v_lshlrev_b32_e32 v97, 1, v69
	s_cbranch_vccnz .LBB0_9
; %bb.6:                                ; %.lr.ph
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	s_lshl_b32 s20, s76, 10
	s_or_b32 s6, s20, 0x1000
	s_lshr_b32 s21, s6, 4
	s_lshr_b32 s31, s6, 6
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_or_b32_e32 v7, v90, v100
	v_or3_b32 v8, v105, v103, v107
	s_movk_i32 s6, 0x108
	v_or3_b32 v7, v7, v101, s63
	v_or_b32_e32 v9, v98, v8
	v_bitop3_b32 v8, v98, s6, v8 bitop3:0x36
	s_movk_i32 s6, 0x240
	v_bitop3_b32 v12, v102, s6, v7 bitop3:0x36
	s_movk_i32 s6, 0x248
	s_and_b32 s13, s13, 0xffff
	v_or_b32_e32 v10, v102, v7
	v_bitop3_b32 v11, v102, 8, v7 bitop3:0x36
	v_bitop3_b32 v7, v102, s6, v7 bitop3:0x36
	s_and_b64 s[6:7], s[56:57], exec
	s_cselect_b32 s6, 0, 0x200
	v_lshl_or_b32 v13, v19, 10, s6
	v_or3_b32 v6, v13, v6, v3
	v_add_u32_e32 v108, v6, v90
	v_mov_b32_e32 v6, 0x220
	v_cndmask_b32_e64 v6, v6, 0, s[2:3]
	v_xor_b32_e32 v13, v6, v5
	v_bitop3_b32 v112, s61, v6, v5 bitop3:0xf6
	v_mov_b32_e32 v5, 0x110
	v_bitop3_b32 v111, s61, v5, v13 bitop3:0x36
	v_mov_b32_e32 v5, 0x440
	v_bitop3_b32 v110, s61, v5, v13 bitop3:0x36
	v_mov_b32_e32 v5, 0x550
	s_movk_i32 s6, 0x70
	v_bitop3_b32 v109, s61, v5, v13 bitop3:0x36
	v_and_b32_e32 v5, 0x70, v4
	v_bitop3_b32 v4, v4, v3, s6 bitop3:0x6c
	s_movk_i32 s6, 0x60
	v_bitop3_b32 v95, v4, s6, v2 bitop3:0x36
	s_and_b64 s[6:7], s[38:39], exec
	v_bitop3_b32 v92, v5, v2, v3 bitop3:0xde
	v_bitop3_b32 v93, v4, 32, v2 bitop3:0x36
	v_bitop3_b32 v94, v4, 64, v2 bitop3:0x36
	s_cselect_b32 s6, 0, 0x208
	v_mov_b32_e32 v2, 0x78
	v_bitop3_b32 v2, s6, v104, v2 bitop3:0x78
	s_add_i32 s6, 0, 0x10980
	v_lshl_add_u32 v3, v86, 6, s6
	v_add3_u32 v6, v3, v2, v98
	v_mov_b32_e32 v2, 0x208
	v_cndmask_b32_e64 v2, v2, 0, s[34:35]
	v_lshl_or_b32 v2, v86, 3, v2
	v_or3_b32 v2, s63, v2, v102
	v_or_b32_e32 v13, v2, v90
	v_bitop3_b32 v14, v2, 8, v90 bitop3:0x36
	v_and_b32_e32 v2, 0x280, v99
	v_or3_b32 v2, v2, v97, v96
	v_or3_b32 v3, v85, s61, v2
	v_or_b32_e32 v4, 0x800, v2
	v_or_b32_e32 v5, 0x1000, v2
	v_or_b32_e32 v2, 0x1800, v2
	v_lshrrev_b32_e32 v2, 4, v2
	v_lshrrev_b32_e32 v4, 4, v4
	v_lshrrev_b32_e32 v5, 4, v5
	v_and_b32_e32 v2, 0x1c0, v2
	s_or_b32 s82, s31, s20
	s_or_b32 s83, s21, s20
	s_lshl_b32 s20, s26, 8
	s_lshl_b32 s16, s16, 6
	v_and_b32_e32 v4, 0xc0, v4
	v_and_b32_e32 v5, 0x140, v5
	s_max_i32 s7, s59, 1
	v_add_u32_e32 v116, v2, v3
	v_add_u32_e32 v2, s30, v22
	s_add_i32 s20, s16, s20
	v_lshl_add_u32 v113, v91, 4, v3
	v_add_u32_e32 v114, v4, v3
	v_add_u32_e32 v115, v5, v3
	v_lshl_add_u32 v3, v2, 13, s20
	v_lshrrev_b32_e32 v4, 1, v0
	s_lshl_b32 s84, s7, 6
	s_add_i32 s7, s24, s30
	v_and_or_b32 v117, v4, 16, v3
	v_add_lshl_u32 v3, s7, v22, 7
	v_lshl_add_u32 v3, s17, 2, v3
	s_lshl_b32 s7, s22, 7
	v_subrev_u32_e32 v3, s7, v3
	s_add_i32 s7, s24, s29
	s_add_i32 s7, s7, s28
	s_lshl_b32 s7, s7, 12
	s_lshl_b32 s20, s27, 8
	v_add_u32_e32 v118, 0x2000, v3
	v_bfe_u32 v3, v0, 3, 3
	s_add_i32 s7, s20, s7
	v_lshl_add_u32 v0, v3, 13, s7
	s_lshl_b32 s7, s24, 12
	s_add_i32 s28, s28, s29
	v_add_u32_e32 v119, 0x60080, v0
	v_add_u32_e32 v0, s28, v21
	s_add_i32 s20, s20, s7
	v_lshl_add_u32 v120, v0, 12, s20
	s_lshl_b32 s20, s17, 8
	s_lshl_b32 s7, s24, 13
	v_add_u32_e32 v1, s23, v1
	s_add_i32 s16, s16, s20
	v_lshrrev_b32_e32 v72, 2, v1
	s_add_i32 s16, s16, s7
	v_lshl_add_u32 v1, v72, 13, s16
	s_lshl_b32 s21, s76, 13
	v_lshl_or_b32 v1, v88, 4, v1
	s_lshl_b32 s16, s22, 13
	s_add_i32 s20, s20, s21
	v_subrev_u32_e32 v1, s16, v1
	s_add_i32 s20, s20, s7
	v_add_u32_e32 v121, 0x80000, v1
	v_lshl_add_u32 v1, v3, 16, s20
	v_mov_b32_e32 v73, 0
	v_or_b32_e32 v1, v1, v90
	v_subrev_u32_e32 v122, s16, v1
	v_mov_b32_e32 v1, v73
	v_add_u32_e32 v4, 32, v0
	v_lshl_add_u64 v[76:77], v[0:1], 0, 64
	v_mov_b32_e32 v3, v73
	v_add_u32_e32 v0, s76, v18
	s_lshl_b32 s7, s60, 19
	s_lshl_b32 s16, s17, 14
	v_mov_b32_e32 v5, v73
	v_lshl_add_u64 v[78:79], v[2:3], 0, 64
	v_add_u32_e32 v2, 4, v0
	s_add_i32 s7, s7, s16
	s_lshl_b32 s16, s22, 19
	s_mov_b32 s15, 0x27000
	s_mov_b32 s14, 0x7ffffffe
	s_mov_b32 s25, 0
	s_and_b32 s53, s9, 0xffff
	s_mov_b32 s52, s8
	s_sub_i32 s81, s26, 32
	v_lshl_add_u64 v[74:75], v[4:5], 0, 64
	v_lshl_add_u64 v[80:81], v[2:3], 0, 64
	v_lshl_add_u64 v[82:83], v[0:1], 0, 64
	s_sub_i32 s85, s7, s16
	s_add_i32 s17, 0, 0x8780
	s_add_i32 s16, 0, 0xc870
	s_add_i32 s24, 0, 0x43c0
	s_mov_b64 s[74:75], 0
	s_mov_b32 s86, 0x5040100
	s_mov_b32 s87, 0x7060302
	s_add_i32 s88, 0, 0x10960
	v_add_u32_e32 v123, s63, v6
	s_mov_b32 s89, 0xc2fc0000
	v_add_u32_e32 v124, s6, v9
	v_add_u32_e32 v125, s6, v8
	v_add_u32_e32 v126, s6, v10
	v_add_u32_e32 v127, s6, v11
	v_add_u32_e32 v128, s6, v12
	v_add_u32_e32 v129, s6, v7
	v_bfrev_b32_e32 v130, 1
	v_add_u32_e32 v131, s6, v13
	v_add_u32_e32 v132, s6, v14
	v_mov_b32_e32 v133, 0xff800000
	v_mov_b32_e32 v134, 0x42800000
	v_not_b32_e32 v135, 63
	s_mov_b32 s90, 0
	s_mov_b32 s92, 0
                                        ; implicit-def: $sgpr72_sgpr73
.LBB0_7:                                ; =>This Inner Loop Header: Depth=1
	s_add_i32 s20, s92, 1
	.loc	1 136 31                        ; chunk_delta_h.py:136:31
	v_cvt_pk_bf16_f32 v14, v66, v67
	v_cvt_pk_bf16_f32 v12, v62, v63
	v_cvt_pk_bf16_f32 v11, v58, v59
	v_cvt_pk_bf16_f32 v10, v54, v55
	v_cvt_pk_bf16_f32 v15, v50, v51
	v_cvt_pk_bf16_f32 v13, v46, v47
	s_mov_b32 s22, s17
	s_mov_b32 s21, s16
	s_mov_b64 s[16:17], s[74:75]
	v_cvt_pk_bf16_f32 v23, v42, v43
	v_cvt_pk_bf16_f32 v22, v40, v41
	s_waitcnt vmcnt(6)
	v_mov_b32_e32 v152, v106
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmp_lt_i32 s20, 2
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v4, s90, v122
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_perm_b32 v178, v11, v14, s86
	v_perm_b32 v179, v11, v14, s87
	v_perm_b32 v180, v23, v15, s86
	v_perm_b32 v181, v23, v15, s87
	v_perm_b32 v182, v10, v12, s86
	v_perm_b32 v183, v10, v12, s87
	v_perm_b32 v184, v22, v13, s86
	v_perm_b32 v185, v22, v13, s87
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[2:3], v[82:83], 0, s[16:17]
	v_lshl_add_u64 v[0:1], v[80:81], 0, s[16:17]
	.loc	1 194 44                        ; chunk_delta_h.py:194:44
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v188, v152, v25
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cselect_b32 s92, s20, 0
	.loc	1 136 31                        ; chunk_delta_h.py:136:31
	s_add_i32 s74, s85, s90
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_add_u32_e32 v139, 0x800, v124
	v_add_u32_e32 v140, 0x800, v125
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v186, 0x80000, v4
	v_add_u32_e32 v187, 0x88000, v4
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_add_u32_e32 v172, 0x80080, v4
	v_add_u32_e32 v173, 0x88080, v4
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[4:5], v[78:79], 0, s[16:17]
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	ds_write2_b32 v124, v178, v180 offset1:32
	ds_write2_b32 v139, v179, v181 offset1:32
	ds_write2_b32 v125, v182, v184 offset1:32
	ds_write2_b32 v140, v183, v185 offset1:32
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v179, v128
	ds_read_u16 v180, v129
	ds_read_u16 v181, v129 offset:1024
	ds_read_u16 v182, v128 offset:1024
	ds_read_u16 v183, v127
	ds_read_u16 v184, v127 offset:1024
	ds_read_u16 v185, v126
	ds_read_u16 v192, v126 offset:1024
.Ltmp6:
	.file	3 "/netra-server/python/sglang/srt/layers/attention/fla" "op.py"
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_mul_f32_e32 v193, 0x3fb8aa3b, v188
	.loc	3 27 29 is_stmt 0               ; op.py:27:29 @[ chunk_delta_h.py:194:33 ]
	v_cmp_ge_f32_e64 s[26:27], 0, v188
.Ltmp7:
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	v_cmp_gt_i64_e64 s[28:29], s[64:65], v[2:3]
	v_cmp_gt_i64_e64 s[30:31], s[64:65], v[0:1]
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_add_u32_e32 v0, s74, v70
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_add_u32 s74, s16, 64
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cndmask_b32_e64 v186, v130, v186, s[28:29]
	v_cmp_gt_i64_e32 vcc, s[64:65], v[4:5]
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_cndmask_b32_e64 v4, v130, v172, s[28:29]
.Ltmp8:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e64 v2, v133, v193, s[26:27]
.Ltmp9:
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_addc_u32 s75, s17, 0
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_lshl_b32 s28, s92, 12
	v_cndmask_b32_e64 v187, v130, v187, s[30:31]
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_cndmask_b32_e64 v5, v130, v173, s[30:31]
.Ltmp10:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cmp_gt_f32_e64 s[26:27], s89, v2
.Ltmp11:
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_ashr_i32 s30, s28, 6
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add_u32_e32 v106, s90, v117
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[8:9], v[76:77], 0, s[16:17]
	v_lshl_add_u64 v[6:7], v[74:75], 0, s[16:17]
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_add_lshl_u32 v1, v0, s62, 1
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	v_add_lshl_u32 v0, v0, s78, 1
	.loc	1 187 39                        ; chunk_delta_h.py:187:39
	s_add_i32 s29, s16, 0x80
.Ltmp12:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e64 v3, 0, v134, s[26:27]
.Ltmp13:
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 s30, s30, s28
	.loc	1 141 35                        ; chunk_delta_h.py:141:35
	v_cvt_pk_bf16_f32 v31, v64, v65
	v_cvt_pk_bf16_f32 v29, v60, v61
	v_cvt_pk_bf16_f32 v27, v56, v57
	v_cvt_pk_bf16_f32 v24, v52, v53
	v_cvt_pk_bf16_f32 v137, v48, v49
	v_cvt_pk_bf16_f32 v28, v38, v39
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v163, s22, v108
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	v_add_u32_e32 v161, s21, v108
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add_u32_e32 v177, 32, v106
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_cmp_gt_i64_e64 s[20:21], s[64:65], v[8:9]
	v_cmp_gt_i64_e64 s[22:23], s[64:65], v[6:7]
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_and_b64 s[16:17], s[38:39], s[66:67]
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_cndmask_b32_e64 v6, v130, v1, s[18:19]
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	v_cndmask_b32_e64 v7, v130, v0, s[18:19]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_lshl_add_u64 v[0:1], s[74:75], 0, v[72:73]
	.loc	1 187 39                        ; chunk_delta_h.py:187:39
	s_min_i32 s29, s29, s64
.Ltmp14:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e64 v8, 0, v135, s[26:27]
	v_add_f32_e32 v2, v2, v3
.Ltmp15:
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_lshl1_add_u32 s27, s30, 0
	.loc	1 141 35                        ; chunk_delta_h.py:141:35
	v_cvt_pk_bf16_f32 v30, v44, v45
	v_cvt_pk_bf16_f32 v26, v36, v37
	.loc	1 141 27 is_stmt 0              ; chunk_delta_h.py:141:27
	v_perm_b32 v164, v27, v31, s86
	v_perm_b32 v165, v27, v31, s87
	v_perm_b32 v166, v28, v137, s86
	v_perm_b32 v169, v28, v137, s87
	v_perm_b32 v167, v24, v29, s86
	v_perm_b32 v168, v24, v29, s87
	.loc	1 185 26 is_stmt 1              ; chunk_delta_h.py:185:26
	v_cndmask_b32_e64 v172, v130, v106, s[16:17]
	v_cndmask_b32_e64 v173, v130, v177, s[16:17]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_cmp_gt_i64_e64 s[16:17], s[64:65], v[0:1]
	.loc	1 189 56                        ; chunk_delta_h.py:189:56
	s_lshl_b32 s26, s29, 5
.Ltmp16:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_exp_f32_e32 v9, v2
.Ltmp17:
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_waitcnt lgkmcnt(5)
	v_perm_b32 v3, v181, v180, s86
	s_waitcnt lgkmcnt(4)
	v_perm_b32 v2, v182, v179, s86
	s_waitcnt lgkmcnt(2)
	v_perm_b32 v1, v184, v183, s86
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v0, v192, v185, s86
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 s29, s27, s79
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	v_perm_b32 v170, v26, v30, s86
	v_perm_b32 v171, v26, v30, s87
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	buffer_store_dwordx4 v[0:3], v6, s[12:15], 0 offen
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b32 v139, v165, v169 offset1:32
	ds_write2_b32 v124, v164, v166 offset1:32
	ds_write2_b32 v125, v167, v170 offset1:32
	ds_write2_b32 v140, v168, v171 offset1:32
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v0, v128
	ds_read_u16 v1, v129
	ds_read_u16 v2, v129 offset:1024
	ds_read_u16 v6, v128 offset:1024
	ds_read_u16 v139, v127
	ds_read_u16 v140, v127 offset:1024
	ds_read_u16 v164, v126
	ds_read_u16 v165, v126 offset:1024
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	ds_read_b128 v[166:169], v163
	ds_read_b128 v[180:183], v163 offset:32
	ds_read_b128 v[192:195], v163 offset:64
	ds_read_b128 v[196:199], v163 offset:96
	s_add_i32 s30, s27, s82
	s_add_i32 m0, s29, 0x8780
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v16, s88, v112
	v_cvt_pk_bf16_f32 v141, v67, s0
	v_cvt_pk_bf16_f32 v142, v51, s0
	v_cvt_pk_bf16_f32 v143, v63, s0
	v_cvt_pk_bf16_f32 v144, v47, s0
	v_cvt_pk_bf16_f32 v145, v59, s0
	v_cvt_pk_bf16_f32 v146, v43, s0
	v_cvt_pk_bf16_f32 v147, v55, s0
	v_add_u32_e32 v20, s88, v92
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	buffer_load_dwordx4 v186, s[40:43], 0 offen lds
	s_add_i32 m0, s30, 0x9780
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	s_waitcnt lgkmcnt(9)
	v_perm_b32 v3, v2, v1, s86
	s_waitcnt lgkmcnt(8)
	v_perm_b32 v2, v6, v0, s86
	s_waitcnt lgkmcnt(6)
	v_perm_b32 v1, v140, v139, s86
	s_waitcnt lgkmcnt(4)
	v_perm_b32 v0, v165, v164, s86
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v17, s88, v111
	v_add_u32_e32 v18, s88, v110
	v_add_u32_e32 v19, s88, v109
	v_cvt_pk_bf16_f32 v148, v41, s0
	v_add_u32_e32 v21, s88, v93
	v_add_u32_e32 v136, s88, v94
	v_add_u32_e32 v138, s88, v95
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	buffer_load_dwordx4 v187, s[40:43], 0 offen lds
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 m0, s29, 0xc870
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	buffer_store_dwordx4 v[0:3], v7, s[12:15], 0 offen
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(1)
	ds_write_b16 v16, v14
	ds_write_b16 v16, v141 offset:128
	ds_write_b16 v16, v15 offset:2048
	ds_write_b16 v16, v142 offset:2176
	ds_write_b16 v17, v12
	ds_write_b16 v17, v143 offset:128
	ds_write_b16 v17, v13 offset:2048
	ds_write_b16 v17, v144 offset:2176
	ds_write_b16 v18, v11
	ds_write_b16 v18, v145 offset:128
	ds_write_b16 v18, v23 offset:2048
	ds_write_b16 v18, v146 offset:2176
	ds_write_b16 v19, v10
	ds_write_b16 v19, v147 offset:128
	ds_write_b16 v19, v22 offset:2048
	ds_write_b16 v19, v148 offset:2176
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[140:143], v20
	ds_read_b128 v[144:147], v21
	ds_read_b128 v[184:187], v136
	ds_read_b128 v[200:203], v138
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v4, s[40:43], 0 offen lds
	s_add_i32 m0, s30, 0xd870
.Ltmp18:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_ldexp_f32 v106, v9, v8
.Ltmp19:
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	buffer_load_dwordx4 v5, s[40:43], 0 offen lds
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[140:143], v[166:169], 0
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	v_cvt_pk_bf16_f32 v149, v65, s0
	v_cvt_pk_bf16_f32 v150, v49, s0
	v_cvt_pk_bf16_f32 v151, v61, s0
	v_cvt_pk_bf16_f32 v153, v45, s0
	v_cvt_pk_bf16_f32 v154, v57, s0
	v_cvt_pk_bf16_f32 v155, v39, s0
	v_cvt_pk_bf16_f32 v156, v53, s0
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[144:147], v[180:183], v[0:15]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	v_cvt_pk_bf16_f32 v157, v37, s0
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	ds_read_b128 v[204:207], v161
	ds_read_b128 v[208:211], v161 offset:32
	ds_read_b128 v[212:215], v161 offset:64
	ds_read_b128 v[216:219], v161 offset:96
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write_b16 v16, v31
	ds_write_b16 v16, v149 offset:128
	ds_write_b16 v16, v137 offset:2048
	ds_write_b16 v16, v150 offset:2176
	ds_write_b16 v17, v29
	ds_write_b16 v17, v151 offset:128
	ds_write_b16 v17, v30 offset:2048
	ds_write_b16 v17, v153 offset:2176
	ds_write_b16 v18, v27
	ds_write_b16 v18, v154 offset:128
	ds_write_b16 v18, v28 offset:2048
	ds_write_b16 v18, v155 offset:2176
	ds_write_b16 v19, v24
	ds_write_b16 v19, v156 offset:128
	ds_write_b16 v19, v26 offset:2048
	ds_write_b16 v19, v157 offset:2176
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	v_mfma_f32_32x32x16_bf16 v[0:15], v[184:187], v[192:195], v[0:15]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_read_b128 v[148:151], v20
	ds_read_b128 v[154:157], v21
	ds_read_b128 v[164:167], v136
	ds_read_b128 v[168:171], v138
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	v_add_u32_e32 v158, s90, v121
	.loc	1 189 60                        ; chunk_delta_h.py:189:60
	s_add_i32 s26, s81, s26
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_and_b64 s[16:17], s[68:69], s[16:17]
	v_cndmask_b32_e64 v158, v130, v158, s[16:17]
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	s_add_i32 s17, s27, 0x8780
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	v_mfma_f32_32x32x16_bf16 v[0:15], v[200:203], v[196:199], v[0:15]
	.loc	1 162 26                        ; chunk_delta_h.py:162:26
	s_add_i32 s16, s27, 0xc870
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_ashr_i32 s27, s26, 31
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	s_mov_b32 s6, s42
	s_mov_b32 s7, s43
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_lshl_b64 s[26:27], s[26:27], 2
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_mul_f32_e32 v189, 0x3fb8aa3b, v152
	.loc	1 179 22                        ; chunk_delta_h.py:179:22
	buffer_load_dwordx4 v[140:143], v158, s[4:7], 0 offen
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[148:151], v[204:207], v[0:15]
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v123, v[32:33], v[34:35] offset1:32
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read2st64_b64 v[26:29], v131 offset1:2
	ds_read2st64_b64 v[30:33], v132 offset1:2
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	v_mfma_f32_32x32x16_bf16 v[0:15], v[154:157], v[208:211], v[0:15]
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_add_u32 s6, s10, s26
	s_mov_b32 s91, s24
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v25, s25, v113
	v_add_u32_e32 v175, s25, v114
	v_add_u32_e32 v174, s25, v115
	v_add_u32_e32 v176, s25, v116
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_cmp_gt_f32_e64 s[24:25], s89, v189
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	v_mfma_f32_32x32x16_bf16 v[0:15], v[164:167], v[212:215], v[0:15]
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	s_addc_u32 s7, s11, s27
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_cndmask_b32_e64 v189, 0, v134, s[24:25]
	s_and_b64 s[24:25], s[24:25], exec
	s_cselect_b32 s24, 0xffffffc0, 0
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_ashr_i32 s25, s28, 4
	ds_read_b64_tr_b16 v[180:181], v25
	ds_read_b64_tr_b16 v[182:183], v25 offset:256
	ds_read_b64_tr_b16 v[184:185], v175 offset:2048
	ds_read_b64_tr_b16 v[186:187], v175 offset:2304
	ds_read_b64_tr_b16 v[192:193], v174 offset:4096
	ds_read_b64_tr_b16 v[194:195], v174 offset:4352
	ds_read_b64_tr_b16 v[174:175], v176 offset:6144
	ds_read_b64_tr_b16 v[176:177], v176 offset:6400
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	v_mfma_f32_32x32x16_bf16 v[0:15], v[168:171], v[216:219], v[0:15]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_add_i32 s25, s25, s28
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(9)
	v_and_b32_e32 v23, 0xffff0000, v26
	v_lshlrev_b32_e32 v22, 16, v26
	v_and_b32_e32 v25, 0xffff0000, v27
	v_lshlrev_b32_e32 v24, 16, v27
	v_and_b32_e32 v27, 0xffff0000, v28
	v_lshlrev_b32_e32 v26, 16, v28
	v_and_b32_e32 v35, 0xffff0000, v29
	v_lshlrev_b32_e32 v34, 16, v29
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v159, v90, v120
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(8)
	v_and_b32_e32 v29, 0xffff0000, v30
	v_lshlrev_b32_e32 v28, 16, v30
	v_and_b32_e32 v145, 0xffff0000, v31
	v_lshlrev_b32_e32 v144, 16, v31
	v_and_b32_e32 v31, 0xffff0000, v32
	v_lshlrev_b32_e32 v30, 16, v32
	v_and_b32_e32 v147, 0xffff0000, v33
	v_lshlrev_b32_e32 v146, 16, v33
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	s_lshl1_add_u32 s25, s25, 0
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_pk_add_f32 v[22:23], v[22:23], v[0:1] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[24:25], v[24:25], v[2:3] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[26:27], v[26:27], v[4:5] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[32:33], v[34:35], v[6:7] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v160, v90, v119
	v_add_u32_e32 v190, 0x40000, v159
	s_add_i32 s26, s25, s80
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_pk_add_f32 v[8:9], v[28:29], v[8:9] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[10:11], v[144:145], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[12:13], v[30:31], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[14:15], v[146:147], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_cvt_pk_bf16_f32 v0, v22, v23
	v_cvt_pk_bf16_f32 v1, v24, v25
	v_cvt_pk_bf16_f32 v2, v26, v27
	v_cvt_pk_bf16_f32 v3, v32, v33
	.loc	1 185 26 is_stmt 0              ; chunk_delta_h.py:185:26
	s_mov_b32 s54, s14
	s_mov_b32 s55, s15
	.loc	1 241 22 is_stmt 1              ; chunk_delta_h.py:241:22
	s_mov_b32 s46, s42
	s_mov_b32 s47, s43
	v_add_u32_e32 v191, 0xffffff80, v160
	v_cndmask_b32_e64 v188, v130, v190, s[20:21]
	s_add_i32 s27, s25, s83
	s_mov_b32 m0, s26
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_cvt_pk_bf16_f32 v4, v8, v9
	v_cvt_pk_bf16_f32 v5, v10, v11
	v_cvt_pk_bf16_f32 v6, v12, v13
	v_cvt_pk_bf16_f32 v7, v14, v15
	.loc	1 194 24                        ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[22:23], v[106:107], v[22:23] op_sel_hi:[0,1]
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_permlane32_swap_b32_e32 v0, v2
	v_permlane32_swap_b32_e32 v1, v3
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	s_mov_b32 s48, s10
	s_mov_b32 s50, s42
	s_mov_b32 s51, s43
	v_cndmask_b32_e32 v178, v130, v118, vcc
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_cndmask_b32_e64 v190, v130, v191, s[22:23]
	buffer_load_dwordx4 v188, s[44:47], 0 offen lds
	s_add_i32 m0, s27, 0x1000
	.loc	1 194 24                        ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[24:25], v[106:107], v[24:25] op_sel_hi:[0,1]
	v_pk_mul_f32 v[26:27], v[106:107], v[26:27] op_sel_hi:[0,1]
	v_pk_mul_f32 v[28:29], v[106:107], v[32:33] op_sel_hi:[0,1]
	v_pk_mul_f32 v[8:9], v[106:107], v[8:9] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[106:107], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[12:13], v[106:107], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[14:15], v[106:107], v[14:15] op_sel_hi:[0,1]
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_permlane32_swap_b32_e32 v4, v6
	v_permlane32_swap_b32_e32 v5, v7
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	v_cvt_pk_bf16_f32 v22, v22, s0
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	buffer_store_dwordx4 v[0:3], v172, s[52:55], 0 offen
	buffer_store_dwordx4 v[4:7], v173, s[52:55], 0 offen
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_add_u32_e32 v162, s91, v113
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	buffer_load_dwordx4 v190, s[44:47], 0 offen lds
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	v_cvt_pk_bf16_f32 v23, v23, s0
	v_cvt_pk_bf16_f32 v8, v8, s0
	v_cvt_pk_bf16_f32 v9, v9, s0
	v_cvt_pk_bf16_f32 v24, v24, s0
	v_cvt_pk_bf16_f32 v25, v25, s0
	v_cvt_pk_bf16_f32 v10, v10, s0
	v_cvt_pk_bf16_f32 v11, v11, s0
	v_cvt_pk_bf16_f32 v26, v26, s0
	v_cvt_pk_bf16_f32 v27, v27, s0
	v_cvt_pk_bf16_f32 v12, v12, s0
	v_cvt_pk_bf16_f32 v13, v13, s0
	v_cvt_pk_bf16_f32 v28, v28, s0
	v_cvt_pk_bf16_f32 v29, v29, s0
	v_cvt_pk_bf16_f32 v14, v14, s0
	v_cvt_pk_bf16_f32 v15, v15, s0
	.loc	1 189 31                        ; chunk_delta_h.py:189:31
	global_load_dword v106, v73, s[6:7]
	.loc	1 193 26                        ; chunk_delta_h.py:193:26
	buffer_load_dword v137, v178, s[48:51], 0 offen
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(2)
	ds_write_b16 v16, v22
	ds_write_b16 v16, v23 offset:128
	ds_write_b16 v16, v8 offset:2048
	ds_write_b16 v16, v9 offset:2176
	ds_write_b16 v17, v24
	ds_write_b16 v17, v25 offset:128
	ds_write_b16 v17, v10 offset:2048
	ds_write_b16 v17, v11 offset:2176
	ds_write_b16 v18, v26
	ds_write_b16 v18, v27 offset:128
	ds_write_b16 v18, v12 offset:2048
	ds_write_b16 v18, v13 offset:2176
	ds_write_b16 v19, v28
	ds_write_b16 v19, v29 offset:128
	ds_write_b16 v19, v14 offset:2048
	ds_write_b16 v19, v15 offset:2176
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[32:35], v20
	ds_read_b128 v[144:147], v21
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_add_u32_e32 v0, s91, v114
	ds_read_b64_tr_b16 v[148:149], v162
	ds_read_b64_tr_b16 v[150:151], v162 offset:256
	ds_read_b64_tr_b16 v[154:155], v0 offset:2048
	ds_read_b64_tr_b16 v[156:157], v0 offset:2304
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[32:35], v[180:183], 0
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	s_add_i32 m0, s26, 0x43c0
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_fmac_f32_e32 v189, 0x3fb8aa3b, v152
	s_and_b64 s[66:67], vcc, s[70:71]
	s_andn2_b64 s[6:7], s[72:73], exec
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_add_i32 s90, s90, 0x80000
	v_add_u32_e32 v119, 0x40000, v119
	v_add_u32_e32 v120, 0x40000, v120
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[32:35], v[148:151], 0
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_add_u32_e32 v32, 0x40080, v159
	v_cndmask_b32_e64 v32, v130, v32, s[20:21]
	v_cndmask_b32_e64 v33, v130, v160, s[22:23]
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	ds_read_b128 v[148:151], v136
	ds_read_b128 v[158:161], v138
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	buffer_load_dwordx4 v32, s[44:47], 0 offen lds
	s_add_i32 m0, s27, 0x53c0
	v_add_u32_e32 v32, s91, v115
	buffer_load_dwordx4 v33, s[44:47], 0 offen lds
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	v_mfma_f32_32x32x16_bf16 v[16:31], v[144:147], v[184:187], v[16:31]
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	v_add_u32_e32 v33, s91, v116
	s_and_b64 s[20:21], s[66:67], exec
	s_or_b64 s[72:73], s[6:7], s[20:21]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_add_u32_e32 v118, 0x2000, v118
	v_mov_b32_e32 v34, v142
	v_mov_b32_e32 v35, v143
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[144:147], v[154:157], v[0:15]
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	ds_read_b64_tr_b16 v[144:145], v32 offset:4096
	ds_read_b64_tr_b16 v[146:147], v32 offset:4352
	ds_read_b64_tr_b16 v[154:155], v33 offset:6144
	ds_read_b64_tr_b16 v[156:157], v33 offset:6400
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_exp_f32_e32 v32, v189
	v_mov_b32_e32 v33, v141
	v_ldexp_f32 v136, v32, s24
	.loc	1 247 26                        ; chunk_delta_h.py:247:26
	s_add_i32 s24, s25, 0x43c0
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[148:151], v[192:195], v[16:31]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cmp_lg_u32 s84, s74
	v_mov_b32_e32 v32, v140
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[148:151], v[144:147], v[0:15]
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	v_mfma_f32_32x32x16_bf16 v[16:31], v[158:161], v[174:177], v[16:31]
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[158:161], v[154:157], v[0:15]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	s_waitcnt vmcnt(2)
	s_nop 8
	v_fma_f32 v66, v66, v136, v16
	v_fma_f32 v67, v67, v136, v17
	v_fma_f32 v62, v62, v136, v18
	v_fma_f32 v63, v63, v136, v19
	v_pk_fma_f32 v[58:59], v[58:59], v[136:137], v[20:21] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[54:55], v[54:55], v[136:137], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[50:51], v[50:51], v[136:137], v[24:25] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[46:47], v[46:47], v[136:137], v[26:27] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[42:43], v[42:43], v[136:137], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[40:41], v[40:41], v[136:137], v[30:31] op_sel_hi:[1,0,1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[64:65], v[64:65], v[136:137], v[0:1] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[60:61], v[136:137], v[2:3] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[56:57], v[56:57], v[136:137], v[4:5] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[52:53], v[52:53], v[136:137], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[48:49], v[48:49], v[136:137], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[44:45], v[44:45], v[136:137], v[10:11] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[38:39], v[38:39], v[136:137], v[12:13] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[36:37], v[36:37], v[136:137], v[14:15] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v25, v137
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_cbranch_scc1 .LBB0_7
; %bb.8:                                ; %._crit_edge
	v_lshl_add_u64 v[0:1], v[72:73], 0, s[74:75]
	v_lshlrev_b64 v[24:25], 12, v[0:1]
	v_add_u32_e32 v16, 32, v108
	v_add_u32_e32 v17, 64, v108
	v_add_u32_e32 v20, 0x60, v108
	s_mov_b64 s[66:67], s[72:73]
	v_mov_b32_e32 v35, v143
	v_mov_b32_e32 v34, v142
	v_mov_b32_e32 v33, v141
	v_mov_b32_e32 v32, v140
	v_mov_b32_e32 v25, v137
	s_mov_b64 s[20:21], s[12:13]
	s_branch .LBB0_10
.LBB0_9:
	.loc	1 0 21 is_stmt 0                ; chunk_delta_h.py:0:21
	s_mov_b32 s25, 0
	s_add_i32 s17, 0, 0x8780
	s_add_i32 s16, 0, 0xc870
	s_add_i32 s24, 0, 0x43c0
.LBB0_10:
	.loc	1 136 23 is_stmt 1              ; chunk_delta_h.py:136:23
	v_or3_b32 v0, v98, v105, v103
	.loc	1 136 31 is_stmt 0              ; chunk_delta_h.py:136:31
	v_cvt_pk_bf16_f32 v4, v66, v67
	v_cvt_pk_bf16_f32 v6, v58, v59
	v_cvt_pk_bf16_f32 v8, v50, v51
	v_cvt_pk_bf16_f32 v10, v42, v43
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_or_b32_e32 v72, v0, v107
	s_add_i32 s7, 0, 0x10980
	s_mov_b32 s5, 0x5040100
	v_add_u32_e32 v12, s7, v72
	v_perm_b32 v1, v6, v4, s5
	s_mov_b32 s6, 0x7060302
	v_perm_b32 v3, v10, v8, s5
	s_movk_i32 s10, 0x108
	.loc	1 156 22 is_stmt 1              ; chunk_delta_h.py:156:22
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	.loc	1 136 31                        ; chunk_delta_h.py:136:31
	v_cvt_pk_bf16_f32 v5, v62, v63
	v_cvt_pk_bf16_f32 v7, v54, v55
	v_cvt_pk_bf16_f32 v9, v46, v47
	v_cvt_pk_bf16_f32 v11, v40, v41
	.loc	1 136 23 is_stmt 0              ; chunk_delta_h.py:136:23
	v_perm_b32 v2, v6, v4, s6
	ds_write2_b32 v12, v1, v3 offset1:32
	v_perm_b32 v1, v10, v8, s6
	v_add_u32_e32 v13, 0x800, v12
	v_bitop3_b32 v0, v0, s10, v107 bitop3:0x36
	ds_write2_b32 v13, v2, v1 offset1:32
	v_add_u32_e32 v14, s7, v0
	v_perm_b32 v0, v7, v5, s5
	v_perm_b32 v2, v11, v9, s5
	v_perm_b32 v1, v7, v5, s6
	ds_write2_b32 v14, v0, v2 offset1:32
	v_perm_b32 v0, v11, v9, s6
	v_add_u32_e32 v15, 0x800, v14
	ds_write2_b32 v15, v1, v0 offset1:32
	v_or_b32_e32 v0, v102, v90
	v_or3_b32 v0, v0, v100, v101
	v_mov_b32_e32 v1, s63
	s_movk_i32 s10, 0x240
	v_or_b32_e32 v73, s63, v0
	v_bitop3_b32 v75, v0, s10, v1 bitop3:0x36
	s_movk_i32 s10, 0x248
	.loc	1 132 21 is_stmt 1              ; chunk_delta_h.py:132:21
	s_max_i32 s4, s59, 0
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_add_u32_e32 v26, s7, v73
	v_bitop3_b32 v74, v0, 8, s63 bitop3:0x36
	v_bitop3_b32 v76, v0, s10, v1 bitop3:0x36
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v27, s7, v74
	v_add_u32_e32 v28, s7, v75
	v_add_u32_e32 v29, s7, v76
	ds_read_u16 v0, v26
	ds_read_u16 v18, v26 offset:1024
	ds_read_u16 v1, v27
	ds_read_u16 v19, v27 offset:1024
	ds_read_u16 v2, v28
	ds_read_u16 v21, v28 offset:1024
	ds_read_u16 v3, v29
	ds_read_u16 v22, v29 offset:1024
	.loc	1 134 16                        ; chunk_delta_h.py:134:16
	s_add_i32 s4, s4, s60
	s_lshl_b32 s4, s4, 19
	s_add_i32 s4, s4, s77
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	v_add_u32_e32 v77, s4, v70
	s_waitcnt lgkmcnt(6)
	v_perm_b32 v0, v18, v0, s5
	v_add_lshl_u32 v18, v77, s62, 1
	v_bfrev_b32_e32 v78, 1
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_and_b64 vcc, s[0:1], s[18:19]
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v3, v22, v3, s5
	v_perm_b32 v2, v21, v2, s5
	v_perm_b32 v1, v19, v1, s5
	v_cndmask_b32_e32 v18, v78, v18, vcc
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	.loc	1 141 35                        ; chunk_delta_h.py:141:35
	v_cvt_pk_bf16_f32 v31, v64, v65
	v_cvt_pk_bf16_f32 v21, v56, v57
	v_cvt_pk_bf16_f32 v70, v48, v49
	v_cvt_pk_bf16_f32 v22, v38, v39
	.loc	1 136 23                        ; chunk_delta_h.py:136:23
	buffer_store_dwordx4 v[0:3], v18, s[20:23], 0 offen
	.loc	1 141 35                        ; chunk_delta_h.py:141:35
	v_cvt_pk_bf16_f32 v23, v60, v61
	v_cvt_pk_bf16_f32 v18, v52, v53
	.loc	1 141 27 is_stmt 0              ; chunk_delta_h.py:141:27
	v_perm_b32 v0, v21, v31, s5
	v_perm_b32 v2, v22, v70, s5
	.loc	1 141 35                        ; chunk_delta_h.py:141:35
	v_cvt_pk_bf16_f32 v30, v44, v45
	v_cvt_pk_bf16_f32 v19, v36, v37
	.loc	1 141 27                        ; chunk_delta_h.py:141:27
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_perm_b32 v1, v21, v31, s6
	ds_write2_b32 v12, v0, v2 offset1:32
	v_perm_b32 v0, v22, v70, s6
	ds_write2_b32 v13, v1, v0 offset1:32
	v_perm_b32 v0, v18, v23, s5
	v_perm_b32 v2, v19, v30, s5
	v_perm_b32 v1, v18, v23, s6
	ds_write2_b32 v14, v0, v2 offset1:32
	v_perm_b32 v0, v19, v30, s6
	ds_write2_b32 v15, v1, v0 offset1:32
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v0, v27
	ds_read_u16 v1, v27 offset:1024
	ds_read_u16 v2, v28
	ds_read_u16 v3, v29
	ds_read_u16 v12, v29 offset:1024
	ds_read_u16 v13, v28 offset:1024
	ds_read_u16 v14, v26
	ds_read_u16 v15, v26 offset:1024
	s_waitcnt lgkmcnt(6)
	v_perm_b32 v1, v1, v0, s5
	s_waitcnt lgkmcnt(3)
	v_perm_b32 v3, v12, v3, s5
	v_add_lshl_u32 v12, v77, s78, 1
	s_waitcnt lgkmcnt(2)
	v_perm_b32 v2, v13, v2, s5
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v0, v15, v14, s5
	v_cndmask_b32_e32 v12, v78, v12, vcc
	buffer_store_dwordx4 v[0:3], v12, s[20:23], 0 offen
	.loc	1 157 44 is_stmt 1              ; chunk_delta_h.py:157:44
	s_add_i32 s6, 0, 0x10960
	v_add_u32_e32 v26, s6, v112
	.loc	1 156 22                        ; chunk_delta_h.py:156:22
	v_add_u32_e32 v0, s17, v108
	v_add_u32_e32 v1, s17, v16
	ds_read_b128 v[122:125], v0
	ds_read_b128 v[114:117], v1
	v_add_u32_e32 v0, s17, v17
	v_add_u32_e32 v1, s17, v20
	ds_read_b128 v[118:121], v0
	ds_read_b128 v[78:81], v1
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_cvt_pk_bf16_f32 v0, v67, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v26, v0 offset:128
	ds_write_b16 v26, v8 offset:2048
	v_cvt_pk_bf16_f32 v0, v51, s0
	ds_write_b16 v26, v0 offset:2176
	v_add_u32_e32 v27, s6, v111
	v_cvt_pk_bf16_f32 v0, v63, s0
	ds_write_b16 v26, v4
	ds_write_b16 v27, v0 offset:128
	ds_write_b16 v27, v9 offset:2048
	v_cvt_pk_bf16_f32 v0, v47, s0
	ds_write_b16 v27, v0 offset:2176
	v_add_u32_e32 v28, s6, v110
	v_cvt_pk_bf16_f32 v0, v59, s0
	ds_write_b16 v27, v5
	ds_write_b16 v28, v0 offset:128
	ds_write_b16 v28, v10 offset:2048
	v_cvt_pk_bf16_f32 v0, v43, s0
	ds_write_b16 v28, v0 offset:2176
	v_add_u32_e32 v29, s6, v109
	v_cvt_pk_bf16_f32 v0, v55, s0
	ds_write_b16 v28, v6
	ds_write_b16 v29, v0 offset:128
	ds_write_b16 v29, v11 offset:2048
	v_cvt_pk_bf16_f32 v0, v41, s0
	ds_write_b16 v29, v0 offset:2176
	.loc	1 157 26 is_stmt 0              ; chunk_delta_h.py:157:26
	v_cndmask_b32_e64 v0, 0, 1, s[0:1]
	v_cmp_ne_u32_e64 s[4:5], 1, v0
	s_andn2_b64 vcc, exec, s[0:1]
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_write_b16 v29, v7
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_cbranch_vccnz .LBB0_12
; %bb.11:
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	v_add_u32_e32 v0, s6, v92
	ds_read_b128 v[110:113], v0
	v_add_u32_e32 v77, s6, v93
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[110:113], v[122:125], 0
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_read_b128 v[110:113], v77
	v_add_u32_e32 v77, s6, v94
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[110:113], v[114:117], v[0:15]
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_read_b128 v[110:113], v77
	v_add_u32_e32 v77, s6, v95
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[110:113], v[118:121], v[0:15]
	.loc	1 157 44                        ; chunk_delta_h.py:157:44
	ds_read_b128 v[110:113], v77
	.loc	1 157 26                        ; chunk_delta_h.py:157:26
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[110:113], v[78:81], v[0:15]
	s_branch .LBB0_13
.LBB0_12:
	.loc	1 0 0                           ; chunk_delta_h.py:0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
.LBB0_13:
	.loc	1 162 26 is_stmt 1              ; chunk_delta_h.py:162:26
	v_add_u32_e32 v77, s16, v108
	v_add_u32_e32 v16, s16, v16
	ds_read_b128 v[116:119], v77
	ds_read_b128 v[108:111], v16
	v_add_u32_e32 v16, s16, v17
	v_add_u32_e32 v17, s16, v20
	ds_read_b128 v[112:115], v16
	ds_read_b128 v[78:81], v17
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	v_cvt_pk_bf16_f32 v16, v65, s0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v26, v16 offset:128
	ds_write_b16 v26, v70 offset:2048
	v_cvt_pk_bf16_f32 v16, v49, s0
	ds_write_b16 v26, v31
	ds_write_b16 v26, v16 offset:2176
	ds_write_b16 v27, v23
	v_cvt_pk_bf16_f32 v16, v61, s0
	ds_write_b16 v27, v16 offset:128
	ds_write_b16 v27, v30 offset:2048
	v_cvt_pk_bf16_f32 v16, v45, s0
	ds_write_b16 v27, v16 offset:2176
	ds_write_b16 v28, v21
	v_cvt_pk_bf16_f32 v16, v57, s0
	ds_write_b16 v28, v16 offset:128
	ds_write_b16 v28, v22 offset:2048
	v_cvt_pk_bf16_f32 v16, v39, s0
	ds_write_b16 v28, v16 offset:2176
	ds_write_b16 v29, v18
	v_cvt_pk_bf16_f32 v16, v53, s0
	ds_write_b16 v29, v16 offset:128
	ds_write_b16 v29, v19 offset:2048
	v_cvt_pk_bf16_f32 v16, v37, s0
	.loc	1 163 31 is_stmt 0              ; chunk_delta_h.py:163:31
	s_and_b64 vcc, exec, s[4:5]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_write_b16 v29, v16 offset:2176
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_cbranch_vccnz .LBB0_15
; %bb.14:
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	v_add_u32_e32 v16, s6, v92
	ds_read_b128 v[18:21], v16
	v_add_u32_e32 v16, s6, v93
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[18:21], v[116:119], v[0:15]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_read_b128 v[18:21], v16
	v_add_u32_e32 v16, s6, v94
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[18:21], v[108:111], v[0:15]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_read_b128 v[18:21], v16
	v_add_u32_e32 v16, s6, v95
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[18:21], v[112:115], v[0:15]
	.loc	1 163 49                        ; chunk_delta_h.py:163:49
	ds_read_b128 v[16:19], v16
	.loc	1 163 31                        ; chunk_delta_h.py:163:31
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[16:19], v[78:81], v[0:15]
.LBB0_15:
	.loc	1 179 52 is_stmt 1              ; chunk_delta_h.py:179:52
	s_and_b64 s[10:11], s[38:39], exec
	s_cselect_b32 s10, 0, 0x208
	v_mov_b32_e32 v17, 0x78
	v_lshlrev_b32_e32 v16, 6, v86
	v_bitop3_b32 v17, s10, v104, v17 bitop3:0x78
	v_add3_u32 v16, s7, v16, v17
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v31, 2, v68
	v_or_b32_e32 v70, 1, v68
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_add3_u32 v16, v16, v98, s63
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or3_b32 v77, v85, s58, 3
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v16, v[32:33], v[34:35] offset1:32
	v_mov_b32_e32 v16, 0x208
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add3_u32 v32, v31, v24, s33
	v_add3_u32 v31, v70, v24, s33
	v_mov_b32_e32 v70, 0x240
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_cndmask_b32_e64 v16, v16, 0, s[34:35]
	v_lshlrev_b32_e32 v17, 3, v86
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add3_u32 v33, v77, v24, s33
	v_lshlrev_b32_e32 v35, 5, v89
	v_cndmask_b32_e64 v77, v70, 0, s[2:3]
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_or3_b32 v16, v16, v17, s63
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_and_b32_e32 v34, 48, v104
	s_lshl_b32 s10, s76, 7
	v_xor_b32_e32 v35, v77, v35
	v_lshl_add_u32 v77, v69, 7, s7
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_or3_b32 v16, v16, v102, v90
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add3_u32 v34, v77, v34, s10
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_add_u32_e32 v17, s7, v16
	v_xad_u32 v16, v16, 8, s7
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add3_u32 v30, v24, v68, s33
	v_add3_u32 v77, v34, v35, v98
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read2st64_b64 v[20:23], v17 offset1:2
	ds_read2st64_b64 v[16:19], v16 offset1:2
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v77, v[30:33]
	v_lshlrev_b32_e32 v30, 9, v91
	.loc	1 114 16                        ; chunk_delta_h.py:114:16
	v_cmp_eq_u32_e32 vcc, 0, v87
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_lshlrev_b32_e32 v32, 3, v69
	s_and_b64 s[2:3], s[56:57], exec
	v_cndmask_b32_e64 v31, v70, 0, vcc
	v_lshl_or_b32 v30, v88, 4, v30
	v_lshlrev_b32_e32 v33, 5, v86
	s_cselect_b32 s2, 0, 0x100
	v_or3_b32 v30, v31, v32, v30
	v_or3_b32 v30, s2, v33, v30
	v_add_u32_e32 v31, s7, v30
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_xad_u32 v30, v30, 64, s7
	ds_read_b32 v31, v31
	ds_read_b32 v70, v30
	.loc	1 114 24                        ; chunk_delta_h.py:114:24
	v_or_b32_e32 v30, 5, v68
	v_or_b32_e32 v32, 4, v68
	v_or_b32_e32 v33, 7, v68
	v_or_b32_e32 v34, 6, v68
	.loc	1 194 44                        ; chunk_delta_h.py:194:44
	v_sub_f32_e32 v25, v106, v25
.Ltmp20:
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_delta_h.py:194:33 ]
	v_mov_b32_e32 v35, 0xff800000
.Ltmp21:
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_add3_u32 v79, v30, v24, s33
	v_add3_u32 v78, v32, v24, s33
	v_add3_u32 v81, v33, v24, s33
	v_add3_u32 v80, v34, v24, s33
.Ltmp22:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_mul_f32_e32 v24, 0x3fb8aa3b, v25
	.loc	3 27 29 is_stmt 0               ; op.py:27:29 @[ chunk_delta_h.py:194:33 ]
	v_cmp_ge_f32_e32 vcc, 0, v25
	s_mov_b32 s7, 0xc2fc0000
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_mov_b32_e32 v68, 0x42800000
	.loc	3 27 35                         ; op.py:27:35 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e32 v25, v35, v24, vcc
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cmp_gt_f32_e32 vcc, s7, v25
.Ltmp23:
	.loc	1 241 22 is_stmt 1              ; chunk_delta_h.py:241:22
	v_and_b32_e32 v82, 0x280, v99
	v_or3_b32 v30, v82, v97, v96
.Ltmp24:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e32 v35, 0, v68, vcc
	v_add_f32_e32 v25, v25, v35
	v_exp_f32_e32 v68, v25
.Ltmp25:
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_or3_b32 v32, v30, v85, s61
	v_or_b32_e32 v33, 0x800, v30
	v_or_b32_e32 v34, 0x1000, v30
	v_or_b32_e32 v30, 0x1800, v30
.Ltmp26:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_not_b32_e32 v69, 63
.Ltmp27:
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_lshrrev_b32_e32 v33, 4, v33
	v_lshrrev_b32_e32 v34, 4, v34
	v_lshrrev_b32_e32 v30, 4, v30
.Ltmp28:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_cndmask_b32_e32 v35, 0, v69, vcc
.Ltmp29:
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_and_b32_e32 v33, 0xc0, v33
	v_and_b32_e32 v34, 0x140, v34
	v_and_b32_e32 v30, 0x1c0, v30
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_and_b64 s[2:3], s[38:39], s[66:67]
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_lshl_add_u32 v24, v91, 4, v32
	v_add_u32_e32 v25, v33, v32
	v_add_u32_e32 v33, v34, v32
	v_add_u32_e32 v32, v30, v32
.Ltmp30:
	.loc	3 27 15                         ; op.py:27:15 @[ chunk_delta_h.py:194:33 ]
	v_ldexp_f32 v30, v68, v35
.Ltmp31:
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_and_b32_e32 v35, 0xffff0000, v20
	v_lshlrev_b32_e32 v34, 16, v20
	v_and_b32_e32 v69, 0xffff0000, v21
	v_lshlrev_b32_e32 v68, 16, v21
	v_and_b32_e32 v21, 0xffff0000, v22
	v_lshlrev_b32_e32 v20, 16, v22
	v_and_b32_e32 v83, 0xffff0000, v23
	v_lshlrev_b32_e32 v82, 16, v23
	v_and_b32_e32 v23, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v16
	v_and_b32_e32 v87, 0xffff0000, v17
	v_lshlrev_b32_e32 v86, 16, v17
	v_and_b32_e32 v17, 0xffff0000, v18
	v_lshlrev_b32_e32 v16, 16, v18
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	v_bfrev_b32_e32 v90, 1
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_pk_add_f32 v[12:13], v[16:17], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_waitcnt lgkmcnt(1)
	v_lshlrev_b32_e32 v16, 1, v31
	s_and_b64 vcc, s[0:1], s[2:3]
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_and_b32_e32 v89, 0xffff0000, v19
	v_lshlrev_b32_e32 v88, 16, v19
	v_pk_add_f32 v[18:19], v[34:35], v[0:1] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[34:35], v[68:69], v[2:3] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[20:21], v[20:21], v[4:5] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[68:69], v[82:83], v[6:7] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_waitcnt lgkmcnt(0)
	v_lshlrev_b32_e32 v17, 1, v70
	v_cndmask_b32_e32 v31, v90, v16, vcc
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v85, s25, v24
	.loc	1 179 52                        ; chunk_delta_h.py:179:52
	v_pk_add_f32 v[8:9], v[22:23], v[8:9] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[10:11], v[86:87], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[14:15], v[88:89], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_cvt_pk_bf16_f32 v0, v18, v19
	v_cvt_pk_bf16_f32 v2, v20, v21
	.loc	1 185 26 is_stmt 0              ; chunk_delta_h.py:185:26
	v_cndmask_b32_e32 v70, v90, v17, vcc
	.loc	1 194 24 is_stmt 1              ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[16:17], v[30:31], v[18:19] op_sel_hi:[0,1]
	v_pk_mul_f32 v[18:19], v[30:31], v[34:35] op_sel_hi:[0,1]
	v_pk_mul_f32 v[20:21], v[30:31], v[20:21] op_sel_hi:[0,1]
	v_pk_mul_f32 v[22:23], v[30:31], v[68:69] op_sel_hi:[0,1]
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	v_add_u32_e32 v107, s6, v94
	v_add_u32_e32 v108, s6, v95
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	v_add_u32_e32 v91, s25, v25
	v_add_u32_e32 v94, s25, v33
	v_add_u32_e32 v95, s25, v32
	.loc	1 185 33                        ; chunk_delta_h.py:185:33
	v_cvt_pk_bf16_f32 v1, v34, v35
	v_cvt_pk_bf16_f32 v3, v68, v69
	v_cvt_pk_bf16_f32 v4, v8, v9
	v_cvt_pk_bf16_f32 v5, v10, v11
	v_cvt_pk_bf16_f32 v6, v12, v13
	v_cvt_pk_bf16_f32 v7, v14, v15
	.loc	1 194 24                        ; chunk_delta_h.py:194:24
	v_pk_mul_f32 v[8:9], v[30:31], v[8:9] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[30:31], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[12:13], v[30:31], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[14:15], v[30:31], v[14:15] op_sel_hi:[0,1]
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	v_cvt_pk_bf16_f32 v30, v16, s0
	v_cvt_pk_bf16_f32 v34, v17, s0
	v_cvt_pk_bf16_f32 v35, v18, s0
	v_cvt_pk_bf16_f32 v68, v19, s0
	v_cvt_pk_bf16_f32 v69, v20, s0
	v_cvt_pk_bf16_f32 v82, v21, s0
	v_cvt_pk_bf16_f32 v83, v22, s0
	v_cvt_pk_bf16_f32 v86, v23, s0
	s_mov_b32 s11, 0x27000
	s_mov_b32 s10, 0x7ffffffe
	v_add_u32_e32 v92, s6, v92
	v_add_u32_e32 v93, s6, v93
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_and_b32 s9, s9, 0xffff
	.loc	1 185 33 is_stmt 0              ; chunk_delta_h.py:185:33
	v_permlane32_swap_b32_e32 v0, v2
	v_permlane32_swap_b32_e32 v1, v3
	v_permlane32_swap_b32_e32 v4, v6
	v_permlane32_swap_b32_e32 v5, v7
	.loc	1 236 21 is_stmt 1              ; chunk_delta_h.py:236:21
	v_cvt_pk_bf16_f32 v8, v8, s0
	v_cvt_pk_bf16_f32 v9, v9, s0
	v_cvt_pk_bf16_f32 v10, v10, s0
	v_cvt_pk_bf16_f32 v11, v11, s0
	v_cvt_pk_bf16_f32 v12, v12, s0
	v_cvt_pk_bf16_f32 v13, v13, s0
	v_cvt_pk_bf16_f32 v14, v14, s0
	v_cvt_pk_bf16_f32 v15, v15, s0
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	s_and_b64 vcc, exec, s[4:5]
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	s_barrier
	ds_write_b128 v77, v[78:81]
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 241 22                        ; chunk_delta_h.py:241:22
	ds_read_b64_tr_b16 v[16:17], v85
	ds_read_b64_tr_b16 v[18:19], v85 offset:256
	ds_read_b64_tr_b16 v[20:21], v91 offset:2048
	ds_read_b64_tr_b16 v[22:23], v91 offset:2304
	ds_read_b64_tr_b16 v[98:99], v94 offset:4096
	ds_read_b64_tr_b16 v[100:101], v94 offset:4352
	ds_read_b64_tr_b16 v[102:103], v95 offset:6144
	ds_read_b64_tr_b16 v[104:105], v95 offset:6400
	.loc	1 185 26                        ; chunk_delta_h.py:185:26
	buffer_store_dwordx4 v[0:3], v31, s[8:11], 0 offen
	buffer_store_dwordx4 v[4:7], v70, s[8:11], 0 offen
	.loc	1 236 21                        ; chunk_delta_h.py:236:21
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v26, v30
	ds_write_b16 v26, v34 offset:128
	ds_write_b16 v26, v8 offset:2048
	ds_write_b16 v26, v9 offset:2176
	ds_write_b16 v27, v35
	ds_write_b16 v27, v68 offset:128
	ds_write_b16 v27, v10 offset:2048
	ds_write_b16 v27, v11 offset:2176
	ds_write_b16 v28, v69
	ds_write_b16 v28, v82 offset:128
	ds_write_b16 v28, v12 offset:2048
	ds_write_b16 v28, v13 offset:2176
	ds_write_b16 v29, v83
	ds_write_b16 v29, v86 offset:128
	ds_write_b16 v29, v14 offset:2048
	ds_write_b16 v29, v15 offset:2176
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[94:97], v92
	ds_read_b128 v[90:93], v93
	ds_read_b128 v[86:89], v107
	ds_read_b128 v[78:81], v108
	.loc	1 242 37                        ; chunk_delta_h.py:242:37
	s_cbranch_vccnz .LBB0_18
; %bb.16:
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[94:97], v[16:19], 0
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[90:93], v[20:23], v[0:15]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[86:89], v[98:101], v[0:15]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[78:81], v[102:105], v[0:15]
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccz .LBB0_19
.LBB0_17:
	.loc	1 0 0 is_stmt 0                 ; chunk_delta_h.py:0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_branch .LBB0_20
.LBB0_18:
	.loc	1 0 0                           ; chunk_delta_h.py:0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	.loc	1 248 41 is_stmt 1              ; chunk_delta_h.py:248:41
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_17
.LBB0_19:
	.loc	1 0 0 is_stmt 0                 ; chunk_delta_h.py:0
	v_add_u32_e32 v16, s24, v24
	ds_read_b64_tr_b16 v[98:99], v16
	ds_read_b64_tr_b16 v[100:101], v16 offset:256
	v_add_u32_e32 v16, s24, v25
	ds_read_b64_tr_b16 v[102:103], v16 offset:2048
	ds_read_b64_tr_b16 v[104:105], v16 offset:2304
	v_add_u32_e32 v33, s24, v33
	v_add_u32_e32 v32, s24, v32
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[94:97], v[98:101], 0
	.loc	1 0 0                           ; chunk_delta_h.py:0
	ds_read_b64_tr_b16 v[94:95], v32 offset:6144
	ds_read_b64_tr_b16 v[96:97], v32 offset:6400
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[90:93], v[102:105], v[16:31]
	.loc	1 0 0                           ; chunk_delta_h.py:0
	ds_read_b64_tr_b16 v[90:91], v33 offset:4096
	ds_read_b64_tr_b16 v[92:93], v33 offset:4352
	.loc	1 248 41                        ; chunk_delta_h.py:248:41
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[86:89], v[90:93], v[16:31]
	v_mfma_f32_32x32x16_bf16 v[16:31], v[78:81], v[94:97], v[16:31]
.LBB0_20:
	.loc	1 195 27 is_stmt 1              ; chunk_delta_h.py:195:27
	v_mul_f32_e32 v32, 0x3fb8aa3b, v106
	s_mov_b32 s2, 0xc2fc0000
	v_mov_b32_e32 v33, 0x42800000
	v_cmp_gt_f32_e32 vcc, s2, v32
	s_and_b64 s[2:3], vcc, exec
	s_cselect_b32 s2, 0xffffffc0, 0
	v_cndmask_b32_e32 v32, 0, v33, vcc
	v_fmac_f32_e32 v32, 0x3fb8aa3b, v106
	v_exp_f32_e32 v32, v32
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	s_mov_b32 s3, 0x7060302
	s_mov_b32 s38, s42
	s_mov_b32 s39, s43
	.loc	1 195 27                        ; chunk_delta_h.py:195:27
	v_ldexp_f32 v32, v32, s2
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[66:67], v[32:33], v[0:1] op_sel_hi:[1,0,1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	s_mov_b32 s2, 0x5040100
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v33, v67, v1, s[0:1]
	v_cndmask_b32_e64 v34, v66, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[62:63], v[32:33], v[2:3] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v2, v63, v1, s[0:1]
	v_cndmask_b32_e64 v3, v62, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[58:59], v[32:33], v[4:5] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v2, v3, v2
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v4, v59, v1, s[0:1]
	v_cndmask_b32_e64 v5, v58, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[54:55], v[32:33], v[6:7] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v3, v5, v4
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v6, v55, v1, s[0:1]
	v_cndmask_b32_e64 v7, v54, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[50:51], v[32:33], v[8:9] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v4, v7, v6
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v8, v51, v1, s[0:1]
	v_cndmask_b32_e64 v9, v50, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[46:47], v[32:33], v[10:11] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v5, v9, v8
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v10, v47, v1, s[0:1]
	v_cndmask_b32_e64 v11, v46, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[42:43], v[32:33], v[12:13] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v6, v11, v10
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v12, v43, v1, s[0:1]
	v_cndmask_b32_e64 v13, v42, v0, s[0:1]
	.loc	1 242 16                        ; chunk_delta_h.py:242:16
	v_pk_fma_f32 v[0:1], v[40:41], v[32:33], v[14:15] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v7, v13, v12
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v14, v41, v1, s[0:1]
	v_cndmask_b32_e64 v15, v40, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[64:65], v[32:33], v[16:17] op_sel_hi:[1,0,1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	v_add_u32_e32 v10, 0, v72
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v16, v65, v1, s[0:1]
	v_cndmask_b32_e64 v17, v64, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[60:61], v[32:33], v[18:19] op_sel_hi:[1,0,1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v8, v15, v14
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v18, v61, v1, s[0:1]
	v_cndmask_b32_e64 v19, v60, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[56:57], v[32:33], v[20:21] op_sel_hi:[1,0,1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	v_add_u32_e32 v11, 0, v76
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v20, v57, v1, s[0:1]
	v_cndmask_b32_e64 v21, v56, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[52:53], v[32:33], v[22:23] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v22, v53, v1, s[0:1]
	v_cndmask_b32_e64 v23, v52, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[48:49], v[32:33], v[24:25] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v24, v49, v1, s[0:1]
	v_cndmask_b32_e64 v25, v48, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[44:45], v[32:33], v[26:27] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v26, v45, v1, s[0:1]
	v_cndmask_b32_e64 v27, v44, v0, s[0:1]
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	v_pk_fma_f32 v[0:1], v[38:39], v[32:33], v[28:29] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v28, v39, v1, s[0:1]
	.loc	1 265 31                        ; chunk_delta_h.py:265:31
	v_cvt_pk_bf16_f32 v1, v34, v33
	.loc	1 265 23 is_stmt 0              ; chunk_delta_h.py:265:23
	v_perm_b32 v9, v3, v1, s2
	v_perm_b32 v1, v3, v1, s3
	v_perm_b32 v3, v7, v5, s2
	ds_write2_b32 v10, v9, v3 offset1:32
	v_perm_b32 v3, v7, v5, s3
	v_add_u32_e32 v5, 0x800, v10
	ds_write2_b32 v5, v1, v3 offset1:32
	v_xad_u32 v7, v72, 8, 0
	v_perm_b32 v1, v4, v2, s2
	v_perm_b32 v3, v8, v6, s2
	v_perm_b32 v2, v4, v2, s3
	ds_write2_b32 v7, v1, v3 offset0:64 offset1:96
	v_perm_b32 v1, v8, v6, s3
	v_add_u32_e32 v4, 0x800, v7
	v_add_u32_e32 v6, 0, v73
	ds_write2_b32 v4, v2, v1 offset0:64 offset1:96
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v8, 0, v74
	v_add_u32_e32 v9, 0, v75
	ds_read_u16 v12, v6
	ds_read_u16 v13, v6 offset:1024
	ds_read_u16 v14, v8
	ds_read_u16 v15, v8 offset:1024
	ds_read_u16 v2, v9
	ds_read_u16 v29, v9 offset:1024
	ds_read_u16 v3, v11
	ds_read_u16 v33, v11 offset:1024
	.loc	1 132 21 is_stmt 1              ; chunk_delta_h.py:132:21
	v_cndmask_b32_e64 v34, v38, v0, s[0:1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	s_waitcnt lgkmcnt(2)
	v_perm_b32 v2, v29, v2, s2
	.loc	1 248 20                        ; chunk_delta_h.py:248:20
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[0:1], v[36:37], v[32:33], v[30:31] op_sel_hi:[1,0,1]
	.loc	1 132 21                        ; chunk_delta_h.py:132:21
	s_nop 0
	v_cndmask_b32_e64 v30, v37, v1, s[0:1]
	v_cndmask_b32_e64 v31, v36, v0, s[0:1]
	.loc	1 265 23                        ; chunk_delta_h.py:265:23
	v_perm_b32 v3, v33, v3, s2
	v_perm_b32 v1, v15, v14, s2
	v_perm_b32 v0, v13, v12, s2
	buffer_store_dwordx4 v[0:3], v71, s[36:39], 0 offen
	.loc	1 270 35                        ; chunk_delta_h.py:270:35
	v_cvt_pk_bf16_f32 v12, v25, v24
	v_cvt_pk_bf16_f32 v14, v34, v28
	v_cvt_pk_bf16_f32 v0, v17, v16
	v_cvt_pk_bf16_f32 v2, v21, v20
	.loc	1 270 27 is_stmt 0              ; chunk_delta_h.py:270:27
	v_perm_b32 v16, v2, v0, s2
	v_perm_b32 v0, v2, v0, s3
	v_perm_b32 v2, v14, v12, s2
	.loc	1 270 35                        ; chunk_delta_h.py:270:35
	v_cvt_pk_bf16_f32 v1, v19, v18
	v_cvt_pk_bf16_f32 v3, v23, v22
	v_cvt_pk_bf16_f32 v13, v27, v26
	v_cvt_pk_bf16_f32 v15, v31, v30
	.loc	1 270 27                        ; chunk_delta_h.py:270:27
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b32 v10, v16, v2 offset1:32
	v_perm_b32 v2, v14, v12, s3
	ds_write2_b32 v5, v0, v2 offset1:32
	v_perm_b32 v0, v3, v1, s2
	v_perm_b32 v2, v15, v13, s2
	v_perm_b32 v1, v3, v1, s3
	ds_write2_b32 v7, v0, v2 offset0:64 offset1:96
	v_perm_b32 v0, v15, v13, s3
	ds_write2_b32 v4, v1, v0 offset0:64 offset1:96
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_u16 v0, v8
	ds_read_u16 v1, v8 offset:1024
	ds_read_u16 v2, v9
	ds_read_u16 v3, v11
	ds_read_u16 v4, v11 offset:1024
	ds_read_u16 v5, v9 offset:1024
	ds_read_u16 v7, v6
	ds_read_u16 v6, v6 offset:1024
	s_waitcnt lgkmcnt(6)
	v_perm_b32 v1, v1, v0, s2
	s_waitcnt lgkmcnt(3)
	v_perm_b32 v3, v4, v3, s2
	s_waitcnt lgkmcnt(2)
	v_perm_b32 v2, v5, v2, s2
	s_waitcnt lgkmcnt(0)
	v_perm_b32 v0, v6, v7, s2
	buffer_store_dwordx4 v[0:3], v84, s[36:39], 0 offen
	.loc	1 263 4 is_stmt 1               ; chunk_delta_h.py:263:4
	s_endpgm
.Ltmp32:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950
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
		.amdhsa_next_free_vgpr 220
		.amdhsa_next_free_sgpr 93
		.amdhsa_accum_offset 220
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
	.size	qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950, .Lfunc_end0-qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.num_vgpr, 220
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.num_agpr, 0
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.numbered_sgpr, 93
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.num_named_barrier, 0
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.private_seg_size, 0
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.uses_vcc, 1
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.uses_flat_scratch, 0
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.has_dyn_sized_stack, 0
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.has_recursion, 0
	.set qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 11084
; TotalNumSgprs: 99
; NumVgprs: 220
; NumAgprs: 0
; TotalNumVgprs: 220
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 27
; NumSGPRsForWavesPerEU: 99
; NumVGPRsForWavesPerEU: 220
; AccumOffset: 220
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 54
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
	.quad	0
	.quad	0
.Ldebug_ranges1:
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
	.asciz	"qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950" ; string offset=77
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
    .name:           qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     99
    .sgpr_spill_count: 0
    .symbol:         qwen36_gdn_h_varlen_bv32_triton_oracle_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     220
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
