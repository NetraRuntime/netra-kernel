// SPDX-License-Identifier: MIT
// Explicit wait/barrier schedules. The caller selects the exact sequence.

	.ifndef NETRA_GFX950_SYNCHRONIZATION_INC
	.set NETRA_GFX950_SYNCHRONIZATION_INC, 1

	.macro NETRA_WAIT_LGKM0
	s_waitcnt lgkmcnt(0)
	.endm

	.macro NETRA_WAIT_VM0
	s_waitcnt vmcnt(0)
	.endm

	.macro NETRA_WAIT_VM0_LGKM0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	.endm

	.macro NETRA_BARRIER
	s_barrier
	.endm

	.macro NETRA_WAIT_LGKM0_BARRIER
	s_waitcnt lgkmcnt(0)
	s_barrier
	.endm

	.endif
