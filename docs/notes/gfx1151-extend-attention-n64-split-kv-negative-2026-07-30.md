# gfx1151 N64 split-KV attention negative result (2026-07-30)

Status: **rejected**. All runtime and hardware-counter values below are measured
on gfx1151. Resource and disassembly properties are labeled static. The raw ASM
candidate is retained as an experiment and is not connected to production
SGLang dispatch.

## Question tested

This experiment tests attention checklist items 1, 2, and 5 together without
repeating online softmax:

- keep the M64 x N64 QK arithmetic and one online-softmax/rescale update;
- retain Q in 32 KiB LDS for the whole key loop;
- place the 8 KiB P transpose at a separate LDS address, removing per-tile Q
  restoration;
- load K and V in two N32 phases through one reusable 16 KiB stage;
- batch eight page-table/global transfers per wave and phase;
- use 56 KiB total LDS, 248 VGPRs, 128 SGPRs, and zero scratch (static gfx1151
  metadata).

The first valid implementation used serial load/wait/write sequences. At exact
T8192 it was 24-48% slower, so batched loading was implemented before the final
decision. This is direct evidence that item 2 is necessary for split staging.

## Correctness gate

The graph-safe device `kv_indptr` ABI is preserved. At T64 and prefix 0, 64,
and 192, the batched candidate is byte-identical to the accepted N64 raw ASM.
At exact T8192 and prefix 0, 8192, 16384, and 24576, every output is also
byte-identical (`max_abs=0`, `mean_abs=0`). These are measured gfx1151 results,
not estimates.

## HIP-event performance gate

Each exact T8192 row uses three warmups and eleven identical-input samples.

| Prefix | Accepted N64 ms | Split-KV N64 ms | Relative | Status |
|---:|---:|---:|---:|---|
| 0 | 44.5979 | 45.6061 | 0.9779x | gfx1151 measured |
| 8,192 | 128.0763 | 131.9309 | 0.9708x | gfx1151 measured |
| 16,384 | 217.3222 | 220.8162 | 0.9842x | gfx1151 measured |
| 24,576 | 307.6241 | 309.9449 | 0.9925x | gfx1151 measured |
| Four tiers | 697.6204 | 708.2980 | 0.9849x | gfx1151 measured sum |

The final batched candidate is 1.53% slower over the four-tier geometry. No
serving integration or full-request benchmark is justified.

## rocprofv3 evidence

Standalone HIP harnesses avoid the known Python/PyTorch PMC abort. Each counter
is collected in a separate rocprofv3 process at exact T8192/prefix24576.

| Counter/resource | Accepted N64 | Split-KV N64 | Result |
|---|---:|---:|---|
| LDS | 65,536 B | 57,344 B | 12.5% lower, static gfx1151 metadata |
| VGPR | 248 | 248 | unchanged, static gfx1151 metadata |
| OccupancyPercent | 7.666990% | 7.565829% | no occupancy step, gfx1151 measured |
| Mean occupancy/active CU | 4.936308 | 4.876838 | no improvement, gfx1151 measured |
| Wavefronts | 8,192 | 8,192 | unchanged, gfx1151 measured |
| VRAM fetch | 17,767,828.7 KiB | 14,878,522.1 KiB | 16.3% lower, gfx1151 measured |
| L2 hit | 27.088579% | 31.518315% | +4.43 points, gfx1151 measured |
| LDS bank conflict | 34.630479 | 36.116368 | worse, gfx1151 measured |
| VALUInsts | 906,046 | 897,973 | 0.9% lower, gfx1151 measured |

The 8 KiB LDS reduction remains above the next residency threshold, so it does
not increase concurrent workgroups or waves. The extra K/V phase barriers and
LDS passes outweigh the improved memory traffic. gfx1151's exposed metric set
has no direct dependency-stall counter; the result does not estimate one.

## Decision

Reject this combined item-1/item-5 layout. Keep the accepted 64 KiB N64 kernel.
A future lower-LDS design must cross a real occupancy threshold (likely at or
below 32 KiB per workgroup) or overlap phase loading with useful compute; a
56 KiB staging reduction alone has no end-to-end value. Item 4 also remains
open because this design still allocates 248 VGPRs.

