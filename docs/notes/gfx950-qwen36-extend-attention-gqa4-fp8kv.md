# Qwen3.6 gfx950 grouped-GQA4 FP8-KV extend attention

Date: 2026-08-04

## Decision

Promote the raw gfx950 grouped-GQA4 extend-attention code object for the Qwen
dFlash path with native FP8 E4M3 KV cache. The production source is
`kernels/gfx950/attention/verify/qwen36_extend_attention_m16_gqa4_fp8kv_gfx950.s`.
The bridge accepts graph batches through 256 and is preloaded before graph
capture.

The dispatch is deliberately narrow: BF16 Q/K/V extension and output, FP8 E4M3
K/V cache, GQA4, head dimension 128, maximum extension 16, causal window 4095,
unit cache scales, no custom mask, sinks, or logit cap. All other shapes remain
on the deployed SGLang implementation.

The instruction body was captured from the measured grouped Triton oracle and
then named, assembled, linked, and dispatched independently as raw AMDGCN. This
promotion establishes the production raw-assembly baseline; it does not claim
that the inherited instruction schedule is the final hand-scheduled CDNA4
implementation.

## Isolated validation

The retained real-checkpoint shape has batch 63, actual M 756, maximum extension
12, 32 query heads, 8 KV heads, dimension 128, int64 QO pointers, int32 KV
pointers, int64 KV indices, and window 4095. Against the recomputed grouped
Triton FP8-KV oracle, 26 of 3,096,576 BF16 outputs differed. Maximum absolute
error was 0.0078125, cosine similarity was 1.0, RMSE was 9.559e-6, and neither
output contained NaN or Inf.

In one process over 100 HIP-event repetitions, the independently assembled raw
kernel measured 122.740 us median. The same grouped Triton launch measured
130.120 us, while the deployed one-wave Triton layout measured 185.200 us. The
raw kernel is 33.7% below the deployed layout median.

The code object is gfx950, wave64, 256 threads, 136 VGPR, 82 SGPR, zero scratch,
and 16,384 bytes dynamic LDS. Live graph capture logged a positive raw dispatch
at batch 256 with 3,072 extension tokens and FP8 E4M3 K/V buffers.

## Serving and quality gates

The exact serving gate used one MI350X, 192 random requests, concurrency 64,
exactly 1,024 input and 1,024 forced output tokens, dFlash block 12, FP8 target
and draft KV, context 262,144, chunk 16,384, and max-prefill 131,072.

- warmed candidate repeats: 6,770.06 and 6,783.26 output tok/s;
- reverse-order warmed control repeats: 6,755.84 and 6,589.23 output tok/s;
- candidate mean 6,776.66 versus control mean 6,672.54: +1.56%;
- acceptance remained effectively unchanged (candidate 4.20--4.21).

The established 200-question chat-format, thinking-disabled GSM8K gate at
concurrency 64 scored 97.0% with 2.0% invalid for the raw candidate, versus
94.5% with 2.5% invalid for the reverse-order control.

## Evidence

- oracle and raw microbenchmark:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T024500Z-gqa4-fp8kv-oracle-gpu6/`
- candidate serving:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T025936Z-qwen36-best-gpu6/`
- reverse-order control:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T030505Z-qwen36-best-gpu6/`
- candidate GSM8K and positive batch-256 dispatch:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T031533Z-qwen36-best-gpu6/`
