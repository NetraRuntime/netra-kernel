// SPDX-License-Identifier: MIT
// Model-independent fixed-contract routed-expert prefill producer.
//
// The public tactic is one kernel contract. The includes below only separate
// semantic stages of its accepted register schedule so addressing, W13,
// activation quantization, W2, partial stores, and metadata can be audited
// without numbered or runtime-selectable pipelines.

	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/moe/prefill/fused_splitk2/entry_routing.inc"
	.include "kernels/gfx950/templates/moe/prefill/fused_splitk2/gate_up.inc"
	.include "kernels/gfx950/templates/moe/prefill/fused_splitk2/silu_quant.inc"
	.include "kernels/gfx950/templates/moe/prefill/fused_splitk2/down_partial.inc"
	.include "kernels/gfx950/templates/moe/prefill/fused_splitk2/metadata.inc"

	NETRA_GFX950_MODULE_HEADER 6

	.macro NETRA_MOE_PREFILL_FUSED_SPLITK2_FP8 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_ROWS, 768
	NETRA_REQUIRE_EQ NETRA_HIDDEN_SIZE, 2048
	NETRA_REQUIRE_EQ NETRA_INTERMEDIATE_SIZE, 512
	NETRA_REQUIRE_EQ NETRA_EXPERTS, 257
	NETRA_REQUIRE_EQ NETRA_TOPK, 9
	NETRA_REQUIRE_EQ NETRA_ROUTE_BLOCK, 64
	NETRA_REQUIRE_EQ NETRA_SCALE_BLOCK, 128
	NETRA_REQUIRE_EQ NETRA_SPLIT_K, 2
	NETRA_REQUIRE_EQ NETRA_WEIGHT_LAYOUT_ID, 1
	NETRA_MOE_PREFILL_FUSED_SPLITK2_ENTRY_ROUTING \symbol
	NETRA_MOE_PREFILL_FUSED_SPLITK2_GATE_UP
	NETRA_MOE_PREFILL_FUSED_SPLITK2_SILU_QUANT
	NETRA_MOE_PREFILL_FUSED_SPLITK2_DOWN_PARTIAL
	NETRA_MOE_PREFILL_FUSED_SPLITK2_METADATA \symbol
	.endm
