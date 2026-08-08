// SPDX-License-Identifier: MIT
//
// Raw AMDGCN chunk4 gate/up reduction kernel for gfx1151.
// Fixed Qwen3.6 shape: partials=[16,8,512] FP32 and output=[8,512]
// FP32. Each partial already contains four scaled MX blocks. The reducer
// accumulates eight chunks per original K half, then performs the final add.
// Launch: grid=(2,8,1), block=(128,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.protected mxfp4_decode_gate_chunk4_reduce_gfx1151
	.globl mxfp4_decode_gate_chunk4_reduce_gfx1151
	.p2align 8
	.type mxfp4_decode_gate_chunk4_reduce_gfx1151,@function
mxfp4_decode_gate_chunk4_reduce_gfx1151:
	// Kernargs: partials, unused scales, output, unused, unused expert_ids.
	s_clause 0x2
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// partial0/output += slot*2048 bytes.
	s_lshl_b32 s14, s3, 11
	s_add_u32 s4, s4, s14
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, s14
	s_addc_u32 s9, s9, 0

	// The second original K half begins at chunk 8.
	s_add_u32 s10, s4, 131072
	s_addc_u32 s11, s5, 0

	// Two workgroups per slot; each lane owns two adjacent columns.
	s_lshl_b32 s14, s2, 8
	v_lshlrev_b32_e32 v1, 1, v0
	v_add_nc_u32_e32 v1, s14, v1
	v_lshlrev_b32_e32 v7, 2, v1
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	s_mov_b32 s16, 8

.Lreduce_chunk:
	global_load_b64 v[2:3], v7, s[4:5]
	global_load_b64 v[4:5], v7, s[10:11]
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v8, v8, v2
	v_add_f32_e32 v9, v9, v3
	v_add_f32_e32 v10, v10, v4
	v_add_f32_e32 v11, v11, v5

	s_add_u32 s4, s4, 16384
	s_addc_u32 s5, s5, 0
	s_add_u32 s10, s10, 16384
	s_addc_u32 s11, s11, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lreduce_chunk

	v_add_f32_e32 v8, v8, v10
	v_add_f32_e32 v9, v9, v11
	global_store_b64 v7, v[8:9], s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_gate_chunk4_reduce_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 34
		.amdhsa_next_free_sgpr 26
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
	.size mxfp4_decode_gate_chunk4_reduce_gfx1151, .Lfunc_end0-mxfp4_decode_gate_chunk4_reduce_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .name: packed
        .offset: 0
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .actual_access: read_only
      - .name: scales
        .offset: 8
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .actual_access: read_only
      - .name: activation
        .offset: 16
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .actual_access: read_only
      - .name: output
        .offset: 24
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .actual_access: write_only
      - .name: expert_ids
        .offset: 32
        .size: 8
        .value_kind: global_buffer
        .address_space: global
        .actual_access: read_only
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: mxfp4_decode_gate_chunk4_reduce_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 26
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_gate_chunk4_reduce_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 34
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
