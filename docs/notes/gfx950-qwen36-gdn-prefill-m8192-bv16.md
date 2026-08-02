# gfx950 Qwen3.6 GDN M8192 prefill recurrence

Date: 2026-08-02

## Scope

This raw AMDGCN module replaces the FLA Triton GDN `h` recurrence only for the
real-checkpoint shape `B=1,T=8192,H=32,Hg=16,K=V=128,BT=64`. It targets
`gfx950`, wave64, and uses the Qwen3.6 FP8 E4M3 128x128-block checkpoint without
changing weight or KV-cache quantization. Unsupported shapes do not enter the
module; the SGLang integration owns the strict shape gate.

The production kernel is
`kernels/gfx950/linear_attention/prefill/qwen36_gdn_h_m8192_bv16_gfx950.s`.
The HIP bridge only loads the code object and enqueues its graph-safe launch.

## CDNA4 design

The deployed Triton kernel used a 32-row V tile, 128 workgroups, 256 threads,
220 VGPRs, 99 SGPRs, 72,064 bytes of LDS, 32 static MFMA instructions, and 35
barriers. The replacement uses a 16-row V tile so that its 256 workgroups match
the 256 physical CUs on one MI350X. Four wave64 waves cooperate per workgroup.
The selected three-stage LDS pipeline uses native
`v_mfma_f32_16x16x32_bf16`, 108 VGPRs, 94 SGPRs, 103,296 dynamic LDS bytes,
zero scratch, and no spills.

The initial instruction stream was recovered from the exact gfx950 Triton
oracle, then made into a standalone raw module, retiled, staged, renamed, and
scheduled for the production ABI. The retained source contains no Triton JIT or
compiler-generated debug sections. The quarantined compiler oracle remains
under `experiments/` and is not an accepted production implementation.

## Correctness and timing

The real layer-0 capture contains 67,108,864 BF16 `h` elements, 33,554,432 BF16
`v_new` elements, and 524,288 BF16 final-state elements. All three outputs are
bit-exact against the deployed implementation. The cleaned source rebuilt to a
gfx950 wave64 code object and passed 100 HIP-event iterations at 436.784 us
median on an MI350X. The retained deployed 32-row kernel measured 542.586 us,
a 19.50% kernel-latency reduction. Across 24 GDN layers this removes roughly
2.5 ms from the exact 8K prefill.

The final same-GPU, sequential piecewise-graph serving comparison used ten
exact, uncached 8192-input/1-output requests per arm. Median end-to-end latency
fell from 130.758 ms to 128.175 ms (1.98%), and median input throughput
increased from 62,713.20 to 63,972.18 token/s (2.01%).

The current-best server is not repeatable on this near-tie prompt: the control
returned the established token/hash in 8/10 requests and the final candidate in
7/10; an earlier candidate process returned it in 10/10. Both arms produced
only the same two token hashes. A proposed cache-flush synchronization did not
remove the variance on a fresh process and was rejected rather than shipped.
The replacement's correctness claim therefore rests on its bit-exact full
tensor outputs, not on attributing shared AITER/MoE reduction-order variance to
this GDN kernel.

## Rejected variants

- Two waves underutilized the machine; eight and sixteen waves increased
  register/LDS pressure and latency. Four waves won the interleaved sweep.
- The `matrix_instr_nonkdim=16` variant lost to the native gfx950 selection.
- One and two LDS stages measured slower than three; four stages added LDS and
  did not improve latency.
- Moving independent scalar/address instructions into two MFMA dependency
  windows was bit-exact but measured within noise (430.564 vs 430.644 us in an
  interleaved run). The accepted gain comes from the BV16 CU-level parallelism
  and three-stage pipeline, not from claiming a schedule-only win.

## Next fusion

QwenLM FlashQLA commit `821fd9d37ede18fdc2a4e707fefe3770bfc32e58`
confirms the larger opportunity: fuse recurrent state construction with GDN
output computation and avoid materializing the full chunk-state tensor when
the caller only needs selected prefix states. The measured `h` plus `chunk_o`
family accounts for about 15.3 ms at exact M8192. The next gfx950 design will
derive wave64 producer/S/X/Y roles and LDS ownership for CDNA4 rather than port
Hopper warp-specialization mechanically.
