# gfx950 Netra engine runtime

This library loads deterministic `netra-engine-1` manifests during
initialization, verifies gfx950/wave64 ownership, the declared minimum ROCm
runtime, and code-object ABI, rejects non-normalized HSACO paths, allocates any
declared static workspace, loads selected HSACOs, resolves every `hipFunction_t`,
and builds fixed numeric profile records. Bindings use numeric
operation/argument indices. Optional HIP graphs are captured only after stable
pointers have been bound; graph binaries are not serialized in the engine.

`netra_engine_launch` performs an exact/bounded numeric guard and device-owner
check, then invokes a cached graph executable or the fixed direct launch list on
the caller's stream. It performs no allocation, synchronization, filesystem or
environment access, JSON parsing, module loading, string lookup, tactic
selection, or registry mutation. A fallback-only compatibility profile returns
`NETRA_STATUS_FALLBACK_REQUIRED` without launching an approximate kernel.
`netra_engine_launch_operation` applies the same guards to one numeric fixed
operation record for staged interception at existing framework boundaries.
It performs no tactic or symbol lookup. Typed scalar constants and static
workspace pointers are installed during initialization; only declared boundary
and persistent pointer slots can be rebound.
`netra_engine_launch_operation_bound` accepts a fixed caller-owned array of all
declared boundary pointers, validates each numeric slot, builds a caller-local
kernel-argument pointer array, and submits the cached handle in one C ABI
crossing. It never mutates the engine's stable pointer record. It has no
allocation, parsing, string/map lookup, module work, or synchronization.

The manifest's `lds_bytes` is fixed code-object resource metadata.
`dynamic_lds_bytes` is a separate field and is the only LDS value supplied to
`hipModuleLaunchKernel`; fixed LDS must never be allocated a second time as
dynamic shared memory. The Qwen compatibility engine binds its existing
SGLang-owned graph-stable intermediates and therefore requires zero device
workspace.

Binding, `netra_engine_finalize_bindings`, and graph preparation are an
externally serialized initialization lifecycle. Direct launches are rejected
until finalization makes their records immutable. Bound operation launches use
only caller-local pointer storage, so concurrent calls cannot mix bindings.
Callers must
serialize launches of the same graph executable unless their HIP version
documents concurrent use. Error retrieval is per-engine and should be
externally serialized. Destruction refuses while a launch call is in flight;
callers must also externally quiesce submitted stream work and all control-plane
calls.
