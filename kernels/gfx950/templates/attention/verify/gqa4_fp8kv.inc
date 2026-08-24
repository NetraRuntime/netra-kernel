// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_00.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_01.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_02.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_03.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_04.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_05.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_06.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4_fp8kv/pipeline_07.inc"
// The fixed GQA4 schedule is decomposed into ordered raw-assembly modules.
// Module calls are resolved by the assembler and add no runtime dispatch.
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_ATTENTION_GQA4_FP8KV symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_00 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_01 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_02 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_03 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_04 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_05 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_06 \symbol
	NETRA_ATTENTION_GQA4_FP8KV_PIPELINE_07 \symbol
	.endm
