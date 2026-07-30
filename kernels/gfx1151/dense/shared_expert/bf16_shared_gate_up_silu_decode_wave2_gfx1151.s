// SPDX-License-Identifier: MIT
//
// Raw gfx1151 BF16 shared-expert gate+up+SiLU GEMV.
// Fixed M=1, gate/up N=512+512, K=2048, row-major physical weights [1024,K].
// Each wave32 computes two gate rows and their paired two up rows; each workgroup contains eight waves.
// Grid=(32,1,1), block=(256,1,1).

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.macro WAVE_SUM REG TMP
v_xor_b32_e32 v17, 16, v11
v_lshlrev_b32_e32 v17, 2, v17
ds_bpermute_b32 v[\TMP], v17, v[\REG]
s_waitcnt lgkmcnt(0)
v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
v_xor_b32_e32 v17, 8, v11
v_lshlrev_b32_e32 v17, 2, v17
ds_bpermute_b32 v[\TMP], v17, v[\REG]
s_waitcnt lgkmcnt(0)
v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
v_xor_b32_e32 v17, 4, v11
v_lshlrev_b32_e32 v17, 2, v17
ds_bpermute_b32 v[\TMP], v17, v[\REG]
s_waitcnt lgkmcnt(0)
v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
v_xor_b32_e32 v17, 2, v11
v_lshlrev_b32_e32 v17, 2, v17
ds_bpermute_b32 v[\TMP], v17, v[\REG]
s_waitcnt lgkmcnt(0)
v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
v_xor_b32_e32 v17, 1, v11
v_lshlrev_b32_e32 v17, 2, v17
ds_bpermute_b32 v[\TMP], v17, v[\REG]
s_waitcnt lgkmcnt(0)
v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
.endm

.macro ROUND_BF16 SRC TMP
v_lshrrev_b32_e32 v[\TMP], 16, v[\SRC]
v_and_b32_e32 v[\TMP], 1, v[\TMP]
v_add_nc_u32_e32 v[\TMP], 0x7fff, v[\TMP]
v_add_nc_u32_e32 v[\SRC], v[\TMP], v[\SRC]
v_lshrrev_b32_e32 v[\SRC], 16, v[\SRC]
.endm

.protected bf16_shared_gate_up_silu_decode_wave2_gfx1151
.globl bf16_shared_gate_up_silu_decode_wave2_gfx1151
.p2align 8
.type bf16_shared_gate_up_silu_decode_wave2_gfx1151,@function
bf16_shared_gate_up_silu_decode_wave2_gfx1151:
// kernarg: weights, activation, output (three stable device pointers).
s_load_b128 s[4:7], s[0:1], 0
s_load_b64 s[8:9], s[0:1], 16
s_waitcnt lgkmcnt(0)

// row = workgroup_id_x*16 + wave_id*2.
v_lshrrev_b32_e32 v10, 5, v0
v_lshlrev_b32_e32 v10, 1, v10
s_lshl_b32 s10, s2, 4
v_add_nc_u32_e32 v10, s10, v10

// Each K step covers two BF16 values per lane. Across the wave the
// accesses form one aligned 128-byte transaction for each output row.
v_and_b32_e32 v11, 31, v0
v_lshlrev_b32_e32 v1, 2, v11
v_lshlrev_b32_e32 v2, 12, v10
v_add_nc_u32_e32 v2, v1, v2
v_add_nc_u32_e32 v8, 4096, v2
v_add_nc_u32_e32 v9, 2097152, v2
v_add_nc_u32_e32 v16, 2101248, v2

v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
s_mov_b32 s12, 32

.Ldot:
global_load_b32 v3, v1, s[6:7]
global_load_b32 v4, v2, s[4:5]
global_load_b32 v5, v8, s[4:5]
global_load_b32 v6, v9, s[4:5]
global_load_b32 v7, v16, s[4:5]
v_add_nc_u32_e32 v1, 128, v1
v_add_nc_u32_e32 v2, 128, v2
v_add_nc_u32_e32 v8, 128, v8
v_add_nc_u32_e32 v9, 128, v9
v_add_nc_u32_e32 v16, 128, v16
s_waitcnt vmcnt(0)
v_dot2_f32_bf16 v12, v4, v3, v12
v_dot2_f32_bf16 v13, v5, v3, v13
v_dot2_f32_bf16 v14, v6, v3, v14
v_dot2_f32_bf16 v15, v7, v3, v15
s_sub_u32 s12, s12, 1
s_cmp_lg_u32 s12, 0
s_cbranch_scc1 .Ldot

WAVE_SUM 12 16
WAVE_SUM 13 16
WAVE_SUM 14 16
WAVE_SUM 15 16

ROUND_BF16 12 16
ROUND_BF16 13 16
ROUND_BF16 14 16
ROUND_BF16 15 16
// Preserve the model-native BF16 projection boundary before SiLU.
v_lshlrev_b32_e32 v12, 16, v12
v_lshlrev_b32_e32 v13, 16, v13
v_lshlrev_b32_e32 v14, 16, v14
v_lshlrev_b32_e32 v15, 16, v15

// silu(gate) * up using the accepted gfx1151 base-2 sequence.
v_mov_b32_e32 v3, 0xbfb8aa3b
v_mov_b32_e32 v4, 0x3f800000
v_mul_f32_e32 v5, v12, v3
v_exp_f32_e32 v5, v5
v_add_f32_e32 v5, v4, v5
v_rcp_f32_e32 v5, v5
v_mul_f32_e32 v6, v12, v14
v_mul_f32_e32 v12, v6, v5
v_mul_f32_e32 v5, v13, v3
v_exp_f32_e32 v5, v5
v_add_f32_e32 v5, v4, v5
v_rcp_f32_e32 v5, v5
v_mul_f32_e32 v6, v13, v15
v_mul_f32_e32 v13, v6, v5
ROUND_BF16 12 16
ROUND_BF16 13 16
v_lshl_or_b32 v12, v13, 16, v12

// One lane per wave stores two consecutive BF16 intermediates.
v_cmp_eq_u32_e32 vcc_lo, 0, v11
s_and_saveexec_b32 s14, vcc_lo
v_lshlrev_b32_e32 v2, 1, v10
global_store_b32 v2, v12, s[8:9]
s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel bf16_shared_gate_up_silu_decode_wave2_gfx1151
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
.amdhsa_next_free_vgpr 18
.amdhsa_next_free_sgpr 16
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
.size bf16_shared_gate_up_silu_decode_wave2_gfx1151, .Lfunc_end0-bf16_shared_gate_up_silu_decode_wave2_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: weights, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: bf16_shared_gate_up_silu_decode_wave2_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 16
    .sgpr_spill_count: 0
    .symbol: bf16_shared_gate_up_silu_decode_wave2_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 18
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
