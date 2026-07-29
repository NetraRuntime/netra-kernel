// SPDX-License-Identifier: MIT
// Experimental raw gfx1151 GDN KKT construction, before triangular solve.
// Fixed B1,T8192,H32,Hg16,K128,BT64,BC16. Grid=(10,128,32), block=32.
// Writes the ten scaled lower-triangular 16x16 blocks to FP32 [T,H,64].

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.protected gdn_kkt_build_fp32_compiler_frag_gfx1151
.globl gdn_kkt_build_fp32_compiler_frag_gfx1151
.p2align 8
.type gdn_kkt_build_fp32_compiler_frag_gfx1151,@function
gdn_kkt_build_fp32_compiler_frag_gfx1151:
  // k,g,beta,out_fp32. s2=block-pair, s3=chunk, s4=head.
  s_clause 0x1
  s_load_b128 s[8:11], s[0:1], 0
  s_load_b128 s[12:15], s[0:1], 16
  s_waitcnt lgkmcnt(0)

  // Map x=0..9 to lower-triangular (row block, column block).
  s_mov_b32 s20, 0
  s_mov_b32 s21, 0
  s_cmp_eq_u32 s2, 0
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 1
  s_mov_b32 s21, 0
  s_cmp_eq_u32 s2, 1
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 1
  s_mov_b32 s21, 1
  s_cmp_eq_u32 s2, 2
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 2
  s_mov_b32 s21, 0
  s_cmp_eq_u32 s2, 3
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 2
  s_mov_b32 s21, 1
  s_cmp_eq_u32 s2, 4
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 2
  s_mov_b32 s21, 2
  s_cmp_eq_u32 s2, 5
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 3
  s_mov_b32 s21, 0
  s_cmp_eq_u32 s2, 6
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 3
  s_mov_b32 s21, 1
  s_cmp_eq_u32 s2, 7
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 3
  s_mov_b32 s21, 2
  s_cmp_eq_u32 s2, 8
  s_cbranch_scc1 .Lpair_done
  s_mov_b32 s20, 3
  s_mov_b32 s21, 3
