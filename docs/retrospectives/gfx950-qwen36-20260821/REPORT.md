# Qwen3.6-27B/35B optimization on AMD MI350X/gfx950

Date: 2026-08-22

Status: retrospective and MI350X campaign complete with explicit correctness and coverage gaps

Kernel revision: `9c5940cceaecb00a26f157a4894d1a8edad4e0d4`

Server revision: `fae2865d9b3096c2cc518aa16d3797ac828f77cc`

## Abstract

This report reconstructs the Qwen3.6 MI350X campaign from the first native
gfx950 FP8 decode work on 2026-07-30 through the 27B work, modular
kernel/compiler refactor, and 2026-08-21 prefill investigation. It inventories
the exact operations, accepted and failed paths, competitor eligibility,
measured results, deployment contracts, and likely causal mechanisms.

The central result is negative as much as positive: microkernel latency does
not predict serving performance. The accepted Netra paths combine exact-shape
specialization with layouts that avoid conversion, fixed graph-safe ABIs,
bounded fallbacks, and byte-locked deployment evidence. AITER remains the
winner for multiple dense and fallback contracts where Netra assembly was
locally faster but failed matched serving. This is an engineering result, not
a claim that one kernel language or vendor library universally wins. A current
isolated MI350X campaign adds exact-output Netra-versus-SGLang/AITER serving
controls, fixed-concurrency diagnostics, standalone GDN attempts, and
rocprofv3 counter passes. Failed repeatability and cross-arm output gates are
retained but never promoted as wins.

A post-audit service-level restoration on 2026-08-22 adds matched complete-
engine 1K/1K controls for Netra, base SGLang, stock SGLang DFlash, and vLLM,
plus a stock-DFlash 1K/8K control. These results extend the deployment-level
comparison; they do not relax the exact-output requirements used to attribute
a gain to an individual kernel.

## Evidence boundary and audit method

The audit used clean, isolated worktrees and fetched both remotes. On the audit
date, `origin/main` exactly matched both supplied historical anchors. The
original user checkouts were dirty and were not modified. The kernel analysis
branch is `analysis/gfx950-qwen36-retrospective-20260821`; the server worktree
is detached and read-only.

The mechanical collector traversed `git log --all`, merges, refs, relevant
reflogs, rename/delete records, historical blobs, notes, JSON, manifests,
tactics, tests, scripts, and external path references in both repositories.
Its result is [the complete chronological ledger](data/chronological-optimization-ledger.csv):
472 relevant commits from 2026-07-30 through 2026-08-21, 2,292 relevant file
changes, 406 relevant reflog records, 45 refs, 290 evidence files, 91 JSON
files, 5,211 numeric leaves, 37 tactics, and 46 manifest operations. File
checksums and deleted/replaced paths are retained in
[the evidence inventory](data/evidence-inventory.csv) and
[historical file ledger](data/historical-file-change-ledger.csv).
The [reviewed decision ledger](optimization-decision-ledger.csv) adds the
requested contract, baseline/candidate, kernel/integrated result, correctness,
decision, reason, evidence commit, and evidence checksum fields to the
decision-bearing experiments. Missing historical fields are explicitly marked
instead of inferred.

A second read-only pass inspected ignored files in both original dirty
checkouts and both isolated worktrees. It selected and hashed 581
target-relevant artifacts: 248 generated assembly/include files, 186
JSON/CSV/log/profile-like files, 87 download metadata files, 25 code objects,
17 checkpoint shards, and other small artifacts. The local 35B checkpoint is
incomplete, but every one of its 17 present shards matches both the size and
LFS SHA-256 recorded by revision
`95a723d08a9490559dae23d0cff1d9466213d989`; missing files are explicitly
listed rather than treated as verified. The revision tree has 43 LFS files:
17 match, zero mismatch, and 26 are absent. The deterministic manifest hash of
the present subset is
`fa6e21a1b5cd2d8f8c7e7893d3f54abe1a51cd4fc80515691c6c05810d78b052`.
The three accepted M1 MoE code-object
hashes found under ignored `build/` trees match the current locked tactic and
deployment hashes across repeated engine builds. The rejected dense one- and
four-wave code objects were also recovered but are correctly not registered as
accepted tactics. Evidence:
[ignored-artifact inventory](data/ignored-artifact-inventory.csv),
[summary](data/ignored-artifact-summary.json), and
[code-object verification](ignored-code-object-verification.csv), plus the
[checkpoint integrity matrix](checkpoint-integrity.csv).

Evidence labels have strict meanings:

- **Current measurement** was generated during this audit on an isolated AMD
  Instinct MI350X/gfx950 using the recorded immutable container.
- **Tracked aggregate** is a number present in a committed Markdown or JSON
  artifact. It is not represented as a newly reproduced measurement.
