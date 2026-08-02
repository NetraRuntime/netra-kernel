# gfx950 Qwen3.6 FlashQLA-derived fused prefill v1

Date: 2026-08-02

Target: one MI350X, `gfx950`, wave64, Qwen3.6-35B-A3B FP8 E4M3
weights, BF16 GDN state, exact `B=1,T=8192,H=32,Hg=16,K=V=128,BT=64`.

QwenLM FlashQLA commit `821fd9d37ede18fdc2a4e707fefe3770bfc32e58`
was used as an algorithmic reference. Its NVIDIA TileLang execution machinery
was not ported. The raw compute experiment in this repository was re-derived
for CDNA4 wave64 and uses `v_mfma_f32_16x16x32_bf16`.

## Correctness localization

The first raw version was invalid. Real-checkpoint stage diagnostics found and
fixed three independent hand-scheduling/addressing defects:

- dependent consumers of `v_exp_f32` needed explicit scheduling distance;
- BF16 values reconstructed with `v_lshl_or_b32` needed distance before MFMA;
- `LOAD_VNEW_B` clobbered the live gated-QK LDS pointer, so the second AV
  reduction half read the wrong LDS region.

After correction, the exact first 64-token chunk has bit-exact final state over
524,288 BF16 elements. Output differs in two BF16 subnormal elements out of
262,144, with maximum absolute error `1.9073486328125e-6`, cosine `1.0`, and
zero registered tolerance failures. LDS grouped-K reload is bit-exact, and the
causal gated-QK LDS round trip has maximum absolute error `4.8828125e-4` with
zero tolerance failures.

## Full-path rejection

Across all 128 chunks, the fused body remains rejected:

- output: cosine `0.9999992847`, maximum absolute error `0.015625`, five
  relative-tolerance failures;
- final state: cosine `0.9999983311`, maximum absolute error `0.0625`, 35
  relative-tolerance failures;
- median HIP-event latency: `1079.131 us`, versus `560.346 us` for the shipped
  raw-H plus Triton-O pair (10 measurements after five warmups).

The performance cause is structural. BV16 launches 256 workgroups but repeats
the identical 64x64 QK calculation eight times per head. A zero-state reset
every 32 chunks was also rejected (`0.986998` output cosine, `2.576172` maximum
absolute error), proving that exact FlashQLA-style affine transition correction
is required before sequence segments can run independently.

The next design is a larger-V segmented kernel with local `(H_t, M_t)` affine
transitions, an exact prefix correction, and parallel fused recurrence/output.
The current v1 kernel is retained only as a correctness-localized raw assembly
reference and negative performance result; it is not integrated into SGLang.

Artifacts:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T114500Z-gdn-fused-avptr-fix-onechunk-gpu2/`;
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T121500Z-gdn-fused-cleaned-v1-full128-gpu2/`;
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T122500Z-gdn-fused-reset-seg32-full128-gpu2/`.
- reproducible build: `/data/netra/worktrees/netra-kernel-gdn-prefill-gfx950-20260802/build/gfx950-qwen36-gdn-fused-h-o-m8192-repro-v1/`;
- raw-source SHA-256: `da4657a959e89d142c70dc8e1ed92f127f3cb315a4a3c3b25cdb28015af52c71`;
- gfx950 HSACO SHA-256: `bd2ea346d5fe43c4c838191255c50105773b6fe08167de9805f9306fe0f8ded0`.
