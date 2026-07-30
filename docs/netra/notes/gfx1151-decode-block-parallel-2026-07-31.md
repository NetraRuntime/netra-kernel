# gfx1151 block-parallel MXFP4 decode kernels (2026-07-31)

All measurements in this note are from the AMD Ryzen AI Max+ PRO 395
(`gfx1151`) in the Netra LXC. "Measured" means HIP events, rocprofv3, or the
labeled serving wall clock as stated. Projections toward 30 tok/s are marked
"estimated".

## Outcome

Two raw AMDGCN kernel pairs replace decode paths whose small number of long
running workgroups underused gfx1151:

- fixed N=2048, K=4096 GDN output projection;
- fixed selected-8, N=512, K=2048 routed gate and up projections.

Both split work at MX-block boundaries and use a raw-ASM reduction that
replays the original FP32 accumulation structure. The GDN reduction performs
the same 128 FMAs in order. The routed reduction independently rebuilds the
original two 32-block split accumulators and then adds them, matching the old
atomic result without clearing output buffers.

## Raw kernels

- `kernels/gfx1151/mxfp4/decode/mxfp4_linear_decode_n2048_k4096_block128_gfx1151.s`
- `kernels/gfx1151/mxfp4/decode/mxfp4_linear_decode_n2048_block128_reduce_gfx1151.s`
- `kernels/gfx1151/mxfp4/decode/mxfp4_decode_gate_block64_gfx1151.s`
- `kernels/gfx1151/mxfp4/decode/mxfp4_decode_gate_block64_reduce_gfx1151.s`

The runtime preloads all four modules before capture. Each launch uses the
caller's HIP stream and cached `hipFunction_t` handles. SGLang allocates stable
per-layer workspaces while processing weights; the launch path does not
allocate, load modules, query tensor values, or synchronize.

## Isolated correctness and HIP-event timing

| gfx1151 path | real checkpoint coverage | correctness | baseline median | candidate median | speedup | status |
|---|---:|---|---:|---:|---:|---|
| N2048 K4096 GDN output | all 30 GDN layers | bit-exact BF16 | 325.006 us | 59.664 us | 5.447x | measured, interleaved rotated weights |
| selected-8 gate+up+SiLU | layers 0/10/20/30 | bit-exact FP32 gate/up and BF16 output | 184.582 us | 67.802 us | 2.722x | measured, interleaved rotated weights |

A cache-hot layer-0 check measured 202.400 us versus 34.304 us (5.900x) for
the GDN output pair and 110.006 us versus 41.318 us (2.662x) for routed
gate+up+SiLU on gfx1151. These are measured HIP-event results, not serving
claims.

The four accepted HSACO SHA-256 values are:

- gate block64: `554a00ebeefe1794a836ed09c18bd8012d991c32ab1eb372bcbbe21383f08688`;
- gate block64 reduction: `21504ef32ce83b9b2f9d74057445842148fdd261a40348d7e7df0daa7b8ae2e5`;
- N2048 K4096 block128: `92261574ee51616951703035872bde3030fa2adee2dd4b08d44a8c8c6b3d37cd`;
- N2048 block128 reduction: `355b524f567924f1212f9e96d0f05bba7b61b6595759c5d2ee9c642ba5b27be5`.

Comments-only source cleanup produced identical HSACO hashes. Complete hashes
are also emitted by the build and should be copied into the result manifest.

## rocprofv3 evidence

The current eager trace is
`results/profiles/gfx1151/decode-m1-32-combined-block-candidates-20260731`.
It is a measured gfx1151 rocprofv3 trace with signal handlers disabled:
46,401 launches, 1,118,447 us trace wall time, 1,010,714 us summed GPU kernel
time, and 108,877 us of positive launch gaps.

Selected measured rows after integration:

