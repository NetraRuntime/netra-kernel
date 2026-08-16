// SPDX-License-Identifier: MIT
//
// Qwen3.6 expert-sorted FP8 gate/up projection for gfx950.
//
// Four wave64s compute four M16 row tiles for the same N16 expert-weight
// tile. The 256-thread workgroup cooperatively loads each 2 KiB shuffled
// weight K block once into LDS, so an M64 route block reuses weight traffic
// across all four waves. Output is BF16 in M64-sorted route order; SiLU,
// requantization, and W2 are deliberately kept outside this first stage-local
// candidate so its correctness and the dominant W13 cost can be isolated.
//
// Grid:      (64 N16 tiles, num_valid_ids / 64 route blocks, 1)
// Workgroup: (256, 1, 1), four wave64s

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_gateup_m64n16_fp8_gfx950
	.globl qwen36_moe_gateup_m64n16_fp8_gfx950
	.p2align 8
	.type qwen36_moe_gateup_m64n16_fp8_gfx950,@function
qwen36_moe_gateup_m64n16_fp8_gfx950:
	// hidden FP8, hidden scale FP32, shuffled W13 FP8, W13 scale FP32,
	// M64 sorted route IDs, compact sorted expert IDs, valid sorted count,
	// sorted-order BF16 output, token rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dword s20, s[0:1], 64
	s_load_dword s39, s[0:1], 68
	s_waitcnt lgkmcnt(0)

	// Reject graph-stable sorting capacity beyond the M64 valid span.
	s_lshl_b32 s21, s3, 6
	s_load_dword s22, s[16:17], 0
	s_lshl_b32 s23, s3, 2
	s_load_dword s23, s[14:15], s23
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s21, s22
	s_cbranch_scc0 .Lend
	s_cmp_eq_u32 s39, 1
	s_cbranch_scc1 .Lend

	// Lane/wave coordinates. Each wave owns one M16 sub-block.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s21, v5

	// Route selected by lane[3:0] supplies the native MFMA A fragment.
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[12:13]

	// Each lane owns four result rows selected by lane[5:4]. Retain their
	// sorted rows and decode their token rows for the four activation scales.
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v42, v5, v3
	v_add_u32_e32 v43, 1, v42
	v_add_u32_e32 v44, 2, v42
	v_add_u32_e32 v45, 3, v42
	v_lshlrev_b32_e32 v3, 2, v42
	global_load_dword v60, v3, s[12:13]
	global_load_dword v61, v3, s[12:13] offset:4
	global_load_dword v62, v3, s[12:13] offset:8
	global_load_dword v63, v3, s[12:13] offset:12
	s_waitcnt vmcnt(0)
	s_cmp_eq_u32 s39, 2
	s_cbranch_scc1 .Lend
	s_cmp_eq_u32 s39, 8
	s_cbranch_scc0 .Lroutes_decoded
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[40:41], vcc
	global_store_dword v6, v7, s[18:19]
	s_waitcnt vmcnt(0)
	s_or_b64 exec, exec, s[40:41]
	s_endpgm
