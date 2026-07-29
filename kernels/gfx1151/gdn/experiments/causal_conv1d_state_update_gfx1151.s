// SPDX-License-Identifier: MIT
// Raw gfx1151 state writeback for T=8192,D=8192,W=4 BF16 causal convolution.
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.protected causal_conv1d_state_update_gfx1151
.globl causal_conv1d_state_update_gfx1151
.p2align 8
.type causal_conv1d_state_update_gfx1151,@function
causal_conv1d_state_update_gfx1151:
s_load_b128 s[4:7], s[0:1], 0
s_load_b64 s[8:9], s[0:1], 16
s_waitcnt lgkmcnt(0)
v_mov_b32_e32 v8, 0
global_load_dword v9, v8, s[8:9]
s_lshl_b32 s10, s2, 8
v_lshlrev_b32_e32 v1, 1, v0
v_add_nc_u32_e32 v1, s10, v1
v_add_nc_u32_e32 v2, 0x07ff4000, v1
global_load_ushort v3, v2, s[4:5]
v_add_nc_u32_e32 v2, 16384, v2
global_load_ushort v4, v2, s[4:5]
v_add_nc_u32_e32 v2, 16384, v2
global_load_ushort v5, v2, s[4:5]
s_waitcnt vmcnt(0)
v_readfirstlane_b32 s11, v9
s_mul_i32 s11, s11, 49152
s_add_u32 s6, s6, s11
s_addc_u32 s7, s7, 0
s_mul_i32 s12, s2, 768
s_waitcnt_depctr 0
v_mul_lo_u32 v6, v0, 6
v_add_nc_u32_e32 v6, s12, v6
global_store_short v6, v3, s[6:7]
global_store_short v6, v4, s[6:7] offset:2
global_store_short v6, v5, s[6:7] offset:4
s_endpgm
.section .rodata,"a",@progbits
.p2align 6,0
.amdhsa_kernel causal_conv1d_state_update_gfx1151
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 24
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 0
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 10
.amdhsa_next_free_sgpr 13
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
.Lend: .size causal_conv1d_state_update_gfx1151,.Lend-causal_conv1d_state_update_gfx1151
.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: x, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: state, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: cache_index, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2,0]
    .max_flat_workgroup_size: 128
    .name: causal_conv1d_state_update_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 15
    .sgpr_spill_count: 0
    .symbol: causal_conv1d_state_update_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 10
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1,2]
...
.end_amdgpu_metadata
