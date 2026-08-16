// SPDX-License-Identifier: MIT
//
// Qwen3.6 FP8 E4M3 wave-N W13+SiLU+quantization experiment for gfx950.
//
// One four-wave64 workgroup consumes one expert-sorted M64 block. Each wave
// owns one N128 activation group and retains all four M16 row tiles in high
// VGPR state. The workgroup stages the complete N512 gate or up K128 slab in
// 64 KiB LDS, so each weight byte is loaded once per M64 block. After all 16
// K128 groups, BF16 SiLU results replace the weight slab and are quantized in
// place to the real checkpoint's route-major E4M3 128-column blocks.
//
// Grid: (1, num_valid_ids/64, 1), workgroup: 256, LDS: 64 KiB.
// This is an isolated W13 milestone; it is not a production serving kernel.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950
	.globl qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950
	.p2align 8
	.type qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950,@function
qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950:
	// hidden, hidden scale, W13, W13 scale, sorted IDs, compact experts,
	// valid count, route activation, route scale, rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dwordx2 s[20:21], s[0:1], 64
	s_load_dword s22, s[0:1], 72
	s_waitcnt lgkmcnt(0)

	// Exact M64 bounds and compact expert.
	s_lshl_b32 s23, s3, 6
	s_load_dword s24, s[16:17], 0
	s_lshl_b32 s25, s3, 2
	s_load_dword s25, s[14:15], s25
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s23, s24
	s_cbranch_scc0 .Lend

	// Wave owns N128; lane groups retain native MFMA row mapping.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0

	// Four hidden-row IDs, one for each retained M16 row tile.
	.macro LOAD_A_ID dst, rowoff
	v_add_u32_e32 v98, s23, v1
	v_add_u32_e32 v98, \rowoff, v98
	v_lshlrev_b32_e32 v98, 2, v98
	global_load_dword v\dst, v98, s[12:13]
	.endm
	LOAD_A_ID 40,0
	LOAD_A_ID 41,16
	LOAD_A_ID 42,32
	LOAD_A_ID 43,48

	// Sixteen result-row IDs provide the per-K128 hidden scales.
	v_lshrrev_b32_e32 v97, 2, v2
	.macro LOAD_RESULT_IDS dst0,dst1,dst2,dst3,rowoff
	v_add_u32_e32 v98, s23, v97
	v_add_u32_e32 v98, \rowoff, v98
	v_lshlrev_b32_e32 v98, 2, v98
	global_load_dwordx4 v[\dst0:\dst3], v98, s[12:13]
	.endm
	LOAD_RESULT_IDS 48,49,50,51,0
	LOAD_RESULT_IDS 52,53,54,55,16
	LOAD_RESULT_IDS 56,57,58,59,32
	LOAD_RESULT_IDS 60,61,62,63,48
	s_waitcnt vmcnt(0)

	// Padded routes read row zero but never write an output in the quantizer.
	.macro DECODE_TOKEN reg
	v_lshrrev_b32_e32 v98, 24, v\reg
	v_and_b32_e32 v\reg, 0x00ffffff, v\reg
	v_cmp_gt_u32_e32 vcc, s22, v\reg
	v_cndmask_b32_e32 v\reg, 0, v\reg, vcc
	v_cmp_gt_u32_e32 vcc, 9, v98
	v_cndmask_b32_e32 v\reg, 0, v\reg, vcc
	.endm
	.irp r,40,41,42,43,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	DECODE_TOKEN \r
	.endr

	// Hidden row bases include the lane-group K-fragment displacement.
	v_lshlrev_b32_e32 v44, 11, v40
	v_lshlrev_b32_e32 v45, 11, v41
	v_lshlrev_b32_e32 v46, 11, v42
	v_lshlrev_b32_e32 v47, 11, v43
	v_add_u32_e32 v44, v2, v44
	v_add_u32_e32 v45, v2, v45
	v_add_u32_e32 v46, v2, v46
	v_add_u32_e32 v47, v2, v47

	// Expert W13 and scale bases. Up follows gate by 1 MiB.
	s_lshl_b32 s26, s25, 21
	s_add_u32 s30, s8, s26
	s_addc_u32 s31, s9, 0
	s_add_u32 s34, s30, 1048576
	s_addc_u32 s35, s31, 0
	s_lshl_b32 s26, s25, 9
	s_add_u32 s32, s10, s26
	s_addc_u32 s33, s11, 0

	// GLOBAL uses a signed 13-bit immediate on gfx950. Materialize one
	// vector base per shuffled N16 tile, then use only 0..1536 immediates.
	.macro BUILD_WEIGHT_ADDRS
	v_mov_b32_e32 v168, v98
	v_add_u32_e32 v169, 32768, v98
	v_add_u32_e32 v170, 65536, v98
	v_add_u32_e32 v171, 98304, v98
	v_add_u32_e32 v172, 131072, v98
	v_add_u32_e32 v173, 163840, v98
	v_add_u32_e32 v174, 196608, v98
	v_add_u32_e32 v175, 229376, v98
	.endm

	// AGPR-resident gate/up accumulators: four M16 row tiles x eight N16
	// tiles x four results x two projections. gfx950 exposes v0..v255;
	// a0..a255 provide the second high-register bank used by this schedule.
	.macro ZERO_ACC reg
	v_accvgpr_write_b32 a\reg, v128
	.endm
	v_mov_b32_e32 v128, 0
	.irp r,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255
	ZERO_ACC \r
	.endr

	s_mov_b32 s27, 0
