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
computational contracts for each profile. For block-8 verification it also
expands 52 exact fixed assembly contracts for the observed graph buckets
through batch 192. Repeated layer use shares these contracts while retaining
per-layer weight and state bindings. The contracts contain no model name.

The observed single-GPU serving shapes are decode M=1 during warmup, decode
M=16 for the concurrency-16 measurement, prefill M=80 during warmup, and
prefill M=256 plus M=3840 for the matched 16-request wave. Exact profiles bind
those shapes and their observed batch counts. Bundled MTP warmup reached an
exact verification shape of M=4 before the unmodified framework failed in its
AITER attention metadata path. `verify_m4_b1` records that shape. The engine
keeps MTP and speculative serving on the framework. The dFlash block-8
deployment below serves selected GDN operations through an opt-in raw-kernel
bridge instead. `verify_m8` records its exact eight-token verification window,
batch range 1 through 128, and sequence bound 32768. A separate observed
`verify_m8_b129_192` profile records batches 129 through 192. The optimized
model manifest pins dFlash block size 8, draft window 2048, zero mamba cache
steps, BF16 state, and full graph batches 1, 2, 4, 8, 16, 32, 64, 80, 96, 112,
128, 160, and 192. Server integration remains disabled by default, so this
does not alter framework behavior unless explicitly enabled.

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
identity. They remain at maturity `verified`. Their five-process 27B serving
soak passed, while the final 35B preservation rerun is still pending.

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
Matched c128 serving nevertheless regressed from 3307.72 to 3206.81 output
tokens/s with FP32 state and to 3220.31 output tokens/s with BF16 state. The
acceptance-normalized changes were -1.05 and -1.45 percent. The tactic remains
verified and opt-in, and is not a serving promotion candidate.

BF16-state evidence is under
`/data/netra/benchmarks/gfx950_qwen36_27b/20260820-bf16state`. The block-12
experiment was bitwise exact against its BF16-pool reference, reduced VRAM by
about 9.1 GB, and improved same-window throughput by 3.7 percent with flat
acceptance. The exact block-8 BF16 core and replay artifacts are bitwise exact
in eager execution and HIP graph replay at batches 1, 32, 128, and 256. A
matched serving screen improved from 3307.72 to 3391.88 output tokens/s, or
+2.54 percent raw and +3.02 percent after acceptance normalization, while the
state pool fell from 18.14 to 9.07 GB. Five fresh BF16-state processes measured
3375.76, 3425.77, 3445.78, 3457.64, and 3440.14 output tokens/s. Their mean was
3429.02 with standard deviation 31.90 and mean dFlash acceptance 3.1464. This
is +4.30 percent raw and +3.12 percent acceptance-normalized over the prior
five-process FP32-state mean. All 1920 requests passed. The tactics remain
disabled by default and are not accepted until the final 35B preservation
gate passes.

The BF16-state c192 throughput profile was subsequently measured with the full
1319-question GSM8K test set using OpenAI chat requests, natural EOS, seed
20260803, and numeric answer scoring. Five fresh-process c128 and c192 pairs
alternated arm order. Across 13,190 requests, c128 averaged 5710.44 output
tokens/s and c192 averaged 6381.33 output tokens/s. The paired improvement was
11.75 percent with a 95 percent confidence interval from 10.41 to 13.09
percent. Mean numeric accuracy was 96.39 percent at c128 and 96.59 percent at
c192. The paired accuracy interval crossed zero, so no quality change is
claimed. Mean acceptance length was 5.5828 and 5.5865 respectively. All ten
fresh processes loaded, captured their full HIP graph ladders, completed every
request, and had no fatal server errors.

This profile is throughput-oriented. Median TTFT increased by 15.93 percent
and median TPOT increased by 31.87 percent. Keep c128 for lower latency. Use
c192 only when aggregate throughput is the priority. The c192 profile uses
TP1, DP1, BF16 recurrent state, maximum running requests 192, client
concurrency 192, and graph batches 1, 2, 4, 8, 16, 32, 64, 80, 96, 112, 128,
160, and 192. Its pinned summary is
`/data/netra/benchmarks/gfx950_qwen36_27b/20260820-gsm8k/bf16-c128-c192-five-fresh-r1/summary.json`
with SHA-256
`ed34b53f83733f37678fded570c9d2a01e6375d1e5a0cb730ad33b7feb0e1786`.

