# Accepted gfx1151 attention Q-load pipeline (2026-07-30)

Status: **accepted and integrated**. Runtime/counter values are measured on
gfx1151; static resources and instruction counts are labeled static. MXFP4
weights are unchanged.

## Ranked-path reason and design

The raw N64 attention kernel remains the dominant exact-32K prefill family.
Its P transpose overlays Q rows 12-15, so every 64-key tile restored those rows
with sixteen serialized `global_load_b128`, `vmcnt(0)`, and `ds_write_b128`
sequences. The prologue used the same serialized pattern.

The accepted hand-written AMDGCN change issues eight 16-byte Q loads per lane,
waits once, then performs eight LDS writes; two batches cover the 256-element
head dimension. It reuses dead v192:v223 and preserves 248 VGPR, 128 SGPR,
65,536-byte LDS, and zero scratch (static gfx1151 metadata). N64 QK/PV,
masking, online-softmax order, K swizzle, P layout, and graph ABI are unchanged.

A sixteen-load issue variant is byte-identical but rejected. Against qpipe8 its
exact T8192 four-tier sum was 676.700 versus 675.483 ms, 0.9982x on gfx1151.

## Correctness

At T64/prefix 0, 64, and 192, production qpipe8 remains inside the accepted
FP32 envelope and differs from Triton by at most 3.0518e-5. Direct comparisons
against the serial raw kernel are byte-identical at T64 and exact T8192 prefix
0/8192/16384/24576 (`max_abs=0`, `mean_abs=0`). These are measured gfx1151
results.

## HIP-event kernel gate

Each exact T8192 row uses three warmups and eleven matched-input samples.

| Prefix | Serial-Q N64 ms | qpipe8 N64 ms | Speedup | Status |
|---:|---:|---:|---:|---|
| 0 | 44.8661 | 43.7200 | 1.0262x | gfx1151 measured |
| 8,192 | 127.7524 | 125.2068 | 1.0203x | gfx1151 measured |
| 16,384 | 217.6079 | 212.0501 | 1.0262x | gfx1151 measured |
| 24,576 | 306.4721 | 298.2497 | 1.0276x | gfx1151 measured |
| Four tiers | 696.6984 | 679.2265 | 1.0257x | gfx1151 measured sum |

## rocprofv3 evidence

Each counter is a standalone-HIP, one-counter-per-process pass at exact
T8192/prefix24576, avoiding the Python/PyTorch PMC abort path.

| Counter/resource | Serial Q | qpipe8 | Result |
|---|---:|---:|---|
| `s_waitcnt` sites | 345 | 317 | 8.12% lower, static gfx1151 disassembly |
| SQ busy cycles | 17,452,896,887 | 17,015,666,685 | 2.505% lower, gfx1151 measured |
| VRAM fetch | 17,838,143.0 KiB | 16,928,460.8 KiB | 5.10% lower, gfx1151 measured |
| L2 hit | 25.359224% | 31.682172% | +6.323 points, gfx1151 measured |
| Mean occupancy/active CU | 4.951211 | 5.082614 | higher, gfx1151 measured |
| Wavefronts | 8,192 | 8,192 | unchanged, gfx1151 measured |
| LDS bank conflict | 34.634101 | 34.658174 | unchanged, gfx1151 measured |
| VALUInsts / SALUInsts | 906,046 / 122,296 | 906,046 / 122,296 | unchanged, gfx1151 measured |

The qpipe8 `OccupancyPercent` sample was invalid (278,275%) and is excluded.
The metric set exposes no direct dependency-stall counter, so none is estimated.

## Graph gate

A graph captured at prefix 0 replayed after only device `kv_indptr[1]` changed
to 8,192. Both prefix-0 and prefix-8,192 replay outputs are byte-identical to
eager. Prefix-8,192 replay median is 124.745 ms over seven HIP-event samples on
gfx1151. Pointers are stable; module loading remains before capture.

## Real-checkpoint serving gate

Two fresh-server, matched-seed, exact 32,768-input/+1-output pairs were uncached,
batch 1, graph disabled, and dFlash disabled. Greedy output IDs and text hashes
match within every pair.

| Pair | Serial-Q host E2E ms | qpipe8 host E2E ms | Speedup | Status |
|---|---:|---:|---:|---|
| A | 24,797.658 | 23,402.156 | 1.0596x | gfx1151 measured host serving |
| B, reverse order | 23,657.757 | 23,207.570 | 1.0194x | gfx1151 measured host serving |
| Mean | 24,227.707 | 23,304.863 | 1.0396x | gfx1151 measured host serving |

A separate matched streaming pair measured TTFT 23,671.592 to 23,398.246 ms
(1.0117x) and effective input throughput 1,384.275 to 1,400.447 tok/s. Total
latency was 23,671.729/23,398.398 ms. Peak process-visible unified-memory values
were 102,249,635,840/102,438,154,240 bytes. Output throughput is not applicable
to a single output token. Counts were exactly 32,768 input, one output, and zero
cached tokens. All values are measured on gfx1151; none is estimated.

## Integration and reproduction

Production `extend_attention_wmma_n64_gfx1151.s` contains qpipe8 and the SGLang
HSACO build consumes it without an ABI or launcher change. Reproduce with
`tools/build/build_extend_attention_qpipe_experiment.sh`,
`tools/benchmark/benchmark_extend_attention_variants.py`, and
`tools/profiling/profile_extend_attention_qpipe8_counters.sh`. Machine-readable
HIP-event, correctness, graph, serving, counters, and disassembly artifacts are
adjacent to this note.
