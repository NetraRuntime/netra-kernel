# DSV4 Triton assembly coverage and qualification

All 28 inventoried entry points have handwritten gfx950 implementations: 27
new control, memory, and numeric ports, plus the previously qualified indexer.
This inventory covers the current TP4×DP2 worker's 27 compiled names and one
source-discovered compressed-tail helper. Cache presence is conservative evidence,
not proof of execution in every request. This does not cover every Triton function
in SGLang or unrelated model families.

**Component implementation is complete. Performance qualification and production
integration remain open.** None of these new ports has been installed into the
serving worker. The existing TP4×DP2/HiCache/Mooncake deployment was restored and
passed native, authenticated public TLS, and Expo/history checks.

| Group | Entry points | Final component evidence | Cases |
| --- | ---: | --- | ---: |
| Control and cache metadata | 10 | `r50/job-04.result.json` | 393 |
| Memory, allocation, embedding | 8 | `r50/memory-final.result.json` | 294 |
| Numeric and sampling | 9 | `r52/full.result.json` | 380 |
| Previously qualified indexer | 1 | Earlier indexer campaign | Separate |

The 1,067 final component cases include small decode and verify rows, large
prefill batches, output canaries, and graph replay. Memory tests include C1–C4,
1,048,570-token fills, prefix-only writes, and an address above 4 GiB. Numeric tests
include 131,072-token vocabularies, changed-input replay and two independent
streams. The separate `r50/job-03.result.json` sampling stress run passed 36 cases
across six seeds. Sampling IDs, expert IDs, and acceptance outputs are exact;
floating-point tolerances are recorded per case. These are not model-level
long-context accuracy tests or end-to-end throughput measurements.

## Changes that mattered

- Wide cache rows use four cooperating waves. The three earlier 8K-page
  regressions now match or beat the reference in the tested 8K-page cases.
- The allocator reuses loaded lengths for token and page prefix sums. Request
  zero skips empty preceding-request reductions. Request-table writes load four
  int64 values and store four int32 entries per lane, with disjoint tiled tails.
- RMS keeps normalized values in registers, interleaves reductions, and handles
  four adjacent BF16 values per lane. Routing retains both IDs and weights until
  coalesced final stores; a ballot preserves smallest-ID ties.
- Full-vocabulary softmax and classic sampling split work across tiles using
  explicitly caller-owned scratch. Classic sampling preserves the reference's
  distinct sum and inclusive-scan orders, including inter-tile accumulation.
- HIP bridges own modules and launches; compute is handwritten assembly. There
  is no silent Triton fallback. Overlapping steps must own separate workspaces.

## Performance and remaining work

Paired timings use five shuffled graph-replay rounds. In r52, single-row HC head
was 11.825 us versus 43.158 us; full-vocabulary softmax was 7.775 us versus
118.552 us; classic sampling was 15.056 us versus 53.010 us; routing was 4.114 us
versus 4.215 us. The corresponding RMS case storing normalized output was
3.827 us versus 3.728 us. Small differences should not be treated as durable
serving speedups without end-to-end evidence.

`performance_summary.json` records every operation's worst case and all measured
regressions above 5%, rather than only favorable examples. Remaining regressions
include RMS without normalized output, large strided RoPE, some high-row-count
allocation/table and embedding cases, and short-vocabulary composite sampling.
The wide metadata fix does not eliminate every other metadata-shape regression.
Production dispatch/integration, actual C1–C4/C256 serving benchmarks, preserved
high-batch throughput, and model-level long-context/history validation remain
required. Neither 300 TPS/user nor 14K C256 TPS is established by this campaign.

## Reproducibility and recovery

The committed control/memory implementation matches the relevant paths in
`r50/final-manifest.json`; numeric code and its validator match
`r52/build-manifest.json`. All 49 recorded implementation/validation source hashes
were checked against the local worktree. Runtime documentation was added after
compilation and is not a compiled input. Earlier numeric source snapshots are
retained with r50/r51 because later variants changed their instruction layout.

r47–r50 used drained windows with the serving worker stopped. r51/r52 kept the
qualified model resident in VRAM, drained the router, and monitored native load;
their controller records show no active native requests during each benchmark.
Both variants compare Triton and assembly under the same run conditions. The
r51/r52 windows avoided model reloads. Recovery evidence lives in the matching
server validation branch.

Historical failures are retained. r49 first exposed an FP8 instruction-dependency
spacing error, then a one-token sampling mismatch at 1,024 requests. Both were
corrected and the final suites passed. Earlier numeric reports labeled every
replay with a supplied callback as changed-input replay, even when that callback
was a no-op for its shape. r52 distinguishes 315 graph-replay cases from the 56
cases whose callbacks actually changed input data.

Build with `bash tools/benchmark/dsv4_control/build.sh BUILD_DIR`, then validate
with `python tools/benchmark/dsv4_control/validate.py --build BUILD_DIR
--reference-root DEPLOYED_SOURCE_COPY --output result.json`. Memory and numeric
use the analogous `dsv4_memory` and `dsv4_numeric` paths. Qualification must run in
a bounded, drained window; retain recovery and source-hash evidence.