.Lroutes_decoded:

	// Clamp padding (slot 9) to hidden row zero. Padding output is ignored.
	v_lshrrev_b32_e32 v5, 24, v4
	v_and_b32_e32 v4, 0x00ffffff, v4
	v_cmp_gt_u32_e32 vcc, s20, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v4, 0, v4, vcc

	v_lshrrev_b32_e32 v5, 24, v60
	v_and_b32_e32 v60, 0x00ffffff, v60
	v_cmp_gt_u32_e32 vcc, s20, v60
	v_cndmask_b32_e32 v60, 0, v60, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v60, 0, v60, vcc
	v_lshrrev_b32_e32 v5, 24, v61
	v_and_b32_e32 v61, 0x00ffffff, v61
	v_cmp_gt_u32_e32 vcc, s20, v61
	v_cndmask_b32_e32 v61, 0, v61, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v61, 0, v61, vcc
	v_lshrrev_b32_e32 v5, 24, v62
	v_and_b32_e32 v62, 0x00ffffff, v62
	v_cmp_gt_u32_e32 vcc, s20, v62
	v_cndmask_b32_e32 v62, 0, v62, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v62, 0, v62, vcc
	v_lshrrev_b32_e32 v5, 24, v63
	v_and_b32_e32 v63, 0x00ffffff, v63
	v_cmp_gt_u32_e32 vcc, s20, v63
	v_cndmask_b32_e32 v63, 0, v63, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v63, 0, v63, vcc

	// Compact expert bases: W13 [E,1024,2048], scales [E,8,16].
	s_lshl_b32 s26, s23, 21
	s_add_u32 s32, s8, s26
	s_addc_u32 s33, s9, 0
	s_lshl_b32 s26, s23, 9
	s_add_u32 s34, s10, s26
	s_addc_u32 s35, s11, 0

	// Hidden A fragment base and shuffled weight/LDS addressing.
	v_lshlrev_b32_e32 v46, 11, v4
	v_add_u32_e32 v46, v2, v46
	s_lshl_b32 s27, s2, 15
	v_lshlrev_b32_e32 v47, 4, v2
	v_lshlrev_b32_e32 v48, 4, v1
	v_add_u32_e32 v47, v47, v48
	v_lshlrev_b32_e32 v50, 3, v0

	// W13 scale block and output column base.
	s_lshr_b32 s28, s2, 3
	s_lshl_b32 s28, s28, 6
	s_lshl_b32 s29, s2, 4

	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	s_mov_b32 s30, 0

.Lk_loop:
	// Cooperative load covers the complete 2 KiB N16xK128 tile once.
	s_lshl_b32 s31, s30, 11
	v_add_u32_e32 v49, s27, v50
	v_add_u32_e32 v49, s31, v49
	global_load_dwordx2 v[48:49], v49, s[32:33]

	// Each wave independently loads its M16 A fragments.
	s_lshl_b32 s36, s30, 7
	v_add_u32_e32 v51, s36, v46
	global_load_dwordx4 v[8:11], v51, s[4:5]
	global_load_dwordx4 v[12:15], v51, s[4:5] offset:64

	// Four activation scales and the shared weight scale for this K block.
	s_lshl_b32 s37, s30, 2
	v_lshlrev_b32_e32 v51, 6, v60
	v_add_u32_e32 v51, s37, v51
	global_load_dword v36, v51, s[6:7]
	v_lshlrev_b32_e32 v51, 6, v61
	v_add_u32_e32 v51, s37, v51
	global_load_dword v37, v51, s[6:7]
	v_lshlrev_b32_e32 v51, 6, v62
	v_add_u32_e32 v51, s37, v51
	global_load_dword v38, v51, s[6:7]
	v_lshlrev_b32_e32 v51, 6, v63
	v_add_u32_e32 v51, s37, v51
	global_load_dword v39, v51, s[6:7]
	s_add_u32 s37, s28, s37
	s_load_dword s38, s[34:35], s37

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	s_cmp_eq_u32 s39, 3
	s_cbranch_scc1 .Lend
	ds_write_b64 v50, v[48:49]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[16:19], v47
	ds_read_b128 v[20:23], v47 offset:1024
	s_waitcnt lgkmcnt(0)
	s_cmp_eq_u32 s39, 4
	s_cbranch_scc1 .Lend

	v_mfma_f32_16x16x128_f8f6f4 v[24:27], v[8:15], v[16:23], 0
	s_nop 15
	v_mul_f32_e32 v24, s38, v24
	v_mul_f32_e32 v25, s38, v25
	v_mul_f32_e32 v26, s38, v26
	v_mul_f32_e32 v27, s38, v27
	v_fmac_f32_e32 v32, v36, v24
	v_fmac_f32_e32 v33, v37, v25
	v_fmac_f32_e32 v34, v38, v26
	v_fmac_f32_e32 v35, v39, v27
	s_cmp_eq_u32 s39, 5
	s_cbranch_scc1 .Lend

	// All waves finish reading LDS before the next cooperative overwrite.
	s_barrier
	s_nop 3
	s_cmp_eq_u32 s39, 6
	s_cbranch_scc1 .Lend
	s_cmp_eq_u32 s39, 7
	s_cbranch_scc0 .Lcontinue_k
	s_cmp_ge_u32 s30, 1
	s_cbranch_scc1 .Lend
