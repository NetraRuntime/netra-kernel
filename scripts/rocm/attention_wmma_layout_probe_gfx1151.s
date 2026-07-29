// SPDX-License-Identifier: MIT
// gfx1151 WMMA layout probe used to derive the raw extend-attention ABI.
// A is row-major BF16[16,16], B is column-major BF16[16,16].
// Raw per-lane accumulators are written as FP32[32,8].

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text
.protected attention_wmma_layout_probe_gfx1151
.globl attention_wmma_layout_probe_gfx1151
.p2align 8
.type attention_wmma_layout_probe_gfx1151,@function
attention_wmma_layout_probe_gfx1151:
  s_clause 0x1
  s_load_b128 s[4:7], s[0:1], 0
  s_load_b64 s[8:9], s[0:1], 16
  s_waitcnt lgkmcnt(0)

  v_and_b32_e32 v1, 15, v0
  v_lshrrev_b32_e32 v2, 4, v0
  v_lshlrev_b32_e32 v3, 5, v1
  v_lshl_add_u32 v3, v2, 4, v3
  global_load_b128 v[16:19], v3, s[4:5]
  global_load_b128 v[24:27], v3, s[6:7]
  s_waitcnt vmcnt(0)

  ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v28, v24 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v29, v25 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v30, v26 offset:swizzle(SWAP,16)
  ds_swizzle_b32 v31, v27 offset:swizzle(SWAP,16)
  s_waitcnt lgkmcnt(0)

  v_dual_mov_b32 v40, 0 :: v_dual_mov_b32 v41, 0
  v_dual_mov_b32 v42, 0 :: v_dual_mov_b32 v43, 0
  v_dual_mov_b32 v44, 0 :: v_dual_mov_b32 v45, 0
  v_dual_mov_b32 v46, 0 :: v_dual_mov_b32 v47, 0
  v_wmma_f32_16x16x16_bf16 v[40:47], v[16:23], v[24:31], v[40:47]

  v_lshlrev_b32_e32 v4, 5, v0
  global_store_b128 v4, v[40:43], s[8:9]
  global_store_b128 v4, v[44:47], s[8:9] offset:16
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel attention_wmma_layout_probe_gfx1151
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 24
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 0
.amdhsa_system_sgpr_workgroup_id_y 0
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 48
.amdhsa_next_free_sgpr 10
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
.size attention_wmma_layout_probe_gfx1151, .Lfunc_end0-attention_wmma_layout_probe_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: a, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: b_column_major, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: raw_c, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: attention_wmma_layout_probe_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 16
    .sgpr_spill_count: 0
    .symbol: attention_wmma_layout_probe_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 48
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
