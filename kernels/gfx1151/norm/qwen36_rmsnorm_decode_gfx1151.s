// SPDX-License-Identifier: MIT
// Raw gfx1151 M=1, N=2048 Qwen3.6 RMSNorm kernels decode.
// Fused semantics: residual=bf16(x+residual), then normalize that value.
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.macro ROUND_BF16 SRC DST TMP
  v_lshrrev_b32_e32 v[\TMP], 16, v[\SRC]
  v_and_b32_e32 v[\TMP], 1, v[\TMP]
  v_add_nc_u32_e32 v[\TMP], 0x7fff, v[\TMP]
  v_add_nc_u32_e32 v[\DST], v[\TMP], v[\SRC]
  v_lshrrev_b32_e32 v[\DST], 16, v[\DST]
.endm

.macro REDUCE_WAVE VALUE TMP
  v_add_f32_dpp v[\VALUE], v[\VALUE], v[\VALUE] row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_add_f32_dpp v[\VALUE], v[\VALUE], v[\VALUE] row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_add_f32_dpp v[\VALUE], v[\VALUE], v[\VALUE] row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_add_f32_dpp v[\VALUE], v[\VALUE], v[\VALUE] row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_permlanex16_b32 v[\TMP], v[\VALUE], -1, -1 op_sel:[1,0]
  v_add_f32_e32 v[\VALUE], v[\VALUE], v[\TMP]
  v_mov_b32_e32 v[\TMP], 124
  ds_bpermute_b32 v[\VALUE], v[\TMP], v[\VALUE]
  s_waitcnt lgkmcnt(0)
.endm

.macro LOAD_X BASE
  global_load_ushort v4, v2, s[\BASE:\BASE+1]
  global_load_ushort v5, v2, s[\BASE:\BASE+1] offset:512
  global_load_ushort v6, v2, s[\BASE:\BASE+1] offset:1024
  global_load_ushort v7, v2, s[\BASE:\BASE+1] offset:1536
  global_load_ushort v8, v2, s[\BASE:\BASE+1] offset:2048
  global_load_ushort v9, v2, s[\BASE:\BASE+1] offset:2560
  global_load_ushort v10, v2, s[\BASE:\BASE+1] offset:3072
  global_load_ushort v11, v2, s[\BASE:\BASE+1] offset:3584
.endm

.macro LOAD_WEIGHT BASE
  global_load_ushort v12, v2, s[\BASE:\BASE+1]
  global_load_ushort v13, v2, s[\BASE:\BASE+1] offset:512
  global_load_ushort v14, v2, s[\BASE:\BASE+1] offset:1024
  global_load_ushort v15, v2, s[\BASE:\BASE+1] offset:1536
  global_load_ushort v16, v2, s[\BASE:\BASE+1] offset:2048
  global_load_ushort v17, v2, s[\BASE:\BASE+1] offset:2560
  global_load_ushort v18, v2, s[\BASE:\BASE+1] offset:3072
  global_load_ushort v19, v2, s[\BASE:\BASE+1] offset:3584
.endm

.macro BF16_TO_F32
  v_lshlrev_b32_e32 v4, 16, v4
  v_lshlrev_b32_e32 v5, 16, v5
  v_lshlrev_b32_e32 v6, 16, v6
  v_lshlrev_b32_e32 v7, 16, v7
  v_lshlrev_b32_e32 v8, 16, v8
  v_lshlrev_b32_e32 v9, 16, v9
  v_lshlrev_b32_e32 v10, 16, v10
  v_lshlrev_b32_e32 v11, 16, v11
.endm

.macro WEIGHT_BF16_TO_F32
  v_lshlrev_b32_e32 v12, 16, v12
  v_lshlrev_b32_e32 v13, 16, v13
  v_lshlrev_b32_e32 v14, 16, v14
  v_lshlrev_b32_e32 v15, 16, v15
  v_lshlrev_b32_e32 v16, 16, v16
  v_lshlrev_b32_e32 v17, 16, v17
  v_lshlrev_b32_e32 v18, 16, v18
  v_lshlrev_b32_e32 v19, 16, v19
.endm

.macro SUM_SQUARES
  v_mul_f32_e32 v28, v4, v4
  v_fmac_f32_e32 v28, v5, v5
  v_fmac_f32_e32 v28, v6, v6
  v_fmac_f32_e32 v28, v7, v7
  v_fmac_f32_e32 v28, v8, v8
  v_fmac_f32_e32 v28, v9, v9
  v_fmac_f32_e32 v28, v10, v10
  v_fmac_f32_e32 v28, v11, v11
  REDUCE_WAVE 28 29
.endm

