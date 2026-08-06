# Qwen3.6 gfx950 exact M128 prefill-attention specialization negative

## Verdict

Rejected. The hand-specialized raw gfx950 schedule is correct for all four
prefix lengths in the exact 32K prefill, but its summed HIP-event time is 3.89%
slower than the deployed in-process Triton `M128/N128/W8` control. It is kept
under `experiments/`; it is not enabled by the runtime.

This experiment also found and fixed a correctness-harness defect: a raw kernel
that wrote nothing could inherit the preceding variant's output and falsely
pass. The harness now poisons output with NaNs before two independent launches,
counts unwritten elements, and includes that count in the deterministic gate.

## Exact contract

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- model: Qwen3.6-35B-A3B, FP8 E4M3 checkpoint; no format conversion
- query/extension: one sequence, M=8192, 16 query heads, D=256, BF16
- paged prefix: GQA8, two KV heads, D=256, native FP8 E4M3
- measured prefix lengths: 0, 8192, 16384, 24576
- grid: `[1, 16, 64]`
- workgroup: 512 threads / eight waves
- dynamic LDS: 65,536 bytes
- timing: HIP events, 3 warmups and 10 retained repetitions
- artifact root: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260806T185310Z-prefill-m128-raw-gpu1`

## Design

The raw source starts from the exact deployed gfx950 instruction schedule and
specializes two generic mappings for the fixed Qwen contract:

1. Replace signed `cur_head / kv_group_num` division with `cur_head >> 3`.
2. Replace the single-sequence `qo_indptr` loads and pointer arithmetic with the
   exact `[0, 8192]` bounds.

The prefix `kv_indptr` remains dynamic, so one code object covers all four
segments of the 32K prompt. This is an experimental hand-specialization of the
deployed schedule, not a claimed from-scratch replacement.

## Code object

- target: `amdgcn-amd-amdhsa--gfx950`
- wavefront: 64
- VGPR: 256
- SGPR: 106
- private segment: 96 bytes
- maximum workgroup: 512
- runtime dynamic LDS: 65,536 bytes
- static instructions: 128 BF16 MFMA, 32 FP8 MFMA, 15 barriers
- HSACO SHA-256: `0452bdef05b38c4ad3c0bfcd039141aad56efd02199d8ab4d610bc714709252f`

## Results

| prefix tokens | Triton control median us | raw specialized median us | raw delta | max abs | cosine | unwritten |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1524.858 | 1580.897 | +3.68% | 0.000244141 | 0.999999821 | 0 |
| 8192 | 2849.172 | 2946.613 | +3.42% | 0.000030518 | 0.999996006 | 0 |
| 16384 | 4167.506 | 4287.729 | +2.88% | 0.000015259 | 0.999997079 | 0 |
| 24576 | 5402.641 | 5671.223 | +4.97% | 0.000015259 | 0.999997675 | 0 |
| sum | 13944.176 | 14486.461 | +3.89% | - | - | 0 |

All raw results were deterministic across two poisoned-output launches. The
unmodified deployed code object launched through the same HIP module bridge was
also 3.84% slower in aggregate than its in-process Triton controls. The simple
prologue specialization is therefore effectively neutral within the direct
module path and does not overcome that path's 2-5% dispatch/runtime penalty.

## Harness false-positive and rejection rationale

The first replay passed an `int32` `qo_indptr` to the deployed ABI, which expects
`int64`. The kernel skipped work, but the old harness compared stale output from
the previous Triton variant and reported a false pass. Converting the ABI input
to `int64` exposed the no-op. Poisoning output before each independent launch
makes this class of failure observable and is retained as a permanent harness
fix.

Prologue work is amortized by the main loop. The remaining object still carries
256 VGPRs, a 96-byte private segment, 15 barriers, and the full repeated prefix
traversal. A viable successor must change main-body liveness, LDS/barrier use,
AGPR/VGPR ownership, or fuse work through the native runtime bridge. Further
fixed-index prologue tuning is not justified by these results.
