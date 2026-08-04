// SPDX-License-Identifier: MIT
//
// Qwen3.6 expert-sorted W2 projection for gfx950.
// Four wave64s compute M64xN128 as two sequential N64 halves, cooperatively
// reuse route activations/scales and preload paired 8 KiB W2 K slabs,
// apply route weights and atomically accumulate packed BF16 pairs directly
// into the final token-major output. This removes the FP32 route-partial
// workspace and the separate fixed-order reduction launch.
// Padded M64 rows are suppressed at the VMEM boundary instead of writing the
// large ignored sink workspace.
// Four validity masks are built once and reused across all N16 stores; router
// weights remain in the fixed-order reducer and are not loaded here.
// Two 16 KiB ping-pong buffers let the next K iteration write a disjoint slab
// without an end-of-iteration barrier.
// Grid: (16 N128 tiles, num_valid_ids/64, 1), workgroup: 256, LDS: 32 KiB.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950
	.globl qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950
	.p2align 8
	.type qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950,@function
qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950:
	// route FP8/scales, shuffled W2/scales, sorted IDs, experts,
	// valid count, BF16 token-major output, rows.
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
	global_load_dword v120, v3, s[14:15]
	global_load_dword v121, v3, s[14:15] offset:4
	global_load_dword v122, v3, s[14:15] offset:8
	global_load_dword v123, v3, s[14:15] offset:12
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
	s_lshl_b32 s26, s2, 16
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

	// One W2 scale covers this N128 group; output starts at x*128.
	s_lshl_b32 s27, s2, 4
	s_lshl_b32 s28, s2, 7

	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	v_mov_b32_e32 v\r, 0
	.endr
	.irp r,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139
	v_mov_b32_e32 v\r, 0
	.endr
	s_mov_b32 s29, 0

.Lk_loop:
	// Alternate complete paired slabs. The producer barrier in each iteration
	// also proves all waves have retired reads from the previous iteration,
	// making that buffer safe to reuse two iterations later.
	s_and_b32 s39, s29, 1
	s_lshl_b32 s39, s39, 14
	v_add_u32_e32 v102, s39, v96
	v_add_u32_e32 v103, s39, v97
	// Cooperative W2 load: four 2 KiB N16xK128 tiles.
	s_lshl_b32 s30, s29, 11
	v_add_u32_e32 v99, s30, v96
	global_load_dwordx2 v[16:17], v99, s[32:33]
	global_load_dwordx2 v[24:25], v99, s[40:41]
	global_load_dwordx2 v[32:33], v99, s[42:43]
	global_load_dwordx2 v[40:41], v99, s[44:45]
	// The second N64 slab is independent and upper LDS is otherwise unused.
	// Put both VMEM rounds in flight before the common wait and producer
	// barrier, then consume them from separate 8 KiB slabs.
	v_add_u32_e32 v101, 32768, v99
	global_load_dwordx2 v[80:81], v101, s[32:33]
	global_load_dwordx2 v[82:83], v101, s[40:41]
	global_load_dwordx2 v[88:89], v101, s[42:43]
	global_load_dwordx2 v[90:91], v101, s[44:45]

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
	ds_write_b64 v102, v[16:17]
	ds_write_b64 v102, v[24:25] offset:2048
	ds_write_b64 v102, v[32:33] offset:4096
	ds_write_b64 v102, v[40:41] offset:6144
	ds_write_b64 v102, v[80:81] offset:8192
	ds_write_b64 v102, v[82:83] offset:10240
	ds_write_b64 v102, v[88:89] offset:12288
	ds_write_b64 v102, v[90:91] offset:14336
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

	// Apply sorted route weights and atomically accumulate adjacent BF16
	// columns. Neighbor exchange stays within each 16-lane MFMA subgroup;
	// only the even lane issues the packed pair atomic.
	v_and_b32_e32 v112, 63, v0
	v_xor_b32_e32 v113, 1, v112
	v_lshlrev_b32_e32 v113, 2, v113
	v_and_b32_e32 v114, 1, v1
	v_cmp_eq_u32_e64 s[44:45], 0, v114
	s_lshl_b32 s28, s2, 8
	v_lshlrev_b32_e32 v115, 1, v1
	v_add_u32_e32 v115, s28, v115
	v_and_b32_e32 v84, 0x00ffffff, v84
	v_and_b32_e32 v85, 0x00ffffff, v85
	v_and_b32_e32 v86, 0x00ffffff, v86
	v_and_b32_e32 v87, 0x00ffffff, v87
	.macro ATOMIC_TILE a0, a1, a2, a3, coloff
	v_mul_f32_e32 v\a0, v120, v\a0
	v_mul_f32_e32 v\a1, v121, v\a1
	v_mul_f32_e32 v\a2, v122, v\a2
	v_mul_f32_e32 v\a3, v123, v\a3
	ds_bpermute_b32 v16, v113, v\a0
	ds_bpermute_b32 v17, v113, v\a1
	ds_bpermute_b32 v18, v113, v\a2
	ds_bpermute_b32 v19, v113, v\a3
	s_waitcnt lgkmcnt(0)
	v_cvt_pk_bf16_f32 v20, v\a0, v16
	v_cvt_pk_bf16_f32 v21, v\a1, v17
	v_cvt_pk_bf16_f32 v22, v\a2, v18
	v_cvt_pk_bf16_f32 v23, v\a3, v19
	v_add_u32_e32 v116, \coloff, v115
	v_lshlrev_b32_e32 v117, 12, v84
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 12, v85
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 12, v86
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 12, v87
	v_add_u32_e32 v124, v116, v124
	s_and_b64 s[42:43], s[46:47], s[44:45]
	s_and_saveexec_b64 s[54:55], s[42:43]
	global_atomic_pk_add_bf16 v117, v20, s[20:21]
	s_or_b64 exec, exec, s[54:55]
	s_and_b64 s[42:43], s[48:49], s[44:45]
	s_and_saveexec_b64 s[54:55], s[42:43]
	global_atomic_pk_add_bf16 v118, v21, s[20:21]
	s_or_b64 exec, exec, s[54:55]
	s_and_b64 s[42:43], s[50:51], s[44:45]
	s_and_saveexec_b64 s[54:55], s[42:43]
	global_atomic_pk_add_bf16 v119, v22, s[20:21]
	s_or_b64 exec, exec, s[54:55]
	s_and_b64 s[42:43], s[52:53], s[44:45]
	s_and_saveexec_b64 s[54:55], s[42:43]
	global_atomic_pk_add_bf16 v124, v23, s[20:21]
	s_or_b64 exec, exec, s[54:55]
	.endm
	ATOMIC_TILE 64,65,66,67,0
	ATOMIC_TILE 68,69,70,71,32
	ATOMIC_TILE 72,73,74,75,64
	ATOMIC_TILE 76,77,78,79,96
	ATOMIC_TILE 124,125,126,127,128
	ATOMIC_TILE 128,129,130,131,160
	ATOMIC_TILE 132,133,134,135,192
	ATOMIC_TILE 136,137,138,139,224
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950
		.amdhsa_group_segment_fixed_size 32768
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 140
		.amdhsa_accum_offset 140
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
	.size qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950, .Lfunc_end0-qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950

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
      - { .name: output_bf16, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: rows, .offset: 72, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 32768
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 58
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_down_m64n128_atomic_masked_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 140
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
