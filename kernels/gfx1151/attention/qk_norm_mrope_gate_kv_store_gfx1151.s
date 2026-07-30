// SPDX-License-Identifier: MIT
// Accepted raw gfx1151 Qwen3.6 standard-attention preparation fusion.
// Fuses interleaved Q/gate extraction, per-head Gemma RMSNorm, partial NeoX
// MRoPE, K output, and page-size-1 BF16 K/V cache stores.
// Fixed Hq=16, Hkv=2, D=256, rotary_dim=64, qkv row=9216 BF16.
// Grid=(M,1,1), block=128 (four wave32; four Q heads per wave).
.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

// Match Triton's four-wave BLOCK_SIZE=256 reduction association while each
// raw wave owns one head. A/B hold consecutive 32-element halves. Triton
// squares adjacent BF16 pairs, reduces each 64-element wave chunk, then folds
// its four partials as (p0+p2)+(p1+p3).
.macro TRITON_QUARTER_SUM A B OUT
  v_and_b32_e32 v32, 15, v0
  v_lshlrev_b32_e32 v31, 3, v32
  ds_bpermute_b32 v20, v31, v[\A]
  ds_bpermute_b32 v22, v31, v[\B]
  v_add_nc_u32_e32 v31, 4, v31
  ds_bpermute_b32 v21, v31, v[\A]
  ds_bpermute_b32 v23, v31, v[\B]
  s_waitcnt lgkmcnt(0)
  v_and_b32_e32 v33, 31, v0
  v_cmp_gt_u32_e32 vcc_lo, 16, v33
  v_cndmask_b32_e32 v20, v22, v20, vcc_lo
  v_cndmask_b32_e32 v21, v23, v21, vcc_lo
  v_mul_f32_e32 v[\OUT], v21, v21
  v_fmac_f32_e32 v[\OUT], v20, v20
  v_add_f32_dpp v[\OUT], v[\OUT], v[\OUT] row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_add_f32_dpp v[\OUT], v[\OUT], v[\OUT] row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_add_f32_dpp v[\OUT], v[\OUT], v[\OUT] row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_add_f32_dpp v[\OUT], v[\OUT], v[\OUT] row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
  v_permlanex16_b32 v30, v[\OUT], -1, -1 op_sel:[1,0]
  v_add_f32_e32 v[\OUT], v[\OUT], v30
  v_mov_b32_e32 v31, 124
  ds_bpermute_b32 v[\OUT], v31, v[\OUT]
  s_waitcnt lgkmcnt(0)
.endm

// Round FP32 SRC to a BF16 bit-pattern in DST, ties-to-even.
.macro ROUND_BF16 SRC DST TMP
  v_lshrrev_b32_e32 v[\TMP], 16, v[\SRC]
  v_and_b32_e32 v[\TMP], 1, v[\TMP]
  v_add_nc_u32_e32 v[\TMP], 0x7fff, v[\TMP]
  v_add_nc_u32_e32 v[\DST], v[\TMP], v[\SRC]
  v_lshrrev_b32_e32 v[\DST], 16, v[\DST]
.endm

.macro LOAD8 BASE
  global_load_ushort v4, v1, s[\BASE:\BASE+1]
  global_load_ushort v5, v1, s[\BASE:\BASE+1] offset:64
  global_load_ushort v6, v1, s[\BASE:\BASE+1] offset:128
  global_load_ushort v7, v1, s[\BASE:\BASE+1] offset:192
  global_load_ushort v8, v1, s[\BASE:\BASE+1] offset:256
  global_load_ushort v9, v1, s[\BASE:\BASE+1] offset:320
  global_load_ushort v10, v1, s[\BASE:\BASE+1] offset:384
  global_load_ushort v11, v1, s[\BASE:\BASE+1] offset:448
.endm

.macro STORE8 BASE REGS
  global_store_short v1, v[\REGS+0], s[\BASE:\BASE+1]
  global_store_short v1, v[\REGS+1], s[\BASE:\BASE+1] offset:64
  global_store_short v1, v[\REGS+2], s[\BASE:\BASE+1] offset:128
  global_store_short v1, v[\REGS+3], s[\BASE:\BASE+1] offset:192
  global_store_short v1, v[\REGS+4], s[\BASE:\BASE+1] offset:256
  global_store_short v1, v[\REGS+5], s[\BASE:\BASE+1] offset:320
  global_store_short v1, v[\REGS+6], s[\BASE:\BASE+1] offset:384
  global_store_short v1, v[\REGS+7], s[\BASE:\BASE+1] offset:448
.endm