- **Recovered raw** is a byte-for-byte local copy of the historical
  `/data/netra/benchmarks/gfx950_qwen36_prefill-20260821.t3C9F4` archive.
- **Inferred mechanism** is a causal interpretation supported by source,
  metadata, counters, or contrasting experiments, not a direct measurement.
- An empty CSV cell means unavailable, never zero.

The execution host exposed eight MI350X/gfx950 GPUs, ROCm 7.2.3, amd-smi
26.2.2, and the exact container image `sha256:89941358...`
(`netra/sglang:v0.5.16-rocm720-mi35x-gigatoken0.9.0`). Four single-GPU
serving arms were reconstructed from saved `docker inspect` records: accepted
27B and 35B deployments and matched controls that disabled the relevant Netra
paths while retaining framework/AITER defaults. The campaign captured
hardware, package, container, log, clock, power, thermal, and process state
before, during, and after execution. All four containers exited cleanly and
the final accelerator process inventory was empty.

The current and recovered evidence sets contain 1,038 files and 1,150,741,298
bytes. Every file is SHA-256 inventoried. Four complete checkpoint trees add
349 file hashes: 27B FP8/DFlash and 35B FP8/DFlash, approximately 73 GB in
total. The external numeric ledger preserves 5,544,631 numeric leaves from 544
JSON/CSV/TSV sources. Seven compressed profiler event traces are deliberately
excluded from that numeric ledger because events are not benchmark samples;
their original bytes remain retained and hashed. The machine-readable scope
and gaps are in [summary.json](summary.json) and
[benchmark coverage](benchmark-coverage.csv). No failed or missing result was
reconstructed from prose.

## Historical reconstruction

### 1. Native 35B decode and integration, 2026-07-30

The first relevant kernel commit, `b42d33684baa4f743c920b1057b41754364e3f92`,
introduced native gfx950 Qwen FP8 decode kernels. Work proceeded by replacing
parts of the routed-MoE dataflow—gate/up, SiLU plus quantization, and
down/reduction—while retaining the exact E4M3 block-128 and BF16-output
contract. The two-wave down projection was promoted at `52518146...`.

The tracked results show why integration mattered immediately. The raw fused
SiLU-plus-quant kernel measured 2.782 microseconds versus 5.523 for the
deployed-equivalent two-kernel harness (1.99x), and the accepted graph pipeline
improved historical output throughput from 148.014 to 158.288 tokens/s.
Conversely, eager
integration regressed 6.01% because dispatch overhead was exposed. Shared-gate
and skip-sort integration later produced +27.31% full-graph and +27.08%
piecewise throughput in its measured scope. The router kernel measured 6.24
microseconds and improved eager/full serving, but the piecewise variant failed
its control semantics and was not promoted there. Evidence:
[FP8 results](../../notes/gfx950-qwen36-fp8-results.json) and
[kernel narrative](../../notes/gfx950-qwen36-fp8-kernels.md).

Argmax is the clearest standalone accepted kernel. PyTorch used only 16
workgroups for `[16,248320]`; Netra split each row into 128 chunks, creating
2,048 stage-one waves, then reduced 128 partial keys per row. It reproduced
PyTorch's NaN/tie/signed-zero semantics in 197/197 cases. Historical mean
latency was 7.949 versus 56.304 microseconds; the serving trace was 12.306
versus 74.550 microseconds. The optimization saved 64.197 microseconds per
verification call without attributing noisy absolute request medians to the
kernel. Evidence: [argmax acceptance report](../../notes/gfx950-qwen36-argmax-f32-accepted.md).

### 2. GDN and attention specialization, late July to early August

M16 GDN verification combined fixed H32/K128/V128/BV16 geometry, BF16 I/O,
and FP32 accumulation/state into assembly whose recorded validation was bit
exact across layers and replay. The combined kernel time was 24.361
microseconds; short serving latency improved 2.32% and verification-call
throughput 3.52–3.69%. Evidence:
[GDN result JSON](../../notes/gfx950-qwen36-gdn-verify-m16-results.json).

The M12 K0 core is causally important. The selected kernel computed without
writing the full intermediate state, avoiding roughly 805 MiB of output
traffic in the rejected full-state variant. It measured 119.1815 versus
186.6225 microseconds for Triton (1.5659x), and the tracked serving ordering
reported 4,445.627 versus 4,107.910 output tokens/s in the reverse arm.
Evidence: [K0 report](../../notes/gfx950-qwen36-gdn-m12-k0.md).

The exact M12 causal convolution measured 21.700 versus 44.860 microseconds
for Triton and was bitwise exact. It is a narrow incremental path, not a claim
about all convolution shapes. Evidence:
[causal-convolution report](../../notes/gfx950-qwen36-gdn-causal-conv-m12.md).

