// SPDX-License-Identifier: MIT
//
// Raw AMDGCN exact-order gate/up reduction for gfx1151.
// Fixed Qwen3.6 shape: partials=[64,8,512] FP32, scales=[256,64,512]
// E8M0, output=[8,512] FP32, and eight selected expert IDs. The two
// 32-block accumulators and final add match the original split-K kernel.
// Launch: grid=(2,8,1), block=(128,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_DOT W, A
	// Four low-nibble magnitudes and four high-nibble magnitudes.
	v_and_b32_e32 v18, 0x07070707, \W
	v_lshrrev_b32_e32 v19, 4, \W
	v_and_b32_e32 v19, 0x07070707, v19
	v_lshlrev_b32_e32 v24, 4, \W
	v_and_b32_e32 v33, 0x80808080, \W

	// BF16 low bytes. v_perm selector 0..3 selects its second source and
	// 4..7 its first source, hence the upper-half LUT is source zero.
	v_perm_b32 v20, v5, v4, v18
	v_perm_b32 v22, v5, v4, v19

	// BF16 high bytes, then apply the E2M1 sign bit.
	v_perm_b32 v21, v7, v6, v18
	v_perm_b32 v23, v7, v6, v19
	v_and_b32_e32 v24, 0x80808080, v24
	v_or_b32_e32 v21, v24, v21
	v_or_b32_e32 v23, v33, v23

	// Interleave low/high bytes into BF16 values, initially paired by N.
	v_perm_b32 v25, v21, v20, 0x05010400
	v_perm_b32 v26, v21, v20, 0x07030602
	v_perm_b32 v27, v23, v22, 0x05010400
	v_perm_b32 v28, v23, v22, 0x07030602

	// Re-pair by K: [low-nibble weight, high-nibble weight] for each N.
	v_perm_b32 v29, v27, v25, 0x05040100
	v_perm_b32 v31, v27, v25, 0x07060302
	v_perm_b32 v32, v28, v26, 0x05040100
	v_perm_b32 v33, v28, v26, 0x07060302
	v_dot2_f32_bf16 v12, v29, \A, v12
	v_dot2_f32_bf16 v13, v31, \A, v13
	v_dot2_f32_bf16 v14, v32, \A, v14
	v_dot2_f32_bf16 v15, v33, \A, v15
	.endm

	.macro LOAD_ROW WREG, AREG, BOFF, AOFF
	global_load_b32 \WREG, v1, s[4:5] offset:\BOFF
	s_load_b32 \AREG, s[8:9], \AOFF
	.endm

	.protected mxfp4_decode_gate_block64_reduce_gfx1151
	.globl mxfp4_decode_gate_block64_reduce_gfx1151
	.p2align 8
	.type mxfp4_decode_gate_block64_reduce_gfx1151,@function
mxfp4_decode_gate_block64_reduce_gfx1151:
	// Kernargs: partials, scales, output, unused, expert_ids.
	s_clause 0x2
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_load_b64 s[22:23], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// Resolve the selected-slot global expert once per workgroup.
	s_lshl_b32 s24, s3, 2
	s_load_b32 s25, s[22:23], s24
	s_waitcnt lgkmcnt(0)

	// partial0/output += slot*2048 bytes.
	s_lshl_b32 s14, s3, 11
	s_add_u32 s4, s4, s14
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, s14
	s_addc_u32 s9, s9, 0

	// scales += global_expert*32768 bytes.
	s_lshl_b32 s14, s25, 15
	s_add_u32 s6, s6, s14
	s_addc_u32 s7, s7, 0

	// Split-1 pointers begin at MX block 32.
	s_add_u32 s10, s4, 524288
	s_addc_u32 s11, s5, 0
	s_add_u32 s12, s6, 16384
	s_addc_u32 s13, s7, 0

	// Two workgroups per slot; each lane owns two adjacent columns.
	s_lshl_b32 s14, s2, 8
	v_lshlrev_b32_e32 v1, 1, v0
	v_add_nc_u32_e32 v1, s14, v1
	v_lshlrev_b32_e32 v7, 2, v1
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	s_mov_b32 s16, 32

.Lreduce_block:
	global_load_b64 v[2:3], v7, s[4:5]
	global_load_b64 v[4:5], v7, s[10:11]
	global_load_ushort v6, v1, s[6:7]
	global_load_ushort v12, v1, s[12:13]
	s_waitcnt vmcnt(0)

	v_and_b32_e32 v13, 255, v6
	v_lshlrev_b32_e32 v13, 23, v13
	v_fmac_f32_e32 v8, v2, v13
	v_lshrrev_b32_e32 v13, 8, v6
	v_lshlrev_b32_e32 v13, 23, v13
	v_fmac_f32_e32 v9, v3, v13
	v_and_b32_e32 v13, 255, v12
	v_lshlrev_b32_e32 v13, 23, v13
	v_fmac_f32_e32 v10, v4, v13
	v_lshrrev_b32_e32 v13, 8, v12
	v_lshlrev_b32_e32 v13, 23, v13
	v_fmac_f32_e32 v11, v5, v13

	s_add_u32 s4, s4, 16384
	s_addc_u32 s5, s5, 0
	s_add_u32 s10, s10, 16384
	s_addc_u32 s11, s11, 0
	s_add_u32 s6, s6, 512
	s_addc_u32 s7, s7, 0
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lreduce_block

	v_add_f32_e32 v8, v8, v10
	v_add_f32_e32 v9, v9, v11
	global_store_b64 v7, v[8:9], s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_gate_block64_reduce_gfx1151
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
	.size mxfp4_decode_gate_block64_reduce_gfx1151, .Lfunc_end0-mxfp4_decode_gate_block64_reduce_gfx1151

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
    .name: mxfp4_decode_gate_block64_reduce_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 26
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_gate_block64_reduce_gfx1151.kd
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
