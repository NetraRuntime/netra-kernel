# Engine directory format

`engine.json` is the load manifest. It contains format/target/ABI requirements,
model and optional checkpoint hashes, TP degree, profiles, operations, selected
tactics, fixed launch data, workspace size, fallbacks, validation status, and a
compiler source hash. Deterministic outputs contain no timestamps.

Sibling files separate contracts, canonical graph, graph recipe, memory plan,
layout/repack plan, symbols, validation plan, and tactic explanations.
`generated/*.s` contains specialized wrappers. `generated/includes/` is the
closed, hash-recorded include tree and `generated/golden/` contains preserved
comparison sources, never runtime-selected copies. `hsaco/*.hsaco` and
`metadata/*.dis` exist only after a successful ROCm build. For refactored
candidates, build also emits `metadata/*.text`, golden disassembly/metadata,
and `metadata/*.equivalence.json`; build fails if `.text` or resources differ.
Repeated compilation to different directories produces byte-identical semantic
files.

The stage-1 Qwen engine records AITER operations as
`framework_fallback`; it cannot accidentally launch a rejected raw candidate.
Unsupported profiles and operations return structured fallback results.

Accepted existing objects use `golden_external_hsaco` contracts. Each record
stores the code-object SHA-256, symbol, kernarg size, ordered typed arguments,
fixed grid/block/LDS, maturity, source and evidence. `--golden-artifact-root`
copies an object only after its bytes match. Pointer arguments explicitly name
either a caller binding or a deterministic static-workspace offset; scalar
arguments are compile-time profile constants. The three-operation Stage-2 Qwen
M1 MoE engine used this format without framework fallbacks.

Launch metadata distinguishes code-object fixed `lds_bytes` from
`dynamic_lds_bytes`. The former is resource evidence and is already reserved by
the raw code object; the runtime passes only the latter to HIP. Temporary
arguments may explicitly request `caller_binding` when preserving an existing
graph-stable server allocation is part of the compatibility contract.

The Stage-3 server compatibility engine extends that artifact with explicit
`server_fallback` records for the active router, attention, GDN, and MoE
dispatch policy. Numeric operation launches may select the accepted kernel
subset even though a whole-profile launch returns fallback-required. This lets
one deterministic manifest represent the active mixed stack without copying or
reloading server-owned code objects and without pretending unsupported work is
compiled.

The runtime C ABI lives under `runtime/gfx950/engine`. Initialization owns all
filesystem access, parsing, module/symbol resolution, workspace allocation, and
optional graph capture. After bindings are frozen, launch does no allocation,
synchronization, file/environment access, parsing, module load, string lookup,
tactic selection, or mutable registration. It checks the current device and
exact/bounded numeric profile, then uses cached handles on the caller stream.