.macro NORMALIZE_ROUND
  TRITON_QUARTER_SUM 4 5 24
  TRITON_QUARTER_SUM 6 7 25
  TRITON_QUARTER_SUM 8 9 26
  TRITON_QUARTER_SUM 10 11 27
  v_add_f32_e32 v30, v24, v26
  v_add_f32_e32 v31, v25, v27
  v_add_f32_e32 v30, v30, v31
  v_mov_b32_e32 v33, 0x358637bd
  v_fmac_f32_e32 v33, 0x3b800000, v30
  v_rsq_f32_e32 v30, v33

  v_add_f32_e32 v33, 1.0, v12
  v_mul_f32_e32 v4, v4, v30
  v_mul_f32_e32 v4, v4, v33
  v_add_f32_e32 v33, 1.0, v13
  v_mul_f32_e32 v5, v5, v30
  v_mul_f32_e32 v5, v5, v33
  v_add_f32_e32 v33, 1.0, v14
  v_mul_f32_e32 v6, v6, v30
  v_mul_f32_e32 v6, v6, v33
  v_add_f32_e32 v33, 1.0, v15
  v_mul_f32_e32 v7, v7, v30
  v_mul_f32_e32 v7, v7, v33
  v_add_f32_e32 v33, 1.0, v16
  v_mul_f32_e32 v8, v8, v30
  v_mul_f32_e32 v8, v8, v33
  v_add_f32_e32 v33, 1.0, v17
  v_mul_f32_e32 v9, v9, v30
  v_mul_f32_e32 v9, v9, v33
  v_add_f32_e32 v33, 1.0, v18
  v_mul_f32_e32 v10, v10, v30
  v_mul_f32_e32 v10, v10, v33
  v_add_f32_e32 v33, 1.0, v19
  v_mul_f32_e32 v11, v11, v30
  v_mul_f32_e32 v11, v11, v33

  ROUND_BF16 4 20 32
  ROUND_BF16 5 21 32
  ROUND_BF16 6 22 32
  ROUND_BF16 7 23 32
  ROUND_BF16 8 24 32
  ROUND_BF16 9 25 32
  ROUND_BF16 10 26 32
  ROUND_BF16 11 27 32

  // gfx1151 v_dot2_bf16_bf16 returns the rounded BF16 product in
  // the low half when the second packed lane is zero, matching Triton.
  v_dot2_bf16_bf16 v30, v20, v29, 0
  v_lshlrev_b32_e32 v30, 16, v30
  v_dot2_bf16_bf16 v31, v21, v28, 0
  v_lshlrev_b32_e32 v31, 16, v31
  v_sub_f32_e32 v30, v30, v31
  ROUND_BF16 30 33 32
  v_dot2_bf16_bf16 v30, v21, v29, 0
  v_lshlrev_b32_e32 v30, 16, v30
  v_dot2_bf16_bf16 v31, v20, v28, 0
  v_lshlrev_b32_e32 v31, 16, v31
  v_add_f32_e32 v30, v30, v31
  ROUND_BF16 30 21 32
  v_mov_b32_e32 v20, v33
.endm

.macro PROCESS_Q HADD
  // q/gate input head byte offset = wave*4096 + HADD*1024.
  s_lshl_b32 s36, s3, 12
  s_add_u32 s36, s36, (\HADD * 1024)
  s_add_u32 s40, s4, s27
  s_addc_u32 s41, s5, 0
  s_add_u32 s40, s40, s36
  s_addc_u32 s41, s41, 0
  s_add_u32 s42, s40, 512
  s_addc_u32 s43, s41, 0

  // q/gate output head byte offset = wave*2048 + HADD*512.
  s_lshl_b32 s37, s3, 11
  s_add_u32 s37, s37, (\HADD * 512)
  s_add_u32 s44, s10, s28
  s_addc_u32 s45, s11, 0
  s_add_u32 s44, s44, s37
  s_addc_u32 s45, s45, 0
  s_add_u32 s46, s6, s28
  s_addc_u32 s47, s7, 0
  s_add_u32 s46, s46, s37
  s_addc_u32 s47, s47, 0

  // Copy gate while the eight output registers are free.
  global_load_ushort v20, v1, s[42:43]
  global_load_ushort v21, v1, s[42:43] offset:64
  global_load_ushort v22, v1, s[42:43] offset:128
  global_load_ushort v23, v1, s[42:43] offset:192
  global_load_ushort v24, v1, s[42:43] offset:256
  global_load_ushort v25, v1, s[42:43] offset:320
  global_load_ushort v26, v1, s[42:43] offset:384
  global_load_ushort v27, v1, s[42:43] offset:448
  LOAD8 40
  s_waitcnt vmcnt(0)
  STORE8 44 20

  v_lshlrev_b32_e32 v4, 16, v4
  v_lshlrev_b32_e32 v5, 16, v5
  v_lshlrev_b32_e32 v6, 16, v6
  v_lshlrev_b32_e32 v7, 16, v7
  v_lshlrev_b32_e32 v8, 16, v8
  v_lshlrev_b32_e32 v9, 16, v9
  v_lshlrev_b32_e32 v10, 16, v10
  v_lshlrev_b32_e32 v11, 16, v11
  NORMALIZE_ROUND
  STORE8 46 20
