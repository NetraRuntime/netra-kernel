// SPDX-License-Identifier: MIT
// Deterministic raw gfx1151 router-weight application + top-8 expert reduction.
// expert=[padded_pairs,2048] FP32, positions=[tokens,8] int32,
// weights=[tokens,8] FP32, output=[tokens,2048] BF16.
// grid=(8,tokens,1), block=(256,1,1).
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.protected expert_weighted_reduce_top8_gfx1151
.globl expert_weighted_reduce_top8_gfx1151
.p2align 8
.type expert_weighted_reduce_top8_gfx1151,@function
expert_weighted_reduce_top8_gfx1151:
s_clause 0x1
s_load_b128 s[4:7], s[0:1], 0
s_load_b128 s[8:11], s[0:1], 16
s_lshl_b32 s12, s3, 5
s_waitcnt lgkmcnt(0)
s_load_b128 s[16:19], s[6:7], s12
s_add_u32 s13, s12, 16
s_load_b128 s[20:23], s[6:7], s13
s_load_b128 s[24:27], s[8:9], s12
s_load_b128 s[28:31], s[8:9], s13
s_lshl_b32 s14, s2, 10
v_lshlrev_b32_e32 v1, 2, v0
v_add_nc_u32_e32 v1, s14, v1
s_waitcnt lgkmcnt(0)
s_lshl_b32 s32, s16, 13
s_lshl_b32 s33, s17, 13
s_lshl_b32 s34, s18, 13
s_lshl_b32 s35, s19, 13
s_lshl_b32 s36, s20, 13
s_lshl_b32 s37, s21, 13
s_lshl_b32 s38, s22, 13
s_lshl_b32 s39, s23, 13
s_waitcnt_depctr 0
v_add_nc_u32_e32 v2, s32, v1
v_add_nc_u32_e32 v3, s33, v1
v_add_nc_u32_e32 v4, s34, v1
v_add_nc_u32_e32 v5, s35, v1
v_add_nc_u32_e32 v6, s36, v1
v_add_nc_u32_e32 v7, s37, v1
v_add_nc_u32_e32 v8, s38, v1
v_add_nc_u32_e32 v9, s39, v1
global_load_b32 v16, v2, s[4:5]
global_load_b32 v17, v3, s[4:5]
global_load_b32 v18, v4, s[4:5]
global_load_b32 v19, v5, s[4:5]
global_load_b32 v20, v6, s[4:5]
global_load_b32 v21, v7, s[4:5]
global_load_b32 v22, v8, s[4:5]
global_load_b32 v23, v9, s[4:5]
s_waitcnt vmcnt(0)
v_mov_b32_e32 v26, s24
v_mov_b32_e32 v27, s25
v_mov_b32_e32 v28, s26
v_mov_b32_e32 v29, s27
v_mov_b32_e32 v30, s28
v_mov_b32_e32 v31, s29
v_mov_b32_e32 v32, s30
v_mov_b32_e32 v33, s31
v_mul_f32_e32 v24, v16, v26
v_fmac_f32_e32 v24, v17, v27
v_fmac_f32_e32 v24, v18, v28
v_fmac_f32_e32 v24, v19, v29
v_fmac_f32_e32 v24, v20, v30
v_fmac_f32_e32 v24, v21, v31
v_fmac_f32_e32 v24, v22, v32
v_fmac_f32_e32 v24, v23, v33
// FP32 to BF16 RNE.
v_lshrrev_b32_e32 v25, 16, v24
v_and_b32_e32 v25, 1, v25
v_add_nc_u32_e32 v25, 0x7fff, v25
v_add_nc_u32_e32 v24, v25, v24
v_lshrrev_b32_e32 v24, 16, v24
s_lshl_b32 s40, s3, 12
v_lshlrev_b32_e32 v25, 1, v0
s_lshl_b32 s41, s2, 9
s_add_u32 s41, s41, s40
v_add_nc_u32_e32 v25, s41, v25
global_store_short v25, v24, s[10:11]
s_endpgm
.section .rodata,"a",@progbits
.p2align 6,0
.amdhsa_kernel expert_weighted_reduce_top8_gfx1151
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
.amdhsa_next_free_vgpr 34
.amdhsa_next_free_sgpr 42
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
.Lend: .size expert_weighted_reduce_top8_gfx1151,.Lend-expert_weighted_reduce_top8_gfx1151
.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: expert, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: positions, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: weights, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2,0]
    .max_flat_workgroup_size: 256
    .name: expert_weighted_reduce_top8_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 44
    .sgpr_spill_count: 0
    .symbol: expert_weighted_reduce_top8_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 34
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1,2]
...
.end_amdgpu_metadata
