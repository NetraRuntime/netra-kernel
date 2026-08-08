# gfx950 fused FMoE: chain measurement and late-A waitcnt split

Date: 2026-08-08 UTC

Status: **validated; retained as the pipelined variant. 282.8 us total on
the exact M=1024 capture, 25.1% behind AITER (was 60% at the 2026-08-07
baseline).**

## Chain measurement

A grid-y override in the harness measured the true per-workgroup serial
chain: one workgroup takes 206.9 us, 146 blocks take 245.0, 256 take 254.0,
and 291 take 310.2. The chain itself dominates; the 291st-block tail round
adds only ~50 us. Scheduling alone cannot reach AITER; the chain had to
shrink.

## Late-A waitcnt split

Per K iteration the head executed `s_waitcnt vmcnt(0)` before the LDS slab
writes, serializing on the A fragments and scales that had been prefetched
only a few hundred nanoseconds earlier, although the writes need only the
weight staging. Because vmcnt completes in order, the wait splits exactly:

- loop head waits `vmcnt(6)` in W13 (`vmcnt(4)` in W2), draining everything
  except the newest A loads; fully padded waves branch to `vmcnt(0)` since
  they never issue A;
- the A drain moves to the pre-MFMA wait as `vmcnt(8)` / `vmcnt(16)`
  (everything except the newest prefetched weight slab), overlapped with
  the barrier and B-fragment LDS reads;
- on the final K iteration no next slab is in flight, so the pre-MFMA wait
  must branch to `vmcnt(0)`; missing that produced 49/50 nondeterministic
  corruptions before the fix and is the sharp edge to remember.

## Results (exact M=1024 capture, 100 iterations)

| Variant | Fused | Reduce | Chain (1 WG) | Gate |
|---|---:|---:|---:|---|
| 2026-08-07 baseline | 346.9 | 15.0 | 255.5 | pass |
| weight pipeline (prior note) | 308.7 | 15.0 | 207.2 | pass |
| + late-A waits (retained) | 267.3 | 15.3 | 185.6 | pass, bit-identical, 0/100 |
| split-K x2 + late-A | 269.9 | 26.4 | - | pass; now strictly dominated |
| AITER 64x256 | 226.0 | - | - | reference |

W13+quant of the chain is now 128.1 us; W2 plus stores about 57.5 us.
Split-K x2 lost its fused advantage once the chain shortened and keeps its
+11 us reducer tax; it is retained only as the deterministic grid-splitting
building block.

## Next lever

The remaining chain cost is the LDS round trip and two barriers per K
iteration. The candidate rewrite streams B fragments directly from global
memory per wave (four waves per CU read the same lines within a short
window, so L2 serves the 4x amplification and HBM traffic stays flat),
which removes ds_write/ds_read/barriers from the K loop entirely and turns
it into a deep-prefetch global-to-MFMA stream, the organization the AITER
kernel already uses. Estimated chain after the rewrite: ~110-120 us, total
near or below the AITER reference.

## 2026-08-08 outcome correction

That estimate and the description of AITER's organization were disproved by
the follow-up experiment.  The barrier-free direct-B variant was numerically
identical, but increased the exact full-grid fused time from 267.3 to 347.0 us.
Matched counters showed that removing 60% of LDS instructions added 8.4% TCC
read sectors, 7.7% VMEM instructions, and 15.9% `SQ_WAIT_ANY`.  L2 absorbed
most, but not all, of the four-wave request amplification.

The exact deployed AITER object was then disassembled.  It uses cooperative
`buffer_load_dwordx4 ... lds`, barriers, and LDS reads; it does not stream a
private copy of B through each wave's VGPRs.  The retained negative and full
counter table are in `gfx950-qwen36-fmoe-direct-b-negative.md`.  A successor
must follow the measured global-to-LDS/deep-accumulation organization or target
a different hotspot; the per-wave direct-B topology should not be tuned
further.