.endm

.protected qk_norm_mrope_gate_kv_store_gfx1151
.globl qk_norm_mrope_gate_kv_store_gfx1151
.p2align 8
.type qk_norm_mrope_gate_kv_store_gfx1151,@function
qk_norm_mrope_gate_kv_store_gfx1151:
s_clause 0x5
s_load_b128 s[4:7], s[0:1], 0
s_load_b128 s[8:11], s[0:1], 16
s_load_b128 s[12:15], s[0:1], 32
s_load_b128 s[16:19], s[0:1], 48
s_load_b128 s[20:23], s[0:1], 64
s_load_b64 s[24:25], s[0:1], 80
s_load_dword s26, s[0:1], 88
s_load_dword s39, s[0:1], 92
s_waitcnt lgkmcnt(0)

// wave=tid/32, lane=tid%32; per-lane byte offset covers d=lane+32*j.
v_lshrrev_b32_e32 v2, 5, v0
v_readfirstlane_b32 s3, v2
v_and_b32_e32 v1, 31, v0
v_lshlrev_b32_e32 v1, 1, v1

// Fixed row byte offsets.
s_mul_i32 s27, s2, 18432
s_lshl_b32 s28, s2, 13
s_lshl_b32 s29, s2, 10

// Wave 0 loads the 32 position-selected cos/sin pairs once into 128 B LDS.
s_cmp_eq_u32 s3, 0
s_cbranch_scc0 .Lcos_ready
s_lshl_b32 s30, s2, 3
s_load_dword s31, s[18:19], s30
s_mov_b32 s32, s39
s_add_u32 s33, s30, s32
s_load_dword s34, s[18:19], s33
s_add_u32 s33, s33, s32
s_load_dword s35, s[18:19], s33
s_waitcnt lgkmcnt(0)

v_and_b32_e32 v30, 31, v0
v_mul_hi_u32 v31, v30, 0xaaaaaaab
v_lshrrev_b32_e32 v31, 1, v31
v_mul_lo_u32 v32, v31, 3
v_sub_nc_u32_e32 v32, v30, v32
v_mov_b32_e32 v33, s31
v_cmp_eq_u32_e32 vcc_lo, 1, v32
v_mov_b32_e32 v31, s34
v_cndmask_b32_e32 v33, v33, v31, vcc_lo
v_cmp_eq_u32_e32 vcc_lo, 2, v32
v_mov_b32_e32 v31, s35
v_cndmask_b32_e32 v33, v33, v31, vcc_lo
v_lshlrev_b32_e32 v33, 7, v33
v_lshlrev_b32_e32 v30, 1, v30
v_add_nc_u32_e32 v33, v33, v30
global_load_ushort v28, v33, s[16:17]
global_load_ushort v29, v33, s[16:17] offset:64
s_waitcnt vmcnt(0)
v_lshlrev_b32_e32 v29, 16, v29
v_or_b32_e32 v28, v28, v29
v_lshlrev_b32_e32 v30, 2, v0
ds_write_b32 v30, v28
s_waitcnt lgkmcnt(0)
.Lcos_ready:
s_barrier
v_and_b32_e32 v30, 31, v0
v_lshlrev_b32_e32 v30, 2, v30
ds_read_b32 v31, v30
s_waitcnt lgkmcnt(0)
v_and_b32_e32 v29, 0xffff, v31
v_lshrrev_b32_e32 v28, 16, v31

// Q Gemma weights are shared by all heads; load once per wave.
global_load_ushort v12, v1, s[12:13]
global_load_ushort v13, v1, s[12:13] offset:64
global_load_ushort v14, v1, s[12:13] offset:128
global_load_ushort v15, v1, s[12:13] offset:192
global_load_ushort v16, v1, s[12:13] offset:256
global_load_ushort v17, v1, s[12:13] offset:320
global_load_ushort v18, v1, s[12:13] offset:384
global_load_ushort v19, v1, s[12:13] offset:448
s_waitcnt vmcnt(0)
v_lshlrev_b32_e32 v12, 16, v12
v_lshlrev_b32_e32 v13, 16, v13
v_lshlrev_b32_e32 v14, 16, v14
v_lshlrev_b32_e32 v15, 16, v15
v_lshlrev_b32_e32 v16, 16, v16
v_lshlrev_b32_e32 v17, 16, v17
v_lshlrev_b32_e32 v18, 16, v18
v_lshlrev_b32_e32 v19, 16, v19

