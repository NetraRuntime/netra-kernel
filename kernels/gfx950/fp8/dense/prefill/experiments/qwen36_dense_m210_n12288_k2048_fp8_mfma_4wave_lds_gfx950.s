// SPDX-License-Identifier: MIT
//
// Native-CDNA4 Qwen3.6 block-FP8 prefill projection:
//   M=210, N=12288, K=2048, FP8 E4M3 weights with 128x128 scales,
//   per-row 1x128 FP8 activation scales, BF16 output.
//
// Grid: (N/16, ceil(ceil(M/16)/4), 1), block: (256, 1, 1).
// Four wave64s compute four 16x16 row tiles for the same output columns.
// The workgroup cooperatively loads each 2 KiB shuffled-weight K block once
// into LDS, reducing redundant HBM weight traffic by up to four times.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950
	.globl qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950
	.p2align 8
	.type qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950,@function
qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950:
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// Lane and wave coordinates within the 256-thread workgroup.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v40, 4, v2
	v_lshrrev_b32_e32 v51, 6, v0
	v_readfirstlane_b32 s25, v51

	// Four consecutive row tiles per workgroup Y.
	s_lshl_b32 s26, s3, 2
	s_add_u32 s26, s26, s25
	s_lshl_b32 s14, s2, 4
	s_lshl_b32 s15, s26, 4

	// A row-major byte offset for K-block zero.
	v_add_u32_e32 v3, s15, v1
	v_lshlrev_b32_e32 v3, 11, v3
	v_add_u32_e32 v3, v2, v3

	// Shuffled-weight tile base and lane read address within the LDS copy.
	s_lshl_b32 s16, s2, 15
	v_lshlrev_b32_e32 v4, 4, v2
	v_lshlrev_b32_e32 v5, 4, v1
	v_add_u32_e32 v4, v4, v5

	// Cooperative B loader: every thread owns eight contiguous bytes.
	v_lshlrev_b32_e32 v50, 3, v0

	// Output offset for accumulator zero: four-row group plus column.
	v_lshlrev_b32_e32 v41, 2, v40
	v_add_u32_e32 v6, s15, v41
	v_lshlrev_b32_e32 v7, 14, v6
	v_lshlrev_b32_e32 v6, 13, v6
	v_add_u32_e32 v6, v6, v7
	v_add_u32_e32 v7, s14, v1
	v_lshlrev_b32_e32 v7, 1, v7
	v_add_u32_e32 v6, v6, v7

	// Scale bases.
	s_lshr_b32 s17, s2, 3
	s_lshl_b32 s17, s17, 6
	s_lshl_b32 s18, s15, 2

	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	s_mov_b32 s19, 0

.Lk_loop:
	// Every wave issues the same cooperative B load. Across the 256 threads,
	// the dwordx2 transactions exactly cover the 2 KiB shuffled K block.
	s_lshl_b32 s21, s19, 11
	v_add_u32_e32 v47, s16, v50
	v_add_u32_e32 v47, s21, v47
	global_load_dwordx2 v[48:49], v47, s[8:9]

	// Prepare A and scales while the shared B block is in flight.
	s_cmp_lt_u32 s26, 13
	s_cbranch_scc1 .Lprepare_full
	s_cmp_eq_u32 s26, 13
	s_cbranch_scc1 .Lprepare_tail
	s_branch .Lprepare_inactive

.Lprepare_full:
	s_lshl_b32 s20, s19, 7
	v_add_u32_e32 v41, s20, v3
	global_load_dwordx4 v[8:11], v41, s[4:5]
	global_load_dwordx4 v[12:15], v41, s[4:5] offset:64

	s_mul_i32 s22, s19, 840
	s_add_u32 s22, s22, s18
	v_lshlrev_b32_e32 v43, 4, v40
	v_add_u32_e32 v43, s22, v43
	global_load_dword v36, v43, s[6:7]
	global_load_dword v37, v43, s[6:7] offset:4
	global_load_dword v38, v43, s[6:7] offset:8
	global_load_dword v39, v43, s[6:7] offset:12

	s_lshl_b32 s23, s19, 2
	s_add_u32 s23, s23, s17
	s_load_dword s24, s[10:11], s23
	s_branch .Lpublish_b