.macro REDUCE_WORKGROUP EPS_SGPR PREFIX
  v_cmp_eq_u32_e32 vcc_lo, 0, v1
  s_and_saveexec_b32 s12, vcc_lo
  v_mov_b32_e32 v30, s2
  v_lshlrev_b32_e32 v30, 2, v30
  ds_write_b32 v30, v28
  s_mov_b32 exec_lo, s12
  s_barrier
  s_cmp_eq_u32 s2, 0
  s_cbranch_scc0 .Lwg_reduced_\PREFIX
  v_lshlrev_b32_e32 v30, 2, v1
  ds_read_b32 v29, v30
  s_waitcnt lgkmcnt(0)
  v_cmp_gt_u32_e32 vcc_lo, 8, v1
  v_cndmask_b32_e32 v28, 0, v29, vcc_lo
  REDUCE_WAVE 28 29
  v_cmp_eq_u32_e32 vcc_lo, 0, v1
  s_and_saveexec_b32 s12, vcc_lo
  v_mul_f32_e32 v28, 0x3a000000, v28
  v_add_f32_e32 v28, s[\EPS_SGPR], v28
  v_rsq_f32_e32 v28, v28
  ds_write_b32 v0, v28
  s_mov_b32 exec_lo, s12
.Lwg_reduced_\PREFIX:
  s_barrier
  v_mov_b32_e32 v30, 0
  ds_read_b32 v28, v30
  s_waitcnt lgkmcnt(0)
.endm

.macro NORMALIZE_AND_STORE OUT_BASE
  v_add_f32_e32 v30, 1.0, v12
  v_mul_f32_e32 v4, v4, v28
  v_mul_f32_e32 v4, v4, v30
  v_add_f32_e32 v30, 1.0, v13
  v_mul_f32_e32 v5, v5, v28
  v_mul_f32_e32 v5, v5, v30
  v_add_f32_e32 v30, 1.0, v14
  v_mul_f32_e32 v6, v6, v28
  v_mul_f32_e32 v6, v6, v30
  v_add_f32_e32 v30, 1.0, v15
  v_mul_f32_e32 v7, v7, v28
  v_mul_f32_e32 v7, v7, v30
  v_add_f32_e32 v30, 1.0, v16
  v_mul_f32_e32 v8, v8, v28
  v_mul_f32_e32 v8, v8, v30
  v_add_f32_e32 v30, 1.0, v17
  v_mul_f32_e32 v9, v9, v28
  v_mul_f32_e32 v9, v9, v30
  v_add_f32_e32 v30, 1.0, v18
  v_mul_f32_e32 v10, v10, v28
  v_mul_f32_e32 v10, v10, v30
  v_add_f32_e32 v30, 1.0, v19
  v_mul_f32_e32 v11, v11, v28
  v_mul_f32_e32 v11, v11, v30
  ROUND_BF16 4 20 31
  ROUND_BF16 5 21 31
  ROUND_BF16 6 22 31
  ROUND_BF16 7 23 31
  ROUND_BF16 8 24 31
  ROUND_BF16 9 25 31
  ROUND_BF16 10 26 31
  ROUND_BF16 11 27 31
  global_store_short v2, v20, s[\OUT_BASE:\OUT_BASE+1]
  global_store_short v2, v21, s[\OUT_BASE:\OUT_BASE+1] offset:512
  global_store_short v2, v22, s[\OUT_BASE:\OUT_BASE+1] offset:1024
  global_store_short v2, v23, s[\OUT_BASE:\OUT_BASE+1] offset:1536
  global_store_short v2, v24, s[\OUT_BASE:\OUT_BASE+1] offset:2048
  global_store_short v2, v25, s[\OUT_BASE:\OUT_BASE+1] offset:2560
  global_store_short v2, v26, s[\OUT_BASE:\OUT_BASE+1] offset:3072
  global_store_short v2, v27, s[\OUT_BASE:\OUT_BASE+1] offset:3584
.endm

.protected qwen36_rmsnorm_decode_gfx1151
.globl qwen36_rmsnorm_decode_gfx1151
.p2align 8
.type qwen36_rmsnorm_decode_gfx1151,@function
qwen36_rmsnorm_decode_gfx1151:
s_load_b128 s[4:7], s[0:1], 0
s_load_b64 s[8:9], s[0:1], 16
s_load_dword s10, s[0:1], 24
s_waitcnt lgkmcnt(0)
v_and_b32_e32 v1, 31, v0
v_lshrrev_b32_e32 v30, 5, v0
v_readfirstlane_b32 s2, v30
v_lshlrev_b32_e32 v2, 1, v0
v_lshlrev_b32_e32 v3, 2, v0
LOAD_X 4
LOAD_WEIGHT 6
s_waitcnt vmcnt(0)
BF16_TO_F32
SUM_SQUARES
WEIGHT_BF16_TO_F32
REDUCE_WORKGROUP 10 standalone
NORMALIZE_AND_STORE 8
s_endpgm
.Lqwen36_end:
.size qwen36_rmsnorm_decode_gfx1151, .Lqwen36_end-qwen36_rmsnorm_decode_gfx1151

