// SPDX-License-Identifier: MIT
//
// Raw gfx1151 MXFP4 speculative-verify kernel.
// Fixed Qwen3.6 expert gate/up shape: E=8, M=12, N=512, K=2048.
// Each packed weight is decoded once and reused for all twelve activation rows.
// Launch grid=(4,8,1), block=(32,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_W W
	v_and_b32_e32 v104, 0x07070707, \W
	v_lshrrev_b32_e32 v105, 4, \W
	v_and_b32_e32 v105, 0x07070707, v105
	v_lshlrev_b32_e32 v114, 4, \W
	v_and_b32_e32 v118, 0x80808080, \W
	v_perm_b32 v106, v5, v4, v104
	v_perm_b32 v108, v5, v4, v105
	v_perm_b32 v107, v7, v6, v104
	v_perm_b32 v109, v7, v6, v105
	v_and_b32_e32 v114, 0x80808080, v114
	v_or_b32_e32 v107, v114, v107
	v_or_b32_e32 v109, v118, v109
	v_perm_b32 v115, v107, v106, 0x05010400
	v_perm_b32 v116, v107, v106, 0x07030602
	v_perm_b32 v117, v109, v108, 0x05010400
	v_perm_b32 v118, v109, v108, 0x07030602
	v_perm_b32 v110, v117, v115, 0x05040100
	v_perm_b32 v111, v117, v115, 0x07060302
	v_perm_b32 v112, v118, v116, 0x05040100
	v_perm_b32 v113, v118, v116, 0x07060302
	.endm

	.macro DOT_ROW BASE, A
	v_dot2_f32_bf16 v[\BASE],   v110, \A, v[\BASE]
	v_dot2_f32_bf16 v[\BASE+1], v111, \A, v[\BASE+1]
	v_dot2_f32_bf16 v[\BASE+2], v112, \A, v[\BASE+2]
	v_dot2_f32_bf16 v[\BASE+3], v113, \A, v[\BASE+3]
	.endm

	.macro DOT12
	DOT_ROW 56,  s20
	DOT_ROW 60,  s21
	DOT_ROW 64,  s22
	DOT_ROW 68,  s23
	DOT_ROW 72,  s24
	DOT_ROW 76,  s25
	DOT_ROW 80,  s26
	DOT_ROW 84,  s27
	DOT_ROW 88,  s28
	DOT_ROW 92,  s29
	DOT_ROW 96,  s30
	DOT_ROW 100, s31
	.endm

	.macro LOAD_ACT12 KOFF
	s_load_b32 s20, s[8:9], \KOFF
	s_load_b32 s21, s[8:9], 4096+\KOFF
	s_load_b32 s22, s[8:9], 8192+\KOFF
	s_load_b32 s23, s[8:9], 12288+\KOFF
	s_load_b32 s24, s[8:9], 16384+\KOFF
	s_load_b32 s25, s[8:9], 20480+\KOFF
	s_load_b32 s26, s[8:9], 24576+\KOFF
	s_load_b32 s27, s[8:9], 28672+\KOFF
	s_load_b32 s28, s[8:9], 32768+\KOFF
	s_load_b32 s29, s[8:9], 36864+\KOFF
	s_load_b32 s30, s[8:9], 40960+\KOFF
	s_load_b32 s31, s[8:9], 45056+\KOFF
	.endm

	.macro ROW BOFF, KOFF
	global_load_b32 v119, v1, s[4:5] offset:\BOFF
	LOAD_ACT12 \KOFF
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_W v119
	DOT12
	.endm

	.macro ZERO_BLOCK
	v_dual_mov_b32 v56, 0 :: v_dual_mov_b32 v57, 0
	v_dual_mov_b32 v58, 0 :: v_dual_mov_b32 v59, 0
	v_dual_mov_b32 v60, 0 :: v_dual_mov_b32 v61, 0
	v_dual_mov_b32 v62, 0 :: v_dual_mov_b32 v63, 0
	v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
	v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
	v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
	v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0
	v_dual_mov_b32 v72, 0 :: v_dual_mov_b32 v73, 0
	v_dual_mov_b32 v74, 0 :: v_dual_mov_b32 v75, 0
	v_dual_mov_b32 v76, 0 :: v_dual_mov_b32 v77, 0
	v_dual_mov_b32 v78, 0 :: v_dual_mov_b32 v79, 0
	v_dual_mov_b32 v80, 0 :: v_dual_mov_b32 v81, 0
	v_dual_mov_b32 v82, 0 :: v_dual_mov_b32 v83, 0
	v_dual_mov_b32 v84, 0 :: v_dual_mov_b32 v85, 0
	v_dual_mov_b32 v86, 0 :: v_dual_mov_b32 v87, 0
	v_dual_mov_b32 v88, 0 :: v_dual_mov_b32 v89, 0
	v_dual_mov_b32 v90, 0 :: v_dual_mov_b32 v91, 0
	v_dual_mov_b32 v92, 0 :: v_dual_mov_b32 v93, 0
	v_dual_mov_b32 v94, 0 :: v_dual_mov_b32 v95, 0
	v_dual_mov_b32 v96, 0 :: v_dual_mov_b32 v97, 0
	v_dual_mov_b32 v98, 0 :: v_dual_mov_b32 v99, 0
	v_dual_mov_b32 v100, 0 :: v_dual_mov_b32 v101, 0
	v_dual_mov_b32 v102, 0 :: v_dual_mov_b32 v103, 0
	.endm

	.macro SCALE_COL OUT, BLK, SHIFT
	.if \SHIFT == 24
	v_lshrrev_b32_e32 v120, 24, v121
	.else
	v_bfe_u32 v120, v121, \SHIFT, 8
	.endif
	v_lshlrev_b32_e32 v120, 23, v120
	v_fmac_f32_e32 v[\OUT],    v[\BLK],    v120
	v_fmac_f32_e32 v[\OUT+4],  v[\BLK+4],  v120
	v_fmac_f32_e32 v[\OUT+8],  v[\BLK+8],  v120
	v_fmac_f32_e32 v[\OUT+12], v[\BLK+12], v120
	v_fmac_f32_e32 v[\OUT+16], v[\BLK+16], v120
	v_fmac_f32_e32 v[\OUT+20], v[\BLK+20], v120
	v_fmac_f32_e32 v[\OUT+24], v[\BLK+24], v120
	v_fmac_f32_e32 v[\OUT+28], v[\BLK+28], v120
	v_fmac_f32_e32 v[\OUT+32], v[\BLK+32], v120
	v_fmac_f32_e32 v[\OUT+36], v[\BLK+36], v120
	v_fmac_f32_e32 v[\OUT+40], v[\BLK+40], v120
	v_fmac_f32_e32 v[\OUT+44], v[\BLK+44], v120
	.endm

	.protected mxfp4_verify_gate_gfx1151
	.globl mxfp4_verify_gate_gfx1151
	.p2align 8
	.type mxfp4_verify_gate_gfx1151,@function
