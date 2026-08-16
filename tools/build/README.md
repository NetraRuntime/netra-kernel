# Build system

Kernel build scripts are deliberately separate from runtime code. Refactoring
this directory must not change assembler definitions, compiler/linker flags,
or generated HSACO and bridge-library bytes without a new correctness and
performance qualification.

## Production profiles

`build_production.sh` is the model-neutral entrypoint. Data-only profiles
compose reusable shape/dtype/layout contracts from an architecture component
registry. The current MI350X Qwen3.6 profile pins the promoted GDN variant 17,
lossless K0, dynamic wavegroups, target GQA8 FP8-KV attention, router, and raw
FP8 decode components.

```text
build_production.sh
  -> profiles/<architecture>_<model>_<mode>.sh   (composition only)
  -> components/<architecture>/<contract>.sh     (loadable adapters)
  -> build_<architecture>_<contract>.sh          (compiler flags/assertions)
  -> kernels/ + runtime/ + harness/               (implementation)
```

```bash
tools/build/build_production.sh list-profiles
tools/build/build_production.sh gfx950-qwen36-dflash contracts
tools/build/build_production.sh gfx950-qwen36-dflash all
```

Set `NETRA_BUILD_ROOT` to build into an isolated comparison directory. The
individual component builders remain implementation entrypoints. Add another
model as a composition profile; do not copy the runner or an entire build
stack. See [`profiles/README.md`](profiles/README.md) and
[`components/README.md`](components/README.md).

## Shared primitives

- `lib/gfx950_assembly.sh` owns the repeated gfx950/wave64 assemble, link,
  disassemble, and metadata-validation sequences.
- `lib/gdn_variants.sh` is the single source for human-readable GDN
  variant names and assembler IDs.
- `lib/component_registry.sh` discovers independent contract adapters and
  rejects invalid or duplicate registrations.

Kernel-specific builders retain all flags and disassembly assertions in plain
view. A shared helper must never infer or silently add optimization flags.

## Performance-preserving refactors

For a build-system-only refactor, build the same component from the parent and
candidate revisions on the same host and ROCm installation, then compare every
`.hsaco` and `.so` by SHA-256. Byte-identical artifacts are the acceptance
criterion; benchmark reruns are required whenever they differ.
