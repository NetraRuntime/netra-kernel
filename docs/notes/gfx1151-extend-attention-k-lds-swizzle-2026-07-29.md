# gfx1151 extend-attention K LDS swizzle (2026-07-29)

Every runtime and serving number below is measured on gfx1151. No runtime
value is estimated. Instruction counts are labeled static.

## Ranked-path reason

The current exact 32,768/+1 process-start trace ranks
`extend_attention_wmma_n64_gfx1151` first: 40 calls, 7,161.990 ms total GPU
duration, 23.65% of kernel time, and 16.67% of traced wall time. The exact
T=8,192/prefix=24,576 counter pass measured 49.789985% LDS bank conflicts,
7.377047% occupancy, 248 VGPR, 64 KiB LDS, and zero scratch.

## Accepted raw AMDGCN change

The production raw-ASM kernel now XOR-permutes each 16-byte K chunk by the
low three bits of its logical K row on LDS write and applies the identical
inverse mapping on LDS read. Both current-chunk K (`PTR=6`) and prefix-cache K
(`PTR=12`) use the mapping. V and every global-memory address are unchanged.

A rejected intermediate recognized only prefix-cache K. Low-amplitude inputs
masked the bug, but an unscaled stress test differed by 1.296875. The accepted
source covers both K paths and is bit-identical to the previous production
kernel at T/prefix pairs 64/0, 64/64, 128/64, and 128/192 with unscaled BF16
random inputs.

## HIP-event result

| T | Prefix | Previous median ms | K-swizzle median ms | Speedup | Status |
|---:|---:|---:|---:|---:|---|
| 8,192 | 0 | 45.2159 | 44.1129 | 1.02500x | gfx1151 measured |
| 8,192 | 8,192 | 130.7386 | 127.9468 | 1.02182x | gfx1151 measured |
| 8,192 | 16,384 | 222.8803 | 217.6100 | 1.02422x | gfx1151 measured |
| 8,192 | 24,576 | 316.4546 | 307.1942 | 1.03015x | gfx1151 measured |

Each row uses 3 warmups and 11 HIP-event samples. Candidate output is bit
identical to the previous production raw kernel for all four exact shapes.

## rocprofv3 counters

| Counter/resource | Previous | K swizzle | Change | Status |
|---|---:|---:|---:|---|
| LDS bank conflict | 49.789985% | 34.634323% | -30.439% relative | gfx1151 measured |
| SQ busy cycles | 17,989,205,750 | 17,400,779,332 | -3.271% | gfx1151 measured |
| Occupancy | 7.377047% | 7.618831% | +0.241784 pp | gfx1151 measured |
| L2 hit | 24.662958% | 30.299905% | +5.636947 pp | gfx1151 measured |
| Fetch size | 19,163,593.94 KiB | 18,862,352.31 KiB | -1.572% | gfx1151 measured |
| VGPR / LDS / scratch | 248 / 65,536 B / 0 B | 248 / 65,536 B / 0 B | unchanged | gfx1151 measured metadata |

`MemUnitBusy` from the older baseline pass was nonsensical (860,299.54%) and
is excluded from comparison. The gfx1151 metric set exposes no direct
dependency-stall counter. Each retained counter was collected in a separate
process-start rocprofv3 pass with signal handlers disabled.

## Real-checkpoint serving gate

Two paired exact 32,768-input/+1-output requests used identical input IDs per
pair. All requests were uncached, batch 1, graph disabled, and dFlash disabled.

| Pair | Previous host E2E ms | K-swizzle host E2E ms | Greedy output | Status |
|---|---:|---:|---|---|
| A | 29,406.675 | 29,144.951 | ID 248045, match | gfx1151 measured |
| B | 29,242.680 | 29,046.815 | ID 220, match | gfx1151 measured |
| Mean | 29,324.678 | 29,095.883 | match | gfx1151 measured |

Mean latency falls by 228.795 ms: 1.00786x, or 0.7802%. Peak process-visible
unified-memory accounting was 60,921,634,816/60,923,731,968 bytes for the two
accepted runs. This is sysfs VRAM accounting on Strix Halo, not dedicated VRAM.

The production HSACO was rebuilt after the paired baseline run. Real-checkpoint
MXFP4 linear and decode tests remain bit exact to BF16 references. The attention
T64 raw-vs-FP32 gate remains within the existing accepted error envelope.

## Graph and disassembly gates

Raw HIP graph capture/replay passed at prefix 0 and after changing only the
device `kv_indptr[1]` value to 64. Both replays were bit identical to eager;
measured medians were 0.029375 and 0.040196 ms over seven HIP-event samples.

Static gfx1151 disassembly grows from 6,480 to 6,800 instructions because the
raw macro expansion adds 96 `v_xor_b32`, 64 `v_and_b32`, 64 vector shifts,
and write-side scalar address operations. WMMA, LDS operation, wait, barrier,
scratch, VGPR, and LDS counts are unchanged. The extra address arithmetic is
retained because measured conflict and end-to-end request costs fall.

## Evidence

- HIP events: `docs/notes/gfx1151-extend-attention-k-lds-swizzle-hip-events-2026-07-29.json`
- Counters: `docs/notes/gfx1151-extend-attention-k-lds-swizzle-counters-2026-07-29.json`
- Static counts: `docs/notes/gfx1151-extend-attention-k-lds-swizzle-disassembly-2026-07-29.json`
- Before/after disassembly: `docs/notes/disassembly/gfx1151-extend-attention-2026-07-29/`
- Reproducer: `tools/benchmark/benchmark_extend_attention_variants.py`
