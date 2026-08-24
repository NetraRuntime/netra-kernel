# Netra Compiler package

This directory contains the installable `netra-compiler` Python package.

```bash
python3 -m pip install ./compiler
netra-compile list-tactics --target gfx950
```

The wheel carries its version-matched schemas, tactic catalogs, model
manifests, profiles, tuning data, and assembly templates under
`netra_compiler/library_data`. An explicit `--library-root` remains available
for developing a checkout or auditing a separately versioned catalog; it never
silently overrides the packaged library.

The compiler core has no mandatory third-party runtime dependencies. Target
implementations are resolved through the `CompilerBackend` registry; gfx950 is
the first registered backend rather than an import embedded in the planner.
