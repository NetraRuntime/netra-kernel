// SPDX-License-Identifier: MIT
//
// Raw gfx1151 M12 routed-group fused gate+up WMMA specialization.
// Qwen3.6: N=512, K=2048, group storage stride=64 rows.
// Launch grid=(32,group_count,1), block=(32,1,1).
//
// One wave computes both gate and up for one expert and contains at most twelve valid rows for an
// M12 decode batch. Compute/store rows 0..11 and preserve the production
// [group,64,*] strides so routing and reduction buffers remain unchanged.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_LOCAL W
	// Input bytes are four adjacent K-pairs for one output column.
	v_and_b32_e32 v49, 0x07070707, \W
	v_lshrrev_b32_e32 v50, 4, \W
	v_and_b32_e32 v50, 0x07070707, v50
	v_lshlrev_b32_e32 v55, 4, \W
	v_and_b32_e32 v59, 0x80808080, \W
	v_perm_b32 v51, v5, v4, v49
	v_perm_b32 v53, v5, v4, v50
	v_perm_b32 v52, v7, v6, v49
	v_perm_b32 v54, v7, v6, v50
	v_and_b32_e32 v55, 0x80808080, v55
	v_or_b32_e32 v52, v55, v52
	v_or_b32_e32 v54, v59, v54
	v_perm_b32 v56, v52, v51, 0x05010400
	v_perm_b32 v57, v52, v51, 0x07030602
	v_perm_b32 v58, v54, v53, 0x05010400
	v_perm_b32 v59, v54, v53, 0x07030602
	v_perm_b32 v24, v58, v56, 0x05040100
	v_perm_b32 v25, v58, v56, 0x07060302
	v_perm_b32 v26, v59, v57, 0x05040100
	v_perm_b32 v27, v59, v57, 0x07060302
	.endm

.macro LOAD_FUSED_HALF AEXTRA GBASE UBASE
// One activation transaction feeds both gate and up WMMAs.
global_load_b128 v[16:19], v8, s[12:13] offset:\AEXTRA
global_load_ubyte v48, \GBASE, s[4:5]
global_load_ubyte v49, \GBASE, s[4:5] offset:512
global_load_ubyte v50, \GBASE, s[4:5] offset:1024
global_load_ubyte v51, \GBASE, s[4:5] offset:1536
global_load_ubyte v83, \UBASE, s[8:9]
global_load_ubyte v84, \UBASE, s[8:9] offset:512
global_load_ubyte v85, \UBASE, s[8:9] offset:1024
global_load_ubyte v86, \UBASE, s[8:9] offset:1536
s_waitcnt vmcnt(0)
ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
v_lshl_or_b32 v49, v49, 8, v48
v_lshl_or_b32 v51, v51, 8, v50
v_lshl_or_b32 v48, v51, 16, v49
DECODE_LOCAL v48
ds_swizzle_b32 v28, v24 offset:swizzle(SWAP,16)
ds_swizzle_b32 v29, v25 offset:swizzle(SWAP,16)
ds_swizzle_b32 v30, v26 offset:swizzle(SWAP,16)
ds_swizzle_b32 v31, v27 offset:swizzle(SWAP,16)
s_waitcnt lgkmcnt(0)
v_wmma_f32_16x16x16_bf16 v[40:47], v[16:23], v[24:31], v[40:47]
v_lshl_or_b32 v84, v84, 8, v83
v_lshl_or_b32 v86, v86, 8, v85
v_lshl_or_b32 v48, v86, 16, v84
DECODE_LOCAL v48
ds_swizzle_b32 v28, v24 offset:swizzle(SWAP,16)
ds_swizzle_b32 v29, v25 offset:swizzle(SWAP,16)
ds_swizzle_b32 v30, v26 offset:swizzle(SWAP,16)
ds_swizzle_b32 v31, v27 offset:swizzle(SWAP,16)
s_waitcnt lgkmcnt(0)
v_wmma_f32_16x16x16_bf16 v[73:80], v[16:23], v[24:31], v[73:80]
.endm

	.protected mxfp4_m12_group_gate_up_wmma_gfx1151
	.globl mxfp4_m12_group_gate_up_wmma_gfx1151
	.p2align 8
	.type mxfp4_m12_group_gate_up_wmma_gfx1151,@function