| gfx1151 kernel | calls | mean GPU time | total GPU time | trace wall share | status |
|---|---:|---:|---:|---:|---|
| GDN N2048 block compute | 798 | 24.632 us | 19.656 ms | 1.757% | measured rocprofv3 |
| GDN exact-order reduction | 798 | 36.688 us | 29.277 ms | 2.618% | measured rocprofv3 |
| routed block64 compute | 2,128 | 36.603 us | 77.892 ms | 6.964% | measured rocprofv3 |
| routed split-preserving reduction | 2,128 | 11.540 us | 24.556 ms | 2.196% | measured rocprofv3 |

The new trace ranks the remaining decode costs as BF16 LM head, BF16 QKV,
padded N12800 K2048 QKVZ/BA, rocBLAS BF16 projections, shared expert, routed
block64, and routed down. This ranking, rather than individual latency alone,
sets the next work order.

## Serving A/B

All serving rows below are uncached, batch 1, graph disabled, dFlash disabled,
and measured on gfx1151 with host monotonic wall time. Candidate and baseline
runs used identical seeds and produced identical deterministic token arrays.

| input/output | variant | cached | server E2E | host E2E | decode indication | peak VRAM | status |
|---|---|---:|---:|---:|---:|---:|---|
| 1/32 | old two paths | 0 | 1,649.419 ms | 1,662.516 ms | 18.794 tok/s (31/E2E) | 80,637,263,872 B | measured gfx1151 |
| 1/32 | GDN pair only | 0 | 1,407.339 ms | 1,420.740 ms | 22.027 tok/s (31/E2E) | 76,884,045,824 B | measured gfx1151 |
| 1/32 | both block pairs | 0 | 1,311.222 ms | 1,324.512 ms | 23.642 tok/s (31/E2E) | 77,614,411,776 B | measured gfx1151 |
| 210/128 | old two paths | 0 | 6,974.074 ms | 6,987.465 ms | 19.58 tok/s SGLang steady log | 78,037,295,104 B | measured gfx1151 |
| 210/128 | both block pairs | 0 | 5,658.705 ms | 5,672.702 ms | 24.55 tok/s SGLang steady log | 78,153,928,704 B | measured gfx1151 |

For exact 210/128, the measured gfx1151 improvement is 1.23245x and 18.861%
lower server E2E latency. The output IDs and output-text SHA-256 are identical.
The paired peak-VRAM delta is about +111 MiB; sysfs peak values include the
whole APU memory accounting domain and therefore are not a precise workspace
allocation measurement.

## Full decode graph gate

`results/profiles/gfx1151/combined-block-candidates-fullgraph-b1-1in-32out-20260731`
records a successful measured gfx1151 full-graph capture and replay for tiers
1/2/4/8/12/16. Capture took 3.23 s and 0.23 GB according to SGLang. The batch-1
request completed with 32 output tokens and request status zero. The trace
includes construction and profiler overhead, so its 19.36 tok/s host batch
rate is not used as an unprofiled replay-performance claim.

## Rejected fusion

The existing raw gate+up fused experiment was repaired to consume global
expert IDs and tested with real selected layer-0 weights. It was bit-exact but
measured 123.191 us versus 110.027 us for two clears, two gate launches, and
SiLU: 0.893x, or 11.97% slower on gfx1151. It remains rejected. The block64
pair succeeds because it increases available waves while preserving narrow
register state; it does not combine both weight streams into one high-pressure
kernel.

## 30 tok/s assessment

The current measured steady eager result is 24.55 tok/s on gfx1151. Reaching
30 tok/s requires reducing steady decode from about 40.73 ms/token to 33.33
ms/token, a further 18.2% latency reduction. This is possible but remains an
estimate, not a measured result. The measured trace exposes enough addressable
cost in padded QKVZ/BA (about 5.3 ms/token), BF16 QKV (about 5.9 ms/token),
launch gaps (about 4 ms/token), and rocBLAS projections. The next candidate is
an exact-order block-parallel N12800 K2048 QKVZ/BA specialization, followed by
unprofiled graph replay and BF16 QKV work.
