// SPDX-License-Identifier: MIT
//
// Raw grouped MXFP4 prefill for gfx1151.
// Rejected measured experiment: paired A-tile prefetch reuses decode scratch
// VGPRs and preserves FP64 accuracy, but measured 4.01% slower at the real
// 1,276-group gfx1151 shape. Retained only as a reproducible negative result.
//
// Qwen3.6 expert gate/up: N=512, K=2048, 64 padded rows per group.
//
// grid=(32, group_count, 1), block=(32,1,1). expert_ids[group] chooses
// the checkpoint expert. A and C are group-major [group,64,K/N].
// Each wave decodes B once and reuses it across four 16-row WMMA tiles.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_TO W O0 O1 O2 O3 U0 U1 U2 U3
	v_and_b32_e32 v88, 0x07070707, \W
	v_lshrrev_b32_e32 v89, 4, \W
	v_and_b32_e32 v89, 0x07070707, v89
	v_lshlrev_b32_e32 v90, 4, \W
	v_and_b32_e32 v91, 0x80808080, \W
	v_perm_b32 v92, v5, v4, v88
	v_perm_b32 v93, v5, v4, v89
	v_perm_b32 v94, v7, v6, v88
	v_perm_b32 v95, v7, v6, v89
	v_and_b32_e32 v90, 0x80808080, v90
	v_or_b32_e32 v94, v90, v94
	v_or_b32_e32 v95, v91, v95
	v_perm_b32 v96, v94, v92, 0x05010400
	v_perm_b32 v97, v94, v92, 0x07030602
	v_perm_b32 v98, v95, v93, 0x05010400
	v_perm_b32 v99, v95, v93, 0x07030602
	v_perm_b32 \O0, v98, v96, 0x05040100
	v_perm_b32 \O1, v98, v96, 0x07060302
	v_perm_b32 \O2, v99, v97, 0x05040100
	v_perm_b32 \O3, v99, v97, 0x07060302
	ds_swizzle_b32 \U0, \O0 offset:swizzle(SWAP,16)
	ds_swizzle_b32 \U1, \O1 offset:swizzle(SWAP,16)
	ds_swizzle_b32 \U2, \O2 offset:swizzle(SWAP,16)
	ds_swizzle_b32 \U3, \O3 offset:swizzle(SWAP,16)
	.endm

	.macro ACC_TILE AOFF C0 C1 C2 C3 C4 C5 C6 C7
	v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
	v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
	v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
	v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0
	v_add_nc_u32_e32 v13, \AOFF, v8
	global_load_b128 v[72:75], v13, s[8:9]
	global_load_b128 v[80:83], v13, s[8:9] offset:32
	s_waitcnt vmcnt(0)
	ds_swizzle_b32 v76, v72 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v77, v73 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v78, v74 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v79, v75 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v84, v80 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v85, v81 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v86, v82 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v87, v83 offset:swizzle(SWAP,16)
	s_waitcnt lgkmcnt(0)
	v_wmma_f32_16x16x16_bf16 v[64:71], v[72:79], v[16:23], v[64:71]
	v_wmma_f32_16x16x16_bf16 v[64:71], v[80:87], v[24:31], v[64:71]
	v_fmac_f32_e32 \C0, v64, v104
	v_fmac_f32_e32 \C1, v65, v104
	v_fmac_f32_e32 \C2, v66, v104
	v_fmac_f32_e32 \C3, v67, v104
	v_fmac_f32_e32 \C4, v68, v104
	v_fmac_f32_e32 \C5, v69, v104
	v_fmac_f32_e32 \C6, v70, v104
	v_fmac_f32_e32 \C7, v71, v104
	.endm


