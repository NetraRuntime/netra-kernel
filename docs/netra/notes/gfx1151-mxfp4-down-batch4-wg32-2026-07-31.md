# gfx1151 MXFP4 routed-down batch4 WG32 decode — 2026-07-31

All results are for AMD Ryzen AI Max+ PRO 395, `gfx1151`. GPU claims use HIP
events or rocprofv3. Serving claims use streaming host wall time. Derived values
are labeled explicitly.

## Decision

Accept `mxfp4_decode_down_batch4_wg32_gfx1151.s` for the exact Qwen3.6
M=1 routed-expert down projection: selected experts 8, N=2048, K=512, MXFP4
weights, FP32 per-expert output. The kernel remains raw wave32 AMDGCN and keeps
the existing 40-byte, 8-byte-aligned five-pointer kernarg ABI, output layout,
MXFP4 weight layout, caller stream, and stable graph-pool pointers.

The old kernel serialized eight pairs of coalesced weight loads behind eight
full `s_waitcnt` points in every 32-K MX block. The accepted kernel issues four
weight/activation pairs, performs one full dependency wait, decodes the batch,
and repeats. It also changes from 2 workgroups of 256 threads per selected slot
to 16 workgroups of 32 threads. Total threads and measured waves remain
unchanged, while 128 single-wave workgroups distribute independently across
40 CUs.

| gfx1151 code object | SHA-256 | status |
|---|---|---|
| baseline routed down | `538865931cac396adb3383dcbe25236c7328de9a88ca5d46294acffe146e5c45` | measured |
| batch4 WG32 | `b7d712619a3fa4c50e869136b6c3f105baa20fa8c5123b19637c5e7170931703` | accepted |

Both use zero LDS and zero scratch. Baseline source metadata is 34 VGPR / 26
SGPR; candidate metadata is 40 VGPR / 30 SGPR. Both occupy the same measured
40-VGPR and 128-SGPR allocation granules, so batching does not reduce the
allocation-granule occupancy limit.

## Correctness

The isolated harness produced zero FP32 bit mismatches for synthetic inputs and
for real layer-0 checkpoint weights. Both baseline and candidate had identical
2.235174179e-08 maximum FP64 spot-check error on the real fixture.

A 179 MB rotating fixture set covers all 40 real checkpoint layers, eight
experts per layer, model-native repacked MXFP4 weights/scales, and independent
BF16 selected-slot activations. It produced zero mismatches over 655,360 FP32
outputs. Eager and full-graph serving each matched baseline output hashes 6/6.

The public shared-library ABI remains 30 `netra_*` symbols with identical old
and new symbol tables. Forty-four common old/new HSACOs are byte-identical; the
accepted down code object is additive and selected through the cached static
runtime descriptor.

## HIP-event timing

| gfx1151 measured shape | baseline | batch4 WG32 | speedup |
|---|---:|---:|---:|
| real layer 0, cache hot | 26.331 us | 14.004 us | 1.8803x |
| all 40 real layers, 179 MB rotation | 48.569 us | 27.097 us | 1.7924x |

The rotating result is the isolated acceptance timing. It avoids presenting a
cache-resident 4.5 MB expert subset as production performance.

## rocprofv3 counters

Every counter was collected in a fresh process with signal handlers disabled;
all 18 passes completed without signal 6.

| gfx1151 measured counter | baseline | batch4 WG32 |
|---|---:|---:|
| fetched KiB | 2182.750 | 2182.563 |
| L2 hit | 10.596% | 11.206% |
| mean occupancy / active CU | 7.864 | 6.116 |
| occupancy | 8.362% | 7.306% |
| memory-unit busy | 72.320% | 49.923% |
| waves | 128 | 128 |
| wave cycles | 10,137,453 | 5,687,838 |
| VALU instructions | 6,378 | 6,378 |

Wave cycles fall 43.893% with effectively identical fetch volume, wave count,
and arithmetic instruction count. The lower sampled occupancy is not a
regression: shorter independent single-wave workgroups complete much sooner.
The available gfx1151 metric set exposes no direct dependency-stall percentage;
none is estimated. `WRITE_SIZE` reported zero for both and is not used.

## Complete-request trace

The accepted exact-1/+32 eager trace is uncached with dFlash disabled. It
measured 1,311 routed-down calls, 37.280 ms total, 28.436 us mean, and 28.374 us
median. The earlier accepted trace measured 47.933 us mean and 47.890 us median;
the derived per-call reductions are 40.67% and 40.75%. The traces used different
request seeds and have different invocation counts, so their total request
kernel milliseconds are not treated as a matched A/B claim.

