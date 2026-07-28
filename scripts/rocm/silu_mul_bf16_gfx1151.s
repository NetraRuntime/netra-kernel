// SPDX-License-Identifier: MIT
// Raw gfx1151 epilogue for 4096 values: bf16(silu(gate_f32) * up_f32).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text
	.protected silu_mul_bf16_gfx1151
	.globl silu_mul_bf16_gfx1151
	.p2align 8
	.type silu_mul_bf16_gfx1151,@function
silu_mul_bf16_gfx1151:
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b64 s[8:9], s[0:1], 16
	s_lshl_b32 s10, s2, 10
	s_waitcnt lgkmcnt(0)
	v_lshlrev_b32_e32 v1, 2, v0
	v_add_nc_u32_e32 v1, s10, v1
	global_load_b32 v2, v1, s[4:5]
	global_load_b32 v3, v1, s[6:7]
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v4, 0xbfb8aa3b
	v_mov_b32_e32 v5, 0x3f800000
	v_mul_f32_e32 v6, v2, v4
	v_exp_f32_e32 v6, v6
	v_add_f32_e32 v6, v5, v6
	v_rcp_f32_e32 v6, v6
	v_mul_f32_e32 v7, v2, v3
	v_mul_f32_e32 v2, v7, v6
	v_lshrrev_b32_e32 v6, 16, v2
	v_and_b32_e32 v6, 1, v6
	v_add_nc_u32_e32 v6, 0x7fff, v6
	v_add_nc_u32_e32 v2, v6, v2
	v_lshrrev_b32_e32 v2, 16, v2
	v_lshrrev_b32_e32 v1, 1, v1
	global_store_short v1, v2, s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel silu_mul_bf16_gfx1151
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
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 11
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_workgroup_processor_mode 1
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size silu_mul_bf16_gfx1151, .Lfunc_end0-silu_mul_bf16_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: gate_f32, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: up_f32, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: output_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: silu_mul_bf16_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 13
    .sgpr_spill_count: 0
    .symbol: silu_mul_bf16_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 8
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