.Lk_loop:
	// Four retained A fragments.
	s_lshl_b32 s28, s27, 7
	v_add_u32_e32 v98, s28, v44
	global_load_dwordx4 v[8:11], v98, s[4:5]
	global_load_dwordx4 v[12:15], v98, s[4:5] offset:64
	v_add_u32_e32 v98, s28, v45
	global_load_dwordx4 v[16:19], v98, s[4:5]
	global_load_dwordx4 v[20:23], v98, s[4:5] offset:64
	v_add_u32_e32 v98, s28, v46
	global_load_dwordx4 v[24:27], v98, s[4:5]
	global_load_dwordx4 v[28:31], v98, s[4:5] offset:64
	v_add_u32_e32 v98, s28, v47
	global_load_dwordx4 v[32:35], v98, s[4:5]
	global_load_dwordx4 v[36:39], v98, s[4:5] offset:64

	// Per-result A scales and per-wave gate/up scales.
	s_lshl_b32 s29, s27, 2
	.macro LOAD_A_SCALE dst, token
	v_lshlrev_b32_e32 v98, 6, v\token
	v_add_u32_e32 v98, s29, v98
	global_load_dword v\dst, v98, s[6:7]
	.endm
	LOAD_A_SCALE 80,48
	LOAD_A_SCALE 81,49
	LOAD_A_SCALE 82,50
	LOAD_A_SCALE 83,51
	LOAD_A_SCALE 84,52
	LOAD_A_SCALE 85,53
	LOAD_A_SCALE 86,54
	LOAD_A_SCALE 87,55
	LOAD_A_SCALE 88,56
	LOAD_A_SCALE 89,57
	LOAD_A_SCALE 90,58
	LOAD_A_SCALE 91,59
	LOAD_A_SCALE 92,60
	LOAD_A_SCALE 93,61
	LOAD_A_SCALE 94,62
	LOAD_A_SCALE 95,63
	v_lshlrev_b32_e32 v98, 6, v3
	v_add_u32_e32 v98, s29, v98
	global_load_dword v96, v98, s[32:33]
	global_load_dword v97, v98, s[32:33] offset:256

	// Each wave loads its N128 (eight N16 tiles) into a private 16 KiB
	// slice. Together the four waves stage the complete N512 gate slab.
	v_lshlrev_b32_e32 v98, 18, v3
	s_lshl_b32 s28, s27, 11
	v_add_u32_e32 v98, s28, v98
	v_and_b32_e32 v99, 63, v0
	v_lshlrev_b32_e32 v99, 3, v99
	v_add_u32_e32 v98, v99, v98
	BUILD_WEIGHT_ADDRS
	global_load_dwordx2 v[104:105], v168, s[30:31] offset:0
	global_load_dwordx2 v[106:107], v168, s[30:31] offset:512
	global_load_dwordx2 v[108:109], v168, s[30:31] offset:1024
	global_load_dwordx2 v[110:111], v168, s[30:31] offset:1536
	global_load_dwordx2 v[112:113], v169, s[30:31] offset:0
	global_load_dwordx2 v[114:115], v169, s[30:31] offset:512
	global_load_dwordx2 v[116:117], v169, s[30:31] offset:1024
	global_load_dwordx2 v[118:119], v169, s[30:31] offset:1536
	global_load_dwordx2 v[120:121], v170, s[30:31] offset:0
	global_load_dwordx2 v[122:123], v170, s[30:31] offset:512
	global_load_dwordx2 v[124:125], v170, s[30:31] offset:1024
	global_load_dwordx2 v[126:127], v170, s[30:31] offset:1536
	global_load_dwordx2 v[128:129], v171, s[30:31] offset:0
	global_load_dwordx2 v[130:131], v171, s[30:31] offset:512
	global_load_dwordx2 v[132:133], v171, s[30:31] offset:1024
	global_load_dwordx2 v[134:135], v171, s[30:31] offset:1536
	global_load_dwordx2 v[136:137], v172, s[30:31] offset:0
	global_load_dwordx2 v[138:139], v172, s[30:31] offset:512
	global_load_dwordx2 v[140:141], v172, s[30:31] offset:1024
	global_load_dwordx2 v[142:143], v172, s[30:31] offset:1536
	global_load_dwordx2 v[144:145], v173, s[30:31] offset:0
	global_load_dwordx2 v[146:147], v173, s[30:31] offset:512
	global_load_dwordx2 v[148:149], v173, s[30:31] offset:1024
	global_load_dwordx2 v[150:151], v173, s[30:31] offset:1536
	global_load_dwordx2 v[152:153], v174, s[30:31] offset:0
	global_load_dwordx2 v[154:155], v174, s[30:31] offset:512
	global_load_dwordx2 v[156:157], v174, s[30:31] offset:1024
	global_load_dwordx2 v[158:159], v174, s[30:31] offset:1536
	global_load_dwordx2 v[160:161], v175, s[30:31] offset:0
	global_load_dwordx2 v[162:163], v175, s[30:31] offset:512
	global_load_dwordx2 v[164:165], v175, s[30:31] offset:1024
	global_load_dwordx2 v[166:167], v175, s[30:31] offset:1536

	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v99, 14, v3
	v_and_b32_e32 v100, 63, v0
	v_lshlrev_b32_e32 v100, 3, v100
	v_add_u32_e32 v99, v100, v99
	ds_write_b64 v99, v[104:105] offset:0
	ds_write_b64 v99, v[106:107] offset:512
	ds_write_b64 v99, v[108:109] offset:1024
	ds_write_b64 v99, v[110:111] offset:1536
	ds_write_b64 v99, v[112:113] offset:2048
	ds_write_b64 v99, v[114:115] offset:2560
	ds_write_b64 v99, v[116:117] offset:3072
	ds_write_b64 v99, v[118:119] offset:3584
	ds_write_b64 v99, v[120:121] offset:4096
	ds_write_b64 v99, v[122:123] offset:4608
	ds_write_b64 v99, v[124:125] offset:5120
	ds_write_b64 v99, v[126:127] offset:5632
	ds_write_b64 v99, v[128:129] offset:6144
	ds_write_b64 v99, v[130:131] offset:6656
	ds_write_b64 v99, v[132:133] offset:7168
	ds_write_b64 v99, v[134:135] offset:7680
	ds_write_b64 v99, v[136:137] offset:8192
	ds_write_b64 v99, v[138:139] offset:8704
	ds_write_b64 v99, v[140:141] offset:9216
	ds_write_b64 v99, v[142:143] offset:9728
	ds_write_b64 v99, v[144:145] offset:10240
	ds_write_b64 v99, v[146:147] offset:10752
	ds_write_b64 v99, v[148:149] offset:11264
	ds_write_b64 v99, v[150:151] offset:11776
	ds_write_b64 v99, v[152:153] offset:12288
	ds_write_b64 v99, v[154:155] offset:12800
	ds_write_b64 v99, v[156:157] offset:13312
	ds_write_b64 v99, v[158:159] offset:13824
	ds_write_b64 v99, v[160:161] offset:14336
	ds_write_b64 v99, v[162:163] offset:14848
	ds_write_b64 v99, v[164:165] offset:15360
	ds_write_b64 v99, v[166:167] offset:15872

	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)

	// Native MFMA read coordinate for this wave's staged N128 slab.
	v_lshlrev_b32_e32 v100, 14, v3
	v_lshlrev_b32_e32 v101, 4, v2
	v_lshlrev_b32_e32 v102, 4, v1
	v_add_u32_e32 v101, v102, v101
	v_add_u32_e32 v100, v101, v100
	ds_read_b128 v[104:107], v100 offset:0
	ds_read_b128 v[108:111], v100 offset:1024
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a0
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a0, v128
	v_accvgpr_read_b32 v128, a1
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a1, v128
	v_accvgpr_read_b32 v128, a2
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a2, v128
	v_accvgpr_read_b32 v128, a3
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a3, v128
	v_accvgpr_read_b32 v128, a64
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a64, v128
	v_accvgpr_read_b32 v128, a65
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a65, v128
	v_accvgpr_read_b32 v128, a66
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a66, v128
	v_accvgpr_read_b32 v128, a67
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a67, v128
	v_accvgpr_read_b32 v128, a128
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a128, v128
	v_accvgpr_read_b32 v128, a129
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a129, v128
	v_accvgpr_read_b32 v128, a130
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a130, v128
	v_accvgpr_read_b32 v128, a131
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a131, v128
	v_accvgpr_read_b32 v128, a192
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a192, v128
	v_accvgpr_read_b32 v128, a193
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a193, v128
	v_accvgpr_read_b32 v128, a194
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a194, v128
	v_accvgpr_read_b32 v128, a195
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a195, v128
	ds_read_b128 v[104:107], v100 offset:2048
	ds_read_b128 v[108:111], v100 offset:3072
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a4
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a4, v128
	v_accvgpr_read_b32 v128, a5
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a5, v128
	v_accvgpr_read_b32 v128, a6
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a6, v128
	v_accvgpr_read_b32 v128, a7
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a7, v128
	v_accvgpr_read_b32 v128, a68
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a68, v128
	v_accvgpr_read_b32 v128, a69
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a69, v128
	v_accvgpr_read_b32 v128, a70
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a70, v128
	v_accvgpr_read_b32 v128, a71
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a71, v128
	v_accvgpr_read_b32 v128, a132
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a132, v128
	v_accvgpr_read_b32 v128, a133
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a133, v128
	v_accvgpr_read_b32 v128, a134
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a134, v128
	v_accvgpr_read_b32 v128, a135
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a135, v128
	v_accvgpr_read_b32 v128, a196
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a196, v128
	v_accvgpr_read_b32 v128, a197
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a197, v128
	v_accvgpr_read_b32 v128, a198
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a198, v128
	v_accvgpr_read_b32 v128, a199
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a199, v128
	ds_read_b128 v[104:107], v100 offset:4096
	ds_read_b128 v[108:111], v100 offset:5120
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a8
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a8, v128
	v_accvgpr_read_b32 v128, a9
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a9, v128
	v_accvgpr_read_b32 v128, a10
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a10, v128
	v_accvgpr_read_b32 v128, a11
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a11, v128
	v_accvgpr_read_b32 v128, a72
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a72, v128
	v_accvgpr_read_b32 v128, a73
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a73, v128
	v_accvgpr_read_b32 v128, a74
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a74, v128
	v_accvgpr_read_b32 v128, a75
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a75, v128
	v_accvgpr_read_b32 v128, a136
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a136, v128
	v_accvgpr_read_b32 v128, a137
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a137, v128
	v_accvgpr_read_b32 v128, a138
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a138, v128
	v_accvgpr_read_b32 v128, a139
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a139, v128
	v_accvgpr_read_b32 v128, a200
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a200, v128
	v_accvgpr_read_b32 v128, a201
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a201, v128
	v_accvgpr_read_b32 v128, a202
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a202, v128
	v_accvgpr_read_b32 v128, a203
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a203, v128
	ds_read_b128 v[104:107], v100 offset:6144
	ds_read_b128 v[108:111], v100 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a12
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a12, v128
	v_accvgpr_read_b32 v128, a13
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a13, v128
	v_accvgpr_read_b32 v128, a14
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a14, v128
	v_accvgpr_read_b32 v128, a15
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a15, v128
	v_accvgpr_read_b32 v128, a76
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a76, v128
	v_accvgpr_read_b32 v128, a77
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a77, v128
	v_accvgpr_read_b32 v128, a78
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a78, v128
	v_accvgpr_read_b32 v128, a79
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a79, v128
	v_accvgpr_read_b32 v128, a140
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a140, v128
	v_accvgpr_read_b32 v128, a141
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a141, v128
	v_accvgpr_read_b32 v128, a142
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a142, v128
	v_accvgpr_read_b32 v128, a143
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a143, v128
	v_accvgpr_read_b32 v128, a204
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a204, v128
	v_accvgpr_read_b32 v128, a205
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a205, v128
	v_accvgpr_read_b32 v128, a206
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a206, v128
	v_accvgpr_read_b32 v128, a207
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a207, v128
	ds_read_b128 v[104:107], v100 offset:8192
	ds_read_b128 v[108:111], v100 offset:9216
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a16
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a16, v128
	v_accvgpr_read_b32 v128, a17
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a17, v128
	v_accvgpr_read_b32 v128, a18
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a18, v128
	v_accvgpr_read_b32 v128, a19
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a19, v128
	v_accvgpr_read_b32 v128, a80
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a80, v128
	v_accvgpr_read_b32 v128, a81
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a81, v128
	v_accvgpr_read_b32 v128, a82
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a82, v128
	v_accvgpr_read_b32 v128, a83
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a83, v128
	v_accvgpr_read_b32 v128, a144
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a144, v128
	v_accvgpr_read_b32 v128, a145
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a145, v128
	v_accvgpr_read_b32 v128, a146
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a146, v128
	v_accvgpr_read_b32 v128, a147
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a147, v128
	v_accvgpr_read_b32 v128, a208
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a208, v128
	v_accvgpr_read_b32 v128, a209
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a209, v128
	v_accvgpr_read_b32 v128, a210
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a210, v128
	v_accvgpr_read_b32 v128, a211
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a211, v128
	ds_read_b128 v[104:107], v100 offset:10240
	ds_read_b128 v[108:111], v100 offset:11264
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a20
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a20, v128
	v_accvgpr_read_b32 v128, a21
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a21, v128
	v_accvgpr_read_b32 v128, a22
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a22, v128
	v_accvgpr_read_b32 v128, a23
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a23, v128
	v_accvgpr_read_b32 v128, a84
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a84, v128
	v_accvgpr_read_b32 v128, a85
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a85, v128
	v_accvgpr_read_b32 v128, a86
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a86, v128
	v_accvgpr_read_b32 v128, a87
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a87, v128
	v_accvgpr_read_b32 v128, a148
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a148, v128
	v_accvgpr_read_b32 v128, a149
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a149, v128
	v_accvgpr_read_b32 v128, a150
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a150, v128
	v_accvgpr_read_b32 v128, a151
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a151, v128
	v_accvgpr_read_b32 v128, a212
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a212, v128
	v_accvgpr_read_b32 v128, a213
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a213, v128
	v_accvgpr_read_b32 v128, a214
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a214, v128
	v_accvgpr_read_b32 v128, a215
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a215, v128
	ds_read_b128 v[104:107], v100 offset:12288
	ds_read_b128 v[108:111], v100 offset:13312
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a24
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a24, v128
	v_accvgpr_read_b32 v128, a25
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a25, v128
	v_accvgpr_read_b32 v128, a26
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a26, v128
	v_accvgpr_read_b32 v128, a27
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a27, v128
	v_accvgpr_read_b32 v128, a88
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a88, v128
	v_accvgpr_read_b32 v128, a89
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a89, v128
	v_accvgpr_read_b32 v128, a90
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a90, v128
	v_accvgpr_read_b32 v128, a91
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a91, v128
	v_accvgpr_read_b32 v128, a152
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a152, v128
	v_accvgpr_read_b32 v128, a153
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a153, v128
	v_accvgpr_read_b32 v128, a154
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a154, v128
	v_accvgpr_read_b32 v128, a155
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a155, v128
	v_accvgpr_read_b32 v128, a216
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a216, v128
	v_accvgpr_read_b32 v128, a217
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a217, v128
	v_accvgpr_read_b32 v128, a218
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a218, v128
	v_accvgpr_read_b32 v128, a219
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a219, v128
	ds_read_b128 v[104:107], v100 offset:14336
	ds_read_b128 v[108:111], v100 offset:15360
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a28
	v_mul_f32_e32 v112, v96, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a28, v128
	v_accvgpr_read_b32 v128, a29
	v_mul_f32_e32 v113, v96, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a29, v128
	v_accvgpr_read_b32 v128, a30
	v_mul_f32_e32 v114, v96, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a30, v128
	v_accvgpr_read_b32 v128, a31
	v_mul_f32_e32 v115, v96, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a31, v128
	v_accvgpr_read_b32 v128, a92
	v_mul_f32_e32 v116, v96, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a92, v128
	v_accvgpr_read_b32 v128, a93
	v_mul_f32_e32 v117, v96, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a93, v128
	v_accvgpr_read_b32 v128, a94
	v_mul_f32_e32 v118, v96, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a94, v128
	v_accvgpr_read_b32 v128, a95
	v_mul_f32_e32 v119, v96, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a95, v128
	v_accvgpr_read_b32 v128, a156
	v_mul_f32_e32 v120, v96, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a156, v128
	v_accvgpr_read_b32 v128, a157
	v_mul_f32_e32 v121, v96, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a157, v128
	v_accvgpr_read_b32 v128, a158
	v_mul_f32_e32 v122, v96, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a158, v128
	v_accvgpr_read_b32 v128, a159
	v_mul_f32_e32 v123, v96, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a159, v128
	v_accvgpr_read_b32 v128, a220
	v_mul_f32_e32 v124, v96, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a220, v128
	v_accvgpr_read_b32 v128, a221
	v_mul_f32_e32 v125, v96, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a221, v128
	v_accvgpr_read_b32 v128, a222
	v_mul_f32_e32 v126, v96, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a222, v128
	v_accvgpr_read_b32 v128, a223
	v_mul_f32_e32 v127, v96, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a223, v128

	// All waves must finish reading gate before LDS is overwritten by up.
	s_barrier

	v_lshlrev_b32_e32 v98, 18, v3
	s_lshl_b32 s28, s27, 11
	v_add_u32_e32 v98, s28, v98
	v_and_b32_e32 v99, 63, v0
	v_lshlrev_b32_e32 v99, 3, v99
	v_add_u32_e32 v98, v99, v98
	BUILD_WEIGHT_ADDRS
	global_load_dwordx2 v[104:105], v168, s[34:35] offset:0
	global_load_dwordx2 v[106:107], v168, s[34:35] offset:512
	global_load_dwordx2 v[108:109], v168, s[34:35] offset:1024
	global_load_dwordx2 v[110:111], v168, s[34:35] offset:1536
	global_load_dwordx2 v[112:113], v169, s[34:35] offset:0
	global_load_dwordx2 v[114:115], v169, s[34:35] offset:512
	global_load_dwordx2 v[116:117], v169, s[34:35] offset:1024
	global_load_dwordx2 v[118:119], v169, s[34:35] offset:1536
	global_load_dwordx2 v[120:121], v170, s[34:35] offset:0
	global_load_dwordx2 v[122:123], v170, s[34:35] offset:512
	global_load_dwordx2 v[124:125], v170, s[34:35] offset:1024
	global_load_dwordx2 v[126:127], v170, s[34:35] offset:1536
	global_load_dwordx2 v[128:129], v171, s[34:35] offset:0
	global_load_dwordx2 v[130:131], v171, s[34:35] offset:512
	global_load_dwordx2 v[132:133], v171, s[34:35] offset:1024
	global_load_dwordx2 v[134:135], v171, s[34:35] offset:1536
	global_load_dwordx2 v[136:137], v172, s[34:35] offset:0
	global_load_dwordx2 v[138:139], v172, s[34:35] offset:512
	global_load_dwordx2 v[140:141], v172, s[34:35] offset:1024
	global_load_dwordx2 v[142:143], v172, s[34:35] offset:1536
	global_load_dwordx2 v[144:145], v173, s[34:35] offset:0
	global_load_dwordx2 v[146:147], v173, s[34:35] offset:512
	global_load_dwordx2 v[148:149], v173, s[34:35] offset:1024
	global_load_dwordx2 v[150:151], v173, s[34:35] offset:1536
	global_load_dwordx2 v[152:153], v174, s[34:35] offset:0
	global_load_dwordx2 v[154:155], v174, s[34:35] offset:512
	global_load_dwordx2 v[156:157], v174, s[34:35] offset:1024
	global_load_dwordx2 v[158:159], v174, s[34:35] offset:1536
	global_load_dwordx2 v[160:161], v175, s[34:35] offset:0
	global_load_dwordx2 v[162:163], v175, s[34:35] offset:512
	global_load_dwordx2 v[164:165], v175, s[34:35] offset:1024
	global_load_dwordx2 v[166:167], v175, s[34:35] offset:1536

	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v99, 14, v3
	v_and_b32_e32 v101, 63, v0
	v_lshlrev_b32_e32 v101, 3, v101
	v_add_u32_e32 v99, v101, v99
	ds_write_b64 v99, v[104:105] offset:0
	ds_write_b64 v99, v[106:107] offset:512
	ds_write_b64 v99, v[108:109] offset:1024
	ds_write_b64 v99, v[110:111] offset:1536
	ds_write_b64 v99, v[112:113] offset:2048
	ds_write_b64 v99, v[114:115] offset:2560
	ds_write_b64 v99, v[116:117] offset:3072
	ds_write_b64 v99, v[118:119] offset:3584
	ds_write_b64 v99, v[120:121] offset:4096
	ds_write_b64 v99, v[122:123] offset:4608
	ds_write_b64 v99, v[124:125] offset:5120
	ds_write_b64 v99, v[126:127] offset:5632
	ds_write_b64 v99, v[128:129] offset:6144
	ds_write_b64 v99, v[130:131] offset:6656
	ds_write_b64 v99, v[132:133] offset:7168
	ds_write_b64 v99, v[134:135] offset:7680
	ds_write_b64 v99, v[136:137] offset:8192
	ds_write_b64 v99, v[138:139] offset:8704
	ds_write_b64 v99, v[140:141] offset:9216
	ds_write_b64 v99, v[142:143] offset:9728
	ds_write_b64 v99, v[144:145] offset:10240
	ds_write_b64 v99, v[146:147] offset:10752
	ds_write_b64 v99, v[148:149] offset:11264
	ds_write_b64 v99, v[150:151] offset:11776
	ds_write_b64 v99, v[152:153] offset:12288
	ds_write_b64 v99, v[154:155] offset:12800
	ds_write_b64 v99, v[156:157] offset:13312
	ds_write_b64 v99, v[158:159] offset:13824
	ds_write_b64 v99, v[160:161] offset:14336
	ds_write_b64 v99, v[162:163] offset:14848
	ds_write_b64 v99, v[164:165] offset:15360
	ds_write_b64 v99, v[166:167] offset:15872

	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[104:107], v100 offset:0
	ds_read_b128 v[108:111], v100 offset:1024
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a32
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a32, v128
	v_accvgpr_read_b32 v128, a33
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a33, v128
	v_accvgpr_read_b32 v128, a34
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a34, v128
	v_accvgpr_read_b32 v128, a35
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a35, v128
	v_accvgpr_read_b32 v128, a96
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a96, v128
	v_accvgpr_read_b32 v128, a97
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a97, v128
	v_accvgpr_read_b32 v128, a98
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a98, v128
	v_accvgpr_read_b32 v128, a99
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a99, v128
	v_accvgpr_read_b32 v128, a160
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a160, v128
	v_accvgpr_read_b32 v128, a161
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a161, v128
	v_accvgpr_read_b32 v128, a162
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a162, v128
	v_accvgpr_read_b32 v128, a163
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a163, v128
	v_accvgpr_read_b32 v128, a224
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a224, v128
	v_accvgpr_read_b32 v128, a225
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a225, v128
	v_accvgpr_read_b32 v128, a226
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a226, v128
	v_accvgpr_read_b32 v128, a227
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a227, v128
	ds_read_b128 v[104:107], v100 offset:2048
	ds_read_b128 v[108:111], v100 offset:3072
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a36
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a36, v128
	v_accvgpr_read_b32 v128, a37
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a37, v128
	v_accvgpr_read_b32 v128, a38
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a38, v128
	v_accvgpr_read_b32 v128, a39
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a39, v128
	v_accvgpr_read_b32 v128, a100
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a100, v128
	v_accvgpr_read_b32 v128, a101
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a101, v128
	v_accvgpr_read_b32 v128, a102
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a102, v128
	v_accvgpr_read_b32 v128, a103
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a103, v128
	v_accvgpr_read_b32 v128, a164
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a164, v128
	v_accvgpr_read_b32 v128, a165
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a165, v128
	v_accvgpr_read_b32 v128, a166
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a166, v128
	v_accvgpr_read_b32 v128, a167
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a167, v128
	v_accvgpr_read_b32 v128, a228
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a228, v128
	v_accvgpr_read_b32 v128, a229
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a229, v128
	v_accvgpr_read_b32 v128, a230
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a230, v128
	v_accvgpr_read_b32 v128, a231
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a231, v128
	ds_read_b128 v[104:107], v100 offset:4096
	ds_read_b128 v[108:111], v100 offset:5120
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a40
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a40, v128
	v_accvgpr_read_b32 v128, a41
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a41, v128
	v_accvgpr_read_b32 v128, a42
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a42, v128
	v_accvgpr_read_b32 v128, a43
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a43, v128
	v_accvgpr_read_b32 v128, a104
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a104, v128
	v_accvgpr_read_b32 v128, a105
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a105, v128
	v_accvgpr_read_b32 v128, a106
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a106, v128
	v_accvgpr_read_b32 v128, a107
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a107, v128
	v_accvgpr_read_b32 v128, a168
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a168, v128
	v_accvgpr_read_b32 v128, a169
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a169, v128
	v_accvgpr_read_b32 v128, a170
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a170, v128
	v_accvgpr_read_b32 v128, a171
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a171, v128
	v_accvgpr_read_b32 v128, a232
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a232, v128
	v_accvgpr_read_b32 v128, a233
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a233, v128
	v_accvgpr_read_b32 v128, a234
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a234, v128
	v_accvgpr_read_b32 v128, a235
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a235, v128
	ds_read_b128 v[104:107], v100 offset:6144
	ds_read_b128 v[108:111], v100 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a44
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a44, v128
	v_accvgpr_read_b32 v128, a45
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a45, v128
	v_accvgpr_read_b32 v128, a46
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a46, v128
	v_accvgpr_read_b32 v128, a47
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a47, v128
	v_accvgpr_read_b32 v128, a108
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a108, v128
	v_accvgpr_read_b32 v128, a109
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a109, v128
	v_accvgpr_read_b32 v128, a110
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a110, v128
	v_accvgpr_read_b32 v128, a111
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a111, v128
	v_accvgpr_read_b32 v128, a172
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a172, v128
	v_accvgpr_read_b32 v128, a173
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a173, v128
	v_accvgpr_read_b32 v128, a174
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a174, v128
	v_accvgpr_read_b32 v128, a175
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a175, v128
	v_accvgpr_read_b32 v128, a236
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a236, v128
	v_accvgpr_read_b32 v128, a237
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a237, v128
	v_accvgpr_read_b32 v128, a238
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a238, v128
	v_accvgpr_read_b32 v128, a239
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a239, v128
	ds_read_b128 v[104:107], v100 offset:8192
	ds_read_b128 v[108:111], v100 offset:9216
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a48
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a48, v128
	v_accvgpr_read_b32 v128, a49
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a49, v128
	v_accvgpr_read_b32 v128, a50
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a50, v128
	v_accvgpr_read_b32 v128, a51
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a51, v128
	v_accvgpr_read_b32 v128, a112
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a112, v128
	v_accvgpr_read_b32 v128, a113
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a113, v128
	v_accvgpr_read_b32 v128, a114
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a114, v128
	v_accvgpr_read_b32 v128, a115
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a115, v128
	v_accvgpr_read_b32 v128, a176
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a176, v128
	v_accvgpr_read_b32 v128, a177
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a177, v128
	v_accvgpr_read_b32 v128, a178
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a178, v128
	v_accvgpr_read_b32 v128, a179
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a179, v128
	v_accvgpr_read_b32 v128, a240
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a240, v128
	v_accvgpr_read_b32 v128, a241
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a241, v128
	v_accvgpr_read_b32 v128, a242
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a242, v128
	v_accvgpr_read_b32 v128, a243
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a243, v128
	ds_read_b128 v[104:107], v100 offset:10240
	ds_read_b128 v[108:111], v100 offset:11264
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a52
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a52, v128
	v_accvgpr_read_b32 v128, a53
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a53, v128
	v_accvgpr_read_b32 v128, a54
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a54, v128
	v_accvgpr_read_b32 v128, a55
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a55, v128
	v_accvgpr_read_b32 v128, a116
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a116, v128
	v_accvgpr_read_b32 v128, a117
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a117, v128
	v_accvgpr_read_b32 v128, a118
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a118, v128
	v_accvgpr_read_b32 v128, a119
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a119, v128
	v_accvgpr_read_b32 v128, a180
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a180, v128
	v_accvgpr_read_b32 v128, a181
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a181, v128
	v_accvgpr_read_b32 v128, a182
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a182, v128
	v_accvgpr_read_b32 v128, a183
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a183, v128
	v_accvgpr_read_b32 v128, a244
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a244, v128
	v_accvgpr_read_b32 v128, a245
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a245, v128
	v_accvgpr_read_b32 v128, a246
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a246, v128
	v_accvgpr_read_b32 v128, a247
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a247, v128
	ds_read_b128 v[104:107], v100 offset:12288
	ds_read_b128 v[108:111], v100 offset:13312
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a56
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a56, v128
	v_accvgpr_read_b32 v128, a57
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a57, v128
	v_accvgpr_read_b32 v128, a58
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a58, v128
	v_accvgpr_read_b32 v128, a59
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a59, v128
	v_accvgpr_read_b32 v128, a120
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a120, v128
	v_accvgpr_read_b32 v128, a121
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a121, v128
	v_accvgpr_read_b32 v128, a122
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a122, v128
	v_accvgpr_read_b32 v128, a123
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a123, v128
	v_accvgpr_read_b32 v128, a184
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a184, v128
	v_accvgpr_read_b32 v128, a185
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a185, v128
	v_accvgpr_read_b32 v128, a186
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a186, v128
	v_accvgpr_read_b32 v128, a187
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a187, v128
	v_accvgpr_read_b32 v128, a248
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a248, v128
	v_accvgpr_read_b32 v128, a249
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a249, v128
	v_accvgpr_read_b32 v128, a250
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a250, v128
	v_accvgpr_read_b32 v128, a251
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a251, v128
	ds_read_b128 v[104:107], v100 offset:14336
	ds_read_b128 v[108:111], v100 offset:15360
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[8:15], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[16:23], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[24:31], v[104:111], 0
	v_mfma_f32_16x16x128_f8f6f4 v[124:127], v[32:39], v[104:111], 0
	s_nop 12
	v_accvgpr_read_b32 v128, a60
	v_mul_f32_e32 v112, v97, v112
	v_fmac_f32_e32 v128, v80, v112
	v_accvgpr_write_b32 a60, v128
	v_accvgpr_read_b32 v128, a61
	v_mul_f32_e32 v113, v97, v113
	v_fmac_f32_e32 v128, v81, v113
	v_accvgpr_write_b32 a61, v128
	v_accvgpr_read_b32 v128, a62
	v_mul_f32_e32 v114, v97, v114
	v_fmac_f32_e32 v128, v82, v114
	v_accvgpr_write_b32 a62, v128
	v_accvgpr_read_b32 v128, a63
	v_mul_f32_e32 v115, v97, v115
	v_fmac_f32_e32 v128, v83, v115
	v_accvgpr_write_b32 a63, v128
	v_accvgpr_read_b32 v128, a124
	v_mul_f32_e32 v116, v97, v116
	v_fmac_f32_e32 v128, v84, v116
	v_accvgpr_write_b32 a124, v128
	v_accvgpr_read_b32 v128, a125
	v_mul_f32_e32 v117, v97, v117
	v_fmac_f32_e32 v128, v85, v117
	v_accvgpr_write_b32 a125, v128
	v_accvgpr_read_b32 v128, a126
	v_mul_f32_e32 v118, v97, v118
	v_fmac_f32_e32 v128, v86, v118
	v_accvgpr_write_b32 a126, v128
	v_accvgpr_read_b32 v128, a127
	v_mul_f32_e32 v119, v97, v119
	v_fmac_f32_e32 v128, v87, v119
	v_accvgpr_write_b32 a127, v128
	v_accvgpr_read_b32 v128, a188
	v_mul_f32_e32 v120, v97, v120
	v_fmac_f32_e32 v128, v88, v120
	v_accvgpr_write_b32 a188, v128
	v_accvgpr_read_b32 v128, a189
	v_mul_f32_e32 v121, v97, v121
	v_fmac_f32_e32 v128, v89, v121
	v_accvgpr_write_b32 a189, v128
	v_accvgpr_read_b32 v128, a190
	v_mul_f32_e32 v122, v97, v122
	v_fmac_f32_e32 v128, v90, v122
	v_accvgpr_write_b32 a190, v128
	v_accvgpr_read_b32 v128, a191
	v_mul_f32_e32 v123, v97, v123
	v_fmac_f32_e32 v128, v91, v123
	v_accvgpr_write_b32 a191, v128
	v_accvgpr_read_b32 v128, a252
	v_mul_f32_e32 v124, v97, v124
	v_fmac_f32_e32 v128, v92, v124
	v_accvgpr_write_b32 a252, v128
	v_accvgpr_read_b32 v128, a253
	v_mul_f32_e32 v125, v97, v125
	v_fmac_f32_e32 v128, v93, v125
	v_accvgpr_write_b32 a253, v128
	v_accvgpr_read_b32 v128, a254
	v_mul_f32_e32 v126, v97, v126
	v_fmac_f32_e32 v128, v94, v126
	v_accvgpr_write_b32 a254, v128
	v_accvgpr_read_b32 v128, a255
	v_mul_f32_e32 v127, v97, v127
	v_fmac_f32_e32 v128, v95, v127
	v_accvgpr_write_b32 a255, v128

	s_barrier
	s_add_u32 s27, s27, 1
	s_cmp_lt_u32 s27, 16
	s_cbranch_scc1 .Lk_loop

	// Replace the weight slab with BF16-rounded SiLU(gate)*up activation.
	s_mov_b32 s48, 0xbfb8aa3b
	s_mov_b32 s49, 0x3f800000
	.macro ACT_STORE g0,g1,g2,g3,u0,u1,u2,u3,ldsoff
	v_accvgpr_read_b32 v120, a\g0
	v_accvgpr_read_b32 v121, a\g1
	v_accvgpr_read_b32 v122, a\g2
	v_accvgpr_read_b32 v123, a\g3
	v_accvgpr_read_b32 v124, a\u0
	v_accvgpr_read_b32 v125, a\u1
	v_accvgpr_read_b32 v126, a\u2
	v_accvgpr_read_b32 v127, a\u3
	v_cvt_pk_bf16_f32 v104, v120, v121
	v_cvt_pk_bf16_f32 v105, v122, v123
	v_cvt_pk_bf16_f32 v106, v124, v125
	v_cvt_pk_bf16_f32 v107, v126, v127
	v_lshlrev_b32_e32 v108, 16, v104
	v_and_b32_e32 v109, 0xffff0000, v104
	v_lshlrev_b32_e32 v110, 16, v105
	v_and_b32_e32 v111, 0xffff0000, v105
	v_lshlrev_b32_e32 v112, 16, v106
	v_and_b32_e32 v113, 0xffff0000, v106
	v_lshlrev_b32_e32 v114, 16, v107
	v_and_b32_e32 v115, 0xffff0000, v107
	v_mul_f32_e32 v116, s48, v108
	v_mul_f32_e32 v117, s48, v109
	v_mul_f32_e32 v118, s48, v110
	v_mul_f32_e32 v119, s48, v111
	v_exp_f32_e32 v116, v116
	v_exp_f32_e32 v117, v117
	v_exp_f32_e32 v118, v118
	v_exp_f32_e32 v119, v119
	v_add_f32_e32 v116, s49, v116
	v_add_f32_e32 v117, s49, v117
	v_add_f32_e32 v118, s49, v118
	v_add_f32_e32 v119, s49, v119
	v_rcp_f32_e32 v116, v116
	v_rcp_f32_e32 v117, v117
	v_rcp_f32_e32 v118, v118
	v_rcp_f32_e32 v119, v119
	v_mul_f32_e32 v108, v116, v108
	v_mul_f32_e32 v109, v117, v109
	v_mul_f32_e32 v110, v118, v110
	v_mul_f32_e32 v111, v119, v111
	v_mul_f32_e32 v108, v112, v108
	v_mul_f32_e32 v109, v113, v109
	v_mul_f32_e32 v110, v114, v110
	v_mul_f32_e32 v111, v115, v111
	v_cvt_pk_bf16_f32 v104, v108, v109
	v_cvt_pk_bf16_f32 v105, v110, v111
	v_add_u32_e32 v106, \ldsoff, v168
	ds_write_b64 v106, v[104:105]
	.endm
	// Row tile 0: native M16 layout within this wave's N128 slab.
	v_lshlrev_b32_e32 v168, 14, v3
	v_and_b32_e32 v169, 63, v0
	v_lshlrev_b32_e32 v169, 5, v169
	v_add_u32_e32 v168, v169, v168
	ACT_STORE 0,1,2,3,32,33,34,35,8192
	ACT_STORE 4,5,6,7,36,37,38,39,8200
	ACT_STORE 8,9,10,11,40,41,42,43,8208
	ACT_STORE 12,13,14,15,44,45,46,47,8216
	ACT_STORE 16,17,18,19,48,49,50,51,0
	ACT_STORE 20,21,22,23,52,53,54,55,8
	ACT_STORE 24,25,26,27,56,57,58,59,16
	ACT_STORE 28,29,30,31,60,61,62,63,24
	// Row tile 1: native M16 layout within this wave's N128 slab.
	v_lshlrev_b32_e32 v168, 14, v3
	v_and_b32_e32 v169, 63, v0
	v_lshlrev_b32_e32 v169, 5, v169
	v_add_u32_e32 v168, v169, v168
	v_add_u32_e32 v168, 2048, v168
	ACT_STORE 64,65,66,67,96,97,98,99,8192
	ACT_STORE 68,69,70,71,100,101,102,103,8200
	ACT_STORE 72,73,74,75,104,105,106,107,8208
	ACT_STORE 76,77,78,79,108,109,110,111,8216
	ACT_STORE 80,81,82,83,112,113,114,115,0
	ACT_STORE 84,85,86,87,116,117,118,119,8
	ACT_STORE 88,89,90,91,120,121,122,123,16
	ACT_STORE 92,93,94,95,124,125,126,127,24
	// Row tile 2: native M16 layout within this wave's N128 slab.
	v_lshlrev_b32_e32 v168, 14, v3
	v_and_b32_e32 v169, 63, v0
	v_lshlrev_b32_e32 v169, 5, v169
	v_add_u32_e32 v168, v169, v168
	v_add_u32_e32 v168, 4096, v168
	ACT_STORE 128,129,130,131,160,161,162,163,8192
	ACT_STORE 132,133,134,135,164,165,166,167,8200
	ACT_STORE 136,137,138,139,168,169,170,171,8208
	ACT_STORE 140,141,142,143,172,173,174,175,8216
	ACT_STORE 144,145,146,147,176,177,178,179,0
	ACT_STORE 148,149,150,151,180,181,182,183,8
	ACT_STORE 152,153,154,155,184,185,186,187,16
	ACT_STORE 156,157,158,159,188,189,190,191,24
	// Row tile 3: native M16 layout within this wave's N128 slab.
	v_lshlrev_b32_e32 v168, 14, v3
	v_and_b32_e32 v169, 63, v0
	v_lshlrev_b32_e32 v169, 5, v169
	v_add_u32_e32 v168, v169, v168
	v_add_u32_e32 v168, 6144, v168
	ACT_STORE 192,193,194,195,224,225,226,227,8192
	ACT_STORE 196,197,198,199,228,229,230,231,8200
	ACT_STORE 200,201,202,203,232,233,234,235,8208
	ACT_STORE 204,205,206,207,236,237,238,239,8216
	ACT_STORE 208,209,210,211,240,241,242,243,0
	ACT_STORE 212,213,214,215,244,245,246,247,8
	ACT_STORE 216,217,218,219,248,249,250,251,16
	ACT_STORE 220,221,222,223,252,253,254,255,24

	s_waitcnt lgkmcnt(0)
	s_barrier

	// Two 32-lane subgroups per wave quantize two routes per iteration.
	// Four waves cover the four N128 blocks concurrently.
	v_and_b32_e32 v1, 31, v0
	v_and_b32_e32 v25, 63, v0
	v_lshrrev_b32_e32 v2, 5, v25
	s_mov_b32 s50, 0
	s_mov_b32 s51, 0x3b124925
	s_mov_b32 s52, 0x2edbe6ff
	s_mov_b32 s53, 0x05040100
