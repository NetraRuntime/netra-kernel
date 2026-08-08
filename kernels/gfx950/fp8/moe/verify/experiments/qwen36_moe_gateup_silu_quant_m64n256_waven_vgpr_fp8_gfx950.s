// SPDX-License-Identifier: MIT
//
// Qwen3.6 FP8 E4M3 wave-N N256 W13+SiLU+quantization experiment for gfx950.
//
// Two four-wave64 workgroups consume one expert-sorted M64 block. Each wave
// owns N64 and retains all four M16 row tiles for both gate and up in
// v64:v191. One workgroup covers N256; two workgroups cover the checkpoint's
// N512 intermediate dimension without duplicating weight traffic. Native
// v192:v255 hold transient MFMA results while native packed-FP32 FMA updates
// the v64:v191 accumulation. AGPRs retain scales and LDS weight operands.
//
// Grid: (2, num_valid_ids/64, 1), workgroup: 256, LDS: 32 KiB.
// This is an isolated W13 milestone; it is not a production serving kernel.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950
	.globl qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950
	.p2align 8
	.type qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950,@function
qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950:
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

	s_lshl_b32 s23, s3, 6
	s_load_dword s24, s[16:17], 0
	s_lshl_b32 s25, s3, 2
	s_load_dword s25, s[14:15], s25
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s23, s24
	s_cbranch_scc0 .Lend

	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0

	// Four native A rows and sixteen result rows.
	.macro LOAD_A_ID dst,rowoff
	v_add_u32_e32 v62, s23, v1
	v_add_u32_e32 v62, \rowoff, v62
	v_lshlrev_b32_e32 v62, 2, v62
	global_load_dword v\dst, v62, s[12:13]
	.endm
	LOAD_A_ID 56,0
	LOAD_A_ID 57,16
	LOAD_A_ID 58,32
	LOAD_A_ID 59,48
	v_lshrrev_b32_e32 v63, 2, v2
	.macro LOAD_RESULT_IDS dst0,dst3,rowoff
	v_add_u32_e32 v62, s23, v63
	v_add_u32_e32 v62, \rowoff, v62
	v_lshlrev_b32_e32 v62, 2, v62
	global_load_dwordx4 v[\dst0:\dst3], v62, s[12:13]
	.endm
	LOAD_RESULT_IDS 40,43,0
	LOAD_RESULT_IDS 44,47,16
	LOAD_RESULT_IDS 48,51,32
	LOAD_RESULT_IDS 52,55,48
	s_waitcnt vmcnt(0)

	.macro DECODE_TOKEN reg
	v_lshrrev_b32_e32 v62, 24, v\reg
	v_and_b32_e32 v\reg, 0x00ffffff, v\reg
	v_cmp_gt_u32_e32 vcc, s22, v\reg
	v_cndmask_b32_e32 v\reg, 0, v\reg, vcc
	v_cmp_gt_u32_e32 vcc, 9, v62
	v_cndmask_b32_e32 v\reg, 0, v\reg, vcc
	.endm
	.irp r,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59
	DECODE_TOKEN \r
	.endr
	v_lshlrev_b32_e32 v56, 11, v56
	v_lshlrev_b32_e32 v57, 11, v57
	v_lshlrev_b32_e32 v58, 11, v58
	v_lshlrev_b32_e32 v59, 11, v59
	v_add_u32_e32 v56, v2, v56
	v_add_u32_e32 v57, v2, v57
	v_add_u32_e32 v58, v2, v58
	v_add_u32_e32 v59, v2, v59

	// Expert bases.
	s_lshl_b32 s26, s25, 21
	s_add_u32 s30, s8, s26
	s_addc_u32 s31, s9, 0
	s_add_u32 s34, s30, 1048576
	s_addc_u32 s35, s31, 0
	s_lshl_b32 s26, s25, 9
	s_add_u32 s32, s10, s26
	s_addc_u32 s33, s11, 0

	// 128 FP32 accumulators: four M16 rows x N64 x gate/up.
	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191
	v_mov_b32_e32 v\r, 0
	.endr
	s_mov_b32 s27, 0
