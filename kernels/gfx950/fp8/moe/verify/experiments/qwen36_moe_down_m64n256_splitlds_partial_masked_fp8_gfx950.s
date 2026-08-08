// SPDX-License-Identifier: MIT
//
// Qwen3.6 expert-sorted W2 projection for gfx950.
// Four wave64s compute M64xN256 as four sequential N64 quarters, cooperatively
// reuse route activations/scales across four 8 KiB W2 K slabs,
// write deterministic FP32 route partials for the fixed-order raw reducer.
// Padded M64 rows are suppressed at the VMEM boundary instead of writing the
// large ignored sink workspace.
// Four validity masks are built once and reused across all N16 stores; router
// weights remain in the fixed-order reducer and are not loaded here.
// Two 16 KiB LDS stages alternate N128 halves. This adds one barrier per K128
// group but restores two workgroups/CU by using only 32 KiB LDS.
// Grid: (8 N256 tiles, num_valid_ids/64, 1), workgroup: 256, LDS: 32 KiB.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950
	.globl qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950
	.p2align 8
	.type qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950,@function
qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950:
	// route FP8/scales, shuffled W2/scales, sorted IDs, experts,
	// valid count, FP32 route-partial workspace, rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dwordx2 s[20:21], s[0:1], 64
	s_load_dword s22, s[0:1], 72
	s_waitcnt lgkmcnt(0)

	// Exact M64 block bounds and compact expert.
	s_lshl_b32 s23, s3, 6
	s_load_dword s24, s[18:19], 0
	s_lshl_b32 s25, s3, 2
	s_load_dword s25, s[16:17], s25
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s23, s24
	s_cbranch_scc0 .Lend

	// Vector-native wave/lane coordinates and M16 sub-block base.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s23, v5

	// Native A route for lane[3:0].
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[12:13]

	// Four result sorted rows and packed IDs for lane[5:4].
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v104, v5, v3
	v_lshlrev_b32_e32 v3, 2, v104
	global_load_dword v84, v3, s[12:13]
	global_load_dword v85, v3, s[12:13] offset:4
	global_load_dword v86, v3, s[12:13] offset:8
	global_load_dword v87, v3, s[12:13] offset:12
	s_waitcnt vmcnt(0)

	// Decode selected A route to token*9+slot; padding reads route zero.
	v_lshrrev_b32_e32 v6, 24, v4
	v_and_b32_e32 v7, 0x00ffffff, v4
	v_mul_lo_u32 v4, 9, v7
	v_add_u32_e32 v4, v6, v4
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, s22, v7
	v_cndmask_b32_e32 v4, 0, v4, vcc

	// Decode four result token rows and route indices.
	.macro DECODE_RESULT packed, route
	v_lshrrev_b32_e32 v6, 24, v\packed
	v_and_b32_e32 v7, 0x00ffffff, v\packed
	v_mul_lo_u32 v\route, 9, v7
	v_add_u32_e32 v\route, v6, v\route
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v\route, 0, v\route, vcc
	v_cmp_gt_u32_e32 vcc, s22, v7
	v_cndmask_b32_e32 v\route, 0, v\route, vcc
	.endm
	DECODE_RESULT 84,92
	DECODE_RESULT 85,93
	DECODE_RESULT 86,94
	DECODE_RESULT 87,95

	// Compact expert W2 [E,2048,512] and scales [E,16,4].
	s_lshl_b32 s26, s25, 20
	s_add_u32 s32, s8, s26
	s_addc_u32 s33, s9, 0
	s_lshl_b32 s26, s25, 8
	s_add_u32 s34, s10, s26
	s_addc_u32 s35, s11, 0
	// Four N16 tiles in this N64 group; W2 tile stride is 8 KiB.
	s_lshl_b32 s26, s2, 17
	s_add_u32 s32, s32, s26
	s_addc_u32 s33, s33, 0
	s_add_u32 s40, s32, 8192
	s_addc_u32 s41, s33, 0
	s_add_u32 s42, s32, 16384
	s_addc_u32 s43, s33, 0
	s_add_u32 s44, s32, 24576
	s_addc_u32 s45, s33, 0

	// Route activation and LDS addresses.
	v_lshlrev_b32_e32 v98, 9, v4
	v_add_u32_e32 v98, v2, v98
	v_lshlrev_b32_e32 v97, 4, v2
	v_lshlrev_b32_e32 v96, 4, v1
	v_add_u32_e32 v97, v97, v96
	v_lshlrev_b32_e32 v96, 3, v0

	// Two W2 scales cover this N256 group; output starts at x*256.
	s_lshl_b32 s27, s2, 5
	s_lshl_b32 s28, s2, 8

	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	v_mov_b32_e32 v\r, 0
	.endr
	.irp r,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139
	v_mov_b32_e32 v\r, 0
	.endr
	.irp r,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171
	v_mov_b32_e32 v\r, 0
	.endr
	s_mov_b32 s29, 0

