# gfx1151 Q/K-MRoPE-KV fusion: full decode graph (2026-07-30)

All performance values below are measured on gfx1151 unless explicitly marked otherwise. The checkpoint remains MXFP4. Prefill graphs and dFlash were disabled for this experiment; only the native SGLang full M1 decode graph was enabled.

## Outcome

The raw gfx1151 Q/K Gemma RMSNorm + MRoPE + gate extraction + page-1 K/V-store module launch is HIP-graph-capture safe. SGLang captured and replayed the full batch-1 decode graph with the raw ASM kernel included. Exact 210-input/128-output greedy tokens matched eager execution in all three paired runs.

A single graph shared output workspace across all ten standard-attention layers was rejected. Although outputs stayed exact, consecutive requests degraded from 18.05 to 9.40 and 6.71 output token/s. Reverting to graph-pool allocations restored stable 17.976-17.978 token/s. The accepted design therefore preallocates a distinct stable output workspace for each attention layer and M1-M16 token tier. Larger prefill shapes continue to use SGLang's graph pool until a bounded prefill workspace design is validated.

The accepted workspace costs 17,408 bytes per layer at M1, 208,896 bytes per layer at M12, and 23,674,880 bytes total if all M1-M16 tiers are resident across all ten standard-attention layers.

## Raw launch capture gate

The reproducible harness captures only the fused raw kernel, changes its input tensor contents in place, replays, and compares Q, K, gate, selected K cache, and selected V cache with the model-native baseline.

| Shape | Exact after mutation | Direct HIP event | Graph replay HIP event | Replay overhead | Capture host time |
|---:|---|---:|---:|---:|---:|
| M1 | yes | 0.009585 ms | 0.013687 ms | 0.004101 ms | 0.357312 ms |
| M12 | yes | 0.009540 ms | 0.013984 ms | 0.004444 ms | 0.353515 ms |
| M64 | yes | 0.012298 ms | 0.016705 ms | 0.004407 ms | 0.283132 ms |
| M210 | yes | 0.023211 ms | 0.028451 ms | 0.005240 ms | 1.406263 ms |

The isolated graph is slower because graph-launch overhead exceeds the saved launch work. The kernel is retained inside whole-model or multi-operation graphs, not wrapped in a one-kernel production graph.

A process-start rocprofv3 trace with signal handlers disabled recorded one capture, one instantiation, and 11 `hipGraphLaunch` calls. Measured `hipGraphLaunch` host API duration averaged 7,915.5 ns. The raw gfx1151 kernel appeared 28 times across warmup, direct timing, capture, correctness replay, and measured graph replays, with 207,830 ns total and 7,422.5 ns mean GPU duration. The full trace summary is in `gfx1151-qk-mrope-kv-graph-rocprofv3-2026-07-30.json`.

## Native SGLang full decode graph

SGLang measured graph construction at 1.54 seconds and 0.09 GB for the M1 tier. Server logs confirm `cuda graph: True` for decode and eager execution for prefill.

Three paired serving runs used exact 210-token inputs, exact 128-token forced outputs, zero cached tokens, deterministic greedy sampling, full M1 decode graph versus eager, and dFlash disabled.

| Metric | Eager median | Full graph median | Graph/eager |
|---|---:|---:|---:|
| TTFT, host measured | 464.046 ms | 439.524 ms | 0.947157x |
| Input throughput | 452.542 token/s | 477.789 token/s | 1.055790x |
| Decode time, host measured | 7076.690 ms | 7064.237 ms | 0.998240x |
| Output throughput | 17.9462 token/s | 17.9779 token/s | 1.001763x |
| Total host E2E | 7544.394 ms | 7503.761 ms | 0.994614x, or 1.005415x speedup |
| Peak VRAM sysfs sample | 102,085,820,416 bytes | 99,071,188,992 bytes | 0.970471x |

The sysfs memory values are reported exactly as measured. Strix Halo exposes unified-memory accounting through this interface, so these values must not be interpreted as dedicated-VRAM capacity.

The graph benefit is measured but small at this workload. It is accepted for correctness, stable-pointer integration, and as the base for larger captured regions; no larger speedup is claimed.

## Loader finding during graph validation

Two loader threads completed 26 shards in about 9-13 seconds across successful launches. Eight loader threads were rejected on the 16 GiB Netra container: the scheduler received SIGKILL at 0/26 shards because concurrent shard materialization exceeded safe host-memory headroom. Faster shard loading must retain bounded in-flight memory rather than only increasing thread count.

## Reproduction

Build the existing raw fusion, then run:

```bash
PYTHONPATH=/root/work/sglang-main/python \
  scripts/rocm/tools/benchmark/benchmark_qk_norm_mrope_kv_fusion.py \
  --tokens 1 12 64 210 --warmup 5 --reps 100 --graph \
  --output docs/netra/notes/gfx1151-qk-mrope-kv-graph-hip-events-2026-07-30.json
```

For native SGLang M1 capture, pass this configuration to the Netra launcher:

```text
--cuda-graph-config '{"decode":{"backend":"full","max_bs":1,"bs":[1]},"prefill":{"backend":"disabled"}}'
```

Machine-readable serving evidence, paired request rows, raw HIP-event samples, workspace sizes, and rejected variants are in `gfx1151-qk-mrope-kv-full-graph-2026-07-30.json`.

## Remaining graph gates

- Capture and replay M2-M16 verification tiers with per-layer workspaces.
- Validate native piecewise prefill tiers without allocating per-layer 8K outputs permanently.
- Profile full graph replay with rocprofv3 at the process level; the current GPU timing evidence covers the raw captured kernel and serving host timing covers end-to-end behavior.
- Integrate dFlash only after a compatible draft checkpoint and source-derived dFlash configuration exist.
