// SPDX-License-Identifier: MIT
// Fixed gfx950/wave64 metadata for the dense five-pointer ABI.

	.ifndef NETRA_GFX950_METADATA_INC
	.set NETRA_GFX950_METADATA_INC, 1

	.macro NETRA_DENSE_FIVE_POINTER_METADATA symbol, lds_bytes, threads, vgprs, sgprs
	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size \lds_bytes
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr \vgprs
		.amdhsa_accum_offset 32
		.amdhsa_next_free_sgpr \sgprs
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size \symbol, .Lfunc_end0-\symbol

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: activation_fp8, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: activation_scale_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: shuffled_weight_fp8, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: weight_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: \lds_bytes
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: \threads
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: \sgprs
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: \vgprs
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm

	.endif
