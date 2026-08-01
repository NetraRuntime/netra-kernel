// SPDX-License-Identifier: MIT
//
// Qwen3.6 expert-sorted FP8 W13 projection for gfx950.
// Four wave64s compute M64xN64. Each 8 KiB expert-weight K slab is loaded
// once per workgroup and reused by all four M16 row waves. Four independent
// MFMAs are issued per K block to hide matrix-pipe latency.
// Grid: (16 N64 tiles, num_valid_ids/64, 1), workgroup: 256, LDS: 8 KiB.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_gateup_m64n64_fp8_gfx950
	.globl qwen36_moe_gateup_m64n64_fp8_gfx950
	.p2align 8
	.type qwen36_moe_gateup_m64n64_fp8_gfx950,@function
qwen36_moe_gateup_m64n64_fp8_gfx950:
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dword s20, s[0:1], 64
	s_waitcnt lgkmcnt(0)

	// M64 sorted-block bounds and compact expert.
	s_lshl_b32 s21, s3, 6
	s_load_dword s22, s[16:17], 0
	s_lshl_b32 s23, s3, 2
	s_load_dword s23, s[14:15], s23
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s21, s22
	s_cbranch_scc0 .Lend

	// Vector-native wave/lane coordinates avoid a readfirstlane dependency.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s21, v5

	// Native A route for lane[3:0].
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[12:13]
	// Four result routes for lane[5:4].
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v88, v5, v3
	v_add_u32_e32 v89, 1, v88
	v_add_u32_e32 v90, 2, v88
	v_add_u32_e32 v91, 3, v88
	v_lshlrev_b32_e32 v3, 2, v88
	global_load_dword v84, v3, s[12:13]
	global_load_dword v85, v3, s[12:13] offset:4
	global_load_dword v86, v3, s[12:13] offset:8
	global_load_dword v87, v3, s[12:13] offset:12
	s_waitcnt vmcnt(0)

	// Decode/clamp the A token and four scale rows. Slot 9 is padding.
	v_lshrrev_b32_e32 v6, 24, v4
	v_and_b32_e32 v4, 0x00ffffff, v4
	v_cmp_gt_u32_e32 vcc, s20, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v4, 0, v4, vcc

	.macro DECODE_ROUTE reg
	v_lshrrev_b32_e32 v6, 24, v\reg
	v_and_b32_e32 v\reg, 0x00ffffff, v\reg
	v_cmp_gt_u32_e32 vcc, s20, v\reg
	v_cndmask_b32_e32 v\reg, 0, v\reg, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v\reg, 0, v\reg, vcc
	.endm
	DECODE_ROUTE 84
	DECODE_ROUTE 85
	DECODE_ROUTE 86
	DECODE_ROUTE 87

	// Expert bases and four shuffled N16 weight-tile bases.
	s_lshl_b32 s24, s23, 21
	s_add_u32 s32, s8, s24
	s_addc_u32 s33, s9, 0
	s_lshl_b32 s24, s23, 9
	s_add_u32 s34, s10, s24
	s_addc_u32 s35, s11, 0
	s_lshl_b32 s24, s2, 17
	s_add_u32 s32, s32, s24
	s_addc_u32 s33, s33, 0
	s_add_u32 s40, s32, 32768
	s_addc_u32 s41, s33, 0
	s_add_u32 s42, s32, 65536
	s_addc_u32 s43, s33, 0
	s_add_u32 s44, s32, 98304
	s_addc_u32 s45, s33, 0

	// A and LDS fragment addresses, cooperative loader byte offset.
	v_lshlrev_b32_e32 v94, 11, v4
	v_add_u32_e32 v94, v2, v94
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_lshlrev_b32_e32 v92, 3, v0

	// One W scale covers this N64 group; output starts at x*64.
	s_lshr_b32 s25, s2, 1
	s_lshl_b32 s25, s25, 6
	s_lshl_b32 s26, s2, 6

	// Sixteen FP32 accumulator registers: four rows x four N16 tiles.
	.macro ZERO_ACC reg
	v_mov_b32_e32 v\reg, 0
	.endm
	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	ZERO_ACC \r
	.endr
	s_mov_b32 s27, 0

