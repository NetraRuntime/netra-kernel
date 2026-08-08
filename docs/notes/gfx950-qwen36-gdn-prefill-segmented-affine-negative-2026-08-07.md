# Qwen3.6 gfx950 segmented GDN prefill affine correction negative

## Verdict

Rejected. Splitting the exact M=8192 prefill into eight independent T=1024
raw gfx950 fused H/O segments and correcting their initial states with a scalar
prefix is not mathematically valid for Qwen3.6 GDN.

The control path (accepted raw M8192 H plus Triton chunk output) is bit-exact
against the retained real-checkpoint capture. The segmented construction fails
both the complete output and final recurrent-state gates.

## Exact workload

- GPU: AMD Instinct MI350X
- target: `gfx950:sramecc+:xnack-`, wave64
- checkpoint: Qwen3.6-35B-A3B FP8 E4M3, 128x128 weight blocks
- total tokens: 8192
- proposed decomposition: 8 segments x 1024 tokens
- heads/query heads: 32/16
- key/value dimensions: 128/128
- recurrence chunk: 64 tokens
- local compute: `qwen36_gdn_fused_h_o_n16_t1024_bv128_gfx950`

Artifact:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T121000Z-gdn-segmented-m8192-gpu1/prototype.json`

## Correctness

| comparison | max abs | cosine | tolerance failures | result |
|---|---:|---:|---:|---|
| raw H + Triton O vs captured output | 0 | 1.0 | 0 | pass, bit-exact |
| raw H + Triton O vs captured final state | 0 | 1.0 | 0 | pass, bit-exact |
| segmented output vs control | 2.57520 | 0.955935 | 806,773 | fail |
| segmented final state vs control | 60.5 | 0.847611 | 1,204 | fail |

The first segment passes the declared tolerance. Error begins at the second
segment, which isolates the failure to propagation of the preceding segment's
state rather than the local T=1024 kernel.

## Root cause

The attempted prefix assumed a scalar affine transition,

`S_(j+1) = a_j S_j + B_j`.

That assumption does not hold. Qwen3.6 GDN uses

`v_new = v - W H`

inside the delta update. Consequently, a chunk or segment applies a full
K-by-K linear operator to the incoming recurrent state. A scalar accumulated
gate cannot reconstruct the state presented to later segments.

A correct parallel scheme must retain or compose the complete transition
operator, or use a two-stage method that first computes exact boundary states
and then computes outputs. The rejected scalar-prefix topology must not be
promoted or used as the basis for a hand-written production kernel.
