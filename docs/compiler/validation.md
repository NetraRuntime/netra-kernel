# Validation and Qwen promotion gates

Run the CPU/static slice:

```bash
PYTHONPATH=compiler python3 -m unittest discover -s tests/compiler -v
python3 -m netra_compiler.cli compile --model manifests/gfx950/models/qwen36-dense.json --target gfx950 --profile decode_m1 --output build/netra-engines/qwen36-dense
python3 -m netra_compiler.cli validate --engine build/netra-engines/qwen36-dense --static
bash tools/compiler/build_engine_gfx950.sh build/netra-engines/qwen36-dense
python3 tools/compiler/validate_gfx950_tactic_catalog.py
```

Build all assembly specializations used by the locked deployment with:

```bash
bash tools/compiler/build_gfx950_tactic_catalog.sh \
  build/gfx950-tactic-catalog
```

The 2026-08-17 model-independent refactor is recorded at
`docs/compiler/gfx950-current-best-template-equivalence-20260817.json`. On the
gfx950 host, all 18 `.text` sections and all 18 semantic AMDHSA metadata records
matched the locked artifacts. Full HSACO byte identity was 0/18 due to non-text
ELF changes and is not claimed. The generated three-operation MoE subset also
passed direct device launches and 20/20 HIP graph replays with the zero oracle
on one MI350X after all graph-stable caller-owned intermediates were bound.

The complete modular catalog was subsequently rebuilt and used at every active
catalogued assembly boundary of the eight-GPU Qwen3.6-35B deployment on
2026-08-18. Evidence is retained under:

```text
/data/netra/benchmarks/netra-engine-foundation-20260818/kernel-modular-v2
```

`artifacts/build-result.json` records exact locked `.text` identity for 18/18
code objects; normalized AMDHSA metadata also matched 18/18. Full HSACO byte
identity remains 0/18 because debug/source provenance differs and is not
claimed. Five fresh-process routed-DP8 samples were 75,145.38, 81,468.60,
80,546.86, 78,287.21, and 77,045.25 output token/s. Their 78,498.66 mean is
-0.32% versus the locked 78,748.15 mean; Welch `t=-0.171` and the approximate
95% delta interval is [-3,661.15, +3,162.16] token/s, so no statistically
distinguishable regression was observed. All five runs passed all 3,072
request, input, output, token, cache, dFlash, and error checks. The aggregate
is `qwen36-modular-five-run-aggregate.json`. This establishes compatibility,
not a speedup, and does not by itself promote a different server runtime path.

The final modular source and include-closure gate is stored at:

```text
/data/netra/benchmarks/netra-engine-foundation-20260817/current-best-assembly-modular-v5
```

It covers the common ABI/kernarg/address/MFMA/numerical/reduction/synchronization
library, GDN state/causal-convolution primitives, all 14 leaf templates, all 18
assembler specializations, and the generated MoE direct/graph smoke.

The later GDN shared-core extraction was cross-assembled at:

```text
/data/netra/benchmarks/netra-engine-foundation-20260817/kernel-library-v1/repo/build/current-best-after-gdn-core
```

All 18 locked `.text` hashes still matched. A compiler-generated,
model-independent 1-wave state-replay engine was built at
`build/generic-gdn-state-replay`: `.text` was the locked
`192f772c...4b89dc`, kernarg 88, fixed LDS 2048, launch block 64 under AMDHSA
maximum 512, and the module/profile guard smoke passed for M=12. That smoke did
not bind real tensors or launch numerical work and is not correctness or
performance evidence.

Cross-assembly does not require a visible GPU. Hardware execution does. With
the retained dense capture:

```bash
bash tools/compiler/validate_qwen_dense_engine_gfx950.sh build/netra-engines/qwen36-dense CAPTURE_DIR
```

The build first assembles both template instances and their preserved golden
sources. It requires byte-identical `.text` and identical resource metadata,
kernarg, and launch contracts, then emits machine-readable equivalence JSON.
The hardware script performs five 200-launch runs per rejected raw candidate
plus the AITER oracle and graph replay. It does not promote a candidate. Compare
explicit `.text` sections, disassemblies, metadata, and launch contracts with
`tools/compiler/compare_disassembly.py`.

The 2026-08-17 template extraction was validated at:

```text
/data/netra/benchmarks/netra-engine-foundation-20260817/assembly-template-refactor-20260817-v5
```

Both generated `.text` hashes equal their preserved sources: one-wave
`a6234d97...177daea`, four-wave LDS `c8f4f7f6...22c7173`. Five real-capture
runs per variant each had 0/2,048 BF16 mismatches, 0/200 nondeterministic
launches, and 20/20 exact graph replays. Median-of-medians was 10.00 us and
15.56 us respectively, matching the retained experiment range. The hardware
summary SHA-256 is
`1a3762784722f21f1eadc855b1ab688ad4d03de80d390f1a188ba60ba06b72aa`.
Both schedules remain rejected because template equivalence cannot erase their
negative matched-serving evidence. The consolidated repository record is
`docs/compiler/gfx950-dense-template-equivalence-20260817.json`.