The candidate trace measured 860.833 ms host wall, 760.763 ms summed GPU
kernels, 107.023 ms positive launch gaps, and 32,011 launches. Request status
was zero; profiler status 137 is the bounded collector terminating the server
after the request. Signal handlers were disabled and no signal-6 loop occurred.

## Eager serving A/B

Two interleaved old/new server rounds with three streaming samples per server
used exact 1 input + 128 output, cached tokens 0, batch 1, eager execution, and
dFlash disabled. All six paired hashes matched.

| gfx1151 measured median | baseline | batch4 WG32 | change |
|---|---:|---:|---:|
| TTFT | 61.704 ms | 62.108 ms | +0.656% |
| decode wall | 3173.712 ms | 3088.769 ms | -2.676% |
| output throughput | 40.016 tok/s | 41.117 tok/s | +2.750% |
| E2E wall | 3234.350 ms | 3154.784 ms | -2.460% |

A separate six-pair non-streaming repetition measured -2.712% median host E2E,
confirming the direction. The newest accepted non-speculative batch-1 eager
rate is therefore **41.117 tok/s measured on gfx1151**. The 50 tok/s target is
not yet reached.

For exact 210 input + 128 output, also uncached/eager/dFlash-disabled, all six
paired output hashes matched:

| gfx1151 measured median | baseline | batch4 WG32 | change |
|---|---:|---:|---:|
| TTFT | 417.207 ms | 417.094 ms | -0.027% |
| input throughput | 503.347 tok/s | 503.484 tok/s | +0.027% |
| decode wall | 3214.964 ms | 3124.654 ms | -2.809% |
| output throughput | 39.503 tok/s | 40.645 tok/s | +2.890% |
| E2E wall | 3639.002 ms | 3542.782 ms | -2.644% |

Whole-APU sysfs peak-VRAM readings varied by server round and are not attributed
to this kernel; the implementation adds no allocation or workspace.

## Full graph gate

Native SGLang full decode graphs captured tiers 1/2/4/8/12/16 before requests.
The raw module and function were preloaded, capture made no allocation or module
lookup, and launches retained the caller stream. All six paired hashes matched.

| gfx1151 measured median | baseline full graph | candidate full graph | change |
|---|---:|---:|---:|
| TTFT | 49.838 ms | 50.793 ms | +1.916% |
| decode wall | 3207.300 ms | 3106.448 ms | -3.144% |
| output throughput | 39.597 tok/s | 40.883 tok/s | +3.247% |
| E2E wall | 3257.700 ms | 3158.013 ms | -3.060% |

Candidate graph construction measured 2.81 s and 3.06 s in the two rounds.
One round reported 0.17 GB and one reported an anomalous 3.11 GB whole-process
memory delta; this is retained as measured rather than normalized away. The
kernel itself adds no graph memory. Candidate full graph is 0.57% slower than
candidate eager throughput, so eager remains the batch-1 performance default.

## Tuning ledger

All rotating values below are measured on gfx1151. The non-pipelined WG64
variant only reached 1.021x. Double-buffering progressed from 1.080x at WG256
to 1.127x at WG32. Correct batch3 WG32 reached 1.627x, and batch4 WG32 reached
1.792x. A nonzero-wait-count triple pipeline appeared ~1.73x but produced
2,109–2,488 FP32 mismatches; it was rejected. Full dependency waits are retained
in the accepted kernel.

## Evidence

- Raw kernel: `kernels/gfx1151/mxfp4/decode/mxfp4_decode_down_batch4_wg32_gfx1151.s`
- Isolated and rotating HIP-event harnesses: `scripts/rocm/harness/gfx1151/mxfp4/benchmark_decode_down_pipeline*.hip`
- Counter script: `scripts/rocm/tools/profiling/profile_decode_down_batch4_counters.sh`
- Counters: `results/profiles/gfx1151/decode-down-batch4-wg32-counters-20260731`
- Complete trace: `results/profiles/gfx1151/down-batch4-wg32-attn-oproj-qkv-shared-wide128-complete-eager-b1-1-plus32-20260731`
- Eager 1/+128 A/B: `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/down-batch4-wg32-eager-1-plus128-ab3-stream-20260731`
- Eager 210/+128 A/B: `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/down-batch4-wg32-eager-210-plus128-ab-20260731`
- Full-graph A/B: `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/down-batch4-wg32-fullgraph-1-plus128-ab-20260731`
- Before/after disassembly: `docs/netra/notes/gfx1151-mxfp4-down-batch4-wg32-disassembly-2026-07-31/`
