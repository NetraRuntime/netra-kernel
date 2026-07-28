// SPDX-License-Identifier: MIT
//
// Raw gfx1151 SGLang decode finalizer for Qwen3.6-35B-A3B.
// Reduces eight routed expert outputs with FP32 router weights and emits BF16.
// Input: [8,2048] fp32; weights: [8] fp32; output: [2048] bf16.
// Launch: grid=(8,1,1), block=(256,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.protected mxfp4_sgl_reduce_gfx1151
	.globl mxfp4_sgl_reduce_gfx1151
	.p2align 8
	.type mxfp4_sgl_reduce_gfx1151,@function
mxfp4_sgl_reduce_gfx1151:
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b64 s[8:9], s[0:1], 16
	s_waitcnt lgkmcnt(0)
	s_load_b128 s[12:15], s[6:7], 0
	s_load_b128 s[16:19], s[6:7], 16

	s_lshl_b32 s20, s2, 10
	v_lshlrev_b32_e32 v1, 2, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v1, s20, v1

	v_mov_b32_e32 v11, v1
	global_load_b32 v2, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v3, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v4, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v5, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v6, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v7, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v8, v11, s[4:5]
	v_add_nc_u32_e32 v11, 8192, v11
	global_load_b32 v9, v11, s[4:5]
	s_waitcnt vmcnt(0) lgkmcnt(0)

	v_mul_f32_e32 v2, s12, v2
	v_fmac_f32_e32 v2, s13, v3
	v_fmac_f32_e32 v2, s14, v4
	v_fmac_f32_e32 v2, s15, v5
	v_fmac_f32_e32 v2, s16, v6
	v_fmac_f32_e32 v2, s17, v7
	v_fmac_f32_e32 v2, s18, v8
	v_fmac_f32_e32 v2, s19, v9

	// IEEE round-to-nearest-even FP32 -> BF16.
	v_lshrrev_b32_e32 v3, 16, v2
	v_and_b32_e32 v3, 1, v3
	v_add_nc_u32_e32 v3, 0x7fff, v3
	v_add_nc_u32_e32 v2, v3, v2
	v_lshrrev_b32_e32 v2, 16, v2
	v_lshrrev_b32_e32 v1, 1, v1
	global_store_short v1, v2, s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_sgl_reduce_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 21
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_workgroup_processor_mode 1
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_shared_vgpr_count 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size mxfp4_sgl_reduce_gfx1151, .Lfunc_end0-mxfp4_sgl_reduce_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: expert_output, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: topk_weights, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: mxfp4_sgl_reduce_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 23
    .sgpr_spill_count: 0
    .symbol: mxfp4_sgl_reduce_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 12
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