Reproduce with
`tools/build/build_extend_attention_n64_split_kv_experiment.sh`,
`tools/benchmark/benchmark_extend_attention_variants.py`, and
`tools/profiling/profile_extend_attention_n64_split_kv_counters.sh`.
Machine-readable HIP-event and counter reports plus before/after disassembly
are adjacent to this note.
# gfx1151 N64 split-KV attention negative result (2026-07-30)

Status: **rejected**. Runtime and counter values below are measured on gfx1151.
Resources are static metadata. This raw ASM is not in production dispatch.

## Design tested

This tests checklist items 1, 2, and 5 without repeating online softmax:

- retain M64 x N64 QK and one online-softmax/rescale update;
- keep Q in 32 KiB LDS across the key loop;
- store the 8 KiB P transpose separately, eliminating Q restoration;
- stage K and V in two N32 phases through reusable 16 KiB LDS;
- batch eight page-table/global transfers per wave and phase;
- allocate 56 KiB LDS, 248 VGPRs, 128 SGPRs, and zero scratch (static gfx1151).

The first correct serial-load version was 24-48% slower at exact T8192. Batched
loading recovered nearly all of that loss, directly validating item 2 as
necessary for split staging.

## Correctness

The graph-safe device `kv_indptr` ABI is preserved. At T64 and prefix 0/64/192,
and exact T8192 at prefix 0/8192/16384/24576, the candidate is byte-identical
to accepted N64 (`max_abs=0`, `mean_abs=0`). These are measured gfx1151 results.

## HIP-event performance

Each exact T8192 row uses three warmups and eleven identical-input samples.

| Prefix | Accepted N64 ms | Split-KV N64 ms | Relative | Status |
|---:|---:|---:|---:|---|
| 0 | 44.5979 | 45.6061 | 0.9779x | gfx1151 measured |
| 8,192 | 128.0763 | 131.9309 | 0.9708x | gfx1151 measured |
| 16,384 | 217.3222 | 220.8162 | 0.9842x | gfx1151 measured |
| 24,576 | 307.6241 | 309.9449 | 0.9925x | gfx1151 measured |
| Four tiers | 697.6204 | 708.2980 | 0.9849x | gfx1151 measured sum |

The batched candidate is 1.53% slower in the four-tier sum. No serving
integration or full-request benchmark is justified.

## rocprofv3 evidence

Standalone HIP harnesses avoid the Python/PyTorch PMC abort. Each counter is a
separate rocprofv3 process at exact T8192/prefix24576.

| Counter/resource | Accepted N64 | Split-KV N64 | Result |
|---|---:|---:|---|
| LDS | 65,536 B | 57,344 B | 12.5% lower, static gfx1151 |
| VGPR | 248 | 248 | unchanged, static gfx1151 |
| OccupancyPercent | 7.666990% | 7.565829% | no occupancy step, gfx1151 measured |
| Mean occupancy/active CU | 4.936308 | 4.876838 | no improvement, gfx1151 measured |
| Wavefronts | 8,192 | 8,192 | unchanged, gfx1151 measured |
| VRAM fetch | 17,767,828.7 KiB | 14,878,522.1 KiB | 16.3% lower, gfx1151 measured |
| L2 hit | 27.088579% | 31.518315% | +4.43 points, gfx1151 measured |
| LDS bank conflict | 34.630479 | 36.116368 | worse, gfx1151 measured |
| VALUInsts | 906,046 | 897,973 | 0.9% lower, gfx1151 measured |

The LDS reduction does not cross a residency threshold, so it cannot increase
concurrent workgroups or waves. Extra K/V phase barriers and LDS passes outweigh
improved memory traffic. gfx1151 exposes no direct dependency-stall counter, so
none is estimated.

## Decision

Reject this combined item-1/item-5 layout and keep accepted N64. A future
lower-LDS design must cross a real occupancy threshold (likely at or below
32 KiB/workgroup) or overlap loads with compute. Item 4 remains open because
this design still allocates 248 VGPRs.

Reproduce with `tools/build/build_extend_attention_n64_split_kv_experiment.sh`,
`tools/benchmark/benchmark_extend_attention_variants.py`, and
`tools/profiling/profile_extend_attention_n64_split_kv_counters.sh`.
Machine-readable HIP-event/counter reports and disassembly are adjacent.