.protected qwen36_fused_add_rmsnorm_decode_gfx1151
.globl qwen36_fused_add_rmsnorm_decode_gfx1151
.p2align 8
.type qwen36_fused_add_rmsnorm_decode_gfx1151,@function
qwen36_fused_add_rmsnorm_decode_gfx1151:
s_load_b128 s[4:7], s[0:1], 0
s_load_b64 s[8:9], s[0:1], 16
s_load_dword s10, s[0:1], 24
s_waitcnt lgkmcnt(0)
v_and_b32_e32 v1, 31, v0
v_lshrrev_b32_e32 v30, 5, v0
v_readfirstlane_b32 s2, v30
v_lshlrev_b32_e32 v2, 1, v0
v_lshlrev_b32_e32 v3, 2, v0
LOAD_X 4
global_load_ushort v20, v2, s[6:7]
global_load_ushort v21, v2, s[6:7] offset:512
global_load_ushort v22, v2, s[6:7] offset:1024
global_load_ushort v23, v2, s[6:7] offset:1536
global_load_ushort v24, v2, s[6:7] offset:2048
global_load_ushort v25, v2, s[6:7] offset:2560
global_load_ushort v26, v2, s[6:7] offset:3072
global_load_ushort v27, v2, s[6:7] offset:3584
LOAD_WEIGHT 8
s_waitcnt vmcnt(0)
BF16_TO_F32
v_lshlrev_b32_e32 v20, 16, v20
WEIGHT_BF16_TO_F32
v_lshlrev_b32_e32 v21, 16, v21
v_lshlrev_b32_e32 v22, 16, v22
v_lshlrev_b32_e32 v23, 16, v23
v_lshlrev_b32_e32 v24, 16, v24
v_lshlrev_b32_e32 v25, 16, v25
v_lshlrev_b32_e32 v26, 16, v26
v_lshlrev_b32_e32 v27, 16, v27
v_add_f32_e32 v4, v4, v20
v_add_f32_e32 v5, v5, v21
v_add_f32_e32 v6, v6, v22
v_add_f32_e32 v7, v7, v23
v_add_f32_e32 v8, v8, v24
v_add_f32_e32 v9, v9, v25
v_add_f32_e32 v10, v10, v26
v_add_f32_e32 v11, v11, v27
ROUND_BF16 4 20 31
ROUND_BF16 5 21 31
ROUND_BF16 6 22 31
ROUND_BF16 7 23 31
ROUND_BF16 8 24 31
ROUND_BF16 9 25 31
ROUND_BF16 10 26 31
ROUND_BF16 11 27 31
global_store_short v2, v20, s[6:7]
global_store_short v2, v21, s[6:7] offset:512
global_store_short v2, v22, s[6:7] offset:1024
global_store_short v2, v23, s[6:7] offset:1536
global_store_short v2, v24, s[6:7] offset:2048
global_store_short v2, v25, s[6:7] offset:2560
global_store_short v2, v26, s[6:7] offset:3072
global_store_short v2, v27, s[6:7] offset:3584
v_lshlrev_b32_e32 v4, 16, v20
v_lshlrev_b32_e32 v5, 16, v21
v_lshlrev_b32_e32 v6, 16, v22
v_lshlrev_b32_e32 v7, 16, v23
v_lshlrev_b32_e32 v8, 16, v24
v_lshlrev_b32_e32 v9, 16, v25
v_lshlrev_b32_e32 v10, 16, v26
v_lshlrev_b32_e32 v11, 16, v27
SUM_SQUARES
REDUCE_WORKGROUP 10 fused
NORMALIZE_AND_STORE 4
s_endpgm
.Lfused_end:
.size qwen36_fused_add_rmsnorm_decode_gfx1151, .Lfused_end-qwen36_fused_add_rmsnorm_decode_gfx1151

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel qwen36_rmsnorm_decode_gfx1151
.amdhsa_group_segment_fixed_size 32
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 32
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 0
.amdhsa_system_sgpr_workgroup_id_y 0
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 32
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
.amdhsa_kernel qwen36_fused_add_rmsnorm_decode_gfx1151
.amdhsa_group_segment_fixed_size 32
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 32
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 0
.amdhsa_system_sgpr_workgroup_id_y 0
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 32
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

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: input, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: weight, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: epsilon, .offset: 24, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .name: qwen36_rmsnorm_decode_gfx1151
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .max_flat_workgroup_size: 256
    .private_segment_fixed_size: 0
    .sgpr_count: 13
    .sgpr_spill_count: 0
    .symbol: qwen36_rmsnorm_decode_gfx1151.kd
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
  - .args:
      - { .name: input, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: residual, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: weight, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: epsilon, .offset: 24, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 32
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .name: qwen36_fused_add_rmsnorm_decode_gfx1151
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .max_flat_workgroup_size: 256
    .private_segment_fixed_size: 0
    .sgpr_count: 13
    .sgpr_spill_count: 0
    .symbol: qwen36_fused_add_rmsnorm_decode_gfx1151.kd
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
