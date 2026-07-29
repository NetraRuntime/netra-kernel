// SPDX-License-Identifier: MIT
// One-time raw gfx1151 MXFP4 byte-layout transform for Qwen3.6 gate/up.
// Input:  [256,1024,512] u8 == [expert,K/2,N].
// Output: [expert,K32,fragment,subgroup,N,4 packed K bytes].
// The 4-bit E2M1 values are copied exactly; no dequantization occurs.
// Grid=(131072,1,1), block=(256,1,1), exactly 33,554,432 dwords.

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.protected mxfp4_prefill_repack_dword_gfx1151
.globl mxfp4_prefill_repack_dword_gfx1151
.p2align 8
.type mxfp4_prefill_repack_dword_gfx1151,@function
mxfp4_prefill_repack_dword_gfx1151:
  // Kernargs: source, destination.
  s_load_b128 s[4:7], s[0:1], 0
  s_waitcnt lgkmcnt(0)

  // i = workgroup*256 + lane, one destination dword per workitem.
  v_mov_b32_e32 v1, s2
  v_lshlrev_b32_e32 v1, 8, v1
  v_add_nc_u32_e32 v1, v0, v1
  v_lshlrev_b32_e32 v2, 2, v1

  // i = ((((expert*64 + block)*2 + fragment)*2 + subgroup)*512 + n).
  v_and_b32_e32 v3, 511, v1
  v_lshrrev_b32_e32 v4, 9, v1
  v_and_b32_e32 v5, 1, v4
  v_lshrrev_b32_e32 v6, 1, v4
  v_and_b32_e32 v7, 1, v6
  v_lshrrev_b32_e32 v8, 2, v4
  v_and_b32_e32 v8, 63, v8
  v_lshrrev_b32_e32 v9, 8, v4

  // packed_k = block*16 + fragment*8 + subgroup*4.
  v_lshlrev_b32_e32 v8, 4, v8
  v_lshl_add_u32 v8, v7, 3, v8
  v_lshl_add_u32 v8, v5, 2, v8

  // source = ((expert*1024 + packed_k)*512 + n).
  v_lshl_add_u32 v8, v9, 10, v8
  v_lshl_add_u32 v3, v8, 9, v3
  global_load_ubyte v10, v3, s[4:5]
  global_load_ubyte v11, v3, s[4:5] offset:512
  global_load_ubyte v12, v3, s[4:5] offset:1024
  global_load_ubyte v13, v3, s[4:5] offset:1536
  s_waitcnt vmcnt(0)
  v_lshl_or_b32 v11, v11, 8, v10
  v_lshl_or_b32 v13, v13, 8, v12
  v_lshl_or_b32 v10, v13, 16, v11
  global_store_dword v2, v10, s[6:7]
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel mxfp4_prefill_repack_dword_gfx1151
  .amdhsa_group_segment_fixed_size 0
  .amdhsa_private_segment_fixed_size 0
  .amdhsa_kernarg_size 16
  .amdhsa_user_sgpr_count 2
  .amdhsa_user_sgpr_kernarg_segment_ptr 1
  .amdhsa_wavefront_size32 1
  .amdhsa_enable_private_segment 0
  .amdhsa_system_sgpr_workgroup_id_x 1
  .amdhsa_system_sgpr_workgroup_id_y 0
  .amdhsa_system_sgpr_workgroup_id_z 0
  .amdhsa_system_vgpr_workitem_id 0
  .amdhsa_next_free_vgpr 14
  .amdhsa_next_free_sgpr 8
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
.size mxfp4_prefill_repack_dword_gfx1151, .Lfunc_end0-mxfp4_prefill_repack_dword_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: source, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: destination, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .max_flat_workgroup_size: 256
    .name: mxfp4_prefill_repack_dword_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 8
    .sgpr_spill_count: 0
    .symbol: mxfp4_prefill_repack_dword_gfx1151.kd
    .vgpr_count: 14
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
