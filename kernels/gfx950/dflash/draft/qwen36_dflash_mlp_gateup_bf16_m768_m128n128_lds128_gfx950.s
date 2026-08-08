// SPDX-License-Identifier: MIT
//
// Qwen3.6 dFlash draft verification fused MLP gate/up projection:
//   BF16 input [768,2048] x concatenated BF16 weight^T [2048,12288]
//     -> BF16 gate/up output [768,12288].
//
// Four wave64s compute a 128x128 macro tile. Each wave owns one 64x64
// quadrant (sixteen native 16x16x32 BF16 MFMA chains). A and B are
// cooperatively staged in padded LDS K128 slabs; two operand register sets
// overlap LDS reads with independent MFMA issue.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.ifndef LDS_PITCH
	.set LDS_PITCH, 272
	.endif
	.set LDS_A_BYTES, LDS_PITCH * 128
	.set LDS_ROW16_BYTES, LDS_PITCH * 16
	.text
	.protected qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950
	.globl qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950
	.p2align 8
	.type qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950,@function
qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950:
	// Save workgroup IDs, then load output, input, and weight pointers.
	s_mov_b32 s12, s2
	s_mov_b32 s13, s3
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// Lane and 2x2 wave-quadrant decomposition.
	v_and_b32_e32 v1, 63, v0
	v_lshrrev_b32_e32 v2, 6, v0
	v_and_b32_e32 v3, 15, v1
	v_and_b32_e32 v4, 48, v1
	v_lshrrev_b32_e32 v5, 1, v2
	v_and_b32_e32 v6, 1, v2
	v_readfirstlane_b32 s14, v5
	v_readfirstlane_b32 s15, v6
	s_lshl_b32 s14, s14, 6
	s_lshl_b32 s15, s15, 6
	s_lshl_b32 s20, s13, 7
	s_lshl_b32 s21, s12, 7
	s_add_u32 s16, s20, s14
	s_add_u32 s17, s21, s15
	s_mov_b32 s22, LDS_PITCH
	s_mov_b32 s23, 6144

	// Two threads per staged row; each loads eight 16-byte vectors.
	v_lshrrev_b32_e32 v7, 1, v0
	v_and_b32_e32 v12, 1, v0
	v_lshlrev_b32_e32 v12, 4, v12
	v_add_u32_e32 v13, s20, v7
	v_lshlrev_b32_e32 v8, 12, v13
	v_add_u32_e32 v8, v8, v12
	v_add_u32_e32 v13, s21, v7
	v_lshlrev_b32_e32 v10, 12, v13
	v_add_u32_e32 v10, v10, v12
	v_mul_lo_u32 v48, v7, s22
	v_add_u32_e32 v48, v48, v12
	v_add_u32_e32 v49, LDS_A_BYTES, v48

	// Four A-row and four B-column panels per wave.
	v_add_u32_e32 v50, s14, v3
	v_mul_lo_u32 v50, v50, s22
	v_add_u32_e32 v50, v50, v4
	v_add_u32_e32 v51, LDS_ROW16_BYTES, v50
	v_add_u32_e32 v52, 2 * LDS_ROW16_BYTES, v50
	v_add_u32_e32 v53, 3 * LDS_ROW16_BYTES, v50
	v_add_u32_e32 v54, s15, v3
	v_mul_lo_u32 v54, v54, s22
	v_add_u32_e32 v54, v54, v4
	v_add_u32_e32 v54, LDS_A_BYTES, v54
	v_add_u32_e32 v55, LDS_ROW16_BYTES, v54
	v_add_u32_e32 v56, 2 * LDS_ROW16_BYTES, v54
	v_add_u32_e32 v57, 3 * LDS_ROW16_BYTES, v54

	// Sixteen 16x16 FP32 accumulator tiles per lane.
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v84, 0
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v88, 0
	v_mov_b32_e32 v89, 0
	v_mov_b32_e32 v90, 0
	v_mov_b32_e32 v91, 0
	v_mov_b32_e32 v92, 0
	v_mov_b32_e32 v93, 0
	v_mov_b32_e32 v94, 0
	v_mov_b32_e32 v95, 0
	v_mov_b32_e32 v96, 0
	v_mov_b32_e32 v97, 0
	v_mov_b32_e32 v98, 0
	v_mov_b32_e32 v99, 0
	v_mov_b32_e32 v100, 0
	v_mov_b32_e32 v101, 0
	v_mov_b32_e32 v102, 0
	v_mov_b32_e32 v103, 0
	v_mov_b32_e32 v104, 0
	v_mov_b32_e32 v105, 0
	v_mov_b32_e32 v106, 0
	v_mov_b32_e32 v107, 0
	v_mov_b32_e32 v108, 0
	v_mov_b32_e32 v109, 0
	v_mov_b32_e32 v110, 0
	v_mov_b32_e32 v111, 0
	v_mov_b32_e32 v112, 0
	v_mov_b32_e32 v113, 0
	v_mov_b32_e32 v114, 0
	v_mov_b32_e32 v115, 0
	v_mov_b32_e32 v116, 0
	v_mov_b32_e32 v117, 0
	v_mov_b32_e32 v118, 0
	v_mov_b32_e32 v119, 0
	v_mov_b32_e32 v120, 0
	v_mov_b32_e32 v121, 0
	v_mov_b32_e32 v122, 0
	v_mov_b32_e32 v123, 0
	v_mov_b32_e32 v124, 0
	v_mov_b32_e32 v125, 0
	v_mov_b32_e32 v126, 0
	v_mov_b32_e32 v127, 0
	s_mov_b32 s18, 0

