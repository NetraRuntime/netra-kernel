// SPDX-License-Identifier: MIT
//
// Experimental raw gfx1151 fused routed gate/up chunk4 reduction + SiLU.
// Input partials: [2,16,8,512] FP32. Output: [8,512] BF16.
// Reduction order matches mxfp4_decode_gate_chunk4_reduce_gfx1151.
// Launch: grid=(2,8,1), block=(128,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.protected mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151
	.globl mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151
	.p2align 8
	.type mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151,@function
mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151:
	// Kernargs: combined partials, BF16 output.
	s_load_b128 s[4:7], s[0:1], 0
	s_waitcnt lgkmcnt(0)

	// Gate and up partials are 262144 bytes apart.
	s_add_u32 s8, s4, 262144
	s_addc_u32 s9, s5, 0
	// Slot offsets: FP32 partial 2048 bytes, BF16 output 1024 bytes.
	s_lshl_b32 s14, s3, 11
	s_lshl_b32 s15, s3, 10
	s_add_u32 s4, s4, s14
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, s14
	s_addc_u32 s9, s9, 0
	s_add_u32 s6, s6, s15
	s_addc_u32 s7, s7, 0

	// Second original K halves begin at chunk 8.
	s_add_u32 s10, s4, 131072
	s_addc_u32 s11, s5, 0
	s_add_u32 s12, s8, 131072
	s_addc_u32 s13, s9, 0

	// Two workgroups per slot; each lane owns two adjacent columns.
	s_lshl_b32 s14, s2, 8
	v_lshlrev_b32_e32 v1, 1, v0
	v_add_nc_u32_e32 v1, s14, v1
	v_lshlrev_b32_e32 v7, 2, v1
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
	v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
	s_mov_b32 s16, 8

.Lreduce_chunk:
	global_load_b64 v[2:3], v7, s[4:5]
	global_load_b64 v[4:5], v7, s[10:11]
	global_load_b64 v[16:17], v7, s[8:9]
	global_load_b64 v[18:19], v7, s[12:13]
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v8, v8, v2
	v_add_f32_e32 v9, v9, v3
	v_add_f32_e32 v10, v10, v4
	v_add_f32_e32 v11, v11, v5
	v_add_f32_e32 v12, v12, v16
	v_add_f32_e32 v13, v13, v17
	v_add_f32_e32 v14, v14, v18
	v_add_f32_e32 v15, v15, v19

	s_add_u32 s4, s4, 16384
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, 16384
	s_addc_u32 s9, s9, 0
	s_add_u32 s10, s10, 16384
	s_addc_u32 s11, s11, 0
	s_add_u32 s12, s12, 16384
	s_addc_u32 s13, s13, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lreduce_chunk

	v_add_f32_e32 v8, v8, v10
	v_add_f32_e32 v9, v9, v11
	v_add_f32_e32 v12, v12, v14
	v_add_f32_e32 v13, v13, v15

	// Exact instruction sequence used by silu_mul_bf16_gfx1151.
	v_mov_b32_e32 v20, 0xbfb8aa3b
	v_mov_b32_e32 v21, 0x3f800000
	v_mul_f32_e32 v22, v8, v20
	v_exp_f32_e32 v22, v22
	v_add_f32_e32 v22, v21, v22
	v_rcp_f32_e32 v22, v22
	v_mul_f32_e32 v23, v8, v12
	v_mul_f32_e32 v8, v23, v22
	v_mul_f32_e32 v22, v9, v20
	v_exp_f32_e32 v22, v22
	v_add_f32_e32 v22, v21, v22
	v_rcp_f32_e32 v22, v22
	v_mul_f32_e32 v23, v9, v13
	v_mul_f32_e32 v9, v23, v22

	// BF16 round-to-nearest-even and pack two adjacent results.
	v_lshrrev_b32_e32 v22, 16, v8
	v_and_b32_e32 v22, 1, v22
	v_add_nc_u32_e32 v22, 0x7fff, v22
	v_add_nc_u32_e32 v8, v22, v8
	v_lshrrev_b32_e32 v8, 16, v8
	v_lshrrev_b32_e32 v22, 16, v9
	v_and_b32_e32 v22, 1, v22
	v_add_nc_u32_e32 v22, 0x7fff, v22
	v_add_nc_u32_e32 v9, v22, v9
	v_lshrrev_b32_e32 v9, 16, v9
	v_lshl_or_b32 v8, v9, 16, v8
	v_lshlrev_b32_e32 v2, 1, v1
	global_store_b32 v2, v8, s[6:7]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 24
		.amdhsa_next_free_sgpr 17
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
	.size mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151, .Lfunc_end0-mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: partials, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output_bf16, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 17
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
