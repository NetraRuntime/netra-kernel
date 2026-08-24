// SPDX-License-Identifier: MIT
// Netra gfx950 assembler-time ABI constants and kernel declaration helpers.

	.ifndef NETRA_GFX950_ABI_INC
	.set NETRA_GFX950_ABI_INC, 1

	.set NETRA_EPILOGUE_IDENTITY, 0
	.set NETRA_EPILOGUE_BIAS, 1
	.set NETRA_EPILOGUE_SILU, 2
	.set NETRA_EPILOGUE_GELU, 3
	.set NETRA_EPILOGUE_GATED_SILU, 4

	.macro NETRA_GFX950_KERNEL_BEGIN symbol
	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected \symbol
	.globl \symbol
	.p2align 8
	.type \symbol,@function
\symbol:
	.endm

	.endif
