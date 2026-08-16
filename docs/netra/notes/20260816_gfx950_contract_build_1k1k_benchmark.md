# gfx950 contract-build 1K/1K validation (2026-08-16)

Commit `a1aef6af8abfcc1b900d9652abeb1a694237427a` was validated on one AMD
Instinct MI350X after the production build system was changed to generic,
profile-driven operation contracts.

## Build and artifact gate

The clean `gfx950-qwen36-dflash` profile built all five components on the
MI350X. The controlled old/new promoted M12 K0 trees remained byte-identical,
with relative-path/content aggregate
`6e9c14c56e89e91f0043759a0076b985e7d8dfea759da38f927755182a4a19aa`.

The clean build's production MoE, router, GQA8 FP8-KV target-attention, and GDN
K0 verification HSACOs matched the artifacts mounted by the saved-best server.
The active server intentionally mounts older state-replay `capacity-fix`
artifacts, however, and those replay HSACOs do not match the generic profile's
replay outputs. Consequently, the serving result below validates the unchanged
saved-best deployment and the build refactor's no-regression claim; it does not
qualify replacing the active replay artifacts with the profile outputs.

## Exact serving contract

- Hardware: one MI350X, GPU 0
- Target: Qwen3.6-35B-A3B-FP8
- Draft: Qwen3.6-35B-A3B-DFlash, block size 12
- Per repetition: 384 requests, concurrency 128, infinite request rate
- Per request: exactly 1,024 input and 1,024 forced output tokens
- Seed 20260809, temperature 0, `ignore_eos=true`
- Tokenized prompts, no benchmark warmup requests

Every repetition completed 384/384 requests and produced exactly 393,216 input
and 393,216 output tokens.

| Repetition | Output tok/s | Duration (s) | Acceptance length |
|---:|---:|---:|---:|
| 1 | 9,432.23 | 41.689 | 6.7625 |
| 2 | 9,305.53 | 42.256 | 6.6288 |
| 3 | 9,819.88 | 40.043 | 6.5515 |
| Mean | **9,519.21** | **41.329** | **6.6476** |

The prior saved v17 result averaged 9,083.34 output tok/s and peaked at
9,257.65 output tok/s across five repetitions. The new three-run mean is 4.80%
higher, its median is 3.71% higher, and its 9,819.88 tok/s peak is 6.07% higher.
Mean acceptance length increased 2.17% from 6.5062 to 6.6476.

## Evidence

The authoritative raw JSON, server metadata, build checksum manifest, and
machine-readable comparison are stored on the MI350X at:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/
  refactor-a1aef6a-1k1k-20260816/
```

An exploratory run with one warmup request reached 9,788.78 output tok/s but
is excluded from the comparison because the saved baseline used zero benchmark
warmup requests. The server health endpoint passed after all measurements.
