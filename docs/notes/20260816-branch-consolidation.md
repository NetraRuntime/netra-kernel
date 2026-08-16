# Branch consolidation audit (2026-08-16)

This audit was performed before reducing the `NetraRuntime/netra-kernel`
remote to `main` only. The audited `main` was
`9cec80a81b6caaae8f496daeebe2fb4b332aef74`. All remote heads were fetched and
pruned before ancestry, patch-ID, source-content, build, and runtime checks.

## Apparent non-ancestor GDN heads

Two GDN heads looked unmerged by ancestry:

- `codex/gdn-prefill-gfx950` (`7193dd18ecf1`)
- `codex/gdn-k0-interleaved-unbounded-gfx950` (`f61f3ff88c79`)

They do not represent missing production source. The packed BV128 prefill
assembly and bridge on `main` have the exact Git blob IDs from `7193dd1`:

- `qwen36_gdn_fused_h_o_n16_t1024_bv128_gfx950.s`:
  `d5ce7f7ec5db3d7fc299632818889806fe9fb8ce`
- `qwen36_gdn_fused_h_o_t1024_bv128_bridge.hip`:
  `6e039bfa308a3a65ff6831b012a43e6185287115`

The interleaved verify work is also present in the evolved source: variants 16
and 17 remain available, variant 18 is retained as rejected scheduling
evidence, and the launch bridge now uses the newer capacity-safe ABI. Replaying
the old patch would overwrite later fused split-convolution, QKVZ-convolution,
state-capacity, and benchmark work, so content validation—not an unsafe
cherry-pick—was the correct consolidation result.

## MI350X validation from exact main

An isolated worktree of `9cec80a` was built on an AMD Instinct MI350X,
`gfx950:sramecc+:xnack-`:

- packed BV128 T=1024 prefill build: passed;
- packed-pair interleaved verify build (variant 17): passed;
- packed-pair decay/dot experimental build (variant 18): passed;
- promoted exact K0 build (variant 13): passed.

The real-checkpoint B64/M12, high-state-slot K0 gate on GPU 7 produced:

| Schedule | Raw median | Triton median | Speedup | Correctness |
|---|---:|---:|---:|---|
| variant 13, promoted exact | 124.321 us | 215.582 us | 1.7341x | bit-exact; 0/3,145,728 mismatches |
| variant 17, optional interleaved | 112.041 us | 208.641 us | 1.8622x | documented 163 mismatches; max abs 0.0009765625 |

The variant-17 result exactly reproduces the tolerance profile documented when
that optional schedule was accepted. Variant 13 remains the default because it
is bit-exact. No rejected schedule was enabled.

Post-audit update: a subsequent five-run 1K/1K DFlash serving gate measured a
2.868% mean end-to-end uplift for variant 17 at concurrency 128. Variant 17 was
therefore promoted to the build default later on 2026-08-16; variant 13 remains
the explicit bit-exact rollback. See
`gfx950-qwen36-gdn-interleaved-packed-verify.md` for the promotion evidence.

## Heads already contained by main

| Branch | Audited head |
|---|---|
| `codex/gqa4-batch256-gfx950` | `042a1d52b185` |
| `codex/qwen36-gfx950-integrated-20260803` | `bc13ca015bb9` |
| `codex/target-attention-int32-20260802` | `ca6eea102d75` |
| `experiments/gfx950-qwen36-attention-gate` | `664558bb0c22` |
| `feat/gfx950-qwen36-optimized-inference` | `f68aa60e282d` |
| `fix/gfx950-qwen36-harness-triton-abi` | `b9be8a9d6861` |
| `perf/gfx950-fmoe-direct-b` | `b107e88fddec` |
| `perf/gfx950-fmoe-g2lds` | `cda1a8949a2c` |
| `perf/gfx950-qwen36-dense-m768-qkvz` | `f72eb744e941` |
| `perf/gfx950-qwen36-deterministic-fmoe` | `12b72dd1f14e` |
| `perf/gfx950-qwen36-dflash-block12-argmax` | `8e9ff9f60bee` |
| `perf/gfx950-qwen36-dflash-down-m768` | `8e81e9c490a0` |
| `perf/gfx950-qwen36-dflash-gateup-bf16` | `442f20db9c4a` |
| `perf/gfx950-qwen36-gdn-fused-proj` | `5bdd6b279d50` |
| `perf/gfx950-qwen36-gdn-m8192-varlen` | `dd84998fa5ca` |
| `perf/gfx950-qwen36-gdn-prefill-conv` | `d2180dc7a499` |
| `perf/gfx950-qwen36-gdn-verify-schedule` | `ce39bd32d645` |
| `perf/gfx950-qwen36-gqa4-epilogue-screen` | `d3fd3c340b07` |
| `perf/gfx950-qwen36-moe-down-atomic` | `b958def07cf7` |
| `perf/gfx950-qwen36-moe-down-n256-fixed` | `a354e1ab510e` |
| `perf/gfx950-qwen36-moe-one-stage` | `5dd97474e23c` |
| `perf/gfx950-qwen36-moe-one-stage-source` | `a5bc32f2cc4d` |
| `perf/gfx950-qwen36-prefill-attention` | `eecf6f0ff2f2` |
| `perf/gfx950-qwen36-prefill-grouped-gqa8` | `f2ec63eb289f` |
| `perf/gfx950-qwen36-prefill-m128-exact` | `4a731f6a7a40` |
| `perf/gfx950-qwen36-qkvzba-split-copy` | `9815a643a7bd` |

`perf/gfx950-qwen36-attention-splitseq-m12` (`7c2779ad244e`) was not an
ancestor, but `git cherry` found zero unique patches; it was present by
patch-ID.

## Intentionally unpromoted experiment

`perf/gfx950-qwen36-gqa4-h2` (`f335d432cca1`) ends with a commit explicitly
rejecting its shared GQA4 reciprocal epilogue. Its results remain documented on
`main`, but its experimental source was not promoted.

## Local-only refs

The local-only heads `codex/gdn-causal-conv-m12-ship-local` (`d97c305f9000`)
and `gfx950-qwen36` (`6a98a96abcf7`) were ancestors of `main`. The remaining
local refs either matched the audited remote heads above or pointed at commits
already contained by `main`; none held an additional production kernel.

After this audit, every remote branch listed above was removed; `origin/main`
is the sole retained remote branch.
