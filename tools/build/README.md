# Build system

Kernel build scripts are deliberately separate from runtime code. Refactoring
this directory must not change assembler definitions, compiler/linker flags,
or generated HSACO and bridge-library bytes without a new correctness and
performance qualification.

## Production MI350X bundle

`build_gfx950_qwen36_production.sh` is the canonical bundle entrypoint for the
Qwen3.6 DFlash serving stack. It pins the promoted GDN variant 17, lossless K0,
dynamic wavegroups, target GQA8 FP8-KV attention, router, and raw FP8 decode
components.

```bash
tools/build/build_gfx950_qwen36_production.sh list
tools/build/build_gfx950_qwen36_production.sh all
tools/build/build_gfx950_qwen36_production.sh gdn-verify-m12-k0
```

Set `NETRA_BUILD_ROOT` to build into an isolated comparison directory. The
individual component builders remain the development entrypoints; do not add a
second production bundle for a new experiment.

## Shared primitives

- `lib/gfx950_assembly.sh` owns the repeated gfx950/wave64 assemble, link,
  disassemble, and metadata-validation sequences.
- `lib/qwen36_gdn_variants.sh` is the single source for human-readable GDN
  variant names and assembler IDs.

Kernel-specific builders retain all flags and disassembly assertions in plain
view. A shared helper must never infer or silently add optimization flags.

## Performance-preserving refactors

For a build-system-only refactor, build the same component from the parent and
candidate revisions on the same host and ROCm installation, then compare every
`.hsaco` and `.so` by SHA-256. Byte-identical artifacts are the acceptance
criterion; benchmark reruns are required whenever they differ.
