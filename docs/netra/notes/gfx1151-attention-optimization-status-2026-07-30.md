# gfx1151 attention optimization status (2026-07-30)

Statuses distinguish measured gfx1151 evidence from proposals. “Good next” is
a prioritization, not an estimated speedup.

| # | Proposal | Status on gfx1151 | Assessment |
|---:|---|---|---|
| 1 | Separate Q and P LDS | Tried; accepted as global-Q/group4-P | The standalone 56 KiB split was 1.53% slower, but group4 removes Q restoration and packs four 8 KiB P workspaces beside shared K/V; combined result is 1.2279x isolated. |
| 2 | Batch/pipeline Q global-to-LDS | Tried, accepted | qpipe8 was accepted at 1.0257x isolated and 1.0396x exact 32K/+1 host E2E, then superseded by group4 global-Q; it remains the retained oracle. qpipe16 was neutral/slower. |
| 3 | Load next Q during current QK | Tried, accepted | Register double-buffering v8:v15 and v216:v223 adds 1.0209x-1.0320x over group4 without raising allocation. |
| 4 | Reduce 244/248 VGPR | Tried alone and with 32 KiB LDS; rejected | N64 reached 224 VGPR exactly. The standalone four-tier sum regressed 0.232%; combining 224 VGPR with 32 KiB LDS still produced no occupancy step, proving 224 VGPR is insufficient for this 512-thread schedule. |
| 5 | Reduce 64 KiB LDS | Tried at 56 and 32 KiB; rejected | A 32 KiB N32/group4 design was 9.919% slower. A bit-exact N64 tile-major P/V-overlay design was 5.740% slower. With 224 VGPR, measured occupancy was 9.10-9.45% versus about 10.02% baseline: halving LDS did not create a residency step. |
| 6 | Reuse K/V across eight query heads per KV head | Tried, accepted in groups of four | A 512-thread workgroup shares each staged K/V tile across four query heads: 1.2279x isolated, 1.2374x full-trace attention, and 1.0509x unprofiled 32K/+1 host E2E. |
| 7 | Cache page-table lookups | Tried, rejected | Full cache cut static scalar loads 33 to 17 and rocprof fetch 9.868%, but regressed prefix-tier time 0.567%. |
| 8 | Pipeline next global K/V tile | Not independently tried | The 32 KiB experiments leave room only by adding schedule penalties and still do not improve residency. Test overlap only with a materially lower-register or smaller-workgroup design; no speedup is estimated. |
| 9 | Precise waits/barriers | Tried, accepted incrementally | Shared-KV cut static waits 317 to 311 and barriers 5 to 4. kvbatch16 then cuts waits 311 to 307, improves prefix-24K 1.0311x and matched full-trace attention 1.0269x. The tile-boundary barrier remains mandatory; omitting it caused nondeterministic LDS overwrite corruption. |
| 10 | Cheaper V layout/wide LDS loads | Tried, rejected | Correct raw V-transpose was byte-identical but four-tier time regressed from 678.713 to 1,148.812 ms; scatter stores doubled bank-conflict metric. |
| 11 | Softmax exponent/reduction scheduling | Tried, rejected | Issuing all eight rows of exponentials before unchanged reductions is bit-identical but only 1.000325x over the exact T8192 four-tier sum; prefix 8K and 24K are neutral/slower. The current schedule already hides this dependency adequately. |
| 12 | Reduce/defer output rescaling | Tried, rejected conditional skip | A bit-identical all-alpha-one ballot cuts dynamic VALUInsts 6.11% and improves full-trace attention 1.00406x, but fresh 32K/+1 pairs split faster/slower and mean serving changes only 0.057%. True deferred scaling remains untested. |
| 13 | Branch-free full/diagonal kernels | Partially accepted | The scalar full-tile mask fast path is production. Separate kernel launches are untested and likely lower value than keeping one graph-safe uniform branch. |
| 14 | Raw M64xN32 persistent/global Q | Tried twice, rejected | Persistent-Q at 52 KiB was 56.9% slower. The stronger 32 KiB global-Q/group4 design reduced the regression to 9.919% but still doubled softmax/rescale updates and fetched 69% more bytes. |
| 15 | Prefix 0/8K/16K/24K specializations | Shapes measured, code not specialized | Low-to-medium priority; current loop bounds already specialize dynamically and duplicated code/graphs have a memory cost. |
| 16 | Larger pages/contiguous page loads | Not tried | Good co-design target. Page-table caching alone failed, while counters show repeated random K/V traffic remains the real boundary. |
| 17 | Fuse Q/K norm + RoPE + KV store | Pending | Sound next fusion target; requires exact KV-cache and RoPE validation before timing. |
| 18 | M2-M16 verify/dFlash attention | Not tried; input-blocked for dFlash | Strategically important. Current checkpoint has no `dflash_config` and no compatible draft checkpoint is installed, so no speedup is estimated. |

## Recommended order

1. Larger contiguous KV pages (#16), co-designed with the accepted four-head reuse schedule.
2. Q/K norm + RoPE + KV-store fusion (#17), with exact KV-cache validation.
3. Revisit LDS residency (#5) only with a materially smaller accumulator/register footprint or smaller workgroup; 224 VGPR plus 32 KiB was measured insufficient.
4. A materially different stable-max/deferred-rescale formulation (#12); retain accepted kvbatch16 (#9).
5. M2-M16 verify kernels (#18) after real dFlash inputs exist; prefix specialization (#15) only if a new full trace proves tier-specific branch cost.

No unmeasured proposal above is assigned a performance number.
