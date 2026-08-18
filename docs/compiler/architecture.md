# Netra compiler architecture

The Qwen3.6-35B Netra SGLang deployment is the compatibility baseline. The
compiler is generic in its model/IR/planning layers, but a runtime kernel is
never generic: every shape, dtype, scale block, layout, epilogue, schedule,
symbol, kernarg, grid, block, LDS use, and workspace offset is fixed before the
engine is served.

The implemented vertical slice covers migration stage 1/2 plus a gated dense
template-extraction path. It reads
an explicit model description, creates a model-independent typed dense graph,
applies an exact profile, ranks immutable tactics, emits an engine directory,
and loads numeric records through the gfx950 C ABI. The ten Qwen full-attention
output-projection bindings deduplicate to one computational contract. A second
Qwen manifest represents the deployed accepted M=1 MoE gate/up, SiLU+quant,
and two-wave down/reduce objects as immutable golden tactics. Compilation may
materialize those existing HSACOs only after their SHA-256 values match.

The deployed AITER dense M=1 operation is the accepted compatibility tactic.
The one-wave and four-wave-LDS raw sources stay `rejected`, but they now have
real assembler-time templates under `kernels/gfx950/templates`. Compilation
emits model-independent fixed-contract wrappers, a closed include tree, and a
hash-checked copy of each untouched experimental source. Cross-assembly proved
byte-identical `.text`, identical resources/kernargs/launch contracts, 0/2,048
BF16 mismatches, 0/200 nondeterministic launches per run, and exact 20-replay
HIP graphs. This equivalence does not override their previous 4.51% and 10.02%
serving regressions, so neither candidate is selected or promotion-eligible.
The assembly used by the locked current-best deployment is now expressed as 14
model-independent fixed-contract tactic templates and 18 concrete build
specializations. Compatibility `.s` files are generated only into `build/`;
model names are excluded from the checked-in assembly tree and tactic identity. Every template rejects a
mismatched gfx950/wave/shape/layout schedule at assembly time. The compiler
catalog derives immutable constants from those guards and matches only exact
contracts, so another model may reuse a tactic without inheriting a Qwen
identity. Cross-assembly produced byte-identical `.text` and semantically
identical AMDHSA metadata for all 18 specializations. Full HSACO byte identity
is not claimed because non-text ELF identity changed. The existing accepted
golden HSACOs remain the deployed artifacts until a generated-engine hardware
A/B passes.

Assembly naming has three intentional levels. Shared primitives are generic
and namespaced (`NETRA_LOAD_KERNARG_*`, `NETRA_MFMA_*`,
`NETRA_GDN_UPDATE8_F32`); tactic families are model-independent names such as
`moe.fp8_block128`, `attention.gqa_fp8kv`, `attention.splitseq_fp8kv`, and
`gdn.recurrent_bv16`; leaf files and public macros use short schedule names
such as `gqa8_fp8kv.inc` and `NETRA_GDN_RECURRENT_PACKED_PAIR`. Exact details
such as `M12/H16/K128`, packing, wave count, layout, and numerical ordering live
in typed contract fields, `NETRA_REQUIRE_EQ` assembler guards, and the tactic
manifest. A `qwen36_*` name appears only as a compatibility symbol in a
deployment recipe needed by the current server. Other frontends select the family plus
exact contract and receive either the same leaf tactic or a structured
fallback.

Compiler specialization has three categories. **Contract constants** (shape,
dtype, quantization, layout, accumulation/reduction rules, tile geometry, and
fixed launch resources) describe one leaf and are not request-time knobs.
**Validated build options** are small enumerated assembler-time choices exposed
by that leaf, currently including GQA8 indirection-pointer width and the locked
GDN one/four/eight-wave builds; each choice produces a distinct symbol and
fixed code object. **Compatibility aliases** preserve existing server ABI names
but do not affect computational identity. A model or architecture frontend may
choose among supported build options through the compiler. If it needs a value
outside the validated set, or if the target ISA/tile/reduction schedule changes,
the backend must provide and validate a sibling specialized leaf in the same
family. None of these choices becomes a runtime GPU branch.