mxfp4_m12_group_gate_up_wmma_gfx1151:
s_clause 0x3
s_load_b128 s[4:7], s[0:1], 0
s_load_b128 s[8:11], s[0:1], 16
s_load_b128 s[12:15], s[0:1], 32
s_load_b128 s[16:19], s[0:1], 48
s_waitcnt lgkmcnt(0)

// Load this group's routed expert ID, then form expert and group strides.
s_lshl_b32 s21, s3, 2
s_waitcnt_depctr 0
s_load_b32 s20, s[14:15], s21
s_waitcnt lgkmcnt(0)
s_lshl_b32 s22, s20, 19
s_lshl_b32 s23, s20, 15
s_lshl_b32 s24, s3, 18
s_lshl_b32 s25, s3, 17
s_waitcnt_depctr 0
s_add_u32 s4, s4, s22
s_addc_u32 s5, s5, 0
s_add_u32 s6, s6, s23
s_addc_u32 s7, s7, 0
s_add_u32 s8, s8, s22
s_addc_u32 s9, s9, 0
s_add_u32 s10, s10, s23
s_addc_u32 s11, s11, 0
s_add_u32 s12, s12, s24
s_addc_u32 s13, s13, 0
s_add_u32 s16, s16, s25
s_addc_u32 s17, s17, 0
s_add_u32 s18, s18, s25
s_addc_u32 s19, s19, 0

// lane column, subgroup, and global output column.
	v_and_b32_e32 v1, 15, v0
	v_lshrrev_b32_e32 v2, 4, v0
	s_lshl_b32 s15, s2, 4
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v3, s15, v1

	// A local address: row*(2048*2) + subgroup*8*2.
	v_lshlrev_b32_e32 v8, 12, v1
	v_lshl_add_u32 v8, v2, 4, v8

	// Packed-weight local address: column + subgroup*4 packed rows*512.
	v_lshl_add_u32 v9, v2, 11, v3

	// Scale local address is the output column (subgroups intentionally duplicate).
	v_mov_b32_e32 v10, v3

	// Exact E2M1 BF16 byte lookup tables.
	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040

// Persistent accumulators for gate and up.
v_dual_mov_b32 v32, 0 :: v_dual_mov_b32 v33, 0
v_dual_mov_b32 v34, 0 :: v_dual_mov_b32 v35, 0
v_dual_mov_b32 v36, 0 :: v_dual_mov_b32 v37, 0
v_dual_mov_b32 v38, 0 :: v_dual_mov_b32 v39, 0
v_dual_mov_b32 v65, 0 :: v_dual_mov_b32 v66, 0
v_dual_mov_b32 v67, 0 :: v_dual_mov_b32 v68, 0
v_dual_mov_b32 v69, 0 :: v_dual_mov_b32 v70, 0
v_dual_mov_b32 v71, 0 :: v_dual_mov_b32 v72, 0
s_mov_b32 s26, 64

.Lmxblock:
v_dual_mov_b32 v40, 0 :: v_dual_mov_b32 v41, 0
v_dual_mov_b32 v42, 0 :: v_dual_mov_b32 v43, 0
v_dual_mov_b32 v44, 0 :: v_dual_mov_b32 v45, 0
v_dual_mov_b32 v46, 0 :: v_dual_mov_b32 v47, 0
v_dual_mov_b32 v73, 0 :: v_dual_mov_b32 v74, 0
v_dual_mov_b32 v75, 0 :: v_dual_mov_b32 v76, 0
v_dual_mov_b32 v77, 0 :: v_dual_mov_b32 v78, 0
v_dual_mov_b32 v79, 0 :: v_dual_mov_b32 v80, 0
global_load_ubyte v63, v10, s[6:7]
global_load_ubyte v81, v10, s[10:11]

LOAD_FUSED_HALF 0 v9 v9
v_add_nc_u32_e32 v12, 4096, v9
LOAD_FUSED_HALF 32 v12 v12

