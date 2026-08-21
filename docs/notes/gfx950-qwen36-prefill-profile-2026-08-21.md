# Qwen3.6 gfx950 prefill profile and candidate report

Date: 2026-08-21

Starting revisions:

- netra-kernel: `d04a2d82fe59f1712dd761d1394bee6db718209d`
- netra-server: `f718b21ed762e5574ff1fc14943459adf417c446`

The measurements below use the exact locked single-GPU stacks. The 27B stack
uses dFlash-8, BF16 recurrent state, TP1/DP1, full graphs, and the C192 graph
ladder. The 35B stack uses dFlash-12, TP1/DP1, C64, piecewise graphs, and the
locked modular M768 producer/reducer pair. Percentages for long 27B are
normalized to the warmed profiled request wall time of 422.977 ms. The
`compare_scalar` event attributed 338.8 ms to a tiny tensor construction; it
overlaps later same-stream kernels and is a Kineto host-synchronization
artifact, so it is excluded from GPU bottleneck totals.

## 27B operation profile

| bucket | operation | exact shape | dtype and layouts | calls | mean GPU time | total request contribution | graph | current implementation | proposed action |
|---|---|---|---|---:|---:|---:|---|---|---|
| short, input 16 | dense projections | observed target contracts include `M16,K5120->N6144/N17408`, `M16,K14336/16384/34816->N5120` | FP8 E4M3, dynamic A per-128, B preshuffled 16x16, BF16 output | 512 | 51.637 us | 26.438 ms, 27.23% of 97.101 ms wall | eager prefill; full graphs cover later verify/decode | AITER CK blockscale preshuffle | retain; table rows and prior custom schedules are already exhausted |
| short | BF16 GDN BA projection | `M16,K5120->N96` | BF16 row-major | 48 | included in small hipBLASLt group | below 0.7 ms total | eager | hipBLASLt | retain; not material |
| short | fused add-RMSNorm-quant | `M<=16,N5120` | BF16 residual/weight to FP8 plus FP32 scale | 254 | 4.251 us | 1.080 ms, 1.11% | eager | Netra modular gfx950 assembly | retain accepted schedule |
| short | GDN recurrent verification | T8, HV48, BV16, BF16 state | BF16 Q/K/V, FP32 accumulate, BF16 state | 48 | 9.978 us | 0.479 ms, 0.49% | captured verification | Netra modular gfx950 assembly | retain locked dFlash-8 contract |
| short | GDN convolution | rows 16, width 4, QKV 10240 | BF16 row-major | 48 | 6.756 us | 0.324 ms, 0.33% | eager | causal-conv framework kernel | below fusion threshold |
| long, input 8192 | dense projections | `M8192,K5120->N6144/N17408`; `M8192,K14336/16384/34816->N5120` | FP8 E4M3, dynamic A per-128, B preshuffled 16x16, BF16 output | 512 | 0.051-1.731 ms by contract | 260.56 ms, 61.60% | eager prefill | AITER CK Tile for large contracts plus CK for smaller contracts | largest bottleneck; stock exact rows already select the best eligible AITER kernels; prior custom-source and frozen-assembly serving candidates were rejected |
| long | GDN recurrent initialization | `M8192,H48,K128,V128,BV16` | BF16 Q/K/V, FP32 accumulate/state update | 48 | 601.868 us | 28.890 ms, 6.83% | eager | framework chunk GDN H kernel | exact fusion remains possible but requires a new modular kernel with substantial end-to-end proof |
| long | full attention prefill | 8192 tokens, GQA6, head dim 256 | BF16 Q/O, FP8 KV cache | 16 | 1.508 ms | 24.133 ms, 5.71% | eager | AITER paged prefill attention | retain; current specialized verification attention is separate |
| long | normalization plus quantization | rows 8192, widths 17408 and 5120 | BF16 to FP8 E4M3 per-128 with FP32 scales | 382 | 42.030-98.226 us | 23.249 ms, 5.50% | eager | Netra modular gfx950 assembly | retain accepted bounded schedules |
| long | GQA6 verification attention | M8, GQA6, head dim 256 | BF16 Q/O, FP8 KV cache | 16 | 612.030 us | 9.792 ms, 2.32% | captured verification | Netra modular gfx950 assembly | locked; no prefill change |
| long | GDN causal convolution | `M8192,QKV=10240,width=4` | BF16 row-major | 48 | 190.104 us | 9.125 ms, 2.16% | eager | causal-conv framework kernel | retain after projection-view candidate made stride cost worse |
| long | GDN chunk output | `M8192,H48,V128` | BF16 | 48 | 165.428 us | 7.941 ms, 1.88% | eager | framework chunk output | potential future exact fusion stage |
| long | QKV materialization | `M8192,[Q2048,K2048,V6144]` | BF16 contiguous cat | 48 | 164.512 us | 7.897 ms, 1.87% | eager | PyTorch `CatArrayBatchedCopy` | tested view elimination; reject after matched serving was +0.026% |
| long | KKT solve and recompute | `M8192,H48,K128,V128` | BF16/FP32 mixed | 96 | 112.999-133.976 us | 11.855 ms, 2.80% | eager | framework chunk kernels | secondary fusion candidate only after a serving-relevant design exists |
| long | BF16 lm_head | `M1,K5120->N248320` (prefill gathers the final token only) | BF16 row-major | 1 | below 0.4 ms | under 0.1% | eager | hipBLASLt | not a prefill bottleneck |

