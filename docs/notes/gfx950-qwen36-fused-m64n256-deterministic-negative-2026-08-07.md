# Qwen3.6 gfx950 deterministic M64N256 FMoE negative

## Verdict

Rejected for serving. The raw gfx950 candidate is deterministic and passes the
real-checkpoint isolated correctness gate, but its 366.004 us median is 63.9%
slower than the deployed AITER 64x256 kernel at the exact hot M=1024 graph
shape. It was therefore not integrated into SGLang and received no serving A/B.

The implementation and harness are retained because they establish a measured
deterministic reference for replacing AITER's packed-BF16 atomic route
accumulation.

## Shape and inputs

- GPU: AMD Instinct MI350X, gfx950, wave64
- Qwen weights: FP8 E4M3 with 128x128 block scales
- rows: 1,024
- hidden: 2,048
- expert intermediate: 512
- top-k: 9
- valid sorted IDs: 18,624 / 291 M64 blocks
- real-checkpoint full export:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T063500Z-raw-fused-m16-m1024/full-export`
- M64 sort:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T030200Z-fmoe64-disassembly-analysis-gpu1/m64-sort`
- retained artifacts:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T000000Z-deterministic-fmoe-n256-gpu1`

## Design

One four-wave workgroup processes each sorted M64 expert block. It computes the
four K128 W13 activation slices, stages W2 in LDS, and stores unweighted FP32
route partials indexed by token and top-k slot. The existing raw fixed-order
reducer then applies route weights in slot order and writes BF16 output.

This supersedes the atomic epilogue in the experimental source. Static
disassembly contains no global atomic instructions.

## Code object

- target: amdgcn-amd-amdhsa--gfx950
- workgroup: 256 threads / four waves
- LDS: 65,536 bytes
- VGPR: 192
- SGPR: 90
- scratch: zero
- static instructions: 24 FP8 MFMA, 66 global FP32 stores, 6 barriers

The reusable build is:

```bash
tools/build/build_gfx950_qwen36_moe_fused_m64n256_partial.sh \
  /data/netra/worktrees/netra-kernel-gdn-dual-replay \
  /data/netra/benchmarks/gfx950_qwen36_optimization/rebuild-deterministic-m64n256
```

## Correctness and determinism

The complete 1,024x2,048 BF16 layer output passed the predeclared gate:

- structural oracle: max abs 0.000849761, cosine 0.999973
- retained AITER output: max abs 0.000976562, cosine 0.999965
- finite output: yes
- bitwise-different repeats: 0 of 20

An independent rebuild and rerun produced the same correctness values and
0-of-20 nondeterminism result, with 368.604 us median and 378.440 us p90.

## HIP-event timing

| implementation | median us | p90 us | result |
|---|---:|---:|---|
| deployed AITER 64x256 | 223.323 | retained baseline | winner |
| raw deterministic M16 | 404.167 | retained baseline | rejected |
| raw deterministic M64N256 | 366.004 | 376.831 | rejected |

The N256 schedule improves the earlier deterministic raw M16 schedule by 9.4%,
but remains 63.9% slower than AITER. The fixed-order FP32 partial buffer and
separate reducer remove atomic nondeterminism at the cost of materialization and
an extra launch. A serving-worthy successor needs to preserve deterministic
route order without this full intermediate traffic, most plausibly through a
graph-safe persistent or multi-phase schedule.
