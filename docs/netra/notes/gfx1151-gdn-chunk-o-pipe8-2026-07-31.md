# gfx1151 GDN chunk-output batched-load pipeline — 2026-07-31

Status: **accepted and measured on gfx1151** for the fixed production Qwen3.6 shape
`B1/T8192/H32/Hg16/K128/V128/BT64/BV32`. The checkpoint remains MXFP4; this
kernel is a model-native BF16/FP32 GDN operation. No alternative quantization
format was tested.

## Decision

The production raw AMDGCN `gdn_chunk_o_bv32_gfx1151` now batches independent
Q/H/K/V global-to-LDS loads before the dependency wait. The accepted source also
keeps the 64-element gate vector resident in LDS across the qh and qk phases and
skips complete causal-mask tiles that are entirely in the future.

The old source serialized 36 `global_load_b128` operations behind individual
`s_waitcnt vmcnt(0)` instructions: eight Q, eight H, sixteen K, and four V loads
per workgroup lane. The accepted schedule issues Q and H in groups of eight, K
in two groups of eight, and V in one group of four. It then performs the same
LDS writes after the precise group wait. Global addresses, LDS layout, WMMA
fragments, FP32 accumulation order, BF16 rounding, output stores, symbol, ABI,
and launch geometry are unchanged.

The fixed 72-byte/eight-byte-aligned kernarg, grid `(4,256,32)`, 64-thread
wave32 workgroup, 25,088-byte LDS allocation, zero scratch, caller HIP stream,
module preload order, and graph-pool pointers remain unchanged. Source VGPRs
rise from 212 to 240; rocprofv3 allocation rises from 216 to 240. Measured
occupancy is unchanged within 0.11%, so the extra load destinations do not reduce
effective occupancy for this LDS-constrained workgroup.

Only this GDN HSACO differs across the clean old/new builds. The other 44 HSACO
hashes are identical. The 30 public `netra_*` exports are identical, and the
export-table diff is empty.

## Correctness and graph safety

The alternating raw A/B harness used identical tensors and a shared physical
output allocation. Production baseline and candidate outputs are bit-identical,
candidate repeats are bit-identical, and the tuned Triton error is unchanged.

| gfx1151 measured gate | Result |
|---|---:|
| raw old/new bit equality | exact |
| candidate repeat equality | exact |
| eager poison-buffer repeats | 30/30 pass |
| graph poison-buffer replays | 30/30 pass |
| maximum absolute error vs tuned Triton | `9.5367431640625e-7` |
| existing tolerance | `3.814697265625e-6` |
| maximum mean absolute error | `1.5847063244978088e-12` |

The module is loaded before capture. Capture and replay do not allocate, load a
module, synchronize, query tensor values, or mutate registration state. Native
SGLang full decode graphs captured tiers 1/2/4/8/12/16. Old captures measured
2.84 and 2.80 s; candidate captures measured 2.82 and 2.81 s. Both reported
0.17 GB graph memory. All paired eager and graph serving requests produced exact
old/new output-token hashes.

## HIP-event performance

The primary alternating 31-sample A/B is **measured on gfx1151**:

| Fixed T8192 raw kernel | Median HIP event |
|---|---:|
| prior production two-wave | 12.815418 ms |
| batched-load candidate | 11.037721 ms |
| speedup | **1.161057x** |
| GPU-duration reduction | **13.8716% derived** |
| graph replay candidate | 11.056316 ms |

After promotion and a clean production rebuild, 30 eager plus 30 graph
correctness repetitions measured 11.817016 ms eager and 11.808279 ms graph.
The tuned Triton oracle measured 15.041637 ms, giving the production raw kernel
a **1.272880x measured gfx1151 speedup versus Triton** in that run.

## rocprofv3 counters

Every counter was collected in a fresh standalone process with rocprofv3 signal
handlers disabled. This avoids the incompatible mixed Python-wheel HSA runtime
that previously caused `aqlprofile` to abort with signal 6.

