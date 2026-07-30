// SPDX-License-Identifier: MIT
//
// Qwen3.6 decode/verification shared-expert routing tail:
//   BF16 hidden [rows,2048], BF16 shared-gate weight [1,2048],
//   routed IDs int32 [rows,8], routed weights FP32 [rows,8]
//     -> copy routed entries, append shared ID 256 and
//        FP32(BF16(sigmoid(BF16(dot(hidden, weight))))).
//
// Grid Y selects an independent row. One wave64 performs sixteen packed BF16
// dot steps per lane. The deployed torch linear materializes a BF16 logit
// before its BF16 sigmoid, so both rounding boundaries are explicit.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_shared_gate_append_m1_gfx950
	.globl qwen36_shared_gate_append_m1_gfx950
	.p2align 8
	.type qwen36_shared_gate_append_m1_gfx950,@function
qwen36_shared_gate_append_m1_gfx950:
	// Kernargs: output IDs, output weights, hidden, shared-gate weight,
	// routed IDs, routed weights.
	// Workgroup ID Y arrives in s2 after the kernarg pointer. Preserve it
	// before loading the first output pointer into the same SGPR pair.
	s_mov_b32 s16, s2
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_load_dwordx2 s[8:9], s[0:1], 24
	s_load_dwordx2 s[10:11], s[0:1], 32
	s_load_dwordx2 s[12:13], s[0:1], 40
	s_waitcnt lgkmcnt(0)

	// Advance every row-major tensor pointer. The shared-gate weight is
	// common to all rows and remains unchanged.
	s_mul_i32 s17, s16, 36
	s_add_u32 s2, s2, s17
	s_addc_u32 s3, s3, 0
	s_add_u32 s4, s4, s17
	s_addc_u32 s5, s5, 0
	s_lshl_b32 s17, s16, 12
	s_add_u32 s6, s6, s17
	s_addc_u32 s7, s7, 0
	s_lshl_b32 s17, s16, 5
	s_add_u32 s10, s10, s17
	s_addc_u32 s11, s11, 0
	s_add_u32 s12, s12, s17
	s_addc_u32 s13, s13, 0

	// Preserve the eight routed entries byte-for-byte.
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_and_saveexec_b64 s[14:15], vcc
	v_lshlrev_b32_e32 v1, 2, v0
	global_load_dword v2, v1, s[10:11]
	global_load_dword v3, v1, s[12:13]
	s_waitcnt vmcnt(0)
	global_store_dword v1, v2, s[2:3]
	global_store_dword v1, v3, s[4:5]
	s_or_b64 exec, exec, s[14:15]

	// Interleaved packed loads are contiguous across wave64. Each instruction
	// covers 128 BF16 values; sixteen cover the 2,048-element dot product.
	v_lshlrev_b32_e32 v1, 2, v0
	global_load_dword v2, v1, s[6:7] offset:0
	global_load_dword v18, v1, s[8:9] offset:0
	global_load_dword v3, v1, s[6:7] offset:256
	global_load_dword v19, v1, s[8:9] offset:256
	global_load_dword v4, v1, s[6:7] offset:512
	global_load_dword v20, v1, s[8:9] offset:512
	global_load_dword v5, v1, s[6:7] offset:768
	global_load_dword v21, v1, s[8:9] offset:768
	global_load_dword v6, v1, s[6:7] offset:1024
	global_load_dword v22, v1, s[8:9] offset:1024
	global_load_dword v7, v1, s[6:7] offset:1280
	global_load_dword v23, v1, s[8:9] offset:1280
	global_load_dword v8, v1, s[6:7] offset:1536
	global_load_dword v24, v1, s[8:9] offset:1536
	global_load_dword v9, v1, s[6:7] offset:1792
	global_load_dword v25, v1, s[8:9] offset:1792
	global_load_dword v10, v1, s[6:7] offset:2048
	global_load_dword v26, v1, s[8:9] offset:2048
	global_load_dword v11, v1, s[6:7] offset:2304
	global_load_dword v27, v1, s[8:9] offset:2304
	global_load_dword v12, v1, s[6:7] offset:2560
	global_load_dword v28, v1, s[8:9] offset:2560
	global_load_dword v13, v1, s[6:7] offset:2816
	global_load_dword v29, v1, s[8:9] offset:2816
	global_load_dword v14, v1, s[6:7] offset:3072
	global_load_dword v30, v1, s[8:9] offset:3072
	global_load_dword v15, v1, s[6:7] offset:3328
	global_load_dword v31, v1, s[8:9] offset:3328
	global_load_dword v16, v1, s[6:7] offset:3584
	global_load_dword v32, v1, s[8:9] offset:3584
	global_load_dword v17, v1, s[6:7] offset:3840
	global_load_dword v33, v1, s[8:9] offset:3840
	s_waitcnt vmcnt(0)

	v_mov_b32_e32 v34, 0
	v_dot2_f32_bf16 v34, v2, v18, v34
	v_dot2_f32_bf16 v34, v3, v19, v34
	v_dot2_f32_bf16 v34, v4, v20, v34
	v_dot2_f32_bf16 v34, v5, v21, v34
	v_dot2_f32_bf16 v34, v6, v22, v34
	v_dot2_f32_bf16 v34, v7, v23, v34
	v_dot2_f32_bf16 v34, v8, v24, v34
	v_dot2_f32_bf16 v34, v9, v25, v34
	v_dot2_f32_bf16 v34, v10, v26, v34
	v_dot2_f32_bf16 v34, v11, v27, v34
	v_dot2_f32_bf16 v34, v12, v28, v34
	v_dot2_f32_bf16 v34, v13, v29, v34
	v_dot2_f32_bf16 v34, v14, v30, v34
	v_dot2_f32_bf16 v34, v15, v31, v34
	v_dot2_f32_bf16 v34, v16, v32, v34
	v_dot2_f32_bf16 v34, v17, v33, v34

	// A full-wave XOR tree avoids the row-boundary semantics of DPP broadcasts.
	v_and_b32_e32 v36, 63, v0
	v_xor_b32_e32 v35, 1, v36
	v_lshlrev_b32_e32 v35, 2, v35
	ds_bpermute_b32 v35, v35, v34
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v34, v34, v35
	v_xor_b32_e32 v35, 2, v36
	v_lshlrev_b32_e32 v35, 2, v35
	ds_bpermute_b32 v35, v35, v34
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v34, v34, v35
	v_xor_b32_e32 v35, 4, v36
	v_lshlrev_b32_e32 v35, 2, v35
	ds_bpermute_b32 v35, v35, v34
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v34, v34, v35
	v_xor_b32_e32 v35, 8, v36
	v_lshlrev_b32_e32 v35, 2, v35
	ds_bpermute_b32 v35, v35, v34
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v34, v34, v35
	v_xor_b32_e32 v35, 16, v36
	v_lshlrev_b32_e32 v35, 2, v35
	ds_bpermute_b32 v35, v35, v34
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v34, v34, v35
	v_xor_b32_e32 v35, 32, v36
	v_lshlrev_b32_e32 v35, 2, v35
	ds_bpermute_b32 v35, v35, v34
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v34, v34, v35

	// Lane 63 owns the complete dot and the ninth output slot.
	v_cmp_eq_u32_e32 vcc, 63, v36
	s_and_saveexec_b64 s[14:15], vcc

	// Round the linear output to BF16, then expand it for sigmoid.
	v_cvt_pk_bf16_f32 v37, v34, v34
	v_lshlrev_b32_e32 v38, 16, v37

	// sigmoid(x) = 1 / (1 + exp(-x)); v_exp consumes a base-2 exponent.
	v_mov_b32_e32 v39, 0xbfb8aa3b
	v_mul_f32_e32 v38, v39, v38
	v_exp_f32_e32 v38, v38
	s_nop 3
	v_add_f32_e32 v38, 1.0, v38
	v_rcp_f32_e32 v38, v38
	s_nop 3

	// Match the deployed BF16 sigmoid result, expanded exactly to FP32.
	v_cvt_pk_bf16_f32 v37, v38, v38
	v_lshlrev_b32_e32 v38, 16, v37
	v_mov_b32_e32 v40, 32
	v_mov_b32_e32 v41, 256
	global_store_dword v40, v41, s[2:3]
	global_store_dword v40, v38, s[4:5]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_shared_gate_append_m1_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 0
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 42
		.amdhsa_accum_offset 44
		.amdhsa_next_free_sgpr 18
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_shared_gate_append_m1_gfx950, .Lfunc_end0-qwen36_shared_gate_append_m1_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_ids_i32, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: output_weights_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: hidden_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: shared_gate_weight_bf16, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: routed_ids_i32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: routed_weights_f32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_shared_gate_append_m1_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 16
    .sgpr_spill_count: 0
    .symbol: qwen36_shared_gate_append_m1_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 42
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
