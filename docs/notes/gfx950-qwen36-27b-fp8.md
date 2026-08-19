# Qwen3.6-27B-FP8 on gfx950

Status: framework-compatible engine, disabled by default

Qwen3.6-27B-FP8 is represented by the real
`Qwen/Qwen3.6-27B-FP8` checkpoint at revision
`e89b16ebf1988b3d6befa7de50abc2d76f26eb09`. The revision-tree SHA-256 is
`80fa5ef34e3beec2b0a5ae835ff24a85dedd7b4fb2dba5742bf47d18c63c02f5`,
and the exact `config.json` SHA-256 is
`885e6830f8d6883fefd63e3608c267452da2e6ce353a3494f42a7aa3d70c8434`.

The text model is dense and hybrid. It has 64 layers in a repeating sequence
of three Gated DeltaNet layers followed by one full-attention layer. Its
hidden size is 5120, dense MLP size is 17408, and maximum position count is
262144. Full attention uses 24 query heads, 4 KV heads, head dimension 256,
and an output gate. GDN uses 16 key heads of dimension 128, 48 value heads of
dimension 128, and a width-4 causal convolution. The checkpoint includes one
MTP layer.

Weights use FP8 E4M3 with dynamic activation quantization and 128 by 128
weight blocks. Checkpoint scale tensors are BF16. SGLang widens them to FP32
during model loading. Projection shards are concatenated on the output axis
and then shuffled once into the AITER 16 by 16 weight layout. Activation
scales use AITER's transposed K-block-major storage. No weight transformation
occurs in the request path.

The model manifest is
`manifests/gfx950/models/qwen36-27b-fp8.json`. It expands six layer templates
into 256 bound dense projections and deduplicates them into five exact
computational contracts for each profile. The contracts contain no model
name.

The observed single-GPU serving shapes are decode M=1 during warmup, decode
M=16 for the concurrency-16 measurement, prefill M=80 during warmup, and
prefill M=256 plus M=3840 for the matched 16-request wave. Exact profiles bind
those shapes and their observed batch counts. Bundled MTP warmup reached an
exact verification shape of M=4 before the unmodified framework failed in its
AITER attention metadata path. `verify_m4_b1` records that shape. The engine
keeps MTP and speculative serving on the framework; the dFlash-12 deployment
below serves them through the verified raw-kernel bridge instead.

## Verified HV48 GDN verification tactics

The dFlash block-12 deployment uses two model-independent gfx950 tactics from
`manifests/gfx950/tactics/gdn_hv48_assembly.json`, both at maturity
`verified`:

- `gdn_verify_precompute_m12_qk_hv48` builds the QK-only normalization
  precompute from
  `kernels/gfx950/templates/gdn/verify/precompute_qk_hv48.inc`. The recurrent
  gate pairs come from an exact framework precompute, so the lane-zero gate
  block is omitted.
- `gdn_verify_core_m12_bv16_hv48_k0` builds the K0 recurrent verification core
  from `kernels/gfx950/templates/gdn/verify/recurrent_bv16_hv48_core.inc`
  with variant 13 arithmetic, one wave per workgroup, an FP32 initial state,
  and a 1.5 MiB HV48 state-pool slot.

Both templates pin the 48-value-head contract. The locked HV32 templates used
by the accepted Qwen3.6-35B tactics are byte-identical to their pinned catalog
hashes; the accepted tactic set is pinned by
`tests/compiler/test_current_best_assembly.py`.

The build entry point is
`tools/build/build_gfx950_qwen36_27b_gdn_verify_m12_batched.sh`. It compiles
the deployment manifest
`manifests/gfx950/deployments/qwen36-27b-gdn-verify-m12-hv48.json`, verifies
the locked executable text hashes recorded from the serving artifacts, copies
`precompute.hsaco` and `core.hsaco` into the serving layout, and builds
`libqwen36_27b_gdn_verify_m12_batched_bridge.so` from
`runtime/gfx950/linear_attention/verify/`. The synthetic correctness and
latency gate is `tools/benchmark/qwen36_27b_gdn_verify_m12_batched_synthetic.py`.

