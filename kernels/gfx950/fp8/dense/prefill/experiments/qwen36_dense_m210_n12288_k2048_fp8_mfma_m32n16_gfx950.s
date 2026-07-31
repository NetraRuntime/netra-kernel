// SPDX-License-Identifier: MIT
//
// Native-CDNA4 Qwen3.6 block-FP8 prefill projection:
//   M=210, N=12288, K=2048, FP8 E4M3 weights with 128x128 scales,
//   per-row 1x128 FP8 activation scales, BF16 output.
//
// Grid: (N/16, ceil(M/32), 1), block: (64, 1, 1).
// One wave64 computes a 32x16 output tile as two independent 16x16 MFMA
// chains. Both row tiles reuse the same shuffled-weight loads with no LDS,
// barriers, split-K, scratch, or atomics.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950
	.globl qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950
	.p2align 8
	.type qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950,@function
qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950:
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v40, 4, v2

	// Column tile and 32-row tile bases.
	s_lshl_b32 s14, s2, 4
	s_lshl_b32 s15, s3, 5

	// A offsets for row tiles [base, base+15] and [base+16, base+31].
	v_add_u32_e32 v3, s15, v1
	v_lshlrev_b32_e32 v3, 11, v3
	v_add_u32_e32 v3, v2, v3

	// AITER shuffled-weight lane address for K-block zero.
	s_lshl_b32 s16, s2, 15
	v_lshlrev_b32_e32 v4, 4, v2
	v_lshlrev_b32_e32 v5, 4, v1
	v_add_u32_e32 v4, v4, v5
	v_add_u32_e32 v4, s16, v4

	// Output offsets for both 16-row tiles.
	v_lshlrev_b32_e32 v41, 2, v40
	v_add_u32_e32 v6, s15, v41
	v_lshlrev_b32_e32 v7, 14, v6
	v_lshlrev_b32_e32 v6, 13, v6
	v_add_u32_e32 v6, v6, v7
	v_add_u32_e32 v7, s14, v1
	v_lshlrev_b32_e32 v7, 1, v7
	v_add_u32_e32 v6, v6, v7
	v_add_u32_e32 v72, 393216, v6

	// Weight and activation-scale bases.
	s_lshr_b32 s17, s2, 3
	s_lshl_b32 s17, s17, 6
	s_lshl_b32 s18, s15, 2

	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v67, 0
	s_mov_b32 s19, 0

	s_cmp_lt_u32 s3, 6
	s_cbranch_scc0 .Ltail_prologue

.Lfull_prologue:
	s_lshl_b32 s20, s19, 7
	s_lshl_b32 s21, s19, 11
	v_add_u32_e32 v41, s20, v3
	v_add_u32_e32 v42, 32768, v3
	v_add_u32_e32 v42, s20, v42
	v_add_u32_e32 v43, s21, v4
	global_load_dwordx4 v[8:11], v41, s[4:5]
	global_load_dwordx4 v[12:15], v41, s[4:5] offset:64
	global_load_dwordx4 v[52:55], v42, s[4:5]
	global_load_dwordx4 v[56:59], v42, s[4:5] offset:64
	global_load_dwordx4 v[16:19], v43, s[8:9]
	global_load_dwordx4 v[20:23], v43, s[8:9] offset:1024

	s_mul_i32 s22, s19, 840
	s_add_u32 s22, s22, s18
	v_lshlrev_b32_e32 v44, 4, v40
	v_add_u32_e32 v44, s22, v44
	global_load_dword v36, v44, s[6:7]
	global_load_dword v37, v44, s[6:7] offset:4
	global_load_dword v38, v44, s[6:7] offset:8
	global_load_dword v39, v44, s[6:7] offset:12
	global_load_dword v68, v44, s[6:7] offset:64
	global_load_dword v69, v44, s[6:7] offset:68
	global_load_dword v70, v44, s[6:7] offset:72
	global_load_dword v71, v44, s[6:7] offset:76

	s_lshl_b32 s23, s19, 2
	s_add_u32 s23, s23, s17
	s_load_dword s24, s[10:11], s23
	s_waitcnt vmcnt(0) & lgkmcnt(0)

