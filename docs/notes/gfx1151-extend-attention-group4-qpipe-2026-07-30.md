# Accepted gfx1151 shared-KV attention (2026-07-30)

Status: **accepted and integrated**. Every runtime and counter value below is
measured on gfx1151. Static instruction/resource values are labeled static.
MXFP4 weights are unchanged; this BF16 attention path remains raw AMDGCN.

## Ranked-path reason and accepted design

The fresh post-qpipe8 32K trace ranked `extend_attention_wmma_n64_gfx1151`
first: 40 calls, 6,791.151 ms, and 27.735% of all kernel time. Qwen3.6 has
16 query heads but only two KV heads, so the prior `(M/64,16)` launch staged
the same K and V data eight times per KV head.

The accepted hand-written gfx1151 kernel changes the launch to `(M/64,4)` with
512-thread workgroups. Four query heads execute together. Their 16 wave32 waves
use four independent 8 KiB P workspaces in LDS, while one four-wave leader group
stages a single shared 32 KiB K or V tile. Q stays in global/cache rather than
being restored through LDS. Two register banks overlap the next Q fragment load
with current QK WMMA. This combines proposal 6, part of proposal 1, and proposal
3 without increasing static allocation: 244 metadata VGPR, 248 allocated VGPR,
128 allocated SGPR, 64 KiB LDS, and zero scratch.

A workgroup barrier at the tile-loop boundary is mandatory. The first prototype
without it sometimes corrupted 217 BF16 values in row 8,064/head 4 at prefix
24,576: the leader could overwrite shared LDS while another head group was still
in PV. After adding the barrier, eight repeated exact T8192/prefix24576 launches
were byte-identical to qpipe8. This rejected intermediate is retained as a
measured negative development result.

## Correctness gates

All exact T8192 comparisons at prefix 0/8K/16K/24K are byte-identical to the
accepted qpipe8 kernel. T64 prefix 0/64/192 also matches qpipe8 byte-for-byte.
Against the FP32 oracle, maximum absolute errors are 1.23296e-4, 4.06522e-5,
and 2.07084e-5 respectively, the same envelope as Triton. Raw versus Triton is
at most 3.05176e-5. The real checkpoint produced identical input hashes, greedy
IDs, and output-text hashes in both profiled and unprofiled pairs.

## HIP-event kernel gate

Each exact T8192 row uses matched inputs, alternating AB/BA order, and eleven
samples.

| Prefix | qpipe8 ms | group4-qpipe ms | Speedup | Status |
|---:|---:|---:|---:|---|
| 0 | 42.3527 | 34.5968 | 1.2242x | gfx1151 measured HIP events |
| 8,192 | 124.5169 | 101.5735 | 1.2259x | gfx1151 measured HIP events |
| 16,384 | 211.1284 | 171.7632 | 1.2292x | gfx1151 measured HIP events |
| 24,576 | 297.5950 | 242.2638 | 1.2284x | gfx1151 measured HIP events |
| Four-tier sum | 675.5930 | 550.1972 | 1.2279x | gfx1151 measured sum |

The register Q pipeline adds another measured 1.0209x to 1.0320x over the
non-pipelined group4 kernel across the same four tiers.

## rocprofv3 counters and disassembly

Each counter has three standalone process launches at exact T8192/prefix24576.
This avoids the Python/PyTorch PMC abort path that previously ended with signal
6. Mean/min/max samples are in the adjacent JSON.

| Counter/resource | qpipe8 | group4-qpipe | Result |
|---|---:|---:|---|
| Mean occupancy/active CU | 5.066871 | 6.314654 | +24.626%, gfx1151 measured |
| VRAM fetch | 16,320,695.4 KiB | 17,424,780.7 KiB | +6.765%, gfx1151 measured tradeoff |
| L2 hit | 31.179682% | 13.965580% | -17.214 points, gfx1151 measured tradeoff |
| LDS bank conflict | 34.658113 | 29.133858 | -15.939%, gfx1151 measured |
| VALU instructions | 906,046 | 878,687.5 | -3.019%, gfx1151 measured |
| Waves | 8,192 | 8,192 | unchanged, gfx1151 measured |
| VGPR / SGPR / LDS / scratch | 248 / 128 / 65,536 / 0 | same | gfx1151 measured profiler allocation |
| Static waits / barriers | 317 / 5 | 311 / 4 | lower, static disassembly |
| Static global loads / WMMA | 96 / 128 | 80 / 128 | lower / unchanged, static disassembly |