mxfp4_verify_gate_gfx1151:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// Expert offsets: packed 2^19, scales 2^15, output 12*512*4.
	s_lshl_b32 s12, s3, 19
	s_lshl_b32 s13, s3, 15
	s_mul_i32 s14, s3, 24576
	s_waitcnt_depctr 0
	s_add_u32 s4, s4, s12
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, s13
	s_addc_u32 s7, s7, 0
	s_add_u32 s10, s10, s14
	s_addc_u32 s11, s11, 0
	// Four one-wave N tiles per expert keep all 20 gfx1151 WGPs occupied.
	s_lshl_b32 s15, s2, 7
	v_lshlrev_b32_e32 v1, 2, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v1, s15, v1

	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040

	// Persistent output accumulators, 12 rows x 4 columns.
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
	v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
	v_dual_mov_b32 v16, 0 :: v_dual_mov_b32 v17, 0
	v_dual_mov_b32 v18, 0 :: v_dual_mov_b32 v19, 0
	v_dual_mov_b32 v20, 0 :: v_dual_mov_b32 v21, 0
	v_dual_mov_b32 v22, 0 :: v_dual_mov_b32 v23, 0
	v_dual_mov_b32 v24, 0 :: v_dual_mov_b32 v25, 0
	v_dual_mov_b32 v26, 0 :: v_dual_mov_b32 v27, 0
	v_dual_mov_b32 v28, 0 :: v_dual_mov_b32 v29, 0
	v_dual_mov_b32 v30, 0 :: v_dual_mov_b32 v31, 0
	v_dual_mov_b32 v32, 0 :: v_dual_mov_b32 v33, 0
	v_dual_mov_b32 v34, 0 :: v_dual_mov_b32 v35, 0
	v_dual_mov_b32 v36, 0 :: v_dual_mov_b32 v37, 0
	v_dual_mov_b32 v38, 0 :: v_dual_mov_b32 v39, 0
	v_dual_mov_b32 v40, 0 :: v_dual_mov_b32 v41, 0
	v_dual_mov_b32 v42, 0 :: v_dual_mov_b32 v43, 0
	v_dual_mov_b32 v44, 0 :: v_dual_mov_b32 v45, 0
	v_dual_mov_b32 v46, 0 :: v_dual_mov_b32 v47, 0
	v_dual_mov_b32 v48, 0 :: v_dual_mov_b32 v49, 0
	v_dual_mov_b32 v50, 0 :: v_dual_mov_b32 v51, 0
	v_dual_mov_b32 v52, 0 :: v_dual_mov_b32 v53, 0
	v_dual_mov_b32 v54, 0 :: v_dual_mov_b32 v55, 0
	s_mov_b32 s32, 64

