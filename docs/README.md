# Documentation

## Performance story

- [Qwen3.6 inference on AMD MI350X: 81.33K TPS, SGLang vs vLLM](blog/2026-08-22-qwen36-amd-mi350x-sglang-vllm-benchmark.md)
- [Qwen3.6 MI350X executive summary](retrospectives/gfx950-qwen36-20260821/EXECUTIVE-SUMMARY.md)
- [Full Qwen3.6 MI350X retrospective](retrospectives/gfx950-qwen36-20260821/REPORT.md)

## Compiler and runtime

- [Architecture](compiler/architecture.md)
- [Kernel contracts](compiler/kernel-contracts.md)
- [Engine directory format](compiler/engine-format.md)
- [Adding a model](compiler/adding-a-model.md)
- [Adding a tactic](compiler/adding-a-tactic.md)
- [Validation and promotion gates](compiler/validation.md)
- [Modularity review](compiler/modularity-review.md)

## Evidence

Machine-readable compatibility summaries are stored beside the compiler
documentation. Detailed development and negative-result records are retained
under `docs/notes/`. A result is evidence only for the exact target, contract,
checkpoint, server configuration, and measurement method it names.

## Project policies

- [Contributing](../CONTRIBUTING.md)
- [Security](../SECURITY.md)
- [Support](../SUPPORT.md)
- [Governance](../GOVERNANCE.md)
- [Code of conduct](../CODE_OF_CONDUCT.md)
- [Release process](../RELEASING.md)