.Lk_loop:
	// Four cooperative dwordx2 streams cover 4*2 KiB of W exactly once.
	s_lshl_b32 s28, s27, 11
	v_add_u32_e32 v95, s28, v92
	global_load_dwordx2 v[16:17], v95, s[32:33]
	global_load_dwordx2 v[24:25], v95, s[40:41]
	global_load_dwordx2 v[32:33], v95, s[42:43]
	global_load_dwordx2 v[40:41], v95, s[44:45]

	// Per-wave A fragment.
	s_lshl_b32 s29, s27, 7
	v_add_u32_e32 v96, s29, v94
	global_load_dwordx4 v[8:11], v96, s[4:5]
	global_load_dwordx4 v[12:15], v96, s[4:5] offset:64

	// Four activation scales and shared W scale.
	s_lshl_b32 s30, s27, 2
	v_lshlrev_b32_e32 v96, 6, v84
	v_add_u32_e32 v96, s30, v96
	global_load_dword v80, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v85
	v_add_u32_e32 v96, s30, v96
	global_load_dword v81, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v86
	v_add_u32_e32 v96, s30, v96
	global_load_dword v82, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v87
	v_add_u32_e32 v96, s30, v96
	global_load_dword v83, v96, s[6:7]
	s_add_u32 s31, s25, s30
	s_load_dword s36, s[34:35], s31

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	ds_write_b64 v92, v[16:17]
	ds_write_b64 v92, v[24:25] offset:2048
	ds_write_b64 v92, v[32:33] offset:4096
	ds_write_b64 v92, v[40:41] offset:6144
	s_waitcnt lgkmcnt(0)
	s_barrier

	ds_read_b128 v[16:19], v93
	ds_read_b128 v[20:23], v93 offset:1024
	ds_read_b128 v[24:27], v93 offset:2048
	ds_read_b128 v[28:31], v93 offset:3072
	ds_read_b128 v[32:35], v93 offset:4096
	ds_read_b128 v[36:39], v93 offset:5120
	ds_read_b128 v[40:43], v93 offset:6144
	ds_read_b128 v[44:47], v93 offset:7168
	s_waitcnt lgkmcnt(0)

	// Four independent matrix instructions cover N64.
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12

	.macro SCALE_ACC tmp, acc, scale
	v_mul_f32_e32 v\tmp, s36, v\tmp
	v_fmac_f32_e32 v\acc, v\scale, v\tmp
	.endm
	SCALE_ACC 48,64,80
	SCALE_ACC 49,65,81
	SCALE_ACC 50,66,82
	SCALE_ACC 51,67,83
	SCALE_ACC 52,68,80
	SCALE_ACC 53,69,81
	SCALE_ACC 54,70,82
	SCALE_ACC 55,71,83
	SCALE_ACC 56,72,80
	SCALE_ACC 57,73,81
	SCALE_ACC 58,74,82
	SCALE_ACC 59,75,83
	SCALE_ACC 60,76,80
	SCALE_ACC 61,77,81
	SCALE_ACC 62,78,82
	SCALE_ACC 63,79,83

	s_barrier
	s_add_u32 s27, s27, 1
	s_cmp_lt_u32 s27, 16
	s_cbranch_scc1 .Lk_loop

	// Store four rows for each of four N16 tiles in sorted-route order.
	v_lshlrev_b32_e32 v96, 11, v88
	v_lshlrev_b32_e32 v97, 11, v89
	v_lshlrev_b32_e32 v98, 11, v90
	v_lshlrev_b32_e32 v99, 11, v91
	v_add_u32_e32 v95, s26, v1
	v_lshlrev_b32_e32 v95, 1, v95

	.macro STORE_TILE a0, a1, a2, a3, coloff
	v_cvt_pk_bf16_f32 v100, v\a0, v\a1
	v_cvt_pk_bf16_f32 v101, v\a2, v\a3
	v_lshrrev_b32_e32 v102, 16, v100
	v_lshrrev_b32_e32 v103, 16, v101
	v_add_u32_e32 v104, \coloff, v95
	v_add_u32_e32 v105, v96, v104
	v_add_u32_e32 v106, v97, v104
	v_add_u32_e32 v107, v98, v104
	v_add_u32_e32 v108, v99, v104
	global_store_short v105, v100, s[18:19]
	global_store_short v106, v102, s[18:19]
	global_store_short v107, v101, s[18:19]
	global_store_short v108, v103, s[18:19]
	.endm
	STORE_TILE 64,65,66,67,0
	STORE_TILE 68,69,70,71,32
	STORE_TILE 72,73,74,75,64
	STORE_TILE 76,77,78,79,96
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_gateup_m64n64_fp8_gfx950
		.amdhsa_group_segment_fixed_size 8192
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 72
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 109
		.amdhsa_accum_offset 112
		.amdhsa_next_free_sgpr 46
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_gateup_m64n64_fp8_gfx950, .Lfunc_end0-qwen36_moe_gateup_m64n64_fp8_gfx950

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
      - { .name: sorted_output_bf16, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: rows, .offset: 64, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 8192
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_gateup_m64n64_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 46
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_gateup_m64n64_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 109
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