Default promotion additionally requires the same server commit, checkpoint,
environment, GPU, request set, seeds, TP, dFlash and graph settings in paired,
interleaved processes. Record kernel and graph inventories, boundary/state and
token hashes, routing/logits/dFlash acceptance, TTFT, throughput, verification
latency, end-to-end median/p90, memory, load time, allocation/synchronization
counts, and raw samples. Performance must be statistically indistinguishable
from or faster than the golden path. Compilation cannot prove a new schedule is
optimal without measurement.

To compile the accepted M=1 MoE compatibility graph from already-built golden
objects and run its synthetic graph-replay smoke test:

```bash
python3 -m netra_compiler.cli compile \
  --model manifests/gfx950/models/qwen36-moe-m1-golden.json \
  --target gfx950 --profile decode_m1 \
  --golden-artifact-root build/gfx950-qwen36-fp8 \
  --output build/netra-engines/qwen36-moe-m1-golden
HIP_VISIBLE_DEVICES=0 \
  bash tools/compiler/run_qwen36_moe_m1_engine_smoke_gfx950.sh \
  build/netra-engines/qwen36-moe-m1-golden
```

The compiler refuses missing or hash-mismatched HSACOs. The smoke allocates
synthetic zero buffers, checks each fixed operation separately, captures the
complete recipe, replays it 20 times, and requires exact BF16 zero output. It
is a runtime/ABI/graph test, not real-checkpoint correctness or performance
evidence.

When the complete eight-MI350X host is quiescent, first run the smaller matched
sequential DP8 compatibility A/B from the server repository. It isolates engine
overhead but is not the authoritative deployment-throughput contract:

```bash
bash scripts/rocm/mi350x/run_netra_engine_dp8_ab.sh \
  /data/netra/benchmarks/netra-engine-foundation-20260817/golden-slice/build/qwen36-moe-m1-golden-v4 \
  /data/netra/benchmarks/netra-engine-foundation-20260817/runtime-hardening-c46d4273/build/runtime/libnetra_engine_gfx950.so \
  /data/netra/benchmarks/gfx950_qwen36_optimization/netra-engine-ab-$(date -u +%Y%m%dT%H%M%SZ)
```

It defaults to 50 repetitions of short, 210+128, and long-prefill cases in
matched sequential server processes. Set `THROUGHPUT_REPETITIONS=5` to retain
five c64/c256/c512 aggregate samples per arm. It reports token, output-
distribution, aggregate dFlash acceptance, median, p90, and throughput sample
comparisons. It stops but does not remove its named containers.

The deployment north-star is separately locked by
`/data/netra/benchmarks/gfx950_qwen36_optimization/CURRENT_BEST.json` with
SHA-256 `2823d64410ba4a87223ede5429c90677cc76aea628244dd3c4a1c810af76557a`.
That contract is full routed DP8, round-robin, concurrency 1024, 3072 requests,
and exactly 1024 input plus 1024 output tokens per request. Do not compare its
78,748.15 output-token/s mean to the smaller isolation A/B's total-token rate.
Run the exact five-fresh-process engine gate from the server repository:

```bash
bash scripts/rocm/mi350x/validate_netra_engine_current_best_dp8.sh \
  ENGINE_DIR RUNTIME_LIBRARY \
  /data/netra/benchmarks/gfx950_qwen36_optimization/netra-engine-current-best-$(date -u +%Y%m%dT%H%M%SZ)
```

The script verifies the lock hash before launch and rejects any benchmark-
contract mismatch. It also requires every worker container to expose the exact
engine environment and read-only mounts and proves that the runtime library is
present in a live process map before sending traffic. This audit is important:
an earlier 2026-08-17 run was correctly excluded after its container records
showed that the then-current DP8 wrapper had not forwarded the engine options.

The audited five-fresh-process run is retained at:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260817T103000Z-netra-engine-current-best-ne779-audited-5run
```

All five exact request/token/cache/error checks and all 40 worker runtime-map
audits passed. Engine output-throughput samples were 80,944.51, 80,538.56,
80,389.09, 74,665.90, and 79,485.58 token/s: mean 79,204.73 versus the locked
78,748.15 mean (+0.58%), median +1.70%, exact two-sided permutation p=0.794.
Mean acceptance was 5.5326 versus 5.5413. The mean end-to-end latency ratio was
0.9899 and the mean TTFT ratio was 1.0070. These are positive compatibility
results, but one throughput sample was below the old minimum and the two
five-run distributions were historical/sequential, not paired/interleaved.
The result therefore does not make engine mode the default.

`SGLANG_NETRA_ENGINE_MODE=disabled` is the default. `shadow` and `compare` are
diagnostic and invalid for latency claims. `engine` may return an engine result
only for accepted fixed-kernel profiles. The dense compatibility engine still
returns framework fallback. The golden MoE engine is wired into the server and
passed retained real-checkpoint operand, graph-replay, and live-model token/
distribution comparisons against the accepted bridge. It remains opt-in until
the exact locked current-best serving contract and every promotion gate pass.
HIP graph recipes are instantiated at runtime, not serialized as portable graph
binaries.