s_waitcnt vmcnt(0)
v_lshlrev_b32_e32 v64, 23, v63
v_lshlrev_b32_e32 v82, 23, v81
v_fmac_f32_e32 v32, v40, v64
v_fmac_f32_e32 v33, v41, v64
v_fmac_f32_e32 v34, v42, v64
v_fmac_f32_e32 v35, v43, v64
v_fmac_f32_e32 v36, v44, v64
v_fmac_f32_e32 v37, v45, v64
v_fmac_f32_e32 v38, v46, v64
v_fmac_f32_e32 v39, v47, v64
v_fmac_f32_e32 v65, v73, v82
v_fmac_f32_e32 v66, v74, v82
v_fmac_f32_e32 v67, v75, v82
v_fmac_f32_e32 v68, v76, v82
v_fmac_f32_e32 v69, v77, v82
v_fmac_f32_e32 v70, v78, v82
v_fmac_f32_e32 v71, v79, v82
v_fmac_f32_e32 v72, v80, v82

s_add_u32 s4, s4, 8192
s_addc_u32 s5, s5, 0
s_add_u32 s6, s6, 512
s_addc_u32 s7, s7, 0
s_add_u32 s8, s8, 8192
s_addc_u32 s9, s9, 0
s_add_u32 s10, s10, 512
s_addc_u32 s11, s11, 0
s_add_u32 s12, s12, 64
s_addc_u32 s13, s13, 0
s_sub_u32 s26, s26, 1
s_waitcnt_depctr 0
s_cmp_lg_u32 s26, 0
s_cbranch_scc1 .Lmxblock

// Gate accumulator-to-row-major transform and store.
ds_swizzle_b32 v16, v36 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v20, v32 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v17, v37 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v21, v33 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v18, v38 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v22, v34 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v19, v39 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v23, v35 offset:swizzle(ROTATE,1,16)
s_waitcnt lgkmcnt(0)
v_mov_b32_dpp v16, v32 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v36, v20 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v17, v33 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v37, v21 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v18, v34 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v38, v22 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v19, v35 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v39, v23 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_lshlrev_b32_e32 v11, 2, v3
v_lshl_add_u32 v11, v2, 14, v11
global_store_b32 v11, v16, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v36, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v17, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v37, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
s_mov_b32 s30, exec_lo
v_cmpx_eq_u32_e32 0, v2
global_store_b32 v11, v18, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v38, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v19, s[16:17]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v39, s[16:17]
s_mov_b32 exec_lo, s30

// Up accumulator-to-row-major transform reuses gate accumulator registers.
ds_swizzle_b32 v16, v69 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v20, v65 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v17, v70 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v21, v66 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v18, v71 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v22, v67 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v19, v72 offset:swizzle(ROTATE,1,16)
ds_swizzle_b32 v23, v68 offset:swizzle(ROTATE,1,16)
s_waitcnt lgkmcnt(0)
v_mov_b32_dpp v16, v65 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v69, v20 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v17, v66 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v70, v21 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v18, v67 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v71, v22 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v19, v68 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_mov_b32_dpp v72, v23 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
v_lshlrev_b32_e32 v11, 2, v3
v_lshl_add_u32 v11, v2, 14, v11
global_store_b32 v11, v16, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v69, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v17, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v70, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
s_mov_b32 s30, exec_lo
v_cmpx_eq_u32_e32 0, v2
global_store_b32 v11, v18, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v71, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v19, s[18:19]
v_add_nc_u32_e32 v11, 2048, v11
global_store_b32 v11, v72, s[18:19]
s_mov_b32 exec_lo, s30
s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_m12_group_gate_up_wmma_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 64
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 87
		.amdhsa_next_free_sgpr 31
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
	.size mxfp4_m12_group_gate_up_wmma_gfx1151, .Lfunc_end0-mxfp4_m12_group_gate_up_wmma_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: gate_packed, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: gate_scales, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: up_packed, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: up_scales, .offset: 24, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation_groups_m64, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: expert_ids, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: gate_output_groups_m64, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: up_output_groups_m64, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: mxfp4_m12_group_gate_up_wmma_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 33
    .sgpr_spill_count: 0
    .symbol: mxfp4_m12_group_gate_up_wmma_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 87
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