.Lk_loop:
	// Lower and upper 16 KiB stages hold one N128 half each. Writes to the
	// next stage never overlap the preceding stage's outstanding reads.
	v_mov_b32_e32 v102, v96
	v_mov_b32_e32 v103, v97
	// Cooperative first-half load: eight 2 KiB N16xK128 tiles.
	s_lshl_b32 s30, s29, 11
	v_add_u32_e32 v99, s30, v96
	global_load_dwordx2 v[16:17], v99, s[32:33]
	global_load_dwordx2 v[18:19], v99, s[40:41]
	global_load_dwordx2 v[20:21], v99, s[42:43]
	global_load_dwordx2 v[22:23], v99, s[44:45]
	v_add_u32_e32 v101, 32768, v99
	global_load_dwordx2 v[24:25], v101, s[32:33]
	global_load_dwordx2 v[26:27], v101, s[40:41]
	global_load_dwordx2 v[28:29], v101, s[42:43]
	global_load_dwordx2 v[30:31], v101, s[44:45]

	// Per-wave route activation fragment.
	s_lshl_b32 s31, s29, 7
	v_add_u32_e32 v100, s31, v98
	global_load_dwordx4 v[8:11], v100, s[4:5]
	global_load_dwordx4 v[12:15], v100, s[4:5] offset:64

	// Four route activation scales and shared W2 scale.
	s_lshl_b32 s36, s29, 2
	v_lshlrev_b32_e32 v100, 4, v92
	v_add_u32_e32 v100, s36, v100
	global_load_dword v108, v100, s[6:7]
	v_lshlrev_b32_e32 v100, 4, v93
	v_add_u32_e32 v100, s36, v100
	global_load_dword v109, v100, s[6:7]
	v_lshlrev_b32_e32 v100, 4, v94
	v_add_u32_e32 v100, s36, v100
	global_load_dword v110, v100, s[6:7]
	v_lshlrev_b32_e32 v100, 4, v95
	v_add_u32_e32 v100, s36, v100
	global_load_dword v111, v100, s[6:7]
	s_add_u32 s37, s27, s36
	s_load_dword s38, s[34:35], s37
	s_add_u32 s30, s37, 16
	s_load_dword s56, s[34:35], s30

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	ds_write_b64 v102, v[16:17]
	ds_write_b64 v102, v[18:19] offset:2048
	ds_write_b64 v102, v[20:21] offset:4096
	ds_write_b64 v102, v[22:23] offset:6144
	ds_write_b64 v102, v[24:25] offset:8192
	ds_write_b64 v102, v[26:27] offset:10240
	ds_write_b64 v102, v[28:29] offset:12288
	ds_write_b64 v102, v[30:31] offset:14336
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[16:19], v103
	ds_read_b128 v[20:23], v103 offset:1024
	ds_read_b128 v[24:27], v103 offset:2048
	ds_read_b128 v[28:31], v103 offset:3072
	ds_read_b128 v[32:35], v103 offset:4096
	ds_read_b128 v[36:39], v103 offset:5120
	ds_read_b128 v[40:43], v103 offset:6144
	ds_read_b128 v[44:47], v103 offset:7168
	s_waitcnt lgkmcnt(0)

	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12

	.macro SCALE_ACC tmp, acc, scale
	v_mul_f32_e32 v\tmp, s38, v\tmp
	v_fmac_f32_e32 v\acc, v\scale, v\tmp
	.endm
	.macro SCALE_ACC_SECOND tmp, acc, scale
	v_mul_f32_e32 v\tmp, s56, v\tmp
	v_fmac_f32_e32 v\acc, v\scale, v\tmp
	.endm
	SCALE_ACC 48,64,108
	SCALE_ACC 49,65,109
	SCALE_ACC 50,66,110
	SCALE_ACC 51,67,111
	SCALE_ACC 52,68,108
	SCALE_ACC 53,69,109
	SCALE_ACC 54,70,110
	SCALE_ACC 55,71,111
	SCALE_ACC 56,72,108
	SCALE_ACC 57,73,109
	SCALE_ACC 58,74,110
	SCALE_ACC 59,75,111
	SCALE_ACC 60,76,108
	SCALE_ACC 61,77,109
	SCALE_ACC 62,78,110
	SCALE_ACC 63,79,111

	// Reuse A/scales and consume the already-resident second N64 slab.
	ds_read_b128 v[16:19], v103 offset:8192
	ds_read_b128 v[20:23], v103 offset:9216
	ds_read_b128 v[24:27], v103 offset:10240
	ds_read_b128 v[28:31], v103 offset:11264
	ds_read_b128 v[32:35], v103 offset:12288
	ds_read_b128 v[36:39], v103 offset:13312
	ds_read_b128 v[40:43], v103 offset:14336
	ds_read_b128 v[44:47], v103 offset:15360
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	SCALE_ACC 48,124,108
	SCALE_ACC 49,125,109
	SCALE_ACC 50,126,110
	SCALE_ACC 51,127,111
	SCALE_ACC 52,128,108
	SCALE_ACC 53,129,109
	SCALE_ACC 54,130,110
	SCALE_ACC 55,131,111
	SCALE_ACC 56,132,108
	SCALE_ACC 57,133,109
	SCALE_ACC 58,134,110
	SCALE_ACC 59,135,111
	SCALE_ACC 60,136,108
	SCALE_ACC 61,137,109
	SCALE_ACC 62,138,110
	SCALE_ACC 63,139,111

	// Stage the second N128 half in upper LDS while retaining A and scales.
	v_add_u32_e32 v101, 65536, v99
	global_load_dwordx2 v[16:17], v101, s[32:33]
	global_load_dwordx2 v[18:19], v101, s[40:41]
	global_load_dwordx2 v[20:21], v101, s[42:43]
	global_load_dwordx2 v[22:23], v101, s[44:45]
	v_add_u32_e32 v101, 32768, v101
	global_load_dwordx2 v[24:25], v101, s[32:33]
	global_load_dwordx2 v[26:27], v101, s[40:41]
	global_load_dwordx2 v[28:29], v101, s[42:43]
	global_load_dwordx2 v[30:31], v101, s[44:45]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v102, 16384, v96
	ds_write_b64 v102, v[16:17]
	ds_write_b64 v102, v[18:19] offset:2048
	ds_write_b64 v102, v[20:21] offset:4096
	ds_write_b64 v102, v[22:23] offset:6144
	ds_write_b64 v102, v[24:25] offset:8192
	ds_write_b64 v102, v[26:27] offset:10240
	ds_write_b64 v102, v[28:29] offset:12288
	ds_write_b64 v102, v[30:31] offset:14336
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v103, 16384, v97

	// Reuse A/scales for the third and fourth N64 quarters.
	ds_read_b128 v[16:19], v103 offset:0
	ds_read_b128 v[20:23], v103 offset:1024
	ds_read_b128 v[24:27], v103 offset:2048
	ds_read_b128 v[28:31], v103 offset:3072
	ds_read_b128 v[32:35], v103 offset:4096
	ds_read_b128 v[36:39], v103 offset:5120
	ds_read_b128 v[40:43], v103 offset:6144
	ds_read_b128 v[44:47], v103 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	SCALE_ACC_SECOND 48,140,108
	SCALE_ACC_SECOND 49,141,109
	SCALE_ACC_SECOND 50,142,110
	SCALE_ACC_SECOND 51,143,111
	SCALE_ACC_SECOND 52,144,108
	SCALE_ACC_SECOND 53,145,109
	SCALE_ACC_SECOND 54,146,110
	SCALE_ACC_SECOND 55,147,111
	SCALE_ACC_SECOND 56,148,108
	SCALE_ACC_SECOND 57,149,109
	SCALE_ACC_SECOND 58,150,110
	SCALE_ACC_SECOND 59,151,111
	SCALE_ACC_SECOND 60,152,108
	SCALE_ACC_SECOND 61,153,109
	SCALE_ACC_SECOND 62,154,110
	SCALE_ACC_SECOND 63,155,111

	ds_read_b128 v[16:19], v103 offset:8192
	ds_read_b128 v[20:23], v103 offset:9216
	ds_read_b128 v[24:27], v103 offset:10240
	ds_read_b128 v[28:31], v103 offset:11264
	ds_read_b128 v[32:35], v103 offset:12288
	ds_read_b128 v[36:39], v103 offset:13312
	ds_read_b128 v[40:43], v103 offset:14336
	ds_read_b128 v[44:47], v103 offset:15360
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	SCALE_ACC_SECOND 48,156,108
	SCALE_ACC_SECOND 49,157,109
	SCALE_ACC_SECOND 50,158,110
	SCALE_ACC_SECOND 51,159,111
	SCALE_ACC_SECOND 52,160,108
	SCALE_ACC_SECOND 53,161,109
	SCALE_ACC_SECOND 54,162,110
	SCALE_ACC_SECOND 55,163,111
	SCALE_ACC_SECOND 56,164,108
	SCALE_ACC_SECOND 57,165,109
	SCALE_ACC_SECOND 58,166,110
	SCALE_ACC_SECOND 59,167,111
	SCALE_ACC_SECOND 60,168,108
	SCALE_ACC_SECOND 61,169,109
	SCALE_ACC_SECOND 62,170,110
	SCALE_ACC_SECOND 63,171,111
	s_add_u32 s29, s29, 1
	s_cmp_lt_u32 s29, 4
	s_cbranch_scc1 .Lk_loop

	// Build the four row-validity masks once for all N16 stores.
	.macro BUILD_VALID_MASK packed, lo, hi
	v_lshrrev_b32_e32 v6, 24, v\packed
	v_and_b32_e32 v7, 0x00ffffff, v\packed
	v_cmp_gt_u32_e64 s[\lo:\hi], 9, v6
	v_cmp_gt_u32_e64 s[54:55], s22, v7
	s_and_b64 s[\lo:\hi], s[\lo:\hi], s[54:55]
	.endm
	BUILD_VALID_MASK 84,46,47
	BUILD_VALID_MASK 85,48,49
	BUILD_VALID_MASK 86,50,51
	BUILD_VALID_MASK 87,52,53

	// Deterministic unweighted FP32 route workspace. Four result rows and
	// four N16 tiles are contiguous in N for each route.
	v_lshlrev_b32_e32 v112, 13, v92
	v_lshlrev_b32_e32 v113, 13, v93
	v_lshlrev_b32_e32 v114, 13, v94
	v_lshlrev_b32_e32 v115, 13, v95
	v_add_u32_e32 v116, s28, v1
	v_lshlrev_b32_e32 v116, 2, v116
	.macro STORE_VALID address, value, lo, hi
	s_and_saveexec_b64 s[54:55], s[\lo:\hi]
	global_store_dword v\address, v\value, s[20:21]
	s_or_b64 exec, exec, s[54:55]
	.endm
	.macro STORE_TILE a0, a1, a2, a3, coloff
	v_add_u32_e32 v117, \coloff, v116
	v_add_u32_e32 v118, v112, v117
	v_add_u32_e32 v119, v113, v117
	v_add_u32_e32 v120, v114, v117
	v_add_u32_e32 v121, v115, v117
	STORE_VALID 118, \a0, 46,47
	STORE_VALID 119, \a1, 48,49
	STORE_VALID 120, \a2, 50,51
	STORE_VALID 121, \a3, 52,53
	.endm
	STORE_TILE 64,65,66,67,0
	STORE_TILE 68,69,70,71,64
	STORE_TILE 72,73,74,75,128
	STORE_TILE 76,77,78,79,192
	STORE_TILE 124,125,126,127,256
	STORE_TILE 128,129,130,131,320
	STORE_TILE 132,133,134,135,384
	STORE_TILE 136,137,138,139,448
	STORE_TILE 140,141,142,143,512
	STORE_TILE 144,145,146,147,576
	STORE_TILE 148,149,150,151,640
	STORE_TILE 152,153,154,155,704
	STORE_TILE 156,157,158,159,768
	STORE_TILE 160,161,162,163,832
	STORE_TILE 164,165,166,167,896
	STORE_TILE 168,169,170,171,960
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950
		.amdhsa_group_segment_fixed_size 32768
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 172
		.amdhsa_accum_offset 172
		.amdhsa_next_free_sgpr 57
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950, .Lfunc_end0-qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: route_activation_fp8, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: route_scale_f32, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w2_fp8, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_weights_f32, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: compact_sorted_expert_ids_i32, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: partial_f32, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: rows, .offset: 72, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 32768
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 60
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_down_m64n256_splitlds_partial_masked_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 172
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
