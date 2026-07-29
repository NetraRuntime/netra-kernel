# gfx1151 dFlash integration report (2026-07-29)

## Status

dFlash execution is **not measured and not integrated** on gfx1151 in the supplied environment. Rechecked after commit `b51e3ed` by enumerating all model configs under `/root/models`; the blocker is unchanged. This is an input blocker, not a performance conclusion: both installed model directories lack `dflash_config`, and no separate DFlash draft checkpoint exists under `/root/models`. SGLang's pinned implementation requires `--speculative-draft-model-path`; inventing draft weights or treating the target/MTP checkpoint as DFlash would invalidate acceptance and throughput results.

## Source-derived interface at SGLang `1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`

- Select `--speculative-algorithm DFLASH` and provide `--speculative-draft-model-path`.
- The handler forces speculative steps and top-k to one. DFlash's unit is its block/verify width.
- `--speculative-dflash-block-size` must be positive and must equal `--speculative-num-draft-tokens` when both are set. Otherwise SGLang reads `dflash_config.block_size` or defaults to 16.
- `--speculative-draft-window-size`, when used, must be at least the block size.
- Draft config parsing requires a valid draft `num_hidden_layers`; optional `target_layer_ids`, `num_target_layers`, `mask_token`, and `mask_token_id` are validated.
- Qwen3.5/Qwen3.6 target code implements `set_dflash_layers_to_capture`, so the target architecture has the required layer-capture hook.
- The v2 worker selects Triton preparation, acceptance, and fused KV materialization on CUDA or HIP. Its comments explicitly identify and avoid two host synchronizations in the legacy compact-rebuild path.
- Target verification is described in the pinned source as fixed-sequence-length prefill/extend with full graph support. Native `tc_piecewise` is separately disabled by SGLang's compatibility rules on HIP.

## Available non-speculative gfx1151 measured baselines

| Mode | Exact input/output | Cached | TTFT | Output rate | Total latency | Status |
|---|---:|---:|---:|---:|---:|---|
| Eager, graph disabled | 32,768 / 16,384 | 0 | 35.3761 s | 12.90 tok/s | 1,305.4599 s | gfx1151 measured |
| Eager under rocprofv3 | 210 / 128 | 0 | unavailable in non-streaming trace request | unavailable | 8.512340 s | gfx1151 measured with profiler overhead |

## Required work once a compatible draft checkpoint is supplied

1. Validate draft config, tokenizer mask ID, selected target layers, and real verify width.
2. Capture eager draft, target-verify, accept/reject, compaction, KV/GDN commit/rollback traces.
3. Record acceptance rate, mean accepted length, drafted tokens, verify calls/latency, rollback cost, TTFT, total latency, output tok/s, and VRAM.
4. Route the existing raw gfx1151 M2–M16 verify ASM kernels into eligible target projections and validate complete logits/accepted-token sequences.
5. Compare eager, full decode graph, native piecewise if HIP support is implemented, dFlash eager, and graph variants.

No dFlash acceptance rate, latency, or speedup is estimated in this report.
