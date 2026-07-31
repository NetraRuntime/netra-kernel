// SPDX-License-Identifier: MIT
//
// Experimental raw gfx1151 fused routed gate/up chunk4 compute.
// Fixed Qwen3.6 shape: selected-8, N=512, K=2048.
// Output partials are [2,16,8,512] FP32 (gate then up).
// Launch: grid=(1,128,1), block=(128,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_DOT W, A, C0, C1, C2, C3
	v_and_b32_e32 v18, 0x07070707, \W
	v_lshrrev_b32_e32 v19, 4, \W
	v_and_b32_e32 v19, 0x07070707, v19
	v_lshlrev_b32_e32 v24, 4, \W
	v_and_b32_e32 v33, 0x80808080, \W
	v_perm_b32 v20, v5, v4, v18
	v_perm_b32 v22, v5, v4, v19
	v_perm_b32 v21, v7, v6, v18
	v_perm_b32 v23, v7, v6, v19
	v_and_b32_e32 v24, 0x80808080, v24
	v_or_b32_e32 v21, v24, v21
	v_or_b32_e32 v23, v33, v23
	v_perm_b32 v25, v21, v20, 0x05010400
	v_perm_b32 v26, v21, v20, 0x07030602
	v_perm_b32 v27, v23, v22, 0x05010400
	v_perm_b32 v28, v23, v22, 0x07030602
	v_perm_b32 v29, v27, v25, 0x05040100
	v_perm_b32 v31, v27, v25, 0x07060302
	v_perm_b32 v32, v28, v26, 0x05040100
	v_perm_b32 v33, v28, v26, 0x07060302
	v_dot2_f32_bf16 \C0, v29, \A, \C0
	v_dot2_f32_bf16 \C1, v31, \A, \C1
	v_dot2_f32_bf16 \C2, v32, \A, \C2
	v_dot2_f32_bf16 \C3, v33, \A, \C3
	.endm

	.macro DECODE_TWO_ROWS GOFF, AOFF
	global_load_b32 v16, v1, s[4:5] offset:\GOFF
	global_load_b32 v38, v1, s[8:9] offset:\GOFF
	s_load_b32 s20, s[12:13], \AOFF
	global_load_b32 v17, v1, s[4:5] offset:\GOFF+512
	global_load_b32 v39, v1, s[8:9] offset:\GOFF+512
	s_load_b32 s21, s[12:13], \AOFF+4
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16, s20, v12, v13, v14, v15
	DECODE_DOT v38, s20, v34, v35, v36, v37
	DECODE_DOT v17, s21, v12, v13, v14, v15
	DECODE_DOT v39, s21, v34, v35, v36, v37
	.endm

	.protected mxfp4_decode_gate_up_chunk4_fused_gfx1151
	.globl mxfp4_decode_gate_up_chunk4_fused_gfx1151
	.p2align 8
	.type mxfp4_decode_gate_up_chunk4_fused_gfx1151,@function