.Lk128_stage_loop:
	// Stage A128xK128 using v128:v159.
	global_load_dwordx4 v[128:131], v8, s[4:5]
	global_load_dwordx4 v[132:135], v8, s[4:5] offset:32
	global_load_dwordx4 v[136:139], v8, s[4:5] offset:64
	global_load_dwordx4 v[140:143], v8, s[4:5] offset:96
	global_load_dwordx4 v[144:147], v8, s[4:5] offset:128
	global_load_dwordx4 v[148:151], v8, s[4:5] offset:160
	global_load_dwordx4 v[152:155], v8, s[4:5] offset:192
	global_load_dwordx4 v[156:159], v8, s[4:5] offset:224
	s_waitcnt vmcnt(0)
	ds_write_b128 v48, v[128:131]
	ds_write_b128 v48, v[132:135] offset:32
	ds_write_b128 v48, v[136:139] offset:64
	ds_write_b128 v48, v[140:143] offset:96
	ds_write_b128 v48, v[144:147] offset:128
	ds_write_b128 v48, v[148:151] offset:160
	ds_write_b128 v48, v[152:155] offset:192
	ds_write_b128 v48, v[156:159] offset:224
	// Reuse v128:v159 to stage B128xK128.
	global_load_dwordx4 v[128:131], v10, s[6:7]
	global_load_dwordx4 v[132:135], v10, s[6:7] offset:32
	global_load_dwordx4 v[136:139], v10, s[6:7] offset:64
	global_load_dwordx4 v[140:143], v10, s[6:7] offset:96
	global_load_dwordx4 v[144:147], v10, s[6:7] offset:128
	global_load_dwordx4 v[148:151], v10, s[6:7] offset:160
	global_load_dwordx4 v[152:155], v10, s[6:7] offset:192
	global_load_dwordx4 v[156:159], v10, s[6:7] offset:224
	s_waitcnt vmcnt(0)
	ds_write_b128 v49, v[128:131]
	ds_write_b128 v49, v[132:135] offset:32
	ds_write_b128 v49, v[136:139] offset:64
	ds_write_b128 v49, v[140:143] offset:96
	ds_write_b128 v49, v[144:147] offset:128
	ds_write_b128 v49, v[148:151] offset:160
	ds_write_b128 v49, v[152:155] offset:192
	ds_write_b128 v49, v[156:159] offset:224
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Prime K[0:32], then alternate operand sets.
	ds_read_b128 v[16:19], v50
	ds_read_b128 v[20:23], v51
	ds_read_b128 v[24:27], v52
	ds_read_b128 v[28:31], v53
	ds_read_b128 v[32:35], v54
	ds_read_b128 v[36:39], v55
	ds_read_b128 v[40:43], v56
	ds_read_b128 v[44:47], v57
	s_waitcnt lgkmcnt(0)
	ds_read_b128 v[128:131], v50 offset:64
	ds_read_b128 v[132:135], v51 offset:64
	ds_read_b128 v[136:139], v52 offset:64
	ds_read_b128 v[140:143], v53 offset:64
	ds_read_b128 v[144:147], v54 offset:64
	ds_read_b128 v[148:151], v55 offset:64
	ds_read_b128 v[152:155], v56 offset:64
	ds_read_b128 v[156:159], v57 offset:64
	v_mfma_f32_16x16x32_bf16 v[64:67], v[16:19], v[32:35], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[16:19], v[36:39], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[16:19], v[40:43], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[16:19], v[44:47], v[76:79]
	v_mfma_f32_16x16x32_bf16 v[80:83], v[20:23], v[32:35], v[80:83]
	v_mfma_f32_16x16x32_bf16 v[84:87], v[20:23], v[36:39], v[84:87]
	v_mfma_f32_16x16x32_bf16 v[88:91], v[20:23], v[40:43], v[88:91]
	v_mfma_f32_16x16x32_bf16 v[92:95], v[20:23], v[44:47], v[92:95]
	v_mfma_f32_16x16x32_bf16 v[96:99], v[24:27], v[32:35], v[96:99]
	v_mfma_f32_16x16x32_bf16 v[100:103], v[24:27], v[36:39], v[100:103]
	v_mfma_f32_16x16x32_bf16 v[104:107], v[24:27], v[40:43], v[104:107]
	v_mfma_f32_16x16x32_bf16 v[108:111], v[24:27], v[44:47], v[108:111]
	v_mfma_f32_16x16x32_bf16 v[112:115], v[28:31], v[32:35], v[112:115]
	v_mfma_f32_16x16x32_bf16 v[116:119], v[28:31], v[36:39], v[116:119]
	v_mfma_f32_16x16x32_bf16 v[120:123], v[28:31], v[40:43], v[120:123]
	v_mfma_f32_16x16x32_bf16 v[124:127], v[28:31], v[44:47], v[124:127]
	s_waitcnt lgkmcnt(0)
	ds_read_b128 v[16:19], v50 offset:128
	ds_read_b128 v[20:23], v51 offset:128
	ds_read_b128 v[24:27], v52 offset:128
	ds_read_b128 v[28:31], v53 offset:128
	ds_read_b128 v[32:35], v54 offset:128
	ds_read_b128 v[36:39], v55 offset:128
	ds_read_b128 v[40:43], v56 offset:128
	ds_read_b128 v[44:47], v57 offset:128
	v_mfma_f32_16x16x32_bf16 v[64:67], v[128:131], v[144:147], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[128:131], v[148:151], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[128:131], v[152:155], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[128:131], v[156:159], v[76:79]
	v_mfma_f32_16x16x32_bf16 v[80:83], v[132:135], v[144:147], v[80:83]
	v_mfma_f32_16x16x32_bf16 v[84:87], v[132:135], v[148:151], v[84:87]
	v_mfma_f32_16x16x32_bf16 v[88:91], v[132:135], v[152:155], v[88:91]
	v_mfma_f32_16x16x32_bf16 v[92:95], v[132:135], v[156:159], v[92:95]
	v_mfma_f32_16x16x32_bf16 v[96:99], v[136:139], v[144:147], v[96:99]
	v_mfma_f32_16x16x32_bf16 v[100:103], v[136:139], v[148:151], v[100:103]
	v_mfma_f32_16x16x32_bf16 v[104:107], v[136:139], v[152:155], v[104:107]
	v_mfma_f32_16x16x32_bf16 v[108:111], v[136:139], v[156:159], v[108:111]
	v_mfma_f32_16x16x32_bf16 v[112:115], v[140:143], v[144:147], v[112:115]
	v_mfma_f32_16x16x32_bf16 v[116:119], v[140:143], v[148:151], v[116:119]
	v_mfma_f32_16x16x32_bf16 v[120:123], v[140:143], v[152:155], v[120:123]
	v_mfma_f32_16x16x32_bf16 v[124:127], v[140:143], v[156:159], v[124:127]
	s_waitcnt lgkmcnt(0)
	ds_read_b128 v[128:131], v50 offset:192
	ds_read_b128 v[132:135], v51 offset:192
	ds_read_b128 v[136:139], v52 offset:192
	ds_read_b128 v[140:143], v53 offset:192
	ds_read_b128 v[144:147], v54 offset:192
	ds_read_b128 v[148:151], v55 offset:192
	ds_read_b128 v[152:155], v56 offset:192
	ds_read_b128 v[156:159], v57 offset:192
	v_mfma_f32_16x16x32_bf16 v[64:67], v[16:19], v[32:35], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[16:19], v[36:39], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[16:19], v[40:43], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[16:19], v[44:47], v[76:79]
	v_mfma_f32_16x16x32_bf16 v[80:83], v[20:23], v[32:35], v[80:83]
	v_mfma_f32_16x16x32_bf16 v[84:87], v[20:23], v[36:39], v[84:87]
	v_mfma_f32_16x16x32_bf16 v[88:91], v[20:23], v[40:43], v[88:91]
	v_mfma_f32_16x16x32_bf16 v[92:95], v[20:23], v[44:47], v[92:95]
	v_mfma_f32_16x16x32_bf16 v[96:99], v[24:27], v[32:35], v[96:99]
	v_mfma_f32_16x16x32_bf16 v[100:103], v[24:27], v[36:39], v[100:103]
	v_mfma_f32_16x16x32_bf16 v[104:107], v[24:27], v[40:43], v[104:107]
	v_mfma_f32_16x16x32_bf16 v[108:111], v[24:27], v[44:47], v[108:111]
	v_mfma_f32_16x16x32_bf16 v[112:115], v[28:31], v[32:35], v[112:115]
	v_mfma_f32_16x16x32_bf16 v[116:119], v[28:31], v[36:39], v[116:119]
	v_mfma_f32_16x16x32_bf16 v[120:123], v[28:31], v[40:43], v[120:123]
	v_mfma_f32_16x16x32_bf16 v[124:127], v[28:31], v[44:47], v[124:127]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[64:67], v[128:131], v[144:147], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[128:131], v[148:151], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[128:131], v[152:155], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[128:131], v[156:159], v[76:79]
	v_mfma_f32_16x16x32_bf16 v[80:83], v[132:135], v[144:147], v[80:83]
	v_mfma_f32_16x16x32_bf16 v[84:87], v[132:135], v[148:151], v[84:87]
	v_mfma_f32_16x16x32_bf16 v[88:91], v[132:135], v[152:155], v[88:91]
	v_mfma_f32_16x16x32_bf16 v[92:95], v[132:135], v[156:159], v[92:95]
	v_mfma_f32_16x16x32_bf16 v[96:99], v[136:139], v[144:147], v[96:99]
	v_mfma_f32_16x16x32_bf16 v[100:103], v[136:139], v[148:151], v[100:103]
	v_mfma_f32_16x16x32_bf16 v[104:107], v[136:139], v[152:155], v[104:107]
	v_mfma_f32_16x16x32_bf16 v[108:111], v[136:139], v[156:159], v[108:111]
	v_mfma_f32_16x16x32_bf16 v[112:115], v[140:143], v[144:147], v[112:115]
	v_mfma_f32_16x16x32_bf16 v[116:119], v[140:143], v[148:151], v[116:119]
	v_mfma_f32_16x16x32_bf16 v[120:123], v[140:143], v[152:155], v[120:123]
	v_mfma_f32_16x16x32_bf16 v[124:127], v[140:143], v[156:159], v[124:127]
	s_barrier
	v_add_u32_e32 v8, 256, v8
	v_add_u32_e32 v10, 256, v10
	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 16
	s_cbranch_scc1 .Lk128_stage_loop

	// Base output address for this wave's 64x64 quadrant.
	v_and_b32_e32 v12, 48, v1
	v_mul_lo_u32 v12, s23, v12
	s_mul_i32 s19, s16, 24576
	v_add_u32_e32 v13, s17, v3
	v_lshlrev_b32_e32 v13, 1, v13
	v_add_u32_e32 v14, s19, v12
	v_add_u32_e32 v14, v14, v13

	// accumulator tile r0c0
	v_cvt_pk_bf16_f32 v32, v64, v65
	v_cvt_pk_bf16_f32 v33, v66, v67
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	global_store_short v14, v32, s[2:3]
	v_add_u32_e32 v15, 24576, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 49152, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 73728, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r0c1
	v_cvt_pk_bf16_f32 v32, v68, v69
	v_cvt_pk_bf16_f32 v33, v70, v71
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 32, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 24608, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 49184, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 73760, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r0c2
	v_cvt_pk_bf16_f32 v32, v72, v73
	v_cvt_pk_bf16_f32 v33, v74, v75
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 64, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 24640, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 49216, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 73792, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r0c3
	v_cvt_pk_bf16_f32 v32, v76, v77
	v_cvt_pk_bf16_f32 v33, v78, v79
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 96, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 24672, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 49248, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 73824, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r1c0
	v_cvt_pk_bf16_f32 v32, v80, v81
	v_cvt_pk_bf16_f32 v33, v82, v83
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 393216, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 417792, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 442368, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 466944, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r1c1
	v_cvt_pk_bf16_f32 v32, v84, v85
	v_cvt_pk_bf16_f32 v33, v86, v87
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 393248, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 417824, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 442400, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 466976, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r1c2
	v_cvt_pk_bf16_f32 v32, v88, v89
	v_cvt_pk_bf16_f32 v33, v90, v91
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 393280, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 417856, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 442432, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 467008, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r1c3
	v_cvt_pk_bf16_f32 v32, v92, v93
	v_cvt_pk_bf16_f32 v33, v94, v95
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 393312, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 417888, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 442464, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 467040, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r2c0
	v_cvt_pk_bf16_f32 v32, v96, v97
	v_cvt_pk_bf16_f32 v33, v98, v99
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 786432, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 811008, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 835584, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 860160, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r2c1
	v_cvt_pk_bf16_f32 v32, v100, v101
	v_cvt_pk_bf16_f32 v33, v102, v103
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 786464, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 811040, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 835616, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 860192, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r2c2
	v_cvt_pk_bf16_f32 v32, v104, v105
	v_cvt_pk_bf16_f32 v33, v106, v107
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 786496, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 811072, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 835648, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 860224, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r2c3
	v_cvt_pk_bf16_f32 v32, v108, v109
	v_cvt_pk_bf16_f32 v33, v110, v111
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 786528, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 811104, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 835680, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 860256, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r3c0
	v_cvt_pk_bf16_f32 v32, v112, v113
	v_cvt_pk_bf16_f32 v33, v114, v115
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 1179648, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 1204224, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 1228800, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 1253376, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r3c1
	v_cvt_pk_bf16_f32 v32, v116, v117
	v_cvt_pk_bf16_f32 v33, v118, v119
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 1179680, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 1204256, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 1228832, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 1253408, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r3c2
	v_cvt_pk_bf16_f32 v32, v120, v121
	v_cvt_pk_bf16_f32 v33, v122, v123
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 1179712, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 1204288, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 1228864, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 1253440, v14
	global_store_short v15, v35, s[2:3]
	// accumulator tile r3c3
	v_cvt_pk_bf16_f32 v32, v124, v125
	v_cvt_pk_bf16_f32 v33, v126, v127
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 1179744, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 1204320, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 1228896, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 1253472, v14
	global_store_short v15, v35, s[2:3]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950
		.amdhsa_group_segment_fixed_size 81920
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 160
		.amdhsa_accum_offset 160
		.amdhsa_next_free_sgpr 24
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950, .Lfunc_end0-qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: input_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: weight_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 81920
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: qwen36_dflash_mlp_gateup_bf16_m768_m128n128_lds128_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 160
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
