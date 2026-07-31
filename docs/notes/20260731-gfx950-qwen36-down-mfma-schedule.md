# gfx950 Qwen3.6 MoE down/reduce MFMA dependency schedule

Date: 2026-07-31 UTC

Target: one AMD Instinct MI350X (`gfx950`), wave64, Qwen3.6-35B-A3B
FP8 E4M3 128x128 weights, BF16 output and accumulation boundary, TP1.

## Accepted change

The production raw-assembly kernel now uses `s_nop 11` after each
`v_mfma_f32_16x16x128_f8f6f4` instead of `s_nop 15`:

```text
kernels/gfx950/fp8/moe/decode/
  qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950.s
```

This is the shortest dependency delay that was correct and deterministic on
the installed gfx950 assembler/runtime. The launch remains 128 workitems (two
wave64s), 42 SGPR, 32 VGPR, 1,024 bytes LDS, no scratch, and no private segment.
The accepted code object is explicitly `amdgcn-amd-amdhsa--gfx950` with
wavefront size 64.

## Schedule sweep

The retained experiment source parameterizes the delay with
`NETRA_MFMA_NOP`:

```text
kernels/gfx950/fp8/moe/decode/experiments/
  qwen36_moe_down_reduce_fp8_mfma_2wave_nop_gfx950.s
```

All variants used the corrected deployed AITER-shuffled weight capture and the
same arithmetic/launch geometry.

| delay | BF16 mismatches vs FP32 oracle | nondeterministic launches | median HIP-event time | decision |
|---:|---:|---:|---:|---|
| 0 | 2,048 / 2,048 | 28 / 1,000 | 8.72 us | reject |
| 3 | 2,048 / 2,048 | 0 / 1,000 | 8.76 us | reject |
| 7 | 2,048 / 2,048 | 999 / 1,000 | 8.92 us | reject |
| 11 | 28 / 2,048 | 0 / 1,000 | 9.04--9.08 us | accept |
| 15 | 28 / 2,048 | 0 / 1,000 | 9.20--9.24 us | control |

Five additional 20,000-launch delay-11 stress runs had zero nondeterministic
outputs. A clean final 20,000-launch rebuild measured 9.12 us for delay 11 and
9.24 us for delay 15, with identical numerical metrics: 28/2,048 BF16
differences versus the FP32 oracle, maximum absolute error 0.00155747, cosine
0.999999.

## Real-checkpoint acceptance

An eager deterministic A-C-A serving comparison used exact uncached
210-input/128-output requests. Twenty delay-11 requests had a combined median
of 4.657588 s; the adjacent ten-request delay-15 control median was 4.689592 s.
This is 0.6824% lower request latency and 0.6871% higher output rate. All 30
requests produced the stable token hash
`8cf5682c0ab5307cb04b6d7292da155ddf14c7936f39fe10e849595e5967ea57`.

The full five-shot GSM8K gate produced 1,251/1,314 correct (95.2055%), inside
the established coherent 1,248--1,254 range. rocprofv3 measured 5,093 bounded
request-window calls at 14.630 us mean versus 14.655 us for the adjacent
delay-15 trace.

Code-object SHA-256:

- delay 11: `ae8adf9d49d05d40fc396ea11db6bbde95ebc299a82085a335cab040939ccce7`
- delay 15: `fb2de6a7ed4c29be0577a8c350dc37b2ce51820bf408988e493b8d5b23f1de97`

## Rejected adjacent variants

The row-major-resident K128 variant was slower in the isolated harness
(10.32 us versus 9.24 us control), and real serving required the already
rejected M>1 Triton prefill residency path; it reproduced the known incoherent
hash and was rejected. The K32 row-major variant had 753/2,048 BF16 oracle
differences and was also rejected. Parallel 3--9-wave variants measured
29.6--31.9 us versus the then-current 27.92 us control and were not promoted.

Artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/
  20260731T124700Z-down-rowmajor-sequential-screen/
  20260731T125200Z-coherent-rowmajor-moe-screen/
  20260731T130100Z-down-mfma-nop-sequential-screen/
  20260731T130700Z-coherent-down-nop11-candidate/
  20260731T131200Z-coherent-down-nop15-control/
  20260731T131800Z-coherent-down-nop11-candidate-repeat/
  20260731T133100Z-coherent-down-nop11-profile/
```