.Lfull_compute:
	v_mfma_f32_16x16x128_f8f6f4 v[24:27], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[52:59], v[16:23], 0
	s_cmp_eq_u32 s19, 15
	s_cbranch_scc1 .Lfull_last

	// Prefetch the next K block into the just-consumed operand registers.
	s_add_u32 s27, s19, 1
	s_lshl_b32 s20, s27, 7
	s_lshl_b32 s21, s27, 11
	v_add_u32_e32 v41, s20, v3
	v_add_u32_e32 v42, 32768, v3
	v_add_u32_e32 v42, s20, v42
	v_add_u32_e32 v43, s21, v4
	global_load_dwordx4 v[8:11], v41, s[4:5]
	global_load_dwordx4 v[12:15], v41, s[4:5] offset:64
	global_load_dwordx4 v[52:55], v42, s[4:5]
	global_load_dwordx4 v[56:59], v42, s[4:5] offset:64
	global_load_dwordx4 v[16:19], v43, s[8:9]
	global_load_dwordx4 v[20:23], v43, s[8:9] offset:1024
	s_nop 1

	v_mul_f32_e32 v24, s24, v24
	v_mul_f32_e32 v25, s24, v25
	v_mul_f32_e32 v26, s24, v26
	v_mul_f32_e32 v27, s24, v27
	v_mul_f32_e32 v60, s24, v60
	v_mul_f32_e32 v61, s24, v61
	v_mul_f32_e32 v62, s24, v62
	v_mul_f32_e32 v63, s24, v63
	v_fmac_f32_e32 v32, v36, v24
	v_fmac_f32_e32 v33, v37, v25
	v_fmac_f32_e32 v34, v38, v26
	v_fmac_f32_e32 v35, v39, v27
	v_fmac_f32_e32 v64, v68, v60
	v_fmac_f32_e32 v65, v69, v61
	v_fmac_f32_e32 v66, v70, v62
	v_fmac_f32_e32 v67, v71, v63

	// Scale loads are small and can trail the bulk A/B prefetch.
	s_mul_i32 s22, s27, 840
	s_add_u32 s22, s22, s18
	v_lshlrev_b32_e32 v44, 4, v40
	v_add_u32_e32 v44, s22, v44
	global_load_dword v36, v44, s[6:7]
	global_load_dword v37, v44, s[6:7] offset:4
	global_load_dword v38, v44, s[6:7] offset:8
	global_load_dword v39, v44, s[6:7] offset:12
	global_load_dword v68, v44, s[6:7] offset:64
	global_load_dword v69, v44, s[6:7] offset:68
	global_load_dword v70, v44, s[6:7] offset:72
	global_load_dword v71, v44, s[6:7] offset:76
	s_lshl_b32 s23, s27, 2
	s_add_u32 s23, s23, s17
	s_load_dword s24, s[10:11], s23
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	s_mov_b32 s19, s27
	s_branch .Lfull_compute

.Lfull_last:
	s_nop 14
	v_mul_f32_e32 v24, s24, v24
	v_mul_f32_e32 v25, s24, v25
	v_mul_f32_e32 v26, s24, v26
	v_mul_f32_e32 v27, s24, v27
	v_mul_f32_e32 v60, s24, v60
	v_mul_f32_e32 v61, s24, v61
	v_mul_f32_e32 v62, s24, v62
	v_mul_f32_e32 v63, s24, v63
	v_fmac_f32_e32 v32, v36, v24
	v_fmac_f32_e32 v33, v37, v25
	v_fmac_f32_e32 v34, v38, v26
	v_fmac_f32_e32 v35, v39, v27
	v_fmac_f32_e32 v64, v68, v60
	v_fmac_f32_e32 v65, v69, v61
	v_fmac_f32_e32 v66, v70, v62
	v_fmac_f32_e32 v67, v71, v63
	s_branch .Lstore_full

