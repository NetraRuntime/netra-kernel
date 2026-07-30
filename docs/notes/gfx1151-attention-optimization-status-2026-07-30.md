# gfx1151 attention optimization status (2026-07-30)

Statuses distinguish measured gfx1151 evidence from proposals. “Good next” is
a prioritization, not an estimated speedup.

| # | Proposal | Status on gfx1151 | Assessment |
|---:|---|---|---|
| 1 | Separate Q and P LDS | Tried, rejected | Byte-identical N64 split-KV removed restoration and used 56 KiB, but was 1.53% slower over exact T8192 four tiers. |
| 2 | Batch/pipeline Q global-to-LDS | Tried, accepted | qpipe8 is production: 1.0257x isolated four-tier and 1.0396x exact 32K/+1 host E2E, measured. qpipe16 was neutral/slower. |
| 3 | Load next Q during current QK | Not independently tried | Good only after freeing LDS/register lifetime; current 64 KiB overlay leaves no clean double buffer. |
| 4 | Reduce 244/248 VGPR | Partially tried | N32 reached 224 VGPR but was 56.9% slower. N64 register reduction remains a good high-priority target because current occupancy is low. |
| 5 | Reduce 64 KiB LDS | Tried, rejected at 56 KiB | No residency step occurred. A design near or below 32 KiB is still worth testing; small reductions are not. |
| 6 | Reuse K/V across eight query heads per KV head | Not tried | Best untested attention idea: Hq=16/Hkv=2 makes duplicated K/V traffic explicit, but it needs a multi-query-head workgroup or persistent cross-head schedule. |
| 7 | Cache page-table lookups | Tried, rejected | Full cache cut static scalar loads 33 to 17 and rocprof fetch 9.868%, but regressed prefix-tier time 0.567%. |
| 8 | Pipeline next global K/V tile | Not independently tried | Good after a lower-LDS or register-staged design; current 64 KiB footprint blocks ordinary LDS double buffering. |
| 9 | Precise waits/barriers | Partially explored | Worth continuing locally, but gfx1151 exposes no direct dependency-stall counter and correctness requires identical producer/consumer gates. |
| 10 | Cheaper V layout/wide LDS loads | Tried, rejected | Correct raw V-transpose was byte-identical but four-tier time regressed from 678.713 to 1,148.812 ms; scatter stores doubled bank-conflict metric. |
| 11 | Softmax exponent/reduction scheduling | Not isolated | Good medium-priority compute target after K/V reuse; preserve exact online-softmax ordering as the correctness oracle. |
| 12 | Reduce/defer output rescaling | Indirect evidence only | N32's doubled softmax/rescale work was costly. Reducing rescale is promising, but requires a stable-max/deferred-scale formulation. |
| 13 | Branch-free full/diagonal kernels | Partially accepted | The scalar full-tile mask fast path is production. Separate kernel launches are untested and likely lower value than keeping one graph-safe uniform branch. |
| 14 | Raw M64xN32 persistent Q | Tried, rejected | Correct candidate used 52 KiB and 224 VGPR but was 56.9% slower due twice as many softmax/rescale tile updates. |
| 15 | Prefix 0/8K/16K/24K specializations | Shapes measured, code not specialized | Low-to-medium priority; current loop bounds already specialize dynamically and duplicated code/graphs have a memory cost. |
| 16 | Larger pages/contiguous page loads | Not tried | Good co-design target. Page-table caching alone failed, while counters show repeated random K/V traffic remains the real boundary. |
| 17 | Fuse Q/K norm + RoPE + KV store | Pending | Sound but lower request-cost priority than attention/KV reuse; requires exact KV-cache and RoPE validation. |
| 18 | M2-M16 verify/dFlash attention | Not tried; input-blocked for dFlash | Strategically important. Current checkpoint has no `dflash_config` and no compatible draft checkpoint is installed, so no speedup is estimated. |

## Recommended order

1. Multi-query-head K/V reuse (#6), ideally combined with contiguous/larger-page
   loading (#16).
2. N64 VGPR reduction (#4) and a real LDS residency step (#5), enabling K/V and
   Q overlap (#3/#8).
3. Softmax scheduling/rescale work (#11/#12), then precise wait cleanup (#9).
4. Fusions and shape-specific variants (#17/#18/#15) after their full-stack
   traces and required dFlash inputs exist.

No unmeasured proposal above is assigned a performance number.
