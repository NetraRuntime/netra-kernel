# Integrating another inference engine

Netra separates three contracts so an engine does not need SGLang internals:

1. `netra-compiler` emits a target-specific, deterministic engine directory.
2. `libnetra_engine.so.1` loads that directory through `<netra/engine.h>`.
3. An optional Python adapter activates engine-specific environment and checks
   compatibility through the `netra.inference_engines` entry-point group.

## Native integration

Install the SDK with CMake, then link `netra::netra_engine` or use
`pkg-config --cflags --libs netra-engine`. The ABI is plain C and its public
header does not include HIP, PyTorch, or SGLang headers. Callers pass their
native HIP stream as opaque `netra_stream_t`, and device pointers are bound by
numeric indices recorded in `engine.json`.

The [reference consumer](../examples/reference_engine/README.md) checks the
runtime ABI without importing any inference framework. `netra_kernel.Engine`
provides the same lifecycle for Python engines.

## Python deployment adapter

Expose one object under this package metadata:

```toml
[project.entry-points."netra.inference_engines"]
myengine = "myengine.netra:adapter"
```

The object implements `netra_kernel.InferenceEngineAdapter`: a stable `name`,
`check(configuration)`, and `activate(bundle, overwrite=False)`. Integration
configuration lives under `bundle.json` → `integrations` → `myengine`, so an
SGLang environment can never be applied accidentally to another engine.

```bash
netra-kernel integrations
netra-kernel check /srv/netra/bundle --integration myengine
netra-kernel run --bundle /srv/netra/bundle --integration myengine -- my-server
```

Bundle activation verifies every SHA-256 first and rejects absolute paths,
parent traversal, symlink escape, missing adapters, and incompatible adapters.
Adapters should only translate their framework boundary; kernel selection,
artifact integrity, native launch, and fallback semantics stay in Netra core.

## Compatibility and performance gate

An adapter is releasable only after numerical tests against the framework
fallback, negative shape/layout tests, graph replay, and matched A/B serving
runs from fresh processes. Report both the reference being compared and the
number of runs. “Stock base” is an image/source provenance description, not
proof that an unmodified framework is slower or faster.
