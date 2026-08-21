# Qwen3.6-27B/35B optimization on AMD MI350X/gfx950

Date: 2026-08-21

Status: evidence-complete repository retrospective; GPU rerun blocked by host capability

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
a claim that one kernel language or vendor library universally wins.

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

Evidence labels have strict meanings:

- **Current measurement** would mean generated during this audit on MI350X.
  There are none.
- **Tracked aggregate** is a number present in a committed Markdown or JSON
  artifact. It is not represented as a newly reproduced measurement.
- **External raw** is a tracked path/hash whose bytes should live under
  `/data/netra`; none of the 347 referenced paths is mounted here.
- **Inferred mechanism** is a causal interpretation supported by source,
  metadata, counters, or contrasting experiments, not a direct measurement.
- An empty CSV cell means unavailable, never zero.

The host has no `/dev/kfd`, ROCm utilities/compiler, or usable Docker daemon.
Only an Intel render node is present. The cited prefill archive
`/data/netra/benchmarks/gfx950_qwen36_prefill-20260821.t3C9F4` is absent.
Therefore a current MI350X benchmark campaign, code-object rebuild, counter
collection, and raw-artifact checksum audit are impossible on this host. The
[environment manifest](data/environment-manifest.json),
[coverage matrix](benchmark-coverage.csv), and
[external artifact inventory](data/external-artifact-inventory.csv) make this
gap machine-readable. No missing samples, confidence intervals, or timings
were reconstructed from prose.

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

Current upstream pins (resolved 2026-08-21) and eligibility are in
[competitor eligibility](competitor-eligibility.csv). AITER, CK/CK Tile,
hipBLASLt, Triton, and PyTorch are eligible only operation by operation.
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
metadata support those facts; only the argmax report retains selected counter
values (including zero LDS bank conflicts). Missing rocprof databases prevent
a uniform counter comparison, so broader occupancy/cache claims remain
hypotheses.

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

1. **Restore evidence and rerun infrastructure.** Mount the 347 referenced
   artifacts, verify expected hashes, reserve an isolated MI350X, record clocks,
   power, thermals, firmware, driver and packages, and run the pinned container.
2. **Close benchmark coverage.** Execute input 16/1K/8K, all required M and C
   points, eager/capture/replay, and matched natural/fixed-output serving. Keep
   per-iteration samples and compute median/mean/p5/p95/stddev/CV/95% CI.
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
7. **Uniform counters and disassembly.** Collect comparable SQ waves,
   VALU/VMEM, TCC sectors, LDS conflicts, occupancy and launch timelines under
   non-intrusive latency runs plus separate counter runs.
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
python3 tools/analysis/build_gfx950_qwen36_retrospective_tables.py
tools/analysis/run_gfx950_qwen36_retrospective_campaign.sh audit
```

Audit validation passed the kernel repository's complete `tools/ci/check.sh`:
97 unit tests plus repository, tactic-library, and example-compilation checks.
The server's dependency-free `test_qwen36_exact_cases.py` passed 17 tests. The
remaining targeted server suite was not run because `pytest` is absent from
the host; GPU tests were not run for the environment reasons above.

The campaign script refuses GPU modes when `/dev/kfd`, `rocminfo`, or the raw
archive is missing. [REPRODUCE.md](REPRODUCE.md) gives the immutable-environment
and benchmark sequence. [benchmark-samples.csv](benchmark-samples.csv) contains
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

## Conclusions and uncertainties

The strongest conclusion is that Netra's speed is a property of a controlled
dataflow and deployment system: exact contracts, layouts, kernels, workspaces,
graphs, and serving gates. Kernel code supplies large wins where it fixes
underfill or traffic; layout/compiler/graph discipline makes those wins
reachable and safe; deployment locks make them reproducible. The rejection
ledger demonstrates that any one layer without the others is unreliable.

Uncertain or unverified in this audit: current performance against the pinned
2026-08-21 upstream revisions; raw-sample distributions for aggregate-only
historical results; raw artifact/hash availability; complete input-1K and
metric coverage; uniform hardware-counter causality; and any claim of research
novelty. Those are explicit next measurements, not hidden assumptions.
