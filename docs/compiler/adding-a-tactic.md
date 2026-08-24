# Adding a gfx950 tactic

Add a tactic predicate, immutable relative source path, fixed symbol/launch,
workspace, graph/determinism properties, compile parameters, maturity, and
evidence references to the gfx950 registry. A source does not become eligible
because it builds or wins a microbenchmark.

Assembly templates may use `.set`, `.if`, macros, and relative `.include`
files. They may not load shape/schedule/epilogue parameters or branch on them at
runtime. Keep fundamentally different schedules separate and share only clear
lower-level macros. Only the selected compile-time epilogue may remain in the
machine code.

For an existing Qwen golden kernel, first create an engine that references the
unchanged artifact. Extract a template only after byte-identical `.text` or
normalized instruction identity and identical metadata/resources/kernargs.
Then require real-capture correctness, deterministic graph replay, and paired
serving performance. Never delete the hand-written golden during migration.

Production fixed-contract tactics live under operation-oriented paths such as
`kernels/gfx950/templates/moe`, `attention`, and `gdn`. Their macro names,
template paths, and contract constants must be model-independent. Put a legacy
model symbol only in a deployment compatibility-build recipe; the compiler
generates its `.s` translation unit under `build/`. Add the template to
`manifests/gfx950/tactics/*.json`; add a deployment compatibility recipe only
when the tactic is part of a locked serving stack
deployment evidence; the manifest pins historical source revision/hash and
template plus transitive include-closure hashes separately. Give it a
model-independent `family` used by frontends and an exact leaf ID used by the
planner. Keep filenames and macro names short and semantic; place the complete
shape/layout/wave/numerical contract in the manifest and `NETRA_REQUIRE_EQ`
guards. `load_fixed_tactic_catalog()` derives its exact matching predicate from
those guards. A new contract may reuse an existing family and primitive
library, but new dimensions require a measured leaf specialization or tactic
when they change the schedule; never widen the runtime kernel with a shape
branch.

Declare `launch_block` explicitly. It is either a positive fixed integer or a
`{"constant": ..., "multiplier": ...}` rule whose constant is an enumerated
compile definition. The compiler resolves the rule into one fixed block per
contract. Do not substitute AMDHSA `max_flat_workgroup_size`; that field only
limits legal launches. The launch grid must likewise be concrete in the model
operation/profile.

Classify every proposed parameter before exposing it:

- Put semantic identity in the typed contract: exact dimensions, dtypes,
  quantization blocks, layouts, epilogue, numerical order, launch, and
  workspace.
- Put a parameter in `compile_definitions` only when the leaf explicitly
  validates a finite set of assembler-time values and each value emits a fixed
  symbol/code object. Record that allowed set in the tactic manifest.
- Put legacy model-specific names only in deployment `symbol` fields. They are
  ABI aliases, not tactic names, source filenames, or selection inputs.
- Create a sibling leaf when a value changes MFMA tiling, wave cooperation,
  memory layout, reduction order, or target-architecture instruction sequence.

Macro parameters containing symbol names are not necessarily multiple code
object exports. If assembler-time conditions choose one entry point, advertise
only the emitted symbol and register a separate typed contract for an alternate
ABI.

This keeps authoring reusable without pretending that one schedule is optimal
for every model or architecture. Qwen, Gemma, and Llama may share a binary only
when their model-independent contracts match exactly; otherwise their frontends
reuse the family and primitive library while the compiler chooses a separately
validated specialization.

Promotion proceeds experiment → verified → accepted only with machine-readable
evidence. Any correctness, token, routing/state, graph, memory, load-time, or
paired performance failure leaves the tactic opt-in or rejected and preserves
framework fallback.
