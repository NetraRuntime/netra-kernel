# gfx1151 raw-kernel layout consolidation — 2026-07-31

Status: **accepted, performance-neutral, measured on gfx1151**.

The accepted host runtime boundary already lives under `runtime/gfx1151/`, but
24 tracked raw AMDGCN sources still remained under
`scripts/rocm/kernels/gfx1151/`. This change moves those production and
experimental `.s` files into their architecture-owned locations under
`kernels/gfx1151/`:

- attention experiments: `kernels/gfx1151/attention/experiments/`;
- GDN production and experiments: `kernels/gfx1151/gdn/`;
- MXFP4 prefill: `kernels/gfx1151/mxfp4/prefill/`;
- MXFP4 M12 verification: `kernels/gfx1151/mxfp4/verify/`.

Only paths and build-script references changed. No raw instruction, metadata,
symbol, launch geometry, kernarg, weight layout, runtime dispatch, SGLang
contract, stream, or graph behavior changed. Two pre-existing ignored `.orig`
files in the old directory were preserved and are not part of the repository.

## Equivalence gates

Every result below is measured on AMD Ryzen AI Max+ PRO 395 (`gfx1151`).

| Gate | Result |
|---|---:|
| Moved source SHA-256 | 24/24 identical |
| Production HSACO SHA-256 | 45/45 byte-identical |
| Production disassembly | identical because every HSACO is byte-identical |
| Public `netra_*` exports | 30/30 exact set |
| Production build | passed in a clean separate output directory |
| Moved experiment builds | 6/6 scripts passed |
| Non-default stream output | bit-exact, identical FNV-1a hash `0xcb1ab68861542b43` |
| Captured graph nodes | 1 old, 1 new |

The existing dispatch A/B harness used 50,000 host samples and 201 HIP-event
samples per library:

| gfx1151 measured metric | Old | New | Delta |
|---|---:|---:|---:|
| eager host median | 0.822 us | 0.821 us | -0.122% |
| eager host p90 | 1.012 us | 0.962 us | -4.941% |
| eager GPU median | 93.174 us | 93.335 us | +0.173% |
| graph host median | 2.184 us | 2.144 us | -1.832% |
| graph host p90 | 2.615 us | 2.334 us | -10.746% |
| graph GPU median | 97.302 us | 97.182 us | -0.123% |
| graph GPU p90 | 99.507 us | 99.547 us | +0.040% |

The host and GPU differences are within or better than the established 1%
performance-neutrality gate, except improvements. Since the code objects are
identical, no serving rerun is needed to establish GPU-kernel equivalence for
this path-only move; the existing real-checkpoint runtime-refactor correctness
and serving evidence remains applicable.

Reproduction inside Netra:

```bash
out=$(mktemp -d /tmp/netra-gfx1151-layout.XXXXXX)
scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh "$PWD" "$out"
build/runtime-refactor/benchmark_runtime_dispatch_ab \
  build/sglang/libnetra_mxfp4_sgl.so "$out/libnetra_mxfp4_sgl.so" 50000
```
