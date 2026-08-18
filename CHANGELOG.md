# Changelog

This project follows semantic versioning for the compiler package and explicit
format versions for engine, graph-recipe, profile, and tactic manifests.

## Unreleased

### Added

- TensorRT-style ahead-of-time compiler foundation for gfx950/wave64.
- Immutable kernel contracts, typed graph IR, exact/bounded profiles, layout
  plans, static memory planning, and deterministic engine manifests.
- Model-independent fixed-tactic catalog and assembler-time template system.
- Stable C ABI HIP runtime with cached fixed launch records.
- Qwen compatibility and synthetic Gemma/Llama reuse demonstrations.

### Changed

- The locked Qwen3.6 gfx950 deployment is generated from modular templates.
- Generated gfx950 `.s`, object, HSACO, disassembly, and metadata files now
  belong under ignored build directories.

### Removed

- Obsolete checked-in gfx950 assembly instances and build entry points that
  depended on them.

## 0.2.0

- Initial deterministic Netra compiler package version.
