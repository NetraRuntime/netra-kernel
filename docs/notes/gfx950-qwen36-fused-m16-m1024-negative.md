# gfx950 Qwen3.6 full fused-MoE M16 experiment

Date: 2026-08-01 UTC

Status: **rejected for serving performance**. The raw assembly pipeline is
deterministic and passes the preregistered layer-level numerical gate, but its
M16 expert tile reloads too much weight data to beat the promoted packaged
AITER M64 kernel. It is retained as a complete gfx950 correctness prototype
and as evidence for the packaged W13 layout.

## Exact real-checkpoint case

- Model: Qwen3.6-35B-A3B-FP8, FP8 E4M3 weights with 128x128 scales.
- Shape: M=1024, top-k=9, hidden=2048, expert intermediate=512.
- Active experts: 197.
- Real routes: 9,216.
- AITER M16 sorted span: 10,992 rows in 687 retained blocks; 1,776 rows are
  slot-9 padding. The graph-stable allocation contains 833 blocks.
- Architecture: gfx950, wave64.

The retained export includes hidden FP8 values/scales, runtime W13/W2 bytes
and FP32 scales, sorted IDs, AITER BF16/FP8 activation boundaries, a structural
W13 oracle, and complete-layer oracles:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/
  20260801T063500Z-raw-fused-m16-m1024/full-export/
```

The structural W13 oracle reproduces the captured AITER post-SiLU BF16
activation at cosine 1.0, maximum absolute error 0.0078125, and mean absolute
error 2.80e-7.

## Raw implementation

The complete expert-compute kernel is:

```text
kernels/gfx950/fp8/moe/verify/experiments/
  qwen36_moe_fused_m16_fp8_gfx950.s
```

It performs W13 FP8 MFMA, BF16-rounded SiLU times up, per-128 E4M3
quantization, and W2 FP8 MFMA without a global activation intermediate. A
separate fixed-order raw reducer applies the nine routing weights. The code
object explicitly targets gfx950/wave64, uses 41,216 bytes of LDS, has no
scratch, and contains native `v_mfma_f32_16x16x128_f8f6f4` instructions.

The matching exporter, build script, and HIP-event harness are:

```text
tools/benchmark/export_qwen36_moe_grouped_capture.py
tools/build/build_gfx950_qwen36_moe_fused_m16.sh
harness/gfx950/fp8/moe/verify/
  qwen36_moe_fused_m1024_pipeline_gfx950.hip
```

## Corrected packaged W13 ABI

The first complete version treated W13 as logical row-major, which produced a
stage-1 cosine of -0.01493 and a complete-layer cosine of 0.01758. The M1024
packaged AITER path actually supplies W13 in its 16x16 shuffle:

```text
[N/16, K/32, 2, 16, 16]
```

The corrected per-lane byte address is:

```text
tile_n16 * 32768 + kblock_128 * 2048 + lane_n * 16 + k_subgroup * 16
```

and the two 16-byte fragments are separated by 1,024 bytes. This differs from
the retained M=1 rowwise path, which receives logical row-major W13. After the
fix, the raw stage-1 BF16 boundary has cosine 1.0, maximum absolute error
0.03125, and mean absolute error 1.79e-6 across 9,437,184 real-route values.

The post-SiLU boundary has cosine 0.999995. The complete raw pipeline compared
with deployed AITER has:

| Metric | Result |
|---|---:|
| BF16 mismatches | 1,657,897 / 2,097,152 |
| maximum absolute error | 0.000976562 |
| mean absolute error | 3.1369e-5 |
| cosine | 0.999965 |
| nondeterministic iterations | 0 / 20 |

## Performance rejection

HIP-event timing on identical captured tensors:

| Path | Median latency |
|---|---:|
| promoted packaged AITER persistent 64x256 | 223.323 us |
| raw M16 full expert compute | 388.887 us |
| raw M16 plus fixed-order reducer | 404.167 us |

The complete raw pipeline is 1.80x slower than the promoted kernel. M16 keeps
the entire gate/up and quantized activation in 40.25 KiB LDS, but it reloads
each expert's W13 and W2 weights for every 16 sorted rows. This is a structural
weight-traffic disadvantage relative to M64 reuse, not a launch-wait tweak.
The kernel is therefore not integrated into SGLang and cannot replace the
current performance base.

Primary diagnostic and timing artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/
  20260801T063500Z-raw-fused-m16-m1024/
    debug-stage7-w13-shuffle-grid833.log
    debug-stage6-w13-shuffle-grid833.log
    production-w13-shuffle-grid833.log
```

Future MoE work should use an M64 expert tile or a materially different
persistent/two-stage organization. Incremental scheduling of this M16 design
cannot recover its fourfold weight-reuse deficit.