Every production leaf includes the common primitive umbrella. GDN adds shared
causal-convolution and recurrent-state primitives; verification and state
replay now use one `gdn/common/recurrent_bv16_core.inc` schedule body behind
thin fixed-batch/public-name leaves, while prefill retains its different
schedule. Attention keeps GQA and split-sequence schedules separate. This is
the extension boundary: reuse ABI, addressing,
MFMA, numerical, reduction, synchronization, state, and layout pieces, but add
a new measured leaf when tile geometry or instruction ordering fundamentally
changes. The compiler hashes the complete transitive include closure, so a
change to any shared primitive deterministically invalidates source-integrity
and build hashes. Stable computational identity separately hashes normalized
instructions/metadata and excludes comments, DWARF paths, compatibility
aliases, and model names.

Compilation flows through frontend → IR → profile → layout plan → tactic
planner → static memory plan → specialized template instantiation/preserved
golden artifact → engine
manifest. Initialization parses the engine once, validates gfx950/wave64 and
device ownership, allocates stable workspace, resolves selected symbols, binds
stable pointers, and may instantiate a HIP graph recipe. Launch performs only a
numeric profile guard and cached graph/direct launch on the caller stream.
Golden operation records also expose a numeric fixed-operation launch for
compatibility interception at existing server boundaries. Direct records
become immutable at binding finalization; bound launches use caller-local
kernarg storage, so concurrent calls cannot mix pointers. Neither path does
allocation, parsing, module work, filesystem access, or string lookup.

The Qwen compatibility engine deliberately reuses SGLang's existing
graph-stable gate/up FP32, activation FP8, and activation-scale tensors. Those
intermediates are explicit caller bindings, so the accepted serving path keeps
the same addresses and the engine needs zero device workspace. This is a
compatibility decision, not a universal layout: future standalone graphs may
own deterministic static intermediates when their performance gate passes.

Fixed code-object LDS and HIP dynamic LDS are separate launch fields. A raw
kernel's `lds_bytes` is validated against AMDHSA metadata; only
`dynamic_lds_bytes` is passed as `sharedMemBytes` to `hipModuleLaunchKernel`.
Conflating the two changes the launch/resource contract and is rejected by
tests.

The graph recipe is deterministic data, not a supposedly portable serialized
HIP graph. HIP graphs are captured and instantiated against process-local
modules and pointers after binding.

Target profiles are registry data under `manifests/gfx950/profiles`.
Shape/quantization guards and priority are not duplicated in compiler logic;
`tensor_parallel: deployment` binds the profile to the model deployment.
Profiles feeding kernels whose grid depends on batch need an exact batch guard
(for example `verify_m12_b1`) or a separately proven max-grid masking contract.
AMDHSA `max_flat_workgroup_size` is a ceiling, not the launch block: the tactic
manifest fixes the block directly or derives it from a finite assembler-time
wave choice.

Current limitations: the accepted MoE graph has passed module load, synthetic
replay, retained real-checkpoint operand equivalence, and the locked five-run
full routed DP8 serving contract. Every serving repetition audited that the
engine runtime was mapped in all eight workers. The engine mean was 79,204.73
output token/s versus the locked 78,748.15 baseline (+0.58%), with every exact
request/token/cache/error check passing. One engine run (74,665.90 token/s) was
below the previous minimum, however, and this was a historical sequential
comparison rather than a paired/interleaved promotion trial. Complete
routing/logits/state, dispatch/allocation, and matched load-time inventories
also remain outstanding, so the server default is unchanged and engine mode is
opt-in. M=16 and M=64 dense profiles currently fall back; raw
bias/SiLU/GELU/gated-SiLU dense epilogues are not validated; the real AITER
repack stays with its validated checkpoint loader; and the synthetic Gemma
fixture is not performance evidence.
