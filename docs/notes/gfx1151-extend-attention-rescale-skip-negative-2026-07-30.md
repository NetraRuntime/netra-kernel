# gfx1151 attention conditional rescale negative result (2026-07-30)

Status: **rejected; production kvbatch16 restored**. All values are measured on
gfx1151; no value is estimated.

The raw ASM candidate ballots the eight online-softmax alpha vectors. When every
lane's alpha is exactly 1.0, it skips 128 output-accumulator multiplies; otherwise
it executes the production sequence unchanged. Outputs are byte-identical at
T64 prefix 0/64/192, T8192 prefix 0/8K/16K/24K, the full real checkpoint, and
two fresh-server pairs.

| Prefix | kvbatch16 ms | rescale-skip ms | Speedup |
|---:|---:|---:|---:|
| 0 | 34.394352 | 34.434822 | 0.998825x |
| 8,192 | 99.735222 | 99.461990 | 1.002747x |
| 16,384 | 166.598633 | 165.906799 | 1.004170x |
| 24,576 | 234.112549 | 232.631897 | 1.006365x |
| **sum** | **534.840755** | **532.435509** | **1.004517x** |

At exact T8192/prefix24576, three-process rocprofv3 counters show dynamic
`VALUInsts` 878687.5→824995.5
(-6.110%),
`MeanOccupancyPerActiveCU` 6.537570→6.588274,
and unchanged 8,192 waves, 248 VGPR, 128 SGPR, 64 KiB LDS, and zero scratch.
`OccupancyPercent` is excluded because gfx1151 emitted invalid samples.

The matched exact 32,768/+1 trace keeps the same input hash, output token 5525,
and output hash. Attention improves 5346.822→5325.216 ms (1.00406x), while
profiled host E2E moves 22843.164→22814.496 ms.

Fresh-server profiler-free results decide the rejection:

| Pair | kvbatch16 ms | rescale-skip ms | Speedup | Result |
|---|---:|---:|---:|---|
| A | 22071.103 | 22000.769 | 1.003197x | faster |
| B | 22086.061 | 22131.321 | 0.997955x | slower |
| **mean** | **22078.582** | **22066.045** | **1.000568x** | noise-level |

The 6.11% dynamic-VALU reduction is real, but its 0.057% mean serving movement is
not repeatable across pairs. Per the end-to-end acceptance rule, do not enable it.
The raw experiment and scripts are retained for future batched/prefix-heavy tests.