.Lquant_loop:
	s_lshl_b32 s54, s50, 1
	v_add_u32_e32 v3, s54, v2
	v_add_u32_e32 v4, s23, v3
	v_lshlrev_b32_e32 v4, 2, v4
	global_load_dword v5, v4, s[12:13]

	// Native LDS address for four adjacent columns of this route.
	v_lshrrev_b32_e32 v6, 4, v3
	v_lshlrev_b32_e32 v6, 11, v6
	v_and_b32_e32 v7, 15, v3
	v_lshrrev_b32_e32 v8, 2, v7
	v_lshlrev_b32_e32 v8, 9, v8
	v_add_u32_e32 v6, v8, v6
	v_and_b32_e32 v8, 3, v7
	v_lshlrev_b32_e32 v8, 1, v8
	v_add_u32_e32 v6, v8, v6
	v_and_b32_e32 v8, 15, v1
	v_lshlrev_b32_e32 v8, 2, v8
	v_and_b32_e32 v9, 15, v8
	v_lshlrev_b32_e32 v9, 5, v9
	v_add_u32_e32 v6, v9, v6
	v_lshrrev_b32_e32 v9, 4, v8
	v_lshlrev_b32_e32 v9, 3, v9
	v_add_u32_e32 v6, v9, v6
	v_cmp_gt_u32_e32 vcc, 16, v1
	v_mov_b32_e32 v9, 8192
	v_cndmask_b32_e32 v9, 0, v9, vcc
	v_add_u32_e32 v6, v9, v6
	v_lshrrev_b32_e32 v10, 6, v0
	v_lshlrev_b32_e32 v10, 14, v10
	v_add_u32_e32 v6, v10, v6
	ds_read_u16 v12, v6
	ds_read_u16 v13, v6 offset:32
	ds_read_u16 v14, v6 offset:64
	ds_read_u16 v15, v6 offset:96
	s_waitcnt vmcnt(0) & lgkmcnt(0)

	v_lshrrev_b32_e32 v16, 24, v5
	v_and_b32_e32 v17, 0x00ffffff, v5
	v_mul_lo_u32 v18, 9, v17
	v_add_u32_e32 v18, v16, v18
	v_lshlrev_b32_e32 v20, 16, v12
	v_lshlrev_b32_e32 v21, 16, v13
	v_lshlrev_b32_e32 v22, 16, v14
	v_lshlrev_b32_e32 v23, 16, v15
	v_max3_f32 v24, |v20|, |v21|, s52
	v_max3_f32 v24, v24, |v22|, |v23|
	.irp mask,1,2,4,8,16
	v_xor_b32_e32 v26, \mask, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	.endr
	v_mul_f32_e32 v24, s51, v24

	v_cmp_gt_u32_e64 s[60:61], 9, v16
	v_cmp_gt_u32_e64 s[62:63], s22, v17
	s_and_b64 s[60:61], s[60:61], s[62:63]
	v_cmp_eq_u32_e64 s[62:63], 0, v1
	s_and_b64 s[62:63], s[62:63], s[60:61]
	v_lshlrev_b32_e32 v26, 4, v18
	v_lshrrev_b32_e32 v27, 6, v0
	v_lshlrev_b32_e32 v27, 2, v27
	v_add_u32_e32 v26, v27, v26
	s_and_saveexec_b64 s[64:65], s[62:63]
	global_store_dword v26, v24, s[20:21]
	s_or_b64 exec, exec, s[64:65]

	v_rcp_f32_e32 v26, v24
	s_nop 1
	v_fma_f32 v27, -v24, v26, 1.0
	s_nop 1
	v_fma_f32 v26, v27, v26, v26
	s_nop 1
	v_mul_f32_e32 v20, v26, v20
	v_mul_f32_e32 v21, v26, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v26, v23
	v_cvt_pk_fp8_f32 v28, v20, v21
	v_cvt_pk_fp8_f32 v29, v22, v23
	v_perm_b32 v28, v29, v28, s53
	v_lshlrev_b32_e32 v26, 9, v18
	v_lshrrev_b32_e32 v27, 6, v0
	v_lshlrev_b32_e32 v27, 7, v27
	v_add_u32_e32 v26, v27, v26
	v_lshlrev_b32_e32 v27, 2, v1
	v_add_u32_e32 v26, v27, v26
	s_and_saveexec_b64 s[64:65], s[60:61]
	global_store_dword v26, v28, s[18:19]
	s_or_b64 exec, exec, s[64:65]

	s_add_u32 s50, s50, 1
	s_cmp_lt_u32 s50, 32
	s_cbranch_scc1 .Lquant_loop
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950
		.amdhsa_group_segment_fixed_size 65536
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 448
		.amdhsa_accum_offset 192
		.amdhsa_next_free_sgpr 66
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950, .Lfunc_end0-qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w13_fp8, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: compact_sorted_expert_ids_i32, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: route_activation_fp8, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: route_scale_f32, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: rows, .offset: 72, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 68
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_gateup_silu_quant_m64_waven_highreg_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 448
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
