// SPDX-License-Identifier: MIT
// Typed kernarg loads. Arguments are assembler registers, never runtime names.

	.ifndef NETRA_GFX950_KERNARGS_INC
	.set NETRA_GFX950_KERNARGS_INC, 1

	.macro NETRA_LOAD_KERNARG_PTR destination, byte_offset
	s_load_dwordx2 \destination, s[0:1], \byte_offset
	.endm

	.macro NETRA_LOAD_KERNARG_U32 destination, byte_offset
	s_load_dword \destination, s[0:1], \byte_offset
	.endm

	.macro NETRA_LOAD_KERNARG_U64 destination, byte_offset
	s_load_dwordx2 \destination, s[0:1], \byte_offset
	.endm

	.macro NETRA_LOAD_KERNARG_U32X4 destination, byte_offset
	s_load_dwordx4 \destination, s[0:1], \byte_offset
	.endm

	.macro NETRA_LOAD_KERNARG_U32X8 destination, byte_offset
	s_load_dwordx8 \destination, s[0:1], \byte_offset
	.endm

	.endif