Attention specialized around the native FP8 KV-cache ABI. The accepted GQA4
path measured 145.442 versus 209.562 microseconds and improved the recorded
production serving run from 3,998.26 to 4,075.41 output tokens/s. The GQA8
target path grouped four query heads sharing a KV head in one 512-thread
workgroup, reducing repeated prefix-KV traffic fourfold relative to the
per-query-head Triton layout. On the exact capture it measured 84.081 versus
185.722 microseconds and improved output throughput 8.406%; error was 28 of
3,096,576 BF16 elements, maximum absolute 0.0009765625, cosine 1.0. A broad
`M<=16` predicate was rejected because it selected an extension-only kernel
for piecewise prefill—proof that dispatch semantics are part of correctness.
Evidence: [GQA4](../../notes/gfx950-qwen36-extend-attention-gqa4.md) and
[GQA8](../../notes/gfx950-qwen36-target-attention-gqa8-fp8kv.md).

### 3. Exact M768 MoE and the modular refactor

Natural C64 serving exposed an exact M768 routed-MoE case. The locked design
is a pair: a two-wave producer writes FP16 split-K2 partials, and a reducer
applies FP32 route scales and emits BF16. After moving model-specific sources
into model-neutral templates, the executable `.text` remained byte-identical.
Recorded metadata is concrete: producer grid `(2,365,1)`, 256 VGPRs and 64 KiB
LDS; reducer grid `(16,768,1)` and 28 VGPRs. The retained five-process result
is mean 11,431.1078 output tokens/s, range 11,386.687–11,474.461, standard
deviation 42.012, accuracy .9525. No matched default sample set is present in
the tracked tree, so the report does not calculate a default speedup.
Evidence: [modularity audit](../../notes/gfx950-template-modularity-audit.md).

The refactor separated three layers:

1. a model frontend expands checkpoint/model structure into exact,
   model-neutral operation contracts;
2. a tactic catalog binds bounded contracts to kernels and explicit
   fallbacks; and
3. the runtime bridge owns initialization and a graph-safe fixed launch ABI.

The current 35B deployment inventory records native server-owned operations
but deliberately leaves unsupported scopes as guarded framework fallbacks.
The 27B manifest expands repeated layers into shared computational contracts;
model names do not participate in tactic keys. Source, executable text,
code-object, workspace, and table hashes prevent an apparently equivalent but
different engine from silently shipping.

### 4. Qwen3.6-27B and BF16 recurrent state

The dense 27B hybrid has 64 layers in a three-GDN/one-full-attention pattern,
hidden size 5,120, GDN H48/K128/V128, full-attention GQA6 D256, and width-4
causal convolution. Its block-8 verification contract differs from 35B; reuse
occurs at the operation contract, never by model label.

BF16 recurrent storage with FP32 accumulation/replay halved the state pool
from 18.14 to 9.07 GB. Five fresh C128 processes averaged 3,429.02 versus
3,287.81 output tokens/s for FP32 state (+4.30% raw), with all 1,920 requests
passing. In paired full-GSM8K C128/C192 runs, C192 averaged 6,381.33 versus
5,710.44 output tokens/s, +11.75% with 95% CI 10.41–13.09, while the accuracy
interval crossed zero. This is explicitly a throughput profile: median TTFT
rose 15.93% and median TPOT 31.87%. Evidence:
[27B deployment report](../../notes/gfx950-qwen36-27b-fp8.md).

The T8 QKVZ+conv assembly demonstrates the serving gate. It was bitwise exact
in eager and graph replay at batches 1/32/128/256 and measured 33.941 versus
44.141 microseconds (1.3005x). Matched serving nevertheless fell from 3,307.72
to 3,206.81 tokens/s with FP32 state and 3,220.31 with BF16 state. It remains
verified and opt-in, not promoted.

### 5. Long-prefill investigation, 2026-08-21

For 27B at input 8,192, dense projections dominated 61.60% of warmed wall
time; GDN initialization was 6.83%, full attention 5.71%, norm/quant 5.50%,
GQA6 verify 2.32%, convolution 2.16%, QKV materialization 1.87%, chunk output
1.88%, and KKT 2.80%. For 35B, non-M768 MoE was 19.63%, attention 11.01%,
dense 11.45%, GDN initialization 9.45%, norm 3.13%, convolution 2.92%, chunk
output 2.48%, and split/materialization 2.32%.

All five 35B M8192 dense contracts were screened over 285 AITER CK, CK Tile,
and assembly candidates. Four already had exact table rows. The missing
`M8192,N5120,K2048` fallback CK13 was itself the fastest valid candidate at
144.6801 microseconds with error ratio zero, so no table change was warranted.

Eliminating QKV projection materialization was exact and made the warmed long
request 2.36% faster, but matched natural C192 serving changed only +0.026%; it
was removed. Previously retained negatives included FMoE block64 (+24.4%
isolated, +0.045% serving), dense M768 QKVZ (115.441 to 110.121 microseconds,
-6.40% serving), a frozen dense verification candidate (-0.94% matched ABBA),
and M8192 convolution (1.496x isolated, -5.60% serving). No 2026-08-21
candidate passed promotion. Evidence:
[prefill report](../../notes/gfx950-qwen36-prefill-profile-2026-08-21.md).

