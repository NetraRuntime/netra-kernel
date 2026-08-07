# Qwen3.6 gfx950 grouped-GQA8 long-prefill topology negative

## Verdict

Rejected before raw-assembly extraction. Grouping query heads so a workgroup can
reuse each FP8 K/V tile is numerically sound for the exact Qwen target-attention
contract, but the best grouped topology is 27.4% slower than the deployed
M128/N128/W8 Triton oracle at the longest 32K-prompt chunk.

The screening implementation is retained in the benchmark harness. No production
runtime integration is enabled.

## Exact contract

- GPU: AMD Instinct MI350X, gfx950, wave64
- target checkpoint and KV cache: FP8 E4M3
- extension: BF16, M=8192, 16 query heads, 2 KV heads, D=256
- prefix: 24,576 tokens; full attention (sliding window = -1)
- output: BF16
- timing: HIP events, 3 warmups and 10 retained repeats
- artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T004800Z-prefill-grouped-gqa8-gpu1`

## Design

The deployed workgroup owns 128 tokens for one query head. The candidate keeps
128 total query rows but groups 2, 4, or 8 heads from the same GQA8 group, so the
heads can reuse the same physical FP8 K/V tile:

| grouped heads | tokens per head | grid | median us | versus control |
|---:|---:|---:|---:|---:|
| deployed M128/N128/W8 | 128 | 1 x 16 x 64 | 5,389.215 | control |
| 2 | 64 | 128 x 2 x 4 | 8,089.784 | +50.11% |
| 4 | 32 | 256 x 2 x 2 | 7,559.098 | +40.26% |
| 8 | 16 | 512 x 2 x 1 | 6,865.351 | +27.39% |

All grouped variants were deterministic across two poisoned-output launches.
The best grouped result had max absolute error 7.62939e-6, cosine 0.99999994,
and zero unwritten elements against the current in-process FP8-KV oracle.

The first implementation also traversed all 8K extension keys for every causal
segment. Bounding the extension loop to each segment's causal endpoint improved
the eight-head arm from 7,648.418 to 6,865.351 us, but it remained decisively
slower than control.

## Invalid screen retained as a method negative

An initial run accidentally used the harness's 4,095-token sliding-window
default. It appeared 25.6% faster, but cosine was only 0.923862 because the
candidate and target full-attention contracts differed. That result is rejected.
The retained full-attention result explicitly uses
`--sliding-window-size -1`.

## gfx950 compiler finding

A separate exact M128 screen tested kpack 1, 2, and 4. The installed gfx950
Triton backend warns that kpack is deprecated and overwrites every value to 1.
Timing differences were noise; kpack is not a viable CDNA4 tuning axis.

## Conclusion

K/V sharing alone does not compensate for the less efficient grouped row/MFMA
layout. Do not extract this compiler object as a raw kernel. A successor must
preserve the deployed M128 row mapping while reducing the 256-VGPR, 64-KiB LDS,
and 15-barrier main-body cost, rather than regrouping heads.