.Lcontinue_k:
	s_cmp_ge_u32 s39, 200
	s_cbranch_scc0 .Ldebug_end_limit
	s_sub_u32 s37, s39, 200
	s_cmp_ge_u32 s30, s37
	s_cbranch_scc1 .Lstore_output
	s_branch .Ladvance_k
.Ldebug_end_limit:
	s_cmp_ge_u32 s39, 100
	s_cbranch_scc0 .Ladvance_k
	s_sub_u32 s37, s39, 100
	s_cmp_ge_u32 s30, s37
	s_cbranch_scc1 .Lend
.Ladvance_k:
	s_add_u32 s30, s30, 1
	s_cmp_lt_u32 s30, 16
	s_cbranch_scc1 .Lk_loop

.Lstore_output:
	// BF16 sorted-order output [sorted_row,1024].
	v_add_u32_e32 v51, s29, v1
	v_lshlrev_b32_e32 v51, 1, v51
	v_lshlrev_b32_e32 v52, 11, v42
	v_add_u32_e32 v52, v51, v52
	v_lshlrev_b32_e32 v53, 11, v43
	v_add_u32_e32 v53, v51, v53
	v_lshlrev_b32_e32 v54, 11, v44
	v_add_u32_e32 v54, v51, v54
	v_lshlrev_b32_e32 v55, 11, v45
	v_add_u32_e32 v55, v51, v55
	v_cvt_pk_bf16_f32 v56, v32, v33
	v_cvt_pk_bf16_f32 v57, v34, v35
	v_lshrrev_b32_e32 v58, 16, v56
	v_lshrrev_b32_e32 v59, 16, v57
	s_cmp_eq_u32 s39, 9
	s_cbranch_scc0 .Lnot_address_dump
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[40:41], vcc
	v_mov_b32_e32 v6, 0
	global_store_dword v6, v51, s[18:19]
	s_waitcnt vmcnt(0)
	s_or_b64 exec, exec, s[40:41]
	s_endpgm
.Lnot_address_dump:
	s_cmp_ge_u32 s39, 200
	s_cbranch_scc0 .Lstore_all_lanes
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[40:41], vcc
	global_store_short v52, v56, s[18:19]
	global_store_short v53, v58, s[18:19]
	global_store_short v54, v57, s[18:19]
	global_store_short v55, v59, s[18:19]
	s_waitcnt vmcnt(0)
	s_or_b64 exec, exec, s[40:41]
	s_endpgm
.Lstore_all_lanes:
	global_store_short v52, v56, s[18:19]
	global_store_short v53, v58, s[18:19]
	global_store_short v54, v57, s[18:19]
	global_store_short v55, v59, s[18:19]
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_gateup_m64n16_fp8_gfx950
		.amdhsa_group_segment_fixed_size 2048
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 72
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 64
		.amdhsa_accum_offset 64
		.amdhsa_next_free_sgpr 42
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_gateup_m64n16_fp8_gfx950, .Lfunc_end0-qwen36_moe_gateup_m64n16_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: shuffled_w13_fp8, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: compact_sorted_expert_ids_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: sorted_output_bf16, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: rows, .offset: 64, .size: 4, .value_kind: by_value }
      - { .name: debug_stage, .offset: 68, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 2048
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_gateup_m64n16_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 42
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_gateup_m64n16_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 64
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