The `compare_scalar` event attributed 338.8 ms to a tiny construction but
overlapped later same-stream work. It is a Kineto host-synchronization
artifact, not a GPU bottleneck, and is excluded.

## Current MI350X benchmark campaign

The current serving campaign used exact token IDs, disabled the radix cache,
ran TP1/DP1 on isolated GPUs, and saved every streaming event, request record,
server-info record, log, and container configuration. The accepted arms used
dFlash-8/BF16 recurrent state for 27B and dFlash-12/piecewise replay for 35B.
Controls changed one feature group: Netra kernels were disabled while the same
model, prompt, graph configuration, framework, AITER stack, and container were
retained. Each exact short/8K case has 20 repetitions; repeat zero is reported
separately as cold and steady statistics exclude it.

The correctness-qualified current results are deliberately narrow:

- 27B input-16/output-1 produced identical output hashes in both arms. Steady
  median wall latency was 59.086 ms for Netra versus 74.501 ms for the control:
  20.65% lower latency, or 1.261x speedup. Netra's 19 steady samples had mean
  59.225 ms, p5 58.815 ms, p95 59.599 ms, sample CV 0.59%, and bootstrap mean
  95% interval 58.998–59.601 ms.
- 27B input-8192/output-1 also produced identical output hashes. Steady median
  wall latency was 409.187 versus 421.226 ms: 2.86% lower, or 1.029x. Netra's
  p5/p95 were 408.168/410.720 ms and its bootstrap mean interval was
  408.944–409.681 ms.
- 35B input-16/output-1 was exact in both arms, but Netra was not the winner:
  steady median wall latency was 24.951 versus 23.828 ms. Netra was 4.71%
  slower, equivalently the control was 1.047x faster. The report retains this
  negative result without explaining it away; most accepted exact paths are
  not activated by an M16 one-output request.

Other current numbers are diagnostic, not winner claims. At 27B C1/C128/C192,
Netra measured 94.291/2,344.276/2,696.436 output tok/s versus
82.245/2,045.948/2,445.381 for the control, apparent speedups of
14.65%/14.58%/10.27%. Every input hash matched, but only 0/3, 37/384, and
73/576 paired output hashes matched under concurrent dFlash scheduling. At
35B C1, all three paired output hashes matched and Netra measured 931.196
versus 803.951 output tok/s, but this is a single three-request measurement
window rather than an independent-process estimate. At C64, Netra measured
4,783.565 versus 4,733.326 output tok/s (+1.06%), while only 60/192 paired
output hashes matched. None of these concurrency deltas is used to promote a
kernel.

Two further correctness failures are first-class evidence. The 35B
input-1024/output-4096 Netra arm generated three distinct output hashes in
three repeats, with wall times 4.107, 20.966, and 11.493 seconds. The 35B
input-8192/output-1 control produced the reference hash in 17/20 repeats and a
second hash in repeats 3, 9, and 19. Both cases are performance-ineligible.
The accepted 35B Netra 8K arm itself passed 20/20 with a steady median of
125.635 ms, but no control speedup is claimed.

The recovered pre-refactor 27B M12 GDN harness ran in six independent
processes on six GPUs, with two opposite orders, batches 1/128/256, and 100 HIP
event samples per implementation per process (1,800 timing samples total).
Its strict gate failed: the hybrid path differed from its Triton reference by
7/73,728, 1,144/9,437,184, and 2,313/18,874,368 BF16 elements; maximum absolute
error was 7.63e-6 to 1.53e-5. The raw assembly path had a gross legacy ABI
mismatch. Timings are stable and fully retained, but they are invalid for a
performance claim. This failure says the old standalone harness no longer
expresses the current modular ABI; it does not override the exact integrated
serving gates.

Finally, separate rocprofv3 counter processes exercised the accepted M1
gate/up and down/reduce kernels for 28 counters each. Gate/up reported 576
waves, 9,216 FP8 MFMA instructions, 9,272.8 KiB fetched, 36 KiB written,
99.11% VALU utilization, zero LDS bank conflicts, and no LDS/scratch. Down
reported 256 waves, 4,608 FP8 MFMA instructions, 4,661.1 KiB fetched, 4 KiB
written, 92.44% VALU utilization, zero LDS bank conflicts, 1 KiB LDS, and no
scratch. The low whole-device occupancy values (3.04% and 1.53%) reflect the
small exact M1 workload, not a general occupancy advantage. Profiler-reported
VGPR/SGPR fields differ from static code-object metadata, so both sources are
preserved rather than silently reconciled. Counter collection is intrusive;
latency comes only from non-profiled timing artifacts.

