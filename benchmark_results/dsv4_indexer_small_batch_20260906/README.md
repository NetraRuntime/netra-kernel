# C4 scorer small-batch follow-up, 2026-09-06

The netra-kernel assembly scorer now selects shorter key tiles and delays
per-wave page reuse until sufficient work is available. The previous policy
jumped from one to four pages at 1024 query-page tasks, producing a large
latency regression at 16 query rows x 4096 C4 keys. The new policy reduces
that case from 10.35 to 5.26 microseconds. Every small/medium shape in the
paired matrix improved relative to the previous assembly.

**Component-qualified improvement; not selected in production SGLang.**
At 4096 C4 keys, 8/16/24/32 query rows (C1–C4 when each request supplies eight
speculative query rows) improve by 9.9%, 49.2%, 45.2%, and 39.3% over the
previous assembly. They still take approximately 1.6%, 11.7%, 14.6%, and
25.7% longer than Gluon. These remaining regressions block a blanket serving
replacement. No new serving-TPS or model-accuracy result is claimed.

## Implementation

The original assembly object is **byte-identical** to the prior tested build
(`original_object_unchanged` in the manifest). It remains selected for large
or long workloads. New assembly variants use 16/32-key tiles, overlapping
loads, independent accumulator sets, packed FP32 postprocessing, one combined
kernel-argument load, and an earlier first-page-table load. A four-wave
variant assigns disjoint page runs to waves for medium workloads. The
original FP32 reduction tree and scale-before-ReLU ordering are preserved.

`Scorer(build_dir)` now defaults to CPU-shape-based automatic selection.
Let `tasks = rows * ceil(width / 64)`:

| Condition, in order | Mode | Pages/wave |
|---|---:|---:|
| rows >= 512, width >= 65536, or tasks >= 65536 | Original 0 | Original 1/4/8 policy |
| tasks <= 128 | Tile16 1 | 1 |
| tasks <= 256 | Tile32 4 | 1 |
| tasks <= 2048 | Paired tiles 5 | 1 |
| tasks <= 8192 | Paired tiles 5 | 2 |
| Otherwise | Four independent waves 6 | 4 |

Modes 2 and 3 remain explicit comparison variants. Explicit page-count
arguments retain the original mode-0 override behavior; they are no longer
silently overridden by the small-work heuristic. Selection reads no GPU
scalars and introduces no shared mutable buffers or extra launches. Caller
stream and device ownership are unchanged. The host symbol becomes
`netra_mqa_launch_v2`; the GPU kernarg ABI remains 76 bytes. Load the matching
runtime, bridge and code object together.

## Correctness

The automatic policy and all six new forced variants each passed **22 shapes**
(154 shape/variant checks), with maximum absolute score difference from Gluon
7.63e-6. The default validator also passed after the final harness update.
Checks include positive/signed weights, one-hot/random FP8 inputs, odd widths,
ragged/zero lengths, invalid page IDs on empty rows, padded input/output rows,
output canaries, three changed-input graph replays, two independent streams,
explicit module close, output row addresses beyond 2/4 GiB, and physical KV
pages beyond 4 GiB. Every shape matched both top-512 key sets and the production
HIP exact-selector's transformed page-index sets. As in the original report,
the FP64 oracle records the small native MFMA arithmetic difference rather
than claiming bitwise identity.

The final 20-workload paired sweep checks scores/top-512 sets before timing.
Each candidate output is reset to NaN so another variant cannot hide missing
stores. The initial four-wave prototype failed canary checks because its
readlane producer/consumer setup lacked delays; adding the delays fixed the
failure, and the final four-wave paths passed all checks. Rejected early
variants were never loaded by a serving worker.

## Paired isolated timings

MI350X/gfx950, ROCm 7.2, one isolated GPU. Each backend runs in the same process
on the same tensors. Five rounds randomize backend order with fixed seeds;
each round measures 20 graph replays with five launches per graph, after
warmup. Each group of eight query rows has a separate KV allocation range.
The previous implementation is commit `d3d301e7b79294461a75c58bbac3b2b5486d764e`
loaded from its retained build. Values below are medians of raw round times,
not serving latency or throughput. Negative reduction denotes a slowdown.

