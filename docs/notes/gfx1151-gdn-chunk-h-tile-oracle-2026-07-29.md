# gfx1151 GDN chunk-H tile oracle (rejected for production)

Status: **compiler oracle only; not enabled in production**. All runtime values below are measured on gfx1151. No values are estimated.

## Trace rank and disassembly finding

After the accepted attention and GDN chunk-output changes, exact uncached 32,768-token rocprofv3 tracing measured `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` at 120 calls, 1,043.031 ms total, and 8.692 ms mean. The production BV32/four-wave/two-stage code object allocates 256 VGPRs, 69 SGPRs, 524 bytes private scratch, and 36 KiB compiler-reported shared storage. Its disassembly has 5,161 instructions/labels lines and exposes extensive scratch traffic caused by the live recurrence and dot accumulators.

## Exact-shape compiler-oracle sweep

Shape: B=1, T=8192, H=32, Hg=16, K=128, V=128, BT=64, variable-length indexing, initial-state read/write, BF16 K/W/U/H/V-new/state and FP32 gating. Timing used HIP events. Every comparison below used identical tensors and checked H, V-new, and final state against BV32/four-wave/two-stage.

| BV | waves | stages | median | correctness |
|---:|---:|---:|---:|---|
| 32 | 4 | 2 | 8.208357 ms | bit-exact reference |
| 16 | 4 | 2 | 5.148278 ms | bit-exact |
| 16 | 8 | 2 | 11.579924 ms | bit-exact |
| 8 | 4 | 2 | 26.558893 ms | failed, max H/V-new error 0.00006103515625 |
| 32 | 8 | 2 | 4.585099 ms | bit-exact on synthetic tensors, 1.7902x |
| 32 | 4 | 1 | 5.267476 ms | bit-exact |

The eight-wave oracle reduces private scratch from 524 to 56 bytes and SGPRs from 69 to 47, while retaining 256 VGPRs. Compiler-reported shared storage increases from 36 to 40 KiB. Before/oracle gfx1151 disassemblies and metadata are in `docs/notes/disassembly/gdn-chunk-h-oracle-gfx1151/`; samples are in `results/kernels/gfx1151/gdn-chunk-h-tile-sweep.json`.

## Real-checkpoint rejection

The temporary server used `SGLANG_GDN_CHUNK_H_NUM_WARPS=8`, graph disabled, dFlash disabled, exact uncached 32,768 input and one output token.

| gfx1151 build | seed | host E2E | greedy token |
|---|---|---:|---:|
| production four-wave baseline | pair-a | 29,930.237 ms | 220 |
| eight-wave compiler oracle | pair-a | 30,169.432 ms | 220 |
| production four-wave baseline | pair-b | 29,806.921 ms | 96043 |
| eight-wave compiler oracle | pair-b | 29,345.743 ms | 3709 |

Pair-b changed its deterministic greedy token even though the synthetic exact-shape comparison was bit-exact. The production environment therefore remains at four waves. The eight-wave schedule is retained only as a performance/disassembly oracle; no serving speedup is accepted or claimed. Any hand-written raw gfx1151 replacement must preserve the paired real-checkpoint tokens before rocprofv3 promotion.
