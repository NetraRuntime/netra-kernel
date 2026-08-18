# Qwen3.6 gfx950 grouped-GQA4 extend attention

The accepted production source is
`kernels/gfx950/attention/verify/qwen36_extend_attention_m16_gqa4_gfx950.s`.
It targets gfx950 explicitly, uses wave64 and a 256-thread workgroup, and
groups four query heads that share one KV head. The HIP runtime bridge performs
module loading and dispatch only.

The live dFlash piecewise-graph ABI is BF16 Q/K/V/O with 32 query heads, eight
KV heads, dimension 128, maximum extension 12, int64 `qo_indptr`, int32
`kv_indptr`, and int64 `kv_indices`. The build script rejects a code object
whose metadata does not declare gfx950.

On the retained real-checkpoint batch-63 capture, the int64-ABI raw replay was
deterministic with max absolute error 0.015625, cosine 0.99999994, no NaN/Inf,
and a 145.442 us HIP-event median. The same-process screen measured 148.602 us
raw versus 209.562 us for the deployed one-wave Triton kernel (29.1% lower).

The integration passed exact repeated token hashes, same-GPU serving A/B, and
GSM8K-200 (0.955 for control and raw). Full serving evidence is recorded in
the netra-server gfx950 notes and under the dated `/data/netra/benchmarks`
artifacts.

Rejected experiments remain in `verify/experiments`: moving scalar spills to
free SGPRs was slower, DPP rescheduling was neutral, and alternate N tiles
changed the reduction result.
