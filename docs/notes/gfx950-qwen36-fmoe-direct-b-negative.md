# gfx950 Qwen3.6 FMoE barrier-free direct-B negative

Date: 2026-08-08 UTC

Status: **rejected; correct, but 29.8% slower than the retained raw W13
schedule and 53.6% slower than deployed AITER. Not integrated.**

## Contract and implementation

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- Qwen weights: FP8 E4M3, 128x128 block scales
- real-checkpoint verification shape: M=1024, hidden=2048,
  intermediate=512, top-k=9
- sorted fixture: 18,624 valid IDs, 291 M64 blocks
- workgroup: 256 threads / four waves; grid: 291 workgroups
- code object: 224 VGPRs, 90 SGPRs, 64 KiB LDS, zero scratch

The candidate removes the W13 weight `ds_write`, `ds_read`, and both barriers.
Each wave instead loads its own B fragments with `global_load_dwordx4`. It
pipelines half 1, the next iteration's half 0, and the six A/scale loads using
newest-N `vmcnt` waits. W2 is unchanged, so the experiment isolates the
proposed W13 organization.

## Correctness and HIP-event timing

The candidate preserves the retained result exactly: structural and AITER
mismatch counts, cosine values, and per-iteration output are unchanged, with
zero nondeterministic iterations in 100 repeats.

| implementation | fused median | reducer | total | gate |
|---|---:|---:|---:|---|
| retained raw late-A | 267.303 us | 15.320 us | 282.763 us | pass |
| direct-B, conservative waits | 347.983 us | 15.280 us | 363.363 us | pass |
| direct-B, pipelined waits | 347.045 us | 15.160 us | 362.264 us | pass |
| deployed AITER 64x256 | 226.0 us | fused | 226.0 us | reference |

Pipelining changes the result by less than 1 us. The exact full grid is
29.8% slower in the fused stage and 28.1% slower end to end than late-A. A
single-workgroup diagnostic improves from the documented 185.6 us chain to
180.1 us, proving that the local barrier removal works but does not transfer
to the occupied grid. The W13-only stage rises from 180.782 to 241.822 us at
the real grid.

## Matched gfx950 counters

Six measured dispatches per counter used the identical real-checkpoint
harness. Values are medians for the fused symbol.

| counter | retained late-A | direct-B | change |
|---|---:|---:|---:|
| `SQ_INSTS_LDS` | 4,336,800 | 1,737,888 | -59.93% |
| `SQ_INSTS_VMEM` | 2,798,268 | 3,013,308 | +7.68% |
| `SQ_WAIT_ANY` | 71,892,508 | 83,328,020 | +15.91% |
| `TCC_READ_SECTORS_sum` | 34,637,508 | 37,561,380 | +8.44% |
| `TCC_HIT_sum` | 1,841,951 | 2,456,549 | +33.37% |
| `TCC_MISS_sum` | 8,138,577 | 8,224,863 | +1.06% |
| profiled duration | 272.819 us | 349.799 us | +28.22% |

L2 does suppress most of the nominal four-wave amplification, but the extra
cache requests, VMEM issue, and wait pressure are still large enough to erase
the benefit of deleting the LDS round trip.

## AITER disassembly correction

Disassembly of the exact deployed `aiter_fmoe_64x256.co` contradicts the
earlier design premise. It contains 384 FP8 MFMAs, 80 `ds_read_b128`, 64
`ds_write_b64`, and 23 barriers, and its weight path uses
`buffer_load_dwordx4 ... lds`. Metadata reports 512 VGPRs, 102 SGPRs, 64 KiB
LDS, wave64, and zero scratch. AITER therefore uses cooperative global-to-LDS
transfer plus much deeper accumulation; it is not a per-wave direct-global B
stream.

## Decision

Do not integrate this kernel, extend it to W2, or retune it at M=768. The
exact M=1024 acceptance rule already fails. Preserve the source as a measured
negative. The next credible FMoE design is a real global-to-LDS transfer
combined with deeper accumulator ownership; otherwise move to a less mature
measured hotspot such as graph-static GDN copy removal and dual-destination
state replay.

Artifacts:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260808T193000Z-fmoe-directb-w13-gpu1`.