.Ltail_prologue:
	// Row tile zero is 192..207 and remains full. Row tile one contains
	// only rows 208 and 209.
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0

	s_lshl_b32 s20, s19, 7
	s_lshl_b32 s21, s19, 11
	v_add_u32_e32 v41, s20, v3
	// Reconstruct the second A tile address because v52 is also its operand.
	v_add_u32_e32 v42, 32768, v3
	v_add_u32_e32 v42, s20, v42
	v_add_u32_e32 v43, s21, v4
	global_load_dwordx4 v[8:11], v41, s[4:5]
	global_load_dwordx4 v[12:15], v41, s[4:5] offset:64
	v_cmp_gt_u32_e32 vcc, 2, v1
	s_and_saveexec_b64 s[28:29], vcc
	global_load_dwordx4 v[52:55], v42, s[4:5]
	global_load_dwordx4 v[56:59], v42, s[4:5] offset:64
	s_or_b64 exec, exec, s[28:29]
	global_load_dwordx4 v[16:19], v43, s[8:9]
	global_load_dwordx4 v[20:23], v43, s[8:9] offset:1024

	s_mul_i32 s22, s19, 840
	s_add_u32 s22, s22, s18
	v_lshlrev_b32_e32 v44, 4, v40
	v_add_u32_e32 v44, s22, v44
	global_load_dword v36, v44, s[6:7]
	global_load_dword v37, v44, s[6:7] offset:4
	global_load_dword v38, v44, s[6:7] offset:8
	global_load_dword v39, v44, s[6:7] offset:12
	v_cmp_gt_u32_e32 vcc, 16, v2
	s_and_saveexec_b64 s[28:29], vcc
	global_load_dword v68, v44, s[6:7] offset:64
	global_load_dword v69, v44, s[6:7] offset:68
	s_or_b64 exec, exec, s[28:29]

	s_lshl_b32 s23, s19, 2
	s_add_u32 s23, s23, s17
	s_load_dword s24, s[10:11], s23
	s_waitcnt vmcnt(0) & lgkmcnt(0)

.Ltail_compute:
	v_mfma_f32_16x16x128_f8f6f4 v[24:27], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[52:59], v[16:23], 0
	s_cmp_eq_u32 s19, 15
	s_cbranch_scc1 .Ltail_last

	s_add_u32 s27, s19, 1
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v59, 0
	s_lshl_b32 s20, s27, 7
	s_lshl_b32 s21, s27, 11
	v_add_u32_e32 v41, s20, v3
	v_add_u32_e32 v42, 32768, v3
	v_add_u32_e32 v42, s20, v42
	v_add_u32_e32 v43, s21, v4
	global_load_dwordx4 v[8:11], v41, s[4:5]
	global_load_dwordx4 v[12:15], v41, s[4:5] offset:64
	v_cmp_gt_u32_e32 vcc, 2, v1
	s_and_saveexec_b64 s[28:29], vcc
	global_load_dwordx4 v[52:55], v42, s[4:5]
	global_load_dwordx4 v[56:59], v42, s[4:5] offset:64
	s_or_b64 exec, exec, s[28:29]
	global_load_dwordx4 v[16:19], v43, s[8:9]
	global_load_dwordx4 v[20:23], v43, s[8:9] offset:1024

	v_mul_f32_e32 v24, s24, v24
	v_mul_f32_e32 v25, s24, v25
	v_mul_f32_e32 v26, s24, v26
	v_mul_f32_e32 v27, s24, v27
	v_mul_f32_e32 v60, s24, v60
	v_mul_f32_e32 v61, s24, v61
	v_fmac_f32_e32 v32, v36, v24
	v_fmac_f32_e32 v33, v37, v25
	v_fmac_f32_e32 v34, v38, v26
	v_fmac_f32_e32 v35, v39, v27
	v_fmac_f32_e32 v64, v68, v60
	v_fmac_f32_e32 v65, v69, v61

	s_mul_i32 s22, s27, 840
	s_add_u32 s22, s22, s18
	v_lshlrev_b32_e32 v44, 4, v40
	v_add_u32_e32 v44, s22, v44
	global_load_dword v36, v44, s[6:7]
	global_load_dword v37, v44, s[6:7] offset:4
	global_load_dword v38, v44, s[6:7] offset:8
	global_load_dword v39, v44, s[6:7] offset:12
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
	v_cmp_gt_u32_e32 vcc, 16, v2
	s_and_saveexec_b64 s[28:29], vcc
	global_load_dword v68, v44, s[6:7] offset:64
	global_load_dword v69, v44, s[6:7] offset:68
	s_or_b64 exec, exec, s[28:29]
	s_lshl_b32 s23, s27, 2
	s_add_u32 s23, s23, s17
	s_load_dword s24, s[10:11], s23
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	s_mov_b32 s19, s27
	s_branch .Ltail_compute

