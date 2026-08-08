// SPDX-License-Identifier: MIT
//
// Qwen3.6 GDN prefill projection split for contiguous BF16 inputs.
// One 256-thread, four-wave workgroup owns one token row:
//   mixed_qkvz [M,12288] -> mixed_qkv [M,8192] + z [M,4096]
//   mixed_ba   [M,64]    -> b [M,32] + a [M,32]
//
// Each lane moves six aligned 16-byte vectors from QKVZ. The first four
// vectors target QKV and the last two target Z. Lanes 0..7 also move BA.
// All row bases use explicit 64-bit scalar arithmetic for M beyond the
// signed 32-bit element-address boundary.

.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6

.text
.protected qwen36_gdn_fused_proj_bf16_gfx950
.globl qwen36_gdn_fused_proj_bf16_gfx950
.p2align 8
.type qwen36_gdn_fused_proj_bf16_gfx950,@function
qwen36_gdn_fused_proj_bf16_gfx950:
// Kernargs: qkv, z, b, a, qkvz, ba pointers.
s_load_dwordx8 s[4:11], s[0:1], 0
s_load_dwordx4 s[12:15], s[0:1], 32
s_waitcnt lgkmcnt(0)

// mixed_qkvz row byte stride = 12288 * 2 = 24576.
s_mul_i32 s16, s2, 24576
s_mul_hi_u32 s17, s2, 24576
s_add_u32 s12, s12, s16
s_addc_u32 s13, s13, s17

// mixed_ba row byte stride = 64 * 2 = 128.
s_mul_i32 s16, s2, 128
s_mul_hi_u32 s17, s2, 128
s_add_u32 s14, s14, s16
s_addc_u32 s15, s15, s17

// mixed_qkv row byte stride = 8192 * 2 = 16384.
s_mul_i32 s16, s2, 16384
s_mul_hi_u32 s17, s2, 16384
s_add_u32 s4, s4, s16
s_addc_u32 s5, s5, s17

// z row byte stride = 4096 * 2 = 8192.
s_mul_i32 s16, s2, 8192
s_mul_hi_u32 s17, s2, 8192
s_add_u32 s6, s6, s16
s_addc_u32 s7, s7, s17

// b and a row byte stride = 32 * 2 = 64.
s_mul_i32 s16, s2, 64
s_mul_hi_u32 s17, s2, 64
s_add_u32 s8, s8, s16
s_addc_u32 s9, s9, s17
s_add_u32 s10, s10, s16
s_addc_u32 s11, s11, s17

// Six 4-KiB stripes cover one 24-KiB QKVZ row.
v_lshlrev_b32_e32 v1, 4, v0
v_add_u32_e32 v2, 4096, v1
v_add_u32_e32 v3, 8192, v1
v_add_u32_e32 v4, 12288, v1
v_add_u32_e32 v5, 16384, v1
v_add_u32_e32 v6, 20480, v1
global_load_dwordx4 v[8:11], v1, s[12:13]
global_load_dwordx4 v[12:15], v2, s[12:13]
global_load_dwordx4 v[16:19], v3, s[12:13]
global_load_dwordx4 v[20:23], v4, s[12:13]
global_load_dwordx4 v[24:27], v5, s[12:13]
global_load_dwordx4 v[28:31], v6, s[12:13]

// Only eight lanes are needed for the 128-byte BA row.
v_cmp_gt_u32_e32 vcc, 8, v0
s_and_saveexec_b64 s[18:19], vcc
global_load_dwordx4 v[32:35], v1, s[14:15]
s_or_b64 exec, exec, s[18:19]
s_waitcnt vmcnt(0)

// QKV keeps the first 16 KiB; Z receives the final 8 KiB.
global_store_dwordx4 v1, v[8:11], s[4:5]
global_store_dwordx4 v2, v[12:15], s[4:5]
global_store_dwordx4 v3, v[16:19], s[4:5]
global_store_dwordx4 v4, v[20:23], s[4:5]
global_store_dwordx4 v1, v[24:27], s[6:7]
global_store_dwordx4 v2, v[28:31], s[6:7]

// BA vectors 0..3 target B; vectors 4..7 target A.
v_cmp_gt_u32_e32 vcc, 4, v0
s_and_saveexec_b64 s[18:19], vcc
global_store_dwordx4 v1, v[32:35], s[8:9]
s_or_b64 exec, exec, s[18:19]

v_cmp_gt_u32_e32 vcc, 8, v0
v_cmp_ge_u32_e64 s[16:17], v0, 4
s_and_b64 vcc, vcc, s[16:17]
s_and_saveexec_b64 s[18:19], vcc
v_add_u32_e32 v7, -64, v1
global_store_dwordx4 v7, v[32:35], s[10:11]
s_or_b64 exec, exec, s[18:19]

s_waitcnt vmcnt(0)
s_endpgm
.Lkernel_end:

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel qwen36_gdn_fused_proj_bf16_gfx950
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 48
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 36
.amdhsa_accum_offset 36
.amdhsa_next_free_sgpr 20
.amdhsa_reserve_vcc 1
.amdhsa_float_denorm_mode_32 3
.amdhsa_float_denorm_mode_16_64 3
.amdhsa_dx10_clamp 1
.amdhsa_ieee_mode 1
.amdhsa_tg_split 0
.end_amdhsa_kernel

.size qwen36_gdn_fused_proj_bf16_gfx950, .Lkernel_end-qwen36_gdn_fused_proj_bf16_gfx950

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: mixed_qkv_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: z_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: b_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: a_bf16, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: mixed_qkvz_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: mixed_ba_bf16, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gdn_fused_proj_bf16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_fused_proj_bf16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 36
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
