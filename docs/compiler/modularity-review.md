# Kernel-library modularity review

The library is modular enough to add a new model without copying most kernel
code when the model maps to an existing exact computational contract. It is
also structured to add a sibling schedule by reusing lower-level gfx950
primitives. It intentionally does not promise that a Qwen schedule can be
widened to arbitrary dimensions without new assembly or measurement.

The extension stack has five boundaries:

1. A model manifest or small frontend emits canonical IR. An explicit graph
   accepts a new family without changing Python dispatch.
2. Immutable semantic contracts remove Qwen/Gemma/Llama identity from tactic
   selection. Shape, ABI, dtype, quantization, layout, reduction, launch, and
   workspace must match exactly.
3. Target profile and layout registries are data. Unknown transforms and
   profiles fail clearly instead of choosing Qwen behavior.
4. Operation-oriented tactic leaves use generic primitives for module/ABI,
   kernargs, addressing, MFMA, reductions, numerics, synchronization, and GDN
   state. GDN verification/replay additionally share one full BV16 recurrent
   core.
5. Qwen-named symbols exist only in deployment compatibility recipes. Their
   `.s` translation units are generated under `build/`; no model-named assembly
   instance is checked into the library or defines computational identity.

For another model with an exact existing contract, expected work is a model
manifest, tensor bindings, checkpoint-layout mapping, exact profiles, and
validation. No assembly rewrite is needed. For a new shape using the same
schedule family, expected work is a short fixed leaf/parameter set plus build
and hardware gates. For a different ISA tile, layout, reduction order, or
numerical lifecycle, a sibling specialized schedule is required; shared
primitives still avoid rewriting boilerplate, but performance-critical code
must not be made dynamically generic.

Evidence supporting the assessment:

- A Llama-style explicit graph selected the existing MoE gate/up tactic with a
  model-independent generated symbol and no Python adapter.
- A generic recurrent graph selected the shared GDN state-replay tactic,
  generated a fixed M=12/B=1/wave1 engine, cross-assembled to the locked `.text`,
  and passed gfx950 module/profile loading.
- A layout-semantic mismatch with identical dimensions produced framework
  fallback.
- All 18 locked current-best artifacts remained byte-identical in `.text` and
  identical in normalized AMDHSA metadata after removing the checked-in
  instances. A five-fresh-process, fully substituted DP8 run was statistically
  indistinguishable from the locked serving baseline.

Remaining maintainability limits are explicit. The Netra SGLang deployment
adapter still owns Qwen-specific boundary mapping and must become semantic-ID
driven before a different model can use the same native integration without
server code. Large attention GQA4/GQA8 leaves share primitives but remain
distinct schedule bodies because their instruction streams differ materially.
Real checkpoint repacking is still delegated to the accepted loader; only
fixture transforms are CPU-tested. Bias/SiLU/GELU/gated-SiLU dense raw
epilogues and M=16/M=64 dense tactics remain unsupported. Gemma compilation is
synthetic and carries no numerical or performance acceptance. None of these
limitations changes the current Qwen default or its fallback.
