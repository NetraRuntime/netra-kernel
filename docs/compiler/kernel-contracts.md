# Kernel contracts and tactics

A contract is an immutable computational identity containing target/wave,
operation and M/N/K, four dtypes, quantization and scale blocks, three layouts,
epilogue, schedule, launch, LDS, workspace, graph/determinism properties, and
the numerical rules for accumulation, rounding, reduction, and NaNs. Its
`nk_…` identifier hashes canonical sorted JSON. Model names, timestamps,
absolute paths, evidence, and machine details do not affect the identifier, so
Qwen and Gemma can share an exact contract.

Launch identity keeps fixed code-object LDS and dynamic launch LDS distinct.
Both are compile-time constants; neither can vary on the request path.

Tactic maturity is `experiment`, `verified`, `accepted`, or `rejected`.
Rejected tactics are never selected. Experimental tactics require an explicit
compiler opt-in, but opt-in does not override `rejected`. Ranking is a stable
rank/name ordering after exact predicate and graph/determinism filtering.
`explain.json` records every selected and rejected candidate and its reasons.

The dense slice preserves FP8 E4M3 inputs/weights, per-128 activation scales,
128×128 weight scales, FP32 fixed-order accumulation, and one final RNE BF16
store. Identity is the only implemented raw dense epilogue. Bias, SiLU, GELU,
and gated-SiLU are represented in the IR and capability table but remain
unsupported experiments rather than fake assembly.

The current Qwen raw dense sources are rejected despite isolated BF16 and graph
correctness: matched serving regressed. Their evidence and exact status come
from `docs/notes/gfx950-qwen36-fp8-kernels.md`.

Non-dense fixed-assembly contracts use the same identity rules with a general
representation: family, operation, immutable constants, concrete build
specialization, versioned ABI/dtype/quantization/layout/numerical identifiers,
kernarg size, fixed launch/workspace, graph and determinism properties,
maturity, and fallback. Compatibility symbols and model evidence are
provenance and are excluded from computational identity. Renaming a template
or include also does not change the computational hash; changing normalized
assembler semantics does.
