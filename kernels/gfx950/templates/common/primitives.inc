// SPDX-License-Identifier: MIT
// Umbrella include for model-independent gfx950 schedule composition.

	.ifndef NETRA_GFX950_PRIMITIVES_INC
	.set NETRA_GFX950_PRIMITIVES_INC, 1

	.include "kernels/gfx950/templates/common/fixed_contract.inc"
	.include "kernels/gfx950/templates/common/module.inc"
	.include "kernels/gfx950/templates/common/kernargs.inc"
	.include "kernels/gfx950/templates/common/synchronization.inc"
	.include "kernels/gfx950/templates/common/addressing.inc"
	.include "kernels/gfx950/templates/common/mfma.inc"
	.include "kernels/gfx950/templates/common/reductions.inc"
	.include "kernels/gfx950/templates/common/numerics.inc"

	.endif
