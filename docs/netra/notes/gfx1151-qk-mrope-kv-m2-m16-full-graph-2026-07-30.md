# gfx1151 Q/K-MRoPE-KV fusion: M2-M16 full decode graphs (2026-07-30)

All numeric results below are measured on gfx1151 unless explicitly marked otherwise. The real Qwen3.6-35B-A3B checkpoint remained MXFP4. dFlash and prefill graphs were disabled. These are native batch decode tiers, not speculative-verify claims.

## Outcome

SGLang captured the full decode model at batch tiers M1, M2, M4, M8, M12, and M16 with the raw gfx1151 Q/K Gemma RMSNorm + MRoPE + gate extraction + K/V-store assembly kernel inside every standard-attention layer. The accepted launch uses SGLang's native `extra_buffer_lazy` Mamba radix-cache strategy and a 1.5 Mamba/full-KV memory ratio. Capture completed in 3.30 seconds, retained 0.17 GB, left 146,907 KV tokens, and resolved all 16 running-request slots.

The ordered M12 correctness gate passed exactly: all 12 graph sequences matched eager for both 64 and 128 forced output tokens. The decode-dominant 210-input/+128-output batch reduced host E2E from 26,918.630 ms to 25,836.506 ms, a measured 1.04188x speedup. The shorter +64 pair was 2.67% slower and is retained as a negative/noisy result.

The process-start rocprofv3 trace changes the optimization priority. The raw attention preparation fusion is graph-safe and fast, but it is only 0.051% of M12 graph kernel time. Decode attention stages plus the fusion are about 0.598%. MXFP4 expert gate and down kernels consume 62.20% by themselves. M2-M16 expert compute is therefore the next ranked target, not another assumption-driven attention rewrite.

## Why the first M12 capture request became M11

The first launch requested tiers `[1,2,4,8,12,16]` but SGLang captured `[1,2,4,8,11]`. This was not a graph parser bug. The hybrid GDN model's default overlap cache uses five Mamba state slots per live request; the automatic pool produced 59 slots, so the request pool was capped at 11.

Merely setting `--max-running-requests 16` made reservation pressure worse in that launch: 52 state slots resolved to ten requests. The accepted configuration uses the native lazy extra-buffer path, which needs four slots per request, and shifts the hybrid pool ratio to 1.5. It produced 69 slots and captured every requested tier through M16.

| Configuration | Mamba slots/request | Resolved requests | Captured tiers | Status |
|---|---:|---:|---|---|
| automatic default overlap | 5 | 11 | 1,2,4,8,11 | rejected for M12/M16 |
| default overlap + requested max 16 | 5 | 10 | 1,2,4,8,10 | rejected |
| `extra_buffer_lazy`, ratio 1.5, max 16 | 4 | 16 | 1,2,4,8,12,16 | accepted |

The six raw-fusion workspaces use 7,485,440 bytes total across ten standard-attention layers. Larger tiers still use the graph pool; no unbounded per-layer prefill allocation was introduced.

## Ordered M12 serving

A single ordered batch API request is the correctness oracle. It holds prompt order and batch membership fixed across fresh graph and eager servers, avoiding numerical differences caused by independently arriving requests occupying different prefill batch positions.

Every row used 12 requests, exactly 210 input tokens per request, zero cached tokens, greedy sampling, forced output length, dFlash disabled, eager prefill, and either M12 full decode graph or eager decode.

| Output/request | Mode | Host batch E2E | Aggregate output throughput | Exact graph/eager | Result |
|---:|---|---:|---:|---|---|
| 64 | eager | 13,819.552 ms | 55.5734 token/s | 12/12 | baseline |
| 64 | full M12 graph | 14,188.449 ms | 54.1285 token/s | 12/12 | 0.97400x; negative/noisy |
| 128 | eager | 26,918.630 ms | 57.0609 token/s | 12/12 | baseline |
| 128 | full M12 graph | 25,836.506 ms | 59.4508 token/s | 12/12 | 1.04188x; accepted |

The sysfs peak samples were 100,638,306,304 bytes for both graph rows, 101,268,017,152 bytes for eager +64, and 100,274,290,688 bytes for eager +128. These are measured unified-memory accounting values on Strix Halo, not dedicated-VRAM capacity.

## Independently arriving concurrency

A synchronized 12-thread streaming test reached a real scheduler line with `#running-req: 12` and `cuda graph: True`. Graph aggregate decode throughput was 56.1457 token/s versus 55.1012 token/s eager, a measured 1.01895x. Batch wall time was 14,578.677 ms graph versus 15,407.078 ms eager. Median streaming TTFT was 2,482.956 ms graph versus 3,268.807 ms eager.

