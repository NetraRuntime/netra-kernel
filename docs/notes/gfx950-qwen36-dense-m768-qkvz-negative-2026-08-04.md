# Qwen3.6 gfx950 M768 QKVZ serving negative

## Verdict

Rejected for deployment. The raw gfx950 kernel is bit-exact against the retained
CKTile BF16 output and 4.6% faster in the isolated real-checkpoint GEMM, but it
regresses the canonical dFlash serving workload by 6.4%. The server remains on
the CKTile control path.

## Target and implementation

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- checkpoint: Qwen3.6-35B-A3B FP8 E4M3, 128x128 blocks
- exact verification shape: M=768, N=12,288, K=2,048
- role: target GDN Q/K/V/Z projection
- launch: 384x24 workgroups, 64 threads per workgroup
- code object: 106 VGPR, 34 SGPR, zero LDS, zero scratch
- raw source:
  `kernels/gfx950/fp8/dense/verify/qwen36_dense_m768_n12288_k2048_fp8_mfma_m32n32_gfx950.s`

The integration was exact-shape gated and positively observed during SGLang
graph capture:

`Using raw gfx950 dense QKVZ kernel for M=768 N=12288 K=2048`

## Isolated result

The real-checkpoint fixture uses a retained M=768 activation and layer-0 QKVZ
weight. Across 200 HIP-event iterations:

| implementation | median us | p90 us |
|---|---:|---:|
| CKTile deployed control | 115.441 | 149.002 |
| raw gfx950 candidate | 110.121 | 111.849 |

The candidate is 4.61% faster at the median. It produced zero BF16 mismatches
across 9,437,184 elements and replayed exactly under HIP graphs. Against the
FP32 oracle, max absolute error was 0.030221 and cosine similarity was 0.999999.

Isolated artifacts:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T063000Z-dense-m768-qkvz-gpu6`

## Canonical serving A/B

Both sides used one MI350X, FP8 weights, FP8 KV, dFlash block 12, 32K context,
0.80 static memory fraction, at most 64 running requests, graphs through 64,
and exactly 192 random requests of 1,024 input plus 1,024 forced output tokens.
Only `SGLANG_NETRA_QWEN36_GFX950_DENSE_M768_QKVZ` changed.

| side | output tok/s | accept length | mean TPOT ms |
|---|---:|---:|---:|
| candidate repeat 1 | 6,601.93 | 4.09 | 7.61 |
| candidate repeat 2 | 6,503.54 | 4.13 | 7.52 |
| candidate repeat 3 | 6,602.20 | 4.13 | 7.57 |
| reverse control 1 | 7,026.21 | 4.22 | 7.04 |
| reverse control 2 | 6,975.27 | 4.21 | 7.05 |

The two warmed candidate repeats average 6,552.87 output tok/s. The reverse
control averages 7,000.74 output tok/s, so the candidate regresses throughput by
6.40%. Acceptance falls by about 0.09 token and TPOT rises by about 7.4%. The
acceptance change is correlated with the regression; this A/B does not by itself
prove whether arithmetic drift or run-to-run draft sampling caused it.

Candidate artifacts:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T052914Z-qwen36-best-gpu6`

Control artifacts:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T053525Z-qwen36-best-gpu6`

## Conclusion

Do not promote this kernel. An isolated win and equality on one retained layer
fixture are not sufficient evidence for the full 30-layer recurrent path. Future
dense work should add layer-by-layer live comparisons and acceptance attribution,
or target a draft projection whose numerical changes are shown not to reduce
acceptance.