No accepted Qwen3.6-35B tactic matches these five projection shapes. The 27B
engine therefore retains `framework.aiter` for all dense projections and
records embedding, vision, unsupported GDN, unsupported attention, MTP, and
sampling boundaries as explicit fallbacks. No 35B tactic or rank is changed.

## Fixed assembly fusion ownership

All Netra-owned fused normalization, activation, and group-quant compute is
implemented by model-independent gfx950 assembly templates in
`kernels/gfx950/templates/activation/verify/` and
`kernels/gfx950/templates/norm/verify/`. The seven verified schedules cover:

- residual add plus RMSNorm plus FP8 group quant at width 5120, with distinct
  FP32-weight and BF16-weight contracts;
- SiLU multiply plus FP8 group quant at width 17408, with and without a BF16
  output store;
- gated RMSNorm plus FP8 group quant at width 128 and 48 heads, with one, two,
  or four rows per workgroup.

The row dimension uses an explicit bounded contract from 1 through 8192
tokens. Width, dtype, layouts, quantization, scale interpretation, numerical
order, ABI, workspace, and graph properties remain fixed. Gated RMSNorm uses
three non-overlapping bounded schedules for the exact 256-compute-unit MI350X:
1 through 10 tokens use one row per workgroup, 11 through 21 use two, and 22
through 8192 use four. The bridge rejects other compute-unit counts. Requests
outside these bounds use the framework fallback. This coverage includes the
irregular prefill batches produced by the c192 GSM8K serving workload while
keeping schedule selection deterministic and model-independent.

The original measured sources are retained only as pinned historical Git
blobs at revision `0e0f97dfee142bee398cd0795d163f82cc591f36`. They are not
runtime sources. Instantiating the templates reproduced the originating
code-object executable text byte for byte on gfx950. The tactics remain
`verified` until the post-migration serving and 35B regression campaigns pass.

Build the seven artifacts and the graph-safe launch bridge on a ROCm host with:

```bash
python3 tools/build/build_gfx950_group_quant_assembly.py \
  --output build/gfx950-group-quant-assembly
```

The measured AITER GEMM selections are also owned and packaged by this
repository. They are model-neutral exact-key tables, not Netra compute
kernels. The selected AITER assembly, CK, and CK Tile implementations remain
explicit framework fallbacks. Build the deterministic package with:

```bash
python3 tools/build/build_gfx950_gemm_tuning_package.py \
  --output build/gfx950-gemm-tuning
```

The package records gfx950, 256 compute units, every exact selection key, and
the SHA-256 of all six tables used by the 27B and preserved 35B deployments.
The server validates `package.json`, the exact inventory, and every table hash
before startup. No model name participates in a selection key.

The bridge performs initialization and symbol lookup before graph capture.
Its launch functions only check the bounded profile and fixed schedule range,
update stable arguments, and launch on the caller-owned stream. The launch path has no allocation,
filesystem access, environment lookup, module loading, symbol lookup, tactic
selection, or synchronization.

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
`decode_m16_b16` and selecting a different output directory. Build the
assembly verification engine with profile `verify_m8` or the c192 ceiling
with profile `verify_m8_b129_192`.

Validate a staged checkpoint without loading its tensor payloads:

```bash
python3 tools/checkpoint/inspect_qwen36_27b_fp8.py \
  /data/netra/models/Qwen3.6-27B-FP8 \
  --output build/qwen36-27b-fp8/checkpoint-inspection.json
```

## Validation status

All eight required profiles compiled and passed static validation on gfx950.
The block-8 verification engine contains 52 exact fixed assembly operations
and 267 explicit framework fallbacks. Two independent c192 builds produced 76
byte-identical semantic files. Both `engine.json` files have SHA-256
`6bcd01b9d0e2345b3931be40f648b15d8ec06685e66c00115d93eccfeb7c71d8`.