## 35B operation profile

| bucket | operation | exact shape | dtype and layouts | calls | mean GPU time | total request contribution | graph | current implementation | proposed action |
|---|---|---|---|---:|---:|---:|---|---|---|
| short, input 16 | routed MoE producer/down | M16 routes, 257 experts, top-k 9, K2048/intermediate512 | FP8 E4M3 block128 weights and activations, BF16 output | 80 | 13.790-27.066 us | 1.635 ms, 3.82% of 42.791 ms wall | piecewise captured | AITER CK MoE | retain; M768 modular pair is not selected at M16 |
| short | dense projections | target contracts include `M16,K2048->N12288/N5120/N1024`, `M16,K4096->N2048`, `M16,K512->N2048` | FP8 E4M3, A per-128, B preshuffled 16x16, BF16 output | 80 | 9.580 us | 0.766 ms, 1.79% | piecewise captured | AITER CK blockscale preshuffle | retain |
| short | MoE sorting | M16 routes, 257 experts, top-k 9 | BF16 logits, FP32 weights, integer route metadata | 40 | 11.160 us | 0.446 ms, 1.04% | piecewise captured | AITER sorting | workspace preparation is not dominant |
| short | GDN recurrent initialization | M16, H32, K/V128 | BF16/FP32 mixed | 30 | 8.758 us | 0.263 ms, 0.61% | piecewise captured | framework chunk GDN | retain |
| long, input 8192 | non-M768 routed MoE fallback | M8192 routes, 257 experts, top-k 9, K2048/intermediate512 | FP8 E4M3 block128 weights and activations, BF16 output | 38 | 685.618 us | 26.053 ms, 19.63% of 132.753 ms wall | piecewise captured | AITER FMoE block64 | largest bottleneck; prior block64 serving experiment was flat, so retain |
| long | attention prefill | 8192 tokens, 16 Q heads, 2 KV heads, head dim 256 | BF16 Q/O, FP8 KV cache | 10 | 1.461 ms | 14.614 ms, 11.01% | piecewise captured | Triton prefill attention | future attention work requires its own measured exact kernel |
| long | dense FP8 projections | `M8192,K2048->N12288/N5120/N1024`; `M8192,K4096->N2048`; `M8192,K512->N2048` | FP8 E4M3, A per-128, B preshuffled 16x16, BF16 output | 156 (76 large plus 80 small) | 9.976-189.479 us | 15.198 ms, 11.45% | piecewise captured | AITER CK blockscale preshuffle | exhaustive 285-candidate screen retained the active CK13/CK16 choices; no table change |
| long | GDN recurrent initialization | `M8192,H32,K128,V128,BV16` | BF16 Q/K/V, FP32 accumulate/state | 29 | 432.677 us | 12.548 ms, 9.45% | piecewise captured | Netra `qwen36_gdn_h_m8192` assembly | retain accepted exact dispatch |
| long | GDN causal convolution | `M8192,QKV=8192,width=4` | BF16 row-major | 29 | 133.856 us | 3.882 ms, 2.92% | piecewise captured | causal-conv framework kernel | secondary only |
| long | GDN chunk output | `M8192,H32,V128` | BF16 | 29 | 113.335 us | 3.287 ms, 2.48% | piecewise captured | framework chunk output | secondary fusion opportunity |
| long | QKVZ/BA split, reshape, cat | `M8192,QKV=8192,Z=4096,BA=64` | BF16 contiguous materialization | 58 | 53.120 us | 3.081 ms, 2.32% | piecewise captured | fused framework materialization kernel | view path is exact but rejected by 27B serving gate; no toggle retained |
| long | normalization plus quantization | M8192, width 2048 and routed inputs | BF16 to FP8 E4M3 per-128, FP32 scales | 350 | 9.941-14.241 us | 4.150 ms, 3.13% | piecewise captured | AITER kernels | retain |
| long | MoE sorting | M8192 routes, 257 experts, top-k 9 | FP32 weights and integer metadata | 38 | 25.670 us | 0.975 ms, 0.73% | piecewise captured | AITER multiphase sorting | not a primary target |
| long | BF16 router | `M8192,K2048->N256` | BF16 row-major | 38 | 21.780 us | 0.828 ms, 0.62% | piecewise captured | AITER/hipBLAS BF16 GEMM | not material |
| long | BF16 lm_head | `M1,K2048->N248320` (final-token gather) | BF16 row-major | 1 | below 0.2 ms | under 0.2% | eager tail | hipBLASLt | not a prefill bottleneck |
| natural C64 screen | locked M768 MoE pair | exactly M768 routes, producer grid `(2,365,1)`, reducer grid `(16,768,1)` | FP8 producer to FP16 split-K2 partials; FP32 route scale; BF16 output | only exact M768 captures | locked | unchanged | piecewise captured | two Netra modular assembly operations | preserve byte-identical pair and workspace contracts |

