# Contributing to Netra Kernel

Thank you for helping improve Netra Kernel. This project accepts compiler,
runtime, documentation, validation, and fixed-contract kernel contributions.
Correctness and a safe fallback take priority over isolated speed results.

## Before opening a change

1. Search existing issues, tactic catalogs, and retained negative-result notes.
2. Open a kernel proposal issue for a new contract, ABI, layout, or schedule.
3. Keep changes scoped to one target and one clearly stated objective.
4. Never include checkpoints, captures, credentials, proprietary data, or
   generated build artifacts in a commit.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
Report security issues privately as described in [SECURITY.md](SECURITY.md).

## Development setup

The CPU/static development path requires Python 3.10 or newer and no GPU
framework dependencies:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e ./compiler
make check
```

ROCm and a visible GPU are optional for CPU compiler work. Cross-assembly needs
ROCm Clang and LLVM tools. Hardware execution needs a compatible device.

## Change categories

### Compiler, manifest, or runtime changes

- Add focused CPU tests for contract validation and deterministic output.
- Preserve deterministic JSON ordering and stable identifiers.
- Keep initialization work out of the launch path.
- Update schemas and format documentation together.
- Return a structured fallback for unsupported profiles.

### New model frontend

- Accept dimensions, dtype, quantization, layout, activation, and parallelism
  from explicit configuration.
- Produce model-independent contracts.
- Do not copy an existing model adapter and rename it.
- Use a clearly labeled synthetic fixture if no redistributable checkpoint is
  available.
- Do not claim checkpoint correctness or performance without running it.

### New or modified tactic

Document all of the following:

- target architecture and wave size;
- complete shape/profile constraints;
- dtype, quantization, scale, and layout semantics;
- kernarg ABI and fixed launch dimensions;
- LDS and workspace requirements;
- numerical contract, reduction order, and rounding points;
- graph-capture and determinism requirements;
- fallback implementation;
- maturity and evidence references;
- explicit measured rank relative to every equivalent tactic.

Every performance-sensitive choice must be an assembler-time constant. Do not
add runtime shape branches to make a tactic appear reusable. Reuse belongs in
templates, contracts, and compiler specialization.

## Kernel promotion gates

Promotion is contract-specific. In increasing order of strength:

1. assembler and include-closure validation;
2. byte-identical `.text`, or normalized instruction identity;
3. identical metadata, resources, kernarg, and launch contract;
4. independent correctness oracle on representative and edge inputs;
5. repeated determinism and native graph replay;
6. framework-boundary shadow comparison;
7. matched, repeated, interleaved serving A/B;
8. token, routing, state, memory, and latency acceptance.

If an applicable gate is not run, record `not_run`; never infer or fabricate a
result. Rejected tactics remain unselectable. Negative evidence may be retained
as documentation without retaining an obsolete source instance.

## Pull requests

Before requesting review:

```bash
make check
git diff --check
```

The pull request template asks for contract, correctness, graph, and
performance evidence. Keep generated objects under `build/`; do not commit
`.o`, `.hsaco`, disassembly, metadata, captures, or benchmark scratch files.

Reviewers may require hardware evidence for a kernel change even when CPU CI
passes. CPU CI verifies compiler and repository invariants; it does not certify
GPU correctness or performance.

## Commit style

Use an imperative subject with a focused prefix when useful, for example:

```text
compiler: reject ambiguous fixed-tactic ranks
gfx950: add exact M16 GQA specialization
docs: record matched serving rejection
```

Do not rewrite or remove another contributor's evidence without explaining why
it is obsolete and preserving any required audit trail.