.Lmxblock:
	ZERO_BLOCK
	global_load_b32 v121, v1, s[6:7]
	ROW 0,    0
	ROW 512,  4
	ROW 1024, 8
	ROW 1536, 12
	ROW 2048, 16
	ROW 2560, 20
	ROW 3072, 24
	ROW 3584, 28
	s_add_u32 s4, s4, 4096
	s_addc_u32 s5, s5, 0
	s_waitcnt_depctr 0
	ROW 0,    32
	ROW 512,  36
	ROW 1024, 40
	ROW 1536, 44
	ROW 2048, 48
	ROW 2560, 52
	ROW 3072, 56
	ROW 3584, 60
	s_add_u32 s4, s4, 4096
	s_addc_u32 s5, s5, 0

	s_waitcnt vmcnt(0)
	SCALE_COL 8,  56,  0
	SCALE_COL 9,  57,  8
	SCALE_COL 10, 58, 16
	SCALE_COL 11, 59, 24
	s_add_u32 s6, s6, 512
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, 64
	s_addc_u32 s9, s9, 0
	s_sub_u32 s32, s32, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s32, 0
	s_cbranch_scc1 .Lmxblock

	// Direct [expert, M, N] output stores.
	s_lshl_b32 s15, s2, 9
	v_lshlrev_b32_e32 v2, 4, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v2, s15, v2
	.macro STORE_ROW BASE
	global_store_b32 v2, v[\BASE], s[10:11]
	global_store_b32 v2, v[\BASE+1], s[10:11] offset:4
	global_store_b32 v2, v[\BASE+2], s[10:11] offset:8
	global_store_b32 v2, v[\BASE+3], s[10:11] offset:12
	v_add_nc_u32_e32 v2, 2048, v2
	.endm
	STORE_ROW 8
	STORE_ROW 12
	STORE_ROW 16
	STORE_ROW 20
	STORE_ROW 24
	STORE_ROW 28
	STORE_ROW 32
	STORE_ROW 36
	STORE_ROW 40
	STORE_ROW 44
	STORE_ROW 48
	STORE_ROW 52
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_verify_gate_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 122
		.amdhsa_next_free_sgpr 33
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
	.size mxfp4_verify_gate_gfx1151, .Lfunc_end0-mxfp4_verify_gate_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: packed, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: scales, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: mxfp4_verify_gate_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 35
    .sgpr_spill_count: 0
    .symbol: mxfp4_verify_gate_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 122
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
