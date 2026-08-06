# Qwen3.6 gfx950 M12 split-sequence target attention promotion

## Verdict

Accepted for the single-GPU MI350X Qwen3.6 FP8 path. The raw gfx950
stage-1/stage-2 attention pair and new graph-safe raw metadata preparation
kernel replace the high-cost target full-attention verification launch for
batch-1 DFlash verification. The exact 32K-input/16K-output serving gate
improved output throughput by 3.39% despite slightly lower aggregate draft
acceptance.

## Contract

- GPU: AMD Instinct MI350X, gfx950, wave64
- target weights: FP8 E4M3 with 128x128 blocks
- target KV: FP8 E4M3
- verification: M=12, Q heads=16, KV heads=2, head dimension=256
- sequence prefix: up to the retained 65,536-token c64 profile
- split schedule: 32 sequence splits, maximum workspace capacity 129
- graph scope: batch-1 target verification, eager and captured replay
- no allocation, host synchronization, or scalar `.item()` in graph replay

The preparation kernel consumes SGLang's stable `req_to_token` table and device
request index, appends the twelve extension slots to the already-materialized
prefix index vector, and emits the twelve causal sequence lengths. The bridge
loads all three HSACOs before graph capture.

## Code objects

| kernel | VGPR | SGPR | LDS | scratch | wave |
|---|---:|---:|---:|---:|---:|
| metadata prepare | 5 | 26 | 0 | 0 | 64 |
| attention stage 1 | 84 | 58 | 0 static / 8 KiB dynamic | 0 | 64 |
| attention stage 2 | 13 | 42 | 0 | 0 | 64 |

All objects declare `amdgcn-amd-amdhsa--gfx950`. Stage 1 contains raw
`v_mfma_f32_16x16x32_fp8_fp8`; none of the three objects reports a spill.

## Isolated correctness and timing

At prefix length 49,152 with a randomly permuted physical KV mapping, 12 verify
tokens, and 32 splits, the raw path was compared with twelve sequential deployed
SGLang attention calls:

| implementation | HIP-event mean | relative |
|---|---:|---:|
| sequential deployed oracle | 1.108661 ms | 1.00x |
| raw prepare + stage 1 + stage 2 | 0.252886 ms | 4.384x |

All 49,152 BF16 output elements were bitwise exact. Intermediate stage-1 output
and LSE were also bitwise exact. Oracle and candidate SHA-256 were both
`a1e3fab44a709a9f2044f4d07837e9be4039fc0780eddada19b56e709c07a06d`.

The retained low-accept trace measured the previously deployed batch-1 target
attention at 2.069419 ms mean, 186.248 ms total over 90 calls, and 68.35% of GPU
time. This was the highest-cost row in that survivor trace.

## End-to-end result

The canonical run used 192 requests at concurrency 64, exactly 32,768 input and
16,384 forced output tokens per request, a 65,536-token context, block-12
DFlash, a 4,096-token physical draft window, and FP8 target/draft KV.

| metric | retained control | candidate | delta |
|---|---:|---:|---:|
| duration | 754.33 s | 729.64 s | -3.27% |
| output throughput | 4,170.22 tok/s | 4,311.37 tok/s | +3.39% |
| total throughput | 12,510.65 tok/s | 12,934.10 tok/s | +3.39% |
| mean TPOT | 7.48 ms | 7.14 ms | -4.46% |
| aggregate accept length | 9.03 | 8.89 | -1.61% |

Because acceptance decreased, the throughput gain cannot be attributed to a
luckier speculative trajectory. Two full GSM8K runs scored 1,258/1,319 (95.38%)
and 1,256/1,319 (95.22%), inside the retained unchanged-control range.

## Remaining issue

This does not repair the artificial forced post-completion acceptance collapse.
The candidate still had two requests below accept length 2; the worst was 1.125
and contained a long newline tail. No acceptance-based bypass is present. This
promotion reduces the honest verification cost while the draft-distribution
problem remains separately open.

Artifacts:

- isolated: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260806T214529Z-attention-splitseq-m12-gpu0`
- serving: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260806T222732Z-qwen36-c64-gpu0`
- retained control: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260806T182838Z-qwen36-c64-gpu3`
