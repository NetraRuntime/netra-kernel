// SPDX-License-Identifier: MIT
//
// Native-CDNA4 Qwen3.6 dense output projection:
//   M=1, N=2048, K=4096, FP8 E4M3, 128x128 block scales -> BF16.
//
// One wave64 computes 16 output columns. The weight is consumed directly in
// AITER shuffle_weight(weight, (16, 16)) layout; no logical-layout duplicate
// is required by the serving integration.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
	.globl qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
	.p2align 8
	.type qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950,@function
qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950:
	// Kernargs: activation FP8, activation scales FP32, shuffled weight FP8,
	//           weight scales FP32, output BF16.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// tile = workgroup id, column = tile*16 + lane%16.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	s_lshl_b32 s18, s2, 4
	v_add_u32_e32 v3, s18, v1
	v_mov_b32_e32 v6, 0

	// Physical shuffled-weight offset for K-block zero:
	// tile*16*4096 + (lane/16)*256 + (lane%16)*16.
	s_lshl_b32 s19, s2, 16
	v_lshlrev_b32_e32 v4, 4, v2
	v_lshlrev_b32_e32 v5, 4, v1
	v_add_u32_e32 v4, v4, v5
	v_add_u32_e32 v4, s19, v4

	// One 128x128 scale covers eight adjacent 16-column tiles.
	s_lshr_b32 s20, s2, 3
	s_lshl_b32 s20, s20, 7
	s_add_u32 s22, s10, s20
	s_addc_u32 s23, s11, 0

	s_mov_b32 s24, 0
.Lkblock:
	// Canonical activation and scale offsets.
	s_lshl_b32 s25, s24, 7
	s_lshl_b32 s26, s24, 2
	s_load_dword s27, s[6:7], s26
	s_load_dword s28, s[22:23], s26
	v_add_u32_e32 v7, s25, v2
	global_load_dwordx4 v[10:13], v7, s[4:5]
	global_load_dwordx4 v[14:17], v7, s[4:5] offset:64

	// Each logical K=128 block occupies 2,048 bytes in the AITER 16x16
	// preshuffle. The second MFMA half is 1,024 bytes after the first.
	s_lshl_b32 s29, s24, 11
	v_add_u32_e32 v8, s29, v4
	global_load_dwordx4 v[18:21], v8, s[8:9]
	global_load_dwordx4 v[22:25], v8, s[8:9] offset:1024
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15
	v_mul_f32_e32 v9, s27, v26
	v_mul_f32_e32 v9, s28, v9
	v_add_f32_e32 v6, v6, v9

	s_add_u32 s24, s24, 1
	s_cmp_lt_u32 s24, 32
	s_cbranch_scc1 .Lkblock

	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[30:31], vcc
	v_cvt_pk_bf16_f32 v8, v6, v6
	v_lshlrev_b32_e32 v9, 1, v3
	global_store_short v9, v8, s[12:13]
	s_or_b64 exec, exec, s[30:31]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 30
		.amdhsa_accum_offset 32
		.amdhsa_next_free_sgpr 32
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950, .Lfunc_end0-qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950

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
    .name: qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 32
    .sgpr_spill_count: 0
    .symbol: qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 30
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
