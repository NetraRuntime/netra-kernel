# gfx1151 N64 attention 224-VGPR experiment — rejected (2026-07-30)

Status: **rejected**. All correctness, HIP-event, and rocprofv3 results are measured on gfx1151 (AMD Ryzen AI Max+ PRO 395); no performance value is estimated. Production remains `extend_attention_wmma_n64_gfx1151`.

## Ranked motivation

The latest exact 32,768-input/+1-output uncached, graph-disabled, dFlash-disabled trace ranks attention first at about 5,347 ms over 40 launches. Production allocates 248 VGPRs, 128 SGPRs, 64 KiB LDS, no scratch, and has low measured occupancy. This experiment tests proposal #4 from the attention ledger directly: whether lowering N64 VGPR allocation creates a residency or runtime benefit.

## Raw ASM design

The candidate changes only physical registers and preserves the algorithm, instruction order, K/V layout, online softmax, and graph-safe ABI:

- the last 16 batch-load registers move from `v231:v246` into dead `v24:v31` and `v56:v63`;
- alternate K/V LDS fragments move from `v225:v232` to `v56:v63`;
- QK, softmax, P-store, PV, and output-address temporaries reuse dead `v0:v13` ranges at their non-overlapping phases;
- all encoded vector registers are below v224;
- workgroup remains 512 threads and LDS remains 65,536 bytes.

The final raw candidate is `scripts/rocm/kernels/gfx1151/attention/experiments/extend_attention_wmma_n64_group4_qpipe_kvbatch16_lowvgpr_gfx1151.s`. It is retained only as a measured experiment.

## Correctness

The final candidate is bit-exact to production for T=8192 at every actual prefix tier tested:

| Prefix | Bit equal | Max abs | Mean abs |
|---:|---|---:|---:|
| 0 | yes | 0 | 0 |
| 8,192 | yes | 0 | 0 |
| 16,384 | yes | 0 | 0 |
| 24,576 | yes | 0 | 0 |

Two intermediate aliasing defects were found before measurement: one Q pointer overlapped its `v8:v11` load destination, and stale reduction macro calls still encoded v225. A later P-address lifetime collision caused non-bit-exact output. All were corrected before the final correctness and performance runs; no incorrect timing is used below.

## Measured HIP-event result

The comparator alternates A/B then B/A and makes both timed kernels write the identical output allocation. This is required on the unified-memory APU: separate 64 MiB output allocations can move results by several percent and are not a fair physical-memory comparison.

31 samples per tier, five warmups:

| Prefix | Production median | 224-VGPR median | Speedup |
|---:|---:|---:|---:|
| 0 | 34.699299 ms | 34.722313 ms | 0.999337x |
| 8,192 | 99.925522 ms | 99.909248 ms | 1.000163x |
| 16,384 | 166.659821 ms | 167.073776 ms | 0.997522x |
| 24,576 | 233.741119 ms | 234.564163 ms | 0.996491x |
| four-tier sum | 535.025761 ms | 536.269501 ms | **0.997681x** |

The aggregate is a measured 0.232% regression on gfx1151.

## rocprofv3 resources and occupancy

rocprofv3 used one counter per process with signal handlers disabled, avoiding the known signal-6 loop failure.

| Metric | Production | Candidate |
|---|---:|---:|
| allocated VGPR | 248 | 224 |
| allocated SGPR | 128 | 128 |
| LDS | 65,536 bytes | 65,536 bytes |
| scratch | 0 | 0 |
| waves | 8,192 | 8,192 |
| OccupancyPercent | 10.021645% | 9.989247% |
| MeanOccupancyPerActiveCU | 6.537445 | 6.503330 |

The intended VGPR reduction is real, but it creates no occupancy tier change. The 64 KiB LDS allocation is still the residency limiter. `SQ_WAVE_CYCLES` saturated at 85,899,345,900 for both variants in this metric pass and is not used as a comparative claim.

## Decision

Reject the standalone N64 register renumbering. It adds address-move instructions and complexity without a residency step, and the long-prefix tiers regress. No production integration, full-request trace, or serving benchmark is warranted after this isolated failure.

The useful retained result is architectural: a future near/below-32-KiB LDS design can reuse this proven 224-VGPR mapping as one component. VGPR reduction and LDS reduction must be co-designed; doing #4 alone does not help gfx1151.

## Reproduction

Run only inside Netra:

```bash
cd /root/netra-mxfp4-gfx1151
scripts/rocm/tools/build/build_extend_attention_lowvgpr_experiment.sh
/root/sglvenv1151/bin/python \
  scripts/rocm/tools/benchmark/benchmark_extend_attention_variants_shared_output.py \
  --baseline-library build/experiments/attention-lowvgpr/libextend_attention_baseline.so \
  --baseline-hsaco build/experiments/attention-lowvgpr/extend_attention_wmma_n64_gfx1151.hsaco \
  --candidate-library build/experiments/attention-lowvgpr/libextend_attention_candidate.so \
  --candidate-hsaco build/experiments/attention-lowvgpr/extend_attention_wmma_n64_group4_qpipe_kvbatch16_lowvgpr_gfx1151.hsaco \
  --tokens 8192 --prefix 0 8192 16384 24576 \
  --warmup 5 --repetitions 31 --interleaved
scripts/rocm/tools/profiling/profile_extend_attention_lowvgpr_counters.sh
```

Machine-readable HIP-event and rocprofv3 summaries, plus before/after disassemblies and their diff, are adjacent under `docs/netra/notes/`.
