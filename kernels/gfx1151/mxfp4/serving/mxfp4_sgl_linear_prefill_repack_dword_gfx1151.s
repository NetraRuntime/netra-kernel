// SPDX-License-Identifier: MIT
// Generic one-time raw gfx1151 dense MXFP4 byte-layout transform.
// Input: [K/2,N] u8. Output: [K32,fragment,subgroup,N,4 packed K bytes].
// Launch grid=(N/8,K/32,1), block=(32,1,1). N must be divisible by 8.

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.protected mxfp4_sgl_linear_prefill_repack_dword_gfx1151
.globl mxfp4_sgl_linear_prefill_repack_dword_gfx1151
.p2align 8
.type mxfp4_sgl_linear_prefill_repack_dword_gfx1151,@function
mxfp4_sgl_linear_prefill_repack_dword_gfx1151:
  s_load_b128 s[4:7], s[0:1], 0
  s_load_b32 s8, s[0:1], 16
  s_waitcnt lgkmcnt(0)

  // block byte base = workgroup_y * N * 16.
  s_mul_i32 s9, s3, s8
  s_lshl_b32 s9, s9, 4

  // Each wave covers four fragment/subgroup combinations for eight N columns.
  v_and_b32_e32 v1, 7, v0
  v_lshrrev_b32_e32 v2, 3, v0
  v_mul_lo_u32 v3, v2, s8
  v_lshlrev_b32_e32 v3, 2, v3
  v_mov_b32_e32 v4, s2
  v_lshl_add_u32 v4, v4, 3, v1

  // Source combo selects packed K rows 0/4/8/12 inside the K32 block.
  v_add_nc_u32_e32 v5, s9, v3
  v_add_nc_u32_e32 v5, v4, v5
  global_load_ubyte v6, v5, s[4:5]
  v_add_nc_u32_e32 v10, s8, v5
  global_load_ubyte v7, v10, s[4:5]
  v_add_nc_u32_e32 v10, s8, v10
  global_load_ubyte v8, v10, s[4:5]
  v_add_nc_u32_e32 v10, s8, v10
  global_load_ubyte v9, v10, s[4:5]

  // Destination stores the four K bytes contiguously for one N column.
  v_lshl_add_u32 v11, v4, 2, v3
  v_add_nc_u32_e32 v11, s9, v11
  s_waitcnt vmcnt(0)
  v_lshl_or_b32 v7, v7, 8, v6
  v_lshl_or_b32 v9, v9, 8, v8
  v_lshl_or_b32 v6, v9, 16, v7
  global_store_dword v11, v6, s[6:7]
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel mxfp4_sgl_linear_prefill_repack_dword_gfx1151
  .amdhsa_group_segment_fixed_size 0
  .amdhsa_private_segment_fixed_size 0
  .amdhsa_kernarg_size 24
  .amdhsa_user_sgpr_count 2
  .amdhsa_user_sgpr_kernarg_segment_ptr 1
  .amdhsa_wavefront_size32 1
  .amdhsa_enable_private_segment 0
  .amdhsa_system_sgpr_workgroup_id_x 1
  .amdhsa_system_sgpr_workgroup_id_y 1
  .amdhsa_system_sgpr_workgroup_id_z 0
  .amdhsa_system_vgpr_workitem_id 0
  .amdhsa_next_free_vgpr 12
  .amdhsa_next_free_sgpr 10
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
.size mxfp4_sgl_linear_prefill_repack_dword_gfx1151, .Lfunc_end0-mxfp4_sgl_linear_prefill_repack_dword_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: source, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: destination, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .offset: 16, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .max_flat_workgroup_size: 32
    .name: mxfp4_sgl_linear_prefill_repack_dword_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 12
    .sgpr_spill_count: 0
    .symbol: mxfp4_sgl_linear_prefill_repack_dword_gfx1151.kd
    .vgpr_count: 12
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
