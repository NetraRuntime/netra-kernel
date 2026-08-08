# gfx950 Qwen3.6 packed BV128 GDN prefill

Date: 2026-08-02

Status: accepted for the guarded `N=16..64`, exactly 1,024-token-per-sequence
serving path.

Target: one AMD Instinct MI350X, `gfx950`, wave64. Qwen weights remain FP8
E4M3 with 128x128 block scales; the GDN inputs and recurrent state retain the
model-native BF16/FP32 types.

The Qwen [FlashQLA design](https://qwen.ai/blog?id=flashqla) and
[QwenLM/FlashQLA](https://github.com/QwenLM/FlashQLA) were algorithmic
references. Their CUDA/SM90 implementation was not ported. This kernel was
re-derived for CDNA4 wave64 and uses raw `v_mfma_f32_16x16x32_bf16` AMDGCN.

## Contract

- packed `N=16..64`, every sequence exactly `T=1024`;
- `H=32`, `Hg=16`, `K=V=128`, `BT=64`, `BV=128`;
- contiguous BF16 Q/K/U/W, FP32 cumulative gate, BF16 state/output;
- device-resident `state_indices` and `cu_seqlens`;
- one 256-thread/four-wave workgroup per `(sequence, head)`;
- 73,728 bytes LDS, 248 VGPRs, 36 SGPRs, no scratch or spills;
- 88-byte kernarg, gfx950 code-object v6, wave64.

The kernel fuses recurrent H and chunk-O without materializing the full H or
`v_new` tensors in HBM. QK is shared across the complete V128 tile. The Python
selector derives the exact-length predicate only from host-owned scheduler
metadata, requires `tokens == N * 1024`, and never performs a GPU `.item()` or
synchronization. Graph capture stays on the existing path because capture
metadata does not provide authoritative per-sequence lengths.

## Packed-addressing failure and fix

Packed v5-v7 were rejected after reproducible SQC page faults. The device fault
address `0x00000014_00200000` showed that the high half of the `cu_seqlens`
pointer had become the sequence byte offset `0x14`. The successive defects
were:

1. v5 loaded a state slot over the pointer high half;
2. v6 overlapped the state-load destination with its pointer source;
3. v7 wrote the sequence byte offset into `s27`, again corrupting
   `s[26:27]`.

The accepted v8 keeps the `state_indices` and `cu_seqlens` pointers intact and
uses `s31` for the byte offset. The kernel also validates the state slot, pool
size, and each exact 1,024-token interval before deriving any global address.

## Correctness

The promoted raw source SHA-256 is
`13d2a018d8ef486ea5e81f9b7b93d25bc075137c3e1d647e78b7865c387f94c3`.
The production build has the same HSACO SHA-256 as the tested packed v8:
`a004ae59fd1c9dc5d7f0ea855102518773230c0b15779a7e9efc81c0c9c08893`.
The promoted build was rerun for 200 launches with reversed high state slots
in a 65-row pool. All state and output guards remained unchanged.

Against the real-checkpoint raw-H plus Triton-O oracle at N16:

- output maximum absolute error `0.015625`, cosine `0.9999994636`, zero
  combined tolerance failures;
- final-state maximum absolute error `0.125`, cosine `0.9999979734`, zero
  combined tolerance failures;
- deterministic eager serving with Triton prefill MoE: zero mismatches across
  80 outputs against each of two control passes and zero self mismatches.

The ordinary AITER-prefill serving path was independently shown to be
nondeterministic, so it is retained for performance measurement but is not the
token-equivalence oracle.

## Performance and selector decision

HIP-event medians for the fused body versus raw-H plus Triton-O:

| sequences | baseline | fused | speedup | decision |
|---:|---:|---:|---:|---|
| 1 | 62.261 us | 365.704 us | 0.170x | reject |
| 8 | 558.865 us | 393.784 us | 1.419x | reject: complete layer is 0.936x |
| 16 | 1,100.666 us | 543.443 us | 2.025x | accept |
| 32 | 2,237.760 us | 1,065.750 us | 2.100x | accept |
| 64 | 4,475.120 us | 2,099.499 us | 2.132x | accept |

Complete GDN-layer speedup is 1.166x at N16 and 1.122x at N64. In the exact
native `/generate` batch serving A/B, the current-best graph+dFlash
configuration improved from 88.351 to 89.688 output tok/s, or 1.0151x. A
same-code deterministic-oracle run measured 52.97-53.05 tok/s control and
53.36-53.89 tok/s fused. The broader HTTP scheduler frequently forms batches
below N16, so this kernel is a narrow accepted win rather than a general
throughput claim.

## Artifacts

- production-build 200-launch gate:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T184500Z-gdn-fused-production-build-stress200-gpu3/result.json`;
- packed v8 N1/N8/N16/N32/N64 gates:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T13*Z-gdn-fused-packed-v8-*/result.json`;
- complete-layer N8/N16/N64 gates:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T08*Z-gdn-fused-bv128-integrated-layer-*/result.json`;
- current-best serving A/B:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T160000Z-gdn-fused-v8-native-batch-candidate.json` and
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T161500Z-gdn-fused-v8-native-batch-control.json`;
- deterministic serving gates:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T173000Z-gdn-fused-v8-triton-prefill-control-native.json` and
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T180000Z-gdn-fused-v8-triton-prefill-candidate-native.json`.
