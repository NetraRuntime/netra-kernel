# gfx950 Qwen GDN state-pool capacity fix

Date: 2026-08-03

Target: one AMD Instinct MI350X (`gfx950`, wave64), Qwen3.6-35B-A3B FP8
E4M3 128x128 block weights, FP8 E4M3 KV cache, dFlash M=12.

## Root cause

The shared raw M=12 verification/state-replay assembly clamped initial,
destination, and tracking state indices to slot 64. That bound came from the
original B64 isolated harness, but serving configures a substantially larger
recurrent-state pool. The first 64-request pass could be correct; later or
tracking slots above 64 all aliased slot 64.

This produced a characteristic false performance result: the first c64
1,024/1,024 pass ran at roughly 5-7K output tok/s, while later passes reported
15-16K tok/s because outputs had collapsed into highly compressible prompt
copying. The historical 15,906 tok/s result is therefore invalid and must not
be reported as optimized throughput.

## Assembly and ABI repair

Kernarg byte 84, previously padding after `stride_v`, now carries the runtime
`state_capacity`. The raw gfx950 assembly loads it once, subtracts one, and
clamps all live state indices to that runtime bound. Both bridges pass the
actual tensor capacity. The dual replay pointers retain their aligned offsets
at bytes 88 and 96, so the kernarg remains 88 bytes for single-destination
replay/verification and 104 bytes for dual replay.

The compute implementation remains raw AMDGCN in
`qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950.s`; FP8 weight and KV
formats are unchanged.

## Correctness evidence

The real-checkpoint high-slot gate uses slots 65-128 and compares against the
Triton recurrence oracle. It passed bit-exactly for accepted-length patterns
zero, one, ramp, and twelve; wavegroup sizes 1, 4, and 8; and HIP graph replay.
Every comparison covered 67,633,152 BF16 state elements with zero mismatches.

Artifact:

`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T034000Z-dflash-state-leak-isolation/capacity-fix/real-b64-high-indices.json`

The target-verifier path was independently gated on the same high-index
condition with the real captured checkpoint state. Its raw output matched both
the Triton K0 oracle and the captured full-cache output bit-exactly across
3,145,728 BF16 elements. Median HIP-event time was 120.781 us for the raw
gfx950 kernel versus 205.562 us for Triton, a 1.702x isolated speedup.

Artifact:

`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T034000Z-dflash-state-leak-isolation/capacity-fix/target-verify-real-b64-high-indices.json`

Three consecutive c64 1,024-input/1,024-output serving passes with both fixed
raw kernels retained normal output entropy:

| pass | output tok/s | accept length | gzip bytes |
|---:|---:|---:|---:|
| 1 | 6,088.41 | 3.96 | 82,926 |
| 2 | 6,222.79 | 3.96 | 81,473 |
| 3 | 5,623.37 | 3.95 | 79,425 |

The corresponding corrupted passes compressed to only 10-18 KB.

Full GSM8K (`enable_thinking=false`, temperature 0, 512 max tokens, 64 client
threads) scored 1,250/1,314 = 0.9512937595, exactly matching the established
coherent baseline. Wall time was 75.9148 seconds and output throughput was
2,668.54 tok/s.

Serving and GSM8K artifacts:

`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T034000Z-dflash-state-leak-isolation/`

## Decision

Accept the dynamic-capacity assembly/ABI fix. Reject every previous warm-run
throughput result whose output entropy collapsed after state-slot reuse.
