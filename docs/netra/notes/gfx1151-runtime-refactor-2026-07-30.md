# gfx1151 host runtime extraction — measured validation

Status: **accepted as a performance-neutral organizational refactor** against
baseline commit `c421a85614c4f168683c53660d8e30b98eb2ae9f`.

Target for every result below: **gfx1151**, AMD Ryzen AI Max+ PRO 395 / Radeon
8060S. Every numeric result is measured; no estimate is presented as a
measurement.

## Boundary and preserved contract

The 621-line SGLang launcher was reduced to a thin C compatibility facade. The
loader, kernargs, descriptors, and subsystem launch paths now live under
`runtime/gfx1151/`. Framework Python and raw `.s` files were not changed.

The accepted implementation preserves:

- one DSO and the existing 19 public `netra_*` C symbols;
- exact public symbol names and C declarations;
- the original preload order of 23 modules and its stop-on-first-failure behavior;
- cached named `hipFunction_t` fields before the hot path;
- packed kernarg field order, 8-byte alignment, and sizes from 16 through 96
  bytes, guarded by `static_assert`;
- launch-parameter-buffer mechanics, grids, workgroups, zero dynamic shared
  memory, and caller stream identity;
- the original per-entry `std::call_once` fast check;
- eager, full-decode graph, and native `tc_piecewise` behavior;
- every environment variable, feature flag, fallback, checkpoint layout, and
  SGLang Python contract.

The registry records its owning device and HIP context once, after the unchanged
preload sequence. No device/context query, map, lock addition, symbol lookup,
filesystem access, allocation, logging, or string construction was added to a
launch after initialization.

## Binary, ABI, and launch equivalence

| Gate | Measured gfx1151 result |
|---|---:|
| Public C exports | 19 old, 19 new, exact set |
| Production HSACOs selected by build | 26/26 SHA-256 byte-identical |
| Code-object metadata | 26/26 `llvm-readobj` outputs identical |
| Raw `.s` changes | 0 |
| Preloaded modules | 23 old, 23 new, exact order |
| Eager 32K GPU launches | 16,888 old, 16,888 new, exact signature multiset |
| Eager 32K `hipModuleLaunchKernel` calls | 3,705 old, 3,705 new |
| Eager 32K device/stream synchronization | 0 old, 0 new |
| B1 graph replay launches | 13,784 old, 13,784 new, exact ordered signatures |
| M12 graph replay launches | 23,864 old, 23,864 new, exact ordered signatures |
| Graph replay allocation/free/synchronization | 0/0/0 old and new |

A launch signature includes kernel name, queue, stream, LDS, scratch, VGPR,
accumulator VGPR, SGPR, grid XYZ, and workgroup XYZ. The eager trace's global
order can interleave differently across two queues, so eager acceptance uses the
exact multiset; graph-correlated signatures are exact in both multiset and order.

The reused `build/sglang` directory contains stale experimental HSACOs that are
not produced by the current build contract. Those files were preserved and
excluded explicitly. The 26 code objects actually selected by the production
build all match the frozen hashes.

## Correctness

All checks used the established tolerance; no tolerance was relaxed.

| Path | Measured gfx1151 result |
|---|---|
| M=1 raw linear, non-default stream | old/new BF16 output bit-exact |
| M=1 real-checkpoint full graph | exact input hash, token sequence, and output hash |
| M=12 real-checkpoint grouped verify path | 12/12 exact input and output hashes |
| Dense prefill M64/128/256/1024/2048/4096/8192 | qkvz, GDN-out, and AB outputs bit-exact old/new |
| Extend attention, prefix 0/128/512 | old/new bit-exact at all tested amplitudes; FP64 oracle recorded |
| Q/K norm + mRoPE + KV store, M=1/12/64/1024 | q, k, gate, selected K cache, and selected V cache bit-exact; graph replay exact after input mutation |
| GDN chunk output, T=8192 | 0 eager/graph failures; max error `1.9073486328125e-6` within `3.814697265625e-6` |
| GDN recompute W/U | old/new raw bit-exact, repeat exact, graph equal to eager, finite |
| Causal convolution + recurrent state | output and state bit-exact to oracle; zero NaNs |
| Expert activation pack | bit-exact, zero prefix/suffix guard corruption |
| Expert weighted reduction, T=128/8192 | zero bit mismatches versus FP64-to-BF16 reference |
| Real-checkpoint eager 32,768/+1 | paired inputs and generated token hashes exact |
| Native `tc_piecewise` M64 | exact input hash, token `13`, and output hash |

Router top-k and weights remain framework-owned and were not modified by this
refactor. Their downstream pack/reduce kernels pass isolated checks, and the
real-checkpoint eager, full-graph, M12, and piecewise token hashes are unchanged.

## Initialization and focused dispatch A/B

Fresh-process initialization used 101 balanced old/new pairs. Direct dispatch
used a non-default stream and alternating order. The production-path summary is
the median of three independent 50,000-sample runs per library.

