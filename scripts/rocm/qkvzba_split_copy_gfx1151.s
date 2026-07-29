// SPDX-License-Identifier: MIT
// Qwen3.6 GDN contiguous QKVZ/BA split-copy, specialized for gfx1151.
//
// Per token:
//   mixed_qkvz[12288] -> mixed_qkv[8192] + z[4096]
//   mixed_ba[64]      -> b[32] + a[32]
// All values are BF16. Each work-item moves one aligned 16-byte vector.
// grid=(7, token_count, 1), block=(256,1,1).

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.protected qkvzba_split_copy_gfx1151
.globl qkvzba_split_copy_gfx1151
.p2align 8
.type qkvzba_split_copy_gfx1151,@function
qkvzba_split_copy_gfx1151:
// qkvz, ba, qkv, z, b, a
s_clause 0x2
s_load_b128 s[4:7], s[0:1], 0
s_load_b128 s[8:11], s[0:1], 16
s_load_b128 s[12:15], s[0:1], 32
s_waitcnt lgkmcnt(0)

// Add row byte strides once in SGPRs.
s_mul_i32 s16, s3, 24576
s_mul_i32 s17, s3, 128
s_lshl_b32 s18, s3, 14
s_lshl_b32 s19, s3, 13
s_lshl_b32 s20, s3, 6
s_add_u32 s4, s4, s16
s_addc_u32 s5, s5, 0
s_add_u32 s6, s6, s17
s_addc_u32 s7, s7, 0
s_add_u32 s8, s8, s18
s_addc_u32 s9, s9, 0
s_add_u32 s10, s10, s19
s_addc_u32 s11, s11, 0
s_add_u32 s12, s12, s20
s_addc_u32 s13, s13, 0
s_add_u32 s14, s14, s20
s_addc_u32 s15, s15, 0

// Vector index within the concatenated 1544-vector output row.
v_lshl_add_u32 v1, s2, 8, v0
s_cmp_lt_u32 s2, 4
s_cbranch_scc1 .Lqkv
s_cmp_lt_u32 s2, 6
s_cbranch_scc1 .Lz

// Final workgroup has eight valid vectors: four b, then four a.
v_cmp_gt_u32_e32 vcc_lo, 8, v0
s_and_b32 exec_lo, exec_lo, vcc_lo
s_cbranch_execz .Lend
s_mov_b32 s21, exec_lo
v_cmp_gt_u32_e32 vcc_lo, 4, v0
s_and_saveexec_b32 s22, vcc_lo
v_lshlrev_b32_e32 v2, 4, v0
global_load_b128 v[4:7], v2, s[6:7]
s_waitcnt vmcnt(0)
global_store_b128 v2, v[4:7], s[12:13]
s_mov_b32 exec_lo, s21
v_cmp_le_u32_e32 vcc_lo, 4, v0
s_and_saveexec_b32 s22, vcc_lo
v_add_nc_u32_e32 v1, -4, v0
v_lshlrev_b32_e32 v2, 4, v1
v_add_nc_u32_e32 v3, 64, v2
global_load_b128 v[4:7], v3, s[6:7]
s_waitcnt vmcnt(0)
global_store_b128 v2, v[4:7], s[14:15]
s_branch .Lend

.Lqkv:
v_lshlrev_b32_e32 v2, 4, v1
global_load_b128 v[4:7], v2, s[4:5]
s_waitcnt vmcnt(0)
global_store_b128 v2, v[4:7], s[8:9]
s_branch .Lend

.Lz:
v_lshlrev_b32_e32 v2, 4, v1
v_add_nc_u32_e32 v3, -16384, v2
global_load_b128 v[4:7], v2, s[4:5]
s_waitcnt vmcnt(0)
global_store_b128 v3, v[4:7], s[10:11]

.Lend:
s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel qkvzba_split_copy_gfx1151
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 48
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 8
.amdhsa_next_free_sgpr 23
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
.size qkvzba_split_copy_gfx1151, .Lfunc_end0-qkvzba_split_copy_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: mixed_qkvz, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: mixed_ba, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: mixed_qkv, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
      - { .name: z, .offset: 24, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
      - { .name: b, .offset: 32, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
      - { .name: a, .offset: 40, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qkvzba_split_copy_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: qkvzba_split_copy_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 8
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