.Lprepare_tail:
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0

	s_lshl_b32 s20, s19, 7
	v_add_u32_e32 v41, s20, v3
	v_cmp_gt_u32_e32 vcc, 2, v1
	s_and_saveexec_b64 s[28:29], vcc
	global_load_dwordx4 v[8:11], v41, s[4:5]
	global_load_dwordx4 v[12:15], v41, s[4:5] offset:64
	s_or_b64 exec, exec, s[28:29]

	s_mul_i32 s22, s19, 840
	s_add_u32 s22, s22, s18
	v_lshlrev_b32_e32 v43, 4, v40
	v_add_u32_e32 v43, s22, v43
	v_cmp_gt_u32_e32 vcc, 16, v2
	s_and_saveexec_b64 s[28:29], vcc
	global_load_dword v36, v43, s[6:7]
	global_load_dword v37, v43, s[6:7] offset:4
	s_or_b64 exec, exec, s[28:29]

	s_lshl_b32 s23, s19, 2
	s_add_u32 s23, s23, s17
	s_load_dword s24, s[10:11], s23
	s_branch .Lpublish_b

.Lprepare_inactive:
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	s_mov_b32 s24, 0

.Lpublish_b:
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	ds_write_b64 v50, v[48:49]
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Each active wave reads the identical B fragment distribution from LDS.
	ds_read_b128 v[16:19], v4
	ds_read_b128 v[20:23], v4 offset:1024
	s_waitcnt lgkmcnt(0)

	s_cmp_ge_u32 s26, 14
	s_cbranch_scc1 .Lfinish_kblock
	v_mfma_f32_16x16x128_f8f6f4 v[24:27], v[8:15], v[16:23], 0
	s_nop 15
	v_mul_f32_e32 v24, s24, v24
	v_mul_f32_e32 v25, s24, v25
	v_mul_f32_e32 v26, s24, v26
	v_mul_f32_e32 v27, s24, v27
	v_fmac_f32_e32 v32, v36, v24
	v_fmac_f32_e32 v33, v37, v25
	v_fmac_f32_e32 v34, v38, v26
	v_fmac_f32_e32 v35, v39, v27

.Lfinish_kblock:
	// All waves must finish consuming LDS before the next cooperative write.
	s_barrier
	s_add_u32 s19, s19, 1
	s_cmp_lt_u32 s19, 16
	s_cbranch_scc1 .Lk_loop

	s_cmp_lt_u32 s26, 13
	s_cbranch_scc1 .Lstore_full
	s_cmp_eq_u32 s26, 13
	s_cbranch_scc1 .Lstore_tail
	s_endpgm

.Lstore_tail:
	v_cmp_gt_u32_e32 vcc, 16, v2
	s_and_saveexec_b64 s[28:29], vcc
	v_cvt_pk_bf16_f32 v44, v32, v33
	v_lshrrev_b32_e32 v46, 16, v44
	global_store_short v6, v44, s[12:13]
	v_add_u32_e32 v7, 24576, v6
	global_store_short v7, v46, s[12:13]
	s_or_b64 exec, exec, s[28:29]
	s_waitcnt vmcnt(0)
	s_endpgm

.Lstore_full:
	v_cvt_pk_bf16_f32 v44, v32, v33
	v_cvt_pk_bf16_f32 v45, v34, v35
	v_lshrrev_b32_e32 v46, 16, v44
	v_lshrrev_b32_e32 v47, 16, v45
	global_store_short v6, v44, s[12:13]
	v_add_u32_e32 v7, 24576, v6
	global_store_short v7, v46, s[12:13]
	v_add_u32_e32 v7, 49152, v6
	global_store_short v7, v45, s[12:13]
	v_add_u32_e32 v7, 73728, v6
	global_store_short v7, v47, s[12:13]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950
		.amdhsa_group_segment_fixed_size 2048
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 52
		.amdhsa_accum_offset 52
		.amdhsa_next_free_sgpr 30
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
	.size qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950, .Lfunc_end0-qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: activation_fp8, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: activation_scale_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: shuffled_weight_fp8, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: weight_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 2048
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 30
    .sgpr_spill_count: 0
    .symbol: qwen36_dense_m210_n12288_k2048_fp8_mfma_4wave_lds_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 52
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
