// SPDX-License-Identifier: MIT
// Common module and fixed-symbol declarations for gfx950 raw assembly.

	.ifndef NETRA_GFX950_MODULE_INC
	.set NETRA_GFX950_MODULE_INC, 1

	.macro NETRA_GFX950_MODULE_HEADER code_object_version=6
	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version \code_object_version
	.text
	.endm

	.macro NETRA_KERNEL_ENTRY symbol, visibility=1
	.if \visibility
	.protected \symbol
	.endif
	.globl \symbol
	.p2align 8
	.type \symbol,@function
\symbol:
	.endm

	.macro NETRA_KERNEL_FUNCTION_END symbol, end_label=.Lfunc_end0
	.text
\end_label:
	.size \symbol, \end_label-\symbol
	.endm

	.endif
