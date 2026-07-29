// SPDX-License-Identifier: MIT
// Raw paired-group MXFP4 down projection for gfx1151.
// Two adjacent M64 groups share one expert's decoded N2048xK512 weights.
// Prototype contract: even group count and expert_ids[2*g] == expert_ids[2*g+1].
// grid=(128, group_count/2, 1), block=(32,1,1).
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.include "mxfp4_prefill_wmma_gfx1151.inc"

.macro PREFILL_ACC_TILE_SECOND AOFF C0 C1 C2 C3 C4 C5 C6 C7
  v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
  v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
  v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
  v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0
  v_add_nc_u32_e32 v13, \AOFF, v8
  global_load_b128 v[72:75], v13, s[20:21]
  global_load_b128 v[80:83], v13, s[20:21] offset:32
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

.protected mxfp4_prefill_down_pair_wmma_gfx1151
.globl mxfp4_prefill_down_pair_wmma_gfx1151
.p2align 8
.type mxfp4_prefill_down_pair_wmma_gfx1151,@function
mxfp4_prefill_down_pair_wmma_gfx1151:
  s_clause 0x1
  s_load_b128 s[4:7], s[0:1], 0
  s_load_b128 s[8:11], s[0:1], 16
  s_load_b64 s[12:13], s[0:1], 32
  s_waitcnt lgkmcnt(0)

  s_lshl_b32 s17, s3, 1
  s_lshl_b32 s19, s17, 2
  s_load_b32 s14, s[12:13], s19
  s_waitcnt lgkmcnt(0)

  s_lshl_b32 s15, s14, 19
  s_lshl_b32 s16, s14, 15
  s_lshl_b32 s24, s17, 16
  s_lshl_b32 s25, s17, 19
  s_waitcnt_depctr 0
  s_add_u32 s4, s4, s15
  s_addc_u32 s5, s5, 0
  s_add_u32 s6, s6, s16
  s_addc_u32 s7, s7, 0
  s_add_u32 s8, s8, s24
  s_addc_u32 s9, s9, 0
  s_add_u32 s20, s8, 65536
  s_addc_u32 s21, s9, 0
  s_add_u32 s10, s10, s25
  s_addc_u32 s11, s11, 0
  s_add_u32 s22, s10, 524288
  s_addc_u32 s23, s11, 0

  v_and_b32_e32 v1, 15, v0
  v_lshrrev_b32_e32 v2, 4, v0
  s_lshl_b32 s15, s2, 4
  s_waitcnt_depctr 0
  v_add_nc_u32_e32 v3, s15, v1

  v_lshlrev_b32_e32 v8, 10, v1
  v_lshl_add_u32 v8, v2, 4, v8
  v_lshl_add_u32 v9, v2, 13, v3
  v_mov_b32_e32 v10, v3

  v_mov_b32_e32 v4, 0xc0800000
  v_mov_b32_e32 v5, 0xc0804000
  v_mov_b32_e32 v6, 0x3f3f3f00
  v_mov_b32_e32 v7, 0x40404040

  .set Z0, 32
  .rept 16
    v_dual_mov_b32 v[Z0], 0 :: v_dual_mov_b32 v[Z0+1], 0
    .set Z0, Z0+2
  .endr
  .set Z1, 105
  .rept 16
    v_dual_mov_b32 v[Z1], 0 :: v_dual_mov_b32 v[Z1+1], 0
    .set Z1, Z1+2
  .endr
  s_mov_b32 s18, 16