mxfp4_decode_gate_up_chunk4_fused_gfx1151:
	// gate packed/scales, up packed/scales, activation, partials, expert IDs.
	s_clause 0x3
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_load_b128 s[12:15], s[0:1], 32
	s_load_b64 s[22:23], s[0:1], 48
	s_waitcnt lgkmcnt(0)

	// workgroup_id_y = selected-slot*16 + four-block chunk.
	s_and_b32 s16, s3, 15
	s_lshr_b32 s17, s3, 4
	s_lshl_b32 s18, s17, 2
	s_waitcnt_depctr 0
	s_load_b32 s26, s[22:23], s18
	s_waitcnt lgkmcnt(0)

	// Both packed tensors: expert*2^19 + chunk*2^15.
	s_lshl_b32 s18, s26, 19
	s_lshl_b32 s19, s16, 15
	s_add_u32 s18, s18, s19
	s_add_u32 s4, s4, s18
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, s18
	s_addc_u32 s9, s9, 0

	// Both scale tensors: expert*2^15 + chunk*2^11.
	s_lshl_b32 s18, s26, 15
	s_lshl_b32 s19, s16, 11
	s_add_u32 s18, s18, s19
	s_add_u32 s6, s6, s18
	s_addc_u32 s7, s7, 0
	s_add_u32 s10, s10, s18
	s_addc_u32 s11, s11, 0

	// Activation chunk and gate partial destination.
	s_lshl_b32 s18, s16, 8
	s_add_u32 s12, s12, s18
	s_addc_u32 s13, s13, 0
	s_lshl_b32 s18, s16, 14
	s_lshl_b32 s19, s17, 11
	s_add_u32 s18, s18, s19
	s_add_u32 s14, s14, s18
	s_addc_u32 s15, s15, 0
	// Up partial tensor follows the 262144-byte gate partial tensor.
	s_add_u32 s24, s14, 262144
	s_addc_u32 s25, s15, 0

	v_lshlrev_b32_e32 v1, 2, v0
	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	v_dual_mov_b32 v40, 0 :: v_dual_mov_b32 v41, 0
	v_dual_mov_b32 v42, 0 :: v_dual_mov_b32 v43, 0
	s_mov_b32 s27, 4

.Lmxblock:
	v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
	v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
	v_dual_mov_b32 v34, 0 :: v_dual_mov_b32 v35, 0
	v_dual_mov_b32 v36, 0 :: v_dual_mov_b32 v37, 0
	global_load_b32 v44, v1, s[6:7]
	global_load_b32 v45, v1, s[10:11]

	DECODE_TWO_ROWS 0, 0
	DECODE_TWO_ROWS 1024, 8
	DECODE_TWO_ROWS 2048, 16
	DECODE_TWO_ROWS 3072, 24
	s_add_u32 s4, s4, 4096
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, 4096
	s_addc_u32 s9, s9, 0
	DECODE_TWO_ROWS 0, 32
	DECODE_TWO_ROWS 1024, 40
	DECODE_TWO_ROWS 2048, 48
	DECODE_TWO_ROWS 3072, 56

	s_waitcnt vmcnt(0)
	v_bfe_u32 v31, v44, 0, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v8, v12, v31
	v_bfe_u32 v31, v44, 8, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v9, v13, v31
	v_bfe_u32 v31, v44, 16, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v10, v14, v31
	v_lshrrev_b32_e32 v31, 24, v44
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v11, v15, v31
	v_bfe_u32 v31, v45, 0, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v40, v34, v31
	v_bfe_u32 v31, v45, 8, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v41, v35, v31
	v_bfe_u32 v31, v45, 16, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v42, v36, v31
	v_lshrrev_b32_e32 v31, 24, v45
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v43, v37, v31

	s_add_u32 s4, s4, 4096
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, 4096
	s_addc_u32 s9, s9, 0
	s_add_u32 s6, s6, 512
	s_addc_u32 s7, s7, 0
	s_add_u32 s10, s10, 512
	s_addc_u32 s11, s11, 0
	s_add_u32 s12, s12, 64
	s_addc_u32 s13, s13, 0
	s_sub_u32 s27, s27, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s27, 0
	s_cbranch_scc1 .Lmxblock

	v_lshlrev_b32_e32 v2, 4, v0
	global_store_b128 v2, v[8:11], s[14:15]
	global_store_b128 v2, v[40:43], s[24:25]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_gate_up_chunk4_fused_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 46
		.amdhsa_next_free_sgpr 28
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
	.size mxfp4_decode_gate_up_chunk4_fused_gfx1151, .Lfunc_end0-mxfp4_decode_gate_up_chunk4_fused_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: gate_packed, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: gate_scales, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: up_packed, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: up_scales, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: activation, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: partials, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: expert_ids, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 56
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: mxfp4_decode_gate_up_chunk4_fused_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 28
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_gate_up_chunk4_fused_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 46
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
