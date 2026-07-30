# gfx1151 attention optimization status (2026-07-30)

Statuses distinguish measured gfx1151 evidence from proposals. “Good next” is
a prioritization, not an estimated speedup.

| # | Proposal | Status on gfx1151 | Assessment |
|---:|---|---|---|
| 1 | Separate Q and P LDS | Tried; accepted as global-Q/group4-P | The standalone 56 KiB split was 1.53% slower, but group4 removes Q restoration and packs four 8 KiB P workspaces beside shared K/V; combined result is 1.2279x isolated. |
| 2 | Batch/pipeline Q global-to-LDS | Tried, accepted | qpipe8 was accepted at 1.0257x isolated and 1.0396x exact 32K/+1 host E2E, then superseded by group4 global-Q; it remains the retained oracle. qpipe16 was neutral/slower. |
| 3 | Load next Q during current QK | Tried, accepted | Register double-buffering v8:v15 and v216:v223 adds 1.0209x-1.0320x over group4 without raising allocation. |
| 4 | Reduce 244/248 VGPR | Partially tried | N32 reached 224 VGPR but was 56.9% slower. N64 register reduction remains a good high-priority target because current occupancy is low. |
| 5 | Reduce 64 KiB LDS | Tried, rejected at 56 KiB | No residency step occurred. A design near or below 32 KiB is still worth testing; small reductions are not. |
| 6 | Reuse K/V across eight query heads per KV head | Tried, accepted in groups of four | A 512-thread workgroup shares each staged K/V tile across four query heads: 1.2279x isolated, 1.2374x full-trace attention, and 1.0509x unprofiled 32K/+1 host E2E. |
| 7 | Cache page-table lookups | Tried, rejected | Full cache cut static scalar loads 33 to 17 and rocprof fetch 9.868%, but regressed prefix-tier time 0.567%. |
| 8 | Pipeline next global K/V tile | Not independently tried | Good after a lower-LDS or register-staged design; current 64 KiB footprint blocks ordinary LDS double buffering. |
| 9 | Precise waits/barriers | Tried, accepted incrementally | Shared-KV cut static waits 317 to 311 and barriers 5 to 4. kvbatch16 then cuts waits 311 to 307, improves prefix-24K 1.0311x and matched full-trace attention 1.0269x. The tile-boundary barrier remains mandatory; omitting it caused nondeterministic LDS overwrite corruption. |
| 10 | Cheaper V layout/wide LDS loads | Tried, rejected | Correct raw V-transpose was byte-identical but four-tier time regressed from 678.713 to 1,148.812 ms; scatter stores doubled bank-conflict metric. |
| 11 | Softmax exponent/reduction scheduling | Tried, rejected | Issuing all eight rows of exponentials before unchanged reductions is bit-identical but only 1.000325x over the exact T8192 four-tier sum; prefix 8K and 24K are neutral/slower. The current schedule already hides this dependency adequately. |
| 12 | Reduce/defer output rescaling | Indirect evidence only | N32's doubled softmax/rescale work was costly. Reducing rescale is promising, but requires a stable-max/deferred-scale formulation. |
| 13 | Branch-free full/diagonal kernels | Partially accepted | The scalar full-tile mask fast path is production. Separate kernel launches are untested and likely lower value than keeping one graph-safe uniform branch. |
| 14 | Raw M64xN32 persistent Q | Tried, rejected | Correct candidate used 52 KiB and 224 VGPR but was 56.9% slower due twice as many softmax/rescale tile updates. |
| 15 | Prefix 0/8K/16K/24K specializations | Shapes measured, code not specialized | Low-to-medium priority; current loop bounds already specialize dynamically and duplicated code/graphs have a memory cost. |
| 16 | Larger pages/contiguous page loads | Not tried | Good co-design target. Page-table caching alone failed, while counters show repeated random K/V traffic remains the real boundary. |
| 17 | Fuse Q/K norm + RoPE + KV store | Pending | Sound next fusion target; requires exact KV-cache and RoPE validation before timing. |
| 18 | M2-M16 verify/dFlash attention | Not tried; input-blocked for dFlash | Strategically important. Current checkpoint has no `dflash_config` and no compatible draft checkpoint is installed, so no speedup is estimated. |

## Recommended order

1. N64 VGPR reduction (#4) and a real LDS residency step (#5), enabling next-K/V overlap (#8).
2. Larger contiguous KV pages (#16), co-designed with the accepted four-head reuse schedule.
3. Deferred/stable-max output-rescale work (#12); retain the accepted dependency-proven kvbatch16 wait cleanup (#9).
4. Q/K norm + RoPE + KV-store fusion (#17); M2-M16 verify kernels (#18) after dFlash inputs exist.
5. Prefix specializations (#15) only if the new full trace shows a tier-specific branch cost.

No unmeasured proposal above is assigned a performance number.