| gfx1151 measured counter | prior two-wave | batched-load | Change |
|---|---:|---:|---:|
| waves | 65,536 | 65,536 | 0% |
| allocated VGPR / SGPR | 216 / 128 | 240 / 128 | +24 / 0 |
| occupancy | 12.464943% | 12.452109% | -0.1030% derived |
| mean occupancy / active CU | 7.984659 | 7.944128 | -0.5076% derived |
| fetched KiB | 180,400.438 | 180,728.813 | +0.1820% derived |
| written KiB | 32,768.000 | 32,775.094 | +0.0216% derived |
| L2 hit | 63.664587% | 64.420658% | +0.756071 points |
| memory-unit busy | 92.294034% | 91.779810% | -0.514224 points |
| LDS bank conflict | 52.114286% | 52.990497% | +0.876211 points |
| SQ wave cycles | 6,241,831,808 | 5,229,363,880 | **-16.2207% derived** |
| SQ busy cycles | 778,776,764 | 715,083,531 | -8.1786% derived |
| VALU instructions | 1,579 | 1,364 | -13.6162% derived |
| SQ LDS instructions | 34,471,936 | 33,882,112 | -1.7110% derived |

The available gfx1151 metric set exposes no direct dependency-stall percentage;
none is estimated. The stable wave count and occupancy, nearly stable traffic,
and lower wave cycles are consistent with removing serialized wait groups rather
than winning through less model data or less parallelism.

## End-to-end serving

Every row is **measured on gfx1151** with the real Qwen3.6 checkpoint, cached
tokens 0, dFlash disabled, exact requested token counts, alternating server order,
and bit-identical paired token hashes.

| Exact uncached request | Graph mode | Old median host E2E | New median host E2E | Change |
|---|---|---:|---:|---:|
| 8,192 input + 1 output | disabled | 4,422.475 ms | 4,368.493 ms | **-1.2206%** |
| 32,768 input + 1 output | disabled | 21,080.304 ms | 20,904.416 ms | **-0.8344%** |
| 8,192 input + 2 output | full decode tiers | 4,394.802 ms | 4,357.653 ms | **-0.8453%** |

The exact 32K/+1 candidate corresponds to **1,567.52 input tok/s derived from
measured host E2E**, versus 1,554.44 tok/s for the paired old build. Peak unified
memory varied by process and does not support a VRAM improvement claim.

## Fresh ranked trace

The post-promotion exact 32K/+1 request trace measured 15,097 launches,
20,689.059 ms summed GPU kernels, 1,075.294 ms positive launch gaps, and
21,723.085 ms trace wall. The optimized GDN kernel made 119 calls totaling
1,440.643 ms, 12.106 ms mean, and 6.632% of trace wall. It is now rank three
behind extend attention (5,158.359 ms) and MXFP4 linear prefill
(1,636.255 ms). The prior independent trace measured 1,702.305 ms for GDN;
because the traces are independent profiler runs, that difference is inventory
evidence rather than a paired A/B claim.

## Experiment ledger

- Persistent full-chunk gates alone were exact but only 1.006919x and too small
  to accept independently.
- Clearing A once and skipping fully future causal tiles was exact and measured
  1.018338x. It is retained as part of the accepted combined schedule.
- Separate branches for fully valid tiles measured 1.018591x in the shorter run,
  providing no material value over the simpler skip schedule; rejected.
- Repacking V for one `ds_load_b128` per WMMA fragment was exact but measured
  1.017224x, slower than the row-major skip schedule. Eight scatter stores per
  staged vector outweighed the cheaper read; rejected.
- Adding the eight-load global pipeline to the skip schedule produced the
  accepted 1.161057x result.

## Evidence

- Production raw ASM: `kernels/gfx1151/gdn/gdn_chunk_o_bv32_gfx1151.s`
- Rejected and component sources: `kernels/gfx1151/gdn/experiments/`
- Repeated gate: `scripts/rocm/tools/correctness/check_gdn_chunk_o_repeated.py`
- Counter driver: `scripts/rocm/tools/profiling/profile_gdn_chunk_o_bv32_counters.sh`
- Disassembly, metadata, hashes, and exports:
  `docs/netra/notes/gfx1151-gdn-chunk-o-pipe8-disassembly-2026-07-31/`
- Machine-readable correctness, counters, serving, profile, and negative results:
  `docs/netra/notes/gfx1151-gdn-chunk-o-pipe8-results-2026-07-31/`
