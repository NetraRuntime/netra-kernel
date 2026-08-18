# Kernel source layout

Architecture is a hard directory boundary. Code, contracts, and measurements
are never assumed portable between targets.

## gfx950

`kernels/gfx950/templates/` is the canonical wave64/CDNA4 source library. It is
organized by reusable mechanism and operation family:

```text
common/       ABI, metadata, kernargs, addressing, numerics, synchronization
dense/        FP8 block-scale dense schedules and compile-time epilogues
moe/          Routed FP8 gate/up, activation/quantization, and down/reduce
attention/    Fixed GQA and split-sequence verification schedules
routing/      Fixed router projections
gdn/          Recurrent-state, causal-convolution, verify, replay, and prefill
```

Leaf templates expose assembler macros. A compiler-generated translation unit
sets every contract and schedule constant, includes exactly one leaf, and
instantiates deterministic symbols. Generated `.s`, objects, code objects,
disassembly, and metadata belong under ignored `build/` directories.

Do not add model names to computational identities. Compatibility aliases may
appear only in deployment recipes. Do not add runtime shape branching to a
template; create another specialized tactic or schedule when the contract
differs.

## gfx1151

`kernels/gfx1151/` is the retained wave32/RDNA direct-assembly backend. Its
`decode`, `verify`, `prefill`, `lm_head`, `serving`, and operation-family
directories preserve their established ABI and validation workflow. These
sources are not valid gfx950 kernels and are not currently emitted by the
gfx950 compiler.

## Maturity and evidence

Filesystem location alone does not promote a gfx950 tactic. Maturity,
compatibility, fallback, and evidence are explicit catalog fields. Rejected
source instances may be removed after their negative evidence is retained.
See [adding a tactic](../docs/compiler/adding-a-tactic.md) and
[validation](../docs/compiler/validation.md).