All request samples, descriptive statistics, comparisons, invalid timing
samples, and counter summaries are in
[current-serving-samples.csv](current-serving-samples.csv),
[current-serving-aggregates.csv](current-serving-aggregates.csv),
[current-serving-comparisons.csv](current-serving-comparisons.csv),
[current-gdn-microbenchmark-samples.csv](current-gdn-microbenchmark-samples.csv),
[current-gdn-microbenchmark-aggregates.csv](current-gdn-microbenchmark-aggregates.csv),
and [current-profiler-counters.csv](current-profiler-counters.csv).

### Post-audit retained-best and stock-DFlash controls

On 2026-08-22, a separate DP1 campaign reran the complete serving stacks on
one otherwise-idle MI350X. The 1K/1K contract used 384 requests at concurrency
128, exactly 1,024 input and 1,024 output tokens per request, greedy sampling,
ignored EOS, seed 20260809, and disabled prefix caching.

| Complete engine | Output tok/s | Duration | Mean TTFT | Mean TPOT |
| --- | ---: | ---: | ---: | ---: |
| **Netra SGLang + DFlash, retained best** | **10,599.51** | 37.0976 s | 757.85 ms | **9.25 ms** |
| Base SGLang 0.5.16 | 7,330.23 | 53.6430 s | 1,036.62 ms | 16.43 ms |
| Stock SGLang 0.5.16 + DFlash | 5,658.28 | 69.4940 s | 806.92 ms | 19.09 ms |
| vLLM 0.26.0 | 4,684.51 | 83.9397 s | 1,274.65 ms | 26.05 ms |

All four arms completed 384/384 requests, reported exactly 393,216 input and
393,216 output tokens, and had zero client errors. Netra delivered 1.45x base
SGLang throughput, 1.87x stock SGLang DFlash throughput, and 2.26x vLLM
throughput on this matched request contract. vLLM accepted text prompts through
its benchmark adapter rather than SGLang's raw token-ID transport, but its
server-side accounting reported the same 1,024/1,024 lengths for every
request.

The Netra arm was reconstructed from the retained lock rather than the current
launcher defaults. Its image, complete environment, server command, mount
layout, active kernel SHA-256 values, and live loaded-bridge map matched the
historical best. This matters because a preceding 8.87K diagnostic had drifted
to a newer server worktree, the wrong replay bridge, disabled router and
QKVZ/conv paths, a denser graph-batch set, and a different stream interval.
That diagnostic is excluded. The fresh exact restoration reached 10,599.51
output tok/s; the original five-fresh-process promotion mean remains
10,004.95 output tok/s.

The matched stock SGLang DFlash long-output control used 128 requests at
concurrency 128 with exactly 1K input and 8K output tokens. It reached 4,628.61
output tok/s in 226.5421 seconds, completed all requests, produced exactly
1,048,576 output tokens, and reported zero client errors. The retained Netra
three-process mean on the same request contract is 12,367.93 output tok/s,
or 2.67x the fresh stock-DFlash control. Netra's historical 14,431.74 output
tok/s observation remains labeled as a peak because it did not recur in the
three-process reproduction.

These runs establish service-level throughput under exact request-length and
completion checks. They are not paired output-equivalence experiments and do
not replace the operation-level correctness gates in the preceding section.
The machine-readable values, result hashes, image IDs, source locks, ratios,
and retained host evidence roots are in
[the 2026-08-22 control summary](../../blog/data/mi350x-1k-controls-20260822.json).

## Operation and competitor inventory

The [operation inventory](operation-inventory.csv) contains 45 reviewed rows
covering both models: dense Q/K/V/QKV/QKVZ/output/gate/up/down/router/lm-head;
blockscale and preshuffle; GDN initialization, verification, recurrent core,
precompute, convolution, splits, KKT, chunk output and state variants; prefill
and verify attention including GQA4/6/8 and FP8 cache; RMSNorm, gated norm,
SiLU and quantization; routed-MoE sort/producer/activation/down/reduction/M768
pair/fallback/workspace; argmax and materialization/synchronization boundaries.
Each row carries exact contract, current implementation, alternatives, graph
scope, status, and evidence.

The [comparison matrix](kernel-comparison-matrix.csv) is the primary requested
table. It never equates implementations whose dtype, scale storage, cache
format, masking, layout, graph semantics, or accuracy gate differs. The compact
[winner table](performance-winners.csv) distinguishes a microkernel winner
from the implementation that actually won the production gate.

The [completion audit](completion-audit.csv) maps every major obligation in
the original brief to its required proof, current evidence, verdict, and
remaining gap. It is intentionally stricter than file-presence checks: the
repository retrospective and current campaign are delivered, while contracts
without a new uniform comparison remain partial and correctness failures stay
explicit. The
[causal mechanism matrix](causal-mechanism-matrix.csv) separately covers 15
accepted Netra paths, distinguishing direct counter/metadata evidence from
source-supported explanations and incomplete counter hypotheses.