.Lk_loop:
	// A fragments for four retained M16 row tiles.
	s_lshl_b32 s28, s27, 7
	v_add_u32_e32 v62, s28, v56
	global_load_dwordx4 v[8:11], v62, s[4:5]
	global_load_dwordx4 v[12:15], v62, s[4:5] offset:64
	v_add_u32_e32 v62, s28, v57
	global_load_dwordx4 v[16:19], v62, s[4:5]
	global_load_dwordx4 v[20:23], v62, s[4:5] offset:64
	v_add_u32_e32 v62, s28, v58
	global_load_dwordx4 v[24:27], v62, s[4:5]
	global_load_dwordx4 v[28:31], v62, s[4:5] offset:64
	v_add_u32_e32 v62, s28, v59
	global_load_dwordx4 v[32:35], v62, s[4:5]
	global_load_dwordx4 v[36:39], v62, s[4:5] offset:64

	// Sixteen per-row A scales are held in AGPRs a64:a79.
	s_lshl_b32 s29, s27, 2
	.macro LOAD_A_SCALE dst,token
	v_lshlrev_b32_e32 v62, 6, v\token
	v_add_u32_e32 v62, s29, v62
	global_load_dword a\dst, v62, s[6:7]
	.endm
	LOAD_A_SCALE 64,40
	LOAD_A_SCALE 65,41
	LOAD_A_SCALE 66,42
	LOAD_A_SCALE 67,43
	LOAD_A_SCALE 68,44
	LOAD_A_SCALE 69,45
	LOAD_A_SCALE 70,46
	LOAD_A_SCALE 71,47
	LOAD_A_SCALE 72,48
	LOAD_A_SCALE 73,49
	LOAD_A_SCALE 74,50
	LOAD_A_SCALE 75,51
	LOAD_A_SCALE 76,52
	LOAD_A_SCALE 77,53
	LOAD_A_SCALE 78,54
	LOAD_A_SCALE 79,55

	// W scale group is shared by each adjacent N64 wave pair.
	v_lshrrev_b32_e32 v62, 1, v3
	s_lshl_b32 s28, s2, 1
	v_add_u32_e32 v62, s28, v62
	v_lshlrev_b32_e32 v62, 6, v62
	v_add_u32_e32 v62, s29, v62
	global_load_dword v60, v62, s[32:33]
	global_load_dword v61, v62, s[32:33] offset:256

	// Global N64 group = workgroup_x*4 + wave. Each wave stages 8 KiB.
	v_mov_b32_e32 v62, s2
	v_lshlrev_b32_e32 v62, 2, v62
	v_add_u32_e32 v62, v3, v62
	v_lshlrev_b32_e32 v62, 17, v62
	s_lshl_b32 s28, s27, 11
	v_add_u32_e32 v62, s28, v62
	v_and_b32_e32 v63, 63, v0
	v_lshlrev_b32_e32 v63, 3, v63
	v_add_u32_e32 v62, v63, v62
	v_mov_b32_e32 v4, v62
	v_add_u32_e32 v5, 32768, v62
	v_add_u32_e32 v6, 65536, v62
	v_add_u32_e32 v7, 98304, v62
	global_load_dwordx2 v[192:193], v4, s[30:31] offset:0
	global_load_dwordx2 v[194:195], v4, s[30:31] offset:512
	global_load_dwordx2 v[196:197], v4, s[30:31] offset:1024
	global_load_dwordx2 v[198:199], v4, s[30:31] offset:1536
	global_load_dwordx2 v[200:201], v5, s[30:31] offset:0
	global_load_dwordx2 v[202:203], v5, s[30:31] offset:512
	global_load_dwordx2 v[204:205], v5, s[30:31] offset:1024
	global_load_dwordx2 v[206:207], v5, s[30:31] offset:1536
	global_load_dwordx2 v[208:209], v6, s[30:31] offset:0
	global_load_dwordx2 v[210:211], v6, s[30:31] offset:512
	global_load_dwordx2 v[212:213], v6, s[30:31] offset:1024
	global_load_dwordx2 v[214:215], v6, s[30:31] offset:1536
	global_load_dwordx2 v[216:217], v7, s[30:31] offset:0
	global_load_dwordx2 v[218:219], v7, s[30:31] offset:512
	global_load_dwordx2 v[220:221], v7, s[30:31] offset:1024
	global_load_dwordx2 v[222:223], v7, s[30:31] offset:1536

	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v62, 13, v3
	v_and_b32_e32 v63, 63, v0
	v_lshlrev_b32_e32 v63, 3, v63
	v_add_u32_e32 v62, v63, v62
	ds_write_b64 v62, v[192:193] offset:0
	ds_write_b64 v62, v[194:195] offset:512
	ds_write_b64 v62, v[196:197] offset:1024
	ds_write_b64 v62, v[198:199] offset:1536
	ds_write_b64 v62, v[200:201] offset:2048
	ds_write_b64 v62, v[202:203] offset:2560
	ds_write_b64 v62, v[204:205] offset:3072
	ds_write_b64 v62, v[206:207] offset:3584
	ds_write_b64 v62, v[208:209] offset:4096
	ds_write_b64 v62, v[210:211] offset:4608
	ds_write_b64 v62, v[212:213] offset:5120
	ds_write_b64 v62, v[214:215] offset:5632
	ds_write_b64 v62, v[216:217] offset:6144
	ds_write_b64 v62, v[218:219] offset:6656
	ds_write_b64 v62, v[220:221] offset:7168
	ds_write_b64 v62, v[222:223] offset:7680

	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v63, 13, v3
	v_lshlrev_b32_e32 v4, 4, v2
	v_lshlrev_b32_e32 v5, 4, v1
	v_add_u32_e32 v4, v5, v4
	v_add_u32_e32 v63, v4, v63
	ds_read_b128 a[128:131], v63 offset:0
	ds_read_b128 a[132:135], v63 offset:1024
	ds_read_b128 a[136:139], v63 offset:2048
	ds_read_b128 a[140:143], v63 offset:3072
	ds_read_b128 a[144:147], v63 offset:4096
	ds_read_b128 a[148:151], v63 offset:5120
	ds_read_b128 a[152:155], v63 offset:6144
	ds_read_b128 a[156:159], v63 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[192:195], v[8:15], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[196:199], v[8:15], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[200:203], v[8:15], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], v[8:15], a[152:159], 0
	v_mfma_f32_16x16x128_f8f6f4 v[208:211], v[16:23], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[212:215], v[16:23], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[216:219], v[16:23], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[220:223], v[16:23], a[152:159], 0
	v_mfma_f32_16x16x128_f8f6f4 v[224:227], v[24:31], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[228:231], v[24:31], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[232:235], v[24:31], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[236:239], v[24:31], a[152:159], 0
	v_mfma_f32_16x16x128_f8f6f4 v[240:243], v[32:39], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[244:247], v[32:39], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[248:251], v[32:39], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[252:255], v[32:39], a[152:159], 0
	s_nop 12
	v_accvgpr_read_b32 v4, a64
	v_accvgpr_read_b32 v5, a65
	v_accvgpr_read_b32 v6, a66
	v_accvgpr_read_b32 v7, a67
	v_mul_f32_e32 v4, v60, v4
	v_mul_f32_e32 v5, v60, v5
	v_mul_f32_e32 v6, v60, v6
	v_mul_f32_e32 v7, v60, v7
	v_pk_fma_f32 v[64:65], v[192:193], v[4:5], v[64:65]
	v_pk_fma_f32 v[66:67], v[194:195], v[6:7], v[66:67]
	v_pk_fma_f32 v[68:69], v[196:197], v[4:5], v[68:69]
	v_pk_fma_f32 v[70:71], v[198:199], v[6:7], v[70:71]
	v_pk_fma_f32 v[72:73], v[200:201], v[4:5], v[72:73]
	v_pk_fma_f32 v[74:75], v[202:203], v[6:7], v[74:75]
	v_pk_fma_f32 v[76:77], v[204:205], v[4:5], v[76:77]
	v_pk_fma_f32 v[78:79], v[206:207], v[6:7], v[78:79]
	v_accvgpr_read_b32 v4, a68
	v_accvgpr_read_b32 v5, a69
	v_accvgpr_read_b32 v6, a70
	v_accvgpr_read_b32 v7, a71
	v_mul_f32_e32 v4, v60, v4
	v_mul_f32_e32 v5, v60, v5
	v_mul_f32_e32 v6, v60, v6
	v_mul_f32_e32 v7, v60, v7
	v_pk_fma_f32 v[96:97], v[208:209], v[4:5], v[96:97]
	v_pk_fma_f32 v[98:99], v[210:211], v[6:7], v[98:99]
	v_pk_fma_f32 v[100:101], v[212:213], v[4:5], v[100:101]
	v_pk_fma_f32 v[102:103], v[214:215], v[6:7], v[102:103]
	v_pk_fma_f32 v[104:105], v[216:217], v[4:5], v[104:105]
	v_pk_fma_f32 v[106:107], v[218:219], v[6:7], v[106:107]
	v_pk_fma_f32 v[108:109], v[220:221], v[4:5], v[108:109]
	v_pk_fma_f32 v[110:111], v[222:223], v[6:7], v[110:111]
	v_accvgpr_read_b32 v4, a72
	v_accvgpr_read_b32 v5, a73
	v_accvgpr_read_b32 v6, a74
	v_accvgpr_read_b32 v7, a75
	v_mul_f32_e32 v4, v60, v4
	v_mul_f32_e32 v5, v60, v5
	v_mul_f32_e32 v6, v60, v6
	v_mul_f32_e32 v7, v60, v7
	v_pk_fma_f32 v[128:129], v[224:225], v[4:5], v[128:129]
	v_pk_fma_f32 v[130:131], v[226:227], v[6:7], v[130:131]
	v_pk_fma_f32 v[132:133], v[228:229], v[4:5], v[132:133]
	v_pk_fma_f32 v[134:135], v[230:231], v[6:7], v[134:135]
	v_pk_fma_f32 v[136:137], v[232:233], v[4:5], v[136:137]
	v_pk_fma_f32 v[138:139], v[234:235], v[6:7], v[138:139]
	v_pk_fma_f32 v[140:141], v[236:237], v[4:5], v[140:141]
	v_pk_fma_f32 v[142:143], v[238:239], v[6:7], v[142:143]
	v_accvgpr_read_b32 v4, a76
	v_accvgpr_read_b32 v5, a77
	v_accvgpr_read_b32 v6, a78
	v_accvgpr_read_b32 v7, a79
	v_mul_f32_e32 v4, v60, v4
	v_mul_f32_e32 v5, v60, v5
	v_mul_f32_e32 v6, v60, v6
	v_mul_f32_e32 v7, v60, v7
	v_pk_fma_f32 v[160:161], v[240:241], v[4:5], v[160:161]
	v_pk_fma_f32 v[162:163], v[242:243], v[6:7], v[162:163]
	v_pk_fma_f32 v[164:165], v[244:245], v[4:5], v[164:165]
	v_pk_fma_f32 v[166:167], v[246:247], v[6:7], v[166:167]
	v_pk_fma_f32 v[168:169], v[248:249], v[4:5], v[168:169]
	v_pk_fma_f32 v[170:171], v[250:251], v[6:7], v[170:171]
	v_pk_fma_f32 v[172:173], v[252:253], v[4:5], v[172:173]
	v_pk_fma_f32 v[174:175], v[254:255], v[6:7], v[174:175]

	s_barrier

	// Up reuses the same LDS coordinates.
	v_mov_b32_e32 v62, s2
	v_lshlrev_b32_e32 v62, 2, v62
	v_add_u32_e32 v62, v3, v62
	v_lshlrev_b32_e32 v62, 17, v62
	s_lshl_b32 s28, s27, 11
	v_add_u32_e32 v62, s28, v62
	v_and_b32_e32 v63, 63, v0
	v_lshlrev_b32_e32 v63, 3, v63
	v_add_u32_e32 v62, v63, v62
	v_mov_b32_e32 v4, v62
	v_add_u32_e32 v5, 32768, v62
	v_add_u32_e32 v6, 65536, v62
	v_add_u32_e32 v7, 98304, v62
	global_load_dwordx2 v[192:193], v4, s[34:35] offset:0
	global_load_dwordx2 v[194:195], v4, s[34:35] offset:512
	global_load_dwordx2 v[196:197], v4, s[34:35] offset:1024
	global_load_dwordx2 v[198:199], v4, s[34:35] offset:1536
	global_load_dwordx2 v[200:201], v5, s[34:35] offset:0
	global_load_dwordx2 v[202:203], v5, s[34:35] offset:512
	global_load_dwordx2 v[204:205], v5, s[34:35] offset:1024
	global_load_dwordx2 v[206:207], v5, s[34:35] offset:1536
	global_load_dwordx2 v[208:209], v6, s[34:35] offset:0
	global_load_dwordx2 v[210:211], v6, s[34:35] offset:512
	global_load_dwordx2 v[212:213], v6, s[34:35] offset:1024
	global_load_dwordx2 v[214:215], v6, s[34:35] offset:1536
	global_load_dwordx2 v[216:217], v7, s[34:35] offset:0
	global_load_dwordx2 v[218:219], v7, s[34:35] offset:512
	global_load_dwordx2 v[220:221], v7, s[34:35] offset:1024
	global_load_dwordx2 v[222:223], v7, s[34:35] offset:1536

	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v62, 13, v3
	v_and_b32_e32 v63, 63, v0
	v_lshlrev_b32_e32 v63, 3, v63
	v_add_u32_e32 v62, v63, v62
	ds_write_b64 v62, v[192:193] offset:0
	ds_write_b64 v62, v[194:195] offset:512
	ds_write_b64 v62, v[196:197] offset:1024
	ds_write_b64 v62, v[198:199] offset:1536
	ds_write_b64 v62, v[200:201] offset:2048
	ds_write_b64 v62, v[202:203] offset:2560
	ds_write_b64 v62, v[204:205] offset:3072
	ds_write_b64 v62, v[206:207] offset:3584
	ds_write_b64 v62, v[208:209] offset:4096
	ds_write_b64 v62, v[210:211] offset:4608
	ds_write_b64 v62, v[212:213] offset:5120
	ds_write_b64 v62, v[214:215] offset:5632
	ds_write_b64 v62, v[216:217] offset:6144
	ds_write_b64 v62, v[218:219] offset:6656
	ds_write_b64 v62, v[220:221] offset:7168
	ds_write_b64 v62, v[222:223] offset:7680

	s_waitcnt lgkmcnt(0)
	s_barrier
	// Cooperative stores use lane*8; MFMA consumes the native lane*16
	// coordinate within this wave's 8 KiB N64 slab.
	v_lshlrev_b32_e32 v63, 13, v3
	v_lshlrev_b32_e32 v4, 4, v2
	v_lshlrev_b32_e32 v5, 4, v1
	v_add_u32_e32 v4, v5, v4
	v_add_u32_e32 v63, v4, v63
	ds_read_b128 a[128:131], v63 offset:0
	ds_read_b128 a[132:135], v63 offset:1024
	ds_read_b128 a[136:139], v63 offset:2048
	ds_read_b128 a[140:143], v63 offset:3072
	ds_read_b128 a[144:147], v63 offset:4096
	ds_read_b128 a[148:151], v63 offset:5120
	ds_read_b128 a[152:155], v63 offset:6144
	ds_read_b128 a[156:159], v63 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[192:195], v[8:15], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[196:199], v[8:15], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[200:203], v[8:15], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], v[8:15], a[152:159], 0
	v_mfma_f32_16x16x128_f8f6f4 v[208:211], v[16:23], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[212:215], v[16:23], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[216:219], v[16:23], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[220:223], v[16:23], a[152:159], 0
	v_mfma_f32_16x16x128_f8f6f4 v[224:227], v[24:31], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[228:231], v[24:31], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[232:235], v[24:31], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[236:239], v[24:31], a[152:159], 0
	v_mfma_f32_16x16x128_f8f6f4 v[240:243], v[32:39], a[128:135], 0
	v_mfma_f32_16x16x128_f8f6f4 v[244:247], v[32:39], a[136:143], 0
	v_mfma_f32_16x16x128_f8f6f4 v[248:251], v[32:39], a[144:151], 0
	v_mfma_f32_16x16x128_f8f6f4 v[252:255], v[32:39], a[152:159], 0
	s_nop 12
	v_accvgpr_read_b32 v4, a64
	v_accvgpr_read_b32 v5, a65
	v_accvgpr_read_b32 v6, a66
	v_accvgpr_read_b32 v7, a67
	v_mul_f32_e32 v4, v61, v4
	v_mul_f32_e32 v5, v61, v5
	v_mul_f32_e32 v6, v61, v6
	v_mul_f32_e32 v7, v61, v7
	v_pk_fma_f32 v[80:81], v[192:193], v[4:5], v[80:81]
	v_pk_fma_f32 v[82:83], v[194:195], v[6:7], v[82:83]
	v_pk_fma_f32 v[84:85], v[196:197], v[4:5], v[84:85]
	v_pk_fma_f32 v[86:87], v[198:199], v[6:7], v[86:87]
	v_pk_fma_f32 v[88:89], v[200:201], v[4:5], v[88:89]
	v_pk_fma_f32 v[90:91], v[202:203], v[6:7], v[90:91]
	v_pk_fma_f32 v[92:93], v[204:205], v[4:5], v[92:93]
	v_pk_fma_f32 v[94:95], v[206:207], v[6:7], v[94:95]
	v_accvgpr_read_b32 v4, a68
	v_accvgpr_read_b32 v5, a69
	v_accvgpr_read_b32 v6, a70
	v_accvgpr_read_b32 v7, a71
	v_mul_f32_e32 v4, v61, v4
	v_mul_f32_e32 v5, v61, v5
	v_mul_f32_e32 v6, v61, v6
	v_mul_f32_e32 v7, v61, v7
	v_pk_fma_f32 v[112:113], v[208:209], v[4:5], v[112:113]
	v_pk_fma_f32 v[114:115], v[210:211], v[6:7], v[114:115]
	v_pk_fma_f32 v[116:117], v[212:213], v[4:5], v[116:117]
	v_pk_fma_f32 v[118:119], v[214:215], v[6:7], v[118:119]
	v_pk_fma_f32 v[120:121], v[216:217], v[4:5], v[120:121]
	v_pk_fma_f32 v[122:123], v[218:219], v[6:7], v[122:123]
	v_pk_fma_f32 v[124:125], v[220:221], v[4:5], v[124:125]
	v_pk_fma_f32 v[126:127], v[222:223], v[6:7], v[126:127]
	v_accvgpr_read_b32 v4, a72
	v_accvgpr_read_b32 v5, a73
	v_accvgpr_read_b32 v6, a74
	v_accvgpr_read_b32 v7, a75
	v_mul_f32_e32 v4, v61, v4
	v_mul_f32_e32 v5, v61, v5
	v_mul_f32_e32 v6, v61, v6
	v_mul_f32_e32 v7, v61, v7
	v_pk_fma_f32 v[144:145], v[224:225], v[4:5], v[144:145]
	v_pk_fma_f32 v[146:147], v[226:227], v[6:7], v[146:147]
	v_pk_fma_f32 v[148:149], v[228:229], v[4:5], v[148:149]
	v_pk_fma_f32 v[150:151], v[230:231], v[6:7], v[150:151]
	v_pk_fma_f32 v[152:153], v[232:233], v[4:5], v[152:153]
	v_pk_fma_f32 v[154:155], v[234:235], v[6:7], v[154:155]
	v_pk_fma_f32 v[156:157], v[236:237], v[4:5], v[156:157]
	v_pk_fma_f32 v[158:159], v[238:239], v[6:7], v[158:159]
	v_accvgpr_read_b32 v4, a76
	v_accvgpr_read_b32 v5, a77
	v_accvgpr_read_b32 v6, a78
	v_accvgpr_read_b32 v7, a79
	v_mul_f32_e32 v4, v61, v4
	v_mul_f32_e32 v5, v61, v5
	v_mul_f32_e32 v6, v61, v6
	v_mul_f32_e32 v7, v61, v7
	v_pk_fma_f32 v[176:177], v[240:241], v[4:5], v[176:177]
	v_pk_fma_f32 v[178:179], v[242:243], v[6:7], v[178:179]
	v_pk_fma_f32 v[180:181], v[244:245], v[4:5], v[180:181]
	v_pk_fma_f32 v[182:183], v[246:247], v[6:7], v[182:183]
	v_pk_fma_f32 v[184:185], v[248:249], v[4:5], v[184:185]
	v_pk_fma_f32 v[186:187], v[250:251], v[6:7], v[186:187]
	v_pk_fma_f32 v[188:189], v[252:253], v[4:5], v[188:189]
	v_pk_fma_f32 v[190:191], v[254:255], v[6:7], v[190:191]

	s_barrier
	s_add_u32 s27, s27, 1
	s_cmp_lt_u32 s27, 16
	s_cbranch_scc1 .Lk_loop

	// BF16 gate/up and activation boundaries into M64xN256 LDS.
	s_mov_b32 s48, 0xbfb8aa3b
	s_mov_b32 s49, 0x3f800000
	.macro ACT_STORE g0,g1,g2,g3,u0,u1,u2,u3,ldsoff
	v_cvt_pk_bf16_f32 v192, v\g0, v\g1
	v_cvt_pk_bf16_f32 v193, v\g2, v\g3
	v_cvt_pk_bf16_f32 v194, v\u0, v\u1
	v_cvt_pk_bf16_f32 v195, v\u2, v\u3
	v_lshlrev_b32_e32 v196, 16, v192
	v_and_b32_e32 v197, 0xffff0000, v192
	v_lshlrev_b32_e32 v198, 16, v193
	v_and_b32_e32 v199, 0xffff0000, v193
	v_lshlrev_b32_e32 v200, 16, v194
	v_and_b32_e32 v201, 0xffff0000, v194
	v_lshlrev_b32_e32 v202, 16, v195
	v_and_b32_e32 v203, 0xffff0000, v195
	v_mul_f32_e32 v204, s48, v196
	v_mul_f32_e32 v205, s48, v197
	v_mul_f32_e32 v206, s48, v198
	v_mul_f32_e32 v207, s48, v199
	v_exp_f32_e32 v204, v204
	v_exp_f32_e32 v205, v205
	v_exp_f32_e32 v206, v206
	v_exp_f32_e32 v207, v207
	v_add_f32_e32 v204, s49, v204
	v_add_f32_e32 v205, s49, v205
	v_add_f32_e32 v206, s49, v206
	v_add_f32_e32 v207, s49, v207
	v_rcp_f32_e32 v204, v204
	v_rcp_f32_e32 v205, v205
	v_rcp_f32_e32 v206, v206
	v_rcp_f32_e32 v207, v207
	v_mul_f32_e32 v196, v204, v196
	v_mul_f32_e32 v197, v205, v197
	v_mul_f32_e32 v198, v206, v198
	v_mul_f32_e32 v199, v207, v199
	v_mul_f32_e32 v196, v200, v196
	v_mul_f32_e32 v197, v201, v197
	v_mul_f32_e32 v198, v202, v198
	v_mul_f32_e32 v199, v203, v199
	v_cvt_pk_bf16_f32 v192, v196, v197
	v_cvt_pk_bf16_f32 v193, v198, v199
	v_add_u32_e32 v194, \ldsoff, v56
	ds_write_b64 v194, v[192:193]
	.endm
	// Retained M16 row tile 0.
	v_lshlrev_b32_e32 v56, 13, v3
	v_and_b32_e32 v57, 63, v0
	v_lshlrev_b32_e32 v57, 5, v57
	v_add_u32_e32 v56, v57, v56
	ACT_STORE 64,65,66,67,80,81,82,83,0
	ACT_STORE 68,69,70,71,84,85,86,87,8
	ACT_STORE 72,73,74,75,88,89,90,91,16
	ACT_STORE 76,77,78,79,92,93,94,95,24
	// Retained M16 row tile 1.
	v_lshlrev_b32_e32 v56, 13, v3
	v_and_b32_e32 v57, 63, v0
	v_lshlrev_b32_e32 v57, 5, v57
	v_add_u32_e32 v56, v57, v56
	v_add_u32_e32 v56, 2048, v56
	ACT_STORE 96,97,98,99,112,113,114,115,0
	ACT_STORE 100,101,102,103,116,117,118,119,8
	ACT_STORE 104,105,106,107,120,121,122,123,16
	ACT_STORE 108,109,110,111,124,125,126,127,24
	// Retained M16 row tile 2.
	v_lshlrev_b32_e32 v56, 13, v3
	v_and_b32_e32 v57, 63, v0
	v_lshlrev_b32_e32 v57, 5, v57
	v_add_u32_e32 v56, v57, v56
	v_add_u32_e32 v56, 4096, v56
	ACT_STORE 128,129,130,131,144,145,146,147,0
	ACT_STORE 132,133,134,135,148,149,150,151,8
	ACT_STORE 136,137,138,139,152,153,154,155,16
	ACT_STORE 140,141,142,143,156,157,158,159,24
	// Retained M16 row tile 3.
	v_lshlrev_b32_e32 v56, 13, v3
	v_and_b32_e32 v57, 63, v0
	v_lshlrev_b32_e32 v57, 5, v57
	v_add_u32_e32 v56, v57, v56
	v_add_u32_e32 v56, 6144, v56
	ACT_STORE 160,161,162,163,176,177,178,179,0
	ACT_STORE 164,165,166,167,180,181,182,183,8
	ACT_STORE 168,169,170,171,184,185,186,187,16
	ACT_STORE 172,173,174,175,188,189,190,191,24

	s_waitcnt lgkmcnt(0)
	s_barrier
	// Adjacent wave pairs jointly quantize one N128 checkpoint block.
	v_and_b32_e32 v1, 31, v0
	v_and_b32_e32 v25, 127, v0
	v_lshrrev_b32_e32 v2, 5, v25
	v_lshrrev_b32_e32 v3, 7, v0
	s_mov_b32 s50, 0
	s_mov_b32 s51, 0x3b124925
	s_mov_b32 s52, 0x2edbe6ff
	s_mov_b32 s53, 0x05040100
