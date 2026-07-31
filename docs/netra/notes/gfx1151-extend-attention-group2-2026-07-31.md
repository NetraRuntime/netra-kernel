# gfx1151 N64 extend-attention group2 schedule — 2026-07-31

All results in this note are for AMD Ryzen AI Max+ PRO 395, `gfx1151`.
GPU timings are measured with HIP events or rocprofv3. Serving timings are
measured from uncached host HTTP wall time. Derived ratios are labeled as such.

## Decision

Accept the raw AMDGCN group2 schedule for long prefill. The production
`extend_attention_wmma_n64_gfx1151.s` still performs the same N64 online
softmax, Q pipeline, and 16-page K/V issue batch, but each 256-thread workgroup
now processes two query heads instead of each 512-thread workgroup processing
four. The launch changes from grid Y 4 / block X 512 to grid Y 8 / block X 256.

This is not accepted as an 8K serving gain: the measured 8K end-to-end delta is
inside run-to-run noise. It is accepted because the exact 32K critical path is
repeatably faster, all compared outputs are bit-identical, and full-decode graph
capture/replay remains correct.

## Code object, ABI, and disassembly

| gfx1151 code object | SHA-256 | status |
|---|---|---|
| group4 baseline | `8cc207d2a76cc6e4d1ae93050f1da774929549612096241008b46ff7cf94c406` | measured |
| group2 candidate | `0ddd7d7d30d17b3d2594c7fbabd9b552c53f8a19f6bd290fed7df6011eaff372` | measured |

The raw instruction diff changes only the scalar workgroup-to-KV-head and
workgroup-to-query-head shift immediates. Launch geometry is changed in the
gfx1151 runtime configuration and standalone harness. Kernel symbol, argument
field order, 72-byte kernarg size, 8-byte alignment, wave32 mode, 64 KiB fixed
LDS, zero scratch, 244 source VGPRs, 64 source SGPRs, and maximum workgroup
metadata remain unchanged. rocprofv3 reports allocation granules of 248 VGPRs
and 128 SGPRs for both variants.

The old and new complete SGLang shared libraries export the same 30 public
symbols. The export-table diff is empty. The caller's HIP stream and the
runtime's preloaded cached `hipFunction_t` path are unchanged.

Before/after disassembly, metadata, hashes, and exports are under
`docs/netra/notes/gfx1151-extend-attention-group2-disassembly-2026-07-31/`.

## Correctness

The T8192 four-prefix A/B is bit-identical at prefixes 0, 8192, 16384, and
24576. A separate T256 page-table test deterministically shuffled page indices
at prefixes 0, 64, 128, and 192; all four outputs are also bit-identical with
zero maximum and mean absolute difference.

The FP64 CPU-reference gate used BF16 Q/K/V inputs at amplitudes 0.02, 1.0,
and 2.0 with T256 and prefix 128. Group4 and group2 outputs were bit-identical
for all three amplitudes and therefore had identical FP64-reference errors:

| amplitude | max abs | mean abs | RMSE | status |
|---:|---:|---:|---:|---|
| 0.02 | 0.001279616 | 0.000089258 | 0.000131447 | measured |
| 1.0 | 0.002275943 | 0.000171991 | 0.000228825 | measured |
| 2.0 | 0.010176803 | 0.000701225 | 0.001041392 | measured |

Four exact 32,768-input/+1-output serving pairs used cached tokens 0, eager
execution, dFlash disabled, and context length 49,152. Every group4/group2
output-token pair was bit-identical. Two additional 8,192-input/+1-output eager
pairs and two 8,192-input/+2-output full-graph pairs were also bit-identical.

## HIP-event kernel timing

Each row is the median of 11 alternating A/B samples with identical T8192
inputs and a shared physical timing-output allocation:

| prefix | group4 | group2 | speedup |
|---:|---:|---:|---:|
| 0 | 34.209335 ms | 31.367523 ms | 1.090597x |
| 8,192 | 99.908485 ms | 93.662437 ms | 1.066687x |
| 16,384 | 166.847031 ms | 159.026901 ms | 1.049175x |
| 24,576 | 233.720871 ms | 228.807098 ms | 1.021476x |
| four-tier sum | 534.685722 ms | 512.863960 ms | 1.042549x derived |

