# Qwen3.6-27B-FP8 on gfx950

Status: framework-compatible engine and verified raw T8 tactics, disabled by default

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
keeps MTP and speculative serving on the framework. The dFlash block-8
deployment below serves selected GDN operations through an opt-in raw-kernel
bridge instead.

## Verified HV48 GDN verification tactics

The catalog retains the verified dFlash block-12 tactics and adds exact
block-8 variants for the current deployment. All are model-independent gfx950
tactics in `manifests/gfx950/tactics/gdn_hv48_assembly.json`. The current
block-8 contracts use:

- A T=8 specialization of `gdn_verify_precompute_m12_qk_hv48` for the
  QK-only normalization precompute. The recurrent gate pairs come from an
  exact framework precompute, so the lane-zero gate block is omitted.
- A T=8 specialization of `gdn_verify_core_m12_bv16_hv48_k0` for the K0
  recurrent verification core, with variant 13 arithmetic, one wave per
  workgroup, and an FP32 initial state.

Two additional block-8 contracts use a BF16 recurrent state pool:

- `gdn_verify_core_t8_bv16_hv48_k0_bf16_state`
- `gdn_state_replay_t8_bv16_hv48_bf16_state`

They are separate from the FP32-state contracts because state type,
accumulation, storage, ABI, and replay semantics are part of computational
identity. They remain at maturity `verified` with serving soak pending.

The Qwen3.8 GDN projection and Conv1D fusion was adapted only as an operator
pattern. The 27B checkpoint has a different exact contract: T=8, QKV=10240,
QKVZ=16384, BF16 input and output, width-4 causal convolution, and 48 value
heads. The new `gdn_qkvz_conv_t8_d10240` tactic uses the generic symbol
`netra_gdn_qkvz_conv_t8_d10240_gfx950`, a 256-thread block, and a
`(40, batch, 1)` grid. It does not reuse the accepted 35B T=12, QKV=8192,
QKVZ=12288 contract.

The locked HV32 templates used by accepted Qwen3.6-35B tactics remain
byte-identical to their pinned catalog hashes. The accepted tactic set is
pinned by `tests/compiler/test_current_best_assembly.py`.

The build entry point is
`tools/build/build_gfx950_qwen36_27b_gdn_verify_m12_batched.sh`. It compiles
the FP32 block-12 and block-8 deployments plus the BF16-state block-8 and
QKVZ-Conv1D deployments. It verifies locked executable text hashes, copies
the artifacts into separate `t8/` and `t8-bf16/` serving layouts, and builds
`libqwen36_27b_gdn_verify_m12_batched_bridge.so` from
`runtime/gfx950/linear_attention/verify/`. Synthetic gates live under
`tools/benchmark/qwen36_27b_gdn_*_synthetic.py`.

The current block-8 five-process baseline is recorded under
`/data/netra/benchmarks/gfx950_qwen36_27b/20260820-blk8-fresh-process-five-rep`.
It measured 3246.51, 3257.92, 3309.78, 3316.49, and 3308.34 output tokens/s,
for a mean of 3287.81 and standard deviation of 32.88 output tokens/s. Mean
dFlash acceptance was approximately 3.1.

Operator evidence for the new QKVZ-Conv1D contract is under
`/data/netra/benchmarks/gfx950_qwen36_27b/20260820-upstream-qkvz-t8`. It was
bitwise exact against the Triton oracle in eager execution and HIP graph
replay at batches 1, 32, 128, and 256. At batch 128 its catalog artifact
measured 33.941 microseconds versus 44.141 microseconds, a 1.3005x operator
speedup. Two independent builds produced identical source, executable text,
code-object bytes, and normalized metadata. The artifact is gfx950 wave64
with kernarg size 64, 33 VGPRs, 34 SGPRs, no LDS, and no private segment.

Prior BF16-state evidence is under
`/data/netra/benchmarks/gfx950_qwen36_27b/20260820-bf16state`. The block-12
experiment was bitwise exact against its BF16-pool reference, reduced VRAM by
about 9.1 GB, and improved same-window throughput by 3.7 percent with flat
acceptance. The exact block-8 BF16 artifacts now build deterministically, but
their matched serving and block-8 operator gates are not run yet. The tactics
are not accepted and remain disabled by default.

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