.macro ACC_TILE_PAIR AOFF0 C0 C1 C2 C3 C4 C5 C6 C7 AOFF1 D0 D1 D2 D3 D4 D5 D6 D7
v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0
v_add_nc_u32_e32 v13, \AOFF0, v8
global_load_b128 v[72:75], v13, s[8:9]
global_load_b128 v[80:83], v13, s[8:9] offset:32
v_add_nc_u32_e32 v14, \AOFF1, v8
global_load_b128 v[88:91], v14, s[8:9]
global_load_b128 v[96:99], v14, s[8:9] offset:32
s_waitcnt vmcnt(2)
ds_swizzle_b32 v76, v72 offset:swizzle(SWAP,16)
ds_swizzle_b32 v77, v73 offset:swizzle(SWAP,16)
ds_swizzle_b32 v78, v74 offset:swizzle(SWAP,16)
ds_swizzle_b32 v79, v75 offset:swizzle(SWAP,16)
ds_swizzle_b32 v84, v80 offset:swizzle(SWAP,16)
ds_swizzle_b32 v85, v81 offset:swizzle(SWAP,16)
ds_swizzle_b32 v86, v82 offset:swizzle(SWAP,16)
ds_swizzle_b32 v87, v83 offset:swizzle(SWAP,16)
s_waitcnt lgkmcnt(0)
v_wmma_f32_16x16x16_bf16 v[64:71], v[72:79], v[16:23], v[64:71]
v_wmma_f32_16x16x16_bf16 v[64:71], v[80:87], v[24:31], v[64:71]
v_fmac_f32_e32 \C0, v64, v104
v_fmac_f32_e32 \C1, v65, v104
v_fmac_f32_e32 \C2, v66, v104
v_fmac_f32_e32 \C3, v67, v104
v_fmac_f32_e32 \C4, v68, v104
v_fmac_f32_e32 \C5, v69, v104
v_fmac_f32_e32 \C6, v70, v104
v_fmac_f32_e32 \C7, v71, v104
s_waitcnt vmcnt(0)
ds_swizzle_b32 v92, v88 offset:swizzle(SWAP,16)
ds_swizzle_b32 v93, v89 offset:swizzle(SWAP,16)
ds_swizzle_b32 v94, v90 offset:swizzle(SWAP,16)
ds_swizzle_b32 v95, v91 offset:swizzle(SWAP,16)
ds_swizzle_b32 v100, v96 offset:swizzle(SWAP,16)
ds_swizzle_b32 v101, v97 offset:swizzle(SWAP,16)
ds_swizzle_b32 v102, v98 offset:swizzle(SWAP,16)
ds_swizzle_b32 v103, v99 offset:swizzle(SWAP,16)
s_waitcnt lgkmcnt(0)
v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0
v_wmma_f32_16x16x16_bf16 v[64:71], v[88:95], v[16:23], v[64:71]
v_wmma_f32_16x16x16_bf16 v[64:71], v[96:103], v[24:31], v[64:71]
v_fmac_f32_e32 \D0, v64, v104
v_fmac_f32_e32 \D1, v65, v104
v_fmac_f32_e32 \D2, v66, v104
v_fmac_f32_e32 \D3, v67, v104
v_fmac_f32_e32 \D4, v68, v104
v_fmac_f32_e32 \D5, v69, v104
v_fmac_f32_e32 \D6, v70, v104
v_fmac_f32_e32 \D7, v71, v104
.endm
	.macro STORE_TILE C0 C1 C2 C3 C4 C5 C6 C7
	ds_swizzle_b32 v72, \C4 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v76, \C0 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v73, \C5 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v77, \C1 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v74, \C6 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v78, \C2 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v75, \C7 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v79, \C3 offset:swizzle(ROTATE,1,16)
	s_waitcnt lgkmcnt(0)
	v_mov_b32_dpp v72, \C0 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C4, v76 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v73, \C1 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C5, v77 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v74, \C2 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C6, v78 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v75, \C3 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C7, v79 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	global_store_b32 v11, v72, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, \C4, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, v73, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, \C5, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, v74, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, \C6, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, v75, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	global_store_b32 v11, \C7, s[10:11]
	v_add_nc_u32_e32 v11, 2048, v11
	.endm

	.protected mxfp4_prefill_gate_wmma_gfx1151
	.globl mxfp4_prefill_gate_wmma_gfx1151
	.p2align 8
	.type mxfp4_prefill_gate_wmma_gfx1151,@function
