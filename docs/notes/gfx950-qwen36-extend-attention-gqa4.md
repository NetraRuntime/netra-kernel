# Qwen3.6 gfx950 grouped-GQA4 extend attention

The accepted production source is
`kernels/gfx950/attention/verify/qwen36_extend_attention_m16_gqa4_gfx950.s`.
It targets gfx950 explicitly, uses wave64 and a 256-thread workgroup, and
groups four query heads that share one KV head. The HIP runtime bridge performs
module loading and dispatch only.

The live dFlash piecewise-graph ABI is BF16 Q/K/V/O with 32 query heads, eight
KV heads, dimension 128, maximum extension 12, int64 `qo_indptr`, int32
`kv_indptr`, and int64 `kv_indices`. The build script rejects a code object
whose metadata does not declare gfx950.

On the retained real-checkpoint batch-63 capture, the int64-ABI raw replay is
deterministic with max absolute error 0.015625, cosine 0.99999994, no NaN/Inf,
and 206 bitwise BF16 differences among 3,096,576 elements. The original code
object measured a 145.442 us HIP-event median, versus 209.562 us for the
deployed one-wave Triton kernel.

## 64-bit KV-cache addressing correction

Sustained dFlash serving exposed a correctness/performance defect that the
original compact capture could not exercise. The Triton-derived raw assembly
used buffer descriptors with `num_records=0x7ffffffe` for the BF16 KV pools.
Each draft KV slot occupies 2,048 bytes, so physical slots at or above
1,048,576 silently returned zero. With radix cache disabled and cache slots
advancing under repeated c64 workloads, dFlash acceptance collapsed on the
third 320-request cycle even though batch-1 token hashes remained stable.

The accepted correction masks invalid tail lanes, constructs the full 64-bit
byte address for every live KV slot, and uses raw `global_load_dwordx4`
instructions for cached K and V. It remains wave64/gfx950 assembly. Resource
use changes from 137 to 156 VGPRs; the code object still declares 106 SGPRs,
zero scratch, 16,384 bytes of dynamic LDS, and a 256-thread workgroup.

The regression harness now supports `--kv-slot-offset`. With an offset of
1,100,000 (past the old 2 GiB boundary), the repaired raw kernel retained the
same correctness statistics as the ordinary capture. Its HIP-event median was
153.862 us versus 190.342 us for the grouped Triton oracle, 19.2% lower.

Full current-best piecewise-graph dFlash serving on one MI350X measured three
successive 192-request c64 cycles, each after 128 warmups, at 6,039.83,
6,000.84, and 6,142.82 output token/s. Acceptance remained 4.64, 4.63, and
4.63. The defective code object measured 5,768.98 and 5,788.63 token/s before
falling to 2,663.37 token/s with 3.03 accepted tokens on cycle three.

Five exact 210-input/128-output requests after the sustained test retained hash
`8cf5682c0ab5307cb04b6d7292da155ddf14c7936f39fe10e849595e5967ea57`.
GSM8K-200 scored 0.960 with 5,324.25 output token/s. Evidence is under:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T003500Z-gqa4-64bit-isolated-gpu1`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T002000Z-dflash-draft-gqa4-only-stability-gpu1`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T005000Z-dflash-gqa4-64bit-sustained-gpu1`

The integration passed exact repeated token hashes, same-GPU serving A/B, and
GSM8K-200 (0.955 for control and raw). Full serving evidence is recorded in
the netra-server gfx950 notes and under the dated `/data/netra/benchmarks`
artifacts.

Rejected experiments remain in `verify/experiments`: moving scalar spills to
free SGPRs was slower, DPP rescheduling was neutral, and alternate N tiles
changed the reduction result.
