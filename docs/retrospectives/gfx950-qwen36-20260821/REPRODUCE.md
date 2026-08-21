# Reproduction runbook

This runbook separates the CPU-safe evidence audit from GPU execution. It does
not install packages into either project environment and it refuses to call a
host GPU campaign unless gfx950 prerequisites are visible.

## 1. Reconstruct the evidence tables

From the clean kernel worktree:

```bash
export NETRA_RETRO_SERVER_ROOT=/absolute/path/to/clean/netra-server
tools/analysis/run_gfx950_qwen36_retrospective_campaign.sh audit
sha256sum -c docs/retrospectives/gfx950-qwen36-20260821/artifact-manifest.sha256
```

The collector is exhaustive and mechanical. The table builder is curated and
must be reviewed whenever evidence changes. Neither runs GPU code.

## 2. Prepare an immutable MI350X run

Use a reserved MI350X/gfx950 with the historical image
`lmsysorg/sglang:v0.5.16-rocm720-mi35x` (recorded digest begins
`sha256:54ac680`) or record a new full digest and treat it as a new campaign.
Historical notes record PyTorch 2.9.1 and ROCm 7.2. Do not substitute a newer
stack under the old result label.

Before any timing, save these outputs in a new external artifact directory:

```bash
tools/analysis/run_gfx950_qwen36_retrospective_campaign.sh gpu-preflight
uname -a
cat /etc/os-release
rocminfo
amd-smi static --asic --board --driver --firmware --vbios
amd-smi metric --clock --temperature --power --mem-usage
rocm-smi --showallinfo
python3 -m torch.utils.collect_env
python3 -m pip freeze
env | LC_ALL=C sort
git -C "$NETRA_RETRO_KERNEL_ROOT" rev-parse HEAD
git -C "$NETRA_RETRO_SERVER_ROOT" rev-parse HEAD
```

Record checkpoint revision/tree hashes and SHA-256 every source, HSACO,
manifest, engine, tuning table, prompt set, container image, and output file.
Keep new raw output outside the tracked tree. Isolate the selected GPU(s), lock
the intended power/clock policy through site-approved tooling, and sample
thermals/clocks before and after each arm.

## 3. Correctness, cold/warm, and replay sequence

For every row in `operation-inventory.csv` that has an eligible competitor:

1. Load identical captured tensors and assert shape, stride, alignment, dtype,
   scale storage, mask, cache format, workspace and output semantics.
2. Run the oracle/candidate before timing. Store bitwise equality, maximum
   absolute/relative error, mismatch count/ratio, cosine, and NaN/Inf counts as
   appropriate to that contract.
3. Measure cold compile/load, first call, warm eager, graph capture, and graph
   replay separately. Include adapters in a second integrated measurement.
4. Use at least five independent fresh processes. Within each process use a
   randomized balanced or ABBA arm order, adequate warmups, and retained
   per-iteration HIP-event timings.
5. Report median, mean, p5, p95, standard deviation, coefficient of variation,
   bootstrap or paired 95% confidence interval, and thermal/clock anomalies.

Current kernel entry points include:

```bash
tools/benchmark/iterate_gfx950_qwen36_moe_silu_mul_quant.sh
tools/benchmark/iterate_gfx950_qwen36_moe_gate_up_mfma.sh
tools/benchmark/iterate_gfx950_qwen36_moe_down_reduce_mfma_2wave.sh
tools/benchmark/iterate_gfx950_qwen36_router_bf16.sh
python3 tools/benchmark/qwen36_27b_gdn_bf16_state_t8_synthetic.py --help
python3 tools/benchmark/qwen36_27b_gdn_qkvz_conv_t8_synthetic.py --help
```

Treat these as operation-specific harnesses, not a substitute for the uniform
statistics protocol. Several historical validation/profile tools were deleted
or renamed; locate them through `data/historical-file-change-ledger.csv` and
run the matching historical commit in a separate worktree if exact
reproduction requires them.

## 4. Required serving matrix

Use the locked TP1/DP1 launches in the clean server worktree:

```bash
bash scripts/rocm/mi350x/launch_qwen36_27b_sglang.sh --help
python3 scripts/rocm/mi350x/benchmark_qwen36_27b.py --help
bash scripts/rocm/mi350x/launch_qwen36_sglang_profile.sh --help
python3 scripts/rocm/mi350x/benchmark_qwen36_concurrency.py --help
```

Do not assume `--help` interfaces are stable; archive the actual command line.
The mandatory matrix is:

- 27B: inputs 16/1K/8K, verification M8/M12, capacities 1/128/192/256 where
  valid, locked C192 and latency-oriented C128, dFlash-8 BF16 state, eager/full
  capture/replay.
- 35B: inputs 16/1K/8K, M16 and exact M768, natural C64, dFlash-12,
  piecewise capture/replay, and non-M768 fallback.

For each arm retain TTFT, prefill, inter-token latency/TPOT, output and total
tokens/s, wall time, p50/p95 latency, peak/resident memory, acceptance length,
request completion, accuracy, graph capture result, replay stability, and both
natural-EOS and matched fixed-output runs. Change one variable at a time.

## 5. Competitors

Pin the commits in `competitor-eligibility.csv` in isolated containers or
worktrees. First prove contract equivalence. If a backend requires cache
dequantization, repacking, scale conversion, layout changes, or different
masking, report it as a distinct integrated path and do not place its raw
kernel latency in the exact-contract speedup column. Ineligibility is a valid
result and must include compiler/runtime output.

## 6. Promotion gate

A candidate is promotable only after correctness, repeated warm and replay
microbenchmarks, graph capture/replay, matched natural serving, and quality all
pass the repository threshold. Archive a negative result when any gate fails.
Do not change production defaults as part of this retrospective.
