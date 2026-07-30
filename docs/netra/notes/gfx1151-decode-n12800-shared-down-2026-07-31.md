# gfx1151 N12800 MXFP4 and BF16 shared-down decode (2026-07-31)

All measurements are from AMD Ryzen AI Max+ PRO 395 (`gfx1151`) inside the
Netra LXC. Values are measured unless explicitly marked estimated.

## Accepted raw kernels

- `mxfp4_linear_decode_n12800_k2048_block64_gfx1151.s`: fixed M1 N12800
  K2048, grid `(25,64,1)`, block 128, one unscaled FP32 partial per MX block.
- `mxfp4_linear_decode_n12800_block64_reduce_gfx1151.s`: exact original-order
  64-FMA scale/reduction, grid 50, block 256, RN-even BF16 output.
- `bf16_shared_down_decode_wave4_gfx1151.s`: fixed M1 N2048 K512 BF16 shared
  expert down projection, grid 64, block 256, four rows per wave32.

The runtime preloads each module before graph capture and launches cached
`hipFunction_t` handles on the caller's HIP stream. Candidate workspaces and
outputs are stable per-layer tensors allocated at model construction.

HSACO SHA-256: N12800 compute
`f16c9cdb6d0fd7bdd6c115225d6a3df76912c170144183c3358df032ba1d411b`,
N12800 reduction
`da22999525a1e03ce074b912804e0d3db38530d03f89f4a5fc9ee19d71617c04`,
and BF16 shared down
`d62461d65232d67c40b8d9ef114f78ab46f4c8712468b266917c630e5e4af0fe`.

## Isolated correctness and HIP events

| gfx1151 path | real weights | correctness | baseline median | raw median | speedup | status |
|---|---:|---|---:|---:|---:|---|
| MXFP4 N12800 K2048 QKVZ/BA | all 30 GDN layers | BF16 bit-exact | 145.974 us | 52.158 us | 2.799x | measured, rotated |
| BF16 N2048 K512 shared down | all 40 layers | max abs 0.001953125, at most 4 BF16 mismatches/layer | 22.722 us | 12.103 us | 1.877x | measured, rotated |

The committed whole-working-set harnesses measured 30-layer N12800 passes at
5.4551 versus 3.0356 ms (1.797x, bit-exact) and 40-layer BF16 shared-down
passes at 1.2936 versus 0.9998 ms (1.294x). Per-launch event synchronization
produces the larger table speedups and is retained only as a kernel probe.

The BF16 kernel uses a different FP32 reduction tree from rocBLAS and is
model-native tolerance-equivalent, not bit-exact. Its exact-210/128 greedy
sequence differs from rocBLAS, while candidate eager and graph replay hashes
match exactly.

## Serving

Uncached batch-1, graph disabled, dFlash disabled, host request wall clock.
All rows use exact token counts on gfx1151.

| comparison | exact tokens | baseline server E2E | candidate server E2E | change | steady decode | status |
|---|---:|---:|---:|---:|---:|---|
| N12800 off/on | 1/32 | 1313.048 ms | 1248.333 ms | -4.929% | 31/E2E 23.61 to 24.83 tok/s | measured approximation |
| N12800 off/on | 210/128 | 5648.668 ms | 5426.993 ms | -3.924% | 24.63 to 25.73 tok/s | measured SGLang log |
| shared down off/on atop N12800 | 1/32 | 1252.322 ms | 1230.755 ms | -1.722% | 31/E2E 24.75 to 25.19 tok/s | measured approximation |
| shared down off/on atop N12800 | 210/128 | 5423.500 ms | 5316.613 ms | -1.971% | 25.75 to 26.27 tok/s | measured SGLang log |

The two additions improve the previous 24.55 tok/s eager result to 26.27
tok/s, a measured 7.01% gain on gfx1151. Candidate eager versus full-graph
exact-210/128 token and text hashes are identical.

## Full graph negative result

Full decode graph tiers 1/2/4/8/12/16 captured successfully with the new raw
kernels. Capture measured 2.86 s and 0.17 GB. Exact-210/128 graph E2E was
5321.928 ms versus eager 5316.613 ms; steady graph decode was 25.91 tok/s
versus eager 26.27 tok/s. Full graph is retained as correct and graph-safe but
rejected as a performance mode for this batch-1 configuration.

## Fresh rocprofv3 ranking

Trace: `results/profiles/gfx1151/decode-m1-32-n12800-shared-down-20260731`.
Measured gfx1151 totals: 46,943 launches, 1,053,748.717 us trace wall,
941,512.976 us summed GPU kernel duration, and 113,173.914 us positive launch
gaps. The profiler ran with signal handlers disabled and no counters, avoiding
the known rocprofv3 signal-6 counter path.

| remaining kernel/family | calls | total GPU | mean GPU | status |
|---|---:|---:|---:|---|
| raw BF16 LM head | 27 | 177.117 ms | 6559.887 us | measured rocprofv3 gfx1151 |
| raw BF16 QKV | 265 | 168.422 ms | 635.556 us | measured rocprofv3 gfx1151 |
| rocBLAS grid256 projection | 1058 | 83.959 ms | 79.357 us | measured rocprofv3 gfx1151 |
| raw shared gate+up+SiLU | 1058 | 78.978 ms | 74.649 us | measured rocprofv3 gfx1151 |
| routed block64 gate/up | 2116 | 77.460 ms | 36.607 us | measured rocprofv3 gfx1151 |
| rocBLAS standard attention output | 265 | 59.595 ms | 224.888 us | measured rocprofv3 gfx1151 |
| N12800 block compute | 793 | 55.329 ms | 69.772 us | measured rocprofv3 gfx1151 |
| N12800 exact reduction | 793 | 17.085 ms | 21.544 us | measured rocprofv3 gfx1151 |
| BF16 shared down | 1058 | 25.595 ms | 24.192 us | measured rocprofv3 gfx1151 |

At 26.27 tok/s, the updated 50 tok/s mission requires reducing 38.066 to
20.000 ms/token, another 47.46% (estimated requirement). Thirty tok/s remains
an intermediate gate requiring another 12.43%. The fresh trace contains
addressable cost, but 50 tok/s is not yet measured. The next work order is a
structural pass over LM-head/sampling, BF16 QKV and attention output, and the
remaining shared/routed expert path rather than launch-only tuning.
