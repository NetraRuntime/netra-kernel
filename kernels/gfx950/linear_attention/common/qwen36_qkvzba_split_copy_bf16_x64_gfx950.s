// SPDX-License-Identifier: MIT
//
// Native CDNA4 Qwen3.6 GDN contiguous QKVZ/BA split-copy.
//
// Per token, all values are model-native BF16:
//   mixed_qkvz[12288] -> mixed_qkv[8192] + z[4096]
//   mixed_ba[64]      -> b[32] + a[32]
//
// gfx950 design: each lane moves one aligned 64-byte stripe through four
// independent 128-bit global operations. Grid X=0 copies the 16 KiB QKV row;
// grid X=1 uses two waves for the 8 KiB Z row and two lanes for B/A. The
// two-workgroup, wave64 layout executes only eight waves per token versus the
// 28-wave gfx1151 reference and uses no LDS, barriers, conversion, or scratch.
// Grid: (2, token_count, 1), block: (256, 1, 1).

.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected qwen36_qkvzba_split_copy_bf16_x64_gfx950
.globl qwen36_qkvzba_split_copy_bf16_x64_gfx950
.p2align 8
.type qwen36_qkvzba_split_copy_bf16_x64_gfx950,@function
qwen36_qkvzba_split_copy_bf16_x64_gfx950:
// qkvz, ba, qkv, z, b, a
s_load_dwordx4 s[4:7], s[0:1], 0
s_load_dwordx4 s[8:11], s[0:1], 16
s_load_dwordx4 s[12:15], s[0:1], 32
s_waitcnt lgkmcnt(0)

// Add token-row byte strides once in scalar registers.
s_mul_i32 s16, s3, 24576
s_lshl_b32 s17, s3, 7
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

s_cmp_eq_u32 s2, 0
s_cbranch_scc0 .Lzba

// QKV: 256 lanes x 64 bytes = one complete 16 KiB row.
v_lshlrev_b32_e32 v1, 6, v0
global_load_dwordx4 v[4:7], v1, s[4:5]
global_load_dwordx4 v[8:11], v1, s[4:5] offset:16
global_load_dwordx4 v[12:15], v1, s[4:5] offset:32
global_load_dwordx4 v[16:19], v1, s[4:5] offset:48
s_waitcnt vmcnt(0)
global_store_dwordx4 v1, v[4:7], s[8:9]
global_store_dwordx4 v1, v[8:11], s[8:9] offset:16
global_store_dwordx4 v1, v[12:15], s[8:9] offset:32
global_store_dwordx4 v1, v[16:19], s[8:9] offset:48
s_endpgm

.Lzba:
// Preserve the full wave mask. Only lanes 0..127 copy Z; lanes 128 and 129
// subsequently copy complete 64-byte B and A rows.
s_mov_b64 s[22:23], exec
v_cmp_gt_u32_e32 vcc, 128, v0
s_and_b64 exec, exec, vcc
s_cbranch_execz .Lafter_z
v_lshlrev_b32_e32 v2, 6, v0
v_add_u32_e32 v1, 16384, v2
global_load_dwordx4 v[4:7], v1, s[4:5]
global_load_dwordx4 v[8:11], v1, s[4:5] offset:16
global_load_dwordx4 v[12:15], v1, s[4:5] offset:32
global_load_dwordx4 v[16:19], v1, s[4:5] offset:48
s_waitcnt vmcnt(0)
global_store_dwordx4 v2, v[4:7], s[10:11]
global_store_dwordx4 v2, v[8:11], s[10:11] offset:16
global_store_dwordx4 v2, v[12:15], s[10:11] offset:32
global_store_dwordx4 v2, v[16:19], s[10:11] offset:48

.Lafter_z:
s_mov_b64 exec, s[22:23]
v_add_u32_e32 v1, -128, v0
v_cmp_gt_u32_e32 vcc, 2, v1
s_and_b64 exec, exec, vcc
s_cbranch_execz .Lend
s_mov_b64 s[24:25], exec

// Local lane zero copies B.
v_cmp_eq_u32_e32 vcc, 0, v1
s_and_b64 exec, exec, vcc
s_cbranch_execz .La
v_mov_b32_e32 v2, 0
global_load_dwordx4 v[4:7], v2, s[6:7]
global_load_dwordx4 v[8:11], v2, s[6:7] offset:16
global_load_dwordx4 v[12:15], v2, s[6:7] offset:32
global_load_dwordx4 v[16:19], v2, s[6:7] offset:48
s_waitcnt vmcnt(0)
global_store_dwordx4 v2, v[4:7], s[12:13]
global_store_dwordx4 v2, v[8:11], s[12:13] offset:16
global_store_dwordx4 v2, v[12:15], s[12:13] offset:32
global_store_dwordx4 v2, v[16:19], s[12:13] offset:48

.La:
s_mov_b64 exec, s[24:25]
v_cmp_eq_u32_e32 vcc, 1, v1
s_and_b64 exec, exec, vcc
s_cbranch_execz .Lend
v_mov_b32_e32 v2, 64
global_load_dwordx4 v[4:7], v2, s[6:7]
global_load_dwordx4 v[8:11], v2, s[6:7] offset:16
global_load_dwordx4 v[12:15], v2, s[6:7] offset:32
global_load_dwordx4 v[16:19], v2, s[6:7] offset:48
s_waitcnt vmcnt(0)
v_mov_b32_e32 v2, 0
global_store_dwordx4 v2, v[4:7], s[14:15]
global_store_dwordx4 v2, v[8:11], s[14:15] offset:16
global_store_dwordx4 v2, v[12:15], s[14:15] offset:32
global_store_dwordx4 v2, v[16:19], s[14:15] offset:48

.Lend:
s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel qwen36_qkvzba_split_copy_bf16_x64_gfx950
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 48
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 20
.amdhsa_accum_offset 20
.amdhsa_next_free_sgpr 26
.amdhsa_reserve_vcc 1
.amdhsa_float_round_mode_32 0
.amdhsa_float_round_mode_16_64 0
.amdhsa_float_denorm_mode_32 3
.amdhsa_float_denorm_mode_16_64 3
.amdhsa_dx10_clamp 1
.amdhsa_ieee_mode 1
.amdhsa_tg_split 0
.end_amdhsa_kernel
.text
.Lfunc_end0:
.size qwen36_qkvzba_split_copy_bf16_x64_gfx950, .Lfunc_end0-qwen36_qkvzba_split_copy_bf16_x64_gfx950

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
    .name: qwen36_qkvzba_split_copy_bf16_x64_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 32
    .sgpr_spill_count: 0
    .symbol: qwen36_qkvzba_split_copy_bf16_x64_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 20
    .vgpr_spill_count: 0
    .wavefront_size: 64
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
