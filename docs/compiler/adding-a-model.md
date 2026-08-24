# Adding a model

Prefer an explicit `netra-model-1` JSON description. A Qwen adapter maps named
dense projections to model-independent operations; repeated layer contracts
deduplicate automatically while each layer retains distinct weight bindings.
Recognized Hugging Face `config.json` files may be inspected without importing
Transformers, but arbitrary PyTorch execution is intentionally not imported.

An explicit canonical `graph` is the zero-code frontend for a new model family.
Its `family` string may be new; no Python dispatch entry is required. Describe
each reusable fixed operation with a model-independent tactic family, operation,
integer compile-time constants, five versioned semantic identifiers (ABI,
dtypes, quantization, layouts, numerical behavior), exact launch grid, typed
kernargs, and fallback. Complete examples are:

```text
tests/compiler/fixtures/llama-moe-gate-up-exact.json
tests/compiler/fixtures/generic-gdn-state-replay-exact.json
```

If an exact registered contract exists, the planner emits the same specialized
binary without carrying the model name into its symbol or contract identity.
If any semantic identifier or constant differs, compilation records a
structured fallback. Equal dimensions alone never authorize reuse.

For Gemma, provide hidden/intermediate dimensions, dtype, quantization, scale
blocks, checkpoint and kernel layouts, and TP degree. Do not infer checkpoint
dimensions. The synthetic fixture demonstrates gate/up/down construction and
reuse of one exact Qwen-compatible identity contract; mismatched epilogues and
shapes fall back and remain unvalidated.

Checkpoint layout → deterministic initialization/offline repack → kernel
layout → consumer output layout is explicit in `layout_plan.json`. The tested
CPU fixture transform is separate from the real AITER shuffle hook. A new
checkpoint transform must gain byte/layout tests and real checkpoint evidence
before being labeled validated.

Profiles are JSON files in `manifests/<target>/profiles`. Add an exact profile
when launch geometry depends on the guarded value. A bounded profile is valid
only when every selected kernel has one fixed safe launch for the full bound;
otherwise compile one exact engine profile per graph bucket.

To add another Qwen operation, add its explicit manifest entry, numerical
rules, layout binding, exact server guard, and fallback. To add Gemma, start
from `tests/compiler/fixtures/gemma-dense-synthetic.json`, replace every
synthetic field with checkpoint-derived values, and retain fallback until the
hardware plan passes.
