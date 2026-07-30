# gfx1151 linear-prefill group4-A reuse (rejected, 2026-07-30)

Status: **rejected from production**. Every runtime number is measured on
`gfx1151`; no runtime is estimated. MXFP4 weights and the accepted persistent
dword layout remain unchanged.

## Ranked motivation and raw design

After the accepted prefill-gate optimization,
`mxfp4_sgl_linear_prefill_wmma_gfx1151` was effectively tied for rank 2 in the
exact 32,768-input/+1-output trace: 360 calls and 2,398.025 ms total GPU time.
The raw experiment grouped four adjacent N16 output waves in a 128-thread
workgroup and cooperatively staged one 4 KiB M64xK32 BF16 activation tile in
LDS. The grid changed from N/16 by G with 32 threads to N/64 by G with 128
threads. Weights, scale decode, WMMA order, accumulators, and output stores
remained per wave.

The design has two barriers per K32 step: one prevents overwrite of the prior A
tile, and one publishes the new tile. It uses 4,096 bytes LDS, 112 profiler
VGPR, 128 profiler SGPR, zero scratch, and the same wave count as production.

## Strengthened isolated correctness and HIP events

The original dense-prefill harness used uniform BF16 activation bytes. That can
hide row-addressing mistakes, so this experiment replaces it with deterministic
splitmix-derived, finite, nonuniform BF16 values across rows and groups. All
three real Qwen3.6 shapes are bit-exact to the production raw kernel, including
graph replay.

| Exact G128/M64 shape | Production median | Group4-A median | Result |
|---|---:|---:|---:|
| N64/K2048, 31 samples | 0.804670 ms | 0.234200 ms | 3.435824x, bit-exact |
| N2048/K4096, 21 samples | 4.869499 ms | 4.776739 ms | 1.019419x, bit-exact |
| N12288/K2048, 11 samples | 12.978018 ms | 13.814508 ms | 0.939448x, bit-exact; reject for this shape |

An all-shape replacement is slower because N12288 dominates. The real-server
trial therefore specialized only N64 and N2048 and retained production for
N12288.

## Disassembly

| Static/resource property | Production | Group4-A |
|---|---:|---:|
| Disassembly lines | 372 | 395 |
| `global_load` sites | 11 | 5 |
| `ds_load` / `ds_store` sites | 0 / 0 | 8 / 2 |
| `s_barrier` sites | 0 | 2 |
| WMMA / `s_waitcnt` sites | 8 / 18 | 8 / 18 |
| LDS / scratch | 0 / 0 bytes | 4,096 / 0 bytes |
| Profiler VGPR / SGPR | 112 / 128 | 112 / 128 |

Before, after, and the unified diff are under
`docs/notes/gfx1151-linear-prefill-group4-a-negative-disassembly-2026-07-30/`.

## Full real-checkpoint trace

Matched exact 32,768 input +1 output, zero cached tokens, graph-disabled, and
dFlash-disabled:

| Metric | Production | N64/N2048 specialization | Measured delta |
|---|---:|---:|---:|
| Linear-prefill GPU total | 2,398.025 ms / 360 calls | 2,275.430 ms / 360 calls | 122.595 ms saved, 1.053878x |
| Total GPU kernel time | 22,503.266 ms | 22,268.774 ms | 234.492 ms saved, 1.010530x |
| Host HTTP E2E | 22,436.713 ms | 22,210.898 ms | 225.815 ms lower, invalid for acceptance |
| Greedy token | 5525 | 0 | **mismatch** |

The specialized trace split is 120 production N12288 calls at 1,626.232 ms and
240 group4-A N64/N2048 calls at 649.198 ms. Profiler resources for group4-A are
112 VGPR, 128 SGPR, 4 KiB LDS, and zero scratch. The process-start profiler
trace is retained even though its output fails correctness.

## Fresh-server reproducibility gate

Using the same two deterministic prompts as the accepted production baseline:

| Run | Production token | Candidate token | Candidate host E2E | Result |
|---|---:|---:|---:|---|
| pair A, first fresh server | 5525 | 5525 | 21,413.088 ms | correct |
| pair B, fresh server | 248045 | 248045 | 21,503.246 ms | correct |
| pair A, second fresh server | 5525 | 0 | 21,451.249 ms | **nondeterministic mismatch** |

All three candidate runs are exact 32,768/+1, uncached, graph-disabled, and
dFlash-disabled. Since identical pair-A inputs produce both 5525 and 0 across
fresh servers, no serving speedup is claimed.

## Decision

Reject and restore the published production raw kernel for every shape. A fresh
post-restore pair-A control returns the expected token 5525 at 21,625.647 ms. The
isolated oracle and graph replay are exact, but the real checkpoint exposes a
nondeterministic greedy-token failure. The raw candidate, strengthened harness,
build script, trace, and disassembly are retained for root-cause work. A future
attempt must capture and compare complete per-layer QKVZ, GDN-output, and BA
buffers on real checkpoint activations before another serving trial.
