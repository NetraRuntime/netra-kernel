// SPDX-License-Identifier: MIT
// Accepted operation-ordered raw gfx1151 Qwen3.6 GDN causal conv: T=8192, D=8192, W=4, BF16, SiLU.
// grid=(64 feature tiles,128 token tiles), block=128. State update is separate.
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.protected causal_conv1d_stream64_ordered_gfx1151
.globl causal_conv1d_stream64_ordered_gfx1151
.p2align 8
.type causal_conv1d_stream64_ordered_gfx1151,@function
causal_conv1d_stream64_ordered_gfx1151:
s_clause 0x2
s_load_b128 s[4:7], s[0:1], 0
s_load_b128 s[8:11], s[0:1], 16
s_load_b128 s[12:15], s[0:1], 32
s_waitcnt lgkmcnt(0)

// feature = workgroup_x*128 + lane; byte address within a token row.
s_lshl_b32 s16, s2, 8
v_lshlrev_b32_e32 v1, 1, v0
v_add_nc_u32_e32 v1, s16, v1
// Current token byte address. Each token row is 8192 BF16 = 16384 bytes.
s_lshl_b32 s17, s3, 20
v_add_nc_u32_e32 v2, s17, v1

// Four feature-major BF16 weights.
v_lshlrev_b32_e32 v3, 3, v0
s_lshl_b32 s18, s2, 10
v_add_nc_u32_e32 v3, s18, v3
global_load_ushort v4, v3, s[6:7]
global_load_ushort v5, v3, s[6:7] offset:2
global_load_ushort v6, v3, s[6:7] offset:4
global_load_ushort v7, v3, s[6:7] offset:6

// Interior tiles obtain the rolling prefix directly from x.
s_cmp_eq_u32 s3, 0
s_cbranch_scc1 .Lboundary
v_add_nc_u32_e32 v8, -49152, v2
global_load_ushort v10, v8, s[4:5]
v_add_nc_u32_e32 v8, 16384, v8
	global_load_ushort v11, v8, s[4:5]
	v_add_nc_u32_e32 v8, 16384, v8
	global_load_ushort v12, v8, s[4:5]
s_branch .Lloaded_prefix

.Lboundary:
// Load cache index and has-initial-state flag. All lanes read the same bytes.
v_mov_b32_e32 v20, 0
global_load_dword v21, v20, s[10:11]
global_load_ubyte v22, v20, s[12:13]
s_waitcnt vmcnt(0)
v_readfirstlane_b32 s19, v21
v_readfirstlane_b32 s20, v22
s_mul_i32 s19, s19, 49152
s_add_u32 s8, s8, s19
s_addc_u32 s9, s9, 0
s_mul_i32 s22, s2, 768
s_waitcnt_depctr 0
v_mul_lo_u32 v8, v0, 6
v_add_nc_u32_e32 v8, s22, v8
s_cmp_eq_u32 s20, 0
s_cbranch_scc1 .Lzero_prefix
global_load_ushort v10, v8, s[8:9]
global_load_ushort v11, v8, s[8:9] offset:2
global_load_ushort v12, v8, s[8:9] offset:4
s_branch .Lloaded_prefix
.Lzero_prefix:
v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
v_mov_b32_e32 v12, 0

.Lloaded_prefix:
s_waitcnt vmcnt(0)
v_mov_b32_e32 v23, 0xbfb8aa3b
v_mov_b32_e32 v24, 0x3f800000
s_mov_b32 s21, 64

.Ltoken:
global_load_ushort v13, v2, s[4:5]
s_waitcnt vmcnt(0)
v_dot2_bf16_bf16 v14, v10, v4, 0
v_dot2_bf16_bf16 v15, v11, v5, 0
v_dot2_bf16_bf16 v16, v12, v6, 0
v_dot2_bf16_bf16 v17, v13, v7, 0
v_lshlrev_b32_e32 v14, 16, v14
v_lshlrev_b32_e32 v15, 16, v15
v_lshlrev_b32_e32 v16, 16, v16
v_lshlrev_b32_e32 v17, 16, v17
v_add_f32_e32 v14, v14, v15
v_add_f32_e32 v14, v14, v16
v_add_f32_e32 v14, v14, v17
// SiLU(x) = x / (1 + exp(-x)); v_exp is base 2.
v_mul_f32_e32 v15, v14, v23
v_exp_f32_e32 v15, v15
v_add_f32_e32 v15, v24, v15
v_div_scale_f32 v16, null, v15, v15, v14
v_rcp_f32_e32 v17, v16
v_fma_f32 v18, -v16, v17, 1.0
v_fmac_f32_e32 v17, v18, v17
v_div_scale_f32 v18, vcc_lo, v14, v15, v14
v_mul_f32_e32 v19, v18, v17
v_fma_f32 v20, -v16, v19, v18
v_fmac_f32_e32 v19, v20, v17
v_fma_f32 v16, -v16, v19, v18
v_div_fmas_f32 v16, v16, v17, v19
v_div_fixup_f32 v14, v16, v15, v14
// Round FP32 to BF16, ties-to-even.
v_lshrrev_b32_e32 v15, 16, v14
v_and_b32_e32 v15, 1, v15
v_add_nc_u32_e32 v15, 0x7fff, v15
v_add_nc_u32_e32 v14, v15, v14
v_lshrrev_b32_e32 v14, 16, v14
global_store_short v2, v14, s[14:15]
v_mov_b32_e32 v10, v11
v_mov_b32_e32 v11, v12
v_mov_b32_e32 v12, v13
v_add_nc_u32_e32 v2, 16384, v2
s_sub_u32 s21, s21, 1
s_cmp_lg_u32 s21, 0
s_cbranch_scc1 .Ltoken
s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel causal_conv1d_stream64_ordered_gfx1151
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
.amdhsa_next_free_vgpr 25
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
.Lend:
.size causal_conv1d_stream64_ordered_gfx1151, .Lend-causal_conv1d_stream64_ordered_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: x, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: weight, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: state, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: cache_index, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: has_initial, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: causal_conv1d_stream64_ordered_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 25
    .sgpr_spill_count: 0
    .symbol: causal_conv1d_stream64_ordered_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 25
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
