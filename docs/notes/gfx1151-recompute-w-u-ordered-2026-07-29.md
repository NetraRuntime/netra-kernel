# Ordered raw-ASM GDN recompute W/U on gfx1151

All performance and correctness values below are measured on gfx1151 unless a
row is explicitly labeled static disassembly. No values are estimated.

## Ranked-path reason

The post-dense-layout exact 32,768/+1 process-start trace ranked
`recompute_w_u_fwd_kernel` fourth. Restricting the comparison to the 120 real
8,192-token chunk calls removes 30 tiny health calls: the compiler kernel used
2,383.947096 ms total, 19.866226 ms mean, and 19.973305 ms median.

## Correctness defect found in the rejected prototype

The rejected A-reuse raw prototype computed W's BF16 right-hand operand as
`k * (beta * exp(g))`. Triton source and disassembly compute the
left-associated `(k * beta) * exp(g)` before BF16 rounding. The reassociation
created small W differences and flipped the robust 32K pair-A greedy token
from compiler token 248045 to raw token 220.

`recompute_w_u_ordered_gfx1151.s` preserves the compiler multiplication order.
It retains the two-wave A-reuse schedule, 16 KiB LDS, 136 VGPR, zero scratch,
and raw WMMA compute. The fixed production specialization is B1, T8192, H32,
Hg16, K128, V128, BT64. Other shapes remain on the compiler fallback.

## Correctness — gfx1151 measured

- Controlled random input versus the 2-wave/1-stage Triton oracle: W max abs
  0.000244140625, U max abs 0.00048828125.
- Across 265 real-checkpoint layer/chunk comparisons from the 8K and paired
  32K validation requests: worst W max abs 0.00048828125 and worst U max abs
  0.03125. All outputs were finite.
- Exact uncached 32,768/+1 pair A: compiler and production raw token 248045.
- Exact uncached 32,768/+1 pair B: compiler and production raw token 220.
- Stable-pointer HIP graph capture/replay was bit-identical to raw eager W/U.

SGLang deterministic-inference mode could not provide an additional gate on
this machine: its unrelated persistent matmul requested 99,328 bytes LDS while
gfx1151 exposes 65,536 bytes. This is a measured runtime limitation, not a
kernel estimate.

## GPU timing — gfx1151 measured with rocprofv3

| Exact request path | Calls | Total GPU ms | Mean ms | Median ms | Min / max ms |
|---|---:|---:|---:|---:|---:|
| Triton 4w3, real T8192 calls | 120 | 2383.947096 | 19.866226 | 19.973305 | 17.508533 / 22.201913 |
| ordered raw ASM | 120 | 1189.433566 | 9.911946 | 9.793720 | 9.525355 / 10.575167 |

The raw family removes 1,194.513530 ms of GPU work, a measured 2.004271x
speedup and 50.1065% reduction. The new process-start trace contains only 60
negligible compiler health calls (3.248136 ms); all 120 request calls dispatch
the raw symbol.

A same-process HIP-event random-input comparison measured 10.656205 ms median
for ordered raw versus 11.772717 ms for the best 2w1 compiler oracle, 1.104776x.

## Hardware counters — gfx1151 measured

The pure ROCm 7.2 HIP runner was used because Python-wheel counter collection
cannot load `aqlprofile` and aborts with signal 6. One counter was collected per
process at the exact production dispatch shape.

| Counter | Value |
|---|---:|
| OccupancyPercent | 24.442883% |
| MeanOccupancyPerActiveCU | 15.871731 |
| Wavefronts / SQ_WAVES | 8,192 / 8,192 |
| FETCH_SIZE | 122,920.9375 KiB |
| WRITE_SIZE | 69,271.75 KiB |
| L2CacheHit | 49.049917% |
| MemUnitBusy | 95.046371% |
| LDSBankConflict | 41.904762% |
| SQ_BUSY_CYCLES | 614,984,581 |
| SQ_WAVE_CYCLES | 9,633,363,066 |
| SQ_INSTS_FLAT | 2,818,048 |
| SQ_INSTS_LDS | 14,221,312 |

The profiler reports 136 VGPR, 128 SGPR, 16,384 bytes LDS, zero scratch, grid
8192x32, block 64. A direct wait/dependency-stall counter is not exposed by
this gfx1151 metric set and is not estimated. The 95.05% memory-unit busy,
49.05% L2 hit rate, and 41.90% LDS bank-conflict rate identify the next raw
revision's concrete limits.

## Serving — gfx1151 measured host E2E

Both rows are exact 32,768 input +1 output, uncached, batch 1, graphs disabled,
and dFlash disabled.

| State | Pair A ms / token | Pair B ms / token | Mean ms |
|---|---:|---:|---:|
| preceding dword-layout baseline | 28100.356803 / 248045 | 27904.237105 / 220 | 28002.296954 |
| ordered raw recompute | 27653.933755 / 248045 | 26888.400422 / 220 | 27271.167089 |

The measured host reduction is 731.129865 ms, 1.026810x, or 2.6110%.
The process-start profiled request independently measured 27,989.581540 ms and
token 248045.

## Disassembly and integration

The ordered raw disassembly is in
`docs/notes/disassembly/recompute-w-u-ordered-gfx1151/ordered.dis`; compiler
and rejected-raw baselines remain in
`docs/notes/disassembly/recompute-w-u-gfx1151/`. Static instruction counts are
8,429 rejected raw versus 8,541 ordered raw. Both have 128 WMMA, 88 global
loads, and 256 global stores; the ordered revision adds 112 scalar/vector
multiply instructions to restore model-native association.

The HIP bridge preloads the HSACO with the other Netra modules. The SGLang
custom-op boundary launches the raw module on the current stream and falls back
to Triton outside the exact safe shape. Capture contains no allocation or
module load; output allocations occur before the custom-op launch.

## Counter-profiler negative result

The first Python counter attempt with the ROCm 7.2 system profiler failed to
load the wheel's `libamdhip64.so.7` (`hsa_ext_image_create_v2`). The ABI-matched
wheel profiler then reported `aqlprofile API table load failed` and caught
signal 6. The accepted counter script therefore uses a pure HIP 7.2 executable
and the system ROCm 7.2 profiler; all fourteen listed passes completed.