Current upstream pins (resolved 2026-08-21) and eligibility are in
[competitor eligibility](competitor-eligibility.csv). AITER, CK/CK Tile,
hipBLASLt, Triton, and PyTorch are eligible only operation by operation.
The current integrated controls exercise SGLang/AITER on both models; the
recovered archive retains the 285-candidate AITER dense screen and historical
exact Triton/PyTorch/library comparisons. The current legacy Triton GDN attempt
failed its exact gate and is not substituted for those historical contracts.
FlashAttention's ROCm backend is conditionally relevant for supported
attention, but exact D256 paged native-FP8 KV equivalence was not established.
HipKittens supports CDNA4/gfx950, while its published attention examples do
not establish this D256 cache ABI. FlashInfer's pinned official source exposes
CUDA backends, not an official ROCm path, so it is ineligible here. rocWMMA is
a building block for a new kernel, not an operation-complete baseline.

Primary implementation sources: [AITER](https://github.com/ROCm/aiter),
[SGLang attention backends](https://github.com/sgl-project/sglang/blob/main/docs/advanced_features/attention_backend.md),
[Composable Kernel](https://github.com/ROCm/composable_kernel),
[hipBLASLt](https://github.com/ROCm/hipBLASLt),
[Triton](https://triton-lang.org/main/index.html),
[FlashAttention](https://github.com/Dao-AILab/flash-attention),
[FlashInfer](https://github.com/flashinfer-ai/flashinfer),
[HipKittens](https://github.com/HazyResearch/HipKittens), and
[rocWMMA](https://github.com/ROCm/rocWMMA). AMD documents MI350X as CDNA4,
gfx950, wave64, 256 compute units, and 160 KiB LDS per CU in the
[ROCm GPU specification](https://rocm.docs.amd.com/en/latest/reference/gpu-specs.html).

## Why Netra is fast

### Contract specialization removes uncertainty

The unit of reuse is the full numerical and layout contract: dimensions,
strides, alignment, dtype, accumulation order, scale interpretation, masking,
cache format, output semantics, workspace, and graph bounds. Exact shapes
remove general-purpose branches and allow fixed workgroup geometry. Bounded
guards send everything else to a known-safe fallback. This explains both the
speed and why a broad attention predicate was a correctness bug.

### Layout work is paid once or eliminated

FP8 weights are preshuffled once into AITER's 16x16 layout; activations use the
expected K-block-major scale storage. No request-path weight transform is
allowed. Native E4M3 cache attention consumes the deployed cache directly.
Fusions are valuable when they remove observable traffic—normalization plus
group quant, gate/up plus activation preparation, or K0 without a full-state
write. A fusion that requires adapters is charged for those adapters in the
integrated result.

### Work is partitioned for gfx950

The argmax decomposition repairs catastrophic underfill: 16 workgroups become
2,048 waves on 256 CUs. GQA8 groups four query heads per KV head so prefix KV
loads are shared. Fixed bounded norm schedules select one, two, or four rows
per workgroup to maintain useful grid size on the exact 256-CU target. MoE
producer/reducer geometry makes split-K and reduction explicit rather than
hidden behind dynamic dispatch.

Register/LDS choices are operation-specific, not slogans. GQA8 spends 148
VGPRs and 32 KiB dynamic LDS to gain KV reuse; the M768 producer spends 256
VGPRs and 64 KiB LDS while its reducer needs only 28 VGPRs. Argmax uses 52
VGPRs, 20 SGPRs, no LDS or scratch in the raw stages. These choices trade
occupancy for reuse/throughput differently. The retained disassembly and
metadata support those facts. The argmax report retains selected historical
counters, and the current campaign adds a uniform 28-counter set for the M1
gate/up and down/reduce pair. Other accepted operations still lack comparable
current counter passes, so broader occupancy/cache claims remain hypotheses.

Recovered ignored HSACOs permit an independent static check of the M1 MoE
pipeline. The accepted gate/up object has 348 bytes of `.text`, 72 decoded
instructions, 30 VGPRs, 40 SGPRs, one MFMA, no LDS and no spills. SiLU/quant
has 724 bytes, 133 instructions, 35 VGPRs, 27 SGPRs, four global-load and two
global-store instructions, four DPP instructions, and no spills. Down/reduce
has 796 bytes, 170 instructions, 32 VGPRs, 42 SGPRs, 1 KiB fixed LDS, two
MFMAs, two barriers, and no spills. These are static counts, not latency or
dynamic traffic measurements; they corroborate the fixed ABI/resource story
without pretending to replace rocprof. Exact commands and results are in
[the static code-object analysis](ignored-code-object-static-analysis.csv).

### Graph integration is part of the kernel

Modules and symbols are loaded before capture. The launch path has stable
arguments and caller-owned streams, with no allocation, file/environment
lookup, module/symbol resolution, tactic selection, or synchronization. That
turns launch-count reduction into an actual replay benefit. Eager dispatch
regressions and piecewise-control failures show why a fast code object without
this integration is incomplete. AMD's [HIP graph documentation](https://rocm.docs.amd.com/projects/HIP/en/latest/how-to/hip_runtime_api/hipgraph.html)
supports the general launch-amortization mechanism.

### Pipelines, not isolated GEMMs, determine the critical path

The decisive resource may be state memory, route metadata, workspace lifetime,
KV traffic, graph capture, or materialization around a GEMM. The M768 pair is
designed around one shared split-K workspace. BF16 state wins by shrinking a
persistent pool. GQA8 wins by cache traffic reuse. The rejected M768 dense,
QKVZ+conv, M8192 convolution, and view experiments show that making one node
faster can move work, disturb overlap, change graph behavior, or optimize a
noncritical fraction. The complete failure record is
[here](rejected-superseded-experiments.csv).

## Generalization and novelty

The detailed classification and citations are in
[prior-art-novelty.csv](prior-art-novelty.csv).

Established practice includes exact/bounded profiles and tactic selection,
split-K, mixed-precision storage/accumulation, fixed graph replay, IO-aware
attention, compiler lowering to operation IR, and serialized deployment
engines. Relevant primary sources include TensorRT
[optimization profiles/tactics](https://docs.nvidia.com/deeplearning/tensorrt/latest/performance/optimization.html),
[engine capabilities](https://docs.nvidia.com/deeplearning/tensorrt/latest/inference-library/capabilities.html),
[MLIR Linalg](https://mlir.llvm.org/docs/Dialects/Linalg/),
[FlashAttention](https://arxiv.org/abs/2205.14135),
[PagedAttention/vLLM](https://arxiv.org/abs/2309.06180), and
[Ansor](https://arxiv.org/abs/2006.06762).

The defensible Netra contribution is a useful, rigorous combination tailored
to gfx950:

- model frontends lower to model-neutral numerical/layout contracts;
- raw assembly ownership is separate from framework integration;
- templates reproduce locked executable text without hot-path abstraction;
- producer/reducer pairs share explicit workspace ABIs;
- manifests bind source, code object, tactic, workspace, engine and deployment
  hashes; and
- promotion requires correctness, graph replay and matched natural serving,
  while negative results remain first-class evidence.

These are strong internal engineering contributions. This audit found no basis
to call them research-novel individually, and makes no research-novel claim.
A defensible research claim would require a wider prior-art search, public raw
artifacts, current reproducible comparisons, and an algorithmic abstraction
beyond this repository's implementation.

The most portable ideas are full-contract identity, explicit fallback,
graph-safe ABI discipline, paired workspace design, deployment hashes, and
serving-gated tactics. The FP8 scale/cache layouts can generalize to models
sharing those contracts. The exact wave64 assembly, CU-count schedule bounds,
MFMA choices, GQA grouping, and M1/M12/M16/M768 shapes are gfx950/shape
specific. On another accelerator, retain the contract and evidence system but
retune partitioning, tiles, vector widths, state placement, and graph bridge.

To reproduce these results upstream, SGLang/AITER would need the exact
checkpoint contracts and preshuffled layouts; native E4M3 paged-cache ABI;
bounded shape dispatch; preloaded graph-safe launchers; the M768 shared
workspace pair; BF16-state storage with FP32 recurrent semantics; immutable
tuning/engine manifests; and the same natural-EOS correctness and performance
gates. Merely copying assembly without those layers is insufficient.

## Prioritized roadmap

1. **Close correctness gaps before optimizing.** Reproduce the 35B 1K-output
   and control-8K hash divergence, then build a concurrency correctness/quality
   gate appropriate for dFlash scheduling. Do not use the diagnostic throughput
   deltas until this gate passes.
2. **Complete independent-process coverage.** Repeat current serving windows
   across independent container launches; add process-level CIs, a direct
   prefill-time field, natural-EOS quality, and current M8/M12/M16/M768/C256
   microbenchmarks against exact-contract controls.
3. **27B long dense prefill (61.60%).** Start from the proven AITER winners;
   optimize groups of projections or upstream dataflow, not another isolated
   row, and gate at natural C192 plus lower-latency C128.
4. **35B non-M768 MoE (19.63%).** Profile integrated sort, producer,
   activation, reduction and workspace lifetime. Prior block64 isolation was
   flat in serving, so require a pipeline-level design.
5. **35B/27B prefill attention (11.01%/5.71%).** Establish a contract-exact
   native-FP8 D256 baseline for AITER, Triton and any eligible FlashAttention
   path before specializing.
6. **GDN initialization/chunk/KKT pipeline.** Target eliminated state traffic
   and materialization across stages; do not optimize chunk kernels in
   isolation.
7. **Extend uniform counters and disassembly.** The M1 MoE pair is covered;
   collect the same SQ/VALU/VMEM/TCC/LDS/occupancy set for the remaining
   accepted paths, retaining separate non-intrusive latency runs.
8. **Upstreamability.** Express winners as operation contracts and reusable
   AITER/SGLang dispatch entries with explicit safe fallbacks, keeping Netra's
   byte-lock and serving gates in CI.

## Reproduction and artifacts

Run the CPU-safe reconstruction from repository root:

```bash
python3 tools/analysis/collect_gfx950_qwen36_retrospective.py \
  --kernel-root "$PWD" \
  --server-root ../netra-server \
  --output-dir docs/retrospectives/gfx950-qwen36-20260821/data
tools/analysis/run_gfx950_qwen36_retrospective_campaign.sh audit
python3 tools/analysis/integrate_gfx950_qwen36_campaign.py \
  --current-root "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT" \
  --recovered-root "$NETRA_RETRO_RECOVERED_ARTIFACT_ROOT" \
  --report-root docs/retrospectives/gfx950-qwen36-20260821 \
  --derived-root "$NETRA_RETRO_DERIVED_ARTIFACT_ROOT"
```

Audit validation passed the kernel repository's complete `tools/ci/check.sh`:
97 unit tests plus repository, tactic-library, and example-compilation checks.
An isolated `uvx pytest` run passed 39 server Qwen3.6 tooling/profile tests and
four subtests across six files. Three other current-main tooling test files
reference scripts that no longer exist, and PyTorch-dependent tests cannot
collect in the local CPU-only worktree. GPU execution ran remotely in the
pinned container: 8/10 exact serving cases passed repeatability, all raw
requests were retained, the six standalone GDN attempts failed their strict
gate as documented, and both accepted M1 profiler harnesses were deterministic
across ten invocations per counter pass.

The campaign script refuses local GPU modes when `/dev/kfd`, `rocminfo`, or the
raw archive is missing. [REPRODUCE.md](REPRODUCE.md) gives the immutable-
environment, inspected-container relaunch, benchmark, profiler, checksum,
transfer, and derivation sequence. [benchmark-samples.csv](benchmark-samples.csv) contains
reviewed fresh-process values preserved in tracked prose;
[benchmark-samples-exhaustive.csv](benchmark-samples-exhaustive.csv) preserves
all mechanically classified sample leaves in tracked JSON. The full numeric
inventory is
[historical-benchmark-metrics.csv](data/historical-benchmark-metrics.csv).
[benchmark-aggregates.csv](benchmark-aggregates.csv) contains reviewed
aggregates, while
[benchmark-aggregates-exhaustive.csv](benchmark-aggregates-exhaustive.csv)
preserves every mechanically classified aggregate/metric field. The curated
low sample count is an evidence limitation, not an assertion that
aggregate-only experiments had one sample. Automated classifications retain
JSON paths so context-like arrays can be recognized rather than
overinterpreted.
[benchmark-sample-derived-aggregates.csv](benchmark-sample-derived-aggregates.csv)
adds reproducible median, linear p5/p95, sample standard deviation, CV, and a
deterministic 20,000-resample bootstrap mean interval for the three retained
five-process sample sets. The current CSVs add 10,100 serving metric rows,
1,800 GDN timing rows, 174 serving aggregate rows, 18 GDN aggregate rows, and
56 profiler-counter rows. The external derived directory contains the full
5,544,631-leaf ledger, 1,038-file artifact inventory, exclusions policy, and
its own `SHA256SUMS`. Descriptive calculations are post-hoc; the raw request,
HIP-event, and counter records remain immutable.

## Conclusions and uncertainties

The strongest conclusion is that Netra's speed is a property of a controlled
dataflow and deployment system: exact contracts, layouts, kernels, workspaces,
graphs, and serving gates. Kernel code supplies large wins where it fixes
underfill or traffic; layout/compiler/graph discipline makes those wins
reachable and safe; deployment locks make them reproducible. The rejection
ledger demonstrates that any one layer without the others is unreliable.

The post-audit controls establish complete-engine throughput for their exact
request contracts: 10,599.51 output tok/s for the fresh retained-best 1K/1K
restoration and a 12,367.93 output tok/s three-process mean at 1K/8K. They do
not establish cross-arm token identity or isolate any one kernel's causal
contribution. Uncertain or ineligible: concurrent cross-arm dFlash output
equivalence; the separate 35B 1K Netra and 8K control cases that failed
repeatability; performance from the legacy standalone GDN harness;
independent-process confidence intervals for the new single-run competitor
controls; uniform current competitor/counter coverage for every operation;
and any claim of research novelty. These are explicit gaps, not hidden
assumptions or inferred wins.
