# Rejected gfx1151 attention page-table caching (2026-07-30)

Status: **rejected; production qpipe8 remains unchanged**. Runtime and counter
values are measured on gfx1151. Static instruction/resource values are labeled
static. MXFP4 weights and model-native BF16 arithmetic are unchanged.

## Motivation and raw-ASM variants

The N64 prefix path loads each 64-entry page-table tile once for K and again
for V. Three hand-written AMDGCN variants tested reuse across the intervening
QK, mask, and online-softmax phase:

1. `ptcache8` leaves page entries 32..60 in `s44:s59`; V consumes that cached
   half before loading entries 0..28. This reverses the V half-tile order.
2. `ptcache8_first` reverses only K staging so entries 0..28 remain live;
   V retains its original ascending half-tile order.
3. `ptcache16` retains both batches in `s44:s75` and eliminates all repeated
   V-side page-table loads. Static YAML SGPR count rises from 48 to 64 while
   VGPR, 64 KiB LDS, and zero scratch remain unchanged.

All variants keep the graph ABI, K swizzle, Q/P overlay, online-softmax order,
and output stores unchanged. The first development schedule incorrectly loaded
new V page entries before consuming the retained entries; the correctness gate
caught it and that build was discarded before performance claims.

## Correctness

The corrected three variants are byte-identical to production qpipe8 at T64
prefix 0/64/192 and exact T8192 prefix 0/8192/16384/24576: `max_abs=0` and
`mean_abs=0`. These are measured gfx1151 results.

## Alternating HIP-event gate

Each exact T8192 row alternates AB/BA order, uses four warmups, and reports the
median of 21 samples except ptcache16, which uses 11 samples. Speedup above one
favors the candidate.

| Variant | Prefix 0 | Prefix 8K | Prefix 16K | Prefix 24K | Prefix-only sum | Decision |
|---|---:|---:|---:|---:|---:|---|
| ptcache8 | 0.98535x | 0.99543x | 0.99652x | 0.99518x | 0.99568x | Reject |
| ptcache8_first | 1.01032x | 1.00115x | 0.99805x | 1.00114x | 1.00011x | Reject as neutral/mixed |
| ptcache16 | 0.98953x | 0.99323x | 0.99606x | 0.99356x | 0.99433x | Reject |

The ptcache8-first prefix-only medians total 633.0468 ms for qpipe8 and
632.9788 ms for the candidate, only 0.011% apart and with a loss at prefix 16K.
The full cache totals 632.7430 versus 636.3524 ms over the three prefix tiers,
a measured 0.567% regression on gfx1151. No serving or graph gate is justified
for a candidate that fails the isolated kernel gate.

## rocprofv3 evidence

Counters compare qpipe8 and ptcache16 at exact T8192/prefix24576 using a
standalone HIP process and one counter per process. SQ, fetch, L2, and occupancy
are means of three independent passes; SALU and wave counts use one pass.

| Counter | qpipe8 | ptcache16 | Delta | Status |
|---|---:|---:|---:|---|
| Static `s_load_b64` sites | 33 | 17 | -16 | static gfx1151 disassembly |
| SQ busy cycles | 16,922,996,721 | 16,865,938,488 | -0.337% | gfx1151 measured |
| Fetch KiB | 17,045,375.3 | 15,363,391.3 | -9.868% | gfx1151 measured |
| L2 hit | 32.6280% | 33.1288% | +0.501 points | gfx1151 measured |
| Mean occupancy/active CU | 5.05837 | 5.10388 | +0.900% | gfx1151 measured |
| SALU instructions | 122,296 | 119,992 | -1.884% | gfx1151 measured |
| Wavefronts | 8,192 | 8,192 | unchanged | gfx1151 measured |

The counter ranges overlap for fetch and SQ busy cycles, and the direct
dependency-stall metric is not exposed for gfx1151. The safe conclusion is
that removing scalar lookups does not translate into elapsed-time value here;
the larger SGPR lifetime and altered half-tile schedules offset it. That cause
is an inference, while the rejection is based on measured elapsed time.

## Reproduction and disposition

Build all raw variants with
`tools/build/build_extend_attention_ptcache_experiment.sh`. Run alternating
HIP-event comparisons with the benchmark script and its
`--interleaved` option, and reproduce counters with
`tools/profiling/profile_extend_attention_ptcache_counters.sh`. Machine JSON,
before/rejected disassembly, and the normalized diff are adjacent to this note.
The raw experiments are retained for future page-size or contiguous-page work;
none is enabled in production.