mxfp4_prefill_gate_wmma_gfx1151:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_load_b64 s[12:13], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// Load the expert selected for this packed 64-row group.
	s_lshl_b32 s14, s3, 2
	s_waitcnt_depctr 0
	s_load_b32 s14, s[12:13], s14
	s_waitcnt lgkmcnt(0)

	// Expert weight offsets and group-major A/C offsets.
	s_lshl_b32 s15, s14, 19
	s_lshl_b32 s16, s14, 15
	s_lshl_b32 s17, s3, 18
	s_lshl_b32 s18, s3, 17
	s_waitcnt_depctr 0
	s_add_u32 s4, s4, s15
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, s16
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, s17
	s_addc_u32 s9, s9, 0
	s_add_u32 s10, s10, s18
	s_addc_u32 s11, s11, 0

	v_and_b32_e32 v1, 15, v0
	v_lshrrev_b32_e32 v2, 4, v0
	s_lshl_b32 s15, s2, 4
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v3, s15, v1

	// A row address within the first 16-row tile; packed B and scale columns.
	v_lshlrev_b32_e32 v8, 12, v1
	v_lshl_add_u32 v8, v2, 4, v8
	v_lshl_add_u32 v9, v2, 11, v3
	v_mov_b32_e32 v10, v3

	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040

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
	v_dual_mov_b32 v56, 0 :: v_dual_mov_b32 v57, 0
	v_dual_mov_b32 v58, 0 :: v_dual_mov_b32 v59, 0
	v_dual_mov_b32 v60, 0 :: v_dual_mov_b32 v61, 0
	v_dual_mov_b32 v62, 0 :: v_dual_mov_b32 v63, 0
	s_mov_b32 s19, 64

.Lmxblock:
	// Both K=16 B fragments and their shared scale issue together.
	global_load_ubyte v104, v10, s[6:7]
	global_load_ubyte v80, v9, s[4:5]
	global_load_ubyte v81, v9, s[4:5] offset:512
	global_load_ubyte v82, v9, s[4:5] offset:1024
	global_load_ubyte v83, v9, s[4:5] offset:1536
	v_add_nc_u32_e32 v12, 4096, v9
	global_load_ubyte v84, v12, s[4:5]
	global_load_ubyte v85, v12, s[4:5] offset:512
	global_load_ubyte v86, v12, s[4:5] offset:1024
	global_load_ubyte v87, v12, s[4:5] offset:1536
	s_waitcnt vmcnt(0)

	v_lshl_or_b32 v81, v81, 8, v80
	v_lshl_or_b32 v83, v83, 8, v82
	v_lshl_or_b32 v80, v83, 16, v81
	DECODE_TO v80 v16 v17 v18 v19 v20 v21 v22 v23
	v_lshl_or_b32 v85, v85, 8, v84
	v_lshl_or_b32 v87, v87, 8, v86
	v_lshl_or_b32 v84, v87, 16, v85
	DECODE_TO v84 v24 v25 v26 v27 v28 v29 v30 v31
	s_waitcnt lgkmcnt(0)
	v_lshlrev_b32_e32 v104, 23, v104

	ACC_TILE_PAIR 0      v32 v33 v34 v35 v36 v37 v38 v39 65536  v40 v41 v42 v43 v44 v45 v46 v47
	ACC_TILE_PAIR 131072 v48 v49 v50 v51 v52 v53 v54 v55 196608 v56 v57 v58 v59 v60 v61 v62 v63

	s_add_u32 s4, s4, 8192
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, 512
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, 64
	s_addc_u32 s9, s9, 0
	s_sub_u32 s19, s19, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s19, 0
	s_cbranch_scc1 .Lmxblock

	// Subgroup 0 starts at row 0 and subgroup 1 at row 8.
	v_lshlrev_b32_e32 v11, 2, v3
	v_lshl_add_u32 v11, v2, 14, v11
	STORE_TILE v32 v33 v34 v35 v36 v37 v38 v39
	v_add_nc_u32_e32 v11, 16384, v11
	STORE_TILE v40 v41 v42 v43 v44 v45 v46 v47
	v_add_nc_u32_e32 v11, 16384, v11
	STORE_TILE v48 v49 v50 v51 v52 v53 v54 v55
	v_add_nc_u32_e32 v11, 16384, v11
	STORE_TILE v56 v57 v58 v59 v60 v61 v62 v63
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_prefill_gate_wmma_gfx1151
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
		.amdhsa_next_free_vgpr 105
		.amdhsa_next_free_sgpr 20
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
	.size mxfp4_prefill_gate_wmma_gfx1151, .Lfunc_end0-mxfp4_prefill_gate_wmma_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: packed, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: scales, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation_groups_m64, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_groups_m64, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: expert_ids, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: mxfp4_prefill_gate_wmma_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 22
    .sgpr_spill_count: 0
    .symbol: mxfp4_prefill_gate_wmma_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 105
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