The seven modular group-quant artifacts built on the supplied 256-compute-unit
MI350X with all locked executable-text hashes identical. Metadata validation
passed for gfx950, wave64, kernarg size, launch dimensions, VGPR, SGPR, AGPR,
LDS, and private segment. Boundary tests at 10, 11, 21, and 22 tokens were
bitwise identical to the former Triton oracle in eager execution and graph
replay. Repeated graph replay was bitwise stable.

Five fresh-process natural-EOS GSM8K runs of the best dFlash block-8, BF16
state, BF16-weight fused add-RMSNorm quantization, GQA6 M=8, c192 stack
measured 6360.07, 6622.10, 6467.57, 6510.44, and 6369.54 output tokens/s.
Mean throughput was 6465.94 output tokens/s with standard deviation 108.25,
mean acceptance 5.5837, and mean numeric accuracy 96.41 percent. All 6595
requests completed without serving errors. This is 2.81 percent above the
prior modular five-process mean of 6289.03 output tokens/s. One additional
post-migration GSM8K run, using the kernel-owned tuning package after removal
of all server table copies, measured 6428.18 output tokens/s and completed all
1319 requests. The tactics remain `verified` and opt in while the full engine
still contains explicit framework fallbacks.

The engine additionally guards the exact dFlash checkpoint repository,
revision, config hash, weights hash, block size, draft window, mamba cache
steps, state type, and graph ladder. Hardware shadow validation for full
engine replacement is `not_run`. Serving used the verified fixed assembly
fusions through the guarded SGLang bindings.

The earlier non-speculative fallback-only engine passed real-checkpoint model
loading, exact guards, full HIP graph capture and replay, short boundary token
checks, and direct state comparison. Its framework control and shadow engine
produced byte-identical prefill and two-step decode logits, GDN intermediates
and recurrent state, and raw FP8 KV cache tensors for the inspected layers.
These historical results establish guarded framework compatibility, not a
Netra kernel speedup for the updated dFlash engine.

Five matched fresh-process serving pairs measured 740.74 output tokens/s for
the framework control and 738.50 output tokens/s for shadow mode. The paired
difference was -0.302 percent with a 95 percent confidence interval from
-6.516 to +2.034 output tokens/s. The interval crosses zero, so no performance
promotion is claimed.

Two gates remain failed. Long repeated generation was nondeterministic in the
unmodified framework control, and bundled EAGLE/MTP warmup failed in the
framework AITER attention metadata path before measurement. The engine is
therefore not accepted or promoted. Unsupported operations and profiles remain
on the framework, and engine mode remains disabled unless
`SGLANG_NETRA_ENGINE_MODE` is explicitly set.

The Qwen3.6-35B catalog remains the primary proven deployment. Its latest
rebuild retained all locked assembly text hashes across 18 code objects and
19 specializations. Full code-object container bytes may vary with the linker,
so preservation is gated on executable text and validated metadata rather
than container identity. Five clean fresh-process runs of the patched server
with the locked current-best deployment averaged 80,444.27 output tokens/s,
compared with the locked 78,748.15 output tokens/s mean. All five met the
canonical target and passed request, token, cache, error, and dFlash checks;
mean dFlash acceptance was 5.5220. One additional attempt with a 23.9-second
system stall is preserved separately and excluded from the clean aggregate.
The locked `CURRENT_BEST.json` hash remained unchanged. DP8 serving was
`not_run` by instruction.

After the 27B migration, five additional fresh-process single-GPU 35B runs
used the exact throughput128, dFlash-12, B128 deployment. They measured
11415.36, 11304.09, 10159.75, 11256.39, and 11462.40 output tokens/s. The mean
was 11119.60 output tokens/s with mean acceptance 5.5821. All 1920 requests
completed with exactly 1024 output tokens and no request errors. This is 11.14
percent above the locked single-GPU mean. The final fixed B128 configuration
guard also completed graph capture after freezing its environment-derived
contract before request launch. The machine-readable summary is
`/data/netra/benchmarks/gfx950_qwen36_27b/20260821-qwen36-35b-regression-r23/five-fresh/summary.json`
with SHA-256
`af4216cf927cb85b0df7b28db4a39222d0dbe85b5d430f14362cf43dc85b39bb`.