.Ltail_last:
	s_nop 14
	v_mul_f32_e32 v24, s24, v24
	v_mul_f32_e32 v25, s24, v25
	v_mul_f32_e32 v26, s24, v26
	v_mul_f32_e32 v27, s24, v27
	v_mul_f32_e32 v60, s24, v60
	v_mul_f32_e32 v61, s24, v61
	v_fmac_f32_e32 v32, v36, v24
	v_fmac_f32_e32 v33, v37, v25
	v_fmac_f32_e32 v34, v38, v26
	v_fmac_f32_e32 v35, v39, v27
	v_fmac_f32_e32 v64, v68, v60
	v_fmac_f32_e32 v65, v69, v61
	s_branch .Lstore_tail

.Lstore_full:
	v_cvt_pk_bf16_f32 v73, v32, v33
	v_cvt_pk_bf16_f32 v74, v34, v35
	v_lshrrev_b32_e32 v75, 16, v73
	v_lshrrev_b32_e32 v76, 16, v74
	global_store_short v6, v73, s[12:13]
	v_add_u32_e32 v7, 24576, v6
	global_store_short v7, v75, s[12:13]
	v_add_u32_e32 v7, 49152, v6
	global_store_short v7, v74, s[12:13]
	v_add_u32_e32 v7, 73728, v6
	global_store_short v7, v76, s[12:13]

	v_cvt_pk_bf16_f32 v73, v64, v65
	v_cvt_pk_bf16_f32 v74, v66, v67
	v_lshrrev_b32_e32 v75, 16, v73
	v_lshrrev_b32_e32 v76, 16, v74
	global_store_short v72, v73, s[12:13]
	v_add_u32_e32 v7, 24576, v72
	global_store_short v7, v75, s[12:13]
	v_add_u32_e32 v7, 49152, v72
	global_store_short v7, v74, s[12:13]
	v_add_u32_e32 v7, 73728, v72
	global_store_short v7, v76, s[12:13]
	s_waitcnt vmcnt(0)
	s_endpgm

.Lstore_tail:
	// First tile is full.
	v_cvt_pk_bf16_f32 v73, v32, v33
	v_cvt_pk_bf16_f32 v74, v34, v35
	v_lshrrev_b32_e32 v75, 16, v73
	v_lshrrev_b32_e32 v76, 16, v74
	global_store_short v6, v73, s[12:13]
	v_add_u32_e32 v7, 24576, v6
	global_store_short v7, v75, s[12:13]
	v_add_u32_e32 v7, 49152, v6
	global_store_short v7, v74, s[12:13]
	v_add_u32_e32 v7, 73728, v6
	global_store_short v7, v76, s[12:13]

	// Second tile has only accumulator rows zero and one in lane group zero.
	v_cmp_gt_u32_e32 vcc, 16, v2
	s_and_saveexec_b64 s[28:29], vcc
	v_cvt_pk_bf16_f32 v73, v64, v65
	v_lshrrev_b32_e32 v75, 16, v73
	global_store_short v72, v73, s[12:13]
	v_add_u32_e32 v7, 24576, v72
	global_store_short v7, v75, s[12:13]
	s_or_b64 exec, exec, s[28:29]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 77
		.amdhsa_accum_offset 80
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
	.size qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950, .Lfunc_end0-qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950

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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 30
    .sgpr_spill_count: 0
    .symbol: qwen36_dense_m210_n12288_k2048_fp8_mfma_m32n16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 77
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
