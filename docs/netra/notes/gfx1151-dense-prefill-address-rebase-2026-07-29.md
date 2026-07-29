# gfx1151 dense-prefill address-rebase experiment (rejected)

Status: **rejected from production** on gfx1151. All numbers below are measured unless explicitly marked estimated.

## Trace rank and exact shapes

The process-start 32,768-token eager trace ranked `mxfp4_sgl_linear_prefill_wmma_gfx1151` third overall at 2,817.256 ms over 360 calls (9.153% of traced GPU time). Its calls split evenly across the Qwen3.6 GDN shapes:

| gfx1151 shape | calls | measured trace total | measured trace mean |
|---|---:|---:|---:|
| QKVZ, N=12,288 K=2,048 groups=128 | 120 | 1,863.298 ms | 15.527 ms |
| GDN output, N=2,048 K=4,096 groups=128 | 120 | 785.612 ms | 6.547 ms |
| A/B, N=64 K=2,048 groups=128 | 120 | 168.346 ms | 1.403 ms |

## Candidate

The generic raw ASM forms eight scalar weight bytes through seven serial vector-address additions per K block. `scripts/rocm/mxfp4_sgl_linear_prefill_n2048k4096_gfx1151.s` precomputes the seven addresses from the common base before issuing the eight loads. It retains the exact WMMA, accumulation, and store order, uses 105 VGPRs, increases declared SGPRs from 29 to 34, and was tested only for the real N=2,048 K=4,096 GDN-output dispatch.

The retained disassemblies are:

- `docs/netra/notes/disassembly/dense-prefill-gfx1151/generic.dis`
- `docs/netra/notes/disassembly/dense-prefill-gfx1151/address-precomputed-n2048k4096.dis`

## HIP-event result

The stable test used 11 samples with 20 launches inside each gfx1151 HIP-event interval and reports per-launch duration. Random packed MXFP4 bytes, exponent byte 127, BF16 activations, groups=128:

| gfx1151 implementation | measured median | measured mean |
|---|---:|---:|
| generic N=2,048 K=4,096 | 7.208725 ms | 7.195431 ms |
| address-precomputed | 7.076682 ms | 7.051635 ms |

Measured kernel-only speedup: **1.01866x**. At 120 calls, the estimated request saving was 15.845 ms. QKVZ and A/B remained on the generic dispatch. The synthetic full 128-group GDN output compared bit-exact between separately loaded generic and candidate modules.

Raw data is under `results/kernels/gfx1151/dense-prefill-address-rebase-20260729/`. The reusable harness is `scripts/rocm/benchmark_dense_prefill_shapes.py`.

## Real-checkpoint rejection

Exact uncached 32,768-input/+1-output serving used greedy sampling, graph disabled, dFlash disabled, and the real `/root/models/qwen36-sgl-mxfp4` checkpoint.

| gfx1151 build | prompt seed | measured host E2E | output token |
|---|---|---:|---:|
| established generic control | pair-b | 30,017.915 ms | 96043 |
| candidate | pair-b | 29,827.941 ms | 3709 |
| candidate repeat, fresh server | pair-b | 29,968.732 ms | 3709 |

The established prior generic runs also produced token 96043 for pair-b. Candidate pair-a retained token 220, but pair-b divergence was deterministic across two fresh candidate servers and disappeared on the fresh generic control. The serving result therefore fails the real-checkpoint greedy-token correctness gate even though the isolated synthetic comparison was bit-exact.

The production launcher, build list, generic ASM, and rebuilt `libnetra_mxfp4_sgl.so` were restored. No end-to-end speedup is claimed. The candidate ASM is retained only as a negative-result artifact for further fault isolation.
