# gfx1151 expert weighted-reduction fusion (rejected)

Status: **not enabled in production**. Every number below is measured on gfx1151; no estimates are reported.

## Why it was targeted

The exact uncached 32,768-token process-start trace ranked the post-expert output path among the largest request costs. The vectorized gather family used 324 calls and 1,132.878 ms total, `indexFuncLargeIndex` used 160 calls and 1,132.119 ms total, and the broader elementwise family used 1,054 calls and 1,102.858 ms total. Part of that elementwise cost is router-weight multiplication. The raw down projections separately used 160 calls and 1,201.098 ms total.

The established SGLang path gathers padded expert rows into sorted pair order, applies router weights, then performs an indexed reduction to tokens. This prototype fuses the gather, router-weight application, fixed-order top-8 FP32 reduction, and FP32-to-BF16 conversion into one raw AMDGCN kernel.

## Raw gfx1151 implementation

`kernels/gfx1151/moe/experiments/expert_weighted_reduce_top8_gfx1151.s` launches a `(8, tokens, 1)` grid with 256 threads. Each wave handles contiguous hidden dimensions for one token, scalar-loads that token's eight padded-row positions and router weights, issues eight coalesced FP32 global loads, performs a fixed slot-order FP32 FMA chain, and writes BF16 with round-to-nearest-even.

The assembled gfx1151 kernel uses 34 VGPRs, 44 SGPRs, zero LDS, zero scratch, and wave32. The disassembly and code-object metadata are in `docs/notes/disassembly/expert-weighted-reduce-top8-gfx1151/`.

## HIP-event microbenchmarks

| shape | raw fused kernel | PyTorch gather × weight + sum | speedup | max abs vs reference |
|---|---:|---:|---:|---:|
| 128 tokens, 1,280 padded rows, H=2,048 | 0.045846 ms | 0.060274 ms | 1.3147x | 0.001953125 |
| 8,192 tokens, 81,664 padded rows, H=2,048 | 2.753972 ms | 13.022768 ms | 4.7287x | 0.0078125 |

The complete samples are in `results/kernels/gfx1151/expert-weighted-reduce-top8-prototype.json`. Timing used HIP events. The prototype was not promoted to rocprofv3 comparison because it failed the real-checkpoint correctness gate.

## Real-checkpoint gate

A temporary SGLang integration replaced the existing gather, in-place router weighting, and `index_add_` reduction. Exact uncached 32,768-input/+1-output serving used graph disabled and dFlash disabled.

| gfx1151 build | prompt | host E2E | greedy token |
|---|---|---:|---:|
| established generic baseline | pair-a | 29,930.237 ms | 220 |
| raw fused reduction | pair-a | 27,746.539 ms | 220 |
| established generic baseline | pair-b | 29,806.921 ms | 96043 |
| raw fused reduction | pair-b | 27,554.398 ms | 3709 |

Although host serving latency decreased by 7.30% for pair-a and 7.56% for pair-b, pair-b changed the deterministic greedy token. The reduction-order difference and BF16 output error are unacceptable for this checkpoint's sensitive logit boundary. Production integration, HIP bridge registration, build registration, and the installed SGLang file were restored. The restored pair-b rerun returned token 96043 and measured 29,997.671 ms host E2E on gfx1151. No end-to-end speedup is accepted or claimed.

Retained negative-result artifacts:

- `kernels/gfx1151/moe/experiments/expert_weighted_reduce_top8_gfx1151.s`
- `harness/gfx1151/moe/expert_weighted_reduce_top8_launcher.hip`
- `tools/benchmark/benchmark_expert_weighted_reduce_top8.py`

A future attempt must reproduce the established indexed accumulation order closely enough to preserve both paired real-checkpoint greedy tokens before profiling or integration.