.Lpair_done:
  s_lshl_b32 s22, s3, 6
  s_lshl_b32 s24, s20, 4
  s_add_u32 s22, s22, s24
  s_lshl_b32 s23, s3, 6
  s_lshl_b32 s24, s21, 4
  s_add_u32 s23, s23, s24
  s_lshr_b32 s25, s4, 1
  s_lshl_b32 s25, s25, 8
  s_cmp_gt_u32 s20, s21
  s_cselect_b32 s26, 16, 0
  s_lshl_b32 s27, s4, 8
  s_lshl_b32 s28, s21, 6

  v_and_b32_e32 v1, 31, v0
  v_and_b32_e32 v3, 15, v0
  v_lshrrev_b32_e32 v4, 4, v1
  v_and_b32_e32 v200, 15, v0
  v_lshrrev_b32_e32 v201, 4, v0

  // Reproduce Triton's direct-load WMMA fragment packing exactly.
  v_lshrrev_b32_e32 v200, 1, v1
  v_and_b32_e32 v201, 1, v1
  v_and_b32_e32 v30, 16, v1
  v_lshrrev_b32_e32 v31, 2, v30
  v_and_b32_e32 v32, 15, v1
  v_lshl_or_b32 v32, v32, 3, v31
  v_xor_b32_e32 v33, 4, v32

  v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
  v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
  v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
  v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0

  .set DK, 0
  .rept 8
    v_add_nc_u32_e32 v202, s22, v200
    v_lshlrev_b32_e32 v204, 12, v202
    v_add_nc_u32_e32 v204, s25, v204
    v_lshl_add_u32 v204, v201, 4, v204
    v_add_nc_u32_e32 v204, (DK*32), v204
    global_load_b128 v[24:27], v204, s[8:9]
    v_add_nc_u32_e32 v203, s23, v200
    v_lshlrev_b32_e32 v205, 12, v203
    v_add_nc_u32_e32 v205, s25, v205
    v_lshl_add_u32 v205, v201, 4, v205
    v_add_nc_u32_e32 v205, (DK*32), v205
    global_load_b128 v[28:31], v205, s[8:9]
    s_waitcnt vmcnt(0)

    ds_bpermute_b32 v34, v32, v24
    ds_bpermute_b32 v35, v33, v24
    ds_bpermute_b32 v36, v32, v25
    ds_bpermute_b32 v37, v33, v25
    ds_bpermute_b32 v38, v32, v26
    ds_bpermute_b32 v39, v33, v26
    ds_bpermute_b32 v40, v32, v27
    ds_bpermute_b32 v41, v33, v27
    s_waitcnt lgkmcnt(0)
    v_cmp_gt_u32_e32 vcc_lo, 16, v1
    v_cndmask_b32_e32 v8, v35, v34, vcc_lo
    v_cndmask_b32_e32 v12, v34, v35, vcc_lo
    v_cndmask_b32_e32 v9, v37, v36, vcc_lo
    v_cndmask_b32_e32 v13, v36, v37, vcc_lo
    v_cndmask_b32_e32 v10, v39, v38, vcc_lo
    v_cndmask_b32_e32 v14, v38, v39, vcc_lo
    v_cndmask_b32_e32 v11, v41, v40, vcc_lo
    v_cndmask_b32_e32 v15, v40, v41, vcc_lo

    ds_bpermute_b32 v34, v32, v28
    ds_bpermute_b32 v35, v33, v28
    ds_bpermute_b32 v36, v32, v29
    ds_bpermute_b32 v37, v33, v29
    ds_bpermute_b32 v38, v32, v30
    ds_bpermute_b32 v39, v33, v30
    ds_bpermute_b32 v40, v32, v31
    ds_bpermute_b32 v41, v33, v31
    s_waitcnt lgkmcnt(0)
    v_cmp_gt_u32_e32 vcc_lo, 16, v1
    v_cndmask_b32_e32 v16, v35, v34, vcc_lo
    v_cndmask_b32_e32 v20, v34, v35, vcc_lo
    v_cndmask_b32_e32 v17, v37, v36, vcc_lo
    v_cndmask_b32_e32 v21, v36, v37, vcc_lo
    v_cndmask_b32_e32 v18, v39, v38, vcc_lo
    v_cndmask_b32_e32 v22, v38, v39, vcc_lo
    v_cndmask_b32_e32 v19, v41, v40, vcc_lo
    v_cndmask_b32_e32 v23, v40, v41, vcc_lo
    v_wmma_f32_16x16x16_bf16 v[64:71], v[8:15], v[16:23], v[64:71]
    .set DK, DK+1
  .endr

  // Column gate is shared by the eight row fragments held by each lane.
  v_add_nc_u32_e32 v80, s23, v3
  v_lshlrev_b32_e32 v80, 7, v80
  v_lshl_add_u32 v80, s4, 2, v80
  global_load_dword v80, v80, s[10:11]
  s_waitcnt vmcnt(0)

  // Match production order: dot, safe_exp gate, beta row scale, causal mask.
  .set RR, 0
  .rept 8
    v_add_nc_u32_e32 v81, (RR*2), v4
    v_add_nc_u32_e32 v82, s22, v81
    v_lshlrev_b32_e32 v83, 7, v82
    v_lshl_add_u32 v83, s4, 2, v83
    global_load_dword v84, v83, s[10:11]
    v_lshlrev_b32_e32 v85, 6, v82
    v_lshl_add_u32 v85, s4, 1, v85
    global_load_ushort v86, v85, s[12:13]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32_e32 v86, 16, v86
    v_sub_f32_e32 v87, v84, v80
    v_mov_b32_e32 v88, 0
    v_cmp_le_f32_e32 vcc_lo, v87, v88
    v_cndmask_b32_e32 v87, 0xff800000, v87, vcc_lo
    v_mul_f32_e32 v87, 0x3fb8aa3b, v87
    v_exp_f32_e32 v87, v87
    v_mul_f32_e32 v[64+RR], v[64+RR], v87
    v_mul_f32_e32 v[64+RR], v[64+RR], v86
    v_add_nc_u32_e32 v89, s26, v81
    v_cmp_gt_u32_e32 vcc_lo, v89, v3
    v_cndmask_b32_e32 v[64+RR], 0, v[64+RR], vcc_lo

    v_lshlrev_b32_e32 v90, 13, v82
    v_add_nc_u32_e32 v90, s27, v90
    v_add_nc_u32_e32 v90, s28, v90
    v_lshl_add_u32 v90, v3, 2, v90
    global_store_dword v90, v[64+RR], s[14:15]
    .set RR, RR+1
  .endr
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel gdn_kkt_build_fp32_compiler_frag_gfx1151
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 32
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_sgpr_workgroup_id_z 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 212
.amdhsa_next_free_sgpr 32
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
.size gdn_kkt_build_fp32_compiler_frag_gfx1151, .Lfunc_end0-gdn_kkt_build_fp32_compiler_frag_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: k, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: beta, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: out_fp32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: gdn_kkt_build_fp32_compiler_frag_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 32
    .sgpr_spill_count: 0
    .symbol: gdn_kkt_build_fp32_compiler_frag_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 212
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
