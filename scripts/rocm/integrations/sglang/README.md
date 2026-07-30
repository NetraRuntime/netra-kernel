# SGLang integration

This directory is the complete serving overlay for SGLang commit
`1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`.

- `sglang-gfx1151-integration.patch` is the base SGLang patch.
- `sglang-gfx1151-qkvz-ba-fusion.patch` applies after it and adds the measured
  Qwen3.6 GDN M=1 QKVZ+BA raw-ASM fusion, batched MXFP4 expert loading, and the
  native `tc_piecewise` model-loop boundary, plus the accepted raw-ASM GDN
  QKVZ/BA split-copy path.
- `sglang-gfx1151-extend-attention.patch` adds the accepted exact-shape raw
  gfx1151 standard-attention dispatch.
- `sglang-gfx1151-gdn-chunk-o.patch` adds the exact-shape raw gfx1151 GDN
  chunk-output dispatch after the base integration patches.
- `sglang-gfx1151-gdn-recompute-w-u.patch` adds the accepted operation-ordered
  raw gfx1151 W/U recompute dispatch for the exact 8K GDN shape.
- `sglang-gfx1151-causal-conv1d.patch` adds the accepted bit-exact ordered-BF16
  raw gfx1151 causal-convolution and state-write dispatch for the exact 8K shape.
- `sglang-gfx1151-qk-mrope-kv-fusion.patch` adds the accepted raw gfx1151 Q/K
  normalization, multi-axis RoPE, gating, and KV-cache-store fusion.
- `sglang-gfx1151-mamba-track-host-flag.patch` carries authoritative CPU-side
  Mamba tracking and batch-1 alignment metadata into `ForwardBatch`, removing
  eager GPU truth conversions and batch-1 dynamic indexing.
- `sglang-gfx1151-gdn-syncfree-chunk-metadata.patch` reuses host sequence
  lengths, constructs FLA indices/offsets directly on gfx1151, and reuses the
  same chunk-index tensor in the GDN output phase.
- `sglang-gfx1151-bf16-lm-head.patch` routes the exact batch-1 BF16
  `[1,2048] x [248320,2048]^T` LM head to the accepted graph-safe raw gfx1151
  assembly kernel. `SGLANG_NETRA_ENABLE_BF16_LM_HEAD=0` restores rocBLAS.
- `sglang-gfx1151-bf16-qkv.patch` routes exact M=1 N9216 K2048 BF16 QKV
  to the accepted raw gfx1151 assembly kernel; M>1 and prefill remain unchanged.
  `SGLANG_NETRA_ENABLE_BF16_QKV=0` restores rocBLAS.
- `sglang-gfx1151-bf16-shared-gate-up-silu.patch` fuses the exact M=1
  N512+512 K2048 shared-expert BF16 projections with register-resident SiLU
  and multiplication. `SGLANG_NETRA_ENABLE_BF16_SHARED_GATE_UP_SILU=0`
  restores rocBLAS plus the separate activation kernel. The same patch routes
  exact M=1 N2048 K512 shared-expert down projections to raw gfx1151 assembly;
  `SGLANG_NETRA_ENABLE_BF16_SHARED_DOWN=0` restores rocBLAS for that path.
- `experiments/` retains integration patches for rejected design oracles.
- The raw GDN bridge is graph-safe and retains Triton for all other shapes.
- `netra_gfx1151_sglang.py` is copied into SGLang's quantization package.
- `netra_mxfp4_sgl_launcher.hip` is launch-only host code for the raw HSACOs.
- `launch.sh` enables the accepted BF16 LM-head, QKV, and shared-expert
  gate/up+SiLU kernels by default after all modules have been built and the SGLang overlay applied; the exact C ABI and
  caller stream are preserved.
- Prefill gate/up weights retain MXFP4 and add a load-time raw-ASM dword-layout
  view for coalesced gfx1151 access; decode retains the serialized layout.
- `launch.sh` starts the validated gfx1151 deployment.

The launcher enables the measured fast-load path by default: safetensors are
read without mmap by two bounded loader threads, then the Qwen integration
stages each 256-expert MXFP4 group into a small number of device copies. On the
16 GiB Netra system, do not raise `SGLANG_WEIGHT_LOADER_THREADS` without first
checking peak host memory. The cold-cache gfx1151 result is documented in
`docs/notes/gfx1151-loading-report-2026-07-29.md`. The accepted prefill view
adds 10 GiB of persistent unified-VRAM allocation but keeps the measured shard
phase at 9.01 seconds and passes the 49K context tier. Its evidence is in
`docs/notes/gfx1151-prefill-gate-dword-layout-2026-07-29.md`.

Build the native artifacts first:

```bash
bash scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
```

Then follow the patch, copy, and launch commands in the repository
`README.md`.
