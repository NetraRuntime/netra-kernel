# gfx1151 attention K/V preload and pipeline experiments — 2026-07-31

Status: **rejected, measured on gfx1151**. Model: Qwen3.6-35B-A3B using the checkpoint-native MXFP4 weights. No estimated performance values and no alternate quantization format are used here.

## Ranked motivation

The accepted group-two N64 extend-attention kernel was the top kernel in the latest exact 32,768-input/+1-output eager request trace: 40 invocations, 5,184.231 ms summed GPU duration, and 23.913% of traced request wall, all measured on gfx1151. Its disassembly showed K and V global loads issued only after a tile boundary barrier, with broad dependency waits before LDS publication. That made next-tile global-to-LDS overlap worth testing even though the kernel already allocates 248 VGPR, 128 SGPR, 64 KiB LDS, and zero scratch.

## Raw AMDGCN variants

Five gfx1151 raw-ASM variants were implemented without changing the 72-byte kernarg ABI, wave32 mode, symbol contract, grid, 256-thread workgroup, 64 KiB LDS allocation, attention arithmetic, page layout, mask, or output layout:

- combined K/V preload moves current-tile global fetches ahead of their existing barriers and publishes to LDS after the barrier;
- V-only preload isolates V staging;
- K-only preload isolates K staging;
- warm-K keeps the first tile unchanged and applies the K barrier-tail schedule only to later tiles;
- true K pipeline prefetches the next K tile during current-tile probability/value work, using registers dead during that phase, then publishes it after the tile boundary.

The first four variants preserve the baseline 248-VGPR, 128-SGPR, 64-KiB-LDS, zero-scratch allocation. The true pipeline also assembles with the same reported resource allocation, but increases live memory traffic and instruction count.

## Correctness

All variants are bit-exact against the accepted raw kernel for the tested real attention layouts on gfx1151. Deterministically shuffled T=256 pages at prefixes 0/64/128/192 and sequential T=8192 pages at prefixes 0/8192/16384/24576 report maximum absolute error 0. The serving-tested K-only variant also produced identical output-token hashes for both exact 32,768-input/+1-output pairs.

## HIP-event results

Each entry below is measured on gfx1151 with a shared output buffer and alternating A/B/BA order. The four-tier sums are sums of per-prefix medians; they are not estimates.

| Raw ASM variant | Samples per prefix | Baseline four-tier sum | Candidate four-tier sum | Baseline/candidate | Decision |
|---|---:|---:|---:|---:|---|
| combined K/V preload | 31 | 512.065275 ms | 510.155809 ms | 1.003743x | reject: only 0.374% aggregate and prefix-24K regressed 0.438% |
| V-only preload | 11 | 511.446938 ms | 512.519020 ms | 0.997908x | reject |
| K-only preload | 31 | 511.058306 ms | 509.177034 ms | 1.003695x | reject after serving gate |
| warm-K | 11 | 512.298676 ms | 511.449387 ms | 1.001661x | reject: below robust acceptance margin |
| true next-K pipeline | 11 | 510.841000 ms | 537.292051 ms | 0.950770x | reject: 4.923% slower |

The true pipeline improves prefix 0 and 8K by 2.230% and 1.841% measured on gfx1151, but regresses prefix 16K and 24K by 5.082% and 9.120%. The long-prefix reversal is consistent with added memory pressure overwhelming the limited overlap window.

## rocprofv3 and resource evidence

The K-only counter runs use one metric per fresh process with rocprofv3 signal handlers disabled. Both variants launch 8,192 waves and retain 248 VGPR, 128 SGPR, 65,536-byte LDS, and zero scratch.

| gfx1151 measured counter | Baseline | K-only preload | Interpretation |
|---|---:|---:|---|
| fetched KiB | 25,941,007.438 | 26,658,856.563 | +2.767% traffic |
| SQ busy cycles | 13,086,351,686 | 12,695,758,620 | -2.985% |
| L2 hit | 7.736% | 8.045% | +0.309 percentage point |
| SALU instructions | 503,631,872 | 505,733,120 | +0.417% |
| VALU instructions | 887,657.5 | 887,657.5 | unchanged |
| waves | 8,192 | 8,192 | unchanged |
| LDS bank conflicts | 28.682 | 28.682 | unchanged |
| occupancy, valid rerun | 10.039% | 10.393% | one sample per variant |

The first occupancy collection and the candidate MemUnitBusy rerun produced impossible profiler values and are explicitly excluded. SQ_WAVE_CYCLES saturated at the same counter maximum for both variants and is also excluded. The gfx1151 metric set exposes no direct wait/dependency-stall percentage, so none is estimated.

## Exact 32K serving gate

The valid eager A/B used the same runtime DSO hash for both variants, exact 32,768 input tokens, one forced output token, cached tokens 0, graphs disabled, and dFlash disabled. Production measured 20,818.102 ms median host E2E; K-only measured 20,793.877 ms, a nominal 0.116% reduction on gfx1151. One pair regressed by 1.703 ms and the other improved by 50.152 ms. This is below run-to-run noise and does not meet the end-to-end acceptance gate.

An earlier attempt failed before model initialization because a stale experimental DSO lacked netra_mxfp4_sgl_decode_block64. It executed no request and no attention kernel and is not performance evidence.

## Disassembly and restoration

Normalized before/after disassembly is retained beside this note. Static disassembly counts are 6,695 instruction lines for baseline, 6,784 for K-only, and 7,077 for true pipeline. Global-load sites rise from 80 to 112; waits remain 307 for K-only and rise to 309 for true pipeline; barriers remain 4; WMMA sites remain 128.

HSACO SHA-256:

- accepted production: 0ddd7d7d30d17b3d2594c7fbabd9b552c53f8a19f6bd290fed7df6011eaff372;
- K-only experiment: a307a00318caa2f5b6cfcfd842bd8193b74789554965200d684e076a01b08677;
- combined K/V experiment: 62a2701c5eba1e095e3760d9fbcfae3450ca049eece499c5c29b7df85e1956a3;
- V-only experiment: 82357a8be630276ecda460fab0534a67fbb90a0947b40ebde9157b72df5b5568;
- warm-K experiment: f361e98b9aff323bbe73a3ea657aae44839aeeb08eedb20053c5c4de13d385ad;
- true pipeline experiment: 492b4b6c08abf3fd11bf9c7d1026c5a3eb714659e7712951909674d4817abe36.

The live SGLang production HSACO was restored and re-hashed to the accepted 0ddd7d... object after serving. Production source, launch geometry, graphs, ABI, and generated code remain unchanged.

## Conclusion

Moving current-tile K loads across the barrier is a small isolated improvement, but it adds traffic and yields only a noisy 0.116% exact-32K serving delta. A true next-tile pipeline actively hurts long prefixes. No variant is accepted. Revisit K/V overlap only after materially lowering the 248-VGPR footprint or changing the 64-KiB residency limit; the existing barrier tail is too short to justify this schedule alone.

Evidence is in gfx1151-attention-kv-preload-negative-results-2026-07-31 and gfx1151-attention-kv-preload-negative-disassembly-2026-07-31.
