# C1–C4 scorer regression fixed, 2026-09-06

The netra-kernel AMDGCN indexer now reaches Gluon parity or better at C1–C4.
The final aligned-output comparison reduces latency by 2.9%, 11.1%, 13.7%
and 22.2% from the previous assembly. C2 is effectively parity with Gluon:
its measured advantage is under 1%, so this is not evidence of a substantial
C2 speedup over Gluon. All four improve on the previous assembly in both
final comparison runs and both tested output row layouts.

**Component-qualified; not selected in production SGLang.** These are indexer
kernel timings, not output tokens/second. C1–C4 here means 8/16/24/32 query rows
when each request contributes eight speculative queries, at 4096 compressed
C4 keys (16K-token input). The 300 output-TPS/user and 14K aggregate serving
objectives still require end-to-end qualification.

## Final C1–C4 comparison

MI350X/gfx950, ROCm 7.2, one isolated GPU. Same tensors and process for all
backends; each request group has a separate physical KV range. Five rounds
randomize backend order. Each round times 20 graph replays, with five launches
per graph after warmup. Values are median microseconds. Baseline assembly is
`84c4ceed7681424443587a3e669831c2cd4b12b3` from its retained runtime and build.
These are repeated kernel timings, not statistical confidence intervals.

| Concurrency mapping | Query rows | Previous µs | Selected µs | Gluon µs | Reduction vs previous | Reduction vs Gluon |
|---|---:|---:|---:|---:|---:|---:|
| C1 | 8 | 4.659 | 4.526 | 4.596 | 2.9% | 1.5% |
| C2 | 16 | 5.278 | 4.695 | 4.737 | 11.0% | 0.9% |
| C3 | 24 | 6.014 | 5.193 | 5.322 | 13.7% | 2.4% |
| C4 | 32 | 6.719 | 5.226 | 5.400 | 22.2% | 3.2% |

Source: `indexer_c14_r46/job-07.result.json`, aligned output. The padded-output
rows in that same 36-workload sweep also pass and put all four ahead of Gluon.
The independent 20-workload final comparison gives C1–C4 4.562, 4.738, 5.228
and 5.292 µs, versus Gluon 4.612, 4.754, 5.352 and 5.381 µs. C2 remains a
small margin in both runs. The 1K- and 16K-key C1–C4 shapes are also included
in the 36-workload sweep; context length is not inferred from a single shape.

## Implementation

Small paths replace two `ds_bpermute` exchanges and their waits with native
gfx950 16/32-lane swaps. Both registers are inputs and outputs of these swap
instructions. Copying each value first, then adding complementary outputs,
preserves the original head-reduction order.

Modes 10 and 13 use four independent waves with one cooperative Q load per
workgroup. Q is staged through 9216 bytes of LDS with a padded 144-byte head
pitch. This removes fourfold redundant Q loads. All waves reach the shared
barrier before inactive waves exit; zero-length rows still never read their
page table or KV. Mode 13 prefetches the later key tiles into separate banks
while the early tiles compute, hiding their load latency at small grids.
Larger grids use mode 10's lower register footprint.

The default CPU-shape policy selects these paths without GPU scalar reads,
tensor copies, additional launches, host synchronization or mutable shared
buffers. The selected paths retain FP32 scale/ReLU/weight order and the
original head reduction tree. HIP code still only owns and launches the
assembly module. GPU kernargs remain 76 bytes and the host ABI remains
`netra_mqa_launch_v2`.

The original mode-0 assembly object is byte-identical to the previous build;
its large/long schedule is unchanged. See the [contract and complete schedule](../../kernels/gfx950/attention/indexer/README.md).

## Correctness and scope

The final automatic policy, forced shared-Q mode 10, and forced
shared-prefetch mode 13 each passed all 22 validator shapes. Maximum absolute
score difference from Gluon in the automatic run is 7.63e-6. Every shape
matched both top-512 key sets and the production HIP exact-selector's
transformed page-index sets. Native FP8 MFMA arithmetic retains the same
small difference from the FP64 oracle as the earlier qualified version.

Coverage includes signed and positive weights, one-hot/random FP8 inputs,
odd widths, ragged/zero lengths, invalid page IDs on empty rows, padded input
and output rows, canaries, three changed-input graph replays, two streams,
module close, output row addresses beyond 2/4 GiB, and physical KV pages
beyond 4 GiB. The automatic suite includes 262144 compressed keys, equivalent
to a 1M-token input capacity; this does not validate 1M-context model accuracy.

All 20 final paired workloads and all 36 final schedule-comparison workloads
passed score and top-512 set checks before timing. Each candidate output is
reset to NaN to expose missing writes. Modes 1–6 also passed their full forced
22-shape checks after the native-swap change in run r45. The transposed mode 7
passed its full suite. Other exploratory modes have the recorded sweep
coverage; they are never selected automatically.

The shared-prefetch full suite was run separately with a 90-second timeout
while the controller was awaiting work; `forced13_run.json` records the run.
The controller's fixed mode allowlist ends at mode 10, so this separate run
provides full forced-mode coverage without altering the running controller.

