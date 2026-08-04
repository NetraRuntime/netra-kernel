# gfx950 interleaved packed GDN verification

The Qwen3.6 dFlash M=12 GDN verification kernel now has a
`packed-pair-interleaved` variant. Four independent V-row dot-product chains
are interleaved so gfx950 can cover packed-VALU dependency latency. The kernel
remains raw wave64 AMDGCN and retains the deployed capacity-aware ABI.

On the real checkpoint StatePass2 capture at batch 64, the new core measured
100.941 us median versus 115.821 us for the deployed variant 13 core, a 1.147x
kernel speedup. Triton measured 197.322 us on the same capture. The candidate
changed FP32 reduction order: 163 of 3,145,728 BF16 outputs differed from
Triton, with maximum absolute error 0.0009765625 and mean absolute error
3.17e-10. This is intentional and was advanced through the serving quality
gate rather than described as bit-exact.

Matched single-MI350X serving measurements used Qwen FP8 E4M3 weights, FP8
E4M3 target and draft KV, dFlash block 12, exact random 1,024-input/1,024-output
requests, 192 requests at concurrency 64, 256K context, 16K chunked prefill,
128K max prefill, and 0.90 static memory fraction:

- variant 13 control: 6,637.31 and 6,585.88 output tok/s (median 6,611.595);
- interleaved candidate: 6,691.42 and 6,710.81 output tok/s (median 6,701.115);
- median gain: 1.354%.

The five-shot, thinking-disabled, temperature-zero GSM8K-200 gate scored
189/200 (94.5%) with the interleaved kernel. The retained control range is
95.5--96.0%; the candidate was explicitly accepted despite that sample delta.

Artifacts are retained under:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/
  20260804T002406Z-qwen36-best-gpu6/
  20260804T002854Z-qwen36-best-gpu6/
```

The original experiment is commit `f61f3ff88c79fe8726d1be5b37f21c202d1e1857`
on `codex/gdn-k0-interleaved-unbounded-gfx950`. Only the interleaved arithmetic
and build selection were ported onto current main; older bridge and state-replay
changes from that diverged branch were deliberately not restored.

The first clean-main rebuild also exposed two omitted unsigned pool-index
clamps. With signed `s_min_i32`, graph capture destroyed the HIP context at the
batch-64 verifier. Restoring the tested branch's `s_min_u32` for both initial
and output state indices makes the emitted verification core match the
validated candidate instruction stream.
