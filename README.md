# Netra Kernel

[![CI](https://github.com/NetraRuntime/netra-kernel/actions/workflows/ci.yml/badge.svg)](https://github.com/NetraRuntime/netra-kernel/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-3776AB.svg)](compiler/pyproject.toml)

**Ahead-of-time GPU kernels for production inference on AMD.**

Netra Kernel compiles model operations into fixed-contract raw-assembly
kernels and packages them as loadable **Netra Engines**. It brings a
TensorRT-style workflow—profiles, tactics, layout planning, static memory
planning, and engine building—to native AMD GPU kernels.

> Compile for the exact serving contract. Launch only specialized kernels at
> runtime.

The first production backend targets `gfx950`/wave64, with a focus on
high-throughput FP8 inference for large language models.

[Get started](#get-started) ·
[Explore the architecture](docs/compiler/architecture.md) ·
[Read the engine format](docs/compiler/engine-format.md) ·
[Contribute](CONTRIBUTING.md)

## What Netra delivers

- **Native performance without a model-locked codebase.** Kernels remain
  schedule-specific raw assembly, while contracts and templates make proven
  mechanisms reusable across compatible Qwen, Gemma, Llama, and future model
  operations.
- **Predictable serving.** Shapes, data types, layouts, quantization, launch
  dimensions, LDS, workspaces, and epilogues are resolved ahead of time.
- **A minimal hot path.** Engine initialization loads modules, resolves
  symbols, binds stable memory, and optionally captures HIP graphs. Serving
  reuses cached handles on a caller-owned stream.
- **Safe specialization.** Exact profile guards prevent approximate dispatch.
  Unsupported contracts return an explicit framework fallback.
- **Evidence-based optimization.** Tactics carry maturity, numerical
  semantics, deterministic ranking, and correctness and performance evidence.

Netra is intentionally not one dynamically generic GPU kernel. Generality
lives in the compiler and kernel library; generated machine code is fully
specialized.

## Proven on Qwen3.6-35B

The initial production target is Qwen3.6-35B-A3B-FP8 serving on eight AMD
MI350X GPUs.

| Deployment | Result |
|---|---:|
| 8× MI350X, DP8, dFlash | **78,498.66 output tokens/s mean** |
| Exact request/input/output/token/cache checks | **15,360 / 15,360 passed** |
| Generated versus locked kernel `.text` | **18 / 18 identical** |

The modular engine result was within 0.32% of the locked 78,748.15 tokens/s
baseline and passed the no-regression statistical gate. These numbers describe
this exact checkpoint, hardware topology, graph configuration, request set,
and five-run measurement; they are not a universal performance claim.

See the
[machine-readable serving validation](docs/compiler/gfx950-qwen36-modular-serving-validation-20260818.json)
and [validation methodology](docs/compiler/validation.md).

## The Netra platform

```text
Model or canonical graph
          │
          ▼
  Netra Compiler
  contracts · profiles · layouts · tactics · memory plan
          │
          ▼
  Specialized raw assembly + Netra Engine
  fixed symbols · fixed launches · graph recipe · fallbacks
          │
          ▼
  Netra Runtime
  cached HIP handles · stable bindings · caller-owned stream
```

### Compiler

The Python compiler accepts an explicit model description or canonical graph,
validates its numerical and layout semantics, selects compatible tactics, and
emits deterministic engine artifacts. The core compiler has no mandatory
third-party Python dependencies.

### Kernel library

The gfx950 library is organized into reusable assembler includes and focused
schedule templates for routed MoE, attention, routing, GDN, and dense
operations. Tactic parameters are assembler-time constants; specialization
never introduces runtime shape branches.

### Netra Engine

An engine contains contracts, selected tactics, launch metadata, static memory
and layout plans, generated sources, optional code objects, and a deterministic
HIP graph recipe. Engine output is reproducible and contains no semantic
timestamps or machine-specific build paths.

### Runtime

The HIP runtime exposes a stable C ABI for loading an engine, querying profiles,
binding persistent and boundary buffers, and launching on a caller-provided
stream. Direct fixed launches remain available when graph capture is disabled.

## Supported today

| Capability | Current support |
|---|---|
| GPU target | AMD `gfx950`, wave64 |
| Accepted operation families | FP8 routed MoE, BF16 routing, GQA FP8-KV attention, split-sequence verification, and GDN |
| Specialization profiles | Decode and fixed verification/prefill profiles used by the catalog |
| Quantization focus | FP8 E4M3 with explicit block-scale and layout semantics |
| Model inputs | Canonical JSON graph, Qwen adapter, and explicit model manifests |
| Reuse demonstrations | Synthetic Gemma and Llama configurations |
| Runtime modes | Direct fixed launches and initialization-time HIP graph recipes |

Gemma and Llama currently demonstrate model-independent contract reuse; they
are not advertised as checkpoint- or performance-accepted deployments. The
separate `gfx1151` wave32 kernel track remains available but is not emitted by
the gfx950 compiler.

## Reuse without compromise

A model name is never part of a computational kernel identity. Reuse happens
only when the complete contract matches:

- operation and exact dimensions;
- data types, accumulation, rounding, and reduction order;
- quantization and scale interpretation;
- tensor and weight layouts;
- ABI, launch dimensions, LDS, and workspace;
- graph-capture and determinism requirements;
- compile-time epilogue and schedule parameters.

When those fields match, different model frontends can select the same tactic
and binary. When they do not, the compiler emits another specialized instance
or preserves the framework fallback. This keeps the library extensible without
making the runtime kernel generic.

## Get started

CPU-only compiler development requires Python 3.10 or newer. ROCm is needed
only to build gfx950 code objects.

```bash
git clone https://github.com/NetraRuntime/netra-kernel.git
cd netra-kernel

python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e ./compiler
make check
```

List the available gfx950 tactics:

```bash
netra-compile list-tactics --target gfx950 --library-root .
```

Compile a Qwen3.6 routed-MoE operation into a specialized gfx950 engine:

```bash
netra-compile compile \
  --model examples/gfx950/qwen36-moe-gate-up.json \
  --target gfx950 \
  --profile decode_m1 \
  --library-root . \
  --output build/netra-engines/qwen36-moe-gate-up

netra-compile explain \
  --engine build/netra-engines/qwen36-moe-gate-up

netra-compile validate \
  --engine build/netra-engines/qwen36-moe-gate-up \
  --static \
  --library-root .
```

The result includes a deterministic manifest, graph and memory recipes,
selected contract, stable symbol, and specialized assembly translation unit
under `build/netra-engines/qwen36-moe-gate-up/`. The example is synthetic and
does not require checkpoint files; its dimensions and semantics match the
accepted Qwen3.6 decode tactic exactly.

## Build for gfx950

Cross-assemble the locked tactic catalog with ROCm Clang and LLVM tools. A
visible GPU is not required for this step.

```bash
ROCM_DIR=/opt/rocm \
  bash tools/compiler/build_gfx950_tactic_catalog.sh \
  build/gfx950-tactic-catalog
```

Build the reusable HIP engine runtime:

```bash
ROCM_DIR=/opt/rocm \
  bash tools/compiler/build_netra_engine_runtime_gfx950.sh \
  build/gfx950-engine-runtime
```

Hardware correctness, determinism, graph replay, and performance promotion
require a visible gfx950 device. Follow the
[hardware validation guide](docs/compiler/validation.md).

## Tactic maturity

- **Experiment:** opt-in development candidate.
- **Verified:** passed its recorded correctness gates but not full deployment
  acceptance.
- **Accepted:** approved only for the exact contract and evidence scope.
- **Rejected:** retained as evidence when useful and never selected.

A faster microbenchmark alone does not promote a tactic. Numerical behavior,
graph replay, full serving correctness, and matched end-to-end performance are
part of the acceptance contract.

## Documentation

- [Compiler architecture](docs/compiler/architecture.md)
- [Kernel contracts](docs/compiler/kernel-contracts.md)
- [Engine directory format](docs/compiler/engine-format.md)
- [Adding a model](docs/compiler/adding-a-model.md)
- [Adding a tactic](docs/compiler/adding-a-tactic.md)
- [Validation and promotion](docs/compiler/validation.md)

## Contributing

Netra Kernel is open source under the MIT License. Contributions to the
compiler, runtime, documentation, model frontends, validation infrastructure,
and fixed-contract kernel library are welcome.

Read [CONTRIBUTING.md](CONTRIBUTING.md), the
[Code of Conduct](CODE_OF_CONDUCT.md), and the
[security policy](SECURITY.md) before opening a change.

## License

[MIT](LICENSE) © Netra contributors