Hardware evidence for the verified maturity is recorded under
`/data/netra/benchmarks/gfx950_qwen36_27b/20260818-dflash12-gdnhv48-attnm16-tuned-gpu7`.
Fixed-prompt captures `deterministic-hv48.json` and
`deterministic-fp32state.json` show identical output tokens and identical
12-bin acceptance histograms across the kernel variants. The locked
concurrency-128 measurement with three warmup waves reached 2314.46 output
tokens/s with mean dFlash acceptance 3.667. The tactics are not accepted and
the engine keeps them out of the default path until the remaining serving
gates pass.

No accepted Qwen3.6-35B tactic matches these five projection shapes. The 27B
engine therefore retains `framework.aiter` for all dense projections and
records the remaining embedding, vision, normalization, activation, GDN,
attention, MTP, and sampling boundaries as explicit fallbacks. This is
intentional. No 35B tactic or rank is changed.

Build a decode engine with:

```bash
PYTHONPATH=compiler python3 -m netra_compiler.cli compile \
  --model manifests/gfx950/models/qwen36-27b-fp8.json \
  --target gfx950 \
  --profile decode_m1 \
  --checkpoint-hash 80fa5ef34e3beec2b0a5ae835ff24a85dedd7b4fb2dba5742bf47d18c63c02f5 \
  --output build/qwen36-27b-fp8/decode_m1
```

Build the exact concurrency-16 serving profile by replacing `decode_m1` with
`decode_m16_b16` and selecting a different output directory.

Validate a staged checkpoint without loading its tensor payloads:

```bash
python3 tools/checkpoint/inspect_qwen36_27b_fp8.py \
  /data/netra/models/Qwen3.6-27B-FP8 \
  --output build/qwen36-27b-fp8/checkpoint-inspection.json
```

## Validation status

All six observed profiles compiled and passed static validation on gfx950.
Each engine contains 267 explicit framework fallbacks and no specialized
code object. Compiling the primary `decode_m16_b16` engine twice produced
byte-identical semantic outputs. Its engine ID is
`ne_f70a65a84efb0dce83555986`.

Real-checkpoint serving passed model loading, exact guards, full HIP graph
capture and replay, short boundary token checks, and direct state comparison.
The framework control and shadow engine produced byte-identical prefill and
two-step decode logits, GDN intermediates and recurrent state, and raw FP8 KV
cache tensors for the inspected layers. These results establish guarded
framework compatibility, not a Netra kernel speedup.

Five matched fresh-process serving pairs measured 740.74 output tokens/s for
the framework control and 738.50 output tokens/s for shadow mode. The paired
difference was -0.302 percent with a 95 percent confidence interval from
-6.516 to +2.034 output tokens/s. The interval crosses zero, so no performance
promotion is claimed.

Two gates remain failed. Long repeated generation was nondeterministic in the
unmodified framework control, and bundled EAGLE/MTP warmup failed in the
framework AITER attention metadata path before measurement. The engine is
therefore not accepted or promoted. All operations remain on the framework,
and the server integration remains disabled unless
`SGLANG_NETRA_ENGINE_MODE` is explicitly set.

The Qwen3.6-35B catalog remains the primary proven deployment. Its rebuilt 18
code objects retained all locked assembly text hashes and 19
specializations. Full code-object container bytes may vary with the linker,
so preservation is gated on executable text and validated metadata rather
than container identity. Five clean fresh-process runs of the patched server
with the locked current-best deployment averaged 80,444.27 output tokens/s,
compared with the locked 78,748.15 output tokens/s mean. All five met the
canonical target and passed request, token, cache, error, and dFlash checks;
mean dFlash acceptance was 5.5220. One additional attempt with a 23.9-second
system stall is preserved separately and excluded from the clean aggregate.
The locked `CURRENT_BEST.json` hash remained unchanged.