The gain decreases with prefix length because group2 stages each K/V tile twice
per KV head while group4 stages it once. The smaller workgroup nevertheless
wins at every measured tier, consistent with shorter workgroup/barrier tail
latency.

## rocprofv3 counters

Counters used identical T8192/prefix24576 dispatch shapes and one metric per
fresh process with rocprofv3 signal handlers disabled:

| gfx1151 measured counter | group4 | group2 |
|---|---:|---:|
| workgroup size | 512 | 256 |
| waves | 8,192 | 8,192 |
| reported occupancy | 10.0317% | 9.9985% |
| mean occupancy / active CU | 6.5378 | 6.5900 |
| fetched KiB | 19,080,408.3 | 26,009,690.2 |
| L2 hit | 7.4741% | 7.8011% |
| memory-unit busy | 19.6815% | 27.6345% |
| SALU instructions | 32,220.25 | 61,478.50 |
| VALU instructions | 878,687.5 | 887,657.5 |

The measured fetch increase is 36.315% derived and the wave count is unchanged.
Therefore this is not an occupancy or traffic-reduction win. It is a workgroup
scheduling win that intentionally spends extra K/V and scalar work. The
`SQ_WAVE_CYCLES` counter returned the same apparent saturation value for both
passes and is not used. The available gfx1151 metric set exposes no direct
dependency-stall percentage, so none is estimated.

A fresh exact 32K/+1 process-start rocprofv3 trace of group2 measured 15,078
launches, 20,941.575 ms summed GPU kernels, 1,076.869 ms positive launch gaps,
and 21,980.750 ms host request wall. Extend attention was 40 invocations,
5,126.412 ms total, 128.160 ms mean, and 23.322% of host wall. This trace is a
candidate inventory, not an old/new whole-request A/B because intervening
production kernels differ from the older trace.

## End-to-end serving

The four exact 32K pairs were run in alternating old/new and new/old server
order. Combined medians are:

| gfx1151 measured exact 32,768/+1 uncached | group4 | group2 | change |
|---|---:|---:|---:|
| host TTFT | 21,320.572 ms | 21,137.364 ms | -0.8593% derived |
| host E2E | 21,320.645 ms | 21,137.439 ms | -0.8593% derived |
| input throughput | 1,536.932 tok/s | 1,550.251 tok/s | +0.8666% derived |

All four paired host deltas favored group2: -18.904, -385.019, -136.396, and
-189.840 ms. The paired median saving is 163.118 ms. Peak unified-memory VRAM
samples are retained in the result JSON but are too variable to attribute a
memory improvement to this schedule.

At exact 8,192/+1 eager, the measured median delta was -0.1233% with one pair
reversing sign, so it is explicitly treated as neutral. At exact 8,192/+2 with
native SGLang full-decode graph tiers 1,2,4,8,12,16, the measured median delta
was -0.1613% with one pair reversing sign. Graph tokens were bit-identical and
no graph break, synchronization, allocation, or launch-count change was added.
Prefill itself remains eager in this full-decode graph configuration.

## Scope and next work

This replacement changes only standard-attention long-prefill scheduling. It
does not improve M=1 decode, GDN layers, MoE, speculative verify, piecewise
prefill graphs, or dFlash. The next long-prefill work should return to the fresh
ranked trace: extend attention remains first at 23.322% of wall, followed by
GDN/prefill projections, expert compute, and scan kernels.

Evidence:

- `docs/netra/notes/gfx1151-extend-attention-group2-t8192-2026-07-31.json`
- `docs/netra/notes/gfx1151-extend-attention-group2-fp64-2026-07-31.json`
- `docs/netra/notes/gfx1151-extend-attention-group2-shuffled-correctness-2026-07-31.json`
- pushed counter, trace, and serving summaries:
  `docs/netra/notes/gfx1151-extend-attention-group2-results-2026-07-31/`
- `results/profiles/gfx1151/attention-group2-counters-20260731/`
- `results/profiles/gfx1151/attention-group2-windowed-32768p1-20260731/`
- `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/attention-group2-eager-32768-plus1-20260731/`
