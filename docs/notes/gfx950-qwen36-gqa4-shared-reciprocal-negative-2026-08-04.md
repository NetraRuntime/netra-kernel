# Qwen3.6 gfx950 GQA4 shared-reciprocal negative

## Verdict

Rejected. Replacing the compiler-expanded per-accumulator FP32 divisions in the
shipped GQA4 FP8-KV attention kernel with a shared softmax reciprocal did not
preserve the MFMA lane/register semantics. Even the minimal final-four-output
variant was deterministic but produced 258,072 BF16 mismatches and cosine
0.951343. The promoted production source is restored unchanged.

## Motivation and retained baseline

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- capture: real dFlash verification, batch 63, 3,072 query tokens, GQA4/D128
- KV cache: FP8 E4M3
- shipped raw kernel: 122.740 us median, 26 / 3,096,576 BF16 mismatches,
  max absolute error 0.0078125, cosine 1.0
- counters: 98.941% VALU utilization, 4.759% MFMA utilization, occupancy 1.0002,
  and 0.0141% memory-unit stalled

Disassembly showed 32 scalarized IEEE divide expansions for one online-softmax
denominator. This made reciprocal sharing a plausible VALU-reduction target.

## Variants

| variant | median us | BF16 mismatches | finite max abs | cosine | deterministic | result |
|---|---:|---:|---:|---:|---|---|
| early branch, one Newton refinement | 122.201 | 2,193,325 | n/a | NaN | no | reject |
| shared IEEE scale/fixup | 205.922 | 406,725 | n/a | NaN | no | reject |
| shared IEEE plus explicit issue delay | 156.501 | 2,058,030 | 3.39e38 | NaN | no | reject |
| reference four-output prologue, two refinements, restored packs | 217.542 | 1,869,170 | 12.8125 | 0.594689 | no | reject |
| final four outputs only, two refinements | 220.642 | 258,072 | 12.8125 | 0.951343 | yes | reject |

Later timings had substantial host/GPU variance on GPU 5 and are not suitable
for a speed claim. Correctness independently rejects every variant.

The generated divide chain interleaves the two final PV MFMAs, address setup,
and two BF16 pack operations. Early branches initially skipped or duplicated
some of this scheduling. Restoring those operations removed NaN/Inf output, but
the final-four register-group gate still proved that direct reciprocal reuse was
not numerically equivalent for this layout.

The installed gfx950 assembler also rejects `s_waitcnt_depctr`; that RDNA-style
dependency wait must not be used for CDNA4. An explicit `s_nop` experiment did
not restore correctness.

## Artifacts

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T072500Z-gqa4-shared-rcp-gpu5`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T073500Z-gqa4-shared-ieee-rcp-gpu5`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T075500Z-gqa4-shared-ieee-delay-gpu5`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T082500Z-gqa4-shared-rcp2-packs-gpu5`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T083500Z-gqa4-shared-rcp2-final4-gpu5`

The rejected assembly evolution remains in the
`perf/gfx950-qwen36-gqa4-h2` branch history. Do not merge its intermediate
production-source commits. Only the harness improvements and this negative
record are suitable for `main`.
