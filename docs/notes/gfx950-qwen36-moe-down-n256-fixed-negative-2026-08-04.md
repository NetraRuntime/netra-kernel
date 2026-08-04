# Qwen3.6 gfx950 fixed-order M64xN256 MoE-down negatives

## Verdict

Rejected. Both raw gfx950 N256 W2 variants preserve the correctness-passing
fixed-order FP32 route reducer, but neither beats the deployed AITER one-stage
FMoE or the existing raw N128 W2 kernel.

The 64 KiB variant halves the N workgroup count and reuses every route
activation across N256. Its W2 kernel is nevertheless 3.28% slower than the
matched N128 control. A 32 KiB split-LDS variant restores two-workgroup/CU
residency, but the second LDS synchronization makes W2 10.04% slower than
N128.

## Exact real-checkpoint method

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- checkpoint format: FP8 E4M3, 128x128 block scales
- rows: 768
- hidden: 2,048
- expert intermediate: 512
- top-k: 9
- valid sorted IDs: 15,872 / 248 M64 blocks
- launch: 8 N256 workgroups per sorted M64 block, 256 threads
- timing: HIP events, 100 retained iterations
- artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T060000Z-moe-down-n256-fixed-gpu6`

The Qwen server remained healthy and idle on GPU 6. Production training and
verification containers were not changed or interrupted.

## Designs

### 64 KiB one-resident-workgroup schedule

One workgroup owns M64xN256. It loads one route activation fragment and its
four scales per K128, stages sixteen N16 weight tiles in a 32 KiB LDS slab, and
retains 64 FP32 accumulators per lane. Two 32 KiB slabs ping-pong across K.

Emitted metadata: wave64, 256 threads, 64 KiB LDS, 172 VGPR, 60 SGPR, zero
scratch. Static disassembly contains 16 FP8 MFMAs, 64 FP32 global stores, and
one barrier in the unrolled loop body.

### 32 KiB split-LDS schedule

The second variant stages the two N128 halves separately in lower and upper
16 KiB LDS. This permits two workgroups/CU but adds a second barrier per K128.

Emitted metadata: wave64, 256 threads, 32 KiB LDS, 172 VGPR, 60 SGPR, zero
scratch. Static disassembly contains 16 FP8 MFMAs, 64 FP32 global stores, and
two barriers in the loop body.

## Results

| implementation | W2 median us | W2 p90 us | complete median us | result |
|---|---:|---:|---:|---|
| existing raw N128 matched control | 61.5405 | 65.7329 | 187.521 | raw control |
| raw N256 64 KiB | 63.5605 | 66.9240 | 186.242 | rejected |
| raw N256 split-LDS 32 KiB | 67.7200 | 71.5410 | 191.821 | rejected |
| deployed AITER 64x256 one-stage, retained | — | — | 182.602 | production winner |

Both candidates pass the predeclared full-output gate:

- structural max absolute error: 0.00084421
- structural cosine: 0.999973
- AITER max absolute error: 0.000976562
- AITER cosine: 0.999965

The 64 KiB candidate's complete raw pipeline remains 1.99% slower than the
retained AITER result. The split-LDS candidate remains 5.05% slower. The
apparent 1.28 us complete-pipeline advantage of 64 KiB N256 over the
same-epoch raw N128 control is upstream-stage timing jitter: the isolated W2
kernel itself is slower, and both raw pipelines lose to AITER.

## Conclusion

Activation reuse was not the limiting factor in the accepted N128 W2 path.
N256 loses either occupancy with 64 KiB LDS or synchronization efficiency with
32 KiB LDS. Do not integrate either variant into SGLang or spend another
serving A/B on this topology. Further verification-MoE work requires a
materially different persistent or multi-phase design; the next optimization
should move to a less-mature measured hotspot.

