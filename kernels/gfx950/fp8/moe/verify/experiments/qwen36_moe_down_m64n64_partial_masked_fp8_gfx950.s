// SPDX-License-Identifier: MIT
//
// Qwen3.6 expert-sorted W2 projection for gfx950.
// Four wave64s compute M64xN64, cooperatively reuse each 8 KiB W2 K slab,
// write deterministic FP32 route partials for the fixed-order raw reducer.
// Padded M64 rows are suppressed at the VMEM boundary instead of writing the
// large ignored sink workspace.
// Four validity masks are built once and reused across all N16 stores; router
// weights remain in the fixed-order reducer and are not loaded here.
// Grid: (32 N64 tiles, num_valid_ids/64, 1), workgroup: 256, LDS: 8 KiB.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_down_m64n64_partial_masked_fp8_gfx950
	.globl qwen36_moe_down_m64n64_partial_masked_fp8_gfx950
	.p2align 8
	.type qwen36_moe_down_m64n64_partial_masked_fp8_gfx950,@function
qwen36_moe_down_m64n64_partial_masked_fp8_gfx950:
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
	s_lshl_b32 s26, s2, 15
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

	// W2 scale group and output N64 base.
	s_lshr_b32 s27, s2, 1
	s_lshl_b32 s27, s27, 4
	s_lshl_b32 s28, s2, 6

	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	v_mov_b32_e32 v\r, 0
	.endr
	s_mov_b32 s29, 0

.Lk_loop:
	// Cooperative W2 load: four 2 KiB N16xK128 tiles.
	s_lshl_b32 s30, s29, 11
	v_add_u32_e32 v99, s30, v96
	global_load_dwordx2 v[16:17], v99, s[32:33]
	global_load_dwordx2 v[24:25], v99, s[40:41]
	global_load_dwordx2 v[32:33], v99, s[42:43]
	global_load_dwordx2 v[40:41], v99, s[44:45]

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

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	ds_write_b64 v96, v[16:17]
	ds_write_b64 v96, v[24:25] offset:2048
	ds_write_b64 v96, v[32:33] offset:4096
	ds_write_b64 v96, v[40:41] offset:6144
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[16:19], v97
	ds_read_b128 v[20:23], v97 offset:1024
	ds_read_b128 v[24:27], v97 offset:2048
	ds_read_b128 v[28:31], v97 offset:3072
	ds_read_b128 v[32:35], v97 offset:4096
	ds_read_b128 v[36:39], v97 offset:5120
	ds_read_b128 v[40:43], v97 offset:6144
	ds_read_b128 v[44:47], v97 offset:7168
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
	s_barrier
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
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_down_m64n64_partial_masked_fp8_gfx950
		.amdhsa_group_segment_fixed_size 8192
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 123
		.amdhsa_accum_offset 124
		.amdhsa_next_free_sgpr 56
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_down_m64n64_partial_masked_fp8_gfx950, .Lfunc_end0-qwen36_moe_down_m64n64_partial_masked_fp8_gfx950

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
    .group_segment_fixed_size: 8192
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_down_m64n64_partial_masked_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 58
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_down_m64n64_partial_masked_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 123
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
