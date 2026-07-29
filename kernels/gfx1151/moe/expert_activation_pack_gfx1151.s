// SPDX-License-Identifier: MIT
// Raw gfx1151 fused routed-token gather + grouped-position scatter + padding clear.
// hidden=[tokens,2048] BF16, pair_tokens=[pairs] int64, position=[pairs] int64,
// output=[total_rows,2048] BF16. position must be strictly increasing.
// grid=(pair_count,1,1), block=(256,1,1); one lane copies/stores 16 bytes.
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.protected expert_activation_pack_gfx1151
.globl expert_activation_pack_gfx1151
.p2align 8
.type expert_activation_pack_gfx1151,@function
expert_activation_pack_gfx1151:
  s_clause 0x2
  s_load_b128 s[4:7], s[0:1], 0
  s_load_b128 s[8:11], s[0:1], 16
  s_load_b64 s[12:13], s[0:1], 32
  s_lshl_b32 s14, s2, 3
  s_waitcnt lgkmcnt(0)
  s_load_b64 s[16:17], s[6:7], s14
  s_load_b64 s[18:19], s[8:9], s14
  s_add_u32 s15, s2, 1
  s_cmp_ge_u32 s15, s12
  s_cbranch_scc1 .Lfinal_pair
  s_add_u32 s14, s14, 8
  s_load_b64 s[20:21], s[8:9], s14
  s_branch .Lnext_ready
.Lfinal_pair:
  s_mov_b32 s20, s13
.Lnext_ready:
  s_waitcnt lgkmcnt(0)

  v_lshlrev_b32_e32 v1, 4, v0
  s_lshl_b32 s22, s16, 12
  v_add_nc_u32_e32 v2, s22, v1
  s_lshl_b32 s22, s18, 12
  v_add_nc_u32_e32 v3, s22, v1
  global_load_b128 v[4:7], v2, s[4:5]
  s_waitcnt vmcnt(0)
  global_store_b128 v3, v[4:7], s[10:11]

  s_add_u32 s22, s18, 1
  s_cmp_ge_u32 s22, s20
  s_cbranch_scc1 .Lend
  v_dual_mov_b32 v4, 0 :: v_dual_mov_b32 v5, 0
  v_dual_mov_b32 v6, 0 :: v_dual_mov_b32 v7, 0
.Lzero_gap:
  s_lshl_b32 s23, s22, 12
  v_add_nc_u32_e32 v3, s23, v1
  global_store_b128 v3, v[4:7], s[10:11]
  s_add_u32 s22, s22, 1
  s_cmp_lt_u32 s22, s20
  s_cbranch_scc1 .Lzero_gap
.Lend:
  s_endpgm
.section .rodata,"a",@progbits
.p2align 6,0
.amdhsa_kernel expert_activation_pack_gfx1151
  .amdhsa_group_segment_fixed_size 0
  .amdhsa_private_segment_fixed_size 0
  .amdhsa_kernarg_size 40
  .amdhsa_user_sgpr_count 2
  .amdhsa_user_sgpr_kernarg_segment_ptr 1
  .amdhsa_wavefront_size32 1
  .amdhsa_enable_private_segment 0
  .amdhsa_system_sgpr_workgroup_id_x 1
  .amdhsa_system_sgpr_workgroup_id_y 0
  .amdhsa_system_sgpr_workgroup_id_z 0
  .amdhsa_system_vgpr_workitem_id 0
  .amdhsa_next_free_vgpr 8
  .amdhsa_next_free_sgpr 24
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
.Lfunc_end: .size expert_activation_pack_gfx1151,.Lfunc_end-expert_activation_pack_gfx1151
.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: pair_tokens, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: position, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: pair_count, .offset: 32, .size: 4, .value_kind: by_value }
      - { .name: total_rows, .offset: 36, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2,0]
    .max_flat_workgroup_size: 256
    .name: expert_activation_pack_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 26
    .sgpr_spill_count: 0
    .symbol: expert_activation_pack_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 8
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1,2]
...
.end_amdgpu_metadata