| Metric | Old | New | Delta |
|---|---:|---:|---:|
| `dlopen` p50 | 11.498 ms | 11.509 ms | +0.094% |
| runtime init/preload p50 | 48.579 ms | 48.894 ms | +0.648% |
| eager host dispatch p50 | 0.842 us | 0.812 us | -3.563% |
| eager host dispatch p90 | 1.032 us | 0.872 us | -15.504% |
| eager HIP-event GPU p50 | 93.254 us | 93.375 us | +0.130% |
| eager HIP-event GPU p90 | 95.459 us | 96.060 us | +0.630% |
| graph-launch host p50 | 2.164 us | 2.144 us | -0.924% |
| graph-launch host p90 | 2.455 us | 2.364 us | -3.707% |
| graph HIP-event GPU p50 | 97.262 us | 97.422 us | +0.164% |
| graph HIP-event GPU p90 | 99.587 us | 99.627 us | +0.040% |

The same direct capture produced one graph node for old and new and bit-exact
outputs. After one process-wide capture warmup, the representative raw capture
was 1.794 us old versus 1.242 us new; instantiate was 26.450 us versus 15.419 us.

## rocprofv3 request and graph evidence

The profiler was `/root/venv1151/bin/rocprofv3`, matched to the PyTorch ROCm SDK,
with `--disable-signal-handlers true`. Counter collection remained disabled for
process-start traces to avoid the known AQL-profile signal-6 failure. The shell's
status-137 `Killed` line is intentional teardown after a completed request, not a
profiler crash.

| Scope | Old | New | Delta |
|---|---:|---:|---:|
| Eager 32K aggregate `hipModuleLaunchKernel` CPU | 39.698 ms | 38.206 ms | -3.757% |
| B1 graph `hipGraphLaunch` mean CPU | 1006.204 us | 935.766 us | -7.000% |
| B1 graph median GPU span | 56.673 ms | 56.539 ms | -0.236% |
| M12 graph `hipGraphLaunch` mean CPU | 1670.775 us | 1671.344 us | +0.034% |
| M12 graph median GPU span | 114.690 ms | 114.495 ms | -0.170% |

Each B1 replay contained 1,723 kernels; each M12 replay contained 2,983. No
allocation, free, device synchronization, or stream synchronization occurred
between the first and last measured graph launch in either library.

An early pair of process-start traces captured different framework capacity
tiers (`...12,15` versus `...12,16`) because available memory differed; that
created one additional 2 MiB framework pool segment outside replay. Balanced
serving runs later captured the identical requested tiers `[1,2,4,8,12,16]` for
both libraries. The balanced full-graph construction times were 3.06/2.91 s old
and 2.95/3.16 s new; logged graph memory was 0.16 GiB old and 0.16/0.17 GiB new
(log precision 0.01 GiB). This startup pool variance is reported, but it is not a
capture-time runtime allocation or replay-path change.

## Real-checkpoint serving A/B

Host E2E is measured HTTP wall time. All prompts were uncached (`cached_tokens=0`),
temperature zero, forced to the exact output length, paired by input seed, and
bit-exact old/new. The endpoint was non-streaming, so TTFT was **not measured**;
no TTFT estimate is supplied. Token rates below are derived from measured host
E2E and therefore labeled as such.

| Scenario | Samples/library | Old p50 | New p50 | p50 delta | p90 delta | Derived input tok/s old/new | Derived output tok/s old/new | Peak VRAM old/new |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| eager 210 in / 128 out | 8 | 7419.707 ms | 7423.040 ms | +0.045% | +0.110% | 28.303 / 28.290 | 17.251 / 17.244 | 72.464 / 72.601 GiB |
| full graph 210 in / 128 out | 8 | 7473.450 ms | 7475.696 ms | +0.030% | +0.041% | 28.099 / 28.091 | 17.127 / 17.122 | 73.459 / 72.726 GiB |
| eager 32,768 in / 1 out | 4 | 21525.081 ms | 21570.177 ms | +0.210% | +0.186% | 1522.317 / 1519.134 | 0.04646 / 0.04636 | 74.262 / 74.302 GiB |

The native `tc_piecewise` M64 one-request correctness anchor was 373.374 ms old
and 374.397 ms new (+0.274%); its capture was 12.14 s/0.22 GiB old and 12.27
s/0.22 GiB new. It is a correctness and construction anchor, not a statistical
throughput claim.

## Acceptance decision

The refactor passes the 1% eager dispatch, graph replay, and end-to-end gates.
It adds no GPU launch, graph break, replay synchronization, or replay allocation;
uses identical HSACOs; preserves deterministic tokens and kernel outputs; and
keeps the SGLang Python bridge unchanged. The abstraction is therefore accepted.

## Reproduction

All commands must run inside Netra:

```bash
scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
scripts/rocm/tools/build/build_runtime_dispatch_ab_gfx1151.sh
scripts/rocm/tools/benchmark/benchmark_runtime_init_ab.py OLD.so NEW.so \
  --pairs 101 --output init-ab.json
build/runtime-refactor/benchmark_runtime_dispatch_ab OLD.so NEW.so 50000
scripts/rocm/tools/benchmark/benchmark_runtime_serving_ab.sh \
  runtime-gfx1151-eager-210p128 210 128 4 2 49152
NETRA_RUNTIME_GRAPH_MODE=full-decode-tiers-1-2-4-8-12-16 \
  scripts/rocm/tools/benchmark/benchmark_runtime_serving_ab.sh \
  runtime-gfx1151-fullgraph-210p128 210 128 4 2 2048
scripts/rocm/tools/profiling/compare_runtime_traces.py OLD_TRACE NEW_TRACE \
  --scope graph --output comparison.json
```

The consolidated machine-readable result is
`results/runtime/gfx1151/runtime-refactor-c421a85-validation.json`.