## Preserved large/long behavior and broader matrix

The four retained mode-0 cases differ by at most 0.7% from baseline medians.
Both the 1024x4096 and 8x262144 cases retain their advantage over Gluon. This
is component evidence, not proof that sustained C256 serving throughput is
unchanged. Negative reduction denotes a slowdown.

| Query rows | C4 keys | Previous µs | Selected µs | Gluon µs | Reduction vs previous |
|---:|---:|---:|---:|---:|---:|
| 1 | 4,096 | 3.604 | 3.563 | 4.524 | 1.1% |
| 2 | 4,096 | 3.856 | 3.832 | 4.551 | 0.6% |
| 4 | 4,096 | 4.189 | 4.125 | 4.572 | 1.5% |
| 8 | 4,096 | 4.692 | 4.562 | 4.612 | 2.8% |
| 16 | 4,096 | 5.260 | 4.738 | 4.754 | 9.9% |
| 24 | 4,096 | 6.037 | 5.228 | 5.352 | 13.4% |
| 32 | 4,096 | 6.689 | 5.292 | 5.381 | 20.9% |
| 64 | 4,096 | 9.241 | 8.104 | 9.402 | 12.3% |
| 128 | 4,096 | 14.602 | 12.964 | 16.524 | 11.2% |
| 256 | 4,096 | 24.165 | 23.655 | 27.213 | 2.1% |
| 1 | 1,024 | 3.560 | 3.554 | 4.458 | 0.2% |
| 8 | 1,024 | 3.885 | 3.842 | 4.498 | 1.1% |
| 128 | 1,024 | 6.598 | 5.313 | 5.900 | 19.5% |
| 1 | 16,384 | 4.158 | 4.081 | 4.551 | 1.9% |
| 8 | 16,384 | 6.695 | 5.295 | 5.397 | 20.9% |
| 128 | 16,384 | 43.282 | 42.605 | 46.269 | 1.6% |
| 1024 | 4,096 | 86.890 | 87.437 | 99.327 | -0.6% |
| 8 | 262,144 | 44.051 | 43.827 | 55.187 | 0.5% |
| 128 | 32,768 | 85.288 | 85.302 | 85.789 | -0.0% |
| 1024 | 262,144 | 5098.327 | 5101.480 | invalid full-pool reference | -0.1% |

Source: `indexer_c14_r46/job-06.result.json`. The >4 GiB packed-pool comparison
retains absolute page IDs in both assembly launches. Its untimed Gluon oracle
is evaluated on rebased slices below 2 GiB to avoid the reference's 32-bit
KV-offset limit discovered in the prior report. The invalid full-pool Gluon
timing is excluded; no new production-pool failure is claimed.

## Experiments and evidence

Transposed MFMA layout, four-wave head splitting, and kernarg preloading did
not improve the selected C1–C4 paths. They remain explicit comparison modes
under `experiments/`; the runtime does not select them. Head splitting
reassociates FP32 additions and is not part of the exact-tree default policy.
Kernarg-preload fallback was compiled but not exercised on older firmware.

The two bounded test windows are r45 and r46. Raw stage-specific results are
retained in their respective directories. r45 results precede shared-Q;
r46 jobs 02/03/04 add shared-Q, preload, and shared-prefetch respectively.
r46 jobs 05/06/07 and `forced13.json` qualify the final sources. Source and
binary SHA-256 hashes are in `indexer_c14_r46/build_manifest.json`; the local
committed source files match those hashes. `original_object_unchanged` is true.
The assembly syntax alignment error in the exploratory preload build was
fixed before any GPU execution of that variant.

Production recovery was requested after all final jobs completed. The
qualified TP4xDP2 worker, router, HiCache and Mooncake configuration are
preserved. Recovery evidence is recorded in netra-server's `INDEXER_C1_C4.md`.
Serving promotion still requires real captured-input qualification,
multi-device ownership checks, request/history/long-context accuracy tests,
and the established C256 a/b/c serving gate.

## Reproduce

Use the deployment's AITER/SGLang reference patches on isolated gfx950 hardware:

```sh
bash tools/benchmark/indexer/build.sh /tmp/c14-build
python tools/benchmark/indexer/validate.py --build /tmp/c14-build \
  --correctness-only --output /tmp/automatic.json
python tools/benchmark/indexer/validate.py --build /tmp/c14-build \
  --mode 13 --correctness-only --output /tmp/shared-prefetch.json
python tools/benchmark/indexer/sweep_small.py --build /tmp/c14-build \
  --baseline-runtime /tmp/84c4cee/dsv4_mqa.py --baseline-build /tmp/84c4cee/build \
  --output /tmp/paired.json
python tools/benchmark/indexer/sweep_c14.py --build /tmp/c14-build \
  --baseline-runtime /tmp/84c4cee/dsv4_mqa.py --baseline-build /tmp/84c4cee/build \
  --output /tmp/schedules.json
```

Instruction references: [AMD CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
and [LLVM AMDGPU kernarg preload documentation](https://llvm.org/docs/AMDGPUUsage.html).
