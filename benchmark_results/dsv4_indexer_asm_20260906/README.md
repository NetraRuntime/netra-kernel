# DeepSeek V4 C4 scorer: gfx950 assembly validation

The C4 preshuffled FP8 paged-MQA scorer was rewritten as handwritten AMDGCN
in netra-kernel. HIP C++ only owns modules and dispatches on the caller's
stream. This experiment does not replace the other Triton families.

**Status: component-qualified experimental implementation; not deployed.**
Some shapes improved and small-batch shapes regressed. No end-to-end C256 TPS,
real-model capture qualification, or 1M-context model-accuracy qualification
was run for this implementation. The existing TP4xDP2 production deployment
remains the selected serving implementation.

## Selected implementation

One wave retains all 64x128 FP8 query values and 64 head weights while
processing a run of KV pages. The policy uses one page when there are fewer
than 1024 query-page tasks, eight pages for width >=65536 and rows >=8, and
four pages otherwise. The pure assembly runtime accepts all of these shapes;
it does not silently route slower cases to Gluon. A future serving integration
must make that selection explicitly after real-request qualification.

The first one-page-per-wave version was slower throughout this test matrix.
Four-page query reuse improved the C256-like shape; eight-page reuse helped
long contexts. Source and raw intermediate results are retained in this
folder. The final source hashes and code-object hashes are in
`build_manifest.json`. The first variant has a 72-byte kernarg ABI; the final
variant adds pages-per-wave at offset 72 (76-byte ABI).

## Correctness

Nine shapes passed: (rows, compressed-key width) = (1,64), (8,65), (9,257),
(8,4096), (16,32768), (8,262144), (1024,4096), (256,257), and (16,32769).
Checks covered one-hot and random FP8 data, positive and signed weights,
ragged/zero lengths, randomized page tables, invalid page IDs on empty rows,
partial page groups, output canaries, independently padded input rows, three
changed-input graph replays, two concurrent streams, explicit module cleanup,
output row addresses above 2/4 GiB, and physical KV addresses above 4 GiB.

All nine shapes matched the deployed Gluon scorer's top-512 sets and the
production exact HIP top-K selector's transformed page-index sets. Maximum
score difference from Gluon was 7.63e-6. They are not bitwise identical.

Both implementations differ slightly from the FP64 mathematical reference:
the largest observed error was 5.84e-4 for both. The oracle check reports both
errors and requires the candidate maximum not to exceed Gluon's by >3e-5.
The tighter candidate/Gluon comparison uses atol=3e-4, rtol=3e-5; its observed
maximum is much smaller. This preserves existing native MFMA behavior; it is
not evidence of an improvement to model accuracy.

Early validation attempts exposed test-harness assumptions: Gluon needs a
padded trailing stage for odd widths, and the exact selector requires a
16-byte row stride (including singleton-row tensors). Those were fixed in
the harness. Initial FP32 and then FP64 oracle-only checks also exposed the
shared native/reference difference above. The first maintenance controller
matched a result JSON as a job; its automatic recovery restored production.
The retry used an exact job-filename pattern. These were not production
kernel changes.

## Isolated GPU graph timings

AMD Instinct MI350X, gfx950, ROCm 7.2. Only visible GPU 0 was tested. Each
round measured 20 graph replays with five scorer launches per graph, after
warmups. Three rounds alternated candidate/reference measurement order. Each
request group owns a separate set of KV pages; eight query rows represent a
speculative block sharing that request's pages. Values below are medians;
raw rounds are retained, including first-round timing variation.

| Query rows | C4 keys | Request groups | Gluon µs | Assembly µs | Median paired speedup |
|---:|---:|---:|---:|---:|---:|
| 1 | 4,096 | 1 | 4.57 | 4.90 | 0.932x |
| 8 | 4,096 | 1 | 4.63 | 5.23 | 0.887x |
| 128 | 4,096 | 16 | 16.73 | 18.19 | 0.923x |
| 1024 | 4,096 | 128 | 99.78 | 88.22 | 1.124x |
| 8 | 262,144 | 1 | 55.24 | 43.86 | 1.257x |
| 128 | 32,768 | 16 | 86.70 | 84.83 | 1.015x |
| 1024 | 262,144 | 128 | 5150.48 | 5093.21 | 1.011x |

The 1024x4096 shape is representative of 128 requests x eight speculative
rows at 16K input tokens in one DP group. It is a scorer microbenchmark,
not a measurement of C256 serving throughput. The 262144-key width exercises
C4 capacity corresponding to 1,048,576 input tokens; it does not validate
retrieval or generation accuracy at that context length. The largest timing
case uses a 4.43 GB packed KV pool and roughly 1 GiB of logits.

Small-batch latency is slower. The production 14K output-TPS target and
300 output-TPS/user targets are not demonstrated by these results. Remaining
promotion gates are real captured-input tests, multi-device launch ownership,
full serving correctness/history/long-context checks, and the unchanged
16,384-input / 4,096-forced-output C256 a/b/c benchmark.
