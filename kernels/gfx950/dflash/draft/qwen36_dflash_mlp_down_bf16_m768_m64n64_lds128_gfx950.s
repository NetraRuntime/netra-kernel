// SPDX-License-Identifier: MIT
//
// Qwen3.6 dFlash draft verification MLP down projection:
//   BF16 input [768,6144] x BF16 weight^T [6144,2048]
//     -> BF16 output [768,2048].
//
// Four wave64s compute a 64x64 output macro tile. Each wave owns one 32x32
// quadrant (four native 16x16x32 BF16 MFMAs). A and B are staged in K=128
// slabs. The LDS row pitch is 272 bytes: the 16-byte pad changes the row-start
// bank by four dwords, avoiding the all-rows-on-one-bank pattern of a 256-byte
// pitch while preserving vector reads.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950
	.globl qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950
	.p2align 8
	.type qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950,@function
qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950:
	// Save workgroup IDs before loading output, input, and weight pointers.
	s_mov_b32 s12, s2
	s_mov_b32 s13, s3
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// Lane/wave decomposition and native MFMA operand subgroup.
	v_and_b32_e32 v1, 63, v0
	v_lshrrev_b32_e32 v2, 6, v0
	v_and_b32_e32 v3, 15, v1
	v_and_b32_e32 v4, 48, v1
	v_lshrrev_b32_e32 v5, 1, v2
	v_and_b32_e32 v6, 1, v2
	v_readfirstlane_b32 s14, v5
	v_readfirstlane_b32 s15, v6
	s_lshl_b32 s14, s14, 5       // wave-relative row base: 0 or 32
	s_lshl_b32 s15, s15, 5       // wave-relative col base: 0 or 32
	s_lshl_b32 s20, s13, 6       // workgroup row base
	s_lshl_b32 s21, s12, 6       // workgroup col base
	s_add_u32 s16, s20, s14      // absolute wave row base
	s_add_u32 s17, s21, s15      // absolute wave col base
	s_mov_b32 s22, 272           // padded LDS row pitch

	// Cooperative global load mapping: four threads per row, each thread loads
	// four 16-byte vectors separated by 64 bytes, covering a 128-BF16 row slab.
	v_lshrrev_b32_e32 v7, 2, v0
	v_and_b32_e32 v12, 3, v0
	v_lshlrev_b32_e32 v12, 4, v12
	v_add_u32_e32 v13, s20, v7
	v_lshlrev_b32_e32 v8, 13, v13
	v_lshlrev_b32_e32 v9, 12, v13
	v_add_u32_e32 v8, v8, v9
	v_add_u32_e32 v8, v8, v12
	v_add_u32_e32 v13, s21, v7
	v_lshlrev_b32_e32 v10, 13, v13
	v_lshlrev_b32_e32 v11, 12, v13
	v_add_u32_e32 v10, v10, v11
	v_add_u32_e32 v10, v10, v12

	// Cooperative LDS write offsets. A occupies [0,17408), B [17408,34816).
	v_mul_lo_u32 v48, v7, s22
	v_add_u32_e32 v48, v48, v12
	v_add_u32_e32 v49, 17408, v48

	// Per-wave LDS read offsets for two 16-row and two 16-column panels.
	v_add_u32_e32 v50, s14, v3
	v_mul_lo_u32 v50, v50, s22
	v_add_u32_e32 v50, v50, v4
	v_add_u32_e32 v51, 4352, v50
	v_add_u32_e32 v52, s15, v3
	v_mul_lo_u32 v52, v52, s22
	v_add_u32_e32 v52, v52, v4
	v_add_u32_e32 v52, 17408, v52
	v_add_u32_e32 v53, 4352, v52

	// Four 16x16 FP32 accumulators per lane.
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
	s_mov_b32 s18, 0

