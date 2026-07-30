// SPDX-License-Identifier: MIT
//
// Experimental native-CDNA4 MFMA Qwen3.6 M=1 MoE down projection.
//
// Two wave64s share each 16-column output tile. Wave 0 evaluates routed slots
// 0..4. Wave 1 evaluates slots 5..8 and writes each individually scaled K-block
// contribution to LDS. After a workgroup barrier, wave 0 consumes those
// contributions in the original slot/K order. This preserves the one-wave
// kernel's FP32 accumulation order while launching 256 waves across the 256-CU
// MI350X instead of 128.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
	.globl qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
	.p2align 8
	.type qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950,@function
qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950:
	// Kernargs: activation, activation_scale, w2, w2_scale,
	//           topk_weights, topk_ids, output.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_waitcnt lgkmcnt(0)

	// v0 is the 0..127 workitem id and v30 is the wave-local lane id.
	v_and_b32_e32 v30, 63, v0
	v_lshrrev_b32_e32 v31, 6, v0

	// lane column and K fragment:
	//   column = lane & 15
	//   fragment = (lane >> 4) * 16
	v_and_b32_e32 v1, 15, v30
	v_and_b32_e32 v2, 48, v30
	s_lshl_b32 s34, s2, 4
	v_add_u32_e32 v3, s34, v1
	v_lshlrev_b32_e32 v4, 9, v3
	v_add_u32_e32 v4, v2, v4

	v_cmp_eq_u32_e32 vcc, 0, v31
	s_cbranch_vccnz .Lwave0

	// Wave 1 computes slots 5..8. Every K-block contribution is retained
	// separately so wave 0 can reproduce the original sequential additions.
	s_mov_b32 s18, 5
.Lwave1_slot:
	s_lshl_b32 s19, s18, 2
	s_load_dword s20, s[14:15], s19
	s_load_dword s21, s[12:13], s19

	s_lshl_b32 s19, s18, 9
	s_add_u32 s22, s4, s19
	s_addc_u32 s23, s5, 0
	s_lshl_b32 s19, s18, 4
	s_add_u32 s28, s6, s19
	s_addc_u32 s29, s7, 0
	s_waitcnt lgkmcnt(0)

	s_lshl_b32 s19, s20, 20
	s_add_u32 s24, s8, s19
	s_addc_u32 s25, s9, 0
	s_lshl_b32 s19, s20, 8
	s_lshr_b32 s35, s2, 3
	s_lshl_b32 s35, s35, 4
	s_add_u32 s19, s19, s35
	s_add_u32 s26, s10, s19
	s_addc_u32 s27, s11, 0

	s_mov_b32 s32, 0
.Lwave1_kblock:
	s_lshl_b32 s33, s32, 7
	s_lshl_b32 s36, s32, 2
	s_load_dword s30, s[28:29], s36
	s_load_dword s31, s[26:27], s36

	v_add_u32_e32 v5, s33, v2
	global_load_dwordx4 v[10:13], v5, s[22:23]
	global_load_dwordx4 v[14:17], v5, s[22:23] offset:64
	v_add_u32_e32 v7, s33, v4
	global_load_dwordx4 v[18:21], v7, s[24:25]
	global_load_dwordx4 v[22:25], v7, s[24:25] offset:64
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15

	v_mul_f32_e32 v7, s30, v26
	v_mul_f32_e32 v7, s31, v7
	v_mul_f32_e32 v7, s21, v7

	// LDS layout: [slot - 5][K block][column], with 64 bytes per
	// contribution. Only the first MFMA lane group owns row zero.
	s_sub_u32 s37, s18, 5
	s_lshl_b32 s37, s37, 2
	s_add_u32 s37, s37, s32
	s_lshl_b32 s37, s37, 6
	v_lshlrev_b32_e32 v8, 2, v1
	v_add_u32_e32 v8, s37, v8
	v_cmp_gt_u32_e32 vcc, 16, v30
	s_and_saveexec_b64 s[38:39], vcc
	ds_write_b32 v8, v7
	s_or_b64 exec, exec, s[38:39]

	s_add_u32 s32, s32, 1
	s_cmp_lt_u32 s32, 4
	s_cbranch_scc1 .Lwave1_kblock

	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 9
	s_cbranch_scc1 .Lwave1_slot

	s_waitcnt lgkmcnt(0)
	s_barrier
	s_endpgm

	// Wave 0 computes slots 0..4 in the original order.
