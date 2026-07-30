# gfx1151 attention 16-page K/V issue batch (2026-07-30)

Status: **accepted in production raw AMDGCN**. Every number below is measured on
gfx1151; no value is estimated. MXFP4 checkpoint weights remain unchanged.

## Change and concrete dependency result

The accepted group4-qpipe kernel issued prefix K/V page loads in two groups of
eight, each ending in broad scalar and vector waits. The new raw gfx1151 ASM
issues all sixteen page-table `s_load_b64` operations, then all sixteen
`global_load_b128` operations, before the corresponding phase waits. It keeps
the mandatory tile-boundary barrier and four-query-head shared K/V schedule.
Static `s_waitcnt` sites fall from 311 to 307; barriers remain 4, scalar page-load
sites remain 33, and global 128-bit load sites remain 80. Both versions report
248 VGPR, 128 SGPR, 64 KiB LDS, zero scratch, 512 threads, and 8,192 waves at the
counter shape.

## Correctness

At T64 with prefix 0/64/192, candidate output is byte-identical to the accepted
group4-qpipe control. Against the FP32 oracle, maximum absolute errors are
0.000123295933, 4.06522304e-05, and
2.07084231e-05; these equal the Triton error envelope.
Raw-versus-Triton maximum difference is at most
3.05175781e-05. Eager and graph replay are
exact at all three shapes. The real-checkpoint control/candidate traces and both
fresh-server pairs have identical input hashes, output IDs, and output hashes;
all are uncached, graph-disabled, and dFlash-disabled.

## Isolated HIP-event timing

| Prefix | group4-qpipe ms | kvbatch16 ms | Speedup | Result |
|---:|---:|---:|---:|---|
| 0 | 34.336613 | 34.334064 | 1.00007x | bit-identical, gfx1151 measured |
| 8,192 | 101.264946 | 99.692627 | 1.01577x | bit-identical, gfx1151 measured |
| 16,384 | 171.717651 | 166.723755 | 1.02995x | bit-identical, gfx1151 measured |
| 24,576 | 241.560486 | 234.283493 | 1.03106x | bit-identical, gfx1151 measured |
| **sum** | **548.879696** | **535.033939** | **1.02588x** | gfx1151 measured |

## rocprofv3 counters

Exact T8192/prefix24576, three independent profiler processes per counter:

| Counter | control | kvbatch16 | Delta |
|---|---:|---:|---:|
| MeanOccupancyPerActiveCU | 6.304195 | 6.533785 | +3.642% |
| FETCH_SIZE, KiB/dispatch | 17503413.3 | 18885545.6 | +7.896% tradeoff |
| L2CacheHit | 13.116677% | 9.718572% | -3.398 points tradeoff |
| LDSBankConflict | 29.133858 | 29.133858 | unchanged |
| VALUInsts | 878687.5 | 878687.5 | unchanged |
| Wavefronts | 8192 | 8192 | unchanged |

`OccupancyPercent` is excluded because one gfx1151 candidate sample was invalid
(267,004%). `MeanOccupancyPerActiveCU` is stable across all three samples. The
measured fetch/cache tradeoff is retained rather than hidden.

## Full real-checkpoint gate

Matched exact 32,768 input +1 output, seed `group4-kvbatch16-pair-a`:

| Metric | control | kvbatch16 | Result |
|---|---:|---:|---:|
| Attention, 40 calls | 5490.794 ms | 5346.822 ms | 1.02693x, rocprofv3 GPU |
| Total GPU kernel time | 23107.600 ms | 23056.319 ms | 1.00222x, rocprofv3 GPU |
| Host HTTP E2E | 23046.373 ms | 22843.164 ms | 1.00890x, measured serving |

Trace wall and aggregate launch gaps are not acceptance claims: the process-start
traces captured different amounts of server JIT/startup work
(33,820 versus
37,723 launches). The target attention
kernel has exactly 40 calls in both traces.

Fresh-server profiler-free pairs:

| Pair | control host E2E ms | kvbatch16 host E2E ms | Speedup | Correctness |
|---|---:|---:|---:|---|
| A | 22148.553 | 22071.103 | 1.00351x | matching hashes/token |
| B | 22140.183 | 22086.061 | 1.00245x | matching hashes/token |
| **mean** | **22144.368** | **22078.582** | **1.00298x** | gfx1151 measured |

## Graph gate

At T8192, graph capture took 7.774151 ms host time.
Allocated memory rose 1,024 bytes and
reserved memory rose 2,097,152 bytes.
Stable pointers passed; prefix 0 capture and device-side prefix 8192 replay are
byte-identical to eager. Eleven replay HIP-event samples have median
100.122040 ms.

## Decision

Accept. The dependency reduction is small but repeatable: 2.69% attention gain
in the matched full trace and 0.30% mean profiler-free serving gain, with exact
model behavior and graph replay. The larger fetch footprint and lower L2 hit
rate are documented costs. Revisit if a contiguous-page design removes the need
for sixteen independent page loads.
