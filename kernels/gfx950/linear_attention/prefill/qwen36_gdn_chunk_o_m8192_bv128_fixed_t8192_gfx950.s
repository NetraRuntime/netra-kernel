// SPDX-License-Identifier: MIT
//
// Raw gfx950 Qwen3.6 GDN chunk-output kernel for the exact M8192 prefill.
// The CDNA4 wave64 schedule gives each four-wave workgroup the complete
// 128-element V dimension. This halves the workgroup count and the repeated
// Q/K traffic of the deployed BV64 schedule while retaining enough XCD-wide
// parallelism. Native 32x32x16 BF16 MFMA computes the QK and state products;
// the selected one-stage 32 KiB LDS layout is spill-free.
//
// Exact shape gate:
//   B=1, T=8192, H=32, Hg=16, K=V=128, BT=64, BK=128, BV=128
//   grid=(1,128,32), block=(256,1,1), dynamic LDS=32,768 bytes
//   fixed ABI: q,k,v,h,g,o,scale,T,global_scratch,profile_scratch
// Quarantined compiler-oracle source hash:
//   a85e6d4b65d15fe089d02d2422125a36b06d38cdbf71203bf5b251b9f23c24b0
//
	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950              ; -- Begin function qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950
	.p2align	8
	.type	qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950,@function
qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950:                     ; @qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950
.Lfunc_begin0:
; %bb.1:
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.p2align	8
; %bb.2:
.LBB0_0:
	s_ashr_i32 s1, s18, 31
	s_lshr_b32 s1, s1, 27
	s_mov_b64 s[24:25], s[2:3]
	s_add_i32 s1, s18, s1
	s_add_i32 s3, s15, 63
	s_mov_b64 s[28:29], s[6:7]
	s_ashr_i32 s2, s1, 5
	s_andn2_b32 s1, s1, 31
	s_ashr_i32 s6, s3, 31
	s_sub_i32 s1, s18, s1
	s_lshr_b32 s6, s6, 26
	s_add_i32 s3, s3, s6
	s_bfe_u32 s6, s1, 0x10007
	s_add_i32 s6, s1, s6
	s_lshr_b32 s3, s3, 6
	s_bfe_i32 s6, s6, 0x80000
	v_readfirstlane_b32 s0, v0
	s_mul_i32 s3, s3, s2
	s_mul_i32 s2, s15, s2
	s_sext_i32_i16 s6, s6
	s_and_b32 s39, s0, 0xc0
	s_lshl_b32 s6, s6, 6
	s_lshl_b32 s38, s2, 5
	v_and_b32_e32 v1, 63, v0
	s_add_i32 s3, s3, s17
	s_lshl_b32 s7, s2, 11
	s_and_b32 s6, s6, 0xffffff80
	s_add_i32 s38, s38, s1
	s_lshl_b32 s44, s16, 7
	v_or_b32_e32 v90, s39, v1
	s_and_b32 s42, s0, 0x80
	s_and_b32 s33, s0, 64
	s_lshl_b32 s0, s17, 18
	s_mov_b32 s22, s15
	s_add_i32 s7, s7, s6
	s_lshl_b32 s2, s38, 7
	s_lshl_b32 s3, s3, 19
	s_lshl_b32 s1, s1, 14
	s_lshl_b32 s43, s17, 6
	s_ashr_i32 s23, s15, 31
	v_lshrrev_b32_e32 v70, 4, v90
	s_add_i32 s15, s0, s44
	s_lshl_b32 s49, s17, 17
	s_add_i32 s30, s3, s1
	s_ashr_i32 s45, s43, 31
	s_ashr_i32 s46, s44, 31
	s_lshr_b32 s47, s42, 2
	v_or_b32_e32 v72, 32, v70
	s_lshr_b32 s48, s33, 1
	s_add_i32 s15, s15, s2
	s_add_i32 s49, s49, s7
	v_or_b32_e32 v71, 16, v70
	v_or_b32_e32 v73, 48, v70
	v_or_b32_e32 v6, s43, v72
	v_mov_b32_e32 v7, s45
	s_cmp_gt_i32 s43, -1
	v_or_b32_e32 v2, s43, v70
	v_mov_b32_e32 v3, s45
	v_or_b32_e32 v4, s43, v71
	v_mov_b32_e32 v5, s45
	v_or_b32_e32 v8, s43, v73
	v_mov_b32_e32 v9, s45
	s_cselect_b64 s[40:41], -1, 0
	v_cmp_gt_i64_e64 s[6:7], s[22:23], v[6:7]
	s_mov_b64 s[36:37], s[10:11]
	v_cmp_gt_i64_e32 vcc, s[22:23], v[2:3]
	v_cmp_gt_i64_e64 s[2:3], s[22:23], v[4:5]
	v_cmp_gt_i64_e64 s[10:11], s[22:23], v[8:9]
	s_and_b64 s[20:21], s[40:41], s[6:7]
	s_lshl_b32 s6, s16, 14
	v_and_b32_e32 v10, 15, v0
	s_and_b64 s[0:1], s[40:41], vcc
	s_and_b64 s[2:3], s[40:41], s[2:3]
	s_and_b64 s[18:19], s[40:41], s[10:11]
	s_and_b32 s25, s25, 0xffff
	s_and_b32 s5, s5, 0xffff
	s_add_i32 s30, s30, s6
	v_lshlrev_b32_e32 v74, 3, v10
	v_or_b32_e32 v2, s44, v70
	v_mov_b32_e32 v3, s46
	v_lshlrev_b32_e32 v4, 7, v71
	v_lshlrev_b32_e32 v5, 7, v72
	v_lshlrev_b32_e32 v6, 7, v73
	v_lshlrev_b32_e32 v7, 7, v70
	s_cmp_gt_i32 s44, -1
	s_mov_b64 s[34:35], 0x80
	v_or3_b32 v8, v7, v74, s30
	v_or3_b32 v7, s30, v7, v74
	v_or3_b32 v4, s30, v4, v74
	v_or3_b32 v5, s30, v5, v74
	v_or3_b32 v6, s30, v6, v74
	s_cselect_b64 s[30:31], -1, 0
	v_cmp_gt_i64_e32 vcc, s[34:35], v[2:3]
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_bfrev_b32_e32 v81, 1
	s_and_b64 vcc, s[30:31], vcc
	v_lshlrev_b32_e32 v2, 1, v7
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s26
	s_mov_b32 s11, s27
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[12:15], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v4
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[16:19], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v5
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[20:23], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 1, v6
	v_lshlrev_b32_e32 v8, 1, v8
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[24:27], v2, s[8:11], 0 offen
	v_or_b32_e32 v2, 0x4000, v8
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[28:31], v2, s[8:11], 0 offen
	v_or_b32_e32 v2, 0x5000, v8
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[32:35], v2, s[8:11], 0 offen
	v_or_b32_e32 v2, 0x6000, v8
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[36:39], v2, s[8:11], 0 offen
	v_or_b32_e32 v2, 0x7000, v8
	v_cndmask_b32_e32 v2, v81, v2, vcc
	buffer_load_dwordx4 v[40:43], v2, s[8:11], 0 offen
	v_lshlrev_b32_e32 v2, 11, v70
	v_lshlrev_b32_e32 v3, 11, v71
	v_lshlrev_b32_e32 v4, 11, v72
	v_lshlrev_b32_e32 v5, 11, v73
	v_or_b32_e32 v6, s49, v74
	v_add_lshl_u32 v2, v6, v2, 1
	v_add_lshl_u32 v3, v6, v3, 1
	v_add_lshl_u32 v4, v6, v4, 1
	v_add_lshl_u32 v5, v6, v5, 1
	v_cndmask_b32_e64 v2, v81, v2, s[0:1]
	v_cndmask_b32_e64 v3, v81, v3, s[2:3]
	v_cndmask_b32_e64 v4, v81, v4, s[20:21]
	v_cndmask_b32_e64 v5, v81, v5, s[18:19]
	s_mov_b32 s6, s26
	s_mov_b32 s7, s27
	buffer_load_dwordx4 v[44:47], v2, s[24:27], 0 offen
	buffer_load_dwordx4 v[48:51], v3, s[24:27], 0 offen
	buffer_load_dwordx4 v[52:55], v4, s[24:27], 0 offen
	buffer_load_dwordx4 v[56:59], v5, s[24:27], 0 offen
	buffer_load_dwordx4 v[60:63], v2, s[4:7], 0 offen
	buffer_load_dwordx4 v[64:67], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[94:97], v4, s[4:7], 0 offen
	buffer_load_dwordx4 v[98:101], v5, s[4:7], 0 offen
	v_mov_b32_e32 v6, 0xf0
	v_mov_b32_e32 v2, 0xe0
	v_bitop3_b32 v85, s39, v6, v1 bitop3:0xc8
	v_bitop3_b32 v1, s39, v2, v1 bitop3:0xc8
	v_and_b32_e32 v2, 14, v0
	v_lshlrev_b32_e32 v93, 5, v1
	v_lshlrev_b32_e32 v3, 3, v2
	v_lshrrev_b32_e32 v1, 1, v1
	v_and_b32_e32 v4, 1, v0
	v_and_b32_e32 v87, 16, v0
	v_lshlrev_b32_e32 v5, 10, v87
	v_bitop3_b32 v1, v93, v1, v3 bitop3:0x36
	v_lshl_add_u32 v3, v4, 13, 0
	v_and_b32_e32 v76, 32, v0
	v_add3_u32 v1, v3, v5, v1
	v_lshlrev_b32_e32 v88, 3, v0
	s_waitcnt vmcnt(15)
	ds_write_b128 v1, v[12:15]
	s_waitcnt vmcnt(14)
	ds_write_b128 v1, v[16:19] offset:128
	s_waitcnt vmcnt(13)
	ds_write_b128 v1, v[20:23] offset:256
	s_waitcnt vmcnt(12)
	ds_write_b128 v1, v[24:27] offset:384
	s_waitcnt vmcnt(11)
	ds_write_b128 v1, v[28:31] offset:512
	s_waitcnt vmcnt(10)
	ds_write_b128 v1, v[32:35] offset:640
	s_waitcnt vmcnt(9)
	ds_write_b128 v1, v[36:39] offset:768
	s_waitcnt vmcnt(8)
	ds_write_b128 v1, v[40:43] offset:896
	v_lshlrev_b32_e32 v1, 9, v2
	v_and_b32_e32 v2, 0xf0, v88
	v_lshlrev_b32_e32 v3, 14, v4
	v_lshlrev_b32_e32 v4, 8, v76
	v_or3_b32 v1, v1, v3, v4
	v_lshl_or_b32 v2, s39, 2, v2
	v_or_b32_e32 v3, v2, v1
	v_add_u32_e32 v4, 0, v3
	s_movk_i32 s4, 0x50
	v_and_b32_e32 v89, 31, v0
	s_movk_i32 s5, 0x70
	v_lshlrev_b32_e32 v34, 8, v89
	v_lshlrev_b32_e32 v35, 4, v10
	v_lshrrev_b32_e32 v36, 1, v76
	v_lshlrev_b32_e32 v86, 4, v90
	v_bitop3_b32 v18, v34, v36, v35 bitop3:0x36
	v_add_u32_e32 v37, 0, v18
	v_xad_u32 v38, v18, 32, 0
	v_xad_u32 v75, v18, 64, 0
	v_xor_b32_e32 v19, 0x60, v18
	v_add_u32_e32 v77, 0, v19
	v_xor_b32_e32 v19, 0x80, v18
	v_add_u32_e32 v78, 0, v19
	v_xor_b32_e32 v19, 0xa0, v18
	v_add_u32_e32 v79, 0, v19
	v_xor_b32_e32 v19, 0xc0, v18
	v_add_u32_e32 v80, 0, v19
	v_xor_b32_e32 v18, 0xe0, v18
	v_add_u32_e32 v82, 0, v18
	s_lshl_b32 s8, s33, 7
	v_bitop3_b32 v35, s8, v35, v36 bitop3:0xf6
	v_or_b32_e32 v36, v35, v34
	v_add_u32_e32 v39, 0, v36
	s_movk_i32 s16, 0x80
	s_movk_i32 s7, 0xa0
	s_movk_i32 s6, 0xe0
	v_or_b32_e32 v91, s48, v89
	v_lshrrev_b32_e32 v92, 3, v76
	v_or_b32_e32 v68, s43, v91
	v_mov_b32_e32 v69, s45
	s_and_b32 s37, s37, 0xffff
	s_mov_b32 s39, s27
	s_mov_b32 s25, 0xc2fc0000
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[40:43], v4
	v_xad_u32 v4, v3, 16, 0
	ds_read_b128 v[102:105], v4
	v_xad_u32 v4, v3, 32, 0
	ds_read_b128 v[106:109], v4
	v_xad_u32 v4, v3, 48, 0
	v_xad_u32 v3, v3, 64, 0
	ds_read_b128 v[110:113], v4
	ds_read_b128 v[114:117], v3
	v_bitop3_b32 v3, v2, s4, v1 bitop3:0x36
	v_add_u32_e32 v3, 0, v3
	s_movk_i32 s4, 0x60
	ds_read_b128 v[118:121], v3
	v_bitop3_b32 v3, v2, s4, v1 bitop3:0x36
	v_bitop3_b32 v1, v2, s5, v1 bitop3:0x36
	v_add_u32_e32 v3, 0, v3
	v_add_u32_e32 v1, 0, v1
	ds_read_b128 v[122:125], v3
	ds_read_b128 v[126:129], v1
	v_xad_u32 v1, v86, v85, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(7)
	ds_write_b128 v1, v[44:47]
	s_waitcnt vmcnt(6)
	ds_write_b128 v1, v[48:51] offset:4096
	s_waitcnt vmcnt(5)
	ds_write_b128 v1, v[52:55] offset:8192
	s_waitcnt vmcnt(4)
	ds_write_b128 v1, v[56:59] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[20:23], v37
	ds_read_b128 v[44:47], v37 offset:8192
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[40:43], v[20:23], 0
	ds_read_b128 v[20:23], v38
	s_movk_i32 s5, 0xc0
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[102:105], v[20:23], v[2:17]
	ds_read_b128 v[20:23], v75
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[106:109], v[20:23], v[2:17]
	ds_read_b128 v[20:23], v77
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[110:113], v[20:23], v[2:17]
	ds_read_b128 v[20:23], v78
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[114:117], v[20:23], v[2:17]
	ds_read_b128 v[20:23], v79
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[118:121], v[20:23], v[2:17]
	ds_read_b128 v[20:23], v80
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[122:125], v[20:23], v[2:17]
	ds_read_b128 v[18:21], v82
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[2:17], v[126:129], v[18:21], v[2:17]
	v_mfma_f32_32x32x16_bf16 v[18:33], v[40:43], v[44:47], 0
	ds_read_b128 v[40:43], v38 offset:8192
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[102:105], v[40:43], v[18:33]
	ds_read_b128 v[40:43], v75 offset:8192
	ds_read_b128 v[102:105], v39
	v_xad_u32 v39, v36, 32, 0
	v_xad_u32 v36, v36, 64, 0
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[106:109], v[40:43], v[18:33]
	ds_read_b128 v[40:43], v77 offset:8192
	ds_read_b128 v[106:109], v39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[110:113], v[40:43], v[18:33]
	ds_read_b128 v[40:43], v78 offset:8192
	ds_read_b128 v[110:113], v36
	v_bitop3_b32 v36, v35, s4, v34 bitop3:0x36
	v_add_u32_e32 v36, 0, v36
	s_lshl_b32 s4, s17, 11
	s_add_i32 s24, s38, s4
	s_mov_b32 s38, s26
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[114:117], v[40:43], v[18:33]
	ds_read_b128 v[40:43], v79 offset:8192
	ds_read_b128 v[114:117], v36
	v_bitop3_b32 v36, v35, s16, v34 bitop3:0x36
	v_add_u32_e32 v36, 0, v36
	s_lshl_b32 s17, s24, 2
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[118:121], v[40:43], v[18:33]
	ds_read_b128 v[40:43], v80 offset:8192
	ds_read_b128 v[118:121], v36
	v_bitop3_b32 v36, v35, s7, v34 bitop3:0x36
	v_add_u32_e32 v36, 0, v36
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[122:125], v[40:43], v[18:33]
	ds_read_b128 v[40:43], v82 offset:8192
	ds_read_b128 v[122:125], v36
	v_bitop3_b32 v36, v35, s5, v34 bitop3:0x36
	v_bitop3_b32 v34, v35, s6, v34 bitop3:0x36
	v_add_u32_e32 v36, 0, v36
	v_add_u32_e32 v34, 0, v34
	ds_read_b128 v[130:133], v34
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[18:33], v[126:129], v[40:43], v[18:33]
	ds_read_b128 v[126:129], v36
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(3)
	ds_write_b128 v1, v[60:63]
	s_waitcnt vmcnt(2)
	ds_write_b128 v1, v[64:67] offset:4096
	s_waitcnt vmcnt(1)
	ds_write_b128 v1, v[94:97] offset:8192
	s_waitcnt vmcnt(0)
	ds_write_b128 v1, v[98:101] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[40:43], v37
	ds_read_b128 v[96:99], v37 offset:8192
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[102:105], 0
	ds_read_b128 v[40:43], v38
	ds_read_b128 v[134:137], v38 offset:8192
	v_or_b32_e32 v34, s43, v89
	v_mov_b32_e32 v35, s45
	v_lshlrev_b32_e32 v1, 5, v89
	v_cmp_gt_i64_e32 vcc, s[22:23], v[34:35]
	v_or_b32_e32 v66, 32, v34
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[106:109], v[50:65]
	ds_read_b128 v[40:43], v75
	v_mov_b32_e32 v67, s45
	s_and_b64 vcc, s[40:41], vcc
	v_add_lshl_u32 v1, s24, v1, 2
	v_cndmask_b32_e32 v34, v81, v1, vcc
	v_cmp_gt_i64_e32 vcc, s[22:23], v[66:67]
	s_and_b64 vcc, s[40:41], vcc
	v_add_u32_e32 v1, 0x1000, v1
	v_or_b32_e32 v66, s43, v92
	v_cndmask_b32_e32 v1, v81, v1, vcc
	v_cmp_gt_i64_e32 vcc, s[22:23], v[68:69]
	v_cmp_gt_i64_e64 s[4:5], s[22:23], v[66:67]
	ds_read_b128 v[66:69], v77 offset:8192
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[110:113], v[50:65]
	ds_read_b128 v[40:43], v77
	buffer_load_dword v94, v34, s[36:39], 0 offen
	buffer_load_dword v95, v1, s[36:39], 0 offen
	v_lshlrev_b32_e32 v1, 5, v91
	s_and_b64 vcc, s[40:41], vcc
	v_add_lshl_u32 v1, s24, v1, 2
	v_cndmask_b32_e32 v1, v81, v1, vcc
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[114:117], v[50:65]
	ds_read_b128 v[40:43], v78
	s_and_b64 s[6:7], s[40:41], s[4:5]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[118:121], v[50:65]
	ds_read_b128 v[40:43], v79
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[122:125], v[50:65]
	ds_read_b128 v[40:43], v80
	ds_read_b128 v[44:47], v82
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[40:43], v[126:129], v[50:65]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[50:65], v[44:47], v[130:133], v[50:65]
	v_mfma_f32_32x32x16_bf16 v[34:49], v[96:99], v[102:105], 0
	ds_read_b128 v[98:101], v75 offset:8192
	v_mfma_f32_32x32x16_bf16 v[34:49], v[134:137], v[106:109], v[34:49]
	ds_read_b128 v[104:107], v82 offset:8192
	v_lshlrev_b32_e32 v75, 2, v76
	v_add_lshl_u32 v83, s24, v75, 2
	buffer_load_dword v75, v1, s[36:39], 0 offen
	v_or_b32_e32 v109, 16, v92
	v_or_b32_e32 v108, 17, v92
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v82, 0x3fb8aa3b, v95
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[98:101], v[110:113], v[34:49]
	v_cmp_gt_f32_e64 s[8:9], s25, v82
	v_mfma_f32_32x32x16_bf16 v[34:49], v[66:69], v[114:117], v[34:49]
	ds_read_b128 v[66:69], v78 offset:8192
	ds_read_b128 v[100:103], v79 offset:8192
	v_or_b32_e32 v79, 2, v92
	v_or_b32_e32 v78, 3, v92
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[66:69], v[118:121], v[34:49]
	v_lshrrev_b32_e32 v68, 2, v76
	v_mul_f32_e32 v76, 0x3fb8aa3b, v94
	v_cmp_gt_f32_e32 vcc, s25, v76
	v_mov_b32_e32 v76, 0x42800000
	v_cndmask_b32_e64 v82, 0, v76, s[8:9]
	v_cndmask_b32_e32 v77, 0, v76, vcc
	v_fmac_f32_e32 v77, 0x3fb8aa3b, v94
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[100:103], v[122:125], v[34:49]
	ds_read_b128 v[100:103], v80 offset:8192
	v_exp_f32_e32 v80, v77
	v_fmac_f32_e32 v82, 0x3fb8aa3b, v95
	v_not_b32_e32 v77, 63
	v_mov_b32_e32 v124, 0xff800000
	v_mov_b32_e32 v67, s45
	v_or_b32_e32 v84, s48, v68
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[34:49], v[100:103], v[126:129], v[34:49]
	v_or_b32_e32 v101, 8, v92
	v_lshl_add_u32 v94, v101, 7, s17
	v_cndmask_b32_e64 v94, v81, v94, s[6:7]
	buffer_load_dword v102, v94, s[36:39], 0 offen
	v_cndmask_b32_e64 v1, v81, v83, s[6:7]
	buffer_load_dword v96, v1, s[36:39], 0 offen
	v_or_b32_e32 v100, 9, v92
	v_lshl_add_u32 v94, v100, 7, s17
	v_cndmask_b32_e64 v94, v81, v94, s[6:7]
	buffer_load_dword v103, v94, s[36:39], 0 offen
	v_add_u32_e32 v1, 0x80, v83
	v_cndmask_b32_e64 v1, v81, v1, s[6:7]
	buffer_load_dword v97, v1, s[36:39], 0 offen
	v_exp_f32_e32 v94, v82
	v_cndmask_b32_e32 v82, 0, v77, vcc
	v_ldexp_f32 v82, v80, v82
	v_cndmask_b32_e64 v80, 0, v77, s[8:9]
	v_ldexp_f32 v80, v94, v80
	v_lshl_add_u32 v1, v79, 7, s17
	v_cndmask_b32_e64 v1, v81, v1, s[6:7]
	buffer_load_dword v98, v1, s[36:39], 0 offen
	v_mfma_f32_32x32x16_bf16 v[34:49], v[104:107], v[130:133], v[34:49]
	v_or_b32_e32 v106, 11, v92
	v_or_b32_e32 v104, 10, v92
	v_or_b32_e32 v83, s47, v89
	v_or_b32_e32 v66, s43, v83
	v_cmp_gt_i64_e64 s[4:5], s[22:23], v[66:67]
	v_or_b32_e32 v66, s44, v84
	v_mov_b32_e32 v67, s46
	v_or_b32_e32 v68, s44, v74
	v_mov_b32_e32 v69, s46
	v_pk_mul_f32 v[2:3], v[2:3], v[82:83] op_sel_hi:[1,0]
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v94, v75, v96
	v_cmp_ge_f32_e32 vcc, 0, v94
	v_mul_f32_e32 v94, 0x3fb8aa3b, v94
	s_nop 0
	v_cndmask_b32_e32 v94, v124, v94, vcc
	v_cmp_gt_f32_e32 vcc, s25, v94
	s_nop 1
	v_cndmask_b32_e32 v95, 0, v76, vcc
	v_add_f32_e32 v94, v94, v95
	v_exp_f32_e32 v94, v94
	s_waitcnt vmcnt(1)
	v_sub_f32_e32 v95, v75, v97
	v_cmp_ge_f32_e64 s[8:9], 0, v95
	v_mul_f32_e32 v95, 0x3fb8aa3b, v95
	v_cndmask_b32_e32 v96, 0, v77, vcc
	v_cndmask_b32_e64 v95, v124, v95, s[8:9]
	v_cmp_gt_f32_e32 vcc, s25, v95
	v_ldexp_f32 v94, v94, v96
	v_lshl_add_u32 v97, v104, 7, s17
	v_cndmask_b32_e32 v96, 0, v76, vcc
	v_add_f32_e32 v95, v95, v96
	v_exp_f32_e32 v95, v95
	v_cndmask_b32_e32 v96, 0, v77, vcc
	v_cndmask_b32_e64 v97, v81, v97, s[6:7]
	buffer_load_dword v105, v97, s[36:39], 0 offen
	v_ldexp_f32 v96, v95, v96
	v_mul_f32_e32 v95, v50, v94
	v_lshl_add_u32 v50, v106, 7, s17
	v_cndmask_b32_e64 v50, v81, v50, s[6:7]
	buffer_load_dword v107, v50, s[36:39], 0 offen
	v_lshl_add_u32 v1, v78, 7, s17
	v_cndmask_b32_e64 v1, v81, v1, s[6:7]
	buffer_load_dword v99, v1, s[36:39], 0 offen
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v50, v75, v98
	v_cmp_ge_f32_e64 s[6:7], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_mul_f32_e32 v94, v51, v96
	v_cndmask_b32_e64 v50, v124, v50, s[6:7]
	v_cmp_gt_f32_e64 s[10:11], s25, v50
	v_lshlrev_b32_e32 v98, 5, v109
	v_bfe_i32 v1, v0, 5, 1
	v_cndmask_b32_e64 v96, 0, v76, s[10:11]
	v_add_f32_e32 v50, v50, v96
	v_exp_f32_e32 v96, v50
	v_cmp_gt_u32_e32 vcc, v91, v92
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v51, v75, v99
	v_cmp_ge_f32_e64 s[8:9], 0, v51
	v_mul_f32_e32 v50, 0x3fb8aa3b, v51
	v_mov_b32_e32 v51, s45
	v_cndmask_b32_e64 v97, v124, v50, s[8:9]
	v_or_b32_e32 v50, s43, v109
	v_cmp_gt_i64_e64 s[6:7], s[22:23], v[50:51]
	s_and_b64 s[6:7], s[40:41], s[6:7]
	v_add_lshl_u32 v50, s24, v98, 2
	v_cndmask_b32_e64 v50, v81, v50, s[6:7]
	buffer_load_dword v110, v50, s[36:39], 0 offen
	v_lshl_add_u32 v50, v108, 7, s17
	v_cndmask_b32_e64 v50, v81, v50, s[6:7]
	buffer_load_dword v111, v50, s[36:39], 0 offen
	v_cmp_gt_f32_e64 s[8:9], s25, v97
	s_nop 1
	v_cndmask_b32_e64 v50, 0, v76, s[8:9]
	v_add_f32_e32 v50, v97, v50
	v_exp_f32_e32 v51, v50
	v_cndmask_b32_e64 v50, 0, v77, s[10:11]
	v_ldexp_f32 v50, v96, v50
	v_cndmask_b32_e64 v96, 0, v77, s[8:9]
	v_ldexp_f32 v51, v51, v96
	v_pk_mul_f32 v[50:51], v[52:53], v[50:51]
	v_cmp_ge_u32_e64 s[8:9], v91, v78
	v_or_b32_e32 v53, 18, v92
	v_lshl_add_u32 v78, v53, 7, s17
	v_cndmask_b32_e64 v96, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v79
	v_cndmask_b32_e64 v78, v81, v78, s[6:7]
	buffer_load_dword v78, v78, s[36:39], 0 offen
	v_cndmask_b32_e64 v97, 0, v50, s[8:9]
	v_sub_f32_e32 v50, v75, v102
	v_cmp_ge_f32_e64 s[8:9], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_sub_f32_e32 v51, v75, v103
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	v_cmp_ge_f32_e64 s[10:11], 0, v51
	v_mul_f32_e32 v51, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v52, 0, v76, s[8:9]
	v_add_f32_e32 v50, v50, v52
	v_or_b32_e32 v52, 19, v92
	v_lshl_add_u32 v79, v52, 7, s17
	v_cndmask_b32_e64 v79, v81, v79, s[6:7]
	buffer_load_dword v79, v79, s[36:39], 0 offen
	v_cndmask_b32_e64 v51, v124, v51, s[10:11]
	v_cmp_gt_f32_e64 s[10:11], s25, v51
	v_exp_f32_e32 v50, v50
	s_nop 0
	v_cndmask_b32_e64 v98, 0, v76, s[10:11]
	v_add_f32_e32 v51, v51, v98
	v_exp_f32_e32 v51, v51
	v_cndmask_b32_e64 v98, 0, v77, s[8:9]
	v_ldexp_f32 v50, v50, v98
	v_cndmask_b32_e64 v98, 0, v77, s[10:11]
	v_ldexp_f32 v51, v51, v98
	v_pk_mul_f32 v[50:51], v[54:55], v[50:51]
	v_cmp_ge_u32_e64 s[8:9], v91, v100
	v_or_b32_e32 v55, 24, v92
	v_lshl_add_u32 v100, v55, 7, s17
	v_cndmask_b32_e64 v98, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v101
	v_cndmask_b32_e64 v100, v81, v100, s[6:7]
	s_nop 0
	v_cndmask_b32_e64 v99, 0, v50, s[8:9]
	v_sub_f32_e32 v50, v75, v105
	v_cmp_ge_f32_e64 s[8:9], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	s_nop 0
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	s_nop 1
	v_cndmask_b32_e64 v51, 0, v76, s[8:9]
	v_add_f32_e32 v50, v50, v51
	v_exp_f32_e32 v50, v50
	v_sub_f32_e32 v51, v75, v107
	v_cmp_ge_f32_e64 s[10:11], 0, v51
	v_mul_f32_e32 v51, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v54, 0, v77, s[8:9]
	v_cndmask_b32_e64 v51, v124, v51, s[10:11]
	v_cmp_gt_f32_e64 s[8:9], s25, v51
	v_ldexp_f32 v50, v50, v54
	buffer_load_dword v107, v100, s[36:39], 0 offen
	v_cndmask_b32_e64 v54, 0, v76, s[8:9]
	v_add_f32_e32 v51, v51, v54
	v_exp_f32_e32 v51, v51
	v_or_b32_e32 v54, 25, v92
	v_lshl_add_u32 v100, v54, 7, s17
	v_cndmask_b32_e64 v100, v81, v100, s[6:7]
	buffer_load_dword v112, v100, s[36:39], 0 offen
	v_cndmask_b32_e64 v100, 0, v77, s[8:9]
	v_ldexp_f32 v51, v51, v100
	v_pk_mul_f32 v[50:51], v[56:57], v[50:51]
	v_cmp_ge_u32_e64 s[8:9], v91, v106
	s_nop 1
	v_cndmask_b32_e64 v100, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v104
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v51, v75, v111
	v_cmp_ge_f32_e64 s[10:11], 0, v51
	v_cndmask_b32_e64 v101, 0, v50, s[8:9]
	v_sub_f32_e32 v50, v75, v110
	v_cmp_ge_f32_e64 s[8:9], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_mul_f32_e32 v51, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	v_cndmask_b32_e64 v51, v124, v51, s[10:11]
	v_cmp_gt_f32_e64 s[10:11], s25, v51
	v_cndmask_b32_e64 v56, 0, v76, s[8:9]
	v_add_f32_e32 v50, v50, v56
	v_cndmask_b32_e64 v56, 0, v76, s[10:11]
	v_exp_f32_e32 v50, v50
	v_add_f32_e32 v51, v51, v56
	v_exp_f32_e32 v51, v51
	v_cndmask_b32_e64 v56, 0, v77, s[8:9]
	v_ldexp_f32 v50, v50, v56
	v_cndmask_b32_e64 v56, 0, v77, s[10:11]
	v_ldexp_f32 v51, v51, v56
	v_or_b32_e32 v56, 26, v92
	v_lshl_add_u32 v57, v56, 7, s17
	v_cndmask_b32_e64 v57, v81, v57, s[6:7]
	v_pk_mul_f32 v[50:51], v[58:59], v[50:51]
	buffer_load_dword v57, v57, s[36:39], 0 offen
	v_cmp_ge_u32_e64 s[8:9], v91, v108
	v_or_b32_e32 v58, 27, v92
	v_or_b32_e32 v111, 32, v92
	v_cndmask_b32_e64 v102, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v109
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v51, v75, v79
	v_lshlrev_b32_e32 v104, 5, v111
	v_cndmask_b32_e64 v103, 0, v50, s[8:9]
	v_lshl_add_u32 v50, v58, 7, s17
	v_cndmask_b32_e64 v50, v81, v50, s[6:7]
	buffer_load_dword v59, v50, s[36:39], 0 offen
	v_sub_f32_e32 v50, v75, v78
	v_cmp_ge_f32_e64 s[6:7], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_cmp_ge_f32_e64 s[8:9], 0, v51
	v_cndmask_b32_e64 v50, v124, v50, s[6:7]
	v_cmp_gt_f32_e64 s[10:11], s25, v50
	s_nop 1
	v_cndmask_b32_e64 v78, 0, v76, s[10:11]
	v_add_f32_e32 v50, v50, v78
	v_exp_f32_e32 v78, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	s_nop 1
	v_cndmask_b32_e64 v51, 0, v76, s[8:9]
	v_add_f32_e32 v50, v50, v51
	v_exp_f32_e32 v79, v50
	v_or_b32_e32 v50, s43, v111
	v_mov_b32_e32 v51, s45
	v_cmp_gt_i64_e64 s[6:7], s[22:23], v[50:51]
	s_and_b64 s[6:7], s[40:41], s[6:7]
	v_add_lshl_u32 v50, s24, v104, 2
	v_cndmask_b32_e64 v50, v81, v50, s[6:7]
	buffer_load_dword v110, v50, s[36:39], 0 offen
	v_cndmask_b32_e64 v50, 0, v77, s[10:11]
	v_ldexp_f32 v50, v78, v50
	v_cndmask_b32_e64 v51, 0, v77, s[8:9]
	v_or_b32_e32 v78, 33, v92
	v_ldexp_f32 v51, v79, v51
	v_lshl_add_u32 v79, v78, 7, s17
	v_cndmask_b32_e64 v79, v81, v79, s[6:7]
	buffer_load_dword v79, v79, s[36:39], 0 offen
	v_pk_mul_f32 v[50:51], v[60:61], v[50:51]
	v_cmp_ge_u32_e64 s[8:9], v91, v52
	s_nop 1
	v_cndmask_b32_e64 v104, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v53
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v51, v75, v112
	v_cmp_ge_f32_e64 s[10:11], 0, v51
	v_cndmask_b32_e64 v105, 0, v50, s[8:9]
	v_sub_f32_e32 v50, v75, v107
	v_cmp_ge_f32_e64 s[8:9], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_mul_f32_e32 v51, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	v_cndmask_b32_e64 v51, v124, v51, s[10:11]
	v_cmp_gt_f32_e64 s[10:11], s25, v51
	v_cndmask_b32_e64 v52, 0, v76, s[8:9]
	v_add_f32_e32 v50, v50, v52
	v_cndmask_b32_e64 v106, 0, v76, s[10:11]
	v_exp_f32_e32 v50, v50
	v_add_f32_e32 v51, v51, v106
	v_exp_f32_e32 v51, v51
	v_cndmask_b32_e64 v106, 0, v77, s[8:9]
	v_ldexp_f32 v50, v50, v106
	v_cndmask_b32_e64 v106, 0, v77, s[10:11]
	v_ldexp_f32 v51, v51, v106
	v_pk_mul_f32 v[50:51], v[62:63], v[50:51]
	v_cmp_ge_u32_e64 s[8:9], v91, v54
	v_or_b32_e32 v53, 34, v92
	v_or_b32_e32 v52, 35, v92
	v_cndmask_b32_e64 v106, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v55
	v_lshl_add_u32 v60, v53, 7, s17
	v_cndmask_b32_e64 v60, v81, v60, s[6:7]
	v_cndmask_b32_e64 v107, 0, v50, s[8:9]
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v50, v75, v57
	v_cmp_ge_f32_e64 s[8:9], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_lshl_add_u32 v61, v52, 7, s17
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	buffer_load_dword v60, v60, s[36:39], 0 offen
	v_cndmask_b32_e64 v61, v81, v61, s[6:7]
	v_cndmask_b32_e64 v51, 0, v76, s[8:9]
	buffer_load_dword v61, v61, s[36:39], 0 offen
	v_add_f32_e32 v50, v50, v51
	v_exp_f32_e32 v50, v50
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v51, v75, v59
	v_cmp_ge_f32_e64 s[10:11], 0, v51
	v_mul_f32_e32 v51, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v54, 0, v77, s[8:9]
	v_cndmask_b32_e64 v51, v124, v51, s[10:11]
	v_cmp_gt_f32_e64 s[8:9], s25, v51
	v_ldexp_f32 v50, v50, v54
	v_or_b32_e32 v55, 40, v92
	v_cndmask_b32_e64 v54, 0, v76, s[8:9]
	v_add_f32_e32 v51, v51, v54
	v_exp_f32_e32 v51, v51
	v_cndmask_b32_e64 v62, 0, v77, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v58
	v_lshl_add_u32 v57, v55, 7, s17
	v_ldexp_f32 v51, v51, v62
	v_pk_mul_f32 v[50:51], v[64:65], v[50:51]
	v_cndmask_b32_e64 v57, v81, v57, s[6:7]
	v_cndmask_b32_e64 v108, 0, v51, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v56
	buffer_load_dword v57, v57, s[36:39], 0 offen
	v_or_b32_e32 v54, 41, v92
	v_cndmask_b32_e64 v109, 0, v50, s[8:9]
	v_or_b32_e32 v58, 42, v92
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v50, v75, v110
	v_cmp_ge_f32_e64 s[8:9], 0, v50
	v_mul_f32_e32 v50, 0x3fb8aa3b, v50
	v_lshl_add_u32 v59, v54, 7, s17
	v_cndmask_b32_e64 v50, v124, v50, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v50
	v_lshl_add_u32 v62, v58, 7, s17
	v_cndmask_b32_e64 v59, v81, v59, s[6:7]
	v_cndmask_b32_e64 v51, 0, v76, s[8:9]
	v_add_f32_e32 v50, v50, v51
	v_exp_f32_e32 v50, v50
	s_waitcnt vmcnt(3)
	v_sub_f32_e32 v51, v75, v79
	v_cmp_ge_f32_e64 s[10:11], 0, v51
	v_mul_f32_e32 v51, 0x3fb8aa3b, v51
	v_cndmask_b32_e64 v56, 0, v77, s[8:9]
	v_cndmask_b32_e64 v51, v124, v51, s[10:11]
	v_cmp_gt_f32_e64 s[8:9], s25, v51
	v_ldexp_f32 v50, v50, v56
	v_cndmask_b32_e64 v62, v81, v62, s[6:7]
	v_cndmask_b32_e64 v56, 0, v76, s[8:9]
	v_add_f32_e32 v51, v51, v56
	v_or_b32_e32 v56, 43, v92
	v_lshl_add_u32 v63, v56, 7, s17
	v_cndmask_b32_e64 v63, v81, v63, s[6:7]
	buffer_load_dword v62, v62, s[36:39], 0 offen
	v_exp_f32_e32 v51, v51
	buffer_load_dword v63, v63, s[36:39], 0 offen
	v_cndmask_b32_e64 v64, 0, v77, s[8:9]
	buffer_load_dword v59, v59, s[36:39], 0 offen
	v_ldexp_f32 v51, v51, v64
	v_pk_mul_f32 v[34:35], v[34:35], v[50:51]
	v_cmp_ge_u32_e64 s[6:7], v91, v78
	v_or_b32_e32 v51, 48, v92
	s_nop 0
	v_cndmask_b32_e64 v110, 0, v35, s[6:7]
	v_cmp_ge_u32_e64 s[6:7], v91, v111
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v35, v75, v61
	v_cndmask_b32_e64 v111, 0, v34, s[6:7]
	v_sub_f32_e32 v34, v75, v60
	v_cmp_ge_f32_e64 s[6:7], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_cmp_ge_f32_e64 s[8:9], 0, v35
	v_cndmask_b32_e64 v34, v124, v34, s[6:7]
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e64 s[6:7], s25, v34
	v_cndmask_b32_e64 v35, v124, v35, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v35
	v_cndmask_b32_e64 v50, 0, v76, s[6:7]
	v_add_f32_e32 v34, v34, v50
	v_cndmask_b32_e64 v50, 0, v76, s[8:9]
	v_exp_f32_e32 v34, v34
	v_add_f32_e32 v35, v35, v50
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v50, 0, v77, s[6:7]
	v_ldexp_f32 v34, v34, v50
	v_cndmask_b32_e64 v50, 0, v77, s[8:9]
	v_ldexp_f32 v35, v35, v50
	v_pk_mul_f32 v[34:35], v[36:37], v[34:35]
	v_or_b32_e32 v36, s43, v51
	v_mov_b32_e32 v37, s45
	v_lshlrev_b32_e32 v60, 5, v51
	v_cmp_gt_i64_e64 s[6:7], s[22:23], v[36:37]
	v_or_b32_e32 v50, 49, v92
	s_and_b64 s[6:7], s[40:41], s[6:7]
	v_add_lshl_u32 v36, s24, v60, 2
	v_cndmask_b32_e64 v36, v81, v36, s[6:7]
	v_lshl_add_u32 v37, v50, 7, s17
	buffer_load_dword v36, v36, s[36:39], 0 offen
	v_cndmask_b32_e64 v37, v81, v37, s[6:7]
	buffer_load_dword v37, v37, s[36:39], 0 offen
	v_cmp_ge_u32_e64 s[8:9], v91, v52
	s_nop 1
	v_cndmask_b32_e64 v112, 0, v35, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v53
	v_or_b32_e32 v53, 50, v92
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v35, v75, v59
	v_cndmask_b32_e64 v113, 0, v34, s[8:9]
	v_sub_f32_e32 v34, v75, v57
	v_cmp_ge_f32_e64 s[8:9], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_lshl_add_u32 v57, v53, 7, s17
	v_cndmask_b32_e64 v34, v124, v34, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v34
	v_cndmask_b32_e64 v57, v81, v57, s[6:7]
	buffer_load_dword v57, v57, s[36:39], 0 offen
	v_cndmask_b32_e64 v52, 0, v76, s[8:9]
	v_add_f32_e32 v34, v34, v52
	v_or_b32_e32 v52, 51, v92
	v_lshl_add_u32 v59, v52, 7, s17
	v_cndmask_b32_e64 v59, v81, v59, s[6:7]
	v_cmp_ge_f32_e64 s[10:11], 0, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	buffer_load_dword v59, v59, s[36:39], 0 offen
	v_cndmask_b32_e64 v35, v124, v35, s[10:11]
	v_cmp_gt_f32_e64 s[10:11], s25, v35
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_cndmask_b32_e64 v60, 0, v76, s[10:11]
	v_add_f32_e32 v35, v35, v60
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v60, 0, v77, s[8:9]
	v_ldexp_f32 v34, v34, v60
	v_cndmask_b32_e64 v60, 0, v77, s[10:11]
	v_ldexp_f32 v35, v35, v60
	v_pk_mul_f32 v[34:35], v[38:39], v[34:35]
	v_cmp_ge_u32_e64 s[8:9], v91, v54
	v_or_b32_e32 v39, 56, v92
	v_or_b32_e32 v38, 57, v92
	v_cndmask_b32_e64 v114, 0, v35, s[8:9]
	v_cmp_ge_u32_e64 s[8:9], v91, v55
	v_lshl_add_u32 v54, v39, 7, s17
	v_cndmask_b32_e64 v54, v81, v54, s[6:7]
	v_cndmask_b32_e64 v115, 0, v34, s[8:9]
	v_sub_f32_e32 v34, v75, v62
	v_lshl_add_u32 v55, v38, 7, s17
	v_sub_f32_e32 v35, v75, v63
	v_cmp_ge_f32_e64 s[8:9], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	buffer_load_dword v54, v54, s[36:39], 0 offen
	v_cndmask_b32_e64 v55, v81, v55, s[6:7]
	v_cmp_ge_f32_e64 s[10:11], 0, v35
	buffer_load_dword v55, v55, s[36:39], 0 offen
	v_cndmask_b32_e64 v34, v124, v34, s[8:9]
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e64 s[8:9], s25, v34
	v_cndmask_b32_e64 v35, v124, v35, s[10:11]
	v_cmp_gt_f32_e64 s[10:11], s25, v35
	v_cndmask_b32_e64 v60, 0, v76, s[8:9]
	v_add_f32_e32 v34, v34, v60
	v_cndmask_b32_e64 v60, 0, v76, s[10:11]
	v_exp_f32_e32 v34, v34
	v_add_f32_e32 v35, v35, v60
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v60, 0, v77, s[8:9]
	v_ldexp_f32 v34, v34, v60
	v_cndmask_b32_e64 v60, 0, v77, s[10:11]
	v_ldexp_f32 v35, v35, v60
	v_pk_mul_f32 v[34:35], v[40:41], v[34:35]
	v_or_b32_e32 v40, 59, v92
	v_or_b32_e32 v41, 58, v92
	v_cmp_ge_u32_e64 s[8:9], v91, v56
	v_lshl_add_u32 v56, v41, 7, s17
	v_lshl_add_u32 v60, v40, 7, s17
	v_cndmask_b32_e64 v56, v81, v56, s[6:7]
	v_cndmask_b32_e64 v60, v81, v60, s[6:7]
	buffer_load_dword v60, v60, s[36:39], 0 offen
	v_cmp_ge_u32_e64 s[6:7], v91, v58
	buffer_load_dword v56, v56, s[36:39], 0 offen
	v_cndmask_b32_e64 v116, 0, v35, s[8:9]
	v_cndmask_b32_e64 v117, 0, v34, s[6:7]
	s_waitcnt vmcnt(7)
	v_sub_f32_e32 v34, v75, v36
	s_waitcnt vmcnt(6)
	v_sub_f32_e32 v35, v75, v37
	v_cmp_ge_f32_e64 s[6:7], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_cmp_ge_f32_e64 s[8:9], 0, v35
	v_cndmask_b32_e64 v34, v124, v34, s[6:7]
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e64 s[6:7], s25, v34
	v_cndmask_b32_e64 v35, v124, v35, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v35
	v_cndmask_b32_e64 v36, 0, v76, s[6:7]
	v_add_f32_e32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v76, s[8:9]
	v_exp_f32_e32 v34, v34
	v_add_f32_e32 v35, v35, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v77, s[6:7]
	v_ldexp_f32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v77, s[8:9]
	v_ldexp_f32 v35, v35, v36
	v_pk_mul_f32 v[34:35], v[42:43], v[34:35]
	v_cmp_ge_u32_e64 s[6:7], v91, v50
	v_lshlrev_b32_e32 v37, 12, v71
	s_nop 0
	v_cndmask_b32_e64 v118, 0, v35, s[6:7]
	v_cmp_ge_u32_e64 s[6:7], v91, v51
	s_waitcnt vmcnt(4)
	v_sub_f32_e32 v35, v75, v59
	v_cmp_ge_f32_e64 s[8:9], 0, v35
	v_cndmask_b32_e64 v119, 0, v34, s[6:7]
	v_sub_f32_e32 v34, v75, v57
	v_cmp_ge_f32_e64 s[6:7], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_cndmask_b32_e64 v34, v124, v34, s[6:7]
	v_cmp_gt_f32_e64 s[6:7], s25, v34
	v_cndmask_b32_e64 v35, v124, v35, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v35
	v_cndmask_b32_e64 v36, 0, v76, s[6:7]
	v_add_f32_e32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v76, s[8:9]
	v_exp_f32_e32 v34, v34
	v_add_f32_e32 v35, v35, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v77, s[6:7]
	v_ldexp_f32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v77, s[8:9]
	v_ldexp_f32 v35, v35, v36
	v_pk_mul_f32 v[34:35], v[44:45], v[34:35]
	v_cmp_ge_u32_e64 s[6:7], v91, v52
	s_nop 1
	v_cndmask_b32_e64 v120, 0, v35, s[6:7]
	v_cmp_ge_u32_e64 s[6:7], v91, v53
	s_waitcnt vmcnt(2)
	v_sub_f32_e32 v35, v75, v55
	v_cmp_ge_f32_e64 s[8:9], 0, v35
	v_cndmask_b32_e64 v121, 0, v34, s[6:7]
	v_sub_f32_e32 v34, v75, v54
	v_cmp_ge_f32_e64 s[6:7], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_cndmask_b32_e64 v34, v124, v34, s[6:7]
	v_cmp_gt_f32_e64 s[6:7], s25, v34
	v_cndmask_b32_e64 v35, v124, v35, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v35
	v_cndmask_b32_e64 v36, 0, v76, s[6:7]
	v_add_f32_e32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v76, s[8:9]
	v_exp_f32_e32 v34, v34
	v_add_f32_e32 v35, v35, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v77, s[6:7]
	v_ldexp_f32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v77, s[8:9]
	v_ldexp_f32 v35, v35, v36
	v_pk_mul_f32 v[34:35], v[46:47], v[34:35]
	v_cmp_ge_u32_e64 s[6:7], v91, v38
	v_lshlrev_b32_e32 v38, 12, v70
	s_nop 0
	v_cndmask_b32_e64 v122, 0, v35, s[6:7]
	v_cmp_ge_u32_e64 s[6:7], v91, v39
	s_waitcnt vmcnt(1)
	v_sub_f32_e32 v35, v75, v60
	v_cmp_ge_f32_e64 s[8:9], 0, v35
	v_cndmask_b32_e64 v123, 0, v34, s[6:7]
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v34, v75, v56
	v_cmp_ge_f32_e64 s[6:7], 0, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_cndmask_b32_e64 v34, v124, v34, s[6:7]
	v_cmp_gt_f32_e64 s[6:7], s25, v34
	v_cndmask_b32_e64 v35, v124, v35, s[8:9]
	v_cmp_gt_f32_e64 s[8:9], s25, v35
	v_cndmask_b32_e64 v36, 0, v76, s[6:7]
	v_add_f32_e32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v76, s[8:9]
	v_exp_f32_e32 v34, v34
	v_add_f32_e32 v35, v35, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v77, s[6:7]
	v_ldexp_f32 v34, v34, v36
	v_cndmask_b32_e64 v36, 0, v77, s[8:9]
	v_ldexp_f32 v35, v35, v36
	v_pk_mul_f32 v[34:35], v[48:49], v[34:35]
	v_cmp_ge_u32_e64 s[6:7], v91, v40
	v_cmp_gt_i64_e64 s[8:9], s[34:35], v[68:69]
	s_and_b64 s[22:23], s[30:31], s[8:9]
	v_cndmask_b32_e64 v124, 0, v35, s[6:7]
	v_cmp_ge_u32_e64 s[6:7], v91, v41
	v_lshlrev_b32_e32 v36, 12, v72
	v_or_b32_e32 v35, s15, v74
	v_cndmask_b32_e64 v125, 0, v34, s[6:7]
	v_cmp_gt_i64_e64 s[6:7], s[34:35], v[66:67]
	s_and_b64 s[8:9], s[6:7], s[4:5]
	s_or_b32 s4, s43, s44
	v_lshlrev_b32_e32 v34, 12, v73
	s_cmp_gt_i32 s4, -1
	s_cselect_b64 s[10:11], -1, 0
	s_and_b64 s[6:7], s[22:23], s[0:1]
	s_and_b64 s[4:5], s[22:23], s[2:3]
	s_and_b64 s[2:3], s[22:23], s[20:21]
	s_and_b64 s[0:1], s[22:23], s[18:19]
	v_add_lshl_u32 v36, v35, v36, 1
	v_add_lshl_u32 v34, v35, v34, 1
	s_and_b32 s29, s29, 0xffff
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	v_add_lshl_u32 v38, v35, v38, 1
	v_add_lshl_u32 v37, v35, v37, 1
	v_cndmask_b32_e64 v36, v81, v36, s[2:3]
	v_cndmask_b32_e64 v34, v81, v34, s[0:1]
	v_cndmask_b32_e64 v38, v81, v38, s[6:7]
	v_cndmask_b32_e64 v37, v81, v37, s[4:5]
	buffer_load_dwordx4 v[72:75], v36, s[28:31], 0 offen
	buffer_load_dwordx4 v[76:79], v34, s[28:31], 0 offen
	v_pk_mul_f32 v[34:35], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[4:5], v[82:83] op_sel_hi:[1,0]
	buffer_load_dwordx4 v[64:67], v38, s[28:31], 0 offen
	buffer_load_dwordx4 v[68:71], v37, s[28:31], 0 offen
	v_pk_mul_f32 v[36:37], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[6:7], v[82:83] op_sel_hi:[1,0]
	s_lshl2_add_u32 s0, s42, 0
	v_pk_mul_f32 v[40:41], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[8:9], v[82:83] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[42:43], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[10:11], v[82:83] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[18:19], v[80:81] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[44:45], s[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[20:21], v[80:81] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[12:13], v[82:83] op_sel_hi:[1,0]
	v_pk_mul_f32 v[46:47], s[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[22:23], v[80:81] op_sel_hi:[1,0]
	v_lshlrev_b32_e32 v22, 4, v89
	v_pk_mul_f32 v[18:19], s[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[24:25], v[80:81] op_sel_hi:[1,0]
	v_lshlrev_b32_e32 v24, 5, v90
	v_and_b32_e32 v24, 0xc00, v24
	v_add3_u32 v23, 0, v93, v22
	v_add3_u32 v22, s0, v24, v22
	v_pk_mul_f32 v[12:13], v[32:33], v[80:81] op_sel_hi:[1,0]
	s_barrier
	ds_write_b128 v23, v[34:37]
	ds_write_b128 v23, v[44:47] offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[36:39], v22
	ds_read_b128 v[32:35], v22 offset:4096
	v_pk_mul_f32 v[20:21], s[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[26:27], v[80:81] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[14:15], v[82:83] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], s[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[28:29], v[80:81] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[16:17], v[82:83] op_sel_hi:[1,0]
	v_pk_mul_f32 v[16:17], s[14:15], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], s[14:15], v[2:3] op_sel_hi:[0,1]
	v_pk_mul_f32 v[4:5], s[14:15], v[4:5] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[30:31], v[80:81] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], s[14:15], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], s[14:15], v[10:11] op_sel_hi:[0,1]
	s_movk_i32 s0, 0x210
	s_and_b32 s13, s13, 0xffff
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v23, v[40:43]
	ds_write_b128 v23, v[18:21] offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[44:47], v22
	ds_read_b128 v[40:43], v22 offset:4096
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v23, v[6:9]
	ds_write_b128 v23, v[14:17] offset:512
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[52:55], v22
	ds_read_b128 v[48:51], v22 offset:4096
	v_lshlrev_b32_e32 v6, 1, v87
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v23, v[2:5]
	ds_write_b128 v23, v[10:13] offset:512
	v_lshlrev_b32_e32 v2, 1, v89
	v_bitop3_b32 v2, v1, v2, s0 bitop3:0x6c
	v_or_b32_e32 v2, s33, v2
	v_cvt_pk_bf16_f32 v5, v95, s0
	v_cmp_ge_u32_e64 s[0:1], v91, v92
	v_add_u32_e32 v4, 0, v2
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e64 v5, 0, v5, s[0:1]
	s_barrier
	ds_read_b128 v[60:63], v22
	ds_read_b128 v[56:59], v22 offset:4096
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b16 v4, v5
	v_cvt_pk_bf16_f32 v5, v94, s0
	v_cndmask_b32_e32 v5, 0, v5, vcc
	ds_write_b16 v4, v5 offset:128
	v_cvt_pk_bf16_f32 v5, v103, s0
	ds_write_b16 v4, v5 offset:2048
	v_cvt_pk_bf16_f32 v5, v102, s0
	ds_write_b16 v4, v5 offset:2176
	v_cvt_pk_bf16_f32 v5, v111, s0
	ds_write_b16 v4, v5 offset:4096
	v_cvt_pk_bf16_f32 v5, v110, s0
	ds_write_b16 v4, v5 offset:4224
	v_cvt_pk_bf16_f32 v5, v119, s0
	ds_write_b16 v4, v5 offset:6144
	v_cvt_pk_bf16_f32 v5, v118, s0
	ds_write_b16 v4, v5 offset:6272
	v_xad_u32 v4, v2, 8, 0
	v_cvt_pk_bf16_f32 v5, v97, s0
	ds_write_b16 v4, v5 offset:256
	v_cvt_pk_bf16_f32 v5, v96, s0
	ds_write_b16 v4, v5 offset:384
	v_cvt_pk_bf16_f32 v5, v105, s0
	ds_write_b16 v4, v5 offset:2304
	v_cvt_pk_bf16_f32 v5, v104, s0
	ds_write_b16 v4, v5 offset:2432
	v_cvt_pk_bf16_f32 v5, v113, s0
	ds_write_b16 v4, v5 offset:4352
	v_cvt_pk_bf16_f32 v5, v112, s0
	ds_write_b16 v4, v5 offset:4480
	v_cvt_pk_bf16_f32 v5, v121, s0
	ds_write_b16 v4, v5 offset:6400
	v_cvt_pk_bf16_f32 v5, v120, s0
	ds_write_b16 v4, v5 offset:6528
	v_xad_u32 v4, v2, 32, 0
	v_cvt_pk_bf16_f32 v5, v99, s0
	ds_write_b16 v4, v5 offset:1024
	v_cvt_pk_bf16_f32 v5, v98, s0
	ds_write_b16 v4, v5 offset:1152
	v_cvt_pk_bf16_f32 v5, v107, s0
	ds_write_b16 v4, v5 offset:3072
	v_cvt_pk_bf16_f32 v5, v106, s0
	ds_write_b16 v4, v5 offset:3200
	v_cvt_pk_bf16_f32 v5, v115, s0
	ds_write_b16 v4, v5 offset:5120
	v_cvt_pk_bf16_f32 v5, v114, s0
	ds_write_b16 v4, v5 offset:5248
	v_cvt_pk_bf16_f32 v5, v123, s0
	ds_write_b16 v4, v5 offset:7168
	v_cvt_pk_bf16_f32 v5, v122, s0
	ds_write_b16 v4, v5 offset:7296
	v_xad_u32 v2, v2, 40, 0
	v_cvt_pk_bf16_f32 v4, v101, s0
	ds_write_b16 v2, v4 offset:1280
	v_cvt_pk_bf16_f32 v4, v100, s0
	ds_write_b16 v2, v4 offset:1408
	v_cvt_pk_bf16_f32 v4, v109, s0
	ds_write_b16 v2, v4 offset:3328
	v_cvt_pk_bf16_f32 v4, v108, s0
	ds_write_b16 v2, v4 offset:3456
	v_cvt_pk_bf16_f32 v4, v117, s0
	ds_write_b16 v2, v4 offset:5376
	v_cvt_pk_bf16_f32 v4, v116, s0
	ds_write_b16 v2, v4 offset:5504
	v_cvt_pk_bf16_f32 v4, v125, s0
	ds_write_b16 v2, v4 offset:7424
	v_cvt_pk_bf16_f32 v4, v124, s0
	ds_write_b16 v2, v4 offset:7552
	v_and_b32_e32 v4, 24, v88
	v_bfe_i32 v5, v0, 3, 1
	s_movk_i32 s1, 0x108
	v_and_b32_e32 v3, 0x210, v1
	v_lshlrev_b32_e32 v2, 5, v0
	v_bitop3_b32 v5, v5, v4, s1 bitop3:0x6c
	s_lshr_b32 s0, s42, 1
	v_and_or_b32 v2, v2, s16, v6
	v_xor_b32_e32 v3, v5, v3
	v_or3_b32 v2, s0, v2, v3
	v_add_u32_e32 v3, 0, v2
	v_xad_u32 v2, v2, 32, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[102:103], v2 offset:1024
	ds_read_b64_tr_b16 v[98:99], v2 offset:3072
	ds_read_b64_tr_b16 v[94:95], v2 offset:5120
	ds_read_b64_tr_b16 v[90:91], v2 offset:7168
	v_lshrrev_b32_e32 v2, 1, v85
	v_xor_b32_e32 v2, v2, v86
	ds_read_b64_tr_b16 v[100:101], v3
	ds_read_b64_tr_b16 v[96:97], v3 offset:2048
	ds_read_b64_tr_b16 v[92:93], v3 offset:4096
	ds_read_b64_tr_b16 v[88:89], v3 offset:6144
	v_add_u32_e32 v3, 0, v2
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v3, v[64:65], v[68:69] offset1:8
	ds_write2st64_b64 v3, v[72:73], v[76:77] offset0:16 offset1:24
	v_xad_u32 v2, v2, 8, 0
	v_lshlrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v0, 1, v0
	s_movk_i32 s0, 0x300
	ds_write2st64_b64 v2, v[66:67], v[70:71] offset1:8
	ds_write2st64_b64 v2, v[74:75], v[78:79] offset0:16 offset1:24
	v_and_b32_e32 v2, 56, v0
	v_and_or_b32 v0, v3, s0, v4
	s_movk_i32 s0, 0x420
	v_bitop3_b32 v1, v1, v2, s0 bitop3:0x6c
	v_xor_b32_e32 v0, v1, v0
	v_or_b32_e32 v0, s33, v0
	v_add_u32_e32 v64, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[16:17], v64
	v_xad_u32 v65, v0, 64, 0
	ds_read_b64_tr_b16 v[18:19], v65 offset:2048
	ds_read_b64_tr_b16 v[20:21], v64 offset:4096
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[16:19], v[100:103], 0
	ds_read_b64_tr_b16 v[22:23], v65 offset:6144
	ds_read_b64_tr_b16 v[16:17], v64 offset:8192
	ds_read_b64_tr_b16 v[68:69], v65 offset:2176
	ds_read_b64_tr_b16 v[70:71], v64 offset:4224
	s_and_b64 vcc, s[10:11], s[8:9]
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[20:23], v[96:99], v[0:15]
	ds_read_b64_tr_b16 v[18:19], v65 offset:10240
	ds_read_b64_tr_b16 v[20:21], v64 offset:12288
	ds_read_b64_tr_b16 v[22:23], v65 offset:14336
	ds_read_b64_tr_b16 v[66:67], v64 offset:128
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[16:19], v[92:95], v[0:15]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[0:15], v[20:23], v[88:91], v[0:15]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[66:69], v[100:103], 0
	ds_read_b64_tr_b16 v[72:73], v65 offset:6272
	ds_read_b64_tr_b16 v[66:67], v64 offset:8320
	s_nop 7
	v_fma_f32 v8, s14, v8, v52
	v_fma_f32 v9, s14, v9, v53
	v_fma_f32 v10, s14, v10, v54
	v_fma_f32 v11, s14, v11, v55
	v_pk_fma_f32 v[12:13], s[14:15], v[12:13], v[60:61] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[0:1], s[14:15], v[0:1], v[36:37] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[2:3], s[14:15], v[2:3], v[38:39] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[36:37], s[14:15], v[4:5], v[44:45] op_sel_hi:[0,1,1]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[70:73], v[96:99], v[16:31]
	ds_read_b64_tr_b16 v[68:69], v65 offset:10368
	ds_read_b64_tr_b16 v[70:71], v64 offset:12416
	ds_read_b64_tr_b16 v[72:73], v65 offset:14464
	v_or_b32_e32 v64, s15, v84
	v_fma_f32 v38, s14, v6, v46
	v_fma_f32 v39, s14, v7, v47
	v_cvt_pk_bf16_f32 v8, v8, v9
	v_cvt_pk_bf16_f32 v9, v10, v11
	v_cvt_pk_bf16_f32 v10, v12, v13
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[66:69], v[92:95], v[16:31]
	v_cvt_pk_bf16_f32 v4, v0, v1
	v_cvt_pk_bf16_f32 v5, v2, v3
	v_cvt_pk_bf16_f32 v6, v36, v37
	v_cvt_pk_bf16_f32 v7, v38, v39
	v_fma_f32 v14, s14, v14, v62
	v_fma_f32 v15, s14, v15, v63
	v_permlane32_swap_b32_e32 v4, v6
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_32x32x16_bf16 v[16:31], v[70:73], v[88:91], v[16:31]
	v_permlane32_swap_b32_e32 v5, v7
	v_cvt_pk_bf16_f32 v11, v14, v15
	v_permlane32_swap_b32_e32 v8, v10
	s_nop 0
	v_permlane32_swap_b32_e32 v9, v11
	s_nop 6
	v_pk_fma_f32 v[16:17], s[14:15], v[16:17], v[32:33] op_sel_hi:[0,1,1]
	v_cvt_pk_bf16_f32 v12, v16, v17
	v_lshlrev_b32_e32 v16, 12, v83
	v_add_lshl_u32 v16, v16, v64, 1
	v_pk_fma_f32 v[18:19], s[14:15], v[18:19], v[34:35] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[20:21], s[14:15], v[20:21], v[40:41] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[22:23], s[14:15], v[22:23], v[42:43] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[24:25], s[14:15], v[24:25], v[48:49] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[26:27], s[14:15], v[26:27], v[50:51] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[28:29], s[14:15], v[28:29], v[56:57] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[30:31], s[14:15], v[30:31], v[58:59] op_sel_hi:[0,1,1]
	s_mov_b32 s14, s26
	s_mov_b32 s15, s27
	v_cndmask_b32_e32 v17, v81, v16, vcc
	buffer_store_dwordx4 v[4:7], v17, s[12:15], 0 offen
	v_cvt_pk_bf16_f32 v13, v18, v19
	v_cvt_pk_bf16_f32 v14, v20, v21
	v_or_b32_e32 v4, 32, v16
	v_cndmask_b32_e32 v4, v81, v4, vcc
	v_cvt_pk_bf16_f32 v15, v22, v23
	buffer_store_dwordx4 v[8:11], v4, s[12:15], 0 offen
	v_or_b32_e32 v4, 0x80, v16
	v_permlane32_swap_b32_e32 v12, v14
	v_permlane32_swap_b32_e32 v13, v15
	v_cndmask_b32_e32 v4, v81, v4, vcc
	v_cvt_pk_bf16_f32 v0, v24, v25
	v_cvt_pk_bf16_f32 v1, v26, v27
	v_cvt_pk_bf16_f32 v2, v28, v29
	v_cvt_pk_bf16_f32 v3, v30, v31
	buffer_store_dwordx4 v[12:15], v4, s[12:15], 0 offen
	v_or_b32_e32 v4, 0xa0, v16
	v_permlane32_swap_b32_e32 v0, v2
	v_permlane32_swap_b32_e32 v1, v3
	v_cndmask_b32_e32 v4, v81, v4, vcc
	buffer_store_dwordx4 v[0:3], v4, s[12:15], 0 offen
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950
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
		.amdhsa_next_free_vgpr 138
		.amdhsa_next_free_sgpr 50
		.amdhsa_accum_offset 140
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
	.size	qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950, .Lfunc_end0-qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950
                                        ; -- End function
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.num_vgpr, 138
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.num_agpr, 0
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.numbered_sgpr, 50
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.num_named_barrier, 0
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.private_seg_size, 0
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.uses_vcc, 1
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.uses_flat_scratch, 0
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.has_dyn_sized_stack, 0
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.has_recursion, 0
	.set qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 8864
; TotalNumSgprs: 56
; NumVgprs: 138
; NumAgprs: 0
; TotalNumVgprs: 138
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 6
; VGPRBlocks: 17
; NumSGPRsForWavesPerEU: 56
; NumVGPRsForWavesPerEU: 138
; AccumOffset: 140
; Occupancy: 3
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 34
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
    .name:           qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     56
    .sgpr_spill_count: 0
    .symbol:         qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     138
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
