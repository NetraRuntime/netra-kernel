// SPDX-License-Identifier: MIT
// Model-independent fixed-contract GQA6/M=8/FP8-KV attention family.
//
// Pointer widths are fixed by the engine contract and resolved by the
// assembler. Each leaf retains its measured register allocation and exact
// instruction order. The shared normalization, packing, descriptor, and ABI
// modules are emitted once and no runtime shape branch is introduced.

	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/attention/common/kernel_descriptor.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa_fp8kv_metadata.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa6_m8/output_normalize.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa6_m8/output_pack_first_store.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa6_m8/qo32_kv32_schedule.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa6_m8/qo32_kv64_schedule.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa6_m8/qo64_kv64_schedule.inc"

	NETRA_GFX950_MODULE_HEADER 5

	.macro NETRA_ATTENTION_GQA6_FP8KV_M8 symbol
	.if (NETRA_QO_INDPTR_BITS == 32) && (NETRA_KV_INDEX_BITS == 32)
	NETRA_ATTENTION_GQA6_FP8KV_QO32_KV32 \symbol
	.elseif (NETRA_QO_INDPTR_BITS == 32) && (NETRA_KV_INDEX_BITS == 64)
	NETRA_ATTENTION_GQA6_FP8KV_QO32_KV64 \symbol
	.elseif (NETRA_QO_INDPTR_BITS == 64) && (NETRA_KV_INDEX_BITS == 64)
	NETRA_ATTENTION_GQA6_FP8KV_QO64_KV64 \symbol
	.else
	.error "unsupported fixed GQA6 pointer-width contract"
	.endif
	.endm