.Lmxblock_pair:
  global_load_ubyte v104, v10, s[6:7]
  global_load_ubyte v80, v9, s[4:5]
  global_load_ubyte v81, v9, s[4:5] offset:2048
  v_add_nc_u32_e32 v14, 4096, v9
  global_load_ubyte v82, v14, s[4:5]
  global_load_ubyte v83, v14, s[4:5] offset:2048
  v_add_nc_u32_e32 v12, 16384, v9
  global_load_ubyte v84, v12, s[4:5]
  global_load_ubyte v85, v12, s[4:5] offset:2048
  v_add_nc_u32_e32 v14, 4096, v12
  global_load_ubyte v86, v14, s[4:5]
  global_load_ubyte v87, v14, s[4:5] offset:2048
  s_waitcnt vmcnt(0)

  v_lshl_or_b32 v81, v81, 8, v80
  v_lshl_or_b32 v83, v83, 8, v82
  v_lshl_or_b32 v80, v83, 16, v81
  PREFILL_DECODE_TO v80 v16 v17 v18 v19 v20 v21 v22 v23
  v_lshl_or_b32 v85, v85, 8, v84
  v_lshl_or_b32 v87, v87, 8, v86
  v_lshl_or_b32 v84, v87, 16, v85
  PREFILL_DECODE_TO v84 v24 v25 v26 v27 v28 v29 v30 v31
  s_waitcnt lgkmcnt(0)
  v_lshlrev_b32_e32 v104, 23, v104

  PREFILL_ACC_TILE 0     v32 v33 v34 v35 v36 v37 v38 v39
  PREFILL_ACC_TILE 16384 v40 v41 v42 v43 v44 v45 v46 v47
  PREFILL_ACC_TILE 32768 v48 v49 v50 v51 v52 v53 v54 v55
  PREFILL_ACC_TILE 49152 v56 v57 v58 v59 v60 v61 v62 v63
  PREFILL_ACC_TILE_SECOND 0     v105 v106 v107 v108 v109 v110 v111 v112
  PREFILL_ACC_TILE_SECOND 16384 v113 v114 v115 v116 v117 v118 v119 v120
  PREFILL_ACC_TILE_SECOND 32768 v121 v122 v123 v124 v125 v126 v127 v128
  PREFILL_ACC_TILE_SECOND 49152 v129 v130 v131 v132 v133 v134 v135 v136

  s_add_u32 s4, s4, 32768
  s_addc_u32 s5, s5, 0
  s_add_u32 s6, s6, 2048
  s_addc_u32 s7, s7, 0
  s_add_u32 s8, s8, 64
  s_addc_u32 s9, s9, 0
  s_add_u32 s20, s20, 64
  s_addc_u32 s21, s21, 0
  s_sub_u32 s18, s18, 1
  s_waitcnt_depctr 0
  s_cmp_lg_u32 s18, 0
  s_cbranch_scc1 .Lmxblock_pair

  v_lshlrev_b32_e32 v11, 2, v3
  v_lshl_add_u32 v11, v2, 16, v11
  PREFILL_STORE_TILE 8192 v32 v33 v34 v35 v36 v37 v38 v39
  v_add_nc_u32_e32 v11, 65536, v11
  PREFILL_STORE_TILE 8192 v40 v41 v42 v43 v44 v45 v46 v47
  v_add_nc_u32_e32 v11, 65536, v11
  PREFILL_STORE_TILE 8192 v48 v49 v50 v51 v52 v53 v54 v55
  v_add_nc_u32_e32 v11, 65536, v11
  PREFILL_STORE_TILE 8192 v56 v57 v58 v59 v60 v61 v62 v63

  s_mov_b32 s10, s22
  s_mov_b32 s11, s23
  v_lshlrev_b32_e32 v11, 2, v3
  v_lshl_add_u32 v11, v2, 16, v11
  PREFILL_STORE_TILE 8192 v105 v106 v107 v108 v109 v110 v111 v112
  v_add_nc_u32_e32 v11, 65536, v11
  PREFILL_STORE_TILE 8192 v113 v114 v115 v116 v117 v118 v119 v120
  v_add_nc_u32_e32 v11, 65536, v11
  PREFILL_STORE_TILE 8192 v121 v122 v123 v124 v125 v126 v127 v128
  v_add_nc_u32_e32 v11, 65536, v11
  PREFILL_STORE_TILE 8192 v129 v130 v131 v132 v133 v134 v135 v136
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6,0
.amdhsa_kernel mxfp4_prefill_down_pair_wmma_gfx1151
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
  .amdhsa_next_free_vgpr 137
  .amdhsa_next_free_sgpr 26
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
.Lend_pair: .size mxfp4_prefill_down_pair_wmma_gfx1151,.Lend_pair-mxfp4_prefill_down_pair_wmma_gfx1151
.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: packed, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: scales, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: activation_groups_m64, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output_groups_m64, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: expert_ids, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2,0]
    .max_flat_workgroup_size: 32
    .name: mxfp4_prefill_down_pair_wmma_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 28
    .sgpr_spill_count: 0
    .symbol: mxfp4_prefill_down_pair_wmma_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 137
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1,2]
...
.end_amdgpu_metadata