## Candidate decisions

1. AITER table coverage: all five 35B M8192 dense contracts were screened
   across 285 CK, CKTile, and assembly candidates. Four already had upstream
   exact rows. The missing `M8192,N5120,K2048` row falls back to CK13, which
   was also the fastest valid candidate (144.6801 us, error ratio 0). Adding a
   row would not change dispatch. No table edit was made.
2. Projection views: direct exact-layout tests passed at rows 16, 257, 1536,
   and 8192; causal convolution, recurrent state, GDN gate/beta, graph capture,
   replay, and repeated replay were bitwise identical. The 27B warmed long
   request improved from 411.737 ms to 401.997 ms (2.36%), and the 48 large QKV
   cats disappeared. Matched natural-EOS C192 serving changed from 6318.36 to
   6320.02 output tokens/s (+0.026%). It failed the serving gate and all toggle
   and dispatch code was removed.
3. Previously retained negatives were not repeated: 35B FMoE block64 was flat
   in matched serving; the dense M768 QKVZ kernel regressed serving 6.4%; the
   frozen dense verification assembly regressed its matched ABBA by 0.94%; and
   custom AITER compute-source tiles are architecture-ineligible.

No candidate met the end-to-end promotion threshold. Consequently no source,
manifest, tactic, lock, or serving-default change is proposed.

## Archived evidence

- Full profile/candidate report:
  `/data/netra/benchmarks/gfx950_qwen36_prefill-20260821.t3C9F4/profile-and-candidate-report.md`
  (SHA-256
  `8b1a81cef4b2b781128604f2f4830b1b0e5501e45e48d35e25417e6497af554e`)
- 27B view-candidate negative summary:
  `/data/netra/benchmarks/gfx950_qwen36_prefill-20260821.t3C9F4/27b-prefill-views-negative-summary.json`
  (SHA-256
  `5bf3af223abb0d4e8635d29c96677635c03f066cf65d595ed72b4b767e786b2f`)
- 35B dense-tuning CSV SHA-256:
  `03492bc92123d06ff806c1b62160000149322ed5de3c66e811c57c1cc8e9c7df`

The locked 27B, 35B primary, and 35B C64 artifacts remained byte-identical
through the campaign.
