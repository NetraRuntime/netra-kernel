// SPDX-License-Identifier: MIT
// Shared fixed-contract AMDHSA descriptor for gfx950 attention schedules.
//
// All arguments are assembler-time constants. The macro emits no dispatch,
// shape selection, allocation, or other runtime policy.

	.ifndef NETRA_GFX950_ATTENTION_DESCRIPTOR_INC
	.set NETRA_GFX950_ATTENTION_DESCRIPTOR_INC, 1

	.macro NETRA_ATTENTION_KERNEL_DESCRIPTOR symbol, lds_bytes, kernarg_bytes, workgroup_y, workgroup_z, next_vgpr, next_sgpr, accum_offset
	.section	.rodata,"a",@progbits
	.p2align	6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size \lds_bytes
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size \kernarg_bytes
		.amdhsa_user_sgpr_count 16
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 14
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y \workgroup_y
		.amdhsa_system_sgpr_workgroup_id_z \workgroup_z
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr \next_vgpr
		.amdhsa_next_free_sgpr \next_sgpr
		.amdhsa_accum_offset \accum_offset
		.amdhsa_reserve_vcc 1
		.amdhsa_reserve_xnack_mask 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.endm

	.endif
