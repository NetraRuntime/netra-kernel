# gfx950 Qwen3.6 FlashQLA segment transition negative result

Date: 2026-08-02

Target: one MI350X, `gfx950`, wave64, Qwen3.6-35B-A3B FP8 E4M3
weights, BF16 GDN state, exact `B=1,T=8192,H=32,Hg=16,K=V=128,BT=64`.

## Exact decomposition

For Qwen's V-first recurrent state `S[V,K]`, one chunk is

```text
v_new = U - W S^T
S' = d S + (diag(e) v_new)^T K
   = H_chunk + S (d I - W^T diag(e) K).
```

The raw kernel initializes `S=I`, sets `U=0`, and executes 32 ordinary
recurrence chunks to produce one homogeneous transition `M_t`. Four sequence
segments therefore compose exactly as `S_{t+1} = H_t + S_t M_t`.

The real-checkpoint FP32 oracle confirmed the derivation before raw-kernel
results were viewed. A single 128-chunk affine summary was bit-exact to direct
recurrence. Composing four independent 32-chunk summaries had maximum absolute
error `2.288818359375e-5`, cosine `1.0`, and no elements over `0.125`.

## Raw gfx950 implementation

The retained experiment is
`kernels/gfx950/linear_attention/prefill/experiments/qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950.s`.
It launches `grid=(32,32,1)`, 256 threads per workgroup, uses 20 KiB LDS,
wave64 `v_mfma_f32_16x16x32_bf16`, 115 VGPRs, 36 SGPRs, and no scratch.
Each workgroup owns one `(segment,head,V16)` transition tile.

The retained diagnostic variant keeps the FP32 transition in BF16 hi/lo LDS
projections and also decomposes the gated update into BF16 hi/lo MFMA
operands. It is not correctness-valid. Five identical launches against one
saved output differed by maximum absolute errors from `0.02249` through
`0.05786` (cosine `0.99778` through `0.99875`). Explicit producer/consumer
waits after every BF16 pack and dependent MFMA, plus correcting the declared
next-free VGPR for the use of `v115`, did not remove the variability. The
saved launch composed with the real initial state had maximum absolute error
`0.24807` versus direct FP32 recurrence, including eight elements over
`0.125`. These numbers are diagnostic only; no output from this kernel is
accepted.

## Performance rejection

Median HIP-event timings on otherwise idle GPU2 were:

| Region | Median latency |
|---|---:|
| shipped raw H | `448.465 us` |
| deployed Triton O | `130.681 us` |
| shipped H + Triton O | `556.246 us` |
| raw transition v0, one BF16 projection | `242.883 us` |
| raw transition v1, hi/lo state | `324.724 us` |
| raw transition diagnostic, hi/lo plus explicit waits | `357.204 us` |

The transition consumes 64.2% of the complete current H+O latency before calculating any
affine `H_t`, corrected prefix state, or output. Unlike FlashQLA's head-only
GPU mapping, the shipped CDNA4 H kernel already launches 8 V tiles by 32 heads
for exactly 256 workgroups, matching all 256 MI350X CUs. Sequence splitting
therefore adds transition work rather than exposing idle CUs.

This segment-32 route is rejected for M8192 on both correctness and
performance. It is retained as raw assembly and algorithmic evidence, but it
must not be integrated into SGLang. A future shape with fewer natural V/head
workgroups may re-evaluate the method from this source after independently
eliminating the run-to-run variability.

Artifacts:

- affine/raw determinism result: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T163000Z-gdn-segment-m-vgpr116-gpu2/result.json`;
- H/O split timing: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T133500Z-gdn-h-o-split-timing-gpu2/result.json`;
- reproducible build: `/data/netra/worktrees/netra-kernel-gdn-prefill-gfx950-20260802/build/gfx950-qwen36-gdn-segment-m-seg32-hilo-v6-vgpr116/`;
- raw-source SHA-256: `d01ee686cd0cdda01c86571b20697d20c772e2138c230e6c3ceb23922776dcd7`;
- gfx950 HSACO SHA-256: `674ec48d9bf7be84dcfa3a68787f1798f436cfcc3b436a3bec96a17b985fe2e0`.