.Lwave0:
	v_mov_b32_e32 v6, 0
	s_mov_b32 s18, 0
.Lwave0_slot:
	s_lshl_b32 s19, s18, 2
	s_load_dword s20, s[14:15], s19
	s_load_dword s21, s[12:13], s19

	s_lshl_b32 s19, s18, 9
	s_add_u32 s22, s4, s19
	s_addc_u32 s23, s5, 0
	s_lshl_b32 s19, s18, 4
	s_add_u32 s28, s6, s19
	s_addc_u32 s29, s7, 0
	s_waitcnt lgkmcnt(0)

	s_lshl_b32 s19, s20, 20
	s_add_u32 s24, s8, s19
	s_addc_u32 s25, s9, 0
	s_lshl_b32 s19, s20, 8
	s_lshr_b32 s35, s2, 3
	s_lshl_b32 s35, s35, 4
	s_add_u32 s19, s19, s35
	s_add_u32 s26, s10, s19
	s_addc_u32 s27, s11, 0

	s_mov_b32 s32, 0
.Lwave0_kblock:
	s_lshl_b32 s33, s32, 7
	s_lshl_b32 s36, s32, 2
	s_load_dword s30, s[28:29], s36
	s_load_dword s31, s[26:27], s36

	v_add_u32_e32 v5, s33, v2
	global_load_dwordx4 v[10:13], v5, s[22:23]
	global_load_dwordx4 v[14:17], v5, s[22:23] offset:64
	v_add_u32_e32 v7, s33, v4
	global_load_dwordx4 v[18:21], v7, s[24:25]
	global_load_dwordx4 v[22:25], v7, s[24:25] offset:64
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15

	v_mul_f32_e32 v7, s30, v26
	v_mul_f32_e32 v7, s31, v7
	v_mul_f32_e32 v7, s21, v7
	v_add_f32_e32 v6, v6, v7

	s_add_u32 s32, s32, 1
	s_cmp_lt_u32 s32, 4
	s_cbranch_scc1 .Lwave0_kblock

	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 5
	s_cbranch_scc1 .Lwave0_slot

	// All wave-1 writes are visible after the barrier. Add them in exact
	// slot-5/K-0 through slot-8/K-3 order.
	s_barrier
	v_cmp_gt_u32_e32 vcc, 16, v30
	s_and_saveexec_b64 s[38:39], vcc
	s_mov_b32 s18, 0
.Lwave0_lds_add:
	s_lshl_b32 s19, s18, 6
	v_lshlrev_b32_e32 v8, 2, v1
	v_add_u32_e32 v8, s19, v8
	ds_read_b32 v7, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v6, v6, v7
	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 16
	s_cbranch_scc1 .Lwave0_lds_add

	v_cvt_pk_bf16_f32 v8, v6, v6
	v_lshlrev_b32_e32 v9, 1, v3
	global_store_short v9, v8, s[16:17]
	s_or_b64 exec, exec, s[38:39]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
		.amdhsa_group_segment_fixed_size 1024
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 32
		.amdhsa_accum_offset 32
		.amdhsa_next_free_sgpr 40
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950, .Lfunc_end0-qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950

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
      - { .name: w2_fp8, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: topk_weights_f32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: topk_ids_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 1024
    .kernarg_segment_align: 8
    .kernarg_segment_size: 56
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 42
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
