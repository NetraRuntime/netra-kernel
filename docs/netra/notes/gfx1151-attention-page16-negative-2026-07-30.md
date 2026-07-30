# gfx1151 page-16 contiguous-KV attention experiment (2026-07-30)

Status: **rejected; production restored to page size 1**. Every runtime claim below is measured on gfx1151. No performance value is estimated.

## Design tested

The raw `extend_attention_wmma_n64_page16_gfx1151` candidate preserves the accepted M64xN64 arithmetic, 512-thread workgroup, group-of-four K/V reuse, and current-chunk path. For the cached prefix, each wave loads four physical-page anchors and derives the other twelve token rows from the allocator's guaranteed 16-token contiguous page instead of loading sixteen token-slot indices.

SGLang's `PagedTokenToKVPoolAllocator` was audited before implementation: its page-size-16 allocation returns contiguous physical token indices within each page, while the NHD KV pool remains `[slot, 2, 256]`. Deterministically shuffled physical pages were used for the raw correctness gate so correctness did not depend on globally sequential slots.

## Correctness and HIP-event result

At T=8192, prefixes 0/8192/16384/24576, Hq=16, Hkv=2, D=256, BF16, three warmups and eleven alternating measured samples per tier, the page-16 candidate was byte-identical to the page-1 raw kernel at every tier.

| Prefix | page-1 median ms | page-16 median ms | page-1/page-16 | Result |
|---:|---:|---:|---:|---|
| 0 | 34.847717 | 34.532375 | 1.009132x | measured |
| 8,192 | 100.242882 | 100.138779 | 1.001040x | measured |
| 16,384 | 167.698547 | 167.769989 | 0.999574x | measured |
| 24,576 | 236.211578 | 236.064011 | 1.000625x | measured |
| Sum | 539.000725 | 538.505154 | 1.000920x | **neutral** |

## Disassembly and rocprofv3 evidence

Both variants allocate 248 VGPR, 128 SGPR, 64 KiB LDS, and zero scratch. Static gfx1151 disassembly changes only the page-index/address path: `s_load` sites fall from 618 to 594, while `s_add` sites rise from 329 to 361. Global-load, WMMA, wait, and barrier sites remain 80, 128, 307, and 4 respectively.

At T=8192/prefix=24576, one counter per fresh rocprofv3 process with `--disable-signal-handlers true` measured SALUInsts 32,220.25 for page 1 and 35,292.25 for page 16: the derived-offset arithmetic outweighed the removed scalar loads. FETCH_SIZE was 19,699,149.75 versus 19,495,835.31 KiB and L2 hit was 11.624896% versus 11.079091%; these single-pass cache counters are retained as evidence, not claimed as improvements. The page-1 OccupancyPercent sample was an impossible rocprofv3 value and is excluded; page 16 measured 9.997420%.

## Exact uncached serving result

Three fresh-server pairs used exact 32,768 input tokens and one forced output token, zero cached tokens, seed 20260730, graph disabled, dFlash disabled. All six produced output token `[82]` and identical input/output hashes.

| Pair | page-1 host E2E ms | page-16 host E2E ms | page-16 minus page-1 ms |
|---:|---:|---:|---:|
| 1 | 21569.101109 | 21551.813776 | -17.287333 |
| 2 | 21563.095230 | 21532.386130 | -30.709100 |
| 3 | 21515.386865 | 21521.612851 | +6.225986 |
| Mean | 21549.194401 | 21535.270919 | -13.923482 |

The mean ratio is 1.000646543x (0.064654% nominal), smaller than run variability; pair 3 reversed sign. Page-1/page-16 sample standard deviations were 29.431782/15.305733 ms. Peak unified VRAM varied by run and showed no stable page-size advantage. These are measured host serving times, not GPU-kernel timings.

## Decision

Reject this page-16 specialization and remove its temporary production dispatch. Retain the raw gfx1151 assembly, build/profile scripts, shuffled-page correctness support, disassembly, HIP events, rocprofv3 summaries, and serving JSON as a reproducible negative result. Larger pages are not automatically beneficial: a future revisit needs a page layout that also reduces K/V transactions or makes cross-wave/cooperative contiguous loads possible, not merely fewer page-table indices.

## Reproduction

- `scripts/rocm/kernels/gfx1151/attention/experiments/extend_attention_wmma_n64_page16_gfx1151.s`
- `scripts/rocm/tools/build/build_extend_attention_page16_experiment.sh`
- `scripts/rocm/tools/benchmark/benchmark_extend_attention_variants_shared_output.py`
- `scripts/rocm/tools/profiling/profile_extend_attention_page16_counters.sh`
- `scripts/rocm/tools/benchmark/benchmark_sglang_fresh_request.sh`
- `scripts/rocm/integrations/sglang/experiments/netra-page16-attention-negative.patch`
- `scripts/rocm/integrations/sglang/experiments/sglang-page16-attention-negative.patch`
