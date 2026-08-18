# Netra Kernel

[![CI](https://github.com/NetraRuntime/netra-kernel/actions/workflows/ci.yml/badge.svg)](https://github.com/NetraRuntime/netra-kernel/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-3776AB.svg)](compiler/pyproject.toml)

Netra Kernel is a fixed-contract GPU kernel library, ahead-of-time compiler,
and lightweight runtime for AMD GPUs. The first compiler backend targets
`gfx950`/wave64 and emits specialized raw-assembly code objects and loadable
Netra Engine directories.

The core rule is:

> Generic at authoring and compilation time; completely specialized at runtime.

Netra does not generate a dynamically generic serving kernel. Shape, layout,
dtype, quantization, schedule, launch dimensions, workspace, and epilogue are
resolved before serving. The runtime retains direct `hipFunction_t` handles,
fixed metadata, stable workspace addresses, caller-owned HIP streams, and exact
profile guards.

## Project status

| Area | Status | Notes |
|---|---|---|
| gfx950 compiler and engine format | Functional vertical slice | CPU/static testable without ROCm |
| gfx950 fixed tactic catalog | 14 tactics, 19 specializations | Model-independent computational identities |
| Qwen3.6-35B DP8 compatibility | Hardware validated | 18/18 `.text` and normalized metadata matches |
| Gemma frontend | Synthetic/static validation | No performance or checkpoint-acceptance claim |
| gfx1151 direct-assembly backend | Retained | Separate wave32 kernel track; not managed by the gfx950 compiler |

The retained Qwen3.6 serving result averaged 78,498.66 output token/s across
five fresh processes versus the locked 78,748.15 token/s baseline. The -0.32%
mean difference was not statistically distinguishable from run-to-run noise.
Every request, input, output, token, cache, dFlash, and error check passed. See
[the machine-readable validation record](docs/compiler/gfx950-qwen36-modular-serving-validation-20260818.json).

This evidence establishes compatibility, not a universal performance claim.
Results are architecture-, checkpoint-, profile-, and server-configuration
specific.

## Architecture

```text
model/configuration
        |
        v
typed graph IR -- exact profiles -- layouts/repack recipes
        |
        v
closed kernel contracts -- tactic filtering/ranking
        |
        v
assembler-time template instantiation
        |
        v
Netra Engine directory
  engine.json + graph recipe + generated source + optional HSACO
        |
        v
initialization: parse, load, resolve, bind, allocate, capture
        |
        v
hot path: exact guard -> cached launch record -> caller stream
```

Model names do not participate in computational contract identity. Qwen,
Gemma, Llama, or another frontend may reuse a tactic only when every semantic
and assembler-time field matches exactly. Unsupported contracts return a
structured fallback result.

The Qwen compatibility symbols and locked hashes live in a deployment recipe,
not in generated computational identity. HIP graphs are represented as
deterministic recipes and instantiated during engine initialization; they are
not advertised as portable serialized graph binaries.

Read the [compiler architecture](docs/compiler/architecture.md),
[kernel contract format](docs/compiler/kernel-contracts.md), and
[engine format](docs/compiler/engine-format.md) for the complete design.

## Repository layout

```text
compiler/netra_compiler/       Python compiler library and CLI
  backends/gfx950/             Catalog, code generation, metadata, build
  frontends/                   Explicit JSON, Qwen, Gemma, recognized HF config
kernels/gfx950/templates/      Reusable wave64 assembly templates/includes
manifests/gfx950/
  tactics/                     Model-independent tactic catalogs
  deployments/                 Compatibility symbols and locked artifacts
  models/                      Model/deployment descriptions
  profiles/                    Exact and bounded shape profiles
runtime/gfx950/engine/         Stable C ABI and HIP engine runtime
schemas/                       Model, profile, contract, and engine schemas
tests/compiler/                CPU-only compiler/runtime contract tests
tools/compiler/                Build, inspect, validate, and repack tools
docs/compiler/                 Architecture and contributor documentation

kernels/gfx1151/              Retained direct wave32 assembly backend
runtime/gfx1151/               Retained gfx1151 runtime
harness/                       Hardware correctness/timing programs
tools/{build,benchmark,...}/   Retained target-specific laboratory tools
docs/notes/                    Historical and current measurement evidence
```

Checked-in gfx950 deployment kernels are templates (`.inc`), not generated
`.s`, object, HSACO, disassembly, or metadata files. Generated artifacts belong
under ignored `build/` directories. The gfx1151 backend intentionally retains
its direct `.s` sources and must not be interpreted as gfx950-compatible.

## Quick start: CPU-only compiler development

Python 3.10 or newer is required. The compiler core uses the standard library.

```bash
git clone https://github.com/NetraRuntime/netra-kernel.git
cd netra-kernel

python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e ./compiler

make check
```

List registered tactics:

```bash
python -m netra_compiler.cli list-tactics \
  --target gfx950 --library-root .
```

Compile and inspect a deterministic Qwen dense compatibility engine:

```bash
python -m netra_compiler.cli compile \
  --model manifests/gfx950/models/qwen36-dense.json \
  --target gfx950 --profile decode_m1 \
  --library-root . \
  --output build/netra-engines/qwen36-dense

python -m netra_compiler.cli explain \
  --engine build/netra-engines/qwen36-dense

python -m netra_compiler.cli validate \
  --engine build/netra-engines/qwen36-dense \
  --static --library-root .
```

Compile the synthetic Gemma graph:

```bash
python -m netra_compiler.cli compile \
  --model tests/compiler/fixtures/gemma-dense-synthetic.json \
  --target gfx950 --profile decode_m1 \
  --library-root . \
  --output build/netra-engines/gemma-dense-synthetic
```

`--library-root` makes the installed Python package independent of checkout
layout while explicitly locating schemas, catalogs, profiles, and templates.

## Build gfx950 artifacts

Cross-assembly requires a ROCm toolchain but does not require a visible GPU:

```bash
ROCM_DIR=/opt/rocm \
  bash tools/compiler/build_gfx950_tactic_catalog.sh \
  build/gfx950-tactic-catalog
```

The build targets `amdgcn-amd-amdhsa`, uses `-mcpu=gfx950`, checks wave64 and
architecture metadata, emits disassembly and metadata, and rejects any locked
`.text` mismatch.

Build the engine runtime separately:

```bash
ROCM_DIR=/opt/rocm \
  bash tools/compiler/build_netra_engine_runtime_gfx950.sh \
  build/gfx950-engine-runtime
```

A visible gfx950 GPU is required only for module loading, correctness,
determinism, graph replay, profiling, and performance measurements. Follow the
[hardware validation guide](docs/compiler/validation.md). Never report a
hardware gate as passed when only cross-assembly or static validation ran.

## Tactic maturity

- `experiment`: opt-in only; never selected by default.
- `verified`: passed stated correctness gates but lacks complete deployment
  acceptance.
- `accepted`: valid only for its exact recorded contract and evidence scope.
- `rejected`: never selected, even when experimental tactics are enabled.

Compatible fixed tactics require an explicit measured rank. Equal-rank matches
are rejected as ambiguous. Unknown constants and semantic fields are rejected
rather than ignored. A fallback remains mandatory until all correctness, graph,
determinism, and serving gates pass.

See [adding a tactic](docs/compiler/adding-a-tactic.md) and
[adding a model](docs/compiler/adding-a-model.md).

## Contributing

Contributions are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md) and
the [Code of Conduct](CODE_OF_CONDUCT.md). Kernel pull requests must state the
exact contract, maturity, fallback, correctness oracle, graph result, and
performance methodology. A microbenchmark improvement alone is not sufficient
for promotion.

Use GitHub Issues for reproducible defects and bounded kernel proposals. Use
private vulnerability reporting for security-sensitive reports; see
[SECURITY.md](SECURITY.md). General support expectations are in
[SUPPORT.md](SUPPORT.md).

## License

Netra Kernel is released under the [MIT License](LICENSE).
