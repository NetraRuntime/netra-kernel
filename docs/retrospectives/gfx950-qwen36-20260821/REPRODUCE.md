# Reproduction runbook

This runbook separates the CPU-safe evidence audit from GPU execution. It does
not install packages into either project environment and it refuses to call a
host GPU campaign unless gfx950 prerequisites are visible.

## 1. Reconstruct the evidence tables

From the clean kernel worktree:

```bash
export NETRA_RETRO_SERVER_ROOT=/absolute/path/to/clean/netra-server
export NETRA_RETRO_ORIGINAL_KERNEL_ROOT=/absolute/path/to/original/netra-kernel
export NETRA_RETRO_ORIGINAL_SERVER_ROOT=/absolute/path/to/original/netra-server
tools/analysis/run_gfx950_qwen36_retrospective_campaign.sh audit
sha256sum -c docs/retrospectives/gfx950-qwen36-20260821/artifact-manifest.sha256
python3 tools/analysis/summarize_benchmark_samples.py --self-test
```

The collector is exhaustive and mechanical. The table builder is curated and
must be reviewed whenever evidence changes. Neither runs GPU code.

To include ignored artifacts from user-owned checkouts without modifying them:

```bash
python3 tools/analysis/collect_ignored_gfx950_artifacts.py \
  --repository original-netra-kernel=/absolute/path/to/original/netra-kernel \
  --repository original-netra-server=/absolute/path/to/original/netra-server \
  --repository analysis-netra-kernel="$PWD" \
  --repository analysis-netra-server="$NETRA_RETRO_SERVER_ROOT" \
  --max-hash-bytes 2000000000 \
  --output-csv docs/retrospectives/gfx950-qwen36-20260821/data/ignored-artifact-inventory.csv \
  --output-summary docs/retrospectives/gfx950-qwen36-20260821/data/ignored-artifact-summary.json
```

The ignored-artifact collector does not follow symlinks and defaults to a
64-MiB hash limit. This campaign explicitly raises that limit to 2 GB to hash
the locally present checkpoint shards. It remains a read-only scan.

Repository validation used:

```bash
# netra-kernel
./tools/ci/check.sh

# netra-server: dependency-light Qwen3.6 tests in an isolated pytest tool env
PYTHONPATH=. uvx --from pytest pytest -q \
  test/registered/unit/tools/test_qwen36_checkpoint_inspector.py \
  test/registered/unit/tools/test_qwen36_concurrency.py \
  test/registered/unit/tools/test_qwen36_exact_cases.py \
  test/registered/unit/tools/test_qwen36_loading_summary.py \
  test/registered/unit/tools/test_qwen36_production_profiles.py \
  test/registered/unit/tools/test_summarize_qwen36_dp8_canonical.py
```

The server command uses an isolated `uvx` environment and does not install
anything into the project. PyTorch/ROCm-dependent tests still require the
locked serving container.

## 2. Prepare an immutable MI350X run

The completed campaign used eight MI350X/gfx950 devices and exact image ID
`sha256:89941358...`, named
`netra/sglang:v0.5.16-rocm720-mi35x-gigatoken0.9.0`, with ROCm 7.2.3 and
amd-smi 26.2.2. Recover the full image ID from the saved inspect record; the
abbreviation here is only for readability. Do not substitute a newer stack
under the same result label.

Relaunch a saved configuration with the supplied read-only reconstruction
tool. It preserves image, command, environment, mounts, devices, IPC, network,
and shared memory while requiring explicit output/GPU/port isolation:

```bash
python3 tools/analysis/relaunch_inspected_container.py \
  --inspect-json /absolute/path/to/container-inspect.json \
  --name netra-retro-reproduction \
  --gpu 0 \
  --results-dir /absolute/path/to/new-results \
  --port 31401
```

The physical GPU is exposed with `ROCR_VISIBLE_DEVICES=<physical>` and appears
as logical device zero through `HIP_VISIBLE_DEVICES=0`. Setting both variables
to the physical index makes nonzero isolated GPUs invisible inside this
container and is not equivalent.

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

## 6. Completed campaign commands and artifact integration

The completed exact and concurrency clients were invoked from the clean server
worktree with one output directory per arm/case. Substitute each arm's saved
URL, model basename, and artifact path:

```bash
python3 "$NETRA_RETRO_SERVER_ROOT/scripts/rocm/mi350x/run_qwen36_exact_cases.py" \
  --base-url http://127.0.0.1:31401 \
  --expected-model-name Qwen3.6-27B-FP8 \
  --campaign-root "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT" \
  --output-dir "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT/27b-baseline/exact-input16_output1" \
  --case input16_output1 --repetitions 20

python3 "$NETRA_RETRO_SERVER_ROOT/scripts/rocm/mi350x/run_qwen36_exact_cases.py" \
  --base-url http://127.0.0.1:31401 \
  --expected-model-name Qwen3.6-27B-FP8 \
  --campaign-root "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT" \
  --output-dir "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT/27b-baseline/exact-input8192_output1" \
  --case input8192_output1 --repetitions 20

python3 "$NETRA_RETRO_SERVER_ROOT/scripts/rocm/mi350x/benchmark_qwen36_concurrency.py" \
  --base-url http://127.0.0.1:31401 \
  --expected-model-name Qwen3.6-27B-FP8 \
  --output-dir "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT/27b-baseline/concurrency-fixed210x128" \
  --input-tokens 210 --output-tokens 128 \
  --concurrencies 1 128 192 --warmup-waves 1 --measurement-waves 3
```

The other arms used their isolated ports and model basenames; 35B used
concurrencies 1 and 64. Exact input-1024/output-4096 used the predefined
`input1024_output4096` case and three repetitions. A nonzero exit from the
repeatability gate is an expected negative artifact, not permission to delete
the partial result directory.

After GPU work is quiescent, hash model trees and artifacts without modifying
the checkpoints:

```bash
(cd /data/netra/models/Qwen3.6-27B-FP8 && \
  find . -type f -print0 | sort -z | xargs -0 sha256sum) \
  > "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT/checkpoints/qwen36-27b-fp8.sha256"

find "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT" -type f ! -name SHA256SUMS -print0 \
  | sort -z | xargs -0 sha256sum \
  > "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT/SHA256SUMS"
```

Repeat the model-tree command for both FP8 and DFlash directories of both
models. Transfer with metadata preservation, then build the compact tracked
tables and the exhaustive external numeric ledger:

```bash
rsync -a gpu-host:/data/netra/benchmarks/gfx950_qwen36_retrospective-20260821.current \
  "$NETRA_RETRO_LOCAL_ARTIFACT_ROOT/"

python3 tools/analysis/integrate_gfx950_qwen36_campaign.py \
  --current-root "$NETRA_RETRO_CURRENT_ARTIFACT_ROOT" \
  --recovered-root "$NETRA_RETRO_RECOVERED_ARTIFACT_ROOT" \
  --report-root docs/retrospectives/gfx950-qwen36-20260821 \
  --derived-root "$NETRA_RETRO_DERIVED_ARTIFACT_ROOT"
```

The derivation tool enumerates every numeric field in parseable benchmark
JSON/CSV/TSV. It excludes profiler event traces from that ledger because they
are event timelines, not benchmark samples, but includes their bytes and
SHA-256 in the artifact inventory.

## 7. Promotion gate

A candidate is promotable only after correctness, repeated warm and replay
microbenchmarks, graph capture/replay, matched natural serving, and quality all
pass the repository threshold. Archive a negative result when any gate fails.
Do not change production defaults as part of this retrospective.