PROCESS_Q 0
PROCESS_Q 1
PROCESS_Q 2
PROCESS_Q 3

// Only waves 0/1 own one KV head each.
s_cmp_lt_u32 s3, 2
s_cbranch_scc0 .Ldone

// K/V input pointers: K starts at byte 16384, V at 17408.
s_lshl_b32 s36, s3, 9
s_add_u32 s36, s36, s27
s_add_u32 s40, s4, s36
s_addc_u32 s41, s5, 0
s_add_u32 s40, s40, 16384
s_addc_u32 s41, s41, 0
s_add_u32 s42, s40, 1024
s_addc_u32 s43, s41, 0

// K output row/head pointer.
s_add_u32 s44, s8, s29
s_addc_u32 s45, s9, 0
s_lshl_b32 s37, s3, 9
s_add_u32 s44, s44, s37
s_addc_u32 s45, s45, 0

// Load K weights, K, and V. V is copied directly to its cache row.
global_load_ushort v12, v1, s[14:15]
global_load_ushort v13, v1, s[14:15] offset:64
global_load_ushort v14, v1, s[14:15] offset:128
global_load_ushort v15, v1, s[14:15] offset:192
global_load_ushort v16, v1, s[14:15] offset:256
global_load_ushort v17, v1, s[14:15] offset:320
global_load_ushort v18, v1, s[14:15] offset:384
global_load_ushort v19, v1, s[14:15] offset:448
LOAD8 40
global_load_ushort v20, v1, s[42:43]
global_load_ushort v21, v1, s[42:43] offset:64
global_load_ushort v22, v1, s[42:43] offset:128
global_load_ushort v23, v1, s[42:43] offset:192
global_load_ushort v24, v1, s[42:43] offset:256
global_load_ushort v25, v1, s[42:43] offset:320
global_load_ushort v26, v1, s[42:43] offset:384
global_load_ushort v27, v1, s[42:43] offset:448
s_waitcnt vmcnt(0)

// Read page-size-1 physical cache slot and form K/V cache head pointers.
s_lshl_b32 s30, s2, 3
s_load_dword s38, s[24:25], s30
s_waitcnt lgkmcnt(0)
s_lshl_b32 s38, s38, 10
s_add_u32 s38, s38, s37
s_add_u32 s46, s22, s38
s_addc_u32 s47, s23, 0
STORE8 46 20

v_lshlrev_b32_e32 v12, 16, v12
v_lshlrev_b32_e32 v13, 16, v13
v_lshlrev_b32_e32 v14, 16, v14
v_lshlrev_b32_e32 v15, 16, v15
v_lshlrev_b32_e32 v16, 16, v16
v_lshlrev_b32_e32 v17, 16, v17
v_lshlrev_b32_e32 v18, 16, v18
v_lshlrev_b32_e32 v19, 16, v19
v_lshlrev_b32_e32 v4, 16, v4
v_lshlrev_b32_e32 v5, 16, v5
v_lshlrev_b32_e32 v6, 16, v6
v_lshlrev_b32_e32 v7, 16, v7
v_lshlrev_b32_e32 v8, 16, v8
v_lshlrev_b32_e32 v9, 16, v9
v_lshlrev_b32_e32 v10, 16, v10
v_lshlrev_b32_e32 v11, 16, v11
NORMALIZE_ROUND
STORE8 44 20
s_add_u32 s46, s20, s38
s_addc_u32 s47, s21, 0
STORE8 46 20

.Ldone:
s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel qk_norm_mrope_gate_kv_store_gfx1151
.amdhsa_group_segment_fixed_size 128
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 96
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 0
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 34
.amdhsa_next_free_sgpr 48
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
.size qk_norm_mrope_gate_kv_store_gfx1151, .Lend-qk_norm_mrope_gate_kv_store_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: qkv, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: q_out, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: k_out, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: gate_out, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: q_weight, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: k_weight, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: cos_sin, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: positions, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: k_cache, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: v_cache, .offset: 72, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: cache_loc, .offset: 80, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: tokens, .offset: 88, .size: 4, .value_kind: by_value }
      - { .name: position_stride_bytes, .offset: 92, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 128
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .language: OpenCL C
    .language_version: [2, 0]
    .name: qk_norm_mrope_gate_kv_store_gfx1151
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .max_flat_workgroup_size: 128
    .private_segment_fixed_size: 0
    .sgpr_count: 48
    .sgpr_spill_count: 0
    .symbol: qk_norm_mrope_gate_kv_store_gfx1151.kd
    .vgpr_count: 34
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
