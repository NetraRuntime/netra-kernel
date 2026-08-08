# gfx950 Qwen GDN verification decay/dot schedule negative

## Verdict

Rejected. Interleaving the recurrent-state decay pairs with the four independent
packed K-dot chains preserved the deployed arithmetic and code-object resources,
but did not produce a material HIP-event improvement.

## Contract

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- model: Qwen3.6-35B-A3B-FP8
- weights: FP8 E4M3 with 128x128 blocks, unchanged
- real checkpoint capture: target verification B=64, M=768, 12 positions
- GDN: 32 value heads, K=128, V=128, BV=16
- K0 verification: live FP32 recurrence, no rollback snapshots
- timing: 1,000 HIP-event iterations on HIP device 6
- artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T135705Z-gdn-verify-schedule-gpu6`

The existing Qwen serving container on GPU 2 remained healthy and was not
restarted. No training or download process was present in the session audit.

## Change

Variant 17 first issued all 16 packed FP32 state-decay multiplies, then issued
four interleaved packed K-dot chains. Experimental variant 18 moved each group
of four independent state-decay pairs immediately before the corresponding dot
stage. It retained the same per-element multiplication and FMA order; only the
instruction schedule changed.

Both wave4 code objects retain:

- 80 VGPR and 40 SGPR
- 2,048 bytes LDS
- zero scratch
- 24 `v_pk_mul_f32`, 40 `v_pk_fma_f32`, and 40 `v_add_f32`
- one barrier per recurrent position

## Results

| implementation | mean us | median us | p90 us |
|---|---:|---:|---:|
| deployed variant 17 | 101.337 | 100.801 | 103.121 |
| decay/dot schedule variant 18 | 101.403 | 100.721 | 103.321 |

The candidate median was 0.079% faster, while mean was 0.065% slower and p90
was 0.194% slower. This is measurement noise, not a serving candidate.

The candidate produced the same oracle signature as the control: 163 of
3,145,728 BF16 values differ from the Triton K0 oracle, maximum absolute error
0.0009765625 and mean absolute error 3.17e-10. This is the already accepted
variant-17 numerical contract; the schedule introduced no additional error.

## Decision

Keep variant 18 only as assembly scheduling evidence and do not enable it in the
runtime. The measured trace assigns 9.35% of GPU time to this raw verifier, but
this local schedule cannot move end-to-end throughput. Further work should target
an architectural change or the larger 26.6% verification-FMoE region.