The scheduler admitted one request first and the other eleven in a second prefill batch in both modes, but the identity/order of the first request differed. Only 7/12 cross-mode sequences matched, including one token-zero divergence. Because both prefill paths were eager and the ordered 12-prompt oracle was 12/12 exact, this is batch-position-sensitive numerical behavior rather than evidence of graph replay corruption. The streaming performance measurements are retained, but that run is rejected as a graph/eager token oracle.

## Production graph rocprofv3 trace

The trace used `/root/venv1151/bin/rocprofv3`, disabled profiler signal handlers, and did not collect hardware counters. This is the known-safe configuration after Python counter collection previously loaded an incompatible AQL-profile table and aborted with signal 6. HIP runtime, kernels, copies, allocations, scratch, statistics, and queue grouping were enabled.

The request was one ordered batch of 12 exact 210-token prompts with eight forced outputs each, uncached. The request completed successfully and the profiler finalized 91 MB of trace data after the server was explicitly stopped.

| Replay metric | Measured value on gfx1151 |
|---|---:|
| `hipGraphLaunch` calls | 8 |
| Correlated kernels | 24,504 |
| Kernels per replay | 3,063 |
| Mean graph GPU span | 194,532.240 us |
| Median graph GPU span | 194,746.144 us |
| Summed kernel GPU time/replay | 185,945.245 us |
| Mean positive inter-kernel gap | 2.804 us |
| Median positive inter-kernel gap | 2.084 us |
| Mean `hipGraphLaunch` CPU duration under profiler | 1,897.356 us |

The launch API value is profiler-instrumented and must not be substituted for an unprofiled replay overhead measurement.

### Ranked M12 graph kernels

| Kernel/family | Calls in 8 replays | Mean GPU time | Graph kernel time |
|---|---:|---:|---:|
| `mxfp4_prefill_gate_wmma_gfx1151` | 640 | 1,155.792 us | 49.726% |
| `mxfp4_prefill_down_wmma_gfx1151` | 320 | 579.899 us | 12.475% |
| dominant dense hipBLAS GEMM | 88 | 1,867.305 us | 11.046% |
| `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 720 | 121.800 us | 5.895% |
| `fused_recurrent_gated_delta_rule_packed_decode_kernel` | 240 | 278.367 us | 4.491% |
| decode attention stage 1 | 80 | 98.906 us | 0.5319% |
| decode attention stage 2 | 80 | 2.814 us | 0.0151% |
| raw QK-norm/MRoPE/KV fusion | 80 | 9.455 us | 0.0508% |

The raw fusion reports 40 VGPR, 128 SGPR, 512 bytes LDS, and zero scratch. It executes ten times per replay, exactly once per standard-attention layer.

## Reproduction

Launch the accepted graph server inside Netra:

```bash
SGLANG_CONTEXT_LENGTH=2048 SGLANG_WEIGHT_LOADER_THREADS=2 \
  bash scripts/rocm/integrations/sglang/launch.sh \
  --max-running-requests 16 \
  --mamba-radix-cache-strategy extra_buffer_lazy \
  --mamba-full-memory-ratio 1.5 \
  --cuda-graph-config '{"decode":{"backend":"full","max_bs":16,"bs":[1,2,4,8,12,16]},"prefill":{"backend":"disabled"}}'
```

Run an ordered exact M12 batch:

```bash
python scripts/rocm/tools/benchmark/benchmark_sglang_batch_request.py \
  --batch-size 12 --input-len 210 --output-len 128 \
  --seed-prefix gfx1151-batch12-controlled-128-20260730 \
  --label gfx1151-full-graph-ordered-batch12-210-plus128 \
  --graph-mode full-decode-tiers-1-2-4-8-12-16 \
  --output results/graphs/gfx1151/ordered-batch12-210-plus128.json
```

Capture and isolate graph replay work:

```bash
scripts/rocm/tools/profiling/profile_sglang_graph_batch_request.sh \
  gfx1151-fullgraph-batch12-210-plus8-20260730 12 210 8 2048

python scripts/rocm/tools/profiling/summarize_graph_replays.py \
  results/profiles/gfx1151/gfx1151-fullgraph-batch12-210-plus8-20260730 \
  --out results/profiles/gfx1151/gfx1151-fullgraph-batch12-210-plus8-20260730/graph-replay-summary.json
```

Machine-readable measurements and negative results are in `gfx1151-qk-mrope-kv-m2-m16-full-graph-2026-07-30.json`.

## Next work

- Specialize the measured M12 MXFP4 expert gate/up and down path in raw gfx1151 assembly; it dominates this graph.
- Reduce the 3,063 kernels per replay by fusing measured adjacent expert activation, packing, reduction, and residual regions.
- Profile and optimize the dense hipBLAS and GDN rows after expert compute.
- Treat dedicated M2-M16 speculative verification and dFlash as separate gates. No compatible draft checkpoint was available here, so no speculative acceptance or rollback claim is made.
- Retain the attention ideas ledger, but only revisit attention when an actual long-context or verify trace ranks it above the current expert path.
