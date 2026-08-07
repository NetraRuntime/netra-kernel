# gfx950 Qwen3.6 fused M64xN256 FMoE: source recovery and weight-stream pipeline

Date: 2026-08-08 UTC

Status: **validated isolated improvement; still behind AITER, not integrated**.

## Source recovery

The deterministic one-stage `qwen36_moe_fused_m64n256_partial_fp8_gfx950`
kernel benchmarked on 2026-08-07 (366 us median) had no retained assembly
source; only its code object, disassembly, and metadata survived in
`20260807T000000Z-deterministic-fmoe-n256-gpu1`. The source was reconstructed
mechanically from the retained disassembly (branch relabeling plus descriptor
and metadata grafts from the atomic sibling) and verified by an exact
normalized-disassembly round trip before any edit. The reconstruction
reproduced the retained log bit for bit: identical structural and AITER
mismatch counts and 361.9 us median over 100 iterations. The benchmark
harness, also lost, was rewritten from the retained
`qwen36_moe_down_m64_partial_pipeline` ancestor with an added per-iteration
determinism check.

## Pipeline result

The kernel serialized every K iteration: global weight slab load, full
`vmcnt(0)` wait, LDS write, barrier, MFMA, barrier. The pipelined variant
keeps the next weight slab in flight in staging registers v[192:223] while
the current slab computes, and prefetches A fragments and scales after the
ACC chains consume the previous values. Wave-skip, barrier count, LDS layout,
kernel symbol, and ABI are unchanged; the descriptor grows to 224 VGPRs,
which keeps two waves per SIMD.

| Variant | Median (100 iters) | Gate |
|---|---:|---|
| reconstructed baseline | 361.9 us | pass, deterministic 0/100 |
| W13+W2 pipelined | 320.0 us (-11.6%) | pass, deterministic 0/100 |
| AITER 64x256 one-stage | 226.0 us | reference |

Output is bit-identical to the baseline (1,585,334 / 2,097,152 structural
BF16 mismatches, cosine 0.999973, AITER cosine 0.999965, the same to the
last digit), so the transform changed scheduling only.

Pipelining W13 alone delivers the entire gain; the W2 loop has only four fat
K iterations per output step and was never latency-starved. A bounds bug
during development (copying the 16-iteration W13 limit into the 4-iteration
W2 loop) produced out-of-range weight reads and is why intermediate variants
failed; the fix restored bit-exactness.

## Remaining gap and next steps

At 320 us the one-stage kernel remains 41.6% behind AITER on the exact
M=1024 capture. The residual cost is organizational, not padding or raw
latency: one workgroup owns a whole M64 block and walks four N128 groups,
two halves, and the quant rows serially with 8 MFMAs per K iteration,
against the AITER 512-VGPR deep accumulation. The next levers, in order:

1. deeper K accumulation per iteration (more MFMA in flight per wait),
2. prefetch across the group/half boundary (the eight per-half primes
   restart the pipeline cold),
3. depth-2 staging with partial `vmcnt` waits.

Artifacts: `20260808T172016Z-fmoe-fused-pipeline-gpu1` (hsacos, SHA256SUMS,
two 100-iteration gate logs). Build:
`tools/build/build_gfx950_qwen36_moe_fused_m64n256.sh`.