.Lk128_stage_loop:
	// Load one K=128 slab for A and B.
	global_load_dwordx4 v[16:19], v8, s[4:5]
	global_load_dwordx4 v[20:23], v8, s[4:5] offset:64
	global_load_dwordx4 v[24:27], v8, s[4:5] offset:128
	global_load_dwordx4 v[28:31], v8, s[4:5] offset:192
	global_load_dwordx4 v[32:35], v10, s[6:7]
	global_load_dwordx4 v[36:39], v10, s[6:7] offset:64
	global_load_dwordx4 v[40:43], v10, s[6:7] offset:128
	global_load_dwordx4 v[44:47], v10, s[6:7] offset:192
	s_waitcnt vmcnt(0)
	ds_write_b128 v48, v[16:19]
	ds_write_b128 v48, v[20:23] offset:64
	ds_write_b128 v48, v[24:27] offset:128
	ds_write_b128 v48, v[28:31] offset:192
	ds_write_b128 v49, v[32:35]
	ds_write_b128 v49, v[36:39] offset:64
	ds_write_b128 v49, v[40:43] offset:128
	ds_write_b128 v49, v[44:47] offset:192
	s_waitcnt lgkmcnt(0)
	s_barrier

	// K[0:32]
	ds_read_b128 v[16:19], v50
	ds_read_b128 v[20:23], v51
	ds_read_b128 v[24:27], v52
	ds_read_b128 v[28:31], v53
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[64:67], v[16:19], v[24:27], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[16:19], v[28:31], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[20:23], v[24:27], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[20:23], v[28:31], v[76:79]

	// K[32:64]
	ds_read_b128 v[16:19], v50 offset:64
	ds_read_b128 v[20:23], v51 offset:64
	ds_read_b128 v[24:27], v52 offset:64
	ds_read_b128 v[28:31], v53 offset:64
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[64:67], v[16:19], v[24:27], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[16:19], v[28:31], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[20:23], v[24:27], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[20:23], v[28:31], v[76:79]

	// K[64:96]
	ds_read_b128 v[16:19], v50 offset:128
	ds_read_b128 v[20:23], v51 offset:128
	ds_read_b128 v[24:27], v52 offset:128
	ds_read_b128 v[28:31], v53 offset:128
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[64:67], v[16:19], v[24:27], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[16:19], v[28:31], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[20:23], v[24:27], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[20:23], v[28:31], v[76:79]

	// K[96:128]
	ds_read_b128 v[16:19], v50 offset:192
	ds_read_b128 v[20:23], v51 offset:192
	ds_read_b128 v[24:27], v52 offset:192
	ds_read_b128 v[28:31], v53 offset:192
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[64:67], v[16:19], v[24:27], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[16:19], v[28:31], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[20:23], v[24:27], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[20:23], v[28:31], v[76:79]

	// All waves must finish LDS reads before the next slab overwrites it.
	s_barrier
	v_add_u32_e32 v8, 256, v8
	v_add_u32_e32 v10, 256, v10
	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 48
	s_cbranch_scc1 .Lk128_stage_loop

	// Base output byte address for accumulator 00.
	v_and_b32_e32 v12, 48, v1
	v_lshlrev_b32_e32 v12, 10, v12
	s_lshl_b32 s19, s16, 12
	v_add_u32_e32 v13, s17, v3
	v_lshlrev_b32_e32 v13, 1, v13
	v_add_u32_e32 v14, s19, v12
	v_add_u32_e32 v14, v14, v13

	// accumulator 00
	v_cvt_pk_bf16_f32 v32, v64, v65
	v_cvt_pk_bf16_f32 v33, v66, v67
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	global_store_short v14, v32, s[2:3]
	v_add_u32_e32 v15, 4096, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 8192, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 12288, v14
	global_store_short v15, v35, s[2:3]

	// accumulator 01: +16 columns
	v_cvt_pk_bf16_f32 v32, v68, v69
	v_cvt_pk_bf16_f32 v33, v70, v71
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 32, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 4128, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 8224, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 12320, v14
	global_store_short v15, v35, s[2:3]

	// accumulator 10: +16 rows
	v_cvt_pk_bf16_f32 v32, v72, v73
	v_cvt_pk_bf16_f32 v33, v74, v75
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 65536, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 69632, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 73728, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 77824, v14
	global_store_short v15, v35, s[2:3]

	// accumulator 11: +16 rows and +16 columns
	v_cvt_pk_bf16_f32 v32, v76, v77
	v_cvt_pk_bf16_f32 v33, v78, v79
	v_lshrrev_b32_e32 v34, 16, v32
	v_lshrrev_b32_e32 v35, 16, v33
	v_add_u32_e32 v15, 65568, v14
	global_store_short v15, v32, s[2:3]
	v_add_u32_e32 v15, 69664, v14
	global_store_short v15, v34, s[2:3]
	v_add_u32_e32 v15, 73760, v14
	global_store_short v15, v33, s[2:3]
	v_add_u32_e32 v15, 77856, v14
	global_store_short v15, v35, s[2:3]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950
		.amdhsa_group_segment_fixed_size 34816
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 80
		.amdhsa_accum_offset 80
		.amdhsa_next_free_sgpr 23
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
	.size qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950, .Lfunc_end0-qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950

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
    .group_segment_fixed_size: 34816
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 23
    .sgpr_spill_count: 0
    .symbol: qwen36_dflash_mlp_down_bf16_m768_m64n64_lds128_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 80
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