.Lquant_loop:
	s_lshl_b32 s54, s50, 2
	v_add_u32_e32 v3, s54, v2
	v_add_u32_e32 v4, s23, v3
	v_lshlrev_b32_e32 v4, 2, v4
	global_load_dword v5, v4, s[12:13]

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
	v_mov_b32_e32 v10, 0
	v_cndmask_b32_e32 v9, v9, v10, vcc
	v_add_u32_e32 v6, v9, v6
	v_lshrrev_b32_e32 v10, 7, v0
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
	v_lshrrev_b32_e32 v27, 7, v0
	s_lshl_b32 s55, s2, 1
	v_add_u32_e32 v27, s55, v27
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
	v_lshrrev_b32_e32 v27, 7, v0
	s_lshl_b32 s55, s2, 1
	v_add_u32_e32 v27, s55, v27
	v_lshlrev_b32_e32 v27, 7, v27
	v_add_u32_e32 v26, v27, v26
	v_lshlrev_b32_e32 v27, 2, v1
	v_add_u32_e32 v26, v27, v26
	s_and_saveexec_b64 s[64:65], s[60:61]
	global_store_dword v26, v28, s[18:19]
	s_or_b64 exec, exec, s[64:65]

	s_add_u32 s50, s50, 1
	s_cmp_lt_u32 s50, 16
	s_cbranch_scc1 .Lquant_loop
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950
		.amdhsa_group_segment_fixed_size 32768
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 416
		.amdhsa_accum_offset 256
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
	.size qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950, .Lfunc_end0-qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950

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
    .group_segment_fixed_size: 32768
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 68
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_gateup_silu_quant_m64n256_waven_vgpr_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 416
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
