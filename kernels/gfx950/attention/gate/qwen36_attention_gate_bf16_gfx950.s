// SPDX-License-Identifier: MIT
//
// Qwen3.6 full-attention output gate for gfx950:
//   out = x * bf16(sigmoid(gate))
//
// The explicit BF16 sigmoid round is required to match SGLang's deployed
// two-kernel PyTorch path.  x/out are compact [T,16,256] BF16 tensors. gate is
// a strided [T,16,256] BF16 view with head stride 512 elements and a runtime
// token stride. One wave owns one (token, head); each lane handles four values.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_attention_gate_bf16_gfx950
	.globl qwen36_attention_gate_bf16_gfx950
	.p2align 8
	.type qwen36_attention_gate_bf16_gfx950,@function
qwen36_attention_gate_bf16_gfx950:
	// Kernargs: out, x, gate, token_count, gate_token_stride_elements.
	// Preserve workgroup X before the first pointer load reuses s2.
	s_mov_b32 s18, s2
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_load_dword s8, s[0:1], 24
	s_load_dword s9, s[0:1], 28
	s_waitcnt lgkmcnt(0)

	// token = workgroup_x / 16; head = workgroup_x % 16.
	s_lshr_b32 s10, s18, 4
	s_and_b32 s11, s18, 15

	// Compact x/out row: token*8192 + head*512 bytes.
	s_lshl_b32 s12, s10, 13
	s_lshl_b32 s13, s11, 9
	s_add_u32 s12, s12, s13
	s_add_u32 s2, s2, s12
	s_addc_u32 s3, s3, 0
	s_add_u32 s4, s4, s12
	s_addc_u32 s5, s5, 0

	// Strided gate row: token*(stride_elements*2) + head*1024 bytes.
	s_lshl_b32 s14, s9, 1
	s_mul_i32 s14, s10, s14
	s_lshl_b32 s15, s11, 10
	s_add_u32 s14, s14, s15
	s_add_u32 s6, s6, s14
	s_addc_u32 s7, s7, 0

	// Four adjacent BF16 values per lane.
	v_lshlrev_b32_e32 v2, 3, v0
	global_load_dwordx2 v[4:5], v2, s[4:5]
	global_load_dwordx2 v[6:7], v2, s[6:7]
	s_waitcnt vmcnt(0)

	// BF16 x and gate -> FP32.
	v_lshlrev_b32_e32 v8, 16, v4
	v_and_b32_e32 v9, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v5
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v12, 16, v6
	v_and_b32_e32 v13, 0xffff0000, v6
	v_lshlrev_b32_e32 v14, 16, v7
	v_and_b32_e32 v15, 0xffff0000, v7

	// sigmoid(g) = rcp(1 + exp2(-log2(e)*g)).  Four independent chains give
	// gfx950 enough VALU latency coverage without scratch or LDS.
	v_mul_f32_e32 v16, 0xbfb8aa3b, v12
	v_mul_f32_e32 v17, 0xbfb8aa3b, v13
	v_mul_f32_e32 v18, 0xbfb8aa3b, v14
	v_mul_f32_e32 v19, 0xbfb8aa3b, v15
	v_exp_f32 v16, v16
	v_exp_f32 v17, v17
	v_exp_f32 v18, v18
	v_exp_f32 v19, v19
	v_add_f32_e32 v16, 1.0, v16
	v_add_f32_e32 v17, 1.0, v17
	v_add_f32_e32 v18, 1.0, v18
	v_add_f32_e32 v19, 1.0, v19
	v_rcp_f32 v16, v16
	v_rcp_f32 v17, v17
	v_rcp_f32 v18, v18
	v_rcp_f32 v19, v19

	// Preserve the eager path's materialized BF16 sigmoid boundary.
	v_cvt_pk_bf16_f32 v20, v16, v17
	v_cvt_pk_bf16_f32 v21, v18, v19
	v_lshlrev_b32_e32 v16, 16, v20
	v_and_b32_e32 v17, 0xffff0000, v20
	v_lshlrev_b32_e32 v18, 16, v21
	v_and_b32_e32 v19, 0xffff0000, v21

	v_mul_f32_e32 v8, v8, v16
	v_mul_f32_e32 v9, v9, v17
	v_mul_f32_e32 v10, v10, v18
	v_mul_f32_e32 v11, v11, v19
	v_cvt_pk_bf16_f32 v20, v8, v9
	v_cvt_pk_bf16_f32 v21, v10, v11
	global_store_dwordx2 v2, v[20:21], s[2:3]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_attention_gate_bf16_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 22
		.amdhsa_accum_offset 24
		.amdhsa_next_free_sgpr 19
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
	.end_amdhsa_kernel

	.text
.Lfunc_end0:
	.size qwen36_attention_gate_bf16_gfx950, .Lfunc_end0-qwen36_attention_gate_bf16_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_bf16, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
      - { .name: input_bf16, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: gate_bf16, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: token_count, .offset: 24, .size: 4, .value_kind: by_value }
      - { .name: gate_token_stride_elements, .offset: 28, .size: 4,
          .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_attention_gate_bf16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: qwen36_attention_gate_bf16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
