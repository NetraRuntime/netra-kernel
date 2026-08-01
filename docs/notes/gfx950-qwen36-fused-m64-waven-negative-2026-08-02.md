# gfx950 Qwen3.6 fused M64 wave-N result

Status: **real-checkpoint validated negative experiment; not integrated**.

This follow-up replaces the rejected row-wave organization with independently
derived gfx950 wave-N schedules. The checkpoint remains FP8 E4M3 with 128x128
block scales. Both kernels are raw wave64 AMDGCN and use native
`v_mfma_f32_16x16x128_f8f6f4`; no HIP compute fallback is present.

The first schedule uses one workgroup per M64 expert block. Four waves own the
four N128 activation groups and retain four M16 row tiles in `a0:a255`. It
uses 64 KiB LDS, 448 combined registers, 68 SGPRs, and no scratch. It exactly
reproduced the retained accepted activation profile and passed the complete
layer gates, but explicit AGPR read/modify/write accumulation made the
W13+SiLU+quantization stage take 306.704 us.

The second schedule uses two workgroups per M64 block. Each wave owns N64 and
keeps all gate/up accumulation in `v64:v191`; `v192:v255` holds transient MFMA
results, and AGPRs hold scales and LDS weight operands. Native
`v_pk_fma_f32` updates two accumulators per instruction. The final code object
uses 32 KiB LDS, 416 combined registers, 68 SGPRs, and no scratch.

An LDS-coordinate defect initially made only the up projection wrong. The
gate projection already differed in just 149 of 27,136 sampled BF16 values
with cosine 0.999999972. The up producer used `lane*8`, the cooperative-store
coordinate, instead of `wave*8192 + lane*16`, the native MFMA read coordinate.
Restoring that coordinate made the complete layer pass both structural and
AITER gates.

| Variant | W13+SiLU+quant median | Complete raw pipeline | Activation FP8 mismatch | Full structural cosine | Full AITER cosine |
|---|---:|---:|---:|---:|---:|
| one-WG, N128/wave, AGPR accumulation | 306.704 us | 404.385 us | 101,625 / 4,718,592 | 0.999973 | 0.999965 |
| two-WG, N64/wave, packed VGPR accumulation | 231.083 us | 326.683 us | 101,630 / 4,718,592 | 0.999973 | 0.999965 |
| one-WG persistent two-N256 phases | 303.023 us | 398.884 us | 101,630 / 4,718,592 | 0.999973 | 0.999965 |
| retained hybrid raw producer | 148.900 us | 250.061 us | 101,625 / 4,718,592 | 0.999973 | 0.999965 |
| packaged AITER complete oracle | - | 223.323 us | - | - | - |

The two VGPR variants missed the inherited activation-byte threshold of
101,627 by three bytes, while still satisfying the stronger complete-layer
maximum-error and cosine gates. They remain rejected because performance is
also below the retained producer; the numerical threshold is not being
relaxed after viewing the result.

The measurements establish two constraints for the next fused design:

1. Merely changing row ownership does not offset a 416/448-register occupancy
   point when W13, quantization, W2, and reduction remain separate kernels.
2. A useful one-stage design must retain wave-owned output-N work while
   avoiding per-accumulator AGPR transfers and eliminating the global
   activation, standalone W2, and route-reduction handoffs together.

Raw results and code-object evidence are retained under:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T000500Z-gateup-waven-highreg-r1-gpu6/`
- `/data/netra/repos/netra-kernel/build/gfx950-qwen36-gateup-waven-highreg-r1/`
- `/data/netra/repos/netra-kernel/build/gfx950-qwen36-gateup-waven-n256-vgpr-r10-pkfma/`
- `/data/netra/repos/netra-kernel/build/gfx950-qwen36-gateup-waven-n256-vgpr-r13-persistent-coordfix/`
- `/data/netra/repos/netra-kernel/build/gfx950-qwen36-gateup-waven-n256-vgpr-r14-retained-negative/`

The experimental sources stay in
`kernels/gfx950/fp8/moe/verify/experiments/` and are not exposed through the
production runtime bridge.
