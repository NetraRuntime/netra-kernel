# gfx1151 prefill-gate four-wave activation reuse (2026-07-30)

Status: **accepted in production raw AMDGCN**. Every performance number below is
measured on gfx1151; no performance value is estimated. The checkpoint remains
MXFP4 and the persistent coalesced-dword weight view is unchanged.

## Ranked-trace motivation

After the accepted attention kvbatch16 change, the raw
`mxfp4_prefill_gate_wmma_gfx1151` kernel ranked second in an exact 32,768-input
+1-output rocprofv3 trace: 320 calls, 2,856.720 ms total GPU time, or 12.390% of
measured kernel time. Each 32-thread output wave reread the same 64x32 BF16
activation tile used by three adjacent N16 output waves.

## Raw gfx1151 design

The accepted kernel changes the launch from 32-thread workgroups to 128-thread
workgroups. Four waves compute four adjacent N16 tiles while cooperatively
loading one 4 KiB activation tile into LDS:

- `logical_x = workgroup_id_x * 4 + wave_id` preserves the original output map;
- thread `tid` loads row `tid >> 1`, half-row `tid & 1`, as two 32-byte halves;
- the four waves read the shared tile at row offsets 0, 1024, 2048, and 3072;
- weights, scale decode, WMMA order, accumulators, and stores remain per wave;
- a top-of-loop barrier protects the previous tile and a post-load barrier
  publishes the next tile before its four consumers read it.

The K loop still has 64 K32 iterations and eight WMMA sites. Conceptually the
activation load is shared four ways; weights and scales are not shared.

## Correctness and HIP-event gate

The reproducible harness uses the exact real model group count G=1,276,
M64/N512/K2048, eleven alternating samples, and the production dword kernel as
the oracle.

| Metric | Production dword | Group4-A | Result |
|---|---:|---:|---:|
| HIP-event median | 8.508117 ms | 7.174542 ms | 1.185876x, gfx1151 measured |
| Bit mismatches | - | 0 | bit-exact |
| Maximum absolute difference | - | 0 | exact |
| Graph replay median | - | 7.188648 ms | exact to eager, gfx1151 measured |

The raw MXFP4 dword repacker is also bit-exact in this run. Module loading and
all allocations occur before graph capture, and the captured launch uses stable
device pointers. This harness did not measure graph construction time or graph
VRAM cost, so neither is estimated here.

## Disassembly and resources

| Property | Production dword | Group4-A |
|---|---:|---:|
| Static disassembly lines | 370 | 393 |
| `global_load` sites | 11 | 5 |
| `ds_load` sites | 0 | 8 |
| `ds_store` sites | 0 | 2 |
| `s_barrier` sites | 0 | 2 |
| WMMA sites | 8 | 8 |
| `s_waitcnt` sites | 20 | 20 |
| Workgroup size | 32 | 128 |
| LDS | 0 | 4,096 bytes |
| VGPR / SGPR | 112 / 128 | 112 / 128 |
| Scratch | 0 | 0 |
| Waves at G1,276 | 40,832 | 40,832 |

The before/after objects and unified diff are retained in
`docs/notes/gfx1151-prefill-gate-group4-a-disassembly-2026-07-30/`.

## rocprofv3 counters

Exact G1,276, three independent process launches per counter:

| Counter | Production dword | Group4-A | Delta |
|---|---:|---:|---:|
| FETCH_SIZE, KiB/dispatch | 394,035.536 | 287,345.071 | -27.076% |
| L2CacheHit | 92.477637% | 82.287689% | -10.190 points, tradeoff |
| LDSBankConflict | 0 | 33.195021 | added LDS conflict, tradeoff |
| MeanOccupancyPerActiveCU | 47.255466 | 47.658783 | +0.853% |
| MemUnitBusy | 99.248596 | 87.923709 | -11.325 points |
| SQ_BUSY_CYCLES | 495,162,419.9 | 409,885,880.6 | -17.222% |
| VALUInsts | 6,625 | 7,144 | +7.834%, tradeoff |
| SALUInsts | 527 | 529 | +2 |
| Wavefronts | 40,832 | 40,832 | unchanged |

The lower fetch and SQ-busy totals dominate the added LDS conflicts and VALU
instructions at this shape. A direct dependency-stall counter is not exposed by
the available gfx1151 rocprofv3 metric set.

## Full real-checkpoint gate

Matched exact 32,768 input +1 output, uncached, seed
`group4-kvbatch16-pair-a`, graphs disabled, and dFlash disabled:

| Metric | Production dword | Group4-A | Result |
|---|---:|---:|---:|
| Gate, 320 calls | 2,856.720 ms | 2,410.063 ms | 1.18533x, rocprofv3 GPU |
| Total GPU kernel time | 23,056.319 ms | 22,503.266 ms | 1.02458x, rocprofv3 GPU |
| Host HTTP E2E | 22,843.164 ms | 22,436.713 ms | 1.01812x, measured serving |

The control and candidate have identical input hashes, output token 5525, and
output hashes. Their process-start traces captured different startup/JIT launch
counts, so aggregate trace-wall and launch-gap deltas are inventory only, not
acceptance claims.

Fresh-server profiler-free pairs:

| Pair | Production dword host E2E | Group4-A host E2E | Speedup | Correctness |
|---|---:|---:|---:|---|
| A | 22,071.103 ms | 21,611.673 ms | 1.02126x | matching hashes/token |
| B | 22,086.061 ms | 21,535.448 ms | 1.02557x | matching hashes/token |
| **mean** | **22,078.582 ms** | **21,573.561 ms** | **1.02341x** | gfx1151 measured |

Both pairs are exact 32,768 input +1 output, zero cached tokens, graph-disabled,
and dFlash-disabled. Candidate peak VRAM samples are 100,911,620,096 and
102,014,083,072 bytes; these are measured sysfs peaks, not estimated.

## Decision

Accept in the production raw gfx1151 ASM path. The isolated and full-trace gate
speedups agree at about 1.185x, fresh serving improves by 2.34% on mean, output
is bit-exact, graph replay is exact, and VGPR/SGPR/scratch do not increase. The
4 KiB LDS footprint, extra barriers, higher VALU count, lower L2 hit rate, and
new bank conflicts are explicit retained costs.

The post-change ranked trace leaves attention first. The raw linear-prefill
kernel is now effectively tied with the improved gate at about 2.40 s total GPU
time and is the next top-down compute target.