| Query rows | C4 keys | Previous assembly µs | Selected µs | Gluon µs | Latency reduction vs previous |
|---:|---:|---:|---:|---:|---:|
| 1 | 4,096 | 4.83 | 3.58 | 4.53 | 25.9% |
| 2 | 4,096 | 4.89 | 3.85 | 4.54 | 21.3% |
| 4 | 4,096 | 4.95 | 4.18 | 4.57 | 15.6% |
| 8 | 4,096 | 5.19 | 4.67 | 4.60 | 9.9% |
| 16 | 4,096 | 10.35 | 5.26 | 4.71 | 49.2% |
| 24 | 4,096 | 11.16 | 6.12 | 5.34 | 45.2% |
| 32 | 4,096 | 11.21 | 6.81 | 5.42 | 39.3% |
| 64 | 4,096 | 13.48 | 9.20 | 9.47 | 31.7% |
| 128 | 4,096 | 17.67 | 14.41 | 17.13 | 18.5% |
| 256 | 4,096 | 25.46 | 24.50 | 27.46 | 3.8% |
| 1 | 1,024 | 4.71 | 3.55 | 4.42 | 24.7% |
| 8 | 1,024 | 4.90 | 3.85 | 4.55 | 21.3% |
| 128 | 1,024 | 11.16 | 6.71 | 5.96 | 39.8% |
| 1 | 16,384 | 4.91 | 4.12 | 4.52 | 16.0% |
| 8 | 16,384 | 11.27 | 6.82 | 5.44 | 39.5% |
| 128 | 16,384 | 46.79 | 44.07 | 46.69 | 5.8% |
| 1024 | 4,096 | 87.24 | 87.36 | 100.14 | -0.1% |
| 8 | 262,144 | 43.61 | 43.85 | 55.37 | -0.5% |
| 128 | 32,768 | 85.23 | 85.53 | 86.10 | -0.3% |
| 1024 | 262,144 | 5099.39 | 5098.13 | invalid full-pool reference | 0.0% |

The four preserved large/long workloads differ from the prior assembly by
at most 0.6% in these medians. The 1024x4096 and 8x262144 cases retain their
advantages over Gluon. This does not demonstrate sustained C256 throughput.

### Large-pool reference limit

The first full-pool comparison failed at 1024x262144 with a 4.43 GB packed KV
allocation. The Gluon reference uses 32-bit KV buffer offsets. Comparing
against rebased slices with offsets below 2 GiB made **both** the original
and selected assembly pass for the full output and top-512 sets. The final
wide-pool comparison retains absolute page IDs and the >4 GiB pool in both
assembly launches; only the untimed reference is rebased. Its invalid
full-pool Gluon latency is excluded. The default validator skips that timing
and points to the paired sweep instead. This also invalidates treating the
old report's 1024x262144 Gluon timing as a qualified performance comparison.
The supported 8x262144 long-context comparison has a small KV pool and passes.

The failed result is retained in `large_pool_reference_failure.json`; the
corrected result is `paired_selected.json`. This is synthetic component
coverage, not a finding that production's per-layer pool crosses that limit.

## Reproduce

See the [kernel contract and build instructions](../../kernels/gfx950/attention/indexer/README.md).
On isolated gfx950 hardware with the deployment's AITER/SGLang patches:

```sh
bash tools/benchmark/indexer/build.sh /tmp/new-mqa
python tools/benchmark/indexer/validate.py --build /tmp/new-mqa --output /tmp/validation.json
# The baseline runtime and build must come from d3d301e, not the new runtime.
python tools/benchmark/indexer/sweep_small.py --build /tmp/new-mqa \
  --baseline-runtime /tmp/baseline/dsv4_mqa.py --baseline-build /tmp/baseline/build \
  --output /tmp/paired.json
```

Use `--all-variants` for the exploratory sweep. `--mode 0` forces the original
kernel; `--mode 1` through `6` force the new variants; default `--mode -1`
uses automatic selection. `--correctness-only` omits timing runs. The source
and tested binary hashes are in `build_manifest.json`; raw correctness and
paired timing reports accompany this document.

Production was paused for bounded isolated tests and recovery was requested
after final validation. Recovery evidence is recorded in netra-server's
small-batch deployment note. Serving promotion still requires real captured
inputs, multi-device ownership checks, full request/history/long-context
correctness, and the existing 16K-input/4096-output C256 a/b/c gate. The
14K aggregate output-TPS and 300 output-TPS/user goals remain unproven.