Direct Q reloads explain the higher fetch and lower L2 hit rate; shared K/V,
lower LDS conflicts, fewer VALU instructions, and a larger cooperative
workgroup still win decisively. `OccupancyPercent` is invalid on gfx1151 in
these passes, ranging from single digits to hundreds of thousands, so it is
explicitly excluded. This metric set exposes no direct dependency-stall counter
and none is estimated.

## Graph gate

The module was loaded before capture and all tensor pointers remained stable.
An exact T8192 graph captured at prefix 0 replayed after only device
`kv_indptr[1]` changed to 8,192. Both outputs are byte-identical to eager.
Construction took 7.230393 ms host time. Graph allocation delta was 1,024 bytes
with a 2,097,152-byte reserved-memory delta. Prefix-8K replay median was
101.548973 ms over eleven gfx1151 HIP-event samples. The raw module launch is
therefore compatible with the existing stable-pointer full/piecewise graph
bridge; this is a kernel graph gate, not a claim that the whole 32K serving path
is graph-enabled.

## Full-request rocprofv3 gate

Exact 32,768 input +1 output requests used the same seed, zero cached tokens,
graph disabled, and dFlash disabled.

| Metric | qpipe8 | group4-qpipe | Result |
|---|---:|---:|---|
| Attention, 40 calls | 6,791.151 ms | 5,488.215 ms | 1.2374x, gfx1151 measured GPU |
| Total kernel time | 24,486.024 ms | 23,136.476 ms | 1.0583x, gfx1151 measured GPU |
| Positive launch gaps | 17,108.147 ms | 14,869.768 ms | 13.084% lower, gfx1151 measured trace |
| Trace wall | 41,574.278 ms | 37,991.278 ms | 1.0943x, gfx1151 measured trace |
| Profiled host E2E | 24,324.723 ms | 22,993.794 ms | 1.0579x, measured host serving |

The candidate trace is now the ranked baseline. Attention remains rank 1 at
5,488.215 ms and 23.721% of kernel time, so further attention work is still
justified.

## Unprofiled real-checkpoint serving gate

Every row is a fresh-server exact 32,768 input +1 output request, batch 1,
uncached, graph disabled, and dFlash disabled. Matched rows have identical input
hashes, greedy token IDs, and output hashes.

| Pair | qpipe8 host E2E ms | group4-qpipe host E2E ms | Speedup | Status |
|---|---:|---:|---:|---|
| A | 23,402.156 | 22,147.810 | 1.0566x | gfx1151 measured host serving |
| B | 23,207.570 | 22,203.472 | 1.0452x | gfx1151 measured host serving |
| Mean | 23,304.863 | 22,175.641 | 1.0509x | gfx1151 measured host serving |

Peak sysfs unified-memory readings for the candidate were 102,142,775,296 and
102,587,011,072 bytes. TTFT/input throughput are unavailable from this
non-streaming +1 endpoint; total host E2E is reported instead. Output throughput
is not applicable to one output token. No value in this report is estimated.

## Updated assessment of the 18 attention proposals

Shared K/V reuse is accepted and is the largest attention gain so far. Per-tile
Q restoration is eliminated as part of the new layout, and next-Q overlap is
accepted. The work did not reduce the 244/248-VGPR allocation or 64 KiB LDS, so
those remain high-priority only if a design crosses a real residency threshold.
Next-global K/V overlap is now more plausible but still constrained by LDS.
Softmax scheduling/rescale, larger contiguous pages, Q/K norm + RoPE + KV-store
fusion, and M2-M16 verify attention remain untested. dFlash remains input-blocked
because no compatible draft/config is installed; no benefit is estimated.

## Integration and reproduction

Production `kernels/gfx1151/attention/extend_attention_wmma_n64_gfx1151.s`
contains the accepted raw ASM. Both launch bridges default to grid Y=4 and
block X=512 while retaining compile-time overrides for the qpipe8 oracle.
Reproduce with:

- `tools/build/build_netra_sglang_gfx1151.sh`
- `tools/build/build_extend_attention_group4_qpipe_experiment.sh`
- `tools/benchmark/benchmark_extend_attention_variants.py`
- `tools/benchmark/benchmark_extend_attention_raw.py`
- `tools/benchmark/benchmark_extend_attention_graph.py`
- `tools/profiling/profile_extend_attention_group4_qpipe_counters.sh`
- `tools/profiling/profile_sglang_request.sh`

Machine-readable correctness, HIP-event, graph, counter, serving, full-trace,
and complete before/after disassembly evidence are adjacent to this note.
